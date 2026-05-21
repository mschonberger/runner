extends CanvasLayer
class_name ScreenFader

@onready var flash: ColorRect = $Flash
@onready var gm: GameManager = get_tree().get_first_node_in_group("game_manager") as GameManager

@export var fade_out_time: float = 0.18
@export var hold_time: float = 0.05
@export var fade_in_time: float = 0.22

var _busy: bool = false

func _ready() -> void:
	add_to_group("screen_fader")
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

func is_busy() -> bool:
	return _busy

func fade_reset_and_fade_in(reset_callable: Callable) -> void:
	if _busy:
		return
	_busy = true

	if gm != null:
		gm.can_start = false

	# Fade to white
	var t_out := create_tween()
	t_out.tween_property(flash, "color:a", 1.0, fade_out_time)
	await t_out.finished

	# Small hold at white
	if hold_time > 0.0:
		await get_tree().create_timer(hold_time).timeout

	# Perform reset
	if reset_callable.is_valid():
		reset_callable.call()

	# Fade back to transparent
	var t_in := create_tween()
	t_in.tween_property(flash, "color:a", 0.0, fade_in_time)
	await t_in.finished

	if gm != null:
		gm.can_start = true

	_busy = false
