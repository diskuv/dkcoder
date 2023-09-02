# ./dk

The recommended way to execute DkML, DkSDK and Second OCaml build scripts is with the help of the `./dk` tool.
The `./dk` tool runs the build script you specify, downloading it beforehand if necessary.
As a result, you can get up and running quickly without having to follow manual installation steps.
*Gradle users: If that sounds like the easy-to-use Gradle Wrapper, that is on purpose!*

The `./dk` tool is compatible with Windows PowerShell, macOS and desktop Linux.
> It can also run on Windows Command Prompt if you invoke it with `.\dk` rather than `./dk`.

## Installing

In Windows PowerShell, macOS and desktop Linux:

```sh
git clone https://gitlab.com/diskuv/dktool.git
dktool/dk user.dkml.wrapper.upgrade HERE
./dk dkml.wrapper.upgrade DONE
```

In Windows Command Prompt:

```dosbatch
git clone https://gitlab.com/diskuv/dktool.git
dktool\dk user.dkml.wrapper.upgrade HERE
.\dk dkml.wrapper.upgrade DONE
```
