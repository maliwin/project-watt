extends Node

signal game_tick(delta: float)

var _next_event_id: int = 1

# { event_id: { "fire_at_time": float, "target_path": NodePath, "method": StringName } }
var _scheduled_events: Dictionary = {}
var _current_time: float = 0.0  # time elapsed since game started, in seconds

const GAME_HZ: float = 30.0  # NOTE: can make this non-const in the future
const GAME_TICK_RATE: float = 1.0 / GAME_HZ
var _time_accumulator: float = 0.0


# Time.schedule(5.0, self, &"_on_timer_complete")
func schedule(duration_seconds: float, target: Node, method: StringName) -> int:
    var event_id = _next_event_id
    _next_event_id += 1
    
    if not target or not target.is_inside_tree():
        printerr("TimeManager: Target node for scheduled event is not valid or not in the tree.")
        return -1
    
    _scheduled_events[event_id] = {
        "fire_at_time": _current_time + duration_seconds,
        "target_path": target.get_path(),
        "method": method
    }
    
    return event_id

func cancel_event(event_id: int) -> bool:
    if _scheduled_events.has(event_id):
        _scheduled_events.erase(event_id)
        return true
    return false

# TODO: do we need this?
func get_current_time() -> float:
    return _current_time

func get_save_data() -> Dictionary:
    return {}  # TODO

func load_save_date(data: Dictionary):
    pass  # TODO


func _process(delta: float):
    _time_accumulator += delta
    
    while _time_accumulator >= GAME_TICK_RATE:
        _current_time += GAME_TICK_RATE
        _tick(GAME_TICK_RATE)
        _time_accumulator -= GAME_TICK_RATE
    
func _tick(fixed_delta: float):
    game_tick.emit(fixed_delta)
    
    var events_to_fire = []
    for event_id in _scheduled_events:
        var event = _scheduled_events[event_id]
        if _current_time >= event.fire_at_time:
            events_to_fire.append(event_id)
    
    for event_id in events_to_fire:
        var event = _scheduled_events.get(event_id, null)
        
        if not event:
            continue
            
        var target_node = get_node_or_null(event.target_path)
        if is_instance_valid(target_node) and target_node.has_method(event.method):
            target_node.call(event.method)
        _scheduled_events.erase(event_id)
