extends CanvasLayer

@export_node_path("CharacterBody3D") var player_path
var player: CharacterBody3D

@onready var playerHUD = $PlayerHUD
@onready var O2Label = $PlayerHUD/BottomLeft/O2Label
@onready var PowerLabel = $PlayerHUD/BottomLeft/PowerLabel
@onready var PowerUsageBar = $PlayerHUD/BottomLeft/HBoxContainer/CenterContainer/PowerUsageBar

var O2TimeLabel: Label
var BattTimeLabel: Label
var SpotLabel: Label
var StatusLabel: Label
var FreqAnalyzerLabel: Label
var DampLabel: Label
var JetpackLabel: Label

var warn_timer: float = 0.0

func _ready():
	if player_path != null:
		player = get_node(player_path)
	$Debug.visible = false

	player.HeartBeat.connect(HeartBeat)

	SpotLabel = new_label("SpotLabel", "", $PlayerHUD/BottomLeft/StatusContainer)
	FreqAnalyzerLabel = new_label("FreqAnalyzerLabel", "", $PlayerHUD/BottomLeft/StatusContainer)
	JetpackLabel = new_label("JetpackLabel", "", $PlayerHUD/BottomLeft/StatusContainer)
	DampLabel = new_label("DampLabel", "", $PlayerHUD/BottomLeft/StatusContainer)

	O2TimeLabel = new_label("O2TimeLabel", "", $PlayerHUD/BottomLeft/StatusContainer)
	BattTimeLabel = new_label("BattTimeLabel", "", $PlayerHUD/BottomLeft/StatusContainer)
	StatusLabel = new_label("StatusLabel", "Status: OK", $PlayerHUD/BottomLeft/StatusContainer)

var power_usage: float = 0.0
var power_delta: int = 0

