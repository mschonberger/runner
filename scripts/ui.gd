# res://scripts/ui.gd
extends CanvasLayer

@onready var label: Label = $ScoreLabel
@onready var start_label: Label = $StartLabel
@onready var controls_label: Label = $ControlsLabel

var gm: GameManager
var blink_timer: float = 0.0
var blink_speed: float = 4.5

var entry_panel: PanelContainer
var name_input: LineEdit
var title_label: Label # Reference pointer to dynamically change title text
var pending_highscore_value: float = 0.0

var global_highest_score: int = 0
var global_leaderboard_text: String = "Loading global leaderboard..."

func _ready() -> void:
	gm = get_parent().get_node("GameManager") as GameManager
	if gm != null:
		gm.highscore_achieved.connect(_on_highscore_triggered)

	_setup_initial_ui_text()
	_build_procedural_entry_ui()
	await get_tree().create_timer(1).timeout
	await fetch_global_scores()
	await get_tree().create_timer(1).timeout
	await fetch_global_scores()

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
		for i in range(gm.leaderboard.size()):
			var entry = gm.leaderboard[i]
			text_output += "%d. %-8s : %d\n" % [i + 1, entry["name"], int(entry["score"])]
		
		text_output += "\n" + global_leaderboard_text
		label.text = text_output

func _setup_initial_ui_text() -> void:
	if controls_label != null:
		controls_label.text = "CONTROLS:\n\n[ Space ] ──── Jump\n[ Ctrl ]  ──── Slide (On Ground)\n[ Ctrl ]  ──── Dash (In Air)\n[ Tap Left Side ]  ──── Dash\n[ Tap Right Side ]  ──── Jump"
	if start_label != null:
		start_label.text = "PRESS SPACE TO START"

func _build_procedural_entry_ui() -> void:
	entry_panel = PanelContainer.new()
	entry_panel.visible = false
	entry_panel.custom_minimum_size = Vector2(340, 120)
	entry_panel.set_anchors_preset(Control.PRESET_CENTER)
	entry_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	entry_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(entry_panel)

	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_top", 12)
	margin_container.add_theme_constant_override("margin_bottom", 12)
	margin_container.add_theme_constant_override("margin_left", 16)
	margin_container.add_theme_constant_override("margin_right", 16)
	entry_panel.add_child(margin_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin_container.add_child(vbox)

	title_label = Label.new()
	title_label.text = "NEW HIGHSCORE!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	name_input = LineEdit.new()
	name_input.placeholder_text = "ENTER YOUR NAME..."
	name_input.max_length = 8
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.text_submitted.connect(_on_name_submitted)
	name_input.gui_input.connect(_on_name_input_clicked)
	vbox.add_child(name_input)
	
	var hint := Label.new()
	hint.text = "Press Enter to Save"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate.a = 0.6
	vbox.add_child(hint)

func _on_highscore_triggered(score_value: float) -> void:
	pending_highscore_value = score_value
	entry_panel.visible = true
	name_input.text = ""
	name_input.grab_focus()
	
	# === DYNAMIC HEADER ALIGNMENT CHECK ===
	var beat_local: bool = gm.qualifies_for_local(score_value)
	var beat_online: bool = score_value > global_highest_score and global_highest_score > 0
	
	if beat_local and beat_online:
		title_label.text = "🏆 ALL-TIME RECORD SHATTERED! 🏆"
	elif beat_online:
		title_label.text = "🌐 NEW WORLD RECORD! 🌐"
	elif beat_local:
		title_label.text = "🏅 NEW LOCAL HIGHSCORE! 🏅"
	else:
		title_label.text = "RUN COMPLETED!"

func _on_name_submitted(new_text: String) -> void:
	entry_panel.visible = false
	await gm.add_leaderboard_entry(new_text, pending_highscore_value)
	await get_tree().create_timer(1).timeout
	await fetch_global_scores()
	await get_tree().create_timer(1).timeout
	await fetch_global_scores()

func _on_name_input_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		name_input.release_focus()
		name_input.grab_focus()
		name_input.caret_column = name_input.text.length()
		DisplayServer.virtual_keyboard_show(name_input.text, name_input.get_global_rect(), name_input.max_length)

# === ASYNC CLOUD DATABASE OPERATIONS ===

func fetch_global_scores() -> void:
	await SilentWolf.Scores.get_scores(3)
	var remote_scores: Array = SilentWolf.Scores.scores
	
	if not remote_scores.is_empty():
		var top_record_entry = remote_scores[0]
		global_highest_score = int(top_record_entry.get("score", 0))
		
		var leaderboard_lines: Array[String] = ["== GLOBAL TOP 3 =="]
		var rank = 1
		for entry in remote_scores:
			var p_name: String = entry.get("player_name", "ANON")
			var p_score: int = int(entry.get("score", 0))
			
			leaderboard_lines.append("%d. %-8s : %d" % [rank, p_name, p_score])
			rank += 1
		global_leaderboard_text = "\n".join(leaderboard_lines)
	else:
		global_highest_score = 0
		global_leaderboard_text = "== GLOBAL TOP 3 =="
	_update_score_ui_display()
