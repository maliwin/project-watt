class_name MiningGameState
extends GameStateBase

func enter():
    # Show the mining view and panel, hide the surface ones.
    mining_view.visible = true
    surface_view.visible = false
    ui_manager.show_mining_panel()

    # Logic for starting or continuing a mine would go here.

func exit():
    # Save the game state before leaving the mine.
    var saved_data = {
        "mined_tiles": Systems.world.mined_tiles.duplicate(),
        "player_pos": Systems.player.get_character_world_pos(),
    }
    # TODO: Store this data somewhere accessible by the SurfaceGameState.

    Systems.inventory.move_pouch_to_storage()
    Systems.player.on_return_to_surface()
