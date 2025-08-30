extends Control
class_name MiningView

const TILE_SIZE := 16
const CHUNK_SIZE := 32

const SCANNER_RANGE_ZOOMED_IN := 2
const SCANNER_RANGE_ZOOMED_OUT := 20

# --- Node References ---
@onready var character: Sprite2D = $SubViewportContainer/SubViewport/Character
@onready var camera: Camera2D = $SubViewportContainer/SubViewport/Camera2D
@onready var chunk_container: Node2D = $SubViewportContainer/SubViewport/ChunkContainer
@onready var world_generator: WorldManager = $/root/Main/Systems/WorldManager

var _character_world_pos := Vector2i(0, 0) # A local copy of the character's logical position.
var _is_zoomed_out := false
var _current_scanner_range := SCANNER_RANGE_ZOOMED_IN

var _chunk_nodes: Dictionary = {} # {Vector2i: TileMapLayer}
var _recycled_chunk_nodes: Array[TileMapLayer] = []

func _ready() -> void:
    var tileset = _create_debug_tileset()
    _create_chunk_pool(tileset)

    Ticker.game_tick.connect(_on_game_tick)
    Event.character_logical_position_changed.connect(_on_character_logical_position_changed)
    Event.character_fall_animation_started.connect(_on_character_fall_animation_started)
    Event.tile_mined_successfully.connect(_on_tile_mined_successfully)

    Event.zoom_level_changed.connect(_apply_zoom)

func _on_game_tick(_delta: float) -> void:
    _update_camera()
    _update_visible_chunks()

func _on_character_logical_position_changed(new_world_pos: Vector2i):
    _character_world_pos = new_world_pos

func _on_character_fall_animation_started(target_pixel_pos: Vector2, duration: float):
    var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
    tween.tween_property(character, "position", target_pixel_pos, duration)

func _on_tile_mined_successfully(tile_pos: Vector2i, _resources: Array[String]):
    var chunk_coord = tile_pos / CHUNK_SIZE
    if _chunk_nodes.has(chunk_coord):
        var chunk_node = _chunk_nodes[chunk_coord]
        var tile_local_pos = tile_pos % CHUNK_SIZE
        chunk_node.set_cell(tile_local_pos, -1)

func _update_camera():
    camera.position = camera.position.lerp(character.position, 0.1)

func _update_visible_chunks():
    var character_chunk_pos = _character_world_pos / CHUNK_SIZE
    var view_width_in_chunks = ceil(float(_current_scanner_range * 2 + 1) / CHUNK_SIZE) + 2
    var view_height_in_chunks = ceil(1500.0 / TILE_SIZE / CHUNK_SIZE) + 2

    var required_chunks: Dictionary = {}
    for x in range(-view_width_in_chunks / 2, view_width_in_chunks / 2 + 1):
        for y in range(-view_height_in_chunks / 2, view_height_in_chunks / 2 + 1):
            var chunk_coord = character_chunk_pos + Vector2i(x, y)
            required_chunks[chunk_coord] = true

    for chunk_coord in _chunk_nodes.keys():
        if not required_chunks.has(chunk_coord):
            _unload_chunk(chunk_coord)

    for chunk_coord in required_chunks:
        if not _chunk_nodes.has(chunk_coord):
            _load_chunk(chunk_coord)

    for chunk_coord in _chunk_nodes:
        var chunk_data = world_generator.get_completed_chunk(chunk_coord)
        if chunk_data:
            _draw_chunk(chunk_coord, chunk_data)

func _load_chunk(chunk_coord: Vector2i):
    if _recycled_chunk_nodes.is_empty():
        print("MiningView ran out of recyclable chunk nodes!")
        return
        
    var new_chunk_node = _recycled_chunk_nodes.pop_front()
    new_chunk_node.position = chunk_coord * CHUNK_SIZE * TILE_SIZE
    chunk_container.add_child(new_chunk_node)
    _chunk_nodes[chunk_coord] = new_chunk_node
    world_generator.queue_chunk_generation(chunk_coord)

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
    
    for tile_local_pos in chunk_data:
        var tile = chunk_data[tile_local_pos]
        if world_generator.is_tile_mined(chunk_coord * CHUNK_SIZE + tile_local_pos):
            continue
            
        var atlas_coords = Vector2i(0, 0) # Stone
        if tile.ore == "copper": atlas_coords = Vector2i(1, 0) # Copper
        
        chunk_node.set_cell(tile_local_pos, 0, atlas_coords)


func _apply_zoom(_is_zoomed_out):
    if _is_zoomed_out:
        _current_scanner_range = SCANNER_RANGE_ZOOMED_OUT
        camera.zoom = Vector2(0.5, 0.5)
    else:
        _current_scanner_range = SCANNER_RANGE_ZOOMED_IN
        camera.zoom = Vector2(1.5, 1.5)
    
    var all_loaded_chunks = _chunk_nodes.keys()
    for chunk_coord in all_loaded_chunks:
        _unload_chunk(chunk_coord)


func _create_chunk_pool(tileset: TileSet):
    var buffer = 2
    var max_view_width_in_chunks = ceil(float(SCANNER_RANGE_ZOOMED_OUT * 2 + 1) / CHUNK_SIZE) + buffer
    var max_view_height_in_chunks = ceil(float(1500) / TILE_SIZE / CHUNK_SIZE) + buffer
    
    for i in range(max_view_width_in_chunks * max_view_height_in_chunks):
        var rock_layer := TileMapLayer.new()
        rock_layer.tile_set = tileset
        _recycled_chunk_nodes.append(rock_layer)

func _create_debug_tileset() -> TileSet:
    var tile_set := TileSet.new()
    var atlas_source := TileSetAtlasSource.new()
    var image := Image.create(TILE_SIZE * 2, TILE_SIZE, false, Image.FORMAT_RGBA8)
    image.fill_rect(Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Color.GRAY)
    image.fill_rect(Rect2i(TILE_SIZE, 0, TILE_SIZE, TILE_SIZE), Color.DARK_GOLDENROD)
    atlas_source.texture = ImageTexture.create_from_image(image)
    atlas_source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
    atlas_source.create_tile(Vector2i(0, 0)) # Stone
    atlas_source.create_tile(Vector2i(1, 0)) # Copper
    tile_set.add_source(atlas_source, 0)
    return tile_set
