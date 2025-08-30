class_name MiningTool
extends Resource

@export var tool_name: String = "Pickaxe"
@export var level: int = 1:
    set(value):
        if level != value:
            level = value
            Event.tool_upgraded.emit(self)

@export var power: int = 10
@export var crit_chance: float = 0.05

const UPGRADE_COSTS = [
    { "power": 2, "cost": { "Copper Bar": 10 } },
    { "power": 2, "cost": { "Copper Bar": 25 } },
    { "power": 3, "cost": { "Iron Bar": 15, "Stone": 50 } }
]

func can_mine_hardness(hardness: int) -> bool:
    return power >= hardness

func get_upgrade_cost() -> Dictionary:
    if level < UPGRADE_COSTS.size():
        return UPGRADE_COSTS[level]["cost"]
    return {} # Return empty dictionary if at max level

func get_next_power() -> int:
    if level < UPGRADE_COSTS.size():
        return UPGRADE_COSTS[level]["power"]
    return power

func reset():
    level = 1
    power = 1
