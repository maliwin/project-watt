class_name GameState
extends Resource

signal depth_changed(new_depth: float)
signal currency_changed(new_currency: int)
signal state_changed(new_state: PlayerState)

enum PlayerState { MINING, ON_SURFACE }
var current_state: PlayerState = PlayerState.MINING:
    set(value):
        if current_state != value:
            current_state = value
            state_changed.emit(current_state)

@export var depth: float = 0.0:
    set(value):
        if depth != value:
            depth = value
            depth_changed.emit(depth)

@export var currency: int = 0:
    set(value):
        if currency != value:
            currency = value
            currency_changed.emit(currency)

@export var mining_speed: float = 61.0
@export var max_mined_row: int = -1

func reset() -> void:
    depth = 0.0
    currency = 0
    mining_speed = 0.5
    max_mined_row = -1
    current_state = PlayerState.MINING
    
