class_name TileTracker
extends Node

signal tile_mined(tile_pos: Vector2i)

# Spatial partitioning - only track tiles in chunks around current view
const CHUNK_SIZE: int = 32
const MAX_CHUNKS: int = 9  # 3x3 grid of chunks around player

# Chunk-based storage instead of infinite dictionary
var _active_chunks: Dictionary = {}  # Vector2i(chunk_x, chunk_y) -> Dictionary
var _chunk_lru: Array[Vector2i] = []  # Least Recently Used chunks

func is_tile_mined(world_pos: Vector2i) -> bool:
    var chunk_pos := _world_to_chunk(world_pos)
    var chunk := _get_chunk(chunk_pos)
    if chunk == null:
        return false
    return chunk.has(world_pos)

func mine_tile(world_pos: Vector2i) -> void:
    var chunk_pos := _world_to_chunk(world_pos)
    var chunk := _get_or_create_chunk(chunk_pos)
    
    if not chunk.has(world_pos):
        chunk[world_pos] = true
        tile_mined.emit(world_pos)

func clear_distant_chunks(center_world_pos: Vector2i) -> void:
    var center_chunk := _world_to_chunk(center_world_pos)
    var chunks_to_remove: Array[Vector2i] = []
    
    # Mark chunks that are too far from center
    for chunk_pos in _active_chunks:
        var distance := center_chunk.distance_squared_to(chunk_pos)
        if distance > 2:  # Keep chunks within 2 chunk distance
            chunks_to_remove.append(chunk_pos)
    
    # Remove distant chunks
    for chunk_pos in chunks_to_remove:
        _active_chunks.erase(chunk_pos)
        _chunk_lru.erase(chunk_pos)

func get_mined_tiles_in_area(center: Vector2i, radius: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var start_chunk := _world_to_chunk(center - Vector2i(radius, radius))
    var end_chunk := _world_to_chunk(center + Vector2i(radius, radius))
    
    for chunk_x in range(start_chunk.x, end_chunk.x + 1):
        for chunk_y in range(start_chunk.y, end_chunk.y + 1):
            var chunk_pos := Vector2i(chunk_x, chunk_y)
            var chunk := _get_chunk(chunk_pos)
            if chunk:
                for tile_pos in chunk:
                    if center.distance_squared_to(tile_pos) <= radius * radius:
                        result.append(tile_pos)
    
    return result

func reset() -> void:
    _active_chunks.clear()
    _chunk_lru.clear()

# Private helper methods
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
        # Move to end of LRU (most recently used)
        _chunk_lru.erase(chunk_pos)
        _chunk_lru.append(chunk_pos)
    
    return _active_chunks[chunk_pos]

func _enforce_chunk_limit() -> void:
    while _chunk_lru.size() > MAX_CHUNKS:
        var oldest_chunk := _chunk_lru[0]
        _chunk_lru.remove_at(0)
        _active_chunks.erase(oldest_chunk)
