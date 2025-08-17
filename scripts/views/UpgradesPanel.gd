extends VBoxContainer

func _ready() -> void:
    # This panel builds its OWN buttons
    _build_buttons()

    # And connects the signals needed to update them
    _connect_button_signals()

    # And updates their initial state
    _update_button_states()

func _connect_button_signals() -> void:
    # Connect to signals that affect button state (e.g., can_afford)
    GM.game_state.currency_changed.connect(_update_button_states)
    GM.mining_tool.tool_upgraded.connect(_update_button_states)

func _build_buttons() -> void:
    # Clear previous buttons
    for child in self.get_children():
        child.queue_free()

    # Sell All Button
    var sell_btn := Button.new()
    sell_btn.text = "Sell All"
    sell_btn.tooltip_text = "Sell all resources for currency"
    sell_btn.pressed.connect(_on_sell_all_pressed)
    self.add_child(sell_btn)

    # Upgrade Pickaxe Button
    var upg_btn := Button.new()
    upg_btn.name = "UpgradePickaxe"
    upg_btn.pressed.connect(_on_upgrade_pickaxe_pressed)
    self.add_child(upg_btn)
    
    _update_button_states()

func _on_sell_all_pressed() -> void:
    GM.sell_all()

func _on_upgrade_pickaxe_pressed() -> void:
    GM.upgrade_pickaxe()

func _update_button_states() -> void:
    print("updating... can i really not afford? ")
    var upg_btn: Button = self.get_node_or_null("UpgradePickaxe")
    if upg_btn == null:
        return
    
    var cost: int = GM.mining_tool.get_upgrade_cost()
    var can_afford: bool = GM.game_state.currency >= cost
    
    upg_btn.text = "Upgrade Pickaxe ($%d)" % cost
    # print("updating... can i really not afford? ", can_afford)
    upg_btn.disabled = not can_afford
    upg_btn.tooltip_text = "Increase pickaxe power from %d to %d" % [
        GM.mining_tool.power,
        GM.mining_tool.power + 1
    ]
