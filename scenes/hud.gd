extends CanvasLayer

@export_node_path("CharacterBody3D") var player_path
var player: CharacterBody3D

@onready var playerHUD = $PlayerHUD
@onready var O2Label = $PlayerHUD/VBoxContainer/O2Label

func _ready():
	player = get_node(player_path)
	$Debug.visible = false

var warn_timer: float = 0.0

func _process(delta):
	playerHUD.modulate.a = randf_range(0.7, 0.8)

	if player.O2 <= 0.1:
		warn_timer += delta
		if player.O2 <= 0.05:
			O2Label.text = "O2: %.1f%% < CRITICAL !" % [player.O2 * 100]
			if warn_timer < 0.5:
				O2Label.modulate = Color.WHITE
			else:
				O2Label.modulate = Color.RED
		else:
			O2Label.text = "O2: %.1f%% < LOW !" % [player.O2 * 100]
			if warn_timer < 0.5:
				O2Label.modulate = Color.WHITE
			else:
				O2Label.modulate = Color.YELLOW
	else:
		O2Label.text = "O2: %.1f%%" % [player.O2 * 100]

	if warn_timer > 1.0:
		warn_timer = 0.0
		if player.O2 <= 0.05:
			GLOBAL.playsound(preload("res://assets/audio/sfx/ui/blip.wav"))

	$PlayerHUD/VBoxContainer/CO2Label.text = "CO2: %.1f%%" % [player.CO2 * 100]

	# Debug Menu
	if Input.is_action_just_pressed("debug"):
		$Debug.visible = !$Debug.visible

	if $Debug.visible:
		var vel = player.accumulated_velocity
		$Debug/VBoxContainer/VelocityLabel.text = "Velocity: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z]
		var pos = player.global_position
		$Debug/VBoxContainer/PositionLabel.text = "Position (Global): (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]

		$Debug/VBoxContainer/MovingLabel.text = "    Moving" if player.is_moving else "NOT Moving"
		$Debug/VBoxContainer/O2Label.text = "O2: %f" % player.O2
		$Debug/VBoxContainer/CO2Label.text = "CO2: %f" % player.CO2
