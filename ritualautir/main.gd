extends Control

var score = 0

@onready var score_label = $Label
@onready var click_sound = $AudioStreamPlayer
@onready var click_button = $Button

func _ready():
	click_button.pressed.connect(on_button_pressed)

func on_button_pressed():
	score = score + 1
	score_label.text = "Score: " + str(score)
	click_sound.play()
