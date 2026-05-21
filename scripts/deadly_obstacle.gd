extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body != null and body.is_in_group("player"):
		# Check if the player has a death/reset method and invoke it immediately
		if body.has_method("_die_and_reset"):
			body.call("_die_and_reset")
