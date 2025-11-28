extends CharacterBody3D

@onready var area = $Area3D

@export var move_speed: float = 10.0
@export var acceleration: float = 8.0
@export var deceleration: float = 0.5
@export var mouse_sensitivity: float = 0.005
@export var look_smoothing: float = 10.0
@export var roll_speed: float = 1.0
@export var roll_smoothing: float = 6.0

var dampening: bool = true

var movement_input := Vector3.ZERO
var smoothed_movement := Vector3.ZERO
var accumulated_velocity := Vector3.ZERO

var mouse_delta := Vector2.ZERO
var smoothed_mouse := Vector2.ZERO

var roll_input := 0.0
var smoothed_roll := 0.0

var sprinting: bool = false

var is_moving: bool = false
var was_moving: bool = false
var is_inputting: bool = false

#const sfx_breathe_in : Array[AudioStream] = [
	#preload("res://assets/audio/sfx/player/breathing/breathe_in1.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_in2.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_in3.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_in4.wav")
#]
#
#const sfx_breathe_out : Array[AudioStream] = [
	#preload("res://assets/audio/sfx/player/breathing/breathe_out1.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_out2.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_out3.wav"),
	#preload("res://assets/audio/sfx/player/breathing/breathe_out4.wav")
#]

var O2: float = 1.0
var health: float = 1.0
var suit_power: float = 1.0

var hull: Area3D = null
var atm: float = 0.0

var O2_use_rate: float = 0.0005

var regen_timer: float = 0.0

var heart_rate: float = 70.0
var beat_timer: float = 0.0

var flashlight: bool = false
var jetpack: bool = false
var freq_analyzer: bool = false
var visor: bool = true

var ap_breathe := AudioStreamPlayer.new()
var ap_jetpack := AudioStreamPlayer.new()
var ap_jetpack_start := AudioStreamPlayer.new()
var ap_freq_analyzer := AudioStreamPlayer.new()

signal HeartBeat

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	ap_breathe.stream = preload("res://assets/audio/sfx/player/breathing.wav")
	ap_breathe.autoplay = true
	ap_breathe.volume_linear = 0.5
	call_deferred("add_child", ap_breathe)

	ap_jetpack.stream = preload("res://assets/audio/sfx/player/jetpack/jetpack_loop.wav")
	ap_jetpack.autoplay = true
	ap_jetpack.volume_linear = 0.0
	call_deferred("add_child", ap_jetpack)

	ap_jetpack_start.stream = preload("res://assets/audio/sfx/player/jetpack/jetpack_start.wav")
	ap_jetpack_start.volume_linear = 0.3
	call_deferred("add_child", ap_jetpack_start)

	ap_freq_analyzer.stream = preload("res://assets/audio/sfx/ui/freqanalyzer.wav")
	ap_freq_analyzer.volume_linear = 0.1
	call_deferred("add_child", ap_freq_analyzer)

	area.area_entered.connect(_area_entered)
	area.area_exited.connect(_area_exited)

func _area_entered(body: Node3D):
	if body.is_in_group(&"hull"):
		hull = body
		atm = body.atm
		print("Entered hull: ", body)

func _area_exited(body: Node3D):
	hull = null
	atm = 0.0
	print("Exited hull: ", body)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_delta = event.relative
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.is_pressed():
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var jetpack_cooldown: float = 0.0

var was_inputting: bool = false

var old_power: float = suit_power
var power_usage: float = 0.0

