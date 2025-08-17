class_name GameState
extends Resource

# Signals for state changes
signal depth_changed(new_depth: float)
signal currency_changed(new_currency: int)

# Core game state with proper typing
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

@export var mining_speed: float = 0.5
@export var max_mined_row: int = -1

# Initialize with default values
func _init():
    depth = 0.0
    currency = 0
    mining_speed = 0.5
    max_mined_row = -1

func reset() -> void:
    depth = 0.0
    currency = 0
    mining_speed = 0.5
    max_mined_row = -1
    
