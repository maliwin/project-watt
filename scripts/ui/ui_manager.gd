extends Control

@onready var mining_panel = $MiningPanel
@onready var surface_panel = $SurfacePanel
@onready var mining_view = $"../../MiningView" 

# TODO: add as dependency
@onready var player_system: PlayerSystem = $/root/Main/Systems/PlayerSystem

func _ready():
    # Event.state_changed.connect(_on_player_state_changed)
    
    mining_panel.return_to_surface_pressed.connect(GM.return_to_surface)
    surface_panel.continue_mine_pressed.connect(GM.continue_mine)
    surface_panel.start_new_mine_pressed.connect(GM.start_new_mine)
    
    mining_view.auto_mining_toggled.connect(player_system.set_auto_mine)
    # _on_player_state_changed(GM.game_state.current_state)
