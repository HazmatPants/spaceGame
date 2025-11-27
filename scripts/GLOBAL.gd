extends Node

var player: CharacterBody3D

func _ready() -> void:
	player = get_tree().current_scene.get_node("Player")

func _process(_delta: float) -> void:
	var lowpass = 50.0
	if not player:
		return

	if player.atm > 0.0:
		lowpass = 2000.0

	AudioServer.set_bus_effect_enabled(1, 2, player.freq_analyzer)

	if player.freq_analyzer:
		lowpass = 20000.0
		AudioServer.get_bus_effect(1, 1).drive = 0.4
	else:
		AudioServer.get_bus_effect(1, 1).drive = 0.0

	AudioServer.get_bus_effect(1, 0).cutoff_hz = lerp(AudioServer.get_bus_effect(1, 0).cutoff_hz,
	lowpass, 0.1)

	AudioServer.get_bus_effect(0, 0).cutoff_hz = lerp(100, 20500, player.health)

func playsound(stream: AudioStream, volume_linear: float=1.0):
	var ap = AudioStreamPlayer.new()
	ap.stream = stream
	ap.volume_linear = volume_linear
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func playsound_random(streams: Array[AudioStream], volume_linear: float=1.0):
	playsound(streams[randi_range(0, streams.size() - 1)], volume_linear)
