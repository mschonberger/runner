extends CanvasLayer

@onready var label: Label = $ScoreLabel
var gm: GameManager

func _ready():
	gm = get_parent().get_node("GameManager")

func _process(_delta):
	if gm == null:
		return

	label.text = "Score: %d\nHighscore: %d" % [
		int(gm.current_score),
		int(gm.highscore)
	]
