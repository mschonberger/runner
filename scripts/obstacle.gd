extends Area2D

@export var penalty_extra: float = 80.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		var col = get_node_or_null("CollisionShape2D")
		if col:
			col.set_deferred("disabled", true)


		var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
		if gm != null:
			gm.apply_speed_penalty(penalty_extra)

		if body.has_method("apply_hit"):
			body.call("apply_hit")

		queue_free()
