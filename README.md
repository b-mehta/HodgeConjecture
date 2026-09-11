# Statement of the Hodge Conjecture

This repo is work in progress towards stating the Hodge conjecture in Lean for the
[Formal Conjectures project](https://github.com/google-deepmind/formal-conjectures).

The basis for this is a 50k lines of code autoformalisation due to Codex, of which 12k lines are
transitively used in the statement. The code is being cleaned up by
[Paul Lezeau](https://sites.google.com/view/paul-lezeau/home/),
[Yaël Dillies](https://www.su.se/english/profiles/y/yadi8568),
[Roktim Mascharak](https://roktimmascharak.github.io/) and
[Jack McCarthy](https://jackmccarthy.org/) during the Formal Conjectures workshop hosted
by Imperial College London 7-11 September 2026 thanks to a generous donation from Google DeepMind.

The short-term goal of this project is to be integrated to the Formal Conjectures repository.
The medium-term goal is for all the prerequisites to the conjecture to be upstreamed to
[Mathlib](https://github.com/leanprover-community/mathlib4).
The long-term goal is to have either a proof or a disproof of the Hodge conjecture in Mathlib.

The statement of the conjecture is in `HodgeConjecture/Statement.lean`.
The remaining content of the project is sorted into four folders:

- `HodgeConjecture/Mathlib`: Content that is on track to be upstreamed to Mathlib;
- `HodgeConjecture/Definitions`: Definitions used in the statement of the conjecture;
- `HodgeConjecture/Lemmas`: Supporting results needed by those definitions;
- `Other`: Results that aren't needed to state the conjecture but may be useful as sanity checks.

The dividing line is `HodgeConjecture/Statement.lean`: a module belongs in `Definitions` if it
defines something the statement mentions, in `Lemmas` if it is needed only to build such a
definition, and in `Other` otherwise. In particular nothing in `Other` may be reachable from the
statement. Two checks keep this honest:

- `lake build` builds `scripts/CheckStatementImports.lean`, which imports the statement and fails if
  the resulting environment contains any module of `Other`;
- `python3 scripts/check_import_layers.py` checks the converse — that every module of `Definitions`,
  `Lemmas` and `Mathlib` really is used by the statement — plus that both umbrella modules are
  complete.

Both checks work on the import graph, where a module counts as used as soon as something it imports
is used. `lake env lean scripts/StatementClosure.lean` measures the stronger property: it walks the
constant-dependency closure of the `HodgeConjecture` term and lists the imported modules that
contribute no declaration to it. That list is the worklist for shrinking what a reader has to audit
to check that the conjecture says what it should. It is a report rather than a check, because a
module can contribute no constant and still be needed — one exporting only notation or `abbrev`s
leaves no trace in the term.

WIP formalisation guide: <https://paul-lez.github.io/HodgeConjecture/>.
