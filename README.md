# TactiGrid — Strategic Arena

A turn-based tactics game built in **Godot 4.4+**.
Move your units across a 10 × 8 grid, outmanoeuvre enemies, and wipe them out before they reach you.

---

## Requirements

| Tool | Minimum Version |
|------|----------------|
| [Godot Engine](https://godotengine.org/download) | **4.4** (stable) |
| OS   | Windows 10 / macOS 12 / Linux (Ubuntu 22+) |

> No additional plugins or add-ons required.

---

## Project Structure

```
TactiGrid/
├── scenes/
│   ├── main.tscn        ← root scene (auto-detected by project.godot)
│   └── Unit.tscn        ← reusable unit prefab
├── scripts/
│   ├── GameManager.gd   ← turn flow, input, spawning, win/lose
│   ├── GridManager.gd   ← tile states, BFS move range, rendering
│   ├── Unit.gd          ← stats, HP, visuals, damage
│   ├── AIController.gd  ← enemy movement + attack logic
│   └── UIManager.gd     ← HUD: labels, buttons, game-over screen
├── icon.svg
├── project.godot
└── README.md            ← you are here
```

---

## Step-by-Step Assembly in Godot

### 1 — Open the Project

1. Launch **Godot 4**.
2. In the Project Manager click **Import**.
3. Navigate to the `TactiGrid/` folder, select `project.godot`, and click **Import & Edit**.

> Godot will import assets and open the editor automatically.

---

### 2 — Create `Unit.tscn`

> **Skip this step if `scenes/Unit.tscn` already exists in your file system** — Godot will detect it automatically.

1. Go to **Scene → New Scene**.
2. Click **Other Node**, pick **Node2D**, and rename it to `Unit`.
3. In the **Inspector** on the right, click the script icon (📜) and attach `scripts/Unit.gd`.
4. Add child nodes (right-click `Unit` in the Scene panel → **Add Child Node**):

| Name | Type | Settings |
|------|------|---------|
| `SpriteRect` | `ColorRect` | Size `48×48`, Position `-24, -24` |
| `HPLabel`    | `Label`     | Size `48×16`, Position `-24, 14`, Font size `9`, Align Centre |

5. Save the scene: **Scene → Save Scene As** → `scenes/Unit.tscn`.

---

### 3 — Create `main.tscn`

> **Skip if `scenes/main.tscn` already exists.**

Build this exact tree in the **Scene** panel:

```
Main              (Node2D)
├── GridManager   (Node2D)    ← script: GridManager.gd
└── GameManager   (Node)      ← script: GameManager.gd
    ├── AIController (Node)   ← script: AIController.gd
    └── UIManager (CanvasLayer) ← script: UIManager.gd
        ├── TurnLabel         (Label)
        ├── EndTurnButton     (Button)
        ├── UnitInfoPanel     (PanelContainer)
        │   └── UnitInfoLabel (Label)
        └── GameOverPanel     (PanelContainer)
            └── VBox          (VBoxContainer)
                ├── ResultLabel   (Label)
                └── RestartButton (Button)
```

#### Node positions & sizes

| Node | Offset Left | Offset Top | Offset Right | Offset Bottom | Extra |
|------|------------|-----------|-------------|--------------|-------|
| TurnLabel | 10 | 10 | 220 | 42 | Font size 16, text "Player Turn" |
| EndTurnButton | 556 | 8 | 694 | 46 | Text "End Turn" |
| UnitInfoPanel | 10 | 476 | 230 | 592 | — |
| UnitInfoLabel | (layout_mode 2) | — | — | — | Text "Select a unit", Font 11 |
| GameOverPanel | anchors preset **Center**, offset ±130 H, ±70 V | — | — | — | `visible = false` |
| ResultLabel | (layout_mode 2) | — | — | — | Font 22, Align Centre |
| RestartButton | (layout_mode 2) | — | — | — | Text "Play Again" |

4. Save as `scenes/main.tscn`.
5. In **Project → Project Settings → Application → Run**, set **Main Scene** to `scenes/main.tscn`.

---

### 4 — Verify Script Attachments

Open each scene and confirm every script is attached:

| Node path | Script |
|-----------|--------|
| `Main/GridManager` | `scripts/GridManager.gd` |
| `Main/GameManager` | `scripts/GameManager.gd` |
| `Main/GameManager/AIController` | `scripts/AIController.gd` |
| `Main/GameManager/UIManager` | `scripts/UIManager.gd` |
| `Unit` (root of Unit.tscn) | `scripts/Unit.gd` |

---

### 5 — Project Settings

Go to **Project → Project Settings**:

| Setting | Value |
|---------|-------|
| Display → Window → Size → Viewport Width | `704` |
| Display → Window → Size → Viewport Height | `600` |
| Rendering → Environment → Default Clear Color | `#1A1B24` |

---

### 6 — Press Play ▶

Hit **F5** (or the ▶ button). The game should launch with three blue units on the left and three red enemies on the right.

---

## How to Play

| Action | How |
|--------|-----|
| **Select a unit** | Left-click a coloured unit on your side |
| **Move** | Left-click a **blue-highlighted** tile |
| **Attack** | Left-click a **red-highlighted** enemy tile |
| **Deselect** | Left-click any empty, un-highlighted tile |
| **End Turn early** | Click the **End Turn** button (top-right) |

**Win condition:** Eliminate all red enemy units.  
**Lose condition:** All your units are destroyed.

---

## Unit Roster

### Your Units (Blue side)

| Name | HP | Move | Atk Range | Damage | Role |
|------|----|------|-----------|--------|------|
| Soldier | 30 | 3 | 1 | 10 | Balanced |
| Archer  | 20 | 2 | 2 | 8  | Ranged    |
| Knight  | 50 | 2 | 1 | 15 | Tank      |

### Enemies (Red side)

| Name | HP | Move | Atk Range | Damage | Threat |
|------|----|------|-----------|--------|--------|
| Grunt  | 25 | 3 | 1 | 8  | Fast rusher |
| Brute  | 40 | 2 | 1 | 12 | Heavy hitter |
| Sniper | 20 | 2 | 3 | 10 | Long-range danger |

---

## Tile Colour Guide

| Colour | Meaning |
|--------|---------|
| Dark blue | Selected unit's tile |
| Light blue | Reachable move tiles |
| Red | Tiles within attack range |
| Default dark | Normal / impassable |

---

## Architecture Overview

```
GameManager
  ├── Handles all player mouse input (_unhandled_input)
  ├── Delegates AI logic → AIController
  ├── Delegates all HUD updates → UIManager
  └── Reads/writes grid state via → GridManager

GridManager
  └── Owns tile_states dict, BFS, _draw()

Unit
  └── Purely reactive: takes damage, reports to GameManager via game_manager.on_unit_died()

AIController
  └── Stateless per turn; receives enemy_units + player_units each call
```

---

## Expanding the Game

| Feature | Where to start |
|---------|---------------|
| Terrain (forests, walls) | Add `terrain_cost: Dictionary` in `GridManager.gd`, weight BFS in `highlight_move_range` |
| New unit types | Subclass `Unit.gd` (e.g. `Healer.gd`) with overridden stats or a `heal()` method |
| Animated movement | `AIController._tween_move()` already uses a Tween — add a path-trace for the player too |
| Smarter AI | Score tiles by threat in `AIController._process_unit()` |
| Multiple maps | Swap out `GridManager` config or load a new scene per level |
| Sound effects | Call `AudioStreamPlayer` inside `Unit.take_damage()` and `_attack()` |
| Save / Load | Use Godot's `FileAccess` to serialise `player_units` stats between sessions |

---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Nonexistent function 'place_on_grid'` | Unit scene uses wrong script | Re-attach `Unit.gd` to the Unit root node |
| `Invalid get index 'grid_manager'` | `grid_manager` is null | Check `GameManager._ready()` sets it before `_spawn_units()` |
| `Node not found: ../GridManager` | Wrong tree structure | `GridManager` must be a **sibling** of `GameManager` under `Main` |
| `Node not found: $TurnLabel` | UIManager child missing | Add `TurnLabel` as a direct child of `UIManager` (CanvasLayer) |
| Units are invisible | `SpriteRect` sized to 0 | Set `SpriteRect` offset_left/right/top/bottom to -24/24/-24/24 |
| Game freezes on AI turn | Infinite loop in BFS | Ensure `blocked` tiles list is correct — check `_get_occupied_tiles` |

---

## License

MIT — free to use, modify, and distribute.  
Built with [Godot Engine](https://godotengine.org) © Juan Linietsky, Ariel Manzur.
