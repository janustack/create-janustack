# create-janustack

[![](https://img.shields.io/crates/v/create-janustack)](https://crates.io/crates/create-janustack)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md)
[![https://good-labs.github.io/greater-good-affirmation/assets/images/badge.svg](https://good-labs.github.io/greater-good-affirmation/assets/images/badge.svg)](https://good-labs.github.io/greater-good-affirmation)


## Usage

To get started using `create-janustack` run of the below commands in the folder you'd like to setup your project.

## Installation

### Bun

```bash
bun create janustack
```

### Cargo

```bash
cargo install create-janustack --locked
cargo create-janustack
```

## Versioning

Delete the Local Tag:
```bash
git tag -d v0.1.0
```
(Optional) Delete the Remote Tag:

```bash
git push -d origin v0.1.0
```

Re-create the Tag and Push:

```bash
git tag v0.1.0
git push origin v0.1.0
```