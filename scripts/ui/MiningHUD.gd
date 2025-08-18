extends Control

signal return_to_surface_pressed

func _on_return_button_pressed():
    return_to_surface_pressed.emit()
