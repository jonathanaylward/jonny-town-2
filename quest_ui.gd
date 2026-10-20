extends CanvasLayer

const FADE_DURATION := 0.4
const PANEL_COLOR := Color(0.05, 0.05, 0.05, 0.82)
const TEXT_COLOR := Color(0.95, 0.90, 0.70, 1.0)
const SUCCESS_COLOR := Color(0.10, 0.55, 0.15, 0.92)

var _quest_done := false
var _quest_overlay: Panel
var _quest_overlay_dismissable := false
var _success_panel: Panel
var _fell_panel: Panel
var _click_overlay: Panel
var _mobile_container: Control
var _joystick: Joystick
var _look_joystick: Joystick


func _ready() -> void:
	add_to_group("quest_ui")
	_build_controls_hud()
	# _build_quest_overlay()
	# _build_success_panel()
	_build_fell_panel()
	_build_click_overlay()
	# _build_mobile_controls()
	# _show_quest_overlay()
	if DisplayServer.is_touchscreen_available():
		# Mobile: no pointer-lock needed; show controls immediately.
		_mobile_container.visible = true
	else:
		show_click_overlay()


func get_joystick_vector() -> Vector2:
	if _joystick:
		return _joystick.value
	return Vector2.ZERO


func get_look_vector() -> Vector2:
	if _look_joystick:
		return _look_joystick.value
	return Vector2.ZERO


# ---------------------------------------------------------------------------
# Controls HUD (bottom-left, always visible)
# ---------------------------------------------------------------------------

func _build_controls_hud() -> void:
	var panel := Panel.new()
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.offset_left = 20
	panel.offset_top = 20

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var controls := [
		["W A S D", "Move"],
		["Space", "Jump"],
		["Mouse", "Look"],
		["← → ↑ ↓", "Look (keys)"],
		["Esc", "Free cursor"],
	]

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)

	for row in controls:
		var hbox := HBoxContainer.new()

		var key_label := Label.new()
		key_label.text = row[0]
		key_label.custom_minimum_size = Vector2(80, 0)
		key_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))
		key_label.add_theme_font_size_override("font_size", _scaled_font_size(14))

		var desc_label := Label.new()
		desc_label.text = row[1]
		desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
		desc_label.add_theme_font_size_override("font_size", _scaled_font_size(14))

		hbox.add_child(key_label)
		hbox.add_child(desc_label)
		vbox.add_child(hbox)

	panel.add_child(vbox)
	add_child(panel)


# ---------------------------------------------------------------------------
# Click-to-play overlay (web-safe mouse capture)
# ---------------------------------------------------------------------------

func _build_click_overlay() -> void:
	_click_overlay = Panel.new()
	_click_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.72)
	_click_overlay.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "Click to Play"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", _scaled_font_size(32))
	_click_overlay.add_child(label)

	_click_overlay.visible = false
	add_child(_click_overlay)


func show_click_overlay() -> void:
	if DisplayServer.is_touchscreen_available():
		return
	_click_overlay.visible = true
	if _mobile_container:
		_mobile_container.visible = false


# ---------------------------------------------------------------------------
# Quest overlay (full-screen, click to dismiss)
# ---------------------------------------------------------------------------

func _build_quest_overlay() -> void:
	_quest_overlay = Panel.new()
	_quest_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	_quest_overlay.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "✦ New Quest ✦\nFind the bush — and jump on it!\nWhatever you do, definitely don't fall off the edge!\nFor real. Don't. I'm serious.\n\n[tap to dismiss]"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", _scaled_font_size(22))
	_quest_overlay.add_child(label)

	_quest_overlay.modulate.a = 0.0
	add_child(_quest_overlay)


func _show_quest_overlay() -> void:
	var tw := create_tween()
	tw.tween_property(_quest_overlay, "modulate:a", 1.0, FADE_DURATION)
	tw.tween_callback(func(): _quest_overlay_dismissable = true)


func _scaled_font_size(base_size: int) -> int:
	# Scale font size relative to a 1080p reference height.
	var h := float(get_viewport().get_visible_rect().size.y)
	var factor: float = clamp(h / 1080.0, 0.75, 2.0)
	return int(base_size * factor)


# ---------------------------------------------------------------------------
# Success panel (centered, click to dismiss)
# ---------------------------------------------------------------------------

