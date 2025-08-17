extends Control

@onready var character: Sprite2D = $Character
@onready var depth_label: Label = $Depth

var rock_grid: Node2D
var ore_grid: Node2D

# Display constants
var tile_size: int = 16
var grid_width: int = 25
var grid_height: int = 40
var character_grid_pos: Vector2i = Vector2i(12, 20)

var world_texture: Texture2D
var rock_sprites: Array = []
var ore_sprites: Array = []

var _last_rendered_depth: float = -1.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    set_process_input(true)
    world_texture = load("res://assets/tiles/world_tileset.png") as Texture2D

    _connect_game_signals()
    
    setup_rock_grid()
    setup_character()
    render_mining_view()

func _connect_game_signals() -> void:
    GM.game_state.depth_changed.connect(_on_depth_changed)
    GM.game_state.currency_changed.connect(_on_game_state_changed)
    
    GM.inventory_system.inventory_changed.connect(_on_game_state_changed)
    
    GM.mining_system.tile_mined_successfully.connect(_on_tile_mined)
    GM.mining_system.auto_mining_progressed.connect(_on_depth_changed)
    
    GM.mining_tool.tool_upgraded.connect(_on_tool_upgraded)

func setup_rock_grid() -> void:
    if rock_grid: rock_grid.queue_free()
    if ore_grid: ore_grid.queue_free()

    rock_grid = Node2D.new()
    rock_grid.name = "RockGrid"
    add_child(rock_grid)

    ore_grid = Node2D.new()
    ore_grid.name = "OreGrid"
    add_child(ore_grid)
    ore_grid.z_index = 50

    rock_sprites.clear()
    ore_sprites.clear()

    for x in range(grid_width):
        rock_sprites.append([])
        ore_sprites.append([])
        for y in range(grid_height):
            var rs := Sprite2D.new()
            rs.name = "Rock_%d_%d" % [x, y]
            rs.position = Vector2(x * tile_size + tile_size * 0.5, y * tile_size + tile_size * 0.5)
            rs.centered = true
            rock_grid.add_child(rs)
            rock_sprites[x].append(rs)

            var os := Sprite2D.new()
            os.name = "Ore_%d_%d" % [x, y]
            os.position = rs.position
            os.centered = true
            ore_grid.add_child(os)
            ore_sprites[x].append(os)

func setup_character() -> void:
    character.position = Vector2(
        character_grid_pos.x * tile_size + tile_size * 0.5,
        character_grid_pos.y * tile_size + tile_size * 0.5
    )
    var character_texture := load("res://sprites/character.png") as Texture2D
    if character_texture:
        character.texture = character_texture
    else:
        character.texture = create_placeholder_texture(tile_size, tile_size, Color.CYAN)
    character.visible = true
    character.z_index = 100

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var local_pos: Vector2 = rock_grid.to_local(event.position)
        var grid_x: int = int(floor(local_pos.x / tile_size))
        var grid_y: int = int(floor(local_pos.y / tile_size))
        if grid_x >= 0 and grid_x < grid_width and grid_y >= 0 and grid_y < grid_height:
            _handle_tile_click(grid_x, grid_y)

func _handle_tile_click(grid_x: int, grid_y: int) -> void:
    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    var world_row: int = base_world_row + (grid_y - character_grid_pos.y)
    GM.player_mine_tile(Vector2i(grid_x, world_row))

func _on_depth_changed(new_depth: float) -> void:
    if abs(new_depth - _last_rendered_depth) >= WorldData.DEPTH_PER_TILE * 0.5:
        render_mining_view()
        _last_rendered_depth = new_depth

func _on_tile_mined(tile_pos: Vector2i, resources: Array[String]) -> void:
    _update_single_tile(tile_pos)

func _on_game_state_changed(_value = null) -> void:
    _update_depth_label()

func _on_tool_upgraded(tool: MiningTool) -> void:
    # Tool upgrade might affect what we can mine, so re-render
    render_mining_view()

func _update_depth_label() -> void:
    var current_depth: float = GM.game_state.depth
    var rock_name: String = WorldData.get_rock_name_for_depth(current_depth)
    depth_label.text = "Depth: %.1f m (%s)" % [current_depth, rock_name]

func _update_single_tile(world_tile_pos: Vector2i) -> void:
    # Convert world position to grid position
    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    var grid_y: int = world_tile_pos.y - base_world_row + character_grid_pos.y
    var grid_x: int = world_tile_pos.x
    
    # Check if tile is visible on screen
    if grid_x < 0 or grid_x >= grid_width or grid_y < 0 or grid_y >= grid_height:
        return
    
    # Update just this tile
    var tile_depth: float = world_tile_pos.y * WorldData.DEPTH_PER_TILE
    var rock_type: WorldData.RockType = WorldData.get_rock_type_for_depth(tile_depth)
    
    _setup_rock_sprite(rock_sprites[grid_x][grid_y], rock_type, world_tile_pos.x, world_tile_pos.y)
    _setup_ore_sprite(ore_sprites[grid_x][grid_y], world_tile_pos.x, world_tile_pos.y, rock_type)

