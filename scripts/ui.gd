extends CanvasLayer

@onready var label: Label = $ScoreLabel
@onready var start_label: Label = $StartLabel
@onready var controls_label: Label = $ControlsLabel

var gm: GameManager
var blink_timer: float = 0.0
var blink_speed: float = 4.5

var entry_panel: PanelContainer
var name_input: LineEdit
var pending_highscore_value: float = 0.0

func _ready() -> void:
	gm = get_parent().get_node("GameManager")
	if gm != null:
		gm.highscore_achieved.connect(_on_highscore_triggered)
		
	_setup_initial_ui_text()
	_build_procedural_entry_ui()

func _process(delta: float) -> void:
	if gm == null:
		return

	# Update UI text dynamically based on running state
	_update_score_ui_display()

	# Toggle main intro screens visibility
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
		# CLEAN RUNNING MODE: Just basic numbers layout, no names
		label.text = "Score: %d\nHighscore: %d" % [
			int(gm.current_score),
			int(gm.get_best_score())
		]
	else:
		# IDLE STATE MODE: Show full ranked top 3 layout dashboard details
		var text_output = "Score: %d\n\n== LEADERBOARD ==\n" % int(gm.current_score)
		for i in range(gm.leaderboard.size()):
			var entry = gm.leaderboard[i]
			text_output += "%d. %-8s : %d\n" % [i + 1, entry["name"], int(entry["score"])]
		label.text = text_output

func _setup_initial_ui_text() -> void:
	if controls_label != null:
		controls_label.text = "CONTROLS:\n\n[ Space ] ──── Jump\n[ Ctrl ]  ──── Slide (On Ground)\n[ Ctrl ]  ──── Dash (In Air)"
	if start_label != null:
		start_label.text = "PRESS SPACE TO START"

func _build_procedural_entry_ui() -> void:
	entry_panel = PanelContainer.new()
	entry_panel.visible = false
	entry_panel.custom_minimum_size = Vector2(320, 140)
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

	var title := Label.new()
	title.text = "NEW HIGHSCORE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	name_input = LineEdit.new()
	name_input.placeholder_text = "ENTER YOUR NAME..."
	name_input.max_length = 8
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.text_submitted.connect(_on_name_submitted)
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

func _on_name_submitted(new_text: String) -> void:
	entry_panel.visible = false
	gm.add_leaderboard_entry(new_text, pending_highscore_value)