func _build_success_panel() -> void:
	_success_panel = Panel.new()
	# 70% wide, 35% tall, centered
	_success_panel.anchor_left = 0.15
	_success_panel.anchor_right = 0.85
	_success_panel.anchor_top = 0.32
	_success_panel.anchor_bottom = 0.68
	_success_panel.offset_left = 0
	_success_panel.offset_right = 0
	_success_panel.offset_top = 0
	_success_panel.offset_bottom = 0

	var style := StyleBoxFlat.new()
	style.bg_color = SUCCESS_COLOR
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 1.0, 0.5, 1.0)
	_success_panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "🎉 Quest Complete! 🎉\nCongratulations. You jumped on the bush!\nFuck yeah!\n\n[click to dismiss]"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", _scaled_font_size(18))
	_success_panel.add_child(label)

	_success_panel.modulate.a = 0.0
	_success_panel.visible = false
	add_child(_success_panel)


# ---------------------------------------------------------------------------
# Fell off panel (centered, auto-respawns)
# ---------------------------------------------------------------------------

func _build_fell_panel() -> void:
	_fell_panel = Panel.new()
	# 70% wide, 25% tall, centered
	_fell_panel.anchor_left = 0.15
	_fell_panel.anchor_right = 0.85
	_fell_panel.anchor_top = 0.375
	_fell_panel.anchor_bottom = 0.625
	_fell_panel.offset_left = 0
	_fell_panel.offset_right = 0
	_fell_panel.offset_top = 0
	_fell_panel.offset_bottom = 0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.05, 0.05, 0.90)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.2, 0.2, 1.0)
	_fell_panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = "💀  Dumbass. I told you.\nRespawning..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", _scaled_font_size(20))
	_fell_panel.add_child(label)

	_fell_panel.modulate.a = 0.0
	_fell_panel.visible = false
	add_child(_fell_panel)


func show_fell_off(respawn_callback: Callable) -> void:
	_fell_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_fell_panel, "modulate:a", 1.0, FADE_DURATION)
	tw.tween_interval(2.5)
	tw.tween_property(_fell_panel, "modulate:a", 0.0, FADE_DURATION)
	tw.tween_callback(_fell_panel.hide)
	tw.tween_callback(respawn_callback)


func complete_quest() -> void:
	if _quest_done:
		return
	_quest_done = true

	# Kill the toast immediately if still showing.
	var kill_tw := create_tween()
	kill_tw.tween_property(_quest_overlay, "modulate:a", 0.0, FADE_DURATION * 0.5)

	# Reveal the success panel.
	_success_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_success_panel, "modulate:a", 1.0, FADE_DURATION)

	# Release mouse so the player can click to dismiss.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _is_tap(event: InputEvent) -> bool:
	return (event is InputEventMouseButton and event.pressed) or \
		   (event is InputEventScreenTouch and event.pressed)


func _input(event: InputEvent) -> void:
	if not _is_tap(event):
		return

	# Click-to-play overlay: capture mouse inside the input callback
	# so browsers honour the pointer-lock request.
	if _click_overlay.visible:
		_click_overlay.visible = false
		if _mobile_container:
			_mobile_container.visible = true
		if not DisplayServer.is_touchscreen_available():
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
		return

	# Initial quest toast dismissal.
	if _quest_overlay_dismissable and _quest_overlay.modulate.a >= 1.0:
		_quest_overlay_dismissable = false
		var tw := create_tween()
		tw.tween_property(_quest_overlay, "modulate:a", 0.0, FADE_DURATION)
		return

	# Success panel dismissal.
	if _quest_done and _success_panel.visible and _success_panel.modulate.a >= 1.0:
		var tw := create_tween()
		tw.tween_property(_success_panel, "modulate:a", 0.0, FADE_DURATION)
		tw.tween_callback(_success_panel.hide)
		if not DisplayServer.is_touchscreen_available():
			tw.tween_callback(show_click_overlay)
		else:
			tw.tween_callback(func(): _mobile_container.visible = true)


# ---------------------------------------------------------------------------
# Mobile touch controls (joystick + jump button)
# ---------------------------------------------------------------------------

