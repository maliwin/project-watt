class_name GameStateBase
extends State

var actor: Node
var state_machine: StateMachine
var game_state: GameState
var ui_manager: UIManager

func initialize(p_actor: Node, p_ui_manager: UIManager):
    actor = p_actor
    state_machine = get_parent() as StateMachine
    game_state = p_actor as GameState
    ui_manager = p_ui_manager