func render_mining_view() -> void:
    _update_depth_label()

    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))

    for x in range(grid_width):
        for y in range(grid_height):
            var world_row: int = base_world_row + (y - character_grid_pos.y)
            var tile_depth: float = world_row * WorldData.DEPTH_PER_TILE
            var rock_type: WorldData.RockType = WorldData.get_rock_type_for_depth(tile_depth)

            _setup_rock_sprite(rock_sprites[x][y], rock_type, x, world_row)
            _setup_ore_sprite(ore_sprites[x][y], x, world_row, rock_type)

    create_tunnel_effect(current_depth)

func _setup_rock_sprite(sprite: Sprite2D, rock_type: WorldData.RockType, grid_x: int, world_row: int) -> void:
    if rock_type == WorldData.RockType.AIR:
        sprite.visible = false
        return

    sprite.texture = world_texture
    sprite.region_enabled = true
    sprite.region_rect = get_tile_region(WorldData.get_atlas_coords_for_rock(rock_type))
    sprite.modulate = get_deterministic_variation(grid_x, world_row, rock_type)

    if GM.is_tile_mined(grid_x, world_row):
        sprite.visible = false
    else:
        sprite.visible = true
        sprite.modulate.a = 1.0

func _setup_ore_sprite(sprite: Sprite2D, grid_x: int, world_row: int, rock_type: WorldData.RockType) -> void:
    if rock_type == WorldData.RockType.AIR or rock_type == WorldData.RockType.BEDROCK:
        sprite.visible = false
        return
    if GM.is_tile_mined(grid_x, world_row):
        sprite.visible = false
        return

    var ore_name: String = WorldData.get_ore_at_position(grid_x, world_row)
    if ore_name == "" or not WorldData.has_ore_atlas(ore_name):
        sprite.visible = false
        return

    sprite.texture = world_texture
    sprite.region_enabled = true
    sprite.region_rect = get_tile_region(WorldData.get_atlas_coords_for_ore(ore_name))
    sprite.modulate = Color(1, 1, 1, 1)
    sprite.visible = true

func get_deterministic_variation(x: int, world_row: int, rock_type: WorldData.RockType) -> Color:
    var seed_value: int = x * 73856093 ^ world_row * 19349663 ^ int(rock_type) * 83492791
    if seed_value < 0: seed_value = -seed_value
    rng.seed = seed_value
    var brightness: float = rng.randf_range(0.88, 1.12)
    var tint: float = rng.randf_range(0.97, 1.03)
    return Color(brightness * tint, brightness, brightness / tint, 1.0)

func create_tunnel_effect(current_depth: float) -> void:
    var max_row: int = GM.game_state.max_mined_row
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    
    # Create tunnel from surface down to max_mined_row
    for y in range(grid_height):
        var world_row: int = base_world_row + (y - character_grid_pos.y)
        if world_row <= max_row:
            # This row should be tunneled
            for dx in range(-1, 2):  # -1, 0, 1 (3-wide tunnel)
                var tile_x: int = character_grid_pos.x + dx
                if tile_x < 0 or tile_x >= grid_width:
                    continue
                
                if dx == 0:
                    # Center column - always cleared
                    rock_sprites[tile_x][y].visible = false
                    ore_sprites[tile_x][y].visible = false
                else:
                    # Side columns - dimmed if not manually mined
                    if not GM.is_tile_mined(tile_x, world_row):
                        rock_sprites[tile_x][y].modulate.a = 0.4
                        ore_sprites[tile_x][y].modulate.a = 0.4

func get_tile_region(atlas_coords: Vector2i) -> Rect2:
    var tileset_tile_size := Vector2i(16, 16)
    var spacing := Vector2i(0, 0)
    var margin := Vector2i(0, 0)
    var x: int = margin.x + atlas_coords.x * (tileset_tile_size.x + spacing.x)
    var y: int = margin.y + atlas_coords.y * (tileset_tile_size.y + spacing.y)
    return Rect2(x, y, tileset_tile_size.x, tileset_tile_size.y)

func create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture := ImageTexture.new()
    texture.set_image(image)
    return texture

func _on_resized() -> void:
    if rock_grid and character:
        rock_grid.position = Vector2.ZERO
        ore_grid.position = Vector2.ZERO
        character.position = Vector2(
            character_grid_pos.x * tile_size + tile_size * 0.5,
            character_grid_pos.y * tile_size + tile_size * 0.5
        )
