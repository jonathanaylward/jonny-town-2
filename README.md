# Bush Finder

A third-person Godot 4.6 scene: walk a stylized forest, orbit the camera, and respawn if you fall off the terrain. The playable web build is at [bushfinder.jonnybyjonny.com](https://bushfinder.jonnybyjonny.com/).

The Godot project name is `JonnyTown2`. This repository is the source. The site is a separate HTML5 export.

## Run

1. Install [Godot 4.6](https://godotengine.org/) with the Forward+ renderer.
2. Open `project.godot`.
3. Press Play. The main scene is `main.tscn`.

Godot will recreate the ignored `.godot/` folder on first open.

| Input | Action |
| --- | --- |
| W A S D | Move |
| Space | Jump |
| Mouse | Look |
| Arrow keys | Look |
| Esc | Release the cursor |

## Project layout

- `player.gd` and `player.tscn` — movement, jump, camera orbit, and fall recovery
- `quest_ui.gd` — click-to-play overlay and the controls HUD
- `main.tscn` — world, Terrain3D, lighting, and the looping music track
- `grass_field.gd`, `base-ground-undulations.gd`, and `ground.gdshader` — grass and ground
- `demo/` — Terrain3D sample content shipped with the plugin
- `addons/terrain_3d` — terrain plugin used by the world
- `addons/godot_mcp` — editor plugin only. It connects to `ws://127.0.0.1:6505` and is not part of gameplay

## Web export

The Web export preset writes `../bush-finder/BushFinder.html`. Rename that file to `index.html` when uploading it as a static site. That export folder is build output and is not part of this repository.

## Third-party material

| Material | License |
| --- | --- |
| [Terrain3D](https://github.com/TokisanGames/Terrain3D) in `addons/terrain_3d` | MIT. See `addons/terrain_3d/LICENSE.txt`. |
| [KayKit Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) ranger and animations. The grass mesh in `mesh/Grass_2_Mesh.res` is from [KayKit Forest](https://kaylousberg.itch.io/kaykit-forest). | CC0 1.0. Kay Lousberg asks that unmodified copies not be resold. |
| ambientCG textures under `demo/assets/textures` | CC0 1.0. See `demo/assets/textures/asset_licenses.txt`. |
| Godot MCP addon | Vendored editor plugin. This copy has no license file. |

Scripts and scenes written for this project are not under a separate open-source license.

The looping track is a local file, `The_Saltwater_Summit.mp3`, and it is gitignored. The scene still references it, so playback works on a machine that has the file.
