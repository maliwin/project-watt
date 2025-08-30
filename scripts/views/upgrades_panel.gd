extends VBoxContainer

func _ready() -> void:
    _build_buttons()
    _connect_button_signals()
    _update_button_states()

func _connect_button_signals() -> void:
    Event.tool_upgraded.connect(_update_button_states)

func _build_buttons() -> void:
    for child in self.get_children():
        child.queue_free()

    var upg_btn := Button.new()
    upg_btn.name = "UpgradePickaxe"
    upg_btn.pressed.connect(_on_upgrade_pickaxe_pressed)
    self.add_child(upg_btn)

func _on_upgrade_pickaxe_pressed() -> void:
    GM.upgrade_pickaxe()

func _update_button_states(_IGNORED_ARG = null) -> void:  # TODO: refactor arg
    var upg_btn: Button = self.get_node_or_null("UpgradePickaxe")
    if upg_btn == null:
        return
    
    upg_btn.text = "Upgrade Pickaxe ($0)"
    upg_btn.disabled = true
    upg_btn.tooltip_text = "Increase pickaxe power from %d to %d" % [
        GM.mining_tool.power,
        GM.mining_tool.power + 1
    ]
