[slack-link]: https://fisherman-wharf.herokuapp.com
[slack-badge]: https://fisherman-wharf.herokuapp.com/badge.svg

[![Slack][slack-badge]][slack-link]

# Autoenvstack

Make your fish feel better in the environment of trees.

(or improved version of [autoenvfish](https://github.com/idan/autoenvfish))

[Fish](https://github.com/fish-shell/fish-shell) plugin. Once installed, it will do essentially the following

* if you enter some directory and there's `.env.fish` inside, it will be sourced
* if you leave that directory, the file will be "unsourced"

"Unsourcing" means restoring back global shell variables (exported or not). There could be multiple `.env.fish` on different levels of folder structure. Diving into such tree with a single `cd` command would cause them to be sourced in order. Global variables are retained at each level, so going back would unsource files in reversed order. It works similarly to the concept of local scope variables in some programming languages, including fish.

### Install

With [fisherman](https://github.com/fisherman/fisherman)

```
fisher autoenvstack
```

### Example

In `~/play/.env.fish` `settitle` sets global variable that is displayed both in the title and command prompt.

In both `~/play/scrapy/.env.fish` and `~/play/flask/.env.fish` Python virtual environment is activated.

By moving around, files are sourced and unsourced, eventually restoring the initial state of the global variables.

![screenshot](https://raw.githubusercontent.com/fisherman/autoenvstack/doc/example_session.png)

### Bugs

If under some circumstances autoenvstack removes all your globally declared variables (no colors, git complains), clean up the cache of universal variables:

```
rm -f ~/.config/fish/fishd.*
```
