extends Control
class_name UIManager

# This script is now just a container for references. The Game States will use it.
@export var mining_view: Control
@export var surface_view: Control
@export var mining_panel: Control
@export var surface_panel: Control

func show_surface_view():
    mining_view.hide()
    mining_panel.hide()
    surface_view.show()
    surface_panel.show()

func show_mining_view():
    surface_view.hide()
    surface_panel.hide()
    mining_view.show()
    mining_panel.show()
