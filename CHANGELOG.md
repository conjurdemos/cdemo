## 1.3.0

*   *\[breaking]* Replaced AWX with Ansible Tower
    
    When we first created cdemo, we assumed that AWX, being a community-driven
    development version of Ansible Tower and available as a container, was the
    path of least resistance for including Tower-like functionality. We soon
    learned that the development process of Tower allows for wild swings in
    functionality and bold experimentation in AWX, after which features go
    through careful planning and consideration for backwards compatability
    before being merged into Tower proper. Therefore, for our purposes, AWX was
    never really suitable and so we've changed to use Tower instead with the
    gratis license from Red Hat.
    
*   Updated Ansible role to use URI module in many places instead of calling out
    to inline curl scripts, to improve readability and maintainability.

## 1.2.0

*   *\[breaking]* Modified idividual roles to use a single set of variables in the site.yml file. Pinned the versions of Gogs and splunk to known working versions

## 1.1.1

*   Moves Conjur Enterprise detecting out of the Conjur role. This allows other
    roles to discover whether we're using Conjur Enterprise, even if the Conjur
    config role isn't included in the run. This is desirable when running only a
    lean subset of the roles.

*   Refactors duplicate tasks in the machinePrep role.

*   Uses the `shell` command with the Splunk CLI to add a monitor for Conjur
    audit data, instead of the unreliable `SPLUNK_ADD` environment variable.

## 1.1.0
This release includes breaking changes. Make special note of changes marked
*\[breaking]*, which may require you to update your understanding.

*   *\[breaking]* Removed the default variable files in each role, moving the
    variables into `conjurDemo/site.yml` for easy changes in a single place.

*   Pinned Splunk to 7.1.2

*   *\[breaking]* Deprecated Splunk user `eva` (login as `admin` with password
    `Cyberark1`)

*   New script: `bin/clean-orphaned-containers` cleans up tomcat/webapp
    containers left over from demo runs.

## 1.0.3

New script `bin/remove-containers` removes all running cdemo Docker containers,
if any. It will not remove containers that are not part of the cdemo cluster.

## 1.0.2

We now pin AWX to version 1.0.8. The next upgrade on this front will likely be
to Tower andnot a newer version of AWX.

## 1.0.1

New script `bin/check-network` performs a pre-check for network connectivity.

It will be run automatically during `installAnsible.sh` or can be run manually
by the user. It will attempt to contact DockerHub, Github, and the Jenkins
plugin site; if any of these fail, the script will print a warning and return a
non-zero exit status.

## 1.0.0

File `VERSION` added to cdemo. This will help us identify which cdemo somebody
is using when it's time to compare behavior between different revisions of the
repo.

A new document, `CONTRIBUTING.md`, gives instructions for maintainers and
contributors.

The string in `VERSION` and this file, `CHANGELOG.md`, will be updated every
time cdemo is revised.
