# Agent Guidelines for Sand Game

## Project Type
Godot 4.3 game project using GDScript. Desert survival game with 3D terrain generation, physics objects, and player mechanics.

## Build/Test Commands
- **Run Game**: Open project in Godot Editor and press F5, or use `godot --headless` for headless testing
- **Export**: Use Godot's export presets (configured in export_presets.cfg)
- **No traditional build/lint/test commands** - Godot handles compilation internally

## Code Style Guidelines

### File Structure
- Main scenes: `*.tscn` files with corresponding `*.gd` scripts
- Source code organized in `src/` directory by feature (ui/, object/, environment/, etc.)
- Textures and assets in `texture/` directory

### GDScript Conventions
- **Exports**: Use `@export` for inspector properties, group with `@export_category("Name")`
- **Node References**: Use `@onready var node = $NodePath` for scene tree references
- **Signals**: Declare with `signal signal_name` and connect with `.connect()`
- **Types**: Use explicit typing `var name: Type` and `func name() -> ReturnType:`
- **Constants**: Use UPPER_CASE for constants and enums

### Naming Conventions
- **Variables**: snake_case (`current_health`, `is_carrying_item`)
- **Functions**: snake_case (`_physics_process`, `take_damage`)
- **Classes**: PascalCase for class names
- **Nodes**: PascalCase for scene node names
- **Files**: snake_case.gd for scripts

### Code Organization
- Group exports by category using `@export_category()`
- Use `#==> SECTION <==` comments for major code sections
- Private functions start with underscore `_private_function()`
- Use `func _ready():` for initialization, `func _process(delta):` for frame updates