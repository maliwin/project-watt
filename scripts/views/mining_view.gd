# mining_view.gd
# A complete rewrite to handle high-performance, chunk-based world rendering and character visuals.
# This script is a "dumb view" - its only job is to display the state of the world
# and report input. It does not contain any game logic itself.
class_name MiningView
extends Control

# --- Configuration ---
@export var CHUNK_SIZE := 32

const SCANNER_RANGE_ZOOMED_IN := 2
const SCANNER_RANGE_ZOOMED_OUT := 20

# --- Node References ---
@onready var character: Sprite2D = $SubViewportContainer/SubViewport/Character
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var chunk_container: Node2D = $SubViewportContainer/SubViewport/ChunkContainer
@onready var world_manager: WorldManager = $/root/Main/Systems/WorldManager

# --- State ---
var _character_world_pos := Vector2i(0, 0) # A local copy for positioning calculations.
var _is_zoomed_out := false
var _current_scanner_range := SCANNER_RANGE_ZOOMED_IN

# --- Chunk Management ---
var _chunk_nodes: Dictionary = {} # {Vector2i: TileMapLayer} - active visual chunks
var _recycled_chunk_nodes: Array[TileMapLayer] = [] # Pool of inactive nodes to reuse


func _ready() -> void:
    # Event.game_started.connect(_on_game_started)
    
    # Connect to all the signals that will control this view.
    Event.character_logical_position_changed.connect(_on_character_logical_position_changed)
    Event.character_fall_animation_started.connect(_on_character_fall_animation_started)
    Event.tile_mined_successfully.connect(_on_tile_mined_successfully)
    Event.zoom_level_changed.connect(_on_zoom_level_changed)


# --- Event Listeners (How the View is Controlled) ---

func _on_game_started(start_pos: Vector2i):
    # The game is ready. Create our visual assets and start the update loop.
    var tileset = _create_debug_tileset()
    _create_chunk_pool(tileset)
    
    _character_world_pos = start_pos
    character.position = _character_world_pos * Constants.TILE_SIZE
    camera.position = character.position # Snap camera immediately on start
    
    # Now that we are initialized, we can safely start our per-frame logic.
    Ticker.game_tick.connect(_on_game_tick)

func _on_game_tick(_delta: float) -> void:
    _update_camera()
    _update_visible_chunks()

func _on_character_logical_position_changed(new_world_pos: Vector2i):
    _character_world_pos = new_world_pos

func _on_character_fall_animation_started(target_pixel_pos: Vector2, duration: float):
    var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
    tween.tween_property(character, "position", target_pixel_pos, duration)

func _on_tile_mined_successfully(tile_pos: Vector2i, _resources: Array[String]):
    _clear_tile_visual(tile_pos)
    
func _on_zoom_level_changed(p_is_zoomed_out: bool):
    _is_zoomed_out = p_is_zoomed_out
    if _is_zoomed_out:
        _current_scanner_range = SCANNER_RANGE_ZOOMED_OUT
        camera.zoom = Vector2(0.5, 0.5)
    else:
        _current_scanner_range = SCANNER_RANGE_ZOOMED_IN
        camera.zoom = Vector2(1.5, 1.5)
    # NOTE: No need to unload chunks. _update_visible_chunks will handle it.


# --- Visual Logic ---

func _update_camera():
    # Camera smoothly follows the character's visual (tweening) position.
    camera.position = camera.position.lerp(character.position, 0.1)

func _clear_tile_visual(tile_pos: Vector2i):
    var chunk_coord = tile_pos / CHUNK_SIZE
    if _chunk_nodes.has(chunk_coord):
        var chunk_node: TileMapLayer = _chunk_nodes[chunk_coord]
        var tile_local_pos = tile_pos % CHUNK_SIZE
        #chunk_node.set_cell(tile_local_pos, -1) # -1 clears the tile
        chunk_node.erase_cell(tile_local_pos)

