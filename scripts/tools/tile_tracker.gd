class_name TileTracker
extends Node

signal tile_mined(tile_pos: Vector2i)

const CHUNK_SIZE: int = 32
const MAX_CHUNKS: int = 9

var _active_chunks: Dictionary = {}
var _chunk_lru: Array[Vector2i] = []

func get_state() -> Dictionary:
    return _active_chunks.duplicate(true)

func set_state(data: Dictionary):
    _active_chunks = data
    _chunk_lru.assign(data.keys())

func is_tile_mined(world_pos: Vector2i) -> bool:
    var chunk_pos := _world_to_chunk(world_pos)
    var chunk := _get_chunk(chunk_pos)
    return chunk.has(world_pos)

func mine_tile(world_pos: Vector2i) -> void:
    var chunk_pos := _world_to_chunk(world_pos)
    var chunk := _get_or_create_chunk(chunk_pos)
    
    if not chunk.has(world_pos):
        chunk[world_pos] = true
        tile_mined.emit(world_pos)

func reset() -> void:
    _active_chunks.clear()
    _chunk_lru.clear()

# --- Private helper methods ---
func _world_to_chunk(world_pos: Vector2i) -> Vector2i:
    return Vector2i(
        world_pos.x / CHUNK_SIZE,
        world_pos.y / CHUNK_SIZE
    )

func _get_chunk(chunk_pos: Vector2i) -> Dictionary:
    return _active_chunks.get(chunk_pos, {})

func _get_or_create_chunk(chunk_pos: Vector2i) -> Dictionary:
    if not _active_chunks.has(chunk_pos):
        _active_chunks[chunk_pos] = {}
        _chunk_lru.append(chunk_pos)
        _enforce_chunk_limit()
    else:
        _chunk_lru.erase(chunk_pos)
        _chunk_lru.append(chunk_pos)
    
    return _active_chunks[chunk_pos]

func _enforce_chunk_limit() -> void:
    while _chunk_lru.size() > MAX_CHUNKS:
        var oldest_chunk = _chunk_lru.pop_front()
        _active_chunks.erase(oldest_chunk)
