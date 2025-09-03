extends Control

@export var ui_manager: UIManager
@export var view_manager: ViewManager
@export var game_state_fsm: StateMachine 

func _ready():
    GameState.initialize(game_state_fsm, ui_manager)
