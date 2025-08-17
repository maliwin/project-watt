extends Node

# Public components - other systems can access these
@onready var game_state := GameState.new()
@onready var mining_tool := MiningTool.new()
@onready var inventory_system := InventorySystem.new()
@onready var tile_tracker := TileTracker.new()
@onready var mining_system := MiningSystem.new()
@onready var upgrade_system := UpgradeSystem.new()

func _ready() -> void:
    # Add systems as children
    add_child(inventory_system)
    add_child(tile_tracker) 
    add_child(mining_system)
    add_child(upgrade_system)
    
    # Initialize system dependencies
    mining_system.initialize(game_state, inventory_system, mining_tool, tile_tracker)
    upgrade_system.initialize(game_state, inventory_system, mining_tool)
    
    # Connect cross-system signals if needed
    _setup_signal_connections()

func _setup_signal_connections() -> void:
    # Example: Could connect mining_system.auto_mining_progressed to UI updates
    pass

# Public API methods - delegate to appropriate systems
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
    return WorldData.get_ore_at_position(world_x, world_y)

func reset_game() -> void:
    game_state.reset()
    mining_tool.reset()
    inventory_system.reset()
    tile_tracker.reset()
    mining_system.reset()

# Backwards compatibility getters (temporary during transition)
var game_data: Dictionary:
    get:
        return {
            "depth": game_state.depth,
            "currency": game_state.currency,
            "inventory": inventory_system.inventory,
            "tool": {
                "name": mining_tool.tool_name,
                "level": mining_tool.level,
                "power": mining_tool.power,
                "crit_chance": mining_tool.crit_chance
            },
            "mining_speed": game_state.mining_speed,
            "max_mined_row": game_state.max_mined_row
        }

var auto_mine_x: int:
    get: return mining_system.auto_mine_column
    set(value): mining_system.auto_mine_column = value

# Signal forwarding for backwards compatibility
func get_tool() -> Dictionary:
    return {
        "name": mining_tool.tool_name,
        "level": mining_tool.level,
        "power": mining_tool.power,
        "crit_chance": mining_tool.crit_chance
    }
