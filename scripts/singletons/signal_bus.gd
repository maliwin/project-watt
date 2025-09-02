# warning-disable unused_signal
extends Node

# Game State
# High-level signals for managing game screens, scenes, and major state transitions
signal game_state_change_requested(target_state_name: String)
signal game_started(start_pos: Vector2i)


# Core Loop
signal game_tick(delta: float)


# Player & Character
signal character_logical_position_changed(new_world_pos: Vector2i)
signal character_fall_animation_started(target_pixel_pos: Vector2, duration: float)
signal tool_upgraded(tool: MiningTool)
signal depth_changed(new_depth: float)
signal currency_changed(new_currency: int)


# Gameplay Events
signal tile_mined_successfully(tile_pos: Vector2i, resources: Array[String])
signal mining_failed(tile_pos: Vector2i, reason: String)
signal mine_attempt_finished
signal auto_mining_progressed(new_depth: float)
signal smelt_complete(bar_type: String, amount: int)


# Progression & Unlocks
signal stat_updated(stat_name: StringName, new_value: Variant)
signal item_crafted(item_id: StringName)
signal upgrade_purchased(upgrade_type: String, new_level: int)
signal upgrade_failed(upgrade_type: String, reason: String)


# Input
signal player_clicked_tile(grid_pos)
signal zoom_level_changed(zoom_in)
signal screen_clicked(screen_position)
