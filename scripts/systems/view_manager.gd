extends Node
class_name ViewManager

@export var mining_view: Control
@export var surface_view: Control

func _ready():
    Systems.views = self

func show_view(view_name: String):
    mining_view.visible = (view_name == "MINING")
    surface_view.visible = (view_name == "SURFACE")
