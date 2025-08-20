extends Control

@onready var sound_player = $AudioStreamPlayer
@onready var top_left = $QuadrantGrid/TopLeft
@onready var top_right = $QuadrantGrid/TopRight
@onready var bottom_left = $QuadrantGrid/BottomLeft
@onready var bottom_right = $QuadrantGrid/BottomRight

func _ready():
	setup_quadrants()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu.tscn")

func setup_quadrants():
	top_left.mouse_entered.connect(func(): play_quadrant_sound(0.8))
	top_right.mouse_entered.connect(func(): play_quadrant_sound(1.2))
	bottom_left.mouse_entered.connect(func(): play_quadrant_sound(1.5))
	bottom_right.mouse_entered.connect(func(): play_quadrant_sound(2.0))

func play_quadrant_sound(pitch):
	sound_player.pitch_scale = pitch
	sound_player.play()
