class_name FallingState
extends State

@export var player: PlayerSystem

func enter():
    var fall_distance = player.calculate_fall_distance()
    if fall_distance > 0:
        player.execute_fall(fall_distance)
    else:
        player.on_fall_complete()

func update(_delta: float):
    # While falling, we don't do anything. We wait for the fall to complete.
    pass
