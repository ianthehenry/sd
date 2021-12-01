# `sd`: my script directory

It's like a hierarchical `~/bin`, but with fancy autocomplete. [See this blog post for an introduction and demo][post].

# Usage

The default behavior for `sd foo bar` is:

- If `~/sd/foo` is an executable file, execute `~/sd/foo bar`.
- If `~/sd/foo/bar` is an executable file, execute it with no arguments.
- If `~/sd/foo/bar` is a directory, this is the same is `sd foo bar --help` (see below).
- If `~/sd/foo/bar` is a non-executable regular file, this is the same is `sd foo bar --cat` (see below).

There are some special flags that are significant to `sd`. If you supply any one of these arguments, `sd` will not invoke your script, and will do something fancier instead.

    $ sd foo bar --help
    $ sd foo bar --new
    $ sd foo bar --edit
    $ sd foo bar --cat
    $ sd foo bar --which
    $ sd foo bar --really

## `--help`

If there's a corresponding `.help` file, print that file. For example, `sd foo --help` would try to print `~/sd/foo.help`.

If there is no `.help` file for the command, `sd` will print the first comment block in the file instead. `sd` currently only recognizes bash-style `#` comments.

For example:

    $ cat ~/sd/nix/sync

```bash
#!/usr/bin/env bash

# make user environment match ~/dotfiles/user.nix
#
# This will remove any packages you've installed with nix-env
# but have not added to user.nix. To see exactly what this
# will do, run:
#
#     sd nix diff

set -euo pipefail

# maybe this should be configurable
nix-env -irf ~/dotfiles/user.nix
```

That will produce the following help output (note that it only prints the first contiguous comment block):

```
$ sd nix sync --help
make user environment match ~/dotfiles/user.nix

This will remove any packages you've installed with nix-env
but have not added to user.nix. To see exactly what this
will do, run:

    sd nix diff
```

If you run `--help` for a directory, it prints a command listing instead:

```
$ sd nix --help
nix commands

install    -- <package> use --latest to install from nixpkgs-unstable
shell      -- add gcroots for shell.nix
diff       -- prints what will happen if you run sync
info       -- <package> prints package description
sync       -- make user environment match ~/dotfiles/user.nix
```

## `--new`

Everything to the left of `--new` is considered a command path, and everything to the right of `--new` is considered the command body. For example:

    sd foo bar --new echo hi

Will try to create a new command at `~/sd/foo/bar` with an initial contents of `echo hi`.

Actually, to be more precise, it will create this script:

    $ cat ~/sd/foo/bar

```bash
#!/usr/bin/env bash

set -euo pipefail

echo hi
```

There is currently no way to customize this template.

If no body is supplied after `--new`, `sd` will open the script for editing.

## `--cat`

Prints the contents of the script. See `SD_CAT` below.

## `--edit`

Open the script in an editor. See `SD_EDITOR` below.

## `--which`

Prints the path of the script.

## `--really`

Suppress special handling of all of the other special flags. This allows you to pass `--help` or `--new` as arguments to your actual script, instead of being interpreted by `sd`. For example:

    $ sd foo bar --help --really

Will invoke:

    ~/sd/foo/bar --help

The first occurrence of the `--really` argument will be removed from the arguments passed to the script, so if you need to pass a literal `--really`, you must pass it twice to `sd`. For example:

    $ sd foo bar --help --really --really

Will invoke:

    $ ~/sd/foo/bar --help --really

# Options

`sd` respects some environment variables:

- `SD_ROOT`: location of the script directory. Defaults to `$HOME/sd`.
- `SD_EDITOR`: used by `sd foo --edit` and `sd foo --new`. Defaults to `$VISUAL`, then `$EDITOR`, then finally falls back to `vi` if neither of those are set.
- `SD_CAT`: program used when printing files, in case you want to use something like [`bat`](https://github.com/sharkdp/bat). Defaults to `cat`.

# Installation

There are two ways to use `sd`:

1. source the `sd` file, which will define the shell function `sd`
2. treat `sd` as a regular executable and put it somewhere on your `PATH`

I prefer to use `sd` as a regular executable, but the function approach is more convenient if you already use a shell plugin manager that knows how to set up `fpath` automatically.

Note that you cannot invoke "recursive `sd`" (that is, write scripts that themselves invoke `sd`) if you use the function approach. This includes all of the helper scripts in `sdefaults/` (explained below).

## Installation as a shell function

You can just source `sd` in your `.zshrc` and set up completion manually (as described below), but `sd` is designed to be compatible with shell plugin managers.

### [Antigen](https://github.com/zsh-users/antigen) (`zsh`)

Add this line to your `.zshrc`:

```shell
antigen bundle ianthehenry/sd
```

Then you can update `sd` by running:

```
$ antigen update
```

### Other plugin managers

You can *probably* install `sd` with other plugin managers as well, but I haven't tested any.

## Installation as a regular script

`sd` is not currently packaged in any package manager that I am aware of, but it should be pretty easy if you want to package it for your distribution. It's just a single script and a single completion file. Until that day:

- Put the `sd` script somewhere on your path.

I like to symlink it to `~/bin`, which is already on my path. If you've cloned this repo to `~/src/sd`, run something like:

    $ ln -s ~/src/sd/sd ~/bin/sd

- Put `_sd` somewhere on your `fpath`.

If you've cloned this repo to `~/src/sd`, add something like this to your `~/.zshrc` file:

```shell
fpath=(~/src/sd $fpath)
```

## `sd help command` vs. `sd command --help`

There are some scripts in `sdefaults/` that you can copy into your own `~/sd` if you like. They'll let you type `sd cat foo bar` instead of `sd foo bar --cat` or `sd new foo -- echo hi` instead of `sd foo --new echo hi` (and so on for each of the built-in commands).

These mostly exist for backwards compatibility with an earlier version of `sd`. You don't have to use them if you don't want to. Note that they will not work if you've installed `sd` as a shell function instead of an executable.

# Why does completion only work in `zsh`

Just because I'm lazy. `bash` completion support is forthcoming. One day...

[post]: https://ianthehenry.com/posts/sd-my-script-directory/

# Changelog

There are no *releases* of `sd`, per se, but I have occasionally made changes.

## 2021-11-30

- added `--really`
- `dir.help` files are now `dir/help` files

You used to be able to provide a description for a directory called `foo/` by writing a file called `foo.help` as a sibling of that directory.

Now directory help summaries are expected in `foo/help` instead.

This has the sort-of nice effect that `sd foo help` is the same as `sd foo --help`.
