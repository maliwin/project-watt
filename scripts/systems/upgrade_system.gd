class_name UpgradeSystem
extends Node

var inventory_system: InventorySystem
var mining_tool: MiningTool

func can_upgrade_pickaxe() -> bool:
    var cost = mining_tool.get_upgrade_cost()
    if cost.is_empty():
        return false # Max level
    return inventory_system.has_in_storage(cost)

func upgrade_pickaxe() -> bool:
    if not can_upgrade_pickaxe():
        Event.upgrade_failed.emit("pickaxe", "Insufficient materials")
        return false
    
    var cost = mining_tool.get_upgrade_cost()
    for item in cost:
        inventory_system.remove_from_storage(item, cost[item])

    mining_tool.power = mining_tool.get_next_power()
    mining_tool.level += 1
    
    Event.upgrade_purchased.emit("pickaxe", mining_tool.level)
    return true
