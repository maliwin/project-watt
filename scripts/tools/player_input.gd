extends Node

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            Event.zoom_level_changed.emit(true)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            Event.zoom_level_changed.emit(false)

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        Event.screen_clicked.emit(event.position)
