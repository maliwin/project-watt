class_name IdleState
extends State

@export var player: PlayerSystem

func enter():
    pass

func update(_delta: float):
    if player._auto_mine:
        player.state_machine.change_state("MINING")
