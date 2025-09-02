extends RichTextLabel

# This component will now display different inventories based on the game state.
# We'll use a variable to track which inventory we should be showing.
enum DisplayMode { POUCH, STORAGE }
var current_mode: DisplayMode = DisplayMode.POUCH # Default to showing the pouch

var _cached_inventory: Dictionary = {}

#func _ready():
    ## Connect to the new inventory signals.
    #await get_tree().process_frame
    #Systems.inventory.pouch_changed.connect(_on_pouch_changed)
    #Systems.inventory.storage_changed.connect(_on_storage_changed)



func _ready():
    # call_deferred() will execute the function on the main thread during idle time,
    # which happens after all nodes have finished their _ready() calls.
    # This is a very safe and common way to handle initialization order.
    call_deferred("_connect_to_systems")

func _connect_to_systems():
    # This code is now guaranteed to run after the Systems singleton is
    # available and all systems have had a chance to register themselves.
    if Systems and Systems.inventory:
        Systems.inventory.pouch_changed.connect(_on_pouch_changed)
        Systems.inventory.storage_changed.connect(_on_storage_changed)
    else:
        push_error("Could not connect to InventorySystem. Is it registered correctly in the Systems singleton?")


func _on_pouch_changed(new_pouch: Dictionary):
    # Only update if we are currently supposed to be showing the pouch.
    if current_mode == DisplayMode.POUCH:
        _update_display("Mining Pouch", new_pouch)

func _on_storage_changed(new_storage: Dictionary):
    # Only update if we are currently supposed to be showing the storage.
    if current_mode == DisplayMode.STORAGE:
        _update_display("Surface Storage", new_storage)

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
