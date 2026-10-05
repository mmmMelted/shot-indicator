extends Node
## Shot Indicator: a PUBG-style marker at the top of the screen showing which way AI gunfire is coming from.
##
## - Every AI shot within earshot (RANGE m, SUPPRESSED_RANGE m with a suppressor) lights a red marker on a thin strip
##   at the top of the screen (a soft red glow, wide at the top and fading downward), placed by the shooter's direction relative to where you're looking: centre = straight
##   ahead, edges = 90 degrees left / right. Shots from behind pin to the nearer edge as an arrow.
## - The marker tracks the shooter's position as you turn and fades out over DURATION s. One marker per shooter.
## - Settings in user://rtv_shotindicator.cfg: range, suppressed range, duration, only shots aimed at you.


const VERSION := "1.0.0"
const TAG := "[ShotIndicator] "
const CONFIG := "user://rtv_shotindicator.cfg"
const STRIP_WIDTH := 560.0
const STRIP_TOP := 18.0
const MARKER_SIZE := Vector2(78, 34)
const HALF_SPAN := 90.0
const MAX_MARKERS := 8
const COLOR := Color(0.9, 0.12, 0.08)


var gameData = preload("res://Resources/GameData.tres")
var _lib = null
var _range := 250.0
var _suppressedRange := 60.0
var _duration := 2.0
var _onlyAtPlayer := false
var _layer: CanvasLayer
var _strip: Control
## shooter instance id -> {"pos": Vector3, "t": seconds left, "box": Glow, "arrow": Label}
var _markers := {}


## The marker: a tapered red glow, strongest along the top edge and fading out downward, with a fainter, wider halo.
class Glow extends Control:
	var color := Color.RED

	func _draw():
		var w := size.x
		var h := size.y
		_wedge(w, h, 0.0, 0.32)
		_wedge(w * 0.78, h * 0.8, (w - w * 0.78) / 2.0, 0.6)

	func _wedge(top: float, h: float, x: float, alpha: float):
		var inset := top * 0.22
		var points := PackedVector2Array([Vector2(x, 0), Vector2(x + top, 0), Vector2(x + top - inset, h), Vector2(x + inset, h)])
		var strong := Color(color, alpha)
		var clear := Color(color, 0.0)
		draw_polygon(points, PackedColorArray([strong, strong, clear, clear]))



func _ready():
	var cfg := ConfigFile.new()
	var fresh := cfg.load(CONFIG) != OK
	var defaults := {"range": 250.0, "suppressed_range": 60.0, "duration": 2.0, "only_shots_at_you": false}
	for key in defaults:
		if fresh || !cfg.has_section_key("indicator", key): cfg.set_value("indicator", key, defaults[key])
	cfg.save(CONFIG)
	_range = float(cfg.get_value("indicator", "range"))
	_suppressedRange = float(cfg.get_value("indicator", "suppressed_range"))
	_duration = max(float(cfg.get_value("indicator", "duration")), 0.2)
	_onlyAtPlayer = bool(cfg.get_value("indicator", "only_shots_at_you"))
	_build_ui()
	print(TAG + "v" + VERSION + " loaded (range " + str(_range) + " m, suppressed " + str(_suppressedRange) + " m)")
	if Engine.has_meta("RTVModLib"):
		var lib = Engine.get_meta("RTVModLib")
		if lib._is_ready: _on_lib_ready()
		else: lib.frameworks_ready.connect(_on_lib_ready)
	else:
		push_warning(TAG + "RTVModLib not found, is Metro Mod Loader installed?")

func _on_lib_ready():
	_lib = Engine.get_meta("RTVModLib")
	_lib.hook("ai-playfire-post", _on_ai_fire)

func _build_ui():
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_strip = Control.new()
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.anchor_left = 0.5
	_strip.anchor_right = 0.5
	_strip.offset_left = -STRIP_WIDTH / 2.0
	_strip.offset_right = STRIP_WIDTH / 2.0
	_strip.offset_top = STRIP_TOP
	_strip.offset_bottom = STRIP_TOP + 12.0
	_layer.add_child(_strip)



## ------------------------------------------------------------------------------------------------ shots

func _on_ai_fire():
	var ai = _lib._caller
	if ai == null || !is_instance_valid(ai) || ai.get("muzzle") == null: return
	var pos: Vector3 = ai.muzzle.global_position
	var reach: float = _suppressedRange if ai.get("suppressed") else _range
	if pos.distance_to(gameData.playerPosition) > reach: return
	if _onlyAtPlayer:
		var target = ai.sensor.get("priority")
		if !is_instance_valid(target) || !target.is_in_group("Player"): return
	var id: int = ai.get_instance_id()
	if !_markers.has(id):
		if _markers.size() >= MAX_MARKERS: _drop_oldest()
		_markers[id] = _make_marker()
	_markers[id]["pos"] = pos
	_markers[id]["t"] = _duration

func _make_marker() -> Dictionary:
	var box := Glow.new()
	box.color = COLOR
	box.size = MARKER_SIZE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.add_child(box)
	var arrow := Label.new()
	arrow.add_theme_color_override("font_color", COLOR)
	arrow.add_theme_font_size_override("font_size", 22)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.position.y = -9.0
	_strip.add_child(arrow)
	return {"pos": Vector3.ZERO, "t": 0.0, "box": box, "arrow": arrow}

func _drop_oldest():
	var oldest = null
	for id in _markers:
		if oldest == null || _markers[id]["t"] < _markers[oldest]["t"]: oldest = id
	_free_marker(oldest)

func _free_marker(id):
	_markers[id]["box"].queue_free()
	_markers[id]["arrow"].queue_free()
	_markers.erase(id)



## ------------------------------------------------------------------------------------------------ per frame

func _process(delta):
	if _markers.is_empty(): return
	var cam := get_viewport().get_camera_3d()
	var blank: bool = cam == null || gameData.transition || get_tree().current_scene == null
	for id in _markers.keys():
		var m: Dictionary = _markers[id]
		m["t"] -= delta
		if m["t"] <= 0.0 || blank:
			_free_marker(id)
			continue
		var forward := -cam.global_basis.z
		forward.y = 0.0
		var to: Vector3 = m["pos"] - cam.global_position
		to.y = 0.0
		if forward.length_squared() < 0.0001 || to.length_squared() < 0.0001: continue
		# Positive = to the right of where you're looking.
		var angle: float = -rad_to_deg(forward.normalized().signed_angle_to(to.normalized(), Vector3.UP))
		var alpha: float = clamp(m["t"] / (_duration * 0.5), 0.0, 1.0)
		var box: Control = m["box"]
		var arrow: Label = m["arrow"]
		if abs(angle) <= HALF_SPAN:
			box.visible = true
			arrow.visible = false
			box.position.x = (angle / HALF_SPAN * 0.5 + 0.5) * STRIP_WIDTH - MARKER_SIZE.x / 2.0
			box.modulate.a = alpha
		else:
			# Behind you: an arrow on the nearer edge.
			box.visible = false
			arrow.visible = true
			arrow.text = "▶" if angle > 0.0 else "◀"
			arrow.position.x = STRIP_WIDTH + 4.0 if angle > 0.0 else -22.0
			arrow.modulate.a = alpha
