extends Control

@onready var sound_player = $AudioStreamPlayer
@onready var top_left = $QuadrantGrid/TopLeft
@onready var top_right = $QuadrantGrid/TopRight
@onready var bottom_left = $QuadrantGrid/BottomLeft
@onready var bottom_right = $QuadrantGrid/BottomRight

var base_color = Color(0.15, 0.15, 0.2, 1.0)

func _ready():
	setup_quadrants()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu.tscn")

func setup_quadrants():
	setup_quadrant(top_left, 0.8, Color(0.3, 0.5, 0.8, 1.0))
	setup_quadrant(top_right, 1.2, Color(0.5, 0.8, 0.3, 1.0))
	setup_quadrant(bottom_left, 1.5, Color(0.8, 0.3, 0.5, 1.0))
	setup_quadrant(bottom_right, 2.0, Color(0.8, 0.5, 0.3, 1.0))

func setup_quadrant(quadrant, pitch, hover_color):
	quadrant.modulate = base_color
	quadrant.mouse_entered.connect(func(): on_quadrant_hover(quadrant, pitch, hover_color))
	quadrant.mouse_exited.connect(func(): on_quadrant_exit(quadrant))

func on_quadrant_hover(quadrant, pitch, color):
	play_quadrant_sound(pitch)
	animate_quadrant_in(quadrant, color)

func on_quadrant_exit(quadrant):
	animate_quadrant_out(quadrant)

func animate_quadrant_in(quadrant, color):
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(quadrant, "modulate", color, 0.15)
	tween.tween_property(quadrant, "scale", Vector2(1.02, 1.02), 0.15).set_ease(Tween.EASE_OUT)

func animate_quadrant_out(quadrant):
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(quadrant, "modulate", base_color, 0.3)
	tween.tween_property(quadrant, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT)

func play_quadrant_sound(pitch):
	sound_player.pitch_scale = pitch
	sound_player.play()
