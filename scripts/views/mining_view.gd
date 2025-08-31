# mining_view.gd
# A complete rewrite to handle high-performance, chunk-based world rendering and character visuals.
# This script is a "dumb view" - its only job is to display the state of the world
# and report input. It does not contain any game logic itself.
class_name MiningView
extends Control

const SCANNER_RANGE_ZOOMED_IN := 2
const SCANNER_RANGE_ZOOMED_OUT := 20

# TODO: should this be here? it's fine for now ig
const ROCK_ID_TO_ATLAS := {
    "dirt": Vector2i(1, 0),
    "stone": Vector2i(2, 0),
    "deep_stone": Vector2i(3, 0),
    "bedrock": Vector2i(4, 0),
    "lava_rock": Vector2i(5, 0)
}

const ORE_ID_TO_ATLAS := {
    "copper": Vector2i(4, 1),
    "iron": Vector2i(0, 1),
    "silver": Vector2i(1, 1),
    "gold": Vector2i(2, 1),
    "obsidian": Vector2i(3, 1)
}

# --- Node References ---
@onready var character: Sprite2D = $SubViewportContainer/SubViewport/Character
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var chunk_container: Node2D = $SubViewportContainer/SubViewport/ChunkContainer
@onready var world_manager: WorldManager = $/root/Main/Systems/WorldManager

# --- State ---
var _character_world_pos := Vector2i(0, 0)
var _is_zoomed_out := false
var _current_scanner_range := SCANNER_RANGE_ZOOMED_IN

# --- Chunk Management ---
var _chunk_nodes: Dictionary = {} # {Vector2i: TileMapLayer} - active visual chunks
var _recycled_chunk_nodes: Array[Node2D] = [] # Pool of inactive nodes to reuse


func _ready() -> void:
    Event.game_started.connect(_on_game_started)
    
    # Connect to all the signals that will control this view.
    Event.character_logical_position_changed.connect(_on_character_logical_position_changed)
    Event.character_fall_animation_started.connect(_on_character_fall_animation_started)
    Event.tile_mined_successfully.connect(_on_tile_mined_successfully)
    Event.zoom_level_changed.connect(_on_zoom_level_changed)


func _on_game_started(start_pos: Vector2i):
    var tileset = _create_debug_tileset()
    _create_chunk_pool(tileset)
    
    _character_world_pos = start_pos
    character.position = _character_world_pos * Constants.TILE_SIZE
    camera.position = character.position
    
    Event.game_tick.connect(_on_game_tick)

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
        camera.zoom = Vector2(2.5, 2.5)

# --- Visual Logic ---

func _update_camera():
    var smoothness = 0.1
    camera.position = camera.position.lerp(character.position, smoothness)
    camera.position = camera.position.snapped(Vector2.ONE / camera.zoom)


func _clear_tile_visual(tile_pos: Vector2i):
    var chunk_coord = tile_pos / Constants.CHUNK_SIZE
    if _chunk_nodes.has(chunk_coord):
        var tile_local_pos = tile_pos % Constants.CHUNK_SIZE
        
        var chunk_node: Node2D = _chunk_nodes[chunk_coord]
        var rock_layer: TileMapLayer = chunk_node.get_node("RockLayer")
        var ore_layer: TileMapLayer = chunk_node.get_node("OreLayer")
        rock_layer.erase_cell(tile_local_pos)
        ore_layer.erase_cell(tile_local_pos)

