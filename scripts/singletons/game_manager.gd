extends Node

# Public components - other systems can access these
@onready var game_state := GameState.new()
@onready var mining_tool := MiningTool.new()
@onready var inventory_system := InventorySystem.new()
@onready var tile_tracker := TileTracker.new()
@onready var mining_system := MiningSystem.new()
@onready var smelting_system := SmeltingSystem.new()
@onready var upgrade_system := UpgradeSystem.new()
@onready var world_data := WorldData.new()

var saved_mine_state: Dictionary = {}

func _ready() -> void:
    add_child(inventory_system)
    add_child(tile_tracker)
    add_child(mining_system)
    add_child(smelting_system)
    add_child(upgrade_system)
    
    mining_system.initialize(game_state, inventory_system, mining_tool, tile_tracker, world_data)
    upgrade_system.initialize(game_state, inventory_system, mining_tool)
    
    start_new_mine()

func return_to_surface():
    mining_system.stop_autominer()
    
    # BUGFIX: Save the raw data, not the node reference.
    saved_mine_state = {
        "tile_tracker_data": tile_tracker.get_state(),
        "depth": game_state.depth,
        "max_row": game_state.max_mined_row,
    }
    
    inventory_system.move_pouch_to_storage()
    
    # Clear the active tracker while on the surface.
    tile_tracker.reset()
    
    game_state.current_state = GameState.PlayerState.ON_SURFACE

func continue_mine():
    if not saved_mine_state:
        start_new_mine()
        return

    # BUGFIX: Restore the mine data using set_state.
    tile_tracker.set_state(saved_mine_state.get("tile_tracker_data"))
    game_state.depth = saved_mine_state.get("depth")
    game_state.max_mined_row = saved_mine_state.get("max_row")
    
    saved_mine_state.clear()
    
    game_state.current_state = GameState.PlayerState.MINING
    mining_system.start_autominer()

func start_new_mine():
    saved_mine_state.clear()
    
    tile_tracker.reset()
    
    game_state.reset()
    
    mining_system.start_autominer()

# --- Passthrough functions ---
func can_mine_tile(tile_pos: Vector2i) -> bool:
    return mining_system.can_mine_tile(tile_pos)

func player_mine_tile(tile_pos: Vector2i) -> bool:
    return mining_system.player_mine_tile(tile_pos)

func is_tile_mined(world_x: int, world_y: int) -> bool:
    return tile_tracker.is_tile_mined(Vector2i(world_x, world_y))

func upgrade_pickaxe() -> bool:
    return upgrade_system.upgrade_pickaxe()

func get_depth_per_tile() -> float:
    return WorldData.DEPTH_PER_TILE

var auto_mine_x: int:
    get: return mining_system.auto_mine_column
    set(value): mining_system.auto_mine_column = value
