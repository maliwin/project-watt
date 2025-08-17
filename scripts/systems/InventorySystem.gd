class_name InventorySystem
extends Node

signal inventory_changed(inventory: Dictionary)
signal resource_added(resource_name: String, amount: int)
signal resource_removed(resource_name: String, amount: int)

# Resource configurations
const SELL_PRICES := {
    "Dirt": 1, "Stone": 2, "Deep Stone": 3, "Bedrock": 0, "Lava Rock": 4,
    "Copper": 5, "Iron": 8, "Silver": 12, "Gold": 20, "Obsidian": 25,
}

# Private inventory storage
var _inventory: Dictionary = {}

# Public read-only access
var inventory: Dictionary:
    get: return _inventory.duplicate()

func add_resource(resource_name: String, amount: int = 1) -> void:
    if amount <= 0:
        return
    
    _inventory[resource_name] = _inventory.get(resource_name, 0) + amount
    resource_added.emit(resource_name, amount)
    inventory_changed.emit(inventory)

func remove_resource(resource_name: String, amount: int = 1) -> bool:
    var current_amount: int = _inventory.get(resource_name, 0)
    if current_amount < amount:
        return false
    
    _inventory[resource_name] = current_amount - amount
    if _inventory[resource_name] == 0:
        _inventory.erase(resource_name)
    
    resource_removed.emit(resource_name, amount)
    inventory_changed.emit(inventory)
    return true

func has_resource(resource_name: String, amount: int = 1) -> bool:
    return _inventory.get(resource_name, 0) >= amount

func get_resource_count(resource_name: String) -> int:
    return _inventory.get(resource_name, 0)

func get_sellable_resources() -> Dictionary:
    var sellable := {}
    for resource in _inventory:
        if SELL_PRICES.has(resource) and SELL_PRICES[resource] > 0:
            sellable[resource] = _inventory[resource]
    return sellable

func get_sell_price(resource_name: String) -> int:
    return SELL_PRICES.get(resource_name, 0)

func get_total_sell_value() -> int:
    var total := 0
    for resource in get_sellable_resources():
        total += get_sellable_resources()[resource] * get_sell_price(resource)
    return total

func clear() -> void:
    _inventory.clear()
    inventory_changed.emit(inventory)

func reset() -> void:
    clear()
