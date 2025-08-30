# warning-disable unused_signal
extends Node

signal tool_upgraded(tool: MiningTool)


signal depth_changed(new_depth: float)
signal currency_changed(new_currency: int)
signal state_changed(new_state)


signal tile_mined_successfully(tile_pos: Vector2i, resources: Array[String])
signal mining_failed(tile_pos: Vector2i, reason: String)
signal auto_mining_progressed(new_depth: float)


signal upgrade_purchased(upgrade_type: String, new_level: int)
signal upgrade_failed(upgrade_type: String, reason: String)


signal smelt_complete(bar_type: String, amount: int)

signal player_clicked_tile(grid_pos)

signal zoom_level_changed(zoom_in)
signal screen_clicked(screen_position)


signal character_logical_position_changed(new_world_pos: Vector2i)
signal character_fall_animation_started(target_pixel_pos: Vector2, duration: float)
