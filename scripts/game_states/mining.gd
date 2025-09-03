class_name MiningGameState
extends GameStateBase

func enter():
    Systems.views.show_view("MINING")
    ui_manager.show_mining_view()

func exit():
    var saved_data = {
        "mined_tiles": Systems.world.mined_tiles.duplicate(),
        "player_pos": Systems.player.get_character_world_pos(),
    }
    var surface_state = state_machine.get_state("SURFACE")
    surface_state.set_saved_mine_data(saved_data)

    Systems.inventory.move_pouch_to_storage()
    Systems.player.on_return_to_surface()
