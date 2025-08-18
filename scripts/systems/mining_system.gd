class_name MiningSystem
extends Node


@export var auto_mine_column: int = 12

var game_state: GameState
var inventory_system: InventorySystem 
var mining_tool: MiningTool
var tile_tracker: TileTracker
var world_data: WorldData

var _auto_mine_timer: Timer
var _auto_mine_accumulator: float = 0.0
const AUTO_MINE_TICK_INTERVAL: float = 0.1

func _ready() -> void:
    # Set up the timer here, but DO NOT start it.
    _auto_mine_timer = Timer.new()
    _auto_mine_timer.wait_time = AUTO_MINE_TICK_INTERVAL
    _auto_mine_timer.one_shot = false
    _auto_mine_timer.timeout.connect(_on_auto_mine_tick)
    add_child(_auto_mine_timer)

func initialize(p_game_state: GameState, p_inventory: InventorySystem, p_tool: MiningTool, p_tracker: TileTracker, p_world_data: WorldData) -> void:
    game_state = p_game_state
    inventory_system = p_inventory  
    mining_tool = p_tool
    tile_tracker = p_tracker
    world_data = p_world_data
    
    _auto_mine_timer.start()

func can_mine_tile(tile_pos: Vector2i) -> bool:
    if tile_tracker.is_tile_mined(tile_pos):
        return false
    
    var depth := tile_pos.y * world_data.DEPTH_PER_TILE
    var rock_name := world_data.get_rock_name_for_depth(depth)
    var hardness := world_data.get_rock_hardness(rock_name)
    
    return mining_tool.can_mine_hardness(hardness)

func mine_tile(tile_pos: Vector2i, is_auto_mining: bool = false) -> bool:
    if not can_mine_tile(tile_pos):
        Event.mining_failed.emit(tile_pos, "Cannot mine this tile")
        return false
    
    tile_tracker.mine_tile(tile_pos)
    
    if tile_pos.x == auto_mine_column and tile_pos.y > game_state.max_mined_row:
        if is_auto_mining:
            game_state.max_mined_row = tile_pos.y
            game_state.depth += world_data.DEPTH_PER_TILE
            Event.auto_mining_progressed.emit(game_state.depth)
    
    var resources := _get_tile_resources(tile_pos)
    for resource in resources:
        inventory_system.add_to_pouch(resource)
    
    Event.tile_mined_successfully.emit(tile_pos, resources)
    
    if randf() < 0.01:
        tile_tracker.clear_distant_chunks(tile_pos)
    
    return true

func player_mine_tile(tile_pos: Vector2i) -> bool:
    return mine_tile(tile_pos, false)

func _on_auto_mine_tick() -> void:
    var mining_speed := game_state.mining_speed
    
    _auto_mine_accumulator += mining_speed * AUTO_MINE_TICK_INTERVAL
    
    while _auto_mine_accumulator >= 1.0:
        _auto_mine_accumulator -= 1.0
        _auto_mine_next_tile()

func _auto_mine_next_tile() -> void:
    var next_row := game_state.max_mined_row + 1
    var target := Vector2i(auto_mine_column, next_row)
    
    while tile_tracker.is_tile_mined(target):
        game_state.max_mined_row = target.y
        game_state.depth += world_data.DEPTH_PER_TILE
        Event.auto_mining_progressed.emit(game_state.depth)
        target.y += 1
    
    mine_tile(target, true)

func _get_tile_resources(tile_pos: Vector2i) -> Array[String]:
    var resources: Array[String] = []
    
    var ore := world_data.get_ore_at_position(tile_pos.x, tile_pos.y, auto_mine_column)
    if ore != "":
        resources.append(ore)
    else:
        var depth := tile_pos.y * world_data.DEPTH_PER_TILE
        var rock_name := world_data.get_rock_name_for_depth(depth)
        resources.append(rock_name)
    
    return resources

func reset() -> void:
    _auto_mine_accumulator = 0.0
    if tile_tracker:
        tile_tracker.reset()
