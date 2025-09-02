extends Control

signal continue_mine_pressed
signal start_new_mine_pressed

@onready var smelting_grid: GridContainer = %SmeltingGrid
@onready var continue_button: Button = %ContinueButton
@onready var new_mine_button: Button = %NewMineButton

func _ready():
    await get_tree().process_frame
    continue_button.pressed.connect(func(): continue_mine_pressed.emit())
    new_mine_button.pressed.connect(func(): start_new_mine_pressed.emit())
    
    visibility_changed.connect(_on_visibility_changed)
    
    _build_smelting_buttons()
    Systems.inventory.storage_changed.connect(_update_smelting_buttons)


func _on_visibility_changed():
    if is_visible():
        # Disable the continue button if there is no saved mine.
        # continue_button.disabled = GM.saved_mine_state.is_empty()
        pass


func _build_smelting_buttons():
    for ore_type in SmeltingSystem.SMELT_RECIPES:
        var recipe = SmeltingSystem.SMELT_RECIPES[ore_type]
        var btn := Button.new()
        btn.name = ore_type
        var cost_text_arr = []
        for item in recipe.cost:
            cost_text_arr.append("%d %s" % [recipe.cost[item], item])
        var cost_text = ", ".join(cost_text_arr)
        
        btn.text = "Smelt %s" % recipe.output
        btn.tooltip_text = "Cost: %s" % cost_text
        # btn.pressed.connect(func(): GM.smelting_system.start_smelting(ore_type))
        smelting_grid.add_child(btn)
    _update_smelting_buttons()


func _update_smelting_buttons(_storage = null):
    for ore_type in SmeltingSystem.SMELT_RECIPES:
        var btn: Button = smelting_grid.find_child(ore_type, false)
        #if btn:
            #btn.disabled = not GM.smelting_system.can_smelt(ore_type)
