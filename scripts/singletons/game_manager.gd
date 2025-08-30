extends Node

@export var starting_planet: PlanetData

var mining_tool := MiningTool.new()

# --- System References ---
# These are the major systems of the game. We get them from the scene tree.
@onready var world_manager: WorldManager = $/root/Main/Systems/WorldManager
@onready var player_system: PlayerSystem = $/root/Main/Systems/PlayerSystem
@onready var mining_system: MiningSystem = $/root/Main/Systems/MiningSystem
# Note: You would add @onready vars for your other systems (Inventory, Smelting, etc.) here as you create them.
@onready var inventory_system := InventorySystem.new()
@onready var smelting_system := SmeltingSystem.new()
@onready var upgrade_system := UpgradeSystem.new()

# --- State ---
var saved_mine_state: Dictionary = {}


func _ready() -> void:
    # "Wire up" the systems by passing them the dependencies they need.
    # This is a clean way to manage dependencies without tight coupling.
    mining_system.initialize(inventory_system, world_manager)
    # You would continue to initialize your other systems here.
    
    # Start the game for the first time.
    start_new_mine()


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
    
    # player_system.start_new_mine()
