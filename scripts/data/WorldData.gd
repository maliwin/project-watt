class_name WorldData
extends Resource

const DEPTH_PER_TILE: float = 2.0

enum RockType { AIR, DIRT, STONE, DEEP_STONE, BEDROCK, LAVA_ROCK }

const ROCK_CONFIG := {
    RockType.AIR: {"depth_range": Vector2i(-99999, 0), "name": "Air", "atlas_coords": Vector2i(0, 0)},
    RockType.DIRT: {"depth_range": Vector2i(0, 100), "name": "Dirt", "atlas_coords": Vector2i(1, 0)},
    RockType.STONE: {"depth_range": Vector2i(100, 500), "name": "Stone", "atlas_coords": Vector2i(2, 0)},
    RockType.DEEP_STONE: {"depth_range": Vector2i(500, 1000), "name": "Deep Stone", "atlas_coords": Vector2i(3, 0)},
    RockType.BEDROCK: {"depth_range": Vector2i(1000, 2000), "name": "Bedrock", "atlas_coords": Vector2i(4, 0)},
    RockType.LAVA_ROCK: {"depth_range": Vector2i(2000, 999999), "name": "Lava Rock", "atlas_coords": Vector2i(5, 0)}
}

const MATERIAL_CONFIG := {
    "Air": {"hardness": 0, "ores": {}},
    "Dirt": {"hardness": 1, "ores": {"Copper": 0.01}},
    "Stone": {"hardness": 2, "ores": {"Iron": 0.05}},
    "Deep Stone": {"hardness": 3, "ores": {"Silver": 0.03, "Gold": 0.02}},
    "Bedrock": {"hardness": 4, "ores": {}},
    "Lava Rock": {"hardness": 5, "ores": {"Obsidian": 0.02, "Gold": 0.01}},
}

const ORE_ATLAS := {
    "Iron": Vector2i(0, 1),
    "Silver": Vector2i(1, 1),
    "Gold": Vector2i(2, 1),
    "Obsidian": Vector2i(3, 1),
    "Copper": Vector2i(4, 1),
}

var _ore_noise_generators: Dictionary = {}

func _init() -> void:
    _setup_ore_noise()

func _setup_ore_noise() -> void:
    var base_seed = randi()
    
    _ore_noise_generators["Copper"] = {
        "vein_noise": _create_noise(base_seed + 1, 0.08),
        "cluster_noise": _create_noise(base_seed + 2, 0.03),
        "threshold": 0.6
    }
    _ore_noise_generators["Iron"] = {
        "vein_noise": _create_noise(base_seed + 3, 0.06),
        "cluster_noise": _create_noise(base_seed + 4, 0.02),
        "threshold": 0.65
    }
    _ore_noise_generators["Silver"] = {
        "vein_noise": _create_noise(base_seed + 5, 0.05),
        "cluster_noise": _create_noise(base_seed + 6, 0.025),
        "threshold": 0.7
    }
    # --- ADJUSTED LAVA AREA ORES ---
    _ore_noise_generators["Gold"] = {
        "vein_noise": _create_noise(base_seed + 7, 0.09), # Slightly larger veins
        "cluster_noise": _create_noise(base_seed + 8, 0.03), # Larger clusters
        "threshold": 0.72 # Lowered threshold = more common
    }
    _ore_noise_generators["Obsidian"] = {
        "vein_noise": _create_noise(base_seed + 9, 0.05),
        "cluster_noise": _create_noise(base_seed + 10, 0.02),
        "threshold": 0.68 # Significantly lowered threshold
    }

# Helper function to reduce repeated code
func _create_noise(seed: int, frequency: float) -> FastNoiseLite:
    var noise := FastNoiseLite.new()
    noise.seed = seed
    noise.frequency = frequency
    noise.fractal_octaves = 2
    return noise

func get_rock_type_for_depth(depth: float) -> RockType:
    for rock_type in ROCK_CONFIG:
        var range_data: Vector2i = ROCK_CONFIG[rock_type]["depth_range"]
        if depth >= range_data.x and depth < range_data.y:
            return rock_type
    return RockType.LAVA_ROCK

func get_rock_name_for_depth(depth: float) -> String:
    var rock_type := get_rock_type_for_depth(depth)
    return ROCK_CONFIG[rock_type]["name"]

func get_rock_hardness(rock_name: String) -> int:
    return MATERIAL_CONFIG.get(rock_name, {}).get("hardness", 1)

func get_atlas_coords_for_rock(rock_type: RockType) -> Vector2i:
    return ROCK_CONFIG[rock_type]["atlas_coords"]

func get_atlas_coords_for_ore(ore_name: String) -> Vector2i:
    return ORE_ATLAS.get(ore_name, Vector2i(0, 0))

func has_ore_atlas(ore_name: String) -> bool:
    return ORE_ATLAS.has(ore_name)

func get_ore_at_position(world_x: int, world_row: int, center_x: int) -> String:
    var depth: float = world_row * DEPTH_PER_TILE
    var rock_name: String = get_rock_name_for_depth(depth)
    var ore_table: Dictionary = MATERIAL_CONFIG[rock_name].get("ores", {})
    
    if ore_table.is_empty():
        return ""

    var distance_from_center = abs(world_x - center_x)
    var max_distance = 15.0 
    var horizontal_penalty = 0.0
    if distance_from_center > 0:
        horizontal_penalty = pow(distance_from_center / max_distance, 2) * 0.4

    var ore_names: Array = ore_table.keys()
    ore_names.sort()
    
    for ore_name in ore_names:
        if _ore_noise_generators.has(ore_name):
            var gen_data = _ore_noise_generators[ore_name]
            
            var vein_noise_value = gen_data["vein_noise"].get_noise_2d(world_x, world_row)
            var cluster_noise_value = gen_data["cluster_noise"].get_noise_2d(world_x, world_row)
            
            var vein_norm = (vein_noise_value + 1.0) / 2.0
            var cluster_norm = (cluster_noise_value + 1.0) / 2.0
            
            var final_noise = (vein_norm + cluster_norm) / 2.0
            
            var threshold = gen_data["threshold"] + horizontal_penalty
            
            if final_noise > threshold:
                return ore_name
    
    return ""
