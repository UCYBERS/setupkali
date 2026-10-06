# Security Policy

## Supported versions

Only the latest release receives fixes. Check yours with `sudo ./setupkali.sh --version`.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Use GitHub's private reporting: **Security tab > Report a vulnerability** on
[UCYBERS/setupkali](https://github.com/UCYBERS/setupkali/security/advisories/new).

Include the version, what you did, what you expected and what happened. You will get a reply
as soon as a maintainer can look at it.

## Scope

setupkali runs as root and installs software, so these matter most:

- Downloads that are not verified (SHA-256 for release assets, pinned commits for git sources)
- Anything that lets a local user gain root through the tool (temporary files, file ownership)
- Weakened defaults (passwords, SSH, screen lock) outside a training VM

## Trust model

- The script, its pinned hashes and `fixed-http-shellshock.nse` live in the same repository.
  Review a release before running it, and prefer a tagged release over `master`.
- The default root password `ucybers` is public. It is offered only on desktop virtual machines
  (VMware, VirtualBox, Hyper-V, Parallels) and is meant for isolated NAT / Host-Only lab networks.
