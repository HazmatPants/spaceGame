extends CanvasLayer

@export_node_path("CharacterBody3D") var player_path
var player: CharacterBody3D

@onready var playerHUD = $PlayerHUD
@onready var O2Label = $PlayerHUD/BottomLeft/O2Label
@onready var PowerLabel = $PlayerHUD/BottomLeft/PowerLabel

var warn_timer: float = 0.0

func _ready():
	if player_path != null:
		player = get_node(player_path)
	$Debug.visible = false

	player.HeartBeat.connect(HeartBeat)

func _process(delta):
	playerHUD.modulate.a = randf_range(0.75, 0.8)

	if player == null:
		return

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

	if player.suit_power <= 0.1:
		warn_timer += delta
		if player.suit_power <= 0.05:
			PowerLabel.text = "BATT: %.1f%% < CRITICAL !" % [player.suit_power * 100]
			if warn_timer < 0.5:
				PowerLabel.modulate = Color.WHITE
			else:
				PowerLabel.modulate = Color.RED
		else:
			PowerLabel.text = "BATT: %.1f%% < LOW !" % [player.suit_power * 100]
			if warn_timer < 0.5:
				PowerLabel.modulate = Color.WHITE
			else:
				PowerLabel.modulate = Color.YELLOW
	else:
		PowerLabel.text = "BATT: %.1f%%" % [player.suit_power * 100]

	if warn_timer > 1.0:
		warn_timer = 0.0
		if player.O2 <= 0.05:
			GLOBAL.playsound(preload("res://assets/audio/sfx/ui/blip.wav"))

	$PlayerHUD/BottomLeft/CO2Label.text = "CO2: %.1f%%" % [player.CO2 * 100]

	$PlayerHUD/Level.rotation = player.rotation.z
	$PlayerHUD/Level/RollVel.scale.x = -player.smoothed_roll * 15

	var rot = player.rotation_degrees

	$PlayerHUD/TopLeft/AzimuthLabel.text = "AZIMUTH: %.1f°" % fposmod(rot.y, 360.0)
	$PlayerHUD/TopLeft/ElevationLabel.text = "ELEV: %.1f°" % rot.x

	$PlayerHUD/BottomLeft/SpotLabel.text = "SPOTLIGHT ON" if player.flashlight else ""

	$PlayerHUD/ECG/BPMLabel.text = "BPM: %s" % str(int(player.heart_rate))
	if $PlayerHUD/ECG/TextureRect/Gradient.position.x < 400:
		$PlayerHUD/ECG/TextureRect/Gradient.position.x += 15

	# Debug Menu
	if Input.is_action_just_pressed("debug"):
		$Debug.visible = !$Debug.visible

	if $Debug.visible:
		var vel = player.velocity
		$Debug/VBoxContainer/VelocityLabel.text = "Velocity: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z]
		var pos = player.global_position
		$Debug/VBoxContainer/PositionLabel.text = "Position (Global): (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]

		$Debug/VBoxContainer/MovingLabel.text = "    Moving" if player.is_moving else "NOT Moving"
		$Debug/VBoxContainer/O2Label.text = "O2: %f" % player.O2
		$Debug/VBoxContainer/CO2Label.text = "CO2: %f" % player.CO2

func HeartBeat():
	GLOBAL.playsound(preload("res://assets/audio/sfx/ui/ECG.wav"), 0.001)
	$PlayerHUD/ECG/TextureRect/Gradient.position.x = -172
