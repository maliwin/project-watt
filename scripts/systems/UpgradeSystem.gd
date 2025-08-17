class_name UpgradeSystem
extends Node

signal upgrade_purchased(upgrade_type: String, new_level: int)
signal upgrade_failed(upgrade_type: String, reason: String)
signal all_resources_sold(total_value: int)

var game_state: GameState
var inventory_system: InventorySystem
var mining_tool: MiningTool

func initialize(p_game_state: GameState, p_inventory: InventorySystem, p_tool: MiningTool) -> void:
    game_state = p_game_state
    inventory_system = p_inventory
    mining_tool = p_tool

func can_upgrade_pickaxe() -> bool:
    if not mining_tool or not game_state:
        return false
    return game_state.currency >= mining_tool.get_upgrade_cost()

func upgrade_pickaxe() -> bool:
    if not can_upgrade_pickaxe():
        upgrade_failed.emit("pickaxe", "Insufficient currency")
        return false
    
    var cost := mining_tool.get_upgrade_cost()
    game_state.currency -= cost
    mining_tool.level += 1
    
    upgrade_purchased.emit("pickaxe", mining_tool.level)
    return true

func sell_all_resources() -> void:
    var sellable := inventory_system.get_sellable_resources()
    var total_value := 0
    
    for resource_name in sellable:
        var amount = sellable[resource_name]
        var price := inventory_system.get_sell_price(resource_name)
        var value = amount * price
        
        if inventory_system.remove_resource(resource_name, amount):
            total_value += value
    
    if total_value > 0:
        game_state.currency += total_value
        all_resources_sold.emit(total_value)

func sell_resource(resource_name: String, amount: int = 1) -> bool:
    if not inventory_system.has_resource(resource_name, amount):
        return false
    
    var price := inventory_system.get_sell_price(resource_name)
    if price <= 0:
        return false
    
    if inventory_system.remove_resource(resource_name, amount):
        game_state.currency += price * amount
        return true
    
    return false
