extends Node

func _unhandled_input(event: InputEvent) -> void:
    # We only handle global clicks here now. Zooming is handled by MiningView.
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Event.screen_clicked.emit(event.position)
