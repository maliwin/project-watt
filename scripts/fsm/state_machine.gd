class_name StateMachine
extends Node

var _current_state: State

var _states: Dictionary = {}

func _ready():
    for child in get_children():
        if child is State:
            _states[child.name.to_upper()] = child

func update(delta: float):
    if _current_state:
        _current_state.update(delta)

func change_state(state_name: String):
    var new_state_name = state_name.to_upper()
    if not _states.has(new_state_name):
        push_error("State '" + new_state_name + "' not found in StateMachine.")
        return

    if _current_state:
        _current_state.exit()

    _current_state = _states[new_state_name]
    _current_state.enter()
