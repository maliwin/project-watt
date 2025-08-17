class_name WorldData
extends Resource

const DEPTH_PER_TILE: float = 2.0

enum RockType { AIR, DIRT, STONE, DEEP_STONE, BEDROCK, LAVA_ROCK }

const ROCK_CONFIG := {
    RockType.AIR: {
        "depth_range": Vector2i(-99999, 0),
        "name": "Air",
        "atlas_coords": Vector2i(0, 0)
    },
    RockType.DIRT: {
        "depth_range": Vector2i(0, 100),
        "name": "Dirt", 
        "atlas_coords": Vector2i(1, 0)
    },
    RockType.STONE: {
        "depth_range": Vector2i(100, 500),
        "name": "Stone",
        "atlas_coords": Vector2i(2, 0)
    },
    RockType.DEEP_STONE: {
        "depth_range": Vector2i(500, 1000),
        "name": "Deep Stone",
        "atlas_coords": Vector2i(3, 0)
    },
    RockType.BEDROCK: {
        "depth_range": Vector2i(1000, 2000),
        "name": "Bedrock",
        "atlas_coords": Vector2i(4, 0)
    },
    RockType.LAVA_ROCK: {
        "depth_range": Vector2i(2000, 999999),
        "name": "Lava Rock",
        "atlas_coords": Vector2i(5, 0)
    }
}

const MATERIAL_CONFIG := {
    "Air": {"hardness": 0, "ores": {}},
    "Dirt": {"hardness": 1, "ores": {"Copper": 0.01}},
    "Stone": {"hardness": 2, "ores": {"Iron": 0.05}},
    "Deep Stone": {"hardness": 3, "ores": {"Silver": 0.03, "Gold": 0.02}},
    "Bedrock": {"hardness": 999, "ores": {}},
    "Lava Rock": {"hardness": 5, "ores": {"Obsidian": 0.02, "Gold": 0.01}},
}

const ORE_ATLAS := {
    "Iron": Vector2i(0, 1),
    "Silver": Vector2i(1, 1), 
    "Gold": Vector2i(2, 1),
    "Obsidian": Vector2i(3, 1),
    "Copper": Vector2i(4, 1),
}

static func get_rock_type_for_depth(depth: float) -> RockType:
    for rock_type in ROCK_CONFIG:
        var range_data: Vector2i = ROCK_CONFIG[rock_type]["depth_range"]
        if depth >= range_data.x and depth < range_data.y:
            return rock_type
    return RockType.LAVA_ROCK

static func get_rock_name_for_depth(depth: float) -> String:
    var rock_type := get_rock_type_for_depth(depth)
    return ROCK_CONFIG[rock_type]["name"]

static func get_rock_hardness(rock_name: String) -> int:
    return MATERIAL_CONFIG.get(rock_name, {}).get("hardness", 1)

static func get_atlas_coords_for_rock(rock_type: RockType) -> Vector2i:
    return ROCK_CONFIG[rock_type]["atlas_coords"]

static func get_atlas_coords_for_ore(ore_name: String) -> Vector2i:
    return ORE_ATLAS.get(ore_name, Vector2i(0, 0))

static func has_ore_atlas(ore_name: String) -> bool:
    return ORE_ATLAS.has(ore_name)

# Deterministic ore generation
static func get_ore_at_position(world_x: int, world_row: int) -> String:
    var depth: float = world_row * DEPTH_PER_TILE
    var rock_name: String = get_rock_name_for_depth(depth)
    var ore_table: Dictionary = MATERIAL_CONFIG[rock_name].get("ores", {})
    
    if ore_table.is_empty():
        return ""
    
    var ore_names: Array = ore_table.keys()
    ore_names.sort()
    
    for ore_name in ore_names:
        var chance: float = ore_table[ore_name]
        if chance <= 0.0:
            continue
            
        var seed_value: int = world_x * 73856093 ^ world_row * 19349663 ^ hash(ore_name)
        if seed_value < 0:
            seed_value = -seed_value
            
        var rng := RandomNumberGenerator.new()
        rng.seed = seed_value
        
        if rng.randf() < chance:
            return ore_name
    
    return ""
