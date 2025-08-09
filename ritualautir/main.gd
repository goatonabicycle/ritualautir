extends Control

var energy = 0.0
var multiplier = 1.0
var timer = 0.0

@onready var energy_label = $GameArea/TopBar/StatsContainer/EnergyPanel/EnergyValue
@onready var multiplier_label = $GameArea/TopBar/StatsContainer/MultiplierPanel/MultiplierValue
@onready var click_sound = $AudioStreamPlayer
@onready var summon_button = $GameArea/CenterContainer/RitualCircle/SummonButton
@onready var moving_block = $GameArea/CenterContainer/RitualCircle/RhythmBar/MovingBlock
@onready var left_zone = $GameArea/CenterContainer/RitualCircle/RhythmBar/LeftZone
@onready var right_zone = $GameArea/CenterContainer/RitualCircle/RhythmBar/RightZone
@onready var click_shadow = $GameArea/CenterContainer/RitualCircle/RhythmBar/ClickShadow
@onready var rhythm_bar = $GameArea/CenterContainer/RitualCircle/RhythmBar

func _ready():
	summon_button.pressed.connect(on_click)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu.tscn")

func _process(delta):
	timer += delta
	move_block()
	pulse_rhythm_bar(delta)
	add_passive_energy(delta)
	decay_multiplier(delta)
	update_ui()

func move_block():
	var position_in_cycle = fmod(timer / 2.0, 1.0)
	var x = sin(position_in_cycle * TAU) * 145 + 145
	moving_block.position.x = x

func pulse_rhythm_bar(delta):
	if rhythm_bar:
		var base_scale = 1.0
		var pulse_amount = 0.02 * min(multiplier / 3.0, 1.0)
		var pulse = sin(timer * 3.0) * pulse_amount + base_scale
		rhythm_bar.scale.y = pulse

func add_passive_energy(delta):
	energy += 0.2 * multiplier * delta

func decay_multiplier(delta):
	multiplier = max(1.0, multiplier - 0.15 * delta)

func update_ui():
	energy_label.text = str(int(energy))
	multiplier_label.text = "x%.1f" % multiplier

func on_click():
	var block_x = moving_block.position.x + 5
	var distance_to_edge = min(block_x, 290 - block_x)
	var is_left_side = block_x < 145
	
	play_sound(distance_to_edge, is_left_side)
	show_shadow()
	
	var zone = get_hit_zone(block_x)
	var reward = calculate_reward(distance_to_edge, zone)
	
	energy += reward.energy
	multiplier = clamp(multiplier + reward.multiplier_change, 1.0, 10.0)
	
	show_feedback(reward)
	flash_zone(zone)

func get_hit_zone(block_x):
	if block_x < 145:
		return left_zone
	else:
		return right_zone

func calculate_reward(distance, zone):
	if distance <= 15:
		zone.color = Color.GREEN
		return {
			"energy": 3.0 * multiplier,
			"multiplier_change": 0.5,
			"text": "PERFECT!"
		}
	elif distance <= 30:
		zone.color = Color.YELLOW
		return {
			"energy": 1.5 * multiplier,
			"multiplier_change": 0.2,
			"text": "GOOD"
		}
	elif distance <= 50:
		zone.color = Color.ORANGE
		return {
			"energy": 1.0 * multiplier,
			"multiplier_change": 0.0,
			"text": "OK"
		}
	else:
		zone.color = Color.RED
		return {
			"energy": 0.5 * multiplier,
			"multiplier_change": -0.5,
			"text": "MISS"
		}

func play_sound(distance, is_left):
	if is_left:
		click_sound.pitch_scale = 0.8 + (1.0 - distance / 150.0) * 0.3
	else:
		click_sound.pitch_scale = 6.4 + (1.0 - distance / 150.0) * 0.6
	
	click_sound.volume_db = -14 + max(0, (50 - distance) / 10)
	click_sound.play()

func show_shadow():
	click_shadow.position.x = moving_block.position.x
	click_shadow.visible = true
	click_shadow.modulate.a = 0.6
	
	var tween = create_tween()
	tween.tween_property(click_shadow, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): click_shadow.visible = false)

func show_feedback(reward):
	show_rating_text(reward.text)
	animate_button()

func show_rating_text(text):
	var label = Label.new()
	$GameArea/CenterContainer/RitualCircle.add_child(label)
	label.text = text.to_upper()
	label.position = Vector2(200, 180)
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	
	if text == "PERFECT!":
		label.add_theme_font_size_override("font_size", 48)
		label.modulate = Color(1.0, 0.8, 0.0, 1.0)
		label.scale = Vector2(0.5, 0.5)
		var shake = create_tween()
		shake.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
		shake.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	elif text == "GOOD":
		label.add_theme_font_size_override("font_size", 36)
		label.modulate = Color(0.2, 1.0, 0.2, 1.0)
	elif text == "OK":
		label.add_theme_font_size_override("font_size", 28)
		label.modulate = Color(1.0, 0.7, 0.2, 1.0)
	else:
		label.add_theme_font_size_override("font_size", 32)
		label.modulate = Color(1.0, 0.1, 0.1, 1.0)
		label.rotation = randf_range(-0.2, 0.2)
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_property(label, "scale", label.scale * 0.8, 0.5)
	tween.chain().tween_callback(func(): label.queue_free())

func animate_button():
	var tween = create_tween()
	tween.tween_property(summon_button, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(summon_button, "scale", Vector2(1.0, 1.0), 0.1)

func flash_zone(zone):
	var tween = create_tween()
	tween.tween_property(zone, "modulate:a", 1.5, 0.1)
	tween.tween_property(zone, "modulate:a", 1.0, 0.2)
	tween.tween_callback(func(): zone.color = Color(0.3, 0.6, 0.3, 0.5))
