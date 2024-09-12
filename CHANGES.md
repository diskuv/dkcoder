# Changes

## Pending (2.1.3)

- Standard error is used consistently for logging in `./dk`
- Use quiet `-q` option for `yum install` in `./dk` for Linux, and `--quiet --no-progress` for `apk add`
- bugfix: Consistently use `-qq install --no-install-suggests` for apt-get install

## 0.4.0.2

- Path-based commands can be given to `./dk`. That means `./dk somewhere/DkHello_Std/Hi.ml` will add `somewhere/` to the You directories and run the module `DkHello_Std.Hi`.
  This feature simplifies the 0.4.0 feature which had required `./dk DkRun_V0_4.Run somewhere/DkHello_Std/Hi.ml`.
- **Breaking change**:
  - Default generator is dune (not dune-ide) if non-DkCoder dune-project. That avoids a conflict with existing dune-project based projects.
  - If you have an old checkout of DkHelloScript, DkSubscribeWebhook or SanetteBogue, remove the `dune-project` from that checkout so that DkCoder can regenerate a dune-project annotated for 0.5.0.
- Add `./dk DkFs_C99.Dir [mkdir|rm]` script
- bugfix: Some module ids were not compilable (ex. `SonicScout_Setup.Q`) since they had dots in their first or last two characters.
- bugfix: The squished module ids (ex. `SonicScout_Setup.Qt`) were using the second and third last characters rather than the correct last and second last characters.
- performance: Optimize initial `./dk` install by not copying files. On Windows install time (neglecting download time) dropped from 75 seconds to 6 seconds.
- usability: Detect if terminal attached on Windows, and use ANSI color when terminal attached (except when NO_COLOR or in CI).
- Add DkCoder_Std package that has module and module types that DkCoder scripts implement.
- Rename `DkDev_Std.ExtractSignatures` to `DkDev_Std.Export`. Include writing .cma alongside updated dkproject.jsonc. Pushdown log level from `DkDev_Std.Export` to `codept-lib-dkcodersig`
- Add type equations for `Tr1Logs_Std` so `Logs.level` (etc.) is equivalent to `Tr1Logs_Std.Logs.level`
- Us scripts are now part of a findlib site-lib and can be referenced from other scripts, not just run as standalone scripts.
- `__dkcoder_register` has been renamed `__init` which means it initializes the module, similar to have Python's `__init__` initializes a class.
- Let `__init` be overridable. WARNING: Although today `__init` is only called for the entry script, future DkCoder will call `__init` for all `You` scripts in dependency order. So defining your own `let __init () = ...` as an alternative to `if Tr1EntryName.module_id = __MODULE_ID__ then ...` will eventually break for `You` scripts.
- Add --force option to `DkFs_C99.Dir rm`
- Add `DkFs_C99.Path` and `DkFs_C99.File`.
- Add `os` to `Tr1HostMachine`.
- Add `--kill` to `DkFs_C99.Path rm`
- findlib.conf generated at analysis time rather than __dk.cmake install time

Important Notes

