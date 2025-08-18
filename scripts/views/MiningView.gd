extends Control

@onready var character: Sprite2D = $SubViewportContainer/SubViewport/Character
@onready var rock_layer: TileMapLayer = $SubViewportContainer/SubViewport/RockLayer
@onready var ore_layer: TileMapLayer = $SubViewportContainer/SubViewport/OreLayer
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D

const ZOOM_OUT_LEVEL = 1.0
const ZOOM_OUT_WIDTH = 25
const ZOOM_IN_LEVEL = 3.5 
const ZOOM_IN_WIDTH = 7

var is_zoomed_in: bool = false

var tile_size: int = 16
var grid_width: int = ZOOM_OUT_WIDTH
var grid_height: int = 40
var character_grid_pos: Vector2i

var _last_rendered_depth: float = -1.0

func _ready() -> void:
    set_process_input(false)
    set_process_unhandled_input(true)
    _connect_game_signals()

    var tile_set := TileSet.new()
    var atlas_source := TileSetAtlasSource.new()
    atlas_source.texture = load("res://assets/tiles/maja_tileset2.png")
    atlas_source.texture_region_size = Vector2i(tile_size, tile_size)
    
    for x in range(6):
        atlas_source.create_tile(Vector2i(x, 0))
    for x in range(5):
        atlas_source.create_tile(Vector2i(x, 1))

    tile_set.add_source(atlas_source, 0)

    rock_layer.tile_set = tile_set
    ore_layer.tile_set = tile_set
    
    setup_character()
    _apply_zoom()
    render_mining_view()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var world_pos = camera.get_canvas_transform().affine_inverse() * get_global_mouse_position()
        var grid_pos = rock_layer.local_to_map(world_pos)
        
        if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
            _handle_tile_click(grid_pos.x, grid_pos.y)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            is_zoomed_in = true
            _apply_zoom()
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            is_zoomed_in = false
            _apply_zoom()

func _connect_game_signals() -> void:
    GM.game_state.depth_changed.connect(_on_depth_changed)
    GM.game_state.currency_changed.connect(_on_game_state_changed)
    # GM.inventory_system.inventory_changed.connect(_on_game_state_changed)
    GM.mining_system.tile_mined_successfully.connect(_on_tile_mined)
    GM.mining_system.auto_mining_progressed.connect(_on_depth_changed)
    GM.mining_tool.tool_upgraded.connect(_on_tool_upgraded)

func setup_character() -> void:
    # This function is now only responsible for the character's appearance, not its position.
    var character_texture := load("res://sprites/character.png") as Texture2D
    if character_texture:
        character.texture = character_texture
    else:
        character.texture = create_placeholder_texture(tile_size, tile_size, Color.CYAN)
    character.visible = true
    character.z_index = 100

func _apply_zoom() -> void:
    if is_zoomed_in:
        camera.zoom = Vector2(ZOOM_IN_LEVEL, ZOOM_IN_LEVEL)
        grid_width = ZOOM_IN_WIDTH
    else:
        camera.zoom = Vector2(ZOOM_OUT_LEVEL, ZOOM_OUT_LEVEL)
        grid_width = ZOOM_OUT_WIDTH
    
    character_grid_pos = Vector2i(grid_width / 2, grid_height / 2)
    
    # Calculate the center position of the character's tile.
    var center_pos = Vector2(
        character_grid_pos.x * tile_size + tile_size * 0.5,
        character_grid_pos.y * tile_size + tile_size * 0.5
    )
    # Set BOTH the camera and the character to this exact same position.
    camera.position = center_pos
    if is_node_ready(): # Check if the node is ready before accessing children
        character.position = center_pos
    
    render_mining_view()

func _handle_tile_click(grid_x: int, grid_y: int) -> void:
    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    var world_row: int = base_world_row + (grid_y - character_grid_pos.y)
    
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x
    var world_col: int = base_world_col + grid_x

    GM.player_mine_tile(Vector2i(world_col, world_row))

func _on_depth_changed(new_depth: float) -> void:
    if abs(new_depth - _last_rendered_depth) >= WorldData.DEPTH_PER_TILE * 0.5:
        render_mining_view()
        _last_rendered_depth = new_depth

func _on_tile_mined(tile_pos: Vector2i, _resources: Array[String]) -> void:
    _update_single_tile(tile_pos)

func _on_game_state_changed(_value = null) -> void:
    var depth_label_node = find_child("Depth", true, false)
    if depth_label_node:
        var current_depth: float = GM.game_state.depth
        var rock_name: String = GM.world_data.get_rock_name_for_depth(current_depth)
        depth_label_node.text = "Depth: %.1f m (%s)" % [current_depth, rock_name]

func _on_tool_upgraded(_tool: MiningTool) -> void:
    render_mining_view()

func _update_single_tile(world_tile_pos: Vector2i) -> void:
    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / GM.world_data.DEPTH_PER_TILE))
    var grid_y: int = world_tile_pos.y - base_world_row + character_grid_pos.y
    
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x
    var grid_x: int = world_tile_pos.x - base_world_col

    if grid_x < 0 or grid_x >= grid_width or grid_y < 0 or grid_y >= grid_height:
        return

    var map_coords = Vector2i(grid_x, grid_y)
    rock_layer.set_cell(map_coords, -1)
    ore_layer.set_cell(map_coords, -1)

func render_mining_view() -> void:
    if not is_node_ready():
        return
    
    _on_game_state_changed()
    
    rock_layer.clear()
    ore_layer.clear()

    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / GM.world_data.DEPTH_PER_TILE))
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x

    for x in range(grid_width):
        for y in range(grid_height):
            var world_row: int = base_world_row + (y - character_grid_pos.y)
            var world_col: int = base_world_col + x
            
            if GM.is_tile_mined(world_col, world_row):
                continue

            var tile_depth: float = world_row * WorldData.DEPTH_PER_TILE
            var rock_type: WorldData.RockType = GM.world_data.get_rock_type_for_depth(tile_depth)
            var map_coords = Vector2i(x,y)

            if rock_type != WorldData.RockType.AIR:
                var rock_atlas_coords = GM.world_data.get_atlas_coords_for_rock(rock_type)
                rock_layer.set_cell(map_coords, 0, rock_atlas_coords)
                
                var ore_name: String = GM.world_data.get_ore_at_position(world_col, world_row, GM.mining_system.auto_mine_column)
                if ore_name != "" and GM.world_data.has_ore_atlas(ore_name):
                    var ore_atlas_coords = GM.world_data.get_atlas_coords_for_ore(ore_name)
                    ore_layer.set_cell(map_coords, 0, ore_atlas_coords)

    create_tunnel_effect(current_depth)

func create_tunnel_effect(current_depth: float) -> void:
    var max_row: int = GM.game_state.max_mined_row
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x
    
    for y in range(grid_height):
        var world_row: int = base_world_row + (y - character_grid_pos.y)
        if world_row <= max_row:
            var world_col: int = GM.auto_mine_x
            var grid_x: int = world_col - base_world_col
            
            if grid_x >= 0 and grid_x < grid_width:
                var grid_pos = Vector2i(grid_x, y)
                if not GM.is_tile_mined(world_col, world_row):
                    rock_layer.set_cell(grid_pos, -1)
                    ore_layer.set_cell(grid_pos, -1)

func create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture := ImageTexture.new()
    texture.set_image(image)
    return texture
