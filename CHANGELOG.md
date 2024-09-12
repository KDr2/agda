Release notes for Agda version 2.7.0.1
======================================

This is a minor release of Agda fixing some bugs and regressions.

Installation
------------

* During installation, Agda type-checks its built-in modules and installs the generated `.agdai` files.
  (This step is now skipped when the Agda executable is not installed, e.g. `cabal install --lib Agda`.)
  Should the generation for (some of) these files fail, the names of the missing ones are now printed,
  but installation continues nevertheless ([PR #7465](https://github.com/agda/agda/pull/7465)).
  Rationale: installation of these files is only crucial when installing Agda in super-user mode.

* Agda supports GHC versions 8.6.5 to 9.10.1.

Pragmas and options
-------------------

* The release notes of 2.7.0 claimed that the option `--exact-split` was now on by default
  ([Issue #7443](https://github.com/agda/agda/issues/7443)).
  This is actually not the case, the documentation has been suitably reverted.

* Default option `--save-metas` has been reverted to `--no-save-metas` because of performance regressions
  ([Issue #7452](https://github.com/agda/agda/issues/7452)).

Bug fixes
---------

* Fixed an internal error related to interface files
  ([Issue #7436](https://github.com/agda/agda/issues/7436)).

* Fixed two internal errors in Mimer:
  ([Issue #7402](https://github.com/agda/agda/issues/7402) and
  [Issue #7484](https://github.com/agda/agda/issues/7484)).

* Fixed a regression causing needless re-checking of files
  ([Issue #7199](https://github.com/agda/agda/issues/7199)).

* Improved printing of terms by fixing a display form bug
  ([PR #7480](https://github.com/agda/agda/issues/7480)).

List of closed issues
---------------------

For 2.7.0.1, the following issues were
[closed](https://github.com/agda/agda/issues?q=is%3Aissue+milestone%3A2.7.0.1+is%3Aclosed)
(see [bug tracker](https://github.com/agda/agda/issues)):

- [Issue #7199](https://github.com/agda/agda/issues/7199): Agda re-checks a file with an up-to-date interface file
- [Issue #7402](https://github.com/agda/agda/issues/7402): Mimer internal error in hole with constraint
- [Issue #7436](https://github.com/agda/agda/issues/7436): Code only reachable from display forms not serialised in Agda 2.7.0
- [Issue #7442](https://github.com/agda/agda/issues/7442): Regression: emptiness check fails when erased constructors are involved
- [Issue #7443](https://github.com/agda/agda/issues/7443): `--exact-split` is not default in 2.7.0, contrary to claims
- [Issue #7452](https://github.com/agda/agda/issues/7452): Performance regression caused by making `--save-metas` the default
- [Issue #7455](https://github.com/agda/agda/issues/7455): Both stack and cabal fail to install Agda
- [Issue #7484](https://github.com/agda/agda/issues/7484): Internal error using Mimer in where block

These pull requests were merged for 2.7.0.1:

- [PR #7427](https://github.com/agda/agda/issues/7427): #7402: mimer failing on higher order goal
- [PR #7444](https://github.com/agda/agda/issues/7444): Fix #7436: make display forms of imported names DeadCode roots
- [PR #7445](https://github.com/agda/agda/issues/7445): Remove disclaimer that Agda would not follow the Haskell PVP
- [PR #7454](https://github.com/agda/agda/issues/7454): Fixed #7199
- [PR #7456](https://github.com/agda/agda/issues/7456): Actually, --exact-split is not really on by default
- [PR #7457](https://github.com/agda/agda/issues/7457): Revert default to `--no-save-metas`
- [PR #7465](https://github.com/agda/agda/issues/7465): Re #7455: Setup.hs: catch when Agda did not produce (all) agdai files
- [PR #7471](https://github.com/agda/agda/issues/7471): setup: Don't assume exe is built on --lib
- [PR #7475](https://github.com/agda/agda/issues/7475): Hotfix for #7442
- [PR #7476](https://github.com/agda/agda/issues/7476): Bump std-lib to latest (v2.1.1) and cubical to latest
- [PR #7480](https://github.com/agda/agda/issues/7480): Match display forms in the right context
- [PR #7487](https://github.com/agda/agda/issues/7487): Mimer shouldn't try to use existing pattern lambdas in solutions
