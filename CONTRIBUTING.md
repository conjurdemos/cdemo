# Contributing to `cdemo`

First of all, thank you for your interest in contributing! We all want cdemo to
be an ideal environment for first-time Conjur demos, and in order for us to
achieve that vision, we need your input.

## Proposing changes to cdemo

Most of cdemo is maintained as a set of Ansible playbooks, and other parts are
shell scripts; but you don't need to be able to write an Ansible playbook or a
shell script, to help out.

Here's how to propose a change to cdemo without writing any code:
1. Open an issue here in the GitHub project
2. In the issue, describe the experience you want to have and your vision around
   it. Implementation suggestions are helpful but not required.
3. Post a link to your issue in the public Conjur Slack ([sign up here][slack])
   or otherwise get in touch with a maintainer.

[slack]: https://slackin-conjur.herokuapp.com/

To propose a change with a working implementation, open a [GitHub pull
request][PR].

[PR]: https://help.github.com/articles/creating-a-pull-request/

## Maintaining the Change Log

Before you open a pull request, you must follow these steps:
1. Increment the version number inside the file `VERSION` according to [semantic
   versioning][semantic]
2. Add the new version number as a heading in `CHANGELOG.md`
3. Describe your changes under the new version heading

[semantic]: https://semver.org/