func _build_mobile_controls() -> void:
	_mobile_container = Control.new()
	_mobile_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mobile_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mobile_container.visible = false
	add_child(_mobile_container)

	var joy_size := 200.0
	var btn_size := 110.0
	var margin := 28.0
	var gap := 14.0

	# Move joystick — bottom-left
	_joystick = Joystick.new()
	_joystick.anchor_left   = 0.0
	_joystick.anchor_right  = 0.0
	_joystick.anchor_top    = 1.0
	_joystick.anchor_bottom = 1.0
	_joystick.offset_left   = margin
	_joystick.offset_right  = margin + joy_size
	_joystick.offset_top    = -joy_size - margin
	_joystick.offset_bottom = -margin
	_mobile_container.add_child(_joystick)

	# Look joystick — bottom-right (mirrors move joystick)
	_look_joystick = Joystick.new()
	_look_joystick.anchor_left   = 1.0
	_look_joystick.anchor_right  = 1.0
	_look_joystick.anchor_top    = 1.0
	_look_joystick.anchor_bottom = 1.0
	_look_joystick.offset_left   = -margin - joy_size
	_look_joystick.offset_right  = -margin
	_look_joystick.offset_top    = -joy_size - margin
	_look_joystick.offset_bottom = -margin
	_mobile_container.add_child(_look_joystick)

	# Jump button — stacked above the look joystick, right-aligned to it
	var jump := JumpButton.new()
	jump.anchor_left   = 1.0
	jump.anchor_right  = 1.0
	jump.anchor_top    = 1.0
	jump.anchor_bottom = 1.0
	jump.offset_left   = -margin - btn_size
	jump.offset_right  = -margin
	jump.offset_top    = -joy_size - margin - gap - btn_size
	jump.offset_bottom = -joy_size - margin - gap
	_mobile_container.add_child(jump)


# ---------------------------------------------------------------------------
# Inner classes
# ---------------------------------------------------------------------------

class Joystick extends Control:
	var value := Vector2.ZERO
	var _active_touch := -2 # -2 = inactive, -1 = mouse, 0+ = finger index
	var _radius := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var center := size / 2.0
		_radius = min(size.x, size.y) / 2.0 - 6.0
		draw_circle(center, _radius, Color(0.0, 0.0, 0.0, 0.30))
		draw_arc(center, _radius, 0.0, TAU, 64, Color(1, 1, 1, 0.55), 4.0, true)
		var knob_pos: Vector2 = center + value * (_radius * 0.55)
		var knob_radius: float = _radius * 0.38
		draw_circle(knob_pos, knob_radius, Color(1, 1, 1, 0.45))
		draw_arc(knob_pos, knob_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 3.0, true)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and _active_touch == -2:
				_active_touch = event.index
				_update(event.position)
				accept_event()
			elif not event.pressed and event.index == _active_touch:
				_reset()
				accept_event()
		elif event is InputEventScreenDrag and event.index == _active_touch:
			_update(event.position)
			accept_event()
		elif event is InputEventMouseButton:
			if event.pressed and _active_touch == -2:
				_active_touch = -1
				_update(event.position)
				accept_event()
			elif not event.pressed and _active_touch == -1:
				_reset()
				accept_event()
		elif event is InputEventMouseMotion and _active_touch == -1:
			_update(event.position)
			accept_event()

	func _update(pos: Vector2) -> void:
		var center := size / 2.0
		var offset: Vector2 = pos - center
		if offset.length() > _radius:
			offset = offset.normalized() * _radius
		value = offset / _radius
		queue_redraw()

	func _reset() -> void:
		_active_touch = -2
		value = Vector2.ZERO
		queue_redraw()


class JumpButton extends Control:
	var _pressed := false
	var _label: Label

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_label = Label.new()
		_label.text = "JUMP"
		_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
		add_child(_label)
		resized.connect(_update_font_size)

	func _update_font_size() -> void:
		var px: int = max(12, int(min(size.x, size.y) * 0.18))
		_label.add_theme_font_size_override("font_size", px)

	func _draw() -> void:
		var center := size / 2.0
		var radius: float = min(size.x, size.y) / 2.0 - 6.0
		var fill: Color = Color(1.0, 1.0, 1.0, 0.45) if _pressed else Color(0.0, 0.0, 0.0, 0.30)
		draw_circle(center, radius, fill)
		draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.85), 4.0, true)

	func _gui_input(event: InputEvent) -> void:
		var press_event := false
		var release_event := false
		if event is InputEventScreenTouch or event is InputEventMouseButton:
			if event.pressed and not _pressed:
				press_event = true
			elif not event.pressed and _pressed:
				release_event = true

		if press_event:
			_pressed = true
			Input.action_press("ui_accept")
			queue_redraw()
			accept_event()
		elif release_event:
			_pressed = false
			Input.action_release("ui_accept")
			queue_redraw()
			accept_event()
