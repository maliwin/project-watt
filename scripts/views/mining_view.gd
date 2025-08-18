extends Control

@onready var character: Sprite2D = $SubViewportContainer/SubViewport/Character
@onready var rock_layer: TileMapLayer = $SubViewportContainer/SubViewport/RockLayer
@onready var ore_layer: TileMapLayer = $SubViewportContainer/SubViewport/OreLayer
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
# FIX: Add a reference to the SubViewportContainer to get its position
@onready var subviewport_container: SubViewportContainer = $SubViewportContainer

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
var _camera_center_pos: Vector2

func _ready() -> void:
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
    
    _last_rendered_depth = GM.game_state.depth
    
    setup_character()
    _apply_zoom()
    render_mining_view()


func _connect_game_signals() -> void:
    Event.depth_changed.connect(_on_depth_changed)
    Event.currency_changed.connect(_on_game_state_changed)
    Event.tile_mined_successfully.connect(_on_tile_mined)
    Event.auto_mining_progressed.connect(_on_depth_changed)
    
    Event.screen_clicked.connect(_on_screen_clicked)
    Event.zoom_level_changed.connect(_on_zoom_level_changed)
    
    # BUGFIX: Connect to state changes to reset the view.
    Event.state_changed.connect(_on_player_state_changed)

# BUGFIX: This function ensures the view resets when a mining session starts.
func _on_player_state_changed(new_state: GameState.PlayerState):
    if new_state == GameState.PlayerState.MINING:
        # Sync the view's internal depth with the official game depth.
        _last_rendered_depth = GM.game_state.depth
        # Force an immediate redraw to show the correct starting location.
        render_mining_view()

func setup_character() -> void:
    var character_texture := load("res://sprites/character.png") as Texture2D
    if character_texture:
        character.texture = character_texture
    else:
        character.texture = create_placeholder_texture(tile_size, tile_size, Color.CYAN)

func _apply_zoom() -> void:
    if is_zoomed_in:
        camera.zoom = Vector2(ZOOM_IN_LEVEL, ZOOM_IN_LEVEL)
        grid_width = ZOOM_IN_WIDTH
    else:
        camera.zoom = Vector2(ZOOM_OUT_LEVEL, ZOOM_OUT_LEVEL)
        grid_width = ZOOM_OUT_WIDTH
    
    character_grid_pos = Vector2i(grid_width / 2, grid_height / 2)
    
    _camera_center_pos = Vector2(
        character_grid_pos.x * tile_size + tile_size * 0.5,
        character_grid_pos.y * tile_size + tile_size * 0.5
    )
    camera.position = _camera_center_pos
    character.position = _camera_center_pos
    
    render_mining_view()

func _handle_tile_click(grid_x: int, grid_y: int) -> void:
    if abs(grid_x - character_grid_pos.x) > 1 or abs(grid_y - character_grid_pos.y) > 1:
        return

    var current_depth: float = GM.game_state.depth
    var base_world_row: int = int(floor(current_depth / WorldData.DEPTH_PER_TILE))
    var world_row: int = base_world_row + (grid_y - character_grid_pos.y)
    
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x
    var world_col: int = base_world_col + grid_x

    GM.player_mine_tile(Vector2i(world_col, world_row))

func _on_depth_changed(new_depth: float) -> void:
    var fall_pixels = (new_depth - _last_rendered_depth) / WorldData.DEPTH_PER_TILE * tile_size

    if abs(fall_pixels) < 1.0:
        if _last_rendered_depth != new_depth:
            _last_rendered_depth = new_depth
            render_mining_view()
        return

    character.position.y -= fall_pixels
    
    _last_rendered_depth = new_depth
    render_mining_view()

    var tween = create_tween()
    var resting_y_pos = _camera_center_pos.y
    tween.tween_property(character, "position:y", resting_y_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

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
    var base_world_row: int = int(floor(_last_rendered_depth / GM.world_data.DEPTH_PER_TILE))
    var grid_y: int = world_tile_pos.y - base_world_row + character_grid_pos.y
    
    var base_world_col: int = GM.auto_mine_x - character_grid_pos.x
    var grid_x: int = world_tile_pos.x - base_world_col

    if grid_x < 0 or grid_x >= grid_width or grid_y < 0 or grid_y >= grid_height:
        return

    var map_coords = Vector2i(grid_x, grid_y)
    rock_layer.set_cell(map_coords, -1)
    ore_layer.set_cell(map_coords, -1)

func render_mining_view() -> void:
    rock_layer.clear()
    ore_layer.clear()
    
    var base_world_row: int = int(floor(_last_rendered_depth / GM.world_data.DEPTH_PER_TILE))
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

func create_placeholder_texture(width: int, height: int, color: Color) -> ImageTexture:
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture := ImageTexture.new()
    texture.set_image(image)
    return texture

func _on_screen_clicked(screen_position: Vector2) -> void:
    # FIX: Convert global screen coordinates to local coordinates within the viewport container
    var local_pos = subviewport_container.get_global_transform().affine_inverse() * screen_position
    
    # Now use the corrected local position to calculate the world position inside the viewport
    var world_pos = camera.get_canvas_transform().affine_inverse() * local_pos
    var grid_pos = rock_layer.local_to_map(world_pos)
    
    if grid_pos.x >= 0 and grid_pos.x < grid_width and grid_pos.y >= 0 and grid_pos.y < grid_height:
        _handle_tile_click(grid_pos.x, grid_pos.y)

func _on_zoom_level_changed(zoom_in: bool) -> void:
    is_zoomed_in = zoom_in
    _apply_zoom()
