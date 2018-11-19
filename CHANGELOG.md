# 1.1.1

* Moves Conjur Enterprise detecting out of the Conjur role. This allows other
  roles to discover whether we're using Conjur Enterprise, even if the Conjur
  config role isn't included in the run. This is desirable when running only a
  lean subset of the roles.
* Refactors duplicate tasks in the machinePrep role.

# 1.1.0
This release includes breaking changes. Make special note of changes marked
*[breaking]*, which may require you to update your understanding.

* *[breaking]* Removed the default variable files in each role, moving the
  variables into `conjurDemo/site.yml` for easy changes in a single place.
* Pinned Splunk to 7.1.2
* *[breaking]* Deprecated Splunk user `eva` (login as `admin` with password
  `Cyberark1`)
* New script: `bin/clean-orphaned-containers` cleans up tomcat/webapp containers
  left over from demo runs.


# 1.0.3

New script `bin/remove-containers` removes all running cdemo Docker containers,
if any. It will not remove containers that are not part of the cdemo cluster.

# 1.0.2

We now pin AWX to version 1.0.8. The next upgrade on this front will likely be
to Tower andnot a newer version of AWX.

# 1.0.1

New script `bin/check-network` performs a pre-check for network connectivity.

It will be run automatically during `installAnsible.sh` or can be run manually
by the user. It will attempt to contact DockerHub, Github, and the Jenkins
plugin site; if any of these fail, the script will print a warning and return a
non-zero exit status.

# 1.0.0

File `VERSION` added to cdemo. This will help us identify which cdemo somebody
is using when it's time to compare behavior between different revisions of the
repo.

A new document, `CONTRIBUTING.md`, gives instructions for maintainers and
contributors.

The string in `VERSION` and this file, `CHANGELOG.md`, will be updated every
time cdemo is revised.
