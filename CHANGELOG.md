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
