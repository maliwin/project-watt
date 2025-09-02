extends Node
class_name WorldManager

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
        # TODO: log to see if this happens
        push_warning("WorldManager: get_tile_data called before planet was initialized.")
        return {"rock": "air", "ore": ""}
    
    var chunk_coord := world_pos / Constants.CHUNK_SIZE
    var tile_local_pos := world_pos % Constants.CHUNK_SIZE
    
    mutex.lock()
    var chunk_data = completed_chunks.get(chunk_coord, null)
    mutex.unlock()
    
    if chunk_data == null:
        # TODO: log to see if this happens and also if we should then store this??
        chunk_data = _generate_chunk_data(chunk_coord)
        
    if chunk_data.has(tile_local_pos):
        return chunk_data[tile_local_pos]
    else:
        # TODO: log to see if this happens
        return {"rock": "air", "ore": ""}

func initialize_mine(planet_data: PlanetData):
    mutex.lock()
    current_planet = planet_data
    noise_generators.clear()

    for ore_id in current_planet.ores:
        var ore_def: Dictionary = current_planet.ores.get(ore_id)
        var noise := FastNoiseLite.new()
        
        noise.seed = current_planet.master_seed + ore_id.hash()
        noise.frequency = ore_def.noise_frequency
        noise.fractal_octaves = ore_def.noise_octaves
        
        noise_generators[ore_id] = noise

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
    Systems.world = self
    
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
        
        if chunk_to_generate != null:
            var data = _generate_chunk_data(chunk_to_generate)
            mutex.lock()
            completed_chunks[chunk_to_generate] = data
            mutex.unlock()
            
func _generate_chunk_data(chunk_coord: Vector2i) -> Dictionary:
    # TODO: slowest part of code, see if ever needs improving
    var data := {}
    var start_x = chunk_coord.x * Constants.CHUNK_SIZE
    var start_y = chunk_coord.y * Constants.CHUNK_SIZE
    
    for y_offset in range(Constants.CHUNK_SIZE):
        var depth = start_y + y_offset
        var layer_data = current_planet.get_layer_for_depth(depth)  # TODO: see if needs optimizing ever
        
        for x_offset in range(Constants.CHUNK_SIZE):
            var world_pos = Vector2i(start_x + x_offset, start_y + y_offset)
            
            var rock_id: String
            var generated_ore_id: String
            
            if not layer_data:  # air, TODO: refactor
                continue
            
            rock_id = layer_data.base_rock_id
            
            for ore_id in current_planet.ores:
                var ore_def = current_planet.ores.get(ore_id)
                if layer_data.base_rock_id in ore_def.valid_layers:
                    var noise_val = noise_generators[ore_id].get_noise_2d(world_pos.x, world_pos.y)
                    var normalized_noise = (noise_val + 1.0) / 2.0
                    
                    if normalized_noise > ore_def.rarity:
                        generated_ore_id = ore_id
                        break
        
            data[Vector2i(x_offset, y_offset)] = {"rock": rock_id, "ore": generated_ore_id}
                
    return data
