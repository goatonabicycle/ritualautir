extends Control

var spirit_energy = 0.0
var displayed_energy = 0.0
var multiplier = 1.0
var displayed_multiplier = 1.0
var base_energy_per_click = 1
var last_click_time = 0

var heartbeat_timer = 0.0
var heartbeat_interval = 1.0
var rhythm_window = 0.15
var perfect_window = 0.05
var multiplier_decay_rate = 0.2
var multiplier_growth_rate = 0.3
var passive_energy_per_beat = 0.5

@onready var energy_label = $GameArea/TopBar/StatsContainer/EnergyPanel/EnergyValue
@onready var multiplier_label = $GameArea/TopBar/StatsContainer/MultiplierPanel/MultiplierValue
@onready var click_sound = $AudioStreamPlayer
@onready var summon_button = $GameArea/CenterContainer/RitualCircle/SummonButton
@onready var click_feedback = $GameArea/CenterContainer/RitualCircle/ClickFeedback
@onready var ritual_circle = $GameArea/CenterContainer/RitualCircle
@onready var heartbeat_indicator = $GameArea/CenterContainer/RitualCircle/HeartbeatIndicator
@onready var heartbeat_pulse = $GameArea/CenterContainer/RitualCircle/HeartbeatPulse

func _ready():
	summon_button.pressed.connect(on_summon_clicked)
	setup_audio_buses()
	update_display()

func setup_audio_buses():	
	pass

func _process(delta):
	heartbeat_timer += delta
	
	if heartbeat_timer >= heartbeat_interval:
		heartbeat_timer -= heartbeat_interval
		pulse_heartbeat()
		spirit_energy += passive_energy_per_beat * multiplier
	
	multiplier = max(1.0, multiplier - multiplier_decay_rate * delta)
	
	displayed_energy = lerp(displayed_energy, spirit_energy, delta * 10)
	displayed_multiplier = lerp(displayed_multiplier, multiplier, delta * 5)
	
	update_heartbeat_visual()
	update_display()

func pulse_heartbeat():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(heartbeat_pulse, "scale:y", 3.0, 0.1)
	tween.tween_property(heartbeat_pulse, "color:a", 0.8, 0.1)
	tween.chain().set_parallel(true)
	tween.tween_property(heartbeat_pulse, "scale:y", 1.0, 0.3)
	tween.tween_property(heartbeat_pulse, "color:a", 0.5, 0.3)

func update_heartbeat_visual():
	var beat_progress = heartbeat_timer / heartbeat_interval
	var alpha = 0.3 + sin(beat_progress * TAU) * 0.2
	heartbeat_indicator.color = Color(0.6, 0.1, 0.1, alpha)

func on_summon_clicked():
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_beat = fmod(heartbeat_timer, heartbeat_interval)
	
	var timing_accuracy = 0.0
	if time_since_beat < rhythm_window or time_since_beat > heartbeat_interval - rhythm_window:
		if time_since_beat < perfect_window or time_since_beat > heartbeat_interval - perfect_window:
			timing_accuracy = 1.0
			multiplier = min(multiplier + multiplier_growth_rate * 2, 10.0)
			show_timing_feedback("PERFECT!")
		else:
			timing_accuracy = 0.5
			multiplier = min(multiplier + multiplier_growth_rate, 10.0)
			show_timing_feedback("GOOD")
	else:
		multiplier = max(1.0, multiplier - 0.5)
		show_timing_feedback("MISS")
	
	last_click_time = current_time
	
	var energy_gained = base_energy_per_click * multiplier
	spirit_energy += energy_gained
	
	show_click_feedback(energy_gained)
	animate_button_press()
	
	var pitch_variation = 1.0 + timing_accuracy * 0.5
	click_sound.pitch_scale = randf_range(1.2, 1.6) * pitch_variation
	click_sound.volume_db = -14 + timing_accuracy * 3
	click_sound.play()
	
	update_display()

func show_timing_feedback(text):
	var timing_label = Label.new()
	ritual_circle.add_child(timing_label)
	timing_label.text = text
	timing_label.add_theme_font_size_override("font_size", 24)
	timing_label.position = Vector2(200, 150)
	timing_label.anchor_left = 0.5
	timing_label.anchor_top = 0.5
	
	var color = Color.WHITE
	if text == "PERFECT!":
		color = Color.GOLD
	elif text == "GOOD":
		color = Color.GREEN
	else:
		color = Color.RED
	
	timing_label.modulate = color
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(timing_label, "position:y", timing_label.position.y - 30, 0.5)
	tween.tween_property(timing_label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func(): timing_label.queue_free())

func show_click_feedback(amount):
	click_feedback.text = "+" + str(int(amount))
	click_feedback.visible = true
	click_feedback.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(click_feedback, "position:y", click_feedback.position.y - 50, 0.5)
	tween.tween_property(click_feedback, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(func(): click_feedback.visible = false)

func animate_button_press():
	var tween = create_tween()
	tween.tween_property(summon_button, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(summon_button, "scale", Vector2(1.0, 1.0), 0.1)

func update_display():
	energy_label.text = str(int(displayed_energy))
	multiplier_label.text = "x" + str(snappedf(displayed_multiplier, 0.01))
