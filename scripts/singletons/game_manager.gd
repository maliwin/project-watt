extends Node

# @export var starting_planet: PlanetData
var starting_planet: PlanetData = load("res://resources/planets/00_aethel.tres")


var mining_tool := MiningTool.new()

@onready var world_manager: WorldManager = $/root/Main/Systems/WorldManager
@onready var player_system: PlayerSystem = $/root/Main/Systems/PlayerSystem
@onready var mining_system: MiningSystem = $/root/Main/Systems/MiningSystem

# TODO: refactor
@onready var inventory_system := InventorySystem.new()
@onready var smelting_system := SmeltingSystem.new()
@onready var upgrade_system := UpgradeSystem.new()

var saved_mine_state: Dictionary = {}


func _ready() -> void:
    mining_system.initialize(inventory_system, world_manager)


func return_to_surface():
    saved_mine_state = {
        "mined_tiles": world_manager.mined_tiles.duplicate(),
        "player_pos": player_system.get_character_world_pos(),
    }
    
    inventory_system.move_pouch_to_storage()
    
    player_system.stop_mining()


func continue_mine():
    if saved_mine_state.is_empty():
        start_new_mine()  # TODO: refactor
        return

    world_manager.mined_tiles = saved_mine_state.get("mined_tiles")
    
    player_system.start_from_position(saved_mine_state.get("player_pos"))
    
    saved_mine_state.clear()


func start_new_mine():
    if starting_planet == null:
        push_error("GameManager: 'Starting Planet' resource is not set in the Inspector!")
        return
        
    saved_mine_state.clear()
    world_manager.initialize_mine(starting_planet)
    inventory_system.reset()
    
    var start_pos = Vector2i(0, -5)
    Event.game_started.emit(start_pos)
