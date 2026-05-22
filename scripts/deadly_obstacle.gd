extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		if body.has_method("_die_and_reset"):
			# 🚨 FIX: Defer the death sequence until the physics step finishes
			body.call_deferred("_die_and_reset")
