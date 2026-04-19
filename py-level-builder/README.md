# Python Level Builder

Take in `midi` files, generate an output `json` file which will be used as the beatmap in Godot.

Spec: (hackmd link, private for now)

## Build

Requirements:

-   `uv`: <https://docs.astral.sh/uv/getting-started/installation/>

To build a level:

1.  Create a file structure like:

    ```txt
    levels
     |> <name>
         |> raw
             |> <inst1>
             |   |> <inst_name>_<inst_waveform>.mid
             |> <inst2> ... same contents
             |> ... for as many instruments as you need
    ```

1.  Open a shell in the `py-level-builder` directory
1.  Run the command `uv run level.py build levels/<name>`
1.  Edit the generated file `levels/<name>/raw/tuning.json` to assign metadata, note bands, etc
1.  Re-run the same command
1.  Copy the output folder `levels/<name>/<name>` into `destructive-interference/levels`

Use `uv run level.py build --help` to see documentation on how to use the command.

When re-running the `build` command after adding / changing midi tracks,
you may get errors complaining that the notes in `tuning.json` don't match the auto-generated ones.
Look to options `--force-update-note-props` and `--ignore-checks` for support.
