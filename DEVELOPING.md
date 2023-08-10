# Developing

## Rebasing

Do **not rebase**. `cmake/FindDkToolScripts.cmake` relies on `FetchContent`,
which in turn relies on `git` fast forward pulls. You will **break everybody**
if you rebase and then push.

> If a pushed rebase does happen, restore the HEAD to the old commit and then do a force push.

## Local `user.` prefix

When running dktool scripts inside a git clone of `dktool`, the
commands will be prefixed with `user.`.

For example, run `./dk user.dksdk.cmake.link` within a git clone of 'dktool'
to test it. Then, after your change is committed and push, other projects
will see that command as `./dk dksdk.cmake.link`.
