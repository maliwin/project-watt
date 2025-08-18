class_name SmeltingSystem
extends Node

signal smelt_complete(bar_type: String, amount: int)

const SMELT_RECIPES := {
    "Copper": { "cost": { "Copper": 10 }, "output": "Copper Bar", "time": 5.0 },
    "Iron": { "cost": { "Iron": 10 }, "output": "Iron Bar", "time": 8.0 }
}

func can_smelt(ore_type: String) -> bool:
    if not SMELT_RECIPES.has(ore_type):
        return false
    var cost = SMELT_RECIPES[ore_type]["cost"]
    return GM.inventory_system.has_in_storage(cost)

func start_smelting(ore_type: String):
    if not can_smelt(ore_type):
        return

    var recipe = SMELT_RECIPES[ore_type]
    for item in recipe["cost"]:
        GM.inventory_system.remove_from_storage(item, recipe["cost"][item])

    var timer = Timer.new()
    timer.wait_time = recipe["time"]
    timer.one_shot = true
    timer.timeout.connect(func():
        GM.inventory_system.add_to_storage(recipe["output"], 1)
        smelt_complete.emit(recipe["output"], 1)
        timer.queue_free()
    )
    add_child(timer)
    timer.start()
