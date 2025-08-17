class_name MiningTool
extends Resource

signal tool_upgraded(tool: MiningTool)

@export var tool_name: String = "Pickaxe"
@export var level: int = 1:
    set(value):
        if level != value:
            level = value
            power = level  # Simple 1:1 scaling for now
            tool_upgraded.emit(self)

@export var power: int = 1
@export var crit_chance: float = 0.05

func _init():
    tool_name = "Pickaxe"
    level = 1
    power = 1
    crit_chance = 0.05

func can_mine_hardness(hardness: int) -> bool:
    return power >= hardness

func get_upgrade_cost() -> int:
    return 50 * level

func reset() -> void:
    tool_name = "Pickaxe"
    level = 1
    power = 1
    crit_chance = 0.05
