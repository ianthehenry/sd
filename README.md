# `sd`: my script directory

It's like a hierarchical `~/bin`, but with fancy autocomplete. [See this blog post for an introduction and demo][post].

# Usage

The default behavior for `sd foo bar` is:

- If `~/sd/foo` is an executable file, execute `~/sd/foo bar`.
- If `~/sd/foo/bar` is an executable file, invoke it with no arguments.
- If `~/sd/foo/bar` is a directory, this is the same is `sd foo bar --help`.
- If `~/sd/foo/bar` is a non-executable regular file, this is the same is `sd foo bar --cat`.

But there are some special flags that are significant to `sd`. If you supply any one of these flags, `sd` will not invoke your script, and will do something fancier instead.

    $ sd foo bar --help
    $ sd foo bar --new
    $ sd foo bar --edit
    $ sd foo bar --cat
    $ sd foo bar --which

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

# Options

`sd` respects some environment variables:

- `SD_ROOT`: location of the script directory. Defaults to `$HOME/sd`.
- `SD_EDITOR`: used by `sd foo --edit` and `sd foo --new`. Defaults to `$VISUAL`, then `$EDITOR`, then finally falls back to `vi` if neither of those are set.
- `SD_CAT`: program used when printing files, in case you want to use something like [`bat`](https://github.com/sharkdp/bat). Defaults to `cat`.

# Installation

There are two ways to use `sd`:

1. source the `sd` file, which will define the shell function `sd`
2. treat `sd` as a regular executable and put it somewhere on your `PATH`

I prefer to use `sd` as a regular executable, but the function approach is convenient for integration with shell plugin managers like [antigen](https://github.com/zsh-users/antigen), which will also set up `fpath` for you so that completion will work without effort.

Note that you cannot invoke "recursive sd" (that is, write scripts that themselves invoke `sd`) if you use the function approach. This includes all of the helper scripts in `sdefaults/` (see below).

## Installation with a shell plugin manager

I don't know how to do this.

## Installation as a regular script

- Put the `sd` script somewhere on your path.

I like to symlink it to `~/bin`, which is already on my path. If you've cloned this repo to `~/src/sd`, run something like:

    $ ln -s ~/src/sd/sd ~/bin/sd

- Put `_sd` somewhere on your `fpath`.

If you've cloned this repo to `~/src/sd`, add something like this to your `~/.zshrc` file:

```shell
fpath=(~/src/sd $fpath)
export fpath
```

## `sd help command` vs. `sd command --help`

There are some scripts in `sdefaults/` that you can copy into your own `~/sd` if you like. They'll let you type `sd cat foo bar` instead of `sd foo bar --cat` or `sd new foo -- echo hi` instead of `sd foo --new echo hi` (and so on for each of the built-in commands).

These mostly exist for backwards compatibility with an earlier version of `sd`. You don't have to use them if you don't want to. Note that they will not work if you've installed `sd` as a shell function instead of an executable.

# Why does completion only work in `zsh`

Just because I'm lazy. `bash` completion support is forthcoming. One day...

[post]: https://ianthehenry.com/posts/sd-my-script-directory/
