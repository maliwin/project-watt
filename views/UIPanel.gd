extends Control

@onready var GM: GameManager = get_node("/root/GameManager")
@onready var resource_display: Label = $MarginContainer/MainContainer/ResourceDisplay
@onready var upgrade_list: VBoxContainer = $MarginContainer/MainContainer/UpgradeArea/UpgradeList

# Cache for performance
var _cached_inventory: Dictionary = {}
var _cached_currency: int = 0
var _cached_tool_level: int = 0

func _ready() -> void:
    if GM == null:
        push_error("UIPanel: Cannot find GameManager autoload")
        return
    
    # Connect to proper typed signals - no more magic strings!
    _connect_game_signals()
    
    _build_buttons()
    _refresh_all()

func _connect_game_signals() -> void:
    # Connect to GameState signals
    GM.game_state.currency_changed.connect(_on_currency_changed)
    
    # Connect to InventorySystem signals
    GM.inventory_system.inventory_changed.connect(_on_inventory_changed)
    
    # Connect to UpgradeSystem signals
    GM.upgrade_system.upgrade_purchased.connect(_on_upgrade_purchased)
    GM.upgrade_system.upgrade_failed.connect(_on_upgrade_failed)
    GM.upgrade_system.all_resources_sold.connect(_on_resources_sold)
    
    # Connect to MiningTool signals
    GM.mining_tool.tool_upgraded.connect(_on_tool_upgraded)

func _build_buttons() -> void:
    # Clear previous buttons
    for child in upgrade_list.get_children():
        child.queue_free()

    # Sell All Button
    var sell_btn := Button.new()
    sell_btn.text = "Sell All"
    sell_btn.tooltip_text = "Sell all resources for currency"
    sell_btn.pressed.connect(_on_sell_all_pressed)
    upgrade_list.add_child(sell_btn)

    # Upgrade Pickaxe Button
    var upg_btn := Button.new()
    upg_btn.name = "UpgradePickaxe"
    upg_btn.pressed.connect(_on_upgrade_pickaxe_pressed)
    upgrade_list.add_child(upg_btn)
    
    _update_button_states()

func _on_sell_all_pressed() -> void:
    GM.sell_all()

func _on_upgrade_pickaxe_pressed() -> void:
    GM.upgrade_pickaxe()

# ---------- Typed Signal Handlers - No magic strings! ----------
func _on_currency_changed(new_currency: int) -> void:
    if _cached_currency != new_currency:
        _cached_currency = new_currency
        _refresh_display()
        _update_button_states()

func _on_inventory_changed(new_inventory: Dictionary) -> void:
    if _cached_inventory.hash() != new_inventory.hash():
        _cached_inventory = new_inventory.duplicate()
        _refresh_display()

func _on_tool_upgraded(tool: MiningTool) -> void:
    if _cached_tool_level != tool.level:
        _cached_tool_level = tool.level
        _refresh_display()
        _update_button_states()

func _on_upgrade_purchased(upgrade_type: String, new_level: int) -> void:
    _show_feedback("Upgrade successful! %s level %d" % [upgrade_type.capitalize(), new_level], Color.GREEN)

func _on_upgrade_failed(upgrade_type: String, reason: String) -> void:
    _show_feedback("Upgrade failed: %s" % reason, Color.RED)

func _on_resources_sold(total_value: int) -> void:
    if total_value > 0:
        _show_feedback("Sold all resources for $%d!" % total_value, Color.YELLOW)

func _show_feedback(message: String, color: Color) -> void:
    # Simple feedback - could be enhanced with proper UI animations
    print("UI Feedback [%s]: %s" % [color, message])

# ---------- Display Updates ----------
func _refresh_all() -> void:
    if GM == null:
        return
    
    _cached_inventory = GM.inventory_system.inventory
    _cached_currency = GM.game_state.currency
    _cached_tool_level = GM.mining_tool.level
    
    _refresh_display()
    _update_button_states()

func _refresh_display() -> void:
    var lines: Array[String] = []
    
    # Resources section with sell prices
    if _cached_inventory.is_empty():
        lines.append("No resources yet.")
    else:
        var sorted_keys: Array = _cached_inventory.keys()
        sorted_keys.sort()
        
        for resource_name in sorted_keys:
            var amount: int = _cached_inventory[resource_name]
            if amount > 0:
                var sell_price := GM.inventory_system.get_sell_price(resource_name)
                if sell_price > 0:
                    lines.append("%s: %d ($%d each)" % [resource_name, amount, sell_price])
                else:
                    lines.append("%s: %d" % [resource_name, amount])
    
    # Currency section
    lines.append("")
    lines.append("💰 Currency: $%d" % _cached_currency)
    
    # Tool section  
    lines.append("")
    var upgrade_cost: int = GM.mining_tool.get_upgrade_cost()
    lines.append("⛏️ Pickaxe Level %d (Power %d)" % [GM.mining_tool.level, GM.mining_tool.power])
    lines.append("   Next upgrade: $%d" % upgrade_cost)
    
    # Mining stats
    lines.append("")
    lines.append("⚡ Mining Speed: %.1f tiles/sec" % GM.game_state.mining_speed)
    
    # Total inventory value
    var total_value := GM.inventory_system.get_total_sell_value()
    if total_value > 0:
        lines.append("📦 Total inventory value: $%d" % total_value)
    
    resource_display.text = "\n".join(lines)

func _update_button_states() -> void:
    var upg_btn: Button = upgrade_list.get_node_or_null("UpgradePickaxe")
    if upg_btn == null:
        return
        
    var cost: int = GM.mining_tool.get_upgrade_cost()
    var can_afford: bool = GM.game_state.currency >= cost
    
    upg_btn.text = "Upgrade Pickaxe ($%d)" % cost
    upg_btn.disabled = not can_afford
    upg_btn.tooltip_text = "Increase pickaxe power from %d to %d" % [
        GM.mining_tool.power,
        GM.mining_tool.power + 1
    ]
