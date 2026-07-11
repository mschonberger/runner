extends Node2D

const SCENE_CENTER: Vector2 = Vector2(192.0 / 2.0, 108.0 / 2.0)

@onready var animation_player := $AnimationPlayer
@onready var hit1_sound: AudioStreamPlayer = $Hit1Sound
@onready var hit2_sound: AudioStreamPlayer = $Hit2Sound
@onready var knife_sound: AudioStreamPlayer = $KnifeSound
@onready var gun_sound: AudioStreamPlayer = $GunSound

var rotation_speed: float = 180.0

func _ready() -> void:
	animation_player.play("intro")
	await get_tree().create_timer(0.1).timeout
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	print("Logo intro animation started and 'animation_finished' signal connected.")

func _on_animation_player_animation_finished(anim_name: String) -> void:
	print("Animation '", anim_name, "' finished. Attempting transition to Start Screen.")
	get_tree().change_scene_to_file("res://ui/start_screen.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if gun_sound: gun_sound.play()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	elif event.is_action_pressed("dash"):
		if hit2_sound: hit2_sound.play()
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func play_sfx1() -> void:
	if hit1_sound: hit1_sound.play()

func play_sfx2() -> void:
	if knife_sound: knife_sound.play()

func play_sfx3() -> void:
	if gun_sound: gun_sound.play()
