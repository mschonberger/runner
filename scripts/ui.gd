# res://scripts/ui.gd
extends CanvasLayer

@onready var label: Label = $ScoreLabel
@onready var start_label: Label = $StartLabel
@onready var controls_label: Label = $ControlsLabel

var gm: GameManager
var blink_timer: float = 0.0
var blink_speed: float = 4.5

# Custom Virtual Keyboard Containers
var entry_panel: PanelContainer
var display_name_label: Label
var title_label: Label 
var mobile_controls_node: CanvasLayer = null

var global_highest_score: int = 0
var global_leaderboard_text: String = "Loading global leaderboard..."
var entered_string: String = ""

func _ready() -> void:
	gm = get_tree().get_first_node_in_group("game_manager") as GameManager
	mobile_controls_node = get_parent().get_node_or_null("MobileControls")

	if gm:
		gm.global_score_upload_completed.connect(_on_global_score_upload_completed)

	_build_procedural_virtual_keyboard_ui()
	_setup_initial_ui_text()

	if gm.player_name == "Guest" or gm.player_name.strip_edges().is_empty():
		_open_name_onboarding()
	else:
		_complete_onboarding(gm.player_name)

func _process(delta: float) -> void:
	if gm == null:
		return

	_update_score_ui_display()

	if gm.running or entry_panel.visible:
		if start_label != null: start_label.visible = false
		if controls_label != null: controls_label.visible = false
	else:
		if start_label != null: start_label.visible = true
		if controls_label != null: controls_label.visible = true
		
		blink_timer += delta
		if start_label != null:
			start_label.modulate.a = (sin(blink_timer * blink_speed) + 1.0) / 2.0

func _update_score_ui_display() -> void:
	if gm.running:
		label.text = "Score: %d\nLocal Best: %d\nOnline Record: %d" % [
			int(gm.current_score),
			int(gm.get_best_score()),
			global_highest_score
		]
	else:
		var text_output = "Score: %d\n\n== LOCAL TOP 3 ==\n" % int(gm.current_score)
		
		var unique_local_entries: Array = []
		var seen_local_names: Dictionary = {}
		
		for entry in gm.leaderboard:
			var name_key: String = entry["name"].to_upper().strip_edges()
			if not seen_local_names.has(name_key):
				seen_local_names[name_key] = true
				unique_local_entries.append(entry)

		var display_limit = min(unique_local_entries.size(), 3)
		for i in range(display_limit):
			var entry = unique_local_entries[i]
			text_output += "%d. %-8s : %d\n" % [i + 1, entry["name"], int(entry["score"])]
		
		text_output += "\n" + global_leaderboard_text
		label.text = text_output

func _setup_initial_ui_text() -> void:
	if controls_label != null:
		controls_label.text = "CONTROLS:\n\n[ Space ] ──── Jump\n[ Ctrl ]  ──── Slide (On Ground)\n[ Ctrl ]  ──── Dash (In Air)\n[ Tap Left Side ]  ──── Dash\n[ Tap Right Side ]  ──── Jump"
	if start_label != null:
		start_label.text = "PRESS SPACE TO START"

# === IN-GAME VIRTUAL KEYBOARD GRAPHICS ENGINE ===

