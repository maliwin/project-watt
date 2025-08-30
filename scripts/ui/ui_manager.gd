extends Control

@onready var mining_panel = $MiningPanel
@onready var surface_panel = $SurfacePanel
@onready var mining_view = $"../../MiningView" 

func _ready():
    # Event.state_changed.connect(_on_player_state_changed)
    
    mining_panel.return_to_surface_pressed.connect(GM.return_to_surface)
    surface_panel.continue_mine_pressed.connect(GM.continue_mine)
    surface_panel.start_new_mine_pressed.connect(GM.start_new_mine)
    
    # _on_player_state_changed(GM.game_state.current_state)
