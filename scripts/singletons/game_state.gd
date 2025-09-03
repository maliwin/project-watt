extends Node

var state_machine: StateMachine
var _is_initialized := false

func _ready():
    Event.game_state_change_requested.connect(_on_game_state_change_requested)

func initialize(p_state_machine: StateMachine, p_ui_manager: UIManager):
    state_machine = p_state_machine
    
    # Pass the ui_manager reference to each child state.
    for state in state_machine.get_children():
        if state is GameStateBase:
            state.initialize(self, p_ui_manager)
            
    _is_initialized = true
    # Now that everything is connected, we can safely change to the initial state.
    state_machine.change_state("MINING")

func _on_game_state_change_requested(target_state_name: String):
    if not _is_initialized:
        push_warning("GameState FSM not initialized yet, cannot change state.")
        return
    state_machine.change_state(target_state_name)
