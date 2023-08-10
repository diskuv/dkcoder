# Developing

When running dktool scripts inside a git clone of `dktool`, the
commands will be prefixed with `user.`.

For example, run `./dk user.dksdk.cmake.link` within a git clone of 'dktool'
to test it. Then, after your change is committed and push, other projects
will see that command as `./dk dksdk.cmake.link`.
