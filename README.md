# Naruto R36S

<p align="center">
  <img src="screenshot.png" alt="Naruto R36S screenshot" width="32%">
  <img src="screenshot2.png" alt="Naruto R36S battle screenshot" width="32%">
  <img src="screenshot3.png" alt="Naruto R36S gamepad mapper" width="32%">
</p>

**Naruto R36S** is a ready-to-run PortMaster build of a fan-made Naruto 2D
fighting game, prepared for the R36S handheld and other PortMaster-compatible
devices running the `aarch64` architecture.

The game is powered by **Ikemen GO**, an open source fighting game engine with
M.U.G.E.N resource compatibility, modern portability, scripting support, and
expanded game modes. This repository contains the canonical game tree,
PortMaster launchers, development tools, and the release packaging workflow.

## Features

- Naruto-based 2D fighting game powered by Ikemen GO.
- Ready-to-run PortMaster package with no external runtime declared.
- Main launcher: `NarutoR36S.sh`.
- Debug launcher: `NarutoR36SDebug.sh`.
- Gamepad remapping launcher: `NarutoR36SGamepad.sh`.
- 157 character folders included under `chars/`.
- 35 stage definitions included under `stages/`.
- Movelists in `moves/` and story content support in `storymode/`.
- Included ARM64 binary: `ikemen_linux.aarch64`.
- Included x64 desktop binary for local testing: `Ikemen_GO_Linux`.

## Installation On R36S / PortMaster

1. Build the port zip:

   ```bash
   tools/build-portmaster-release.sh
   ```

2. The package is written to:

   ```text
   dist/naruto-r36s.zip
   ```

3. Install the zip with PortMaster, or extract it into your firmware's ports
   folder. The final layout should look like this:

   ```text
   ports/
   |-- NarutoR36S.sh
   |-- NarutoR36SDebug.sh
   |-- NarutoR36SGamepad.sh
   `-- naruto-r36s/
       |-- chars/
       |-- data/
       |-- stages/
       |-- storymode/
       `-- ikemen_linux.aarch64
   ```

4. Launch **Naruto R36S** from the ports menu.

To remap controls, open **Naruto R36S Gamepad** from Ports. To run the game with
debug output, use **Naruto R36S (Debug)**.

## Controls

| Button | Action |
| --- | --- |
| Y | Low punch |
| X | High punch |
| B | Low kick |
| A | High kick |
| Start | Menu |
| Select | Taunt |

## Local Development

The repository root is the canonical game tree. To run the game locally on
Linux x64:

```bash
tools/run-x64.sh
```

For a quick startup smoke test:

```bash
tools/smoke-x64.sh
```

The smoke test runs Ikemen in windowed mode, with music and sound disabled, while
updating characters and stages. If the UI stays alive until the timeout, the
test is treated as successful.

## Packaging

The release script stages the PortMaster layout and builds the final package:

```bash
tools/build-portmaster-release.sh
```

Default output:

```text
dist/naruto-r36s.zip
```

You can also choose a custom output path:

```bash
tools/build-portmaster-release.sh --output dist/my-build.zip
```

Or preview what would be copied without creating the zip:

```bash
tools/build-portmaster-release.sh --dry-run
```

During packaging, the script excludes x64 binaries, editor tools, logs,
temporary files, Windows metadata, and old staging folders. The final package
uses the `naruto-r36s/` data folder so it can coexist with the official Ikemen
port.

## Repository Layout

```text
.
|-- NarutoR36S.sh              # Main PortMaster launcher
|-- NarutoR36SDebug.sh         # Ikemen debug launcher
|-- NarutoR36SGamepad.sh       # SDL gamepad remapping launcher
|-- chars/                     # Characters
|-- data/                      # Ikemen data, configuration, and screenpack
|-- external/                  # External config, gamecontrollerdb, icons
|-- font/                      # Fonts
|-- lifebars/                  # Lifebars
|-- moves/                     # Movelists
|-- save/                      # Save data and configuration
|-- sound/                     # Sound and music
|-- stages/                    # Stages
|-- storymode/                 # Story mode scripts and catalog
|-- tools/                     # Development and release scripts
|-- gameinfo.xml               # Frontend game metadata
`-- port.json                  # PortMaster metadata
```

## Port Metadata

- Name: `Naruto R36S`
- PortMaster archive: `naruto-r36s.zip`
- Architecture: `aarch64`
- Porter: `leonkasovan`
- Engine: `Ikemen GO`
- Status: `Ready to run`
- Data folder: `naruto-r36s/`

## Engine

Ikemen GO aims for compatibility with M.U.G.E.N 1.1 Beta resources while adding
its own engine features, including advanced scripting, expanded game modes, and
better cross-platform support. This port uses that foundation to run the Naruto
content inside the PortMaster environment.

Learn more:

- Ikemen GO: <https://github.com/ikemen-engine/Ikemen-GO>
- Ikemen GO Wiki: <https://github.com/ikemen-engine/Ikemen-GO/wiki>
- M.U.G.E.N documentation: <https://www.elecbyte.com/mugendocs-11b1/mugen.html>

## Licenses And Credits

Thanks to the **Ikemen GO** team for developing and releasing the engine.

This is a fan-made project. Naruto and related marks belong to their respective
owners. See the included license files as well:

- `License.txt`
- `ScreenpackLicense.txt`
- `licenses/License.txt`
