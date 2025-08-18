class_name GameState
extends Resource

enum PlayerState { MINING, ON_SURFACE }
var current_state: PlayerState = PlayerState.ON_SURFACE:
    set(value):
        if current_state != value:
            current_state = value
            Event.state_changed.emit(current_state)

@export var depth: float = -2.0:
    set(value):
        if depth != value:
            depth = value
            Event.depth_changed.emit(depth)

@export var currency: int = 0:
    set(value):
        if currency != value:
            currency = value
            Event.currency_changed.emit(currency)

@export var mining_speed: float = 431.0
@export var max_mined_row: int = -1

func reset() -> void:
    depth = -2.0
    currency = 0
    mining_speed = 431.0
    max_mined_row = -1
    # BUGFIX: Use self to ensure the setter is called and the signal is emitted.
    self.current_state = PlayerState.MINING
