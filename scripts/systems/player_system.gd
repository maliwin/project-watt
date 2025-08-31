class_name PlayerSystem
extends Node

enum CharacterState { IDLE, MINING, FALLING }

var _character_state := CharacterState.MINING
var _character_world_pos := Vector2i(0, -1)  # TODO: refactor
var _current_tool: MiningTool

func _ready():
    _current_tool = MiningTool.new()
    
    Event.game_tick.connect(_on_game_tick)
    Event.tile_mined_successfully.connect(_on_tile_mined)
    
    _start_mining_next_block()

func _on_game_tick(delta: float):
    pass

func get_character_world_pos() -> Vector2i:
    return _character_world_pos

# --- Auto-Mining Logic ---

func _start_mining_next_block():
    #if _character_state != CharacterState.MINING:
        #push_warning("Can't start mining next block because not in correct state.")
        #return
        
    # var mining_speed = _current_tool.get_mining_speed()
    var mining_speed = 0.0001
    Ticker.schedule(mining_speed, self, "_mine_block_below")

func _mine_block_below():
    var _character_state := CharacterState.MINING
    
    var target_pos = _character_world_pos + Vector2i(0, 1)
    
    GM.mining_system.attempt_mine_tile(target_pos, _current_tool)
    

func _on_tile_mined(tile_pos: Vector2i, _resources: Array[String]):
    _check_for_fall()

func _check_for_fall():
    var fall_distance_tiles = 0
    while GM.world_manager.is_tile_mined(_character_world_pos + Vector2i(0, fall_distance_tiles + 1)):
        # Placeholder until full world generation is implemented
        if _character_world_pos.y + fall_distance_tiles + 1 >= 5000:
            break
        fall_distance_tiles += 1
    
    if fall_distance_tiles > 0:
        _character_state = CharacterState.FALLING
        _character_world_pos.y += fall_distance_tiles
        
        Event.character_logical_position_changed.emit(_character_world_pos)
        
        var target_pixel_pos = _character_world_pos * Constants.TILE_SIZE
        # var fall_duration = sqrt(fall_distance_tiles * 0.1)
        var fall_duration = 0
        Event.character_fall_animation_started.emit(target_pixel_pos, fall_duration)
        
        var delay = clamp(fall_distance_tiles * 0.05, 0.1, 1.0)
        # Ticker.schedule(fall_duration + delay, self, "_on_fall_complete")
        Ticker.schedule(0.000001, self, "_on_fall_complete")
    else:
        _start_mining_next_block()

func _on_fall_complete():
    _start_mining_next_block()
