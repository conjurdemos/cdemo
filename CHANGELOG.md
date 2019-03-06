## Unreleased

*   Created new feature that installs 3.11 of OKD. This just stands up OKD in a
    usuable state. It's accessible via https://okd.cyberark.local:8443 from the
    local machine.

## 1.4.0

Moderate reorganization, plus fixes for correctness and readability

*   *\[breaking]*: Component selection is now done in `conjurDemo/inventory.yml`
    instead of in `conjurDemo/site.yml`.
    
    This was changed for two reasons:
    * Inventory is an easier ini file to modify with less noise from the many
      configuraiton options in `site.yml`, most of which users shouldn't have
      reason to change.
    * Configuration per-hosts in the inventory propagates to all playbooks run
      on that host, removing repetition and complexity.

*   Changes to scripts:

    Two scripts were renamed-
    1. `cleanEnvironment.sh` is now `bin/clean-environment`
    2. `installAnsible.sh` is now `bin/install-ansible`

*   The clean environment script will no longer remove Docker entirely by
    default. If you want this behavior, you need to run it with a flag like so:
       
    ```
    $ bin/clean-enviornment --remove-docker
    ```

*   Many parts of the clean script are broken out into dependencies, allowing
    you to clean only certain parts of the environment if you desire.
    Specifically, you have these additional options (all of which are also
    invoked by the `clean-environment` script:)
       
    * `bin/remove-ansible`
    * `bin/remove-containers`
    * `bin/remove-nginx`
    * `bin/remove-postgres`
    * `bin/remove-rabbitmq`

*    New script `bin/install` makes installing cdemo more foolproof. Instead of
     typing out the `ansible-playbook` command by hand or pasting it out of the
     documentation, you can run `bin/install`.
     
     This script also accepts a `--debug` flag which will enable Ansible's
     "debug" strategy, giving you a REPL on installation failure instead of
     aborting the playbook. This could be useful if you are making modifications
     to the playbooks or if you're experiencing intermittant network issues and
     would like to be able to retry steps instead of starting over.
     
*    We now use a `conjurrc` file and a copy of the certificate from the
     appliance to configure the Conjur CLI instead of interactively running
     `conjur init`. This is correct practice for automated use cases and for
     improving security.

*    The containers for `gogs` and `conjur-cli` are now added to the Ansible
     inventory after they're created, so you can run commands against them. In
     the future we may support dynamic Docker inventory to discover
     already-running containers, and add other containers that are part of cdemo
     to the inventory.
     
*    We now use the official Docker repositories to install the latest
     `docker-ce`, `docker-ce-cli`, and `continerd.io`, which should provide the
     most up to date fixes and features for Docker use cases.

## 1.3.1

*   Updates Jenkins minor version

    The Jenkins declarative policy pipeline plugin, which we use in our labs,
    got an update that dropped support for the version of Jenkins we had pinned,
    specifically `2.133`. We upgraded the pinned version to `2.163`, which is
    still supported by the plugin.

*   Made the Ansible Tower CLI available in the Jenkins container for easy
    interaction between these two systems.

*   Fixed: various breaking issues with Lab 3 (the Ansible Conjur identity demo)

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
