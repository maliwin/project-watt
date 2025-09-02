extends PanelContainer
class_name PickaxePanel

@onready var name_label: Label = %NameLabel
@onready var power_label: Label = %PowerLabel
@onready var crit_label: Label = %CritLabel

func _ready() -> void:
    # Connect to the tool upgraded signal to automatically refresh
    Event.tool_upgraded.connect(update_stats)
    # Initial update
    # update_stats(GM.mining_tool)

func update_stats(tool: MiningTool) -> void:
    if not is_instance_valid(tool):
        return
        
    name_label.text = "Tool: %s (Lv. %d)" % [tool.tool_name, tool.level]
    power_label.text = "Power: %d" % tool.power
    crit_label.text = "Crit Chance: %d%%" % (tool.crit_chance * 100)
