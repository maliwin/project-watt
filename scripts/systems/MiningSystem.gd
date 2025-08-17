class_name MiningSystem
extends Node

# Typed signals - no more magic strings!
signal tile_mined_successfully(tile_pos: Vector2i, resources: Array[String])
signal mining_failed(tile_pos: Vector2i, reason: String)
signal auto_mining_progressed(new_depth: float)

@export var auto_mine_column: int = 12

# Dependencies - injected, not global singletons
var game_state: GameState
var inventory_system: InventorySystem 
var mining_tool: MiningTool
var tile_tracker: TileTracker

# Auto-mining system
var _auto_mine_timer: Timer
var _auto_mine_accumulator: float = 0.0
const AUTO_MINE_TICK_INTERVAL: float = 0.1

func _ready() -> void:
    _setup_auto_mining_timer()

func initialize(p_game_state: GameState, p_inventory: InventorySystem, p_tool: MiningTool, p_tracker: TileTracker) -> void:
    game_state = p_game_state
    inventory_system = p_inventory  
    mining_tool = p_tool
    tile_tracker = p_tracker

func can_mine_tile(tile_pos: Vector2i) -> bool:
    # Already mined?
    if tile_tracker.is_tile_mined(tile_pos):
        return false
    
    # Tool powerful enough?
    var depth := tile_pos.y * WorldData.DEPTH_PER_TILE
    var rock_name := WorldData.get_rock_name_for_depth(depth)
    var hardness := WorldData.get_rock_hardness(rock_name)
    
    return mining_tool.can_mine_hardness(hardness)

func mine_tile(tile_pos: Vector2i, is_auto_mining: bool = false) -> bool:
    if not can_mine_tile(tile_pos):
        mining_failed.emit(tile_pos, "Cannot mine this tile")
        return false
    
    # Mark as mined
    tile_tracker.mine_tile(tile_pos)
    
    # Update progression for center column only
    if tile_pos.x == auto_mine_column and tile_pos.y > game_state.max_mined_row:
        # Auto-mining advances depth
        if is_auto_mining:
            game_state.max_mined_row = tile_pos.y
            game_state.depth += WorldData.DEPTH_PER_TILE
            auto_mining_progressed.emit(game_state.depth)
    
    # Give resources
    var resources := _get_tile_resources(tile_pos)
    for resource in resources:
        inventory_system.add_resource(resource)
    
    tile_mined_successfully.emit(tile_pos, resources)
    
    # Clean up distant tiles periodically
    if randf() < 0.01:  # 1% chance per mine
        tile_tracker.clear_distant_chunks(tile_pos)
    
    return true

func player_mine_tile(tile_pos: Vector2i) -> bool:
    return mine_tile(tile_pos, false)

# Auto-mining system
func _setup_auto_mining_timer() -> void:
    _auto_mine_timer = Timer.new()
    _auto_mine_timer.wait_time = AUTO_MINE_TICK_INTERVAL
    _auto_mine_timer.one_shot = false
    _auto_mine_timer.timeout.connect(_on_auto_mine_tick)
    add_child(_auto_mine_timer)
    _auto_mine_timer.start()

func _on_auto_mine_tick() -> void:
    if not game_state:
        return
        
    var mining_speed := game_state.mining_speed
    if mining_speed <= 0.0:
        return
    
    _auto_mine_accumulator += mining_speed * AUTO_MINE_TICK_INTERVAL
    
    while _auto_mine_accumulator >= 1.0:
        _auto_mine_accumulator -= 1.0
        _auto_mine_next_tile()

func _auto_mine_next_tile() -> void:
    var next_row := game_state.max_mined_row + 1
    var target := Vector2i(auto_mine_column, next_row)
    
    while tile_tracker.is_tile_mined(target):
        # Update state as we "fall" through the empty space
        game_state.max_mined_row = target.y
        game_state.depth += WorldData.DEPTH_PER_TILE
        auto_mining_progressed.emit(game_state.depth)
        # Move to the next tile down
        target.y += 1
    
    mine_tile(target, true)

# Resource generation
func _get_tile_resources(tile_pos: Vector2i) -> Array[String]:
    var resources: Array[String] = []
    
    # Check for ore first
    var ore := WorldData.get_ore_at_position(tile_pos.x, tile_pos.y)
    if ore != "":
        resources.append(ore)
    else:
        # Give base rock material
        var depth := tile_pos.y * WorldData.DEPTH_PER_TILE
        var rock_name := WorldData.get_rock_name_for_depth(depth)
        resources.append(rock_name)
    
    return resources

func reset() -> void:
    _auto_mine_accumulator = 0.0
    if tile_tracker:
        tile_tracker.reset()
