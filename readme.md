# mlPure

> Pretty, minimal and fast ZSH prompt forked from [Pure](https://github.com/sindresorhus/pure) by [Sindre Sorhus](https://github.com/sindresorhus/).

### Why?

- Add some options and style changes.
- Add asynchronous check for **git stash**.

![](screenshot.png)
![](screenshot-2.png)

## Install

Clone repository.

```bash
git clone https://github.com/loliee/mlpure.git "$HOME/.mlpure"
```

Add prompt functions to path

```
# .zshenv or .zshrc
fpath=( "$HOME/.mlpure" $fpath )
```

## Getting started

Initialize the prompt system (if not so already) and choose `pure`:

```sh
# .zshrc
autoload -U promptinit && promptinit
prompt mlpure
```


## Options

### `PURE_CMD_MAX_EXEC_TIME`

The max execution time of a process before its run time is shown when it exits. Defaults to `5` seconds.

### `PURE_GIT_PULL`

Set `PURE_GIT_PULL=0` to prevent Pure from checking whether the current Git remote has been updated.

### `PURE_GIT_UNTRACKED_DIRTY`

Set `PURE_GIT_UNTRACKED_DIRTY=0` to not include untracked files in dirtiness check. Only really useful on extremely huge repos like the WebKit repo.

### `PURE_GIT_DELAY_DIRTY_CHECK`

Time in seconds to delay git dirty checking for large repositories (git status takes > 2 seconds). The check is performed asynchronously, this is to save CPU. Defaults to `1800` seconds.

### `MLPURE_PROMPT_SYMBOL`

Defines the prompt symbol. The default value is `❯`.

### `PURE_GIT_DOWN_ARROW`

Defines the git down arrow symbol. The default value is `⇣`.

### `PURE_GIT_UP_ARROW`

Defines the git up arrow symbol. The default value is `⇡`.

### `MLPURE_FORCE_DISPLAY_USERNAME`

Set `MLPURE_FORCE_DISPLAY_USERNAME=1` to force username display.

### `MLPURE_GIT_STASH_CHECK`

Set `MLPURE_GIT_STASH_CHECK=1` to cancel stash checking.

### `MLPURE_USERNAME_COLOR`

Username prompt color, defaults to `white`.

### `MLPURE_CURSOR_COLOR_OK`

"previous command success" separator color, defaults to `yellow`.

### `MLPURE_CURSOR_COLOR_K0`

"previous command failed "separator color, defaults to `red`.

### `MLPURE_GIT_STASH_COLOR`

`MLPURE_GIT_STASH_COLOR` define "stash" recycle char's color, defaults to red.
```

## Example

```sh
# .zshrc

autoload -U promptinit && promptinit

# optionally define some options
MLPURE_CMD_MAX_EXEC_TIME=10
MLPURE_FORCE_DISPLAY_USERNAME=1
MLPURE_USERNAME_COLOR=red

prompt mlpure
```

## Tips

**Iterm2**
[Patate Toy](https://github.com/loliee/patatetoy-iterm2) colorscheme.

To have commands colorized as seen in the screenshot install [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).

## Integration

### [prezto](https://github.com/sorin-ionescu/prezto)

Set `zstyle ':prezto:module:prompt' theme 'mlpure'` in `~/.zpreztorc`.

## License

MIT © [Sindre Sorhus](http://sindresorhus.com)
