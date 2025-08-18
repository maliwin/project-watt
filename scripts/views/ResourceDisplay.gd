extends RichTextLabel

# This component will now display different inventories based on the game state.
# We'll use a variable to track which inventory we should be showing.
enum DisplayMode { POUCH, STORAGE }
var current_mode: DisplayMode = DisplayMode.POUCH # Default to showing the pouch

var _cached_inventory: Dictionary = {}

func _ready():
    # Connect to the new inventory signals.
    GM.inventory_system.pouch_changed.connect(_on_pouch_changed)
    GM.inventory_system.storage_changed.connect(_on_storage_changed)
    
    # We also need to know when the player's state changes to switch modes.
    GM.game_state.state_changed.connect(_on_player_state_changed)
    
    # Initial setup
    _on_player_state_changed(GM.game_state.current_state)

func _on_pouch_changed(new_pouch: Dictionary):
    # Only update if we are currently supposed to be showing the pouch.
    if current_mode == DisplayMode.POUCH:
        _update_display("Mining Pouch", new_pouch)

func _on_storage_changed(new_storage: Dictionary):
    # Only update if we are currently supposed to be showing the storage.
    if current_mode == DisplayMode.STORAGE:
        _update_display("Surface Storage", new_storage)

func _on_player_state_changed(new_state: GameState.PlayerState):
    if new_state == GameState.PlayerState.MINING:
        current_mode = DisplayMode.POUCH
        # When we switch to mining, immediately update with the latest pouch contents.
        _update_display("Mining Pouch", GM.inventory_system.get_pouch_contents())
    else: # ON_SURFACE
        current_mode = DisplayMode.STORAGE
        # When we switch to the surface, update with the latest storage contents.
        _update_display("Surface Storage", GM.inventory_system.get_storage_contents())

# A generalized function to render any given inventory.
func _update_display(title: String, inventory: Dictionary):
    # Avoid unnecessary updates if the inventory hasn't changed.
    if _cached_inventory.hash() == inventory.hash():
        return
    _cached_inventory = inventory.duplicate()
    
    clear() # Clears the RichTextLabel
    
    # Use BBCode for simple formatting
    push_bold()
    append_text(title)
    pop()
    
    newline()
    
    if inventory.is_empty():
        append_text("No resources yet.")
        return
        
    var sorted_keys: Array = inventory.keys()
    sorted_keys.sort()
        
    for resource_name in sorted_keys:
        var amount: int = inventory[resource_name]
        if amount > 0:
            # We no longer need to show sell prices here.
            append_text("\n- %s: %d" % [resource_name, amount])
