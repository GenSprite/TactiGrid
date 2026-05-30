# TactiGrid: Strategic Arena — Godot 4 Setup Guide

## Project Structure

```
TactiGrid/
├── scripts/
│   ├── GameManager.gd
│   ├── GridManager.gd
│   ├── Unit.gd
│   ├── AIController.gd
│   └── UIManager.gd
└── scenes/
    ├── Main.tscn       ← root scene
    └── Unit.tscn       ← unit prefab
```

---

## Step 1 — Create Unit.tscn

1. In Godot, go **Scene → New Scene**.
2. Root node: **Node2D**, rename to `Unit`.
3. Attach script: `scripts/Unit.gd`
4. Add children:
   - **ColorRect** (rename to `SpriteRect`)
     - Size: `48 x 48`
     - Position: `-24, -24`  (centers it on the node)
   - **Label** (rename to `HPLabel`)
     - Position: `-24, 14`
     - Size: `48 x 16`
     - Horizontal alignment: Center
     - Font size: 10
5. Save as `scenes/Unit.tscn`.

---

## Step 2 — Create Main.tscn

1. **Scene → New Scene** → Root node: **Node2D**, rename to `Main`.
2. Add children in this order:

```
Main  (Node2D)
├── GridManager   (Node2D)  ← attach scripts/GridManager.gd
├── GameManager   (Node)    ← attach scripts/GameManager.gd
│   ├── AIController (Node) ← attach scripts/AIController.gd
│   └── UIManager (CanvasLayer) ← attach scripts/UIManager.gd
│       ├── TurnLabel   (Label)
│       ├── EndTurnButton (Button)
│       ├── UnitInfoPanel (PanelContainer)
│       │   └── UnitInfoLabel (Label)
│       └── GameOverPanel (PanelContainer)
│           ├── ResultLabel (Label)
│           └── RestartButton (Button)  [optional]
```

### Node positions / sizes (anchors top-left unless noted)

| Node           | Position       | Size        | Text / Notes               |
|----------------|----------------|-------------|----------------------------|
| TurnLabel      | (10, 10)       | (200, 32)   | "Player Turn"              |
| EndTurnButton  | (560, 10)      | (120, 36)   | "End Turn"                 |
| UnitInfoPanel  | (10, 530)      | (200, 100)  | —                          |
| UnitInfoLabel  | (0, 0)         | (200, 100)  | "Select a unit"            |
| GameOverPanel  | (220, 220)     | (200, 100)  | Centred on screen          |
| ResultLabel    | (0, 20)        | (200, 40)   | "" (set at runtime)        |

3. Save as `scenes/Main.tscn` and set it as **Main Scene** in Project Settings.

---

## Step 3 — Wire @onready references

Open **GameManager.gd** — the `@onready` paths assume this hierarchy:
```
$GridManager     → the GridManager Node2D child
$AIController    → child of GameManager
$UIManager       → child of GameManager
```
Adjust if your tree differs.

Open **UIManager.gd** — it expects:
```
$TurnLabel
$UnitInfoPanel/UnitInfoLabel
$EndTurnButton
$GameOverPanel
$GameOverPanel/ResultLabel
```

---

## Step 4 — Project Settings

- **Display > Window > Size**: 704 × 600  (10 cols × 64px = 640, + 64px HUD margin)
- **Rendering > Environment > Default Clear Color**: `#1a1b24`

---

## How to Play

| Action             | How                                           |
|--------------------|-----------------------------------------------|
| Select unit        | Left-click a **blue/green/yellow** unit       |
| Move               | Left-click a **blue-highlighted** tile        |
| Attack             | Left-click a **red-highlighted** enemy tile   |
| Deselect           | Left-click an empty tile                      |
| End turn early     | Click the **End Turn** button (top-right)     |

The AI automatically moves and attacks during the Enemy Turn.  
Win by eliminating all **red** enemy units. Lose if all your units die.

---

## Expanding the Game (future iterations)

- **Terrain types** — add a `terrain_cost` dict in GridManager for forests/walls  
- **Unit classes** — subclass Unit.gd for Healer, Tank, Ranger with special abilities  
- **Animations** — use AnimationPlayer or Tween to slide units along paths  
- **Smarter AI** — score moves by threat-assessment in AIController  
- **Multiple maps** — load different GridManager configs per level  
- **Audio** — hook `AudioStreamPlayer` nodes into take_damage() and _attack()
