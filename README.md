# `sd`: my script directory

I haven't written a real readme yet. I probably will, eventually. In the meantime, [this blog post explains the project pretty well][post].

# Installation

So this isn't, like, distributed anywhere reasonable. Like, it's not... packaged in any package manager that I am aware of. So...

- Put `bin/sd` somewhere on your path.

I like to symlink it to `~/bin`, which is already on my path. If you've cloned this repo to `~/src/sd`, run something like:

    $ ln -s ~/src/sd/bin/sd ~/bin/sd

- Put `completions/_sd` somewhere on your `fpath`.

If you've cloned this repo to `~/src/sd`, add something like this:

```shell
fpath=(~/src/sd/completions $fpath)
```

To your `~/.zshrc` file.

- Set up your initial `~/sd`

This will not be necessary once I rewrite `sd` as something other than a janky bash script, but it is necessary right now: you need to copy all of the files in the `sdefaults/` directory into your own `~/sd`. Or you can set up symlinks:

```shell
mkdir -p "$HOME/sd"
for file in "$HOME"/src/sd/sdefaults/*; do
  if [[ ! -s "$HOME/sd/$(basename "$file")" ]]; then
    ln -s "$file" "$HOME/sd/$(basename "$file")"
  fi
done
```

# Why does this only work in `zsh`

Just because I'm lazy. `bash` completion support is forthcoming. One day...

[post]: https://ianthehenry.com/posts/sd-my-script-directory/
