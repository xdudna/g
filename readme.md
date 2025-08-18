# g

## What is g?

g 是为 Git 命令设计的高效缩写工具旨在通过简洁的字母组合（如 `g j` 对应 `git switch`、`g p` 对应 `git pull` 等）简化日常版本控制操作。

同时，你也可以像使用 `git` 一样使用 `g` 命令。比如你可以使用 `g push`，这依然会执行 `git push`。

例外：g 占用了 `am`, `version` 及 `help` 命令。 但你仍可以使用 `g ver` 来执行 `git version`，`g hp` 来执行 `git help`。
而对于 `am`，`g am` 被用作了 `git commit --amend`，你只能使用 `git am` 来执行 `git am`。

G is an efficient abbreviation tool designed for Git commands. It aims to simplify daily version control operations through concise letter combinations (e.g., `g j` corresponds to `git switch`, `g p` corresponds to `git pull`, etc.).

Additionally, you can use the g command just like you would use the git. 
For example, you can use `g push`, which will still execute `git push`.

Exceptions: The g tool reserves the commands `am`, `version`, and `help`. However, you can still:

- Run `g ver` to execute `git version`;
- Run `g hp` to execute `git help`.

As for `am`: `g am` is used for `git commit --amend`, so you can only run the original `git am` to execute the git am command.

## How to use g?

将 g 加入到环境变量的路径中即可。

You only need to add g to your environment variable path.

## What commands are supported?

g 支持但不限于以下命令：

g supports, but is not limited to, the following commands:

```bash
g a   # git add
g j   # git switch branch
g p   # git pull
g P   # git push 
g cm  # git commit 
g s   # git status -s 
      # ...
```

通过 `g help` 可以查看更多命令。

Run `g help` to view more commands.