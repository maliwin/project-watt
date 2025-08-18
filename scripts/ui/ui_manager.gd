extends Control

# These variables connect to the scenes we just instanced.
@onready var mining_hud = $MiningHUD
@onready var surface_hud = $SurfaceHUD

func _ready():
    # Listen for the state change signal from our GameState.
    Event.state_changed.connect(_on_player_state_changed)
    
    mining_hud.return_to_surface_pressed.connect(GM.return_to_surface)
    
    # Set the initial UI state when the game starts.
    _on_player_state_changed(GM.game_state.current_state)

# This function shows/hides the correct HUD based on the player's state.
func _on_player_state_changed(new_state: GameState.PlayerState):
    if new_state == GameState.PlayerState.MINING:
        mining_hud.show()
        surface_hud.hide()
    elif new_state == GameState.PlayerState.ON_SURFACE:
        mining_hud.hide()
        surface_hud.show()