- `open__.ml` is not transitive at compile-time. That means other libraries that use your library may get:

  ```text
  Error: This expression has type Uri.t but an expression was expected of type
          DkCurl_StdO__.Open__.Uri.t
        DkCurl_StdO__.Open__.Uri.t is abstract because no corresponding cmi file was found in path.
  ```

  Use fully-qualified module ids if other libraries will use your scripts.
  A future version of DkCoder may change the error message but won't mandate that you fully qualify
  every module reference (that defeats the purpose for the vast majority of scripts which aren't shared).
  Alternatives include requiring fully qualifing module ids in `.mli` files (but not `.ml`),
  or having an `exports__.ml` that functions as the public compile-transitive version of `open__.ml`.

## 0.4.0.1

- Run using a file path in addition to module id
- Add Tr1Tar
- Expose Logs.Src and Logs.Tag for codept
- bugfix: Do not search for nephews of implicit or optimistic modules
- Upgrade merlin from 4.12-414 to 4.14-414
- bugfix: `[%sample]` was not dedenting when there was a blank line
- Add Tr1String_Ext
- Add `./dk DkStdRestApis_Gen.StripeGen`
- Upgrade to Tezt 4.1.0 which has upstreamed Windows fixes from DkCoder 0.3.0
- Add `Tr1HostMachine` implicit with a ``abi : [`android_arm64v8a|`android_arm32v7a|`android_x86|`android_x86_64|`darwin_arm64|`darwin_x86_64|`linux_arm64|`linux_arm32v6|`linux_arm32v7|`linux_x86_64|`linux_x86|`windows_x86_64|`windows_x86|`windows_arm64|`windows_arm32|`dragonfly_x86_64|`freebsd_x86_64|`netbsd_x86_64|`openbsd_x86_64|`unknown_unknown|`darwin_ppc64|`linux_ppc64|`linux_s390x]`` value

## 0.3.0

- Add cohttp-curl
- Do not distribute .pdb in non-debug builds
- Add Tr1Logs_Std, Tr1Logs_Clap and Tr1Logs_Lwt and Tr1Http_Std and Tr1Uri_Std
- Export base64, ezjsonm, resto and json-data-encoding and uri and cohttp-server-lwt-unix and cohttp-curl-lwt
- bugfix: Stitched modules were not being created if nephews already existed
- bugfix: implicit modules check if known to solver
- bugfix: setting solver state should fully set state
- bugfix: modified aliases means must expand to solve harder
- bugfix: Fix bug with duplicated pending module
- Add simultaneity invariant check of pending and resolved solver states

## 0.2.0

- Support `.mli` interface files
- Libraries can have a `open__.ml` module that will be pre-opened for every script in the library.
  This module is the correct place to supply the DkCoder required module imports without changing existing OCaml code:

  ```ocaml
  module Printf = Tr1Stdlib_V414CRuntime.Printf
  module Bos = Tr1BosStd.Bos
  module Bogue = Tr1Bogue_Std.Bogue
  ```

- A bugfix for SDL logging is included and SDL logging is now enabled.
- Module and library names ending with `__` are reserved for DkCoder internal use.
- `DkDev_Std` is a reserved "Us" library. You cannot redefine this library. Any library that starts with `Dk` is also reserved.
- Add implicit modules (see below)
- Make `__MODULE_ID__` value available to scripts so they can see their own fully qualified module identifiers (ex. `SanetteBogue_Snoke.X.Y.Snoke`)
- Make `__LIBRARY__` value available to scripts so they can see which library they belong (ex. `SanetteBogue_Snoke`)
- Make `__FILE__` value be the Unix-style (forward slashes) relative path of the script to the script directory (ex. `SanetteBogue_Snoke/X/Y/Snoke.ml`).
- `Stdlib.Format` was moved from Tr1Stdlib_V414Base to Tr1Stdlib_V414CRuntime because `Format.printf` does C-based file I/O.
- The `dune` generator and the internal DuneUs generator will use fixed length encoding of the library names.
  This partially mitigates very long paths created by Dune that fail on Windows path limits.
- Added `Tr1Tezt_C` and `Tr1Tezt_Core`.
  - No Runner module is provided since that only connects to Unix.
  - The `Process` module has been removed since it assumes Windows and its dependency `Lwt_process` is buggy on Windows.
  - A `ProcessShexp` is bundled that is a cross-platform, almost API-equivalent of Tezt's `Process`.
    - No `spawn_with_stdin` since difficult to bridge I/O channels between Lwt and Shexp.
    - No `?runner` parameters since Runner is Unix-only.
    - There is an extra method `spawn_of` that accepts a `Shexp.t` process
  - A `ProcessCompat` is bundled that does not assume Windows but still uses a buggy `Lwt_process`. Use for porting old code only.
- The Debug builds are no longer bundled due to Microsoft not allowing those to be distributed. Also speeds install time. Anyone with source code access (ie. DkSDK subscribers) can do debug builds and get meaningful stack traces.
- End of life and a grace period for a version are enforced with messages and errors. They respect the SOURCE_DATE_EPOCH environment variable so setting it to `1903608000` (Apr 28, 2030) can test what it looks like.

### 0.2.0 - Implicit Modules

Implicit modules are modules that are automatically created if you use them. Unlike explicit modules, their content can be based on the structure of the project.

#### 0.2.0 - Tr1Assets.LocalDir

The `v ()` function will populate a cache folder containing all non-ml source code in the `assets__` subfolder of the library directory.
The `v ()` function will return the cache folder.

```ocaml
val v : unit -> string
(** [v ()] is the absolute path of a cache folder containing all the files
    in the `assets__` subfolder of the library directory.

    For example, in a project:

    {v
      <project>    
        ├── dk
        ├── dk.cmd    
        └── src
            └── SanetteBogue_Snoke
                ├── Snoke.ml
                └── assets__
                    ├── SnakeChan-MMoJ.ttf
                    ├── images
                    │   ├── apple.png
                    │   └── snoke_title.png
                    └── sounds
                        └── sol.wav    
    v}

    the ["Snoke.ml"] script would have access to a cached directory from
    [v ()] that contains:

    {v
      <v ()>
      ├── SnakeChan-MMoJ.ttf
      ├── images
      │   ├── apple.png
      │   └── snoke_title.png
      └── sounds
          └── sol.wav    
    v}
    *)
```

#### 0.2.0 - Tr1EntryName

```ocaml
(** The name of the DkCoder library the entry script belongs to.
    Ex: SanetteBogue_Snoke *)
val library : string

(** The simple name of the entry script.
    Ex: Snoke *)
val simple_name : string

(** The fully qualfied module name for the entry script.
    Ex: SanetteBogue_Snoke.Snoke *)
val module_name : string
```

Using the `Tr1EntryName` module, you can mimic the following Python:

```python
if __name__ == "__main__":
    print("Hello, World!")
```

with

```ocaml
let () =
  if Tr1EntryName.module_id = __MODULE_ID__ then
    Tr1Stdlib_V414Io.StdIo.print_endline "Hello, World!"
```

That means you can isolate side-effects when importing other scripts.

#### 0.2.0 - Tr1Version

```ocaml
(** The fully qualified [Run] module corresponding to the current version.
    Ex: DkRun_V0_1.Run *)
val run_module : string

val run_env_url_base : string option
(** The base URL necessary when if launching with {!run_module} when
    [run_module = "DkRun_Env.Run"]. *)

val major_version : int
val minor_version : int
```

### Known problems

#### Windows hung processes

Exiting scripts with Ctrl-C on Windows only exits the Windows batch script, not the actual subprocess.

For now `taskkill /f /im ocamlrunx.exe` will kill these hung processes.

#### Windows STATUS_ACCESS_VIOLATION

On first install for Windows running the `./DkHelloScript/dk DkRun_V0_2.Run -- DkHelloScript_Std.Y33Article --serve`
example gives:

```text
[00:00:22.564] [[32m[1mSUCCESS[0m] (3/18) reproducibility or quick typing
[00:00:22.564] Starting test: focus on what you run
[00:00:22.566] [1m[.\dk.cmd#3] '.\dk.cmd' DkRun_V0_2.Run '--generator=dune' -- DkHelloScript_Std.AndHelloAgain[0m
[ERROR][2024-04-29T00:00:43Z] /Run/
       Failed to run
         C:\Users\WDAGUtilityAccount\DkHelloScript\src\DkHelloScript_Std\Y33Article.ml
         (DkHelloScript_Std.Y33Article). Code fa10b83d.

       Problem: The DkHelloScript_Std.Y33Article script exited with
         STATUS_ACCESS_VIOLATION (0xC0000005) - The instruction at 0x%08lx
       referenced memory at 0x%08lx. The memory could not be %s.
       Solution: Scroll up to see why.
```

Rerunning it works.

### Punted past 0.2.0

- Fetch and use "Them" libraries
  - Adds --cmake-exe (DKCODER_CMAKE_EXE envar) and --ninja-exe (DKCODER_NINJA_EXE envvar) to Run command.
- Libraries can have a `lib__.ml` module that can provide documentation for the library (ex. `MyLibrary_Std`) through a top comment:

  ```ocaml
  (** This is the documentation for your library. *)

  (* Anything else inside lib__.ml will trigger an error *)
  ```

  Documentation hover tips are refreshed on the next run command (ex. `./dk DkHelloScript_Std.N0xxLanguage.Example051`)
- Running `DkDev_Std.ExtractSignatures` will update `dkproject.jsonc` with an `exports` field that has codept signatures.
  The `dkproject.jsonc` will be created if not present.

## 0.1.0

Initial version.
