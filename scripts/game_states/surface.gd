class_name SurfaceGameState
extends GameStateBase

var _saved_mine_data: Dictionary = {}

func enter():
    Systems.views.show_view("SURFACE")
    ui_manager.show_surface_view()
    ui_manager.surface_panel.set_continue_button_visibility(not _saved_mine_data.is_empty())

func set_saved_mine_data(data: Dictionary):
    _saved_mine_data = data

func get_saved_mine_data() -> Dictionary:
    return _saved_mine_data