func _update_visible_chunks():
    # TODO: refactor this whole thing
    var view_size_in_tiles = get_viewport_rect().size / (Constants.TILE_SIZE * camera.zoom)
    
    # visible area
    var view_width_in_chunks = ceil(view_size_in_tiles.x / Constants.CHUNK_SIZE) + 2 # +2 for buffer
    var view_height_in_chunks = ceil(view_size_in_tiles.y / Constants.CHUNK_SIZE) + 2
    
    # even bigger buffer area, but we don't really know how much you can zoom out
    var buffer_width_in_chunks = view_width_in_chunks + 4
    var buffer_height_in_chunks = view_height_in_chunks + 4

    var required_chunks: Dictionary = {}
    var buffered_chunks: Dictionary = {}
    
    var camera_world_pos = camera.position / Constants.TILE_SIZE
    var camera_chunk_pos = Vector2i(round(camera_world_pos.x / Constants.CHUNK_SIZE), round(camera_world_pos.y / Constants.CHUNK_SIZE))

    # required_chunks for visible area
    var half_view_width = view_width_in_chunks / 2.0
    var start_x = camera_chunk_pos.x - floor(half_view_width)
    var end_x = camera_chunk_pos.x + ceil(half_view_width)

    var half_view_height = view_height_in_chunks / 2.0
    var start_y = camera_chunk_pos.y - floor(half_view_height)
    var end_y = camera_chunk_pos.y + ceil(half_view_height)

    for y in range(start_y, end_y + 1):
        for x in range(start_x, end_x + 1):
            required_chunks[Vector2i(x, y)] = true
    
    # buffered_chunks
    var half_buffer_width = buffer_width_in_chunks / 2.0
    start_x = camera_chunk_pos.x - floor(half_buffer_width)
    end_x = camera_chunk_pos.x + ceil(half_buffer_width)
    var half_buffer_height = buffer_height_in_chunks / 2.0
    start_y = camera_chunk_pos.y - floor(half_buffer_height)
    end_y = camera_chunk_pos.y + ceil(half_buffer_height)

    for y in range(start_y, end_y):
        for x in range(start_x, end_x):
            buffered_chunks[Vector2i(x, y)] = true

    # Unload chunks that are no longer needed.
    for chunk_coord in _chunk_nodes.keys():
        if not buffered_chunks.has(chunk_coord):
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
        # TODO its super easy to get into this on zoom out, fix at some point soon
        # push_warning("MiningView ran out of recyclable chunk nodes! The view may appear incomplete.")
        return
        
    var new_chunk_node = _recycled_chunk_nodes.pop_front()
    new_chunk_node.position = chunk_coord * Constants.CHUNK_SIZE * Constants.TILE_SIZE
    chunk_container.add_child(new_chunk_node)
    _chunk_nodes[chunk_coord] = new_chunk_node
    
    world_manager.queue_chunk_generation(chunk_coord)

func _unload_chunk(chunk_coord: Vector2i):
    var chunk_node = _chunk_nodes.get(chunk_coord)
    if chunk_node:
        # TODO: how optimal is this? can't these also be re-used?
        chunk_node.get_node("RockLayer").clear()
        chunk_node.get_node("OreLayer").clear()
        chunk_container.remove_child(chunk_node)
        _recycled_chunk_nodes.append(chunk_node)
        _chunk_nodes.erase(chunk_coord)

func _draw_chunk(chunk_coord: Vector2i, chunk_data: Dictionary):
    var chunk_node: Node2D = _chunk_nodes.get(chunk_coord)
    if not chunk_node: return
    
    var rock_layer: TileMapLayer = chunk_node.get_node("RockLayer")
    var ore_layer: TileMapLayer = chunk_node.get_node("OreLayer")
    
    # TODO: I'm sure this can also be optimized to avoid calling is_tile_mined thousands of times
    for tile_local_pos in chunk_data:
        var world_pos = chunk_coord * Constants.CHUNK_SIZE + tile_local_pos
        if world_manager.is_tile_mined(world_pos):
            continue # Skip this tile if it's already mined
        
        var tile = chunk_data[tile_local_pos]
        
        # base rock layer
        var rock_atlas_coords = ROCK_ID_TO_ATLAS.get(tile.rock)
        rock_layer.set_cell(tile_local_pos, 0, rock_atlas_coords)
        
        if tile.ore != "":
            var ore_atlas_coords = ORE_ID_TO_ATLAS.get(tile.ore, Vector2i(-1,-1))
            if ore_atlas_coords != Vector2i(-1, -1):
                ore_layer.set_cell(tile_local_pos, 0, ore_atlas_coords)

# --- Setup & Helpers ---

func _create_chunk_pool(tileset: TileSet):
    # Create enough chunk nodes to fill the maximum possible zoomed-out view, plus a buffer.
    var max_view_size = get_viewport_rect().size / (Constants.TILE_SIZE * 0.5) # Using min zoom for max size
    var max_view_width_in_chunks = ceil(max_view_size.x / Constants.CHUNK_SIZE) + 4 # +4 for large buffer
    var max_view_height_in_chunks = ceil(max_view_size.y / Constants.CHUNK_SIZE) + 4
    
    for i in range(max_view_width_in_chunks * max_view_height_in_chunks):
        var chunk_base = Node2D.new()
        
        var rock_layer := TileMapLayer.new()
        rock_layer.name = "RockLayer"
        rock_layer.tile_set = tileset
        chunk_base.add_child(rock_layer)
        
        var ore_layer := TileMapLayer.new()
        ore_layer.name = "OreLayer"
        ore_layer.tile_set = tileset
        chunk_base.add_child(ore_layer)
        
        _recycled_chunk_nodes.append(chunk_base)

func _create_debug_tileset() -> TileSet:
    var tile_size: int = 16
    var tile_set := TileSet.new()
    var atlas_source := TileSetAtlasSource.new()
    atlas_source.texture = load("res://assets/tiles/maja_tileset2.png")
    atlas_source.texture_region_size = Vector2i(tile_size, tile_size)
    for x in range(6):
        atlas_source.create_tile(Vector2i(x, 0))
    for x in range(5):
        atlas_source.create_tile(Vector2i(x, 1))
    tile_set.add_source(atlas_source, 0)
    return tile_set
