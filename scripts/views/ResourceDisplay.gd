extends RichTextLabel

@onready var GM = get_node("/root/GM") # <-- Add this line

var _cached_inventory: Dictionary = {}
var _cached_currency: int = 0
var _cached_tool_level: int = 0

func _ready() -> void:
    _connect_game_signals()

func _connect_game_signals() -> void:
    GM.game_state.currency_changed.connect(_on_currency_changed)
    GM.inventory_system.inventory_changed.connect(_on_inventory_changed)
    GM.mining_tool.tool_upgraded.connect(_on_tool_upgraded)

func _refresh_display() -> void:
    var lines: Array[String] = []
    
    if _cached_inventory.is_empty():
        lines.append("No resources yet.")
    else:
        var sorted_keys: Array = _cached_inventory.keys()
        sorted_keys.sort()
        
        for resource_name in sorted_keys:
            var amount: int = _cached_inventory[resource_name]
            if amount > 0:
                var sell_price = GM.inventory_system.get_sell_price(resource_name)
                if sell_price > 0:
                    lines.append("%s: %d ($%d each)" % [resource_name, amount, sell_price])
                else:
                    lines.append("%s: %d" % [resource_name, amount])
    
    lines.append("")
    lines.append("💰 Currency: $%d" % _cached_currency)
    
    lines.append("")
    var upgrade_cost: int = GM.mining_tool.get_upgrade_cost()
    lines.append("⛏️ Pickaxe Level %d (Power %d)" % [GM.mining_tool.level, GM.mining_tool.power])
    lines.append("   Next upgrade: $%d" % upgrade_cost)
    
    lines.append("")
    lines.append("⚡ Mining Speed: %.1f tiles/sec" % GM.game_state.mining_speed)
    
    var total_value = GM.inventory_system.get_total_sell_value()
    if total_value > 0:
        lines.append("📦 Total inventory value: $%d" % total_value)
    
    text = "\n".join(lines)


func _on_currency_changed(new_currency: int) -> void:
    if _cached_currency != new_currency:
        _cached_currency = new_currency
        _refresh_display()

func _on_inventory_changed(new_inventory: Dictionary) -> void:
    if _cached_inventory.hash() != new_inventory.hash():
        _cached_inventory = new_inventory.duplicate()
        _refresh_display()

func _on_tool_upgraded(tool: MiningTool) -> void:
    if _cached_tool_level != tool.level:
        _cached_tool_level = tool.level
        _refresh_display()