func _update_visible_chunks():
    # Dynamically determine the view size based on the actual viewport.
    var view_size_in_tiles = get_viewport_rect().size / (Constants.TILE_SIZE * camera.zoom)
    
    var character_chunk_pos = _character_world_pos / CHUNK_SIZE
    var view_width_in_chunks = ceil(view_size_in_tiles.x / CHUNK_SIZE) + 2 # +2 for buffer
    var view_height_in_chunks = ceil(view_size_in_tiles.y / CHUNK_SIZE) + 2

    var required_chunks: Dictionary = {}
    # Calculate required chunks based on the camera's view, not the character's logical position.
    var camera_world_pos = camera.position / Constants.TILE_SIZE
    var camera_chunk_pos = Vector2i(floor(camera_world_pos.x / CHUNK_SIZE), floor(camera_world_pos.y / CHUNK_SIZE))

    for x in range(-view_width_in_chunks / 2, view_width_in_chunks / 2 + 1):
        for y in range(-view_height_in_chunks / 2, view_height_in_chunks / 2 + 1):
            var chunk_coord = camera_chunk_pos + Vector2i(x, y)
            required_chunks[chunk_coord] = true

    # Unload chunks that are no longer needed.
    for chunk_coord in _chunk_nodes.keys():
        if not required_chunks.has(chunk_coord):
            _unload_chunk(chunk_coord)

    # Request and draw new chunks that have entered the view.
    for chunk_coord in required_chunks:
        if not _chunk_nodes.has(chunk_coord):
            _load_chunk(chunk_coord)

    # Check for and draw any completed chunk data from the generator.
    for chunk_coord in _chunk_nodes:
        var chunk_data = world_manager.get_completed_chunk(chunk_coord)
        if chunk_data:
            _draw_chunk(chunk_coord, chunk_data)

func _load_chunk(chunk_coord: Vector2i):
    if _recycled_chunk_nodes.is_empty():
        push_warning("MiningView ran out of recyclable chunk nodes! The view may appear incomplete.")
        return
        
    var new_chunk_node = _recycled_chunk_nodes.pop_front()
    new_chunk_node.position = chunk_coord * CHUNK_SIZE * Constants.TILE_SIZE
    chunk_container.add_child(new_chunk_node)
    _chunk_nodes[chunk_coord] = new_chunk_node
    
    world_manager.queue_chunk_generation(chunk_coord)

func _unload_chunk(chunk_coord: Vector2i):
    var chunk_node = _chunk_nodes.get(chunk_coord)
    if chunk_node:
        chunk_node.clear()
        chunk_container.remove_child(chunk_node)
        _recycled_chunk_nodes.append(chunk_node)
        _chunk_nodes.erase(chunk_coord)

func _draw_chunk(chunk_coord: Vector2i, chunk_data: Dictionary):
    var chunk_node = _chunk_nodes.get(chunk_coord)
    if not chunk_node: return
    
    # The view's only job is to draw what it's told. No more redundant checks.
    for tile_local_pos in chunk_data:
        var tile = chunk_data[tile_local_pos]
        
        # In a real implementation, you would look up the correct atlas coords
        # for the "rock" and "ore" IDs from a central resource.
        var atlas_coords = Vector2i(0, 0) # Placeholder for "stone"
        if tile.ore == "copper": atlas_coords = Vector2i(1, 0) # Placeholder for "copper"
        
        chunk_node.set_cell(tile_local_pos, 0, atlas_coords)


# --- Setup & Helpers ---

func _create_chunk_pool(tileset: TileSet):
    # Create enough chunk nodes to fill the maximum possible zoomed-out view, plus a buffer.
    var max_view_size = get_viewport_rect().size / (Constants.TILE_SIZE * 0.5) # Using min zoom for max size
    var max_view_width_in_chunks = ceil(max_view_size.x / CHUNK_SIZE) + 4 # +4 for large buffer
    var max_view_height_in_chunks = ceil(max_view_size.y / CHUNK_SIZE) + 4
    
    for i in range(max_view_width_in_chunks * max_view_height_in_chunks):
        var rock_layer := TileMapLayer.new()
        rock_layer.tile_set = tileset
        _recycled_chunk_nodes.append(rock_layer)

func _create_debug_tileset() -> TileSet:
    var tile_set := TileSet.new()
    var atlas_source := TileSetAtlasSource.new()
    var image := Image.create(Constants.TILE_SIZE * 2, Constants.TILE_SIZE, false, Image.FORMAT_RGBA8)
    image.fill_rect(Rect2i(0, 0, Constants.TILE_SIZE, Constants.TILE_SIZE), Color.GRAY) # Stone
    image.fill_rect(Rect2i(Constants.TILE_SIZE, 0, Constants.TILE_SIZE, Constants.TILE_SIZE), Color.DARK_GOLDENROD) # Copper
    atlas_source.texture = ImageTexture.create_from_image(image)
    atlas_source.texture_region_size = Vector2i(Constants.TILE_SIZE, Constants.TILE_SIZE)
    atlas_source.create_tile(Vector2i(0, 0)) # Stone is source_id 0, atlas_coords (0,0)
    atlas_source.create_tile(Vector2i(1, 0)) # Copper is source_id 0, atlas_coords (1,0)
    tile_set.add_source(atlas_source, 0)
    return tile_set
