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

## Quiet Mode

Any command that ends in `Quiet`, like `./dk DkRun_Env.RunQuiet`, will not print messages while dk initializes itself.
However, if `sudo` is required for elevation, then commands will be echoed to the terminal.

## Licenses

`dktool` is available under the Open Software License version 3.0,
<https://opensource.org/license/osl-3-0-php/>. A guide to the Open Software License version 3.0 is available at
<https://rosenlaw.com/OSL3.0-explained.htm>.

### 7-Zip

`dk.cmd` downloads parts of the 7-Zip program. 7-Zip is licensed under the GNU LGPL license. The source code for 7-Zip can be found at <www.7-zip.org>. Attribute requirements are available at <https://www.7-zip.org/faq.html>.
