extends StaticBody2D
class_name PlatformChunk

@export var chunk_width: float = 1056.0
@export var main_color: Color = Color.WHITE

const SKYSCRAPER_HEIGHT: float = 950.0
const SHADER_PATH = "res://shader/color_replace.gdshader"

func _ready() -> void:
	if int(chunk_width) in [528, 1056, 1584, 2112]:
		_apply_skyscraper_sprite()

func _physics_process(delta: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if gm and gm.running:
		position.x -= gm.current_speed * delta

func _apply_skyscraper_sprite() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	var variant := randi_range(1, 6)
	var width_key := int(chunk_width)
	var path := "res://art/houses/%d House %d.png" % [width_key, variant]

	if ResourceLoader.exists(path):
		sprite.texture = load(path)
		sprite.position = Vector2(0.0, SKYSCRAPER_HEIGHT / 2.0)
		sprite.scale = Vector2.ONE
		sprite.visible = true

		_setup_shader_material(sprite)
	else:
		push_error("Base PlatformChunk: Cannot find asset path: " + path)

func _setup_shader_material(sprite: Sprite2D) -> void:
	var shader_res = load(SHADER_PATH) as Shader
	if shader_res:
		var mat := ShaderMaterial.new()
		mat.shader = shader_res
		mat.set_shader_parameter("replace_color", main_color)
		sprite.material = mat
