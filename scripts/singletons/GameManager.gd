extends Node

# Public components - other systems can access these
@onready var game_state := GameState.new()
@onready var mining_tool := MiningTool.new()
@onready var inventory_system := InventorySystem.new()
@onready var tile_tracker := TileTracker.new()
@onready var mining_system := MiningSystem.new()
@onready var upgrade_system := UpgradeSystem.new()
@onready var world_data := WorldData.new()

func _ready() -> void:
    add_child(inventory_system)
    add_child(tile_tracker) 
    add_child(mining_system)
    add_child(upgrade_system)
    
    mining_system.initialize(game_state, inventory_system, mining_tool, tile_tracker, world_data)
    upgrade_system.initialize(game_state, inventory_system, mining_tool)
    
    _setup_signal_connections()

func _setup_signal_connections() -> void:
    pass

func can_mine_tile(tile_pos: Vector2i) -> bool:
    return mining_system.can_mine_tile(tile_pos)

func player_mine_tile(tile_pos: Vector2i) -> bool:
    return mining_system.player_mine_tile(tile_pos)

func is_tile_mined(world_x: int, world_y: int) -> bool:
    return tile_tracker.is_tile_mined(Vector2i(world_x, world_y))

func upgrade_pickaxe() -> bool:
    return upgrade_system.upgrade_pickaxe()

func sell_all() -> void:
    upgrade_system.sell_all_resources()

func get_depth_per_tile() -> float:
    return WorldData.DEPTH_PER_TILE

func query_ore_at(world_x: int, world_y: int) -> String:
    return world_data.get_ore_at_position(world_x, world_y, auto_mine_x)

func reset_game() -> void:
    game_state.reset()
    mining_tool.reset()
    inventory_system.reset()
    tile_tracker.reset()
    mining_system.reset()

var auto_mine_x: int:
    get: return mining_system.auto_mine_column
    set(value): mining_system.auto_mine_column = value
