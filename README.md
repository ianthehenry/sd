# `sd`: my `s`cript `d`irectory

- [Usage](#usage)
- [Installation](#installation)
- [Changelog](#changelog)

Has this ever happened to you?

*Black and white video plays of someone struggling to find a shell script they wrote a year ago and stuffed into their `~/bin` without giving it a very meaningful name.*

Don't you hate it when you can't find the scripts you need, when you need it? Well now there's a better way!

*Color fills the screen. Someone holds `sd` up to the camera, and flashes a winning smile. They've found the script on their first try.*

Introducing `sd`, the script directory for the refined, sophisticated professional. Simply organize your scripts in a logical directory hierarchy, and let `sd` take care of the rest!

    $ tree ~/sd
    /Users/ian/sd
    ├── blog
    │   ├── edit
    │   ├── preview
    │   └── publish
    ├── nix
    │   ├── diff
    │   ├── info
    │   └── sync
    └── tmux
        └── init

And now instead of typing `~/sd/blog/publish`, you can just type `sd blog publish` -- a savings of nearly three whole characters!

But wait! There's more! You'll wonder how you ever lived without `sd`'s best-in-class tab completion:

    $ sd nix <TAB>
    diff  -- prints what will happen if you run sync
    info  -- <package> prints package description
    sync  -- make user environment match ~/dotfiles/user.nix

Simply write a one-line comment in your script, and you'll never be left scratching your head over how you were supposed to call it!

# uhh

Hi okay sorry. [Take a look at this blog post for a real introduction and a fancy asciinema demo of how it works.](https://ianthehenry.com/posts/sd-my-script-directory/)

# Usage

The default behavior for `sd foo bar` is:

- If `~/sd/foo` is an executable file, execute `~/sd/foo bar`.
- If `~/sd/foo/bar` is an executable file, execute it with no arguments.
- If `~/sd/foo/bar` is a directory, this is the same is `sd foo bar --help` (it prints usage information).
- If `~/sd/foo/bar` is a non-executable regular file, this is the same is `sd foo bar --cat` (it just prints the file out).

There are some special flags that are significant to `sd`. If you supply any one of these arguments, `sd` will not invoke your script, and will do something fancier instead.

    $ sd foo bar --help
    $ sd foo bar --new
    $ sd foo bar --edit
    $ sd foo bar --cat
    $ sd foo bar --which
    $ sd foo bar --really

## `--help`

Print the contents of a help file, or generate a help file from comments in a script.

For executables, `sd` looks for a file with the same name but the `.help` extension. For example, `sd nix diff --help` would look for a file called `~/sd/nix/diff.help`, and print it out.

For directories, `sd` looks for a file that's just called `help`. So `sd nix --help` would look for `~/sd/nix/help`.

If there is no help file for an executable, `sd` will print the first comment block in the file instead. `sd` currently only recognizes bash-style `#` comments.

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

If you run `--help` for a directory, it will also print out a command listing after the help text:

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

    $ sd foo bar --new echo hi

Will try to create a new command at `~/sd/foo/bar` with an initial contents of `echo hi`.

Actually, to be more precise, it will create this script:

    $ cat ~/sd/foo/bar

```bash
#!/usr/bin/env bash

set -euo pipefail

echo hi
```

Assuming the default template.

If no body is supplied after `--new`, `sd` will open the script for editing.

### custom script templates

You can customize the template used by `--new` by creating a file called `template`, either in `~/sd` or one of its subdirectories.

`sd` will try to find a template by walking recursively up the directory hierarchy. For example, if you run:

```
$ sd foo bar baz --new
```

`sd` will try to find a template at `~/sd/foo/bar/template` first, then fall back to `~/sd/foo/template`, then `~/sd/template`. If it doesn't find any template file, it will use the default bash template shown above.

(There is no need to make your `template` executable -- `sd` will take care of that for you.)

When `--new` is used to create an inline script, that script will always go at the *end* of your template file. There is currently no way to customize this.

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

# Context

When a script is invoked, `sd` will set the environment variable `SD` to the directory that the script was found in -- in other words, `$(dirname "$0")`.

This makes it slightly more convenient to refer to shared helper files or other scripts relative to the executing script.

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

Note that you cannot invoke "recursive `sd`" (that is, write scripts that themselves invoke `sd`) if you use the function approach, unless you're writing zsh scripts. But you probably shouldn't.

## Installation as a regular script

## Using Nix

As far as I know, [Nix](https://search.nixos.org/packages?channel=unstable&query=script-directory) is the only package manager with `sd` pre-packaged (as `nixpkgs.script-directory`).

`sd` is also [available in home manager](https://github.com/nix-community/home-manager/blob/master/modules/programs/script-directory.nix). You can install it by adding something like this to your `~/.config/home-manager/home.nix`:

```nix
{...}: {
  home.programs.script-directory = {
    script-directory = {
      enable = true;
      settings = {
        # SD_ROOT = "${config.home.homeDirectory}/custom-script-directory";
        # SD_EDITOR = "vim";
        # SD_CAT = "bat";
      };
    };
  };
}
```

## Without a package manager

1. Put the `sd` script somewhere on your `PATH`.
2. Put the `_sd` completion script somewhere on your `fpath`.

I like to symlink `sd` to `~/bin`, which is already on my path. If you've cloned this repo to `~/src/sd`, you can do that by running something like:

    $ ln -s ~/src/sd/sd ~/bin/sd

There isn't really a standard place in your home directory to put completion scripts, so unless you've made your own, you'll probably want to add your clone directly to your `fpath`. You should add that to your `.zshrc` file before the line where you call `compinit`. It should look something like this:

    # ~/.zshrc

    fpath=(~/src/sd $fpath)
    autoload -U compinit
    compinit

If you use a zsh framework like [`oh-my-zsh`](https://github.com/ohmyzsh/ohmyzsh), it probably calls `compinit` for you. In that case, just set your `fpath` before you source the framework's initialization script.

Note that changes you make to your `~/.zshrc` will only take effect for *future* shells you create, so to start enjoying `sd` immediately you'll also want to run these commands in your existing shells:

    $ fpath=(~/src/sd $fpath)
    $ compinit

## As a shell function

You can just source `sd` in your `.zshrc` and set up completion manually (as described [above](#installation-as-a-regular-script)), but `sd` is designed to be compatible with shell plugin managers.

### [Antigen](https://github.com/zsh-users/antigen)

Add this line to your `.zshrc`:

```shell
antigen bundle ianthehenry/sd
```

### [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh):

Clone this repo into your custom plugins directory:

```
$ git clone https://github.com/ianthehenry/sd.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/sd
```

And then add it to the plugins list in your `~/.zshrc` before you source `oh-my-zsh`:

```
plugins+=(sd)
source "$ZSH/oh-my-zsh.sh"
```

# bash/fish autocompletion support

Patrick Jackson contributed [an unofficial fish completion script](https://gist.github.com/patricksjackson/5065e4a9d8e825dafc7824112f17a5e6), which should be usable with some modification (as written it does not respect `SD_ROOT`, but it should act as a very good starting point if you use fish).

Bash doesn't support the fancy completion-with-description feature that is sort of the whole point of `sd`, but there are apparently ways to hack something similar.


# Changelog

## v1.1.0 2022-10-30

- fix a bug where `--help` would print every comment in the script

## v1.0.1 2022-04-17

- better error message if `~/sd` does not exist
- better error message if `~/sd` exists but is not a directory

## v1.0.0 2022-02-27

`sd` is now released under the MIT license. There are no functional changes from the pre-1.0 releases.

## v0.3.0 2022-02-26

- scripts now run with the `SD` environment variable set to the directory they were found in
- autocompletion now completes arguments to commands instead of just commands
    - only completes positional file arguments and the built-in flags (like `--help`)
- `sd` now only forks a subshell when invoked as a function
- `sd` now `exec`s scripts instead of `fork`+`exec`
    - this fixes the rare issue where a long-running script could throw errors when it finished if you were editing the `sd` executable itself while the script was running, because `bash` was trying to execute the "rest" of the file and apparently doing so by byte index or something (??)
    - this only affects me

## v0.2.0 2022-02-24

- added per-directory `template` files, to override the `bash` default

## v0.1.1 2021-12-05

- fix a bug where `--new` wouldn't work unless provided with an initial script

## v0.1.0 2021-12-01

- added `--really`
- `dir.help` files are now `dir/help` files

You used to be able to provide a description for a directory called `foo/` by writing a file called `foo.help` as a sibling of that directory.

Now directory help summaries are expected in `foo/help` instead.

This has the sort-of nice effect that `sd foo help` is sometimes similar to `sd foo --help`. Except that the latter also prints out subcommands.
