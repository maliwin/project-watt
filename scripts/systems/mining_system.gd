class_name MiningSystem
extends Node

# --- Dependencies ---
var inventory_system: InventorySystem
var world_manager: WorldManager

func _ready():
    Systems.mining = self

func initialize(p_inventory: InventorySystem, p_world_manager: WorldManager):
    inventory_system = p_inventory
    world_manager = p_world_manager

func attempt_mine_tile(tile_pos: Vector2i, tool: MiningTool):
    # 1. Rule Check: Is this tile already mined?
    if world_manager.is_tile_mined(tile_pos):
        Event.mining_failed.emit(tile_pos, "Tile already mined.")
        return

    # 2. Data Query: What is this tile made of?
    var tile_data = world_manager.get_tile_data(tile_pos)
    if tile_data == null or tile_data.rock == "air":
        Event.mining_failed.emit(tile_pos, "Cannot mine empty space.")
        return

    # 3. Rule Check: Is the tool strong enough?
    var tile_hardness = world_manager.current_planet.get_total_hardness(tile_data)
    if not tool.can_mine_hardness(tile_hardness):
        Event.mining_failed.emit(tile_pos, "Tool not strong enough.")
        # We still want to notify the PlayerSystem that the attempt is over.
        # A new signal is useful here for specific feedback.
        Event.mine_attempt_finished.emit()
        return

    # 4. Execution: The attempt is successful.
    # a. Tell the WorldManager to update its state.
    world_manager.destroy_tile(tile_pos)
    
    # b. Determine the resources yielded.
    var resources = _get_tile_resources(tile_data)
    
    # c. Tell the InventorySystem to add the resources.
    for resource in resources:
        inventory_system.add_to_pouch(resource)
    
    # d. Announce the success to the entire game.
    Event.tile_mined_successfully.emit(tile_pos, resources)


func _get_tile_resources(tile_data: Dictionary) -> Array[String]:
    var resources: Array[String] = []
    
    if tile_data.ore != "":
        resources.append(tile_data.ore)
    else:
        resources.append(tile_data.rock)
    
    return resources
