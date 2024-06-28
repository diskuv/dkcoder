# Changes

## 0.4.0

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
