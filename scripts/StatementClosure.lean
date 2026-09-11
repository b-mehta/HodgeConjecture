/-
Copyright 2026 The Formal Conjectures Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-/
import HodgeConjecture.Statement

/-!
# Which modules does the statement actually use?

`scripts/check_import_layers.py` checks that every module of `Definitions`, `Lemmas` and `Mathlib`
is *reachable* from `HodgeConjecture.Statement` in the import graph. That is a weak invariant: a
module is reachable as soon as something it imports is reachable, whether or not the statement uses
anything it defines.

This report measures the stronger thing. It walks the constant-dependency closure of the
`HodgeConjecture` term itself and lists the imported repository modules that contribute no
declaration to it. Those modules are candidates for moving downstream of the statement, which is
what keeps the statement auditable: a reader checking that the conjecture says what it should
reads the closure, not the import graph.

Run it with

```
lake env lean scripts/StatementClosure.lean
```

## Two caveats before deleting anything

A module can legitimately contribute no constant and still be required:

* it may export only notation, attributes or `local instance`s, which leave no trace in the term —
  `HodgeConjecture.Mathlib.CategoryTheory.ConcreteCategory.Notation` supplies the `↧` notation used
  in nearly every signature in the repository and appears in this list;
* `abbrev` and `@[reducible]` definitions are unfolded during elaboration, so a module whose
  statement-facing exports are all abbreviations also appears here.

So treat the output as a worklist, not a verdict: move a module, then rebuild.
-/

open Lean

/-- The repository libraries. -/
def isRepositoryModule (m : Name) : Bool :=
  (`HodgeConjecture).isPrefixOf m || (`Other).isPrefixOf m

run_cmd do
  let env ← getEnv

  -- Every declaration of a repository module present in this environment, with its module.
  let mods := env.header.moduleNames
  let mut declModule : Std.HashMap Name Name := {}
  for i in [0:mods.size] do
    if isRepositoryModule mods[i]! then
      for d in env.header.moduleData[i]!.constNames do
        declModule := declModule.insert d mods[i]!

  -- The constants `HodgeConjecture` transitively depends on, through both types and values.
  let mut used : Std.HashSet Name := {}
  let mut todo : Array Name := #[`HodgeConjecture]
  while h : todo.size > 0 do
    let n := todo.back
    todo := todo.pop
    if used.contains n then continue
    used := used.insert n
    if let some ci := env.find? n then
      for c in ci.type.getUsedConstants do todo := todo.push c
      if let some v := ci.value? then
        for c in v.getUsedConstants do todo := todo.push c

  let mut contributing : Std.HashMap Name Nat := {}
  let mut usedDecls : Nat := 0
  for (d, m) in declModule.toArray do
    if used.contains d then
      usedDecls := usedDecls + 1
      contributing := contributing.insert m ((contributing.getD m 0) + 1)

  let imported := mods.filter isRepositoryModule
  let inert := (imported.filter (!contributing.contains ·)).qsort (·.toString < ·.toString)

  logInfo m!"\
    repository declarations in this environment: {declModule.size}\n\
    used by `HodgeConjecture`:                   {usedDecls}\n\
    repository modules imported:                 {imported.size}\n\
    contributing no used declaration:            {inert.size}"

  unless inert.isEmpty do
    logInfo m!"Modules contributing nothing to the statement term:\
      {indentD (.joinSep (inert.toList.map (m!"{·}")) "\n")}"
