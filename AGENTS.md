# Repository Identity

This repository is the implementation and distribution package for the
ThisIsEnough (`tie`) workflow runtime itself.

It is not an application repository that has had the workflow applied to it.
The workflow source lives here: skills, commands, runtime specs, templates,
installer files, and plugin metadata.

When working in this repository, treat changes as changes to the workflow
runtime product. Do not assume workflow state files are the source of truth for
this repository unless the user explicitly asks to test or run `tie` against
this repo.
