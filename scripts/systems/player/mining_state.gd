class_name MiningState
extends State

@export var player: PlayerSystem

func enter():
    player.start_mining_next_block()

func update(_delta: float):
    if not player._auto_mine:
        player.state_machine.change_state("IDLE")

func exit():
    player.cancel_pending_mine()