func _build_procedural_virtual_keyboard_ui() -> void:
	entry_panel = PanelContainer.new()
	entry_panel.visible = false
	entry_panel.custom_minimum_size = Vector2(450, 280)
	entry_panel.set_anchors_preset(Control.PRESET_CENTER)
	entry_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	entry_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(entry_panel)

	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_top", 16)
	margin_container.add_theme_constant_override("margin_bottom", 16)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	entry_panel.add_child(margin_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin_container.add_child(vbox)

	title_label = Label.new()
	title_label.text = "WELCOME! SET YOUR RUNNER NAME:"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Name Text Display Panel Room
	display_name_label = Label.new()
	display_name_label.text = "________"
	display_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display_name_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(display_name_label)

	# Build Keyboard Character Selection Matrix (Grid)
	var grid = GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(grid)

	# Generate character strings procedurally
	var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for i in range(alphabet.length()):
		var char_letter = alphabet[i]
		var btn = Button.new()
		btn.text = char_letter
		btn.custom_minimum_size = Vector2(44, 44)
		btn.pressed.connect(_on_keyboard_char_pressed.bind(char_letter))
		grid.add_child(btn)

	# Backspace Button
	var btn_back = Button.new()
	btn_back.text = "DEL"
	btn_back.custom_minimum_size = Vector2(44, 44)
	btn_back.pressed.connect(_on_keyboard_backspace_pressed)
	grid.add_child(btn_back)

	# Submit Confirmation Button
	var btn_enter = Button.new()
	btn_enter.text = "OK"
	btn_enter.custom_minimum_size = Vector2(94, 44)
	btn_enter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_enter.pressed.connect(_on_keyboard_submit_pressed)
	
	# Add spacing component step to balance asymmetric grid line length layout
	grid.add_child(btn_enter)

func _open_name_onboarding() -> void:
	gm.can_start = false
	entry_panel.visible = true
	entered_string = ""
	_update_keyboard_text_ui()
	_toggle_touch_zones(false)

func _on_keyboard_char_pressed(letter: String) -> void:
	if entered_string.length() < 8:
		entered_string += letter
		_update_keyboard_text_ui()

func _on_keyboard_backspace_pressed() -> void:
	if entered_string.length() > 0:
		entered_string = entered_string.substr(0, entered_string.length() - 1)
		_update_keyboard_text_ui()

func _update_keyboard_text_ui() -> void:
	if entered_string.is_empty():
		display_name_label.text = "________"
	else:
		display_name_label.text = entered_string + "_".repeat(8 - entered_string.length())

func _on_keyboard_submit_pressed() -> void:
	var final_name = entered_string.strip_edges()
	if final_name.is_empty():
		final_name = "RUNNER"
	
	gm.save_player_name(final_name)
	_complete_onboarding(final_name)

func _complete_onboarding(_confirmed_name: String) -> void:
	entry_panel.visible = false
	_toggle_touch_zones(true)
	gm.can_start = true
	
	await fetch_global_scores()
	await get_tree().create_timer(1.0).timeout
	await fetch_global_scores()

func _toggle_touch_zones(enable_touch: bool) -> void:
	if mobile_controls_node != null:
		mobile_controls_node.visible = enable_touch
		if enable_touch:
			mobile_controls_node.process_mode = PROCESS_MODE_INHERIT
		else:
			mobile_controls_node.process_mode = PROCESS_MODE_DISABLED

# === CLOUD NETWORK LEADERBOARD CACHE PROCESSING ===

func fetch_global_scores() -> void:
	await SilentWolf.Scores.get_scores(10).sw_get_scores_complete
	var remote_scores: Array = SilentWolf.Scores.scores
	
	if not remote_scores.is_empty():
		# Save the absolute highest score for the "Online Record" tracker
		global_highest_score = int(remote_scores[0].get("score", 0))
		
		var leaderboard_lines: Array[String] = ["== GLOBAL TOP 3 =="]
		var seen_global_names: Dictionary = {}
		var rank = 1
		
		# --- Filter Global Duplicates ---
		for entry in remote_scores:
			if rank > 3:
				break
				
			var p_name: String = entry.get("player_name", "ANON").to_upper().strip_edges()
			var p_score: int = int(entry.get("score", 0))
			
			if seen_global_names.has(p_name):
				continue
				
			seen_global_names[p_name] = true
			leaderboard_lines.append("%d. %-8s : %d" % [rank, p_name, p_score])
			rank += 1
			
		global_leaderboard_text = "\n".join(leaderboard_lines)
	else:
		global_highest_score = 0
		global_leaderboard_text = "== GLOBAL TOP 3 =="
		
	_update_score_ui_display()

func _on_global_score_upload_completed() -> void:
	print("UI: Refreshing leaderboard after successful upload...")
	fetch_global_scores()
