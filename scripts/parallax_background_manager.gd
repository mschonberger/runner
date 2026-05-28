extends Node2D
class_name ParallaxBackgroundManager

@export var score_milestone: float = 2500.0
@export var fade_duration: float = 2.0
@export var background_tint: Color = Color(0.65, 0.65, 0.65, 1.0)
@export var background_speed_modifier: float = 0.2
@export var all_packs_textures: Array[Array] = [
	[ # PACK 1 (0 to 2500 Points)
		"res://art/background/City A/A1.png",
		"res://art/background/City A/A2.png",
		"res://art/background/City A/A3.png",
		"res://art/background/City A/A4.png",
		"res://art/background/City A/A5.png"
	],
	[ # PACK 2 (2500 to 5000 Points)
		"res://art/background/City B/B1.png",
		"res://art/background/City B/B2.png",
		"res://art/background/City B/B3.png",
		"res://art/background/City B/B4.png",
		"res://art/background/City B/B5.png"
	],
	[ # PACK 3 (5000 to 7500 Points)
		"res://art/background/City C/C1.png",
		"res://art/background/City C/C2.png",
		"res://art/background/City C/C3.png",
		"res://art/background/City C/C4.png",
		"res://art/background/City C/C5.png"
	],
	[ # PACK 4 (7500 to 10000 Points)
		"res://art/background/City D/D1.png",
		"res://art/background/City D/D2.png",
		"res://art/background/City D/D3.png",
		"res://art/background/City D/D4.png",
		"res://art/background/City D/D5.png"
	],
	[ # PACK 5 (10000 to 12500 Points)
		"res://art/background/City E/E1.png",
		"res://art/background/City E/E2.png",
		"res://art/background/City E/E3.png",
		"res://art/background/City E/E4.png",
		"res://art/background/City E/E5.png"
	],
	[ # PACK 6 (12500 to 15000 Points)
		"res://art/background/City F/F1.png",
		"res://art/background/City F/F2.png",
		"res://art/background/City F/F3.png",
		"res://art/background/City F/F4.png",
		"res://art/background/City F/F5.png"
	],
	[ # PACK 7 (15000 to 17500 Points)
		"res://art/background/City G/G1.png",
		"res://art/background/City G/G2.png",
		"res://art/background/City G/G3.png",
		"res://art/background/City G/G4.png",
		"res://art/background/City G/G5.png"
	],
	[ # PACK 8 (17500 to 20000 Points)
		"res://art/background/City H/H1.png",
		"res://art/background/City H/H2.png",
		"res://art/background/City H/H3.png",
		"res://art/background/City H/H4.png",
		"res://art/background/City H/H5.png"
	]
]

@onready var pack_a: Node2D = $PackA
@onready var pack_b: Node2D = $PackB

var gm: GameManager = null
var next_fade_score: float = 2500.0
var is_fading: bool = false

var current_pack_index: int = 0
var active_is_pack_a: bool = true

func _ready() -> void:
	add_to_group("parallax_manager")
	gm = get_tree().get_first_node_in_group("game_manager") as GameManager
	_reset_visibility()

func _physics_process(_delta: float) -> void:
	if gm == null or not gm.running:
		_set_layer_autoscroll(0.0)
		return
		
	_set_layer_autoscroll(gm.current_speed * background_speed_modifier)
		
	if gm.current_score >= next_fade_score and not is_fading:
		trigger_next_pack_fade()
		next_fade_score += score_milestone

func _set_layer_autoscroll(adjusted_speed: float) -> void:
	for layer in pack_a.get_children():
		if layer is Parallax2D:
			layer.autoscroll.x = -adjusted_speed * layer.scroll_scale.x

	for layer in pack_b.get_children():
		if layer is Parallax2D:
			layer.autoscroll.x = -adjusted_speed * layer.scroll_scale.x

func _reset_visibility() -> void:
	is_fading = false
	next_fade_score = score_milestone
	active_is_pack_a = true
	
	if not all_packs_textures.is_empty():
		current_pack_index = randi() % all_packs_textures.size()
	else:
		current_pack_index = 0
	
	_load_pack_textures_into_node(pack_a, current_pack_index)
	
	pack_a.modulate = background_tint
	pack_b.modulate = background_tint
	
	pack_a.modulate.a = 1.0
	pack_b.modulate.a = 0.0

func trigger_next_pack_fade() -> void:
	if all_packs_textures.is_empty():
		return
		
	is_fading = true
	var next_pack_index = (current_pack_index + 1) % all_packs_textures.size()
	
	if active_is_pack_a:
		_load_pack_textures_into_node(pack_b, next_pack_index)
	else:
		_load_pack_textures_into_node(pack_a, next_pack_index)
		
	var tween = create_tween().set_parallel(true)
	
	if active_is_pack_a:
		tween.tween_property(pack_a, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tween.tween_property(pack_b, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property(pack_b, "modulate:a", 0.0, fade_duration).set_trans(Tween.TRANS_SINE)
		tween.tween_property(pack_a, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE)
		
	current_pack_index = next_pack_index
	tween.finished.connect(_on_fade_completed)

func _on_fade_completed() -> void:
	active_is_pack_a = not active_is_pack_a
	is_fading = false

func _load_pack_textures_into_node(target_node: Node2D, pack_idx: int) -> void:
	if pack_idx >= all_packs_textures.size():
		return
		
	var pack_paths = all_packs_textures[pack_idx]
	var layers = target_node.get_children()
	
	for i in range(min(layers.size(), pack_paths.size())):
		var sprite = layers[i].get_node_or_null("Sprite2D") as Sprite2D
		if sprite and pack_paths[i] != "":
			sprite.texture = load(pack_paths[i])

func reset_parallax_on_death() -> void:
	_reset_visibility()