func _process(delta):
	movement_input = Vector3.ZERO
	roll_input = 0.0

	if Input.is_action_pressed("move_forward"):
		movement_input.z -= 1
	if Input.is_action_pressed("move_backward"):
		movement_input.z += 1
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("move_up"):
		movement_input.y += 1
	if Input.is_action_pressed("move_down"):
		movement_input.y -= 1

	if Input.is_action_pressed("roll_left"):
		roll_input += 2 if sprinting else 1
	if Input.is_action_pressed("roll_right"):
		roll_input -= 2 if sprinting else 1

	is_inputting = movement_input.length() > 0.0

	jetpack_cooldown -= delta

	if Input.is_action_just_pressed("visor"):
		visor = !visor

	if Input.is_action_just_pressed("flashlight"):
		if suit_power > 0.0:
			flashlight = !flashlight
			$Camera/SpotLight.visible = flashlight
			if flashlight:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/ui_light_on.ogg"))
			else:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/ui_light_off.ogg"))

	if Input.is_action_just_pressed("dampeners"):
		if suit_power > 0.0:
			dampening = !dampening
			if dampening:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/on.wav"))
			else:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/off.wav"))

	if Input.is_action_just_pressed("freq_analyzer"):
		if suit_power > 0.0:
			freq_analyzer = !freq_analyzer
			AudioServer.get_bus_effect(1, 0).cutoff_hz = 20.0
			ap_freq_analyzer.playing = freq_analyzer
			if freq_analyzer:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/on.wav"))
			else:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/off.wav"))

	if Input.is_action_just_pressed("jetpack"):
		if suit_power > 0.0:
			jetpack = !jetpack
			if jetpack:
				ap_jetpack_start.play()
				ap_jetpack_start.volume_linear = 1.0
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/on.wav"))
			else:
				GLOBAL.playsound(preload("res://assets/audio/sfx/ui/off.wav"))

	O2 = clampf(O2, 0.0, 1.0)
	health = clampf(health, 0.0, 1.0)

	if O2 <= 0.0 or (not visor and atm <= 0.0):
		health -= 0.05 * delta

	if freq_analyzer:
		suit_power -= 0.0001 * delta

	suit_power -= 0.00005 * delta

	if flashlight:
		suit_power -= 0.0001 * delta

	O2 -= O2_use_rate * delta

	heart_rate = lerp(200, 70, health)

	if health < 1.0:
		regen_timer += delta
		if regen_timer > 2.0:
			health += 0.01
			regen_timer = 0.0
	else:
		regen_timer = 0.0

	beat_timer += delta

	if beat_timer >= 60 / heart_rate:
		HeartBeat.emit()
		beat_timer = 0.0

	if jetpack:
		suit_power -= 0.0002 * delta
		if is_inputting:
			ap_jetpack.volume_linear = lerp(ap_jetpack.volume_linear, 0.3, 0.1)
		else:
			ap_jetpack.volume_linear = lerp(ap_jetpack.volume_linear, 0.1, 0.1)
	else:
		ap_jetpack.volume_linear = lerp(ap_jetpack.volume_linear, 0.0, 0.1)

	ap_jetpack.pitch_scale = lerp(ap_jetpack.pitch_scale, 1.2 if sprinting else 1.0, 0.1)
	ap_jetpack_start.volume_linear = lerp(ap_jetpack_start.volume_linear, 0.2 if is_inputting and jetpack else 0.0, 0.05)

	if Input.is_action_just_pressed("sprint") and is_moving and jetpack:
		ap_jetpack_start.volume_linear = 1.0
		ap_jetpack_start.play()

	if dampening and velocity.length() > 0.2:
		suit_power -= 0.00001 * delta

	if is_inputting and jetpack:
		jetpack_cooldown = 0.5
		if sprinting:
			suit_power -= 0.0004 * delta
		else:
			suit_power -= 0.0002 * delta

	power_usage = suit_power - old_power

	if health <= 0.0:
		get_tree().change_scene_to_packed(preload("res://scenes/death_screen.tscn"))

	if old_power > 0.0 and suit_power <= 0.0:
		GLOBAL.playsound(preload("res://assets/audio/sfx/ui/warn.wav"))
		jetpack = false
		freq_analyzer = false
		ap_freq_analyzer.playing = false

	was_moving = is_moving
	was_inputting = is_inputting
	old_power = suit_power

func _physics_process(delta):
	smoothed_mouse = smoothed_mouse.lerp(mouse_delta, clamp(look_smoothing * delta, 0.0, 1.0))

	var yaw = -smoothed_mouse.x * mouse_sensitivity
	var pitch = -smoothed_mouse.y * mouse_sensitivity
	rotate_object_local(Vector3(1, 0, 0), pitch)
	rotate_object_local(Vector3(0, 1, 0), yaw)

	mouse_delta = Vector2.ZERO

	smoothed_roll = lerp(smoothed_roll, roll_input, clamp(roll_smoothing * delta, 0.0, 1.0))
	rotate_object_local(Vector3(0, 0, 1), smoothed_roll * roll_speed * delta)

	if movement_input != Vector3.ZERO:
		var move_delta = clamp(acceleration * delta, 0.0, 1.0)
		smoothed_movement = smoothed_movement.lerp(movement_input.normalized(), move_delta)

	var localbasis = global_transform.basis
	var direction = (localbasis.x * smoothed_movement.x +
					 localbasis.y * smoothed_movement.y +
					 localbasis.z * smoothed_movement.z)

	sprinting = Input.is_action_pressed("sprint")

	var speed = move_speed * 2 if sprinting else move_speed

	if movement_input != Vector3.ZERO: 
		if jetpack:
			accumulated_velocity += direction * speed * delta
		else:
			accumulated_velocity += direction * (speed / 10) * delta

	if dampening and movement_input == Vector3.ZERO:
		accumulated_velocity = accumulated_velocity.lerp(Vector3.ZERO, clamp(deceleration * delta, 0.0, 1.0))

	velocity = accumulated_velocity

	is_moving = velocity.length() > 0.25

	move_and_slide()
