class_name InventorySystem
extends Node

signal pouch_changed(inventory: Dictionary)
signal storage_changed(inventory: Dictionary)

#const SELL_PRICES := {
    #"Dirt": 1, "Stone": 2, "Deep Stone": 3, "Bedrock": 0, "Lava Rock": 4,
    #"Copper": 5, "Iron": 8, "Silver": 12, "Gold": 20, "Obsidian": 25,
    #"Copper Bar": 15, "Iron Bar": 24
#}

var _pouch: Dictionary = {}
var _storage: Dictionary = {}

# --- POUCH FUNCTIONS ---
func add_to_pouch(resource_name: String, amount: int = 1):
    _pouch[resource_name] = _pouch.get(resource_name, 0) + amount
    pouch_changed.emit(_pouch.duplicate())

func get_pouch_contents() -> Dictionary:
    return _pouch.duplicate()

# --- STORAGE FUNCTIONS ---
func add_to_storage(resource_name: String, amount: int = 1):
    _storage[resource_name] = _storage.get(resource_name, 0) + amount
    storage_changed.emit(_storage.duplicate())

func remove_from_storage(resource_name: String, amount: int = 1) -> bool:
    if _storage.get(resource_name, 0) < amount:
        return false
    _storage[resource_name] -= amount
    if _storage[resource_name] == 0:
        _storage.erase(resource_name)
    storage_changed.emit(_storage.duplicate())
    return true

func get_storage_contents() -> Dictionary:
    return _storage.duplicate()

func has_in_storage(requirements: Dictionary) -> bool:
    for item in requirements:
        if _storage.get(item, 0) < requirements[item]:
            return false
    return true

func move_pouch_to_storage():
    for item in _pouch:
        add_to_storage(item, _pouch[item])
    _pouch.clear()
    pouch_changed.emit(_pouch.duplicate())

func reset():
    _pouch.clear()
    _storage.clear()
    pouch_changed.emit(_pouch.duplicate())
    storage_changed.emit(_storage.duplicate())
