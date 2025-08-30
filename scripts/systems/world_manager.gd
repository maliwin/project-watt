extends Node
class_name WorldManager

const CHUNK_SIZE := 32  # TODO: is this ok?

# type TileData = { "rock": String, "ore": String }
# type ChunkData = Dictionary[Vector2i, TileData]

# Threading
var thread: Thread
var is_running := false
var pending_chunks := []  # [Vector2i]
var completed_chunks := {}  # {Vector2i: chunk_data}
var mutex := Mutex.new()
var semaphore := Semaphore.new()

# State
var current_planet: PlanetData
var noise_generators := {}
var mined_tiles: Dictionary = {}  # {Vector2i: bool}
var is_initialized := false
# TODO: do we want guaranteed ore anywhere?

# --- Public API ---

func is_tile_mined(world_pos: Vector2i) -> bool:
    return mined_tiles.has(world_pos)

func destroy_tile(world_pos: Vector2i):
    mined_tiles[world_pos] = true

func get_tile_data(world_pos: Vector2i) -> Dictionary:
    if not is_initialized:
        push_warning("WorldManager: get_tile_data called before planet was initialized.")
        return {"rock": "air", "ore": ""}
    
    var chunk_coord := world_pos / CHUNK_SIZE
    var tile_local_pos := world_pos % CHUNK_SIZE
    
    # First, check if the chunk is already generated and ready.
    mutex.lock()
    var chunk_data = completed_chunks.get(chunk_coord, null)
    mutex.unlock()
    
    # If the chunk wasn't ready, we must generate it now, on the main thread.
    # This is a fallback to prevent the game from breaking if logic outpaces generation.
    if chunk_data == null:
        chunk_data = _generate_chunk_data(chunk_coord)
        
    # Now that we have the chunk data, find the specific tile.
    # The chunk_data dictionary only contains non-air tiles for optimization.
    if chunk_data.has(tile_local_pos):
        # The key exists, so we can safely return its data.
        return chunk_data[tile_local_pos]
    else:
        # If the key doesn't exist, it means the tile is air.
        return {"rock": "air", "ore": ""}


func initialize_mine(planet_data: PlanetData):
    mutex.lock()
    current_planet = planet_data
    noise_generators.clear()

    for ore_def in current_planet.ores:
        var noise := FastNoiseLite.new()
        noise.seed = current_planet.master_seed + ore_def.ore_id.hash()
        noise.frequency = ore_def.noise_frequency
        noise.fractal_octaves = ore_def.noise_octaves
        noise_generators[ore_def.ore_id] = noise

    is_initialized = true
    mutex.unlock()


func queue_chunk_generation(chunk_coord: Vector2i):
    if not is_initialized:
        return
        
    mutex.lock()
    if not pending_chunks.has(chunk_coord) and not completed_chunks.has(chunk_coord):
        pending_chunks.append(chunk_coord)
        semaphore.post()
    mutex.unlock()

func get_completed_chunk(chunk_coord: Vector2i):
    mutex.lock()
    var chunk_data = completed_chunks.get(chunk_coord, null)
    completed_chunks.erase(chunk_coord)
    mutex.unlock()
    
    return chunk_data
    
    
# --- Generation ---

func _ready():
    thread = Thread.new()
    is_running = true
    thread.start(_thread_function)
    
func _exit_tree():
    is_running = false
    if thread:
        semaphore.post()
        thread.wait_to_finish()

func _thread_function():
    while is_running:
        semaphore.wait()
        
        if not is_running:
            break
            
        mutex.lock()
        var chunk_to_generate = null
        if not pending_chunks.is_empty():
            chunk_to_generate = pending_chunks.pop_front()
        mutex.unlock()
        
        print(chunk_to_generate)
        if chunk_to_generate:
            var data = _generate_chunk_data(chunk_to_generate)
            mutex.lock()
            completed_chunks[chunk_to_generate] = data
            mutex.unlock()
            
func _generate_chunk_data(chunk_coord: Vector2i) -> Dictionary:
    var data := {}
    var start_x = chunk_coord.x * CHUNK_SIZE
    var start_y = chunk_coord.y * CHUNK_SIZE
    
    for y_offset in range(CHUNK_SIZE):
        var depth = start_y + y_offset
        var layer_data = current_planet.get_layer_for_depth(depth)  # TODO: see if needs optimizing ever
        
        for x_offset in range(CHUNK_SIZE):
            var world_pos = Vector2i(start_x + x_offset, start_y + y_offset)
            
            var rock_id: String
            var ore_id: String = ""
            
            if not layer_data:  # air, TODO: refactor
                continue
            
            rock_id = layer_data.base_rock_id
            
            for ore_def in current_planet.ores:
                if layer_data.base_rock_id in ore_def.valid_layers:
                    var noise_val = noise_generators[ore_def.ore_id].get_noise_2d(world_pos.x, world_pos.y)
                    var normalized_noise = (noise_val + 1.0) / 2.0
                    
                    if normalized_noise > ore_def.rarity:
                        ore_id = ore_def.ore_id
                        break
        
            data[Vector2i(x_offset, y_offset)] = {"rock": rock_id, "ore": ore_id}
                
    return data
