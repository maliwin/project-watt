class_name PlayerSystem
extends Node

@onready var state_machine: StateMachine = $StateMachine

var _character_world_pos := Vector2i(0, -1)
var _current_tool: MiningTool
var _auto_mine := false
var _mining_event_id: int = -1


func _ready():
    _current_tool = MiningTool.new()
    
    Event.game_tick.connect(_on_game_tick)
    Event.tile_mined_successfully.connect(_on_tile_mined)
    
    state_machine.change_state("IDLE")
    
    Systems.player = self


func _on_game_tick(delta: float):
    state_machine.update(delta)


# --- Public Commands (called by UI / other systems) ---

func set_auto_mine(auto_mine_on: bool):
    print("Auto-mine toggled to: ", auto_mine_on)
    _auto_mine = auto_mine_on

func return_to_surface():
    _auto_mine = false
    state_machine.change_state("IDLE")

# --- Helper Functions (called by States) ---

func start_mining_next_block():
    if _mining_event_id != -1: return
    var mining_speed = 0.1 # Faster for testing
    _mining_event_id = Ticker.schedule(mining_speed, self, "_mine_block_below")

func cancel_pending_mine():
    if _mining_event_id != -1:
        Ticker.cancel_event(_mining_event_id)
        _mining_event_id = -1
        
func calculate_fall_distance() -> int:
    var fall_distance = 0
    while Systems.world.is_tile_mined(_character_world_pos + Vector2i(0, fall_distance + 1)):
        if _character_world_pos.y + fall_distance + 1 >= 5000: break
        fall_distance += 1
    return fall_distance

func execute_fall(distance: int):
    _character_world_pos.y += distance
    Event.character_logical_position_changed.emit(_character_world_pos)
    
    var target_pixel_pos = _character_world_pos * Constants.TILE_SIZE
    var fall_duration = sqrt(distance * 0.1)
    Event.character_fall_animation_started.emit(target_pixel_pos, fall_duration)
    
    var delay = clamp(distance * 0.05, 0.1, 1.0)
    Ticker.schedule(fall_duration + delay, self, "on_fall_complete")

func on_fall_complete():
    if calculate_fall_distance() > 0:
        state_machine.change_state("FALLING")
    elif _auto_mine:
        state_machine.change_state("MINING")
    else:
        state_machine.change_state("IDLE")
        
func get_character_world_pos() -> Vector2i:
    return _character_world_pos

# --- Private Logic ---

func _on_tile_mined(_tile_pos: Vector2i, _resources: Array[String]):
    if calculate_fall_distance() > 0:
        state_machine.change_state("FALLING")
    elif state_machine._current_state.name.to_upper() == "MINING" and _auto_mine:
        start_mining_next_block()
    else:
        state_machine.change_state("IDLE")

func _mine_block_below():
    _mining_event_id = -1
    if state_machine._current_state.name.to_upper() != "MINING": return
    var target_pos = _character_world_pos + Vector2i(0, 1)
    Systems.mining.attempt_mine_tile(target_pos, _current_tool)