func _process(delta):
	playerHUD.modulate.a = randf_range(0.75, 0.8)

	if player == null:
		return

	if player.hull:
		$PlayerHUD/BottomLeft/ExtAtmLabel.text = "EXT ATM: %.1f" % player.hull.atm
	else:
		$PlayerHUD/BottomLeft/ExtAtmLabel.text = "EXT ATM: 0.0"

	O2TimeLabel.text = "O2Δ: T-%s" % [int(player.O2 / player.O2_use_rate)]

	power_delta = lerp(power_delta, int(player.suit_power / abs(player.power_usage) / 60), 0.1)

	BattTimeLabel.text = "BATTΔ: T-%s" % power_delta

	if player.O2 <= 0.1:
		warn_timer += delta
		if player.O2 <= 0.05:
			O2Label.text = "O2: %.1f%% < CRITICAL !" % [player.O2 * 100]
			if warn_timer < 0.25:
				O2Label.modulate = Color.WHITE
			else:
				O2Label.modulate = Color.RED
		else:
			O2Label.text = "O2: %.1f%% < LOW !" % [player.O2 * 100]
			if warn_timer < 0.25:
				O2Label.modulate = Color.WHITE
			else:
				O2Label.modulate = Color.YELLOW
	else:
		O2Label.text = "O2: %.1f%%" % [player.O2 * 100]
	if player.health < 0.5:
		if player.health < 0.25:
			if warn_timer < 0.25:
				$PlayerHUD/HealthLabel.modulate = Color.WHITE
			else:
				$PlayerHUD/HealthLabel.modulate = Color.RED
		else:
			if warn_timer < 0.25:
				$PlayerHUD/HealthLabel.modulate = Color.WHITE
			else:
				$PlayerHUD/HealthLabel.modulate = Color.YELLOW
	else:
		$PlayerHUD/HealthLabel.modulate = Color.WHITE

	if player.suit_power <= 0.1:
		warn_timer += delta
		if player.suit_power <= 0.05:
			PowerLabel.text = "BATT: %.1f%% < CRITICAL !" % [player.suit_power * 100]
			if warn_timer < 0.25:
				PowerLabel.modulate = Color.WHITE
			else:
				PowerLabel.modulate = Color.RED
		else:
			PowerLabel.text = "BATT: %.1f%% < LOW !" % [player.suit_power * 100]
			if warn_timer < 0.25:
				PowerLabel.modulate = Color.WHITE
			else:
				PowerLabel.modulate = Color.YELLOW
	else:
		PowerLabel.text = "BATT: %.1f%%" % [player.suit_power * 100]

	power_usage = lerp(power_usage, abs(player.power_usage * 1e5), 0.1)

	PowerUsageBar.value = power_usage
	PowerUsageBar.modulate = Color(1.0, 1.5 - power_usage, 1.5 - power_usage)

	if warn_timer > 0.5:
		warn_timer = 0.0
		if player.O2 <= 0.05:
			GLOBAL.playsound(preload("res://assets/audio/sfx/ui/warn.wav"))

	$PlayerHUD/Level.rotation = player.rotation.z

	var level_pos = player.rotation.x * 450

	$PlayerHUD/Level.position.x = ($PlayerHUD/Crosshair.position.x + sin(-$PlayerHUD/Level.rotation) * level_pos) - 28
	$PlayerHUD/Level.position.y = $PlayerHUD/Crosshair.position.y + cos(-$PlayerHUD/Level.rotation) * level_pos

	var rot = player.rotation_degrees

	$PlayerHUD/AzimuthLabel.text = "%.1f°" % fposmod(rot.y, 360.0)
	$PlayerHUD/ElevationLabel.text = "%.1f°" % rot.x

	SpotLabel.text = "SPOTLIGHT ON" if player.flashlight else ""

	if player.freq_analyzer:
		FreqAnalyzerLabel.text = "FREQ ANALYZER ON" 
		FreqAnalyzerLabel.modulate = Color.GREEN
	else:
		FreqAnalyzerLabel.text = "FREQ ANALYZER OFF" 
		FreqAnalyzerLabel.modulate = Color.RED

	if player.dampening:
		DampLabel.text = "DAMPENERS ON"
		DampLabel.modulate = Color.GREEN
	else:
		DampLabel.modulate = Color.RED
		DampLabel.text = "DAMPENERS OFF"

	if player.jetpack:
		JetpackLabel.text = "JETPACK ON"
		JetpackLabel.modulate = Color.GREEN
	else:
		JetpackLabel.modulate = Color.RED
		JetpackLabel.text = "JETPACK OFF"

	$PlayerHUD/HealthLabel.text = "H: %s" % [int(player.health * 100)]

	$PlayerHUD/HealthLabel/RegenBG.modulate.a = player.regen_timer - 1.0
	$PlayerHUD/HealthLabel/RegenBG.size = $PlayerHUD/HealthLabel.size

	if $PlayerHUD/ECG/TextureRect/Gradient.position.x < 400:
		$PlayerHUD/ECG/TextureRect/Gradient.position.x += 15 * (player.heart_rate / 100)

	$PlayerHUD/ECG/TextureRect.self_modulate = Color(1.0, player.health, player.health)

	if is_zero_approx(player.atm):
		StatusLabel.text = "Status: IN VACUUM"
	else:
		StatusLabel.text = "Status: OK"

	$VisorOverlay.visible = player.visor
	$PlayerHUD.visible = player.visor and not player.suit_power <= 0.0
	$NoPowerLabel.visible = player.suit_power <= 0.0

	$NoPowerLabel.modulate.a = lerp($NoPowerLabel.modulate.a, 0.5, 0.05)

	if warn_timer > 0.25:
		$NoPowerLabel.modulate.a = 1.0

	var blur = $BlurSharp.material.get_shader_parameter("blur_sharp")

	if player.O2 <= 0.0 or (not player.visor and player.atm <= 0.0):
		$BlurSharp.material.set_shader_parameter("blur_sharp", lerp(blur, -5.0, 0.005))
		if warn_timer > 0.25:
			$PlayerHUD/AsphyxLabel.visible = false
		else:
			$PlayerHUD/AsphyxLabel.visible = true
	else:
		$BlurSharp.material.set_shader_parameter("blur_sharp", lerp(blur, 0.0, 0.005))

	$Blackout.modulate.a = 1.0 - player.health

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

func HeartBeat():
	$PlayerHUD/ECG/TextureRect/Gradient.position.x = -172
	await get_tree().create_timer(0.1).timeout
	GLOBAL.playsound(preload("res://assets/audio/sfx/ui/ECG.wav"), lerp(0.05, 0.001, player.health))

func new_label(label_name: String, text: String, parent: Control) -> Label:
	var label = Label.new()
	label.name = label_name
	label.text = text
	parent.add_child(label)
	return label
