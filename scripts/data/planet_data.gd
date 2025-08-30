extends Resource
class_name PlanetData

@export_group("Core Properties")
@export var planet_name: String = "Aethel-7"
@export var master_seed: int = 12345

@export_group("Geological Layers")
@export var layers: Array[Dictionary] = [
    {"name": "Dirt", "start_depth": 0, "base_rock_id": "dirt"},
    {"name": "Stone", "start_depth": 100, "base_rock_id": "stone"},
    {"name": "Deep Stone", "start_depth": 500, "base_rock_id": "deep_stone"},
    {"name": "Bedrock", "start_depth": 1000, "base_rock_id": "bedrock"},
    {"name": "Lava Rock", "start_depth": 2000, "base_rock_id": "lava_rock"}
]

@export_group("Rock Properties")
@export var rock_properties: Dictionary = {
    "dirt": {"hardness": 1},
    "stone": {"hardness": 2},
    "deep_stone": {"hardness": 5},
    "bedrock": {"hardness": 10},
    "lava_rock": {"hardness": 20}
}

@export_group("Ore Deposits")
@export var ores: Array[Dictionary] = [
    {"ore_id": "copper", "valid_layers": ["dirt", "stone"], "rarity": 0.6, "noise_frequency": 0.08, "noise_octaves": 2},
    {"ore_id": "iron", "valid_layers": ["stone", "deep_stone"], "rarity": 0.7, "noise_frequency": 0.06, "noise_octaves": 3},
    {"ore_id": "silver", "valid_layers": ["deep_stone"], "rarity": 0.85, "noise_frequency": 0.05, "noise_octaves": 2},
    {"ore_id": "gold", "valid_layers": ["deep_stone", "bedrock"], "rarity": 0.9, "noise_frequency": 0.09, "noise_octaves": 1},
    {"ore_id": "obsidian", "valid_layers": ["lava_rock"], "rarity": 0.8, "noise_frequency": 0.05, "noise_octaves": 3}
]

# TODO: needed here?
func get_layer_for_depth(depth: float) -> Dictionary:
    for layer in layers:
        if depth >= layer.start_depth:
            return layer
    return {}
    

func get_total_hardness(tile_data: Dictionary) -> int:
    var base_hardness = rock_properties.get(tile_data.rock, {"hardness": 1}).hardness
    var bonus_hardness = 0
    if tile_data.ore != "":
        for ore_def in ores:
            if ore_def.ore_id == tile_data.ore:
                bonus_hardness = ore_def.get("hardness_bonus", 0)
                break
    return base_hardness + bonus_hardness
