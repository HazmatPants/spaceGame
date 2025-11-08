extends CharacterBody3D

@export var move_speed: float = 10.0
@export var acceleration: float = 8.0
@export var deceleration: float = 0.5
@export var mouse_sensitivity: float = 0.005
@export var look_smoothing: float = 10.0
@export var roll_speed: float = 1.0
@export var roll_smoothing: float = 6.0

@export var dampening: bool = true

var movement_input := Vector3.ZERO
var smoothed_movement := Vector3.ZERO
var accumulated_velocity := Vector3.ZERO

var mouse_delta := Vector2.ZERO
var smoothed_mouse := Vector2.ZERO

var roll_input := 0.0
var smoothed_roll := 0.0

var is_moving: bool = false

const sfx_breathe_in := [
	preload("res://assets/audio/sfx/player/breathing/breathe_in1.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_in2.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_in3.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_in4.wav")
]

const sfx_breathe_out := [
	preload("res://assets/audio/sfx/player/breathing/breathe_out1.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_out2.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_out3.wav"),
	preload("res://assets/audio/sfx/player/breathing/breathe_out4.wav")
]

var O2: float = 1.0
var CO2: float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.is_pressed():
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var breathe_timer: float = 2.0
var next_breathe_time: float = 3.0
var breathe_cycle: bool = true # true = breathe in

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
		roll_input += 1
	if Input.is_action_pressed("roll_right"):
		roll_input -= 1

	breathe_timer += delta

	if breathe_timer > next_breathe_time:
		breathe_timer = 0.0
		if O2 <= 0.05:
			next_breathe_time = randf_range(2.0, 2.5)
		else:
			next_breathe_time = randf_range(2.5, 3.5)
		if breathe_cycle:
			GLOBAL.playsound(sfx_breathe_in[randf_range(0, sfx_breathe_in.size() - 1)])
			O2 -= 0.001
			breathe_cycle = false
		else:
			GLOBAL.playsound(sfx_breathe_out[randf_range(0, sfx_breathe_out.size() - 1)])
			CO2 += 0.0001
			breathe_cycle = true

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

	if movement_input != Vector3.ZERO:
		accumulated_velocity += direction * move_speed * delta

	if dampening and movement_input == Vector3.ZERO:
		accumulated_velocity = accumulated_velocity.lerp(Vector3.ZERO, clamp(deceleration * delta, 0.0, 1.0))

	velocity = accumulated_velocity

	is_moving = velocity.length() > 0.001

	move_and_slide()
