extends Node

func playsound(stream: AudioStream, volume_linear: float=1.0):
	var ap = AudioStreamPlayer.new()
	ap.stream = stream
	ap.volume_linear = volume_linear
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)

func playsound_random(streams: Array[AudioStream], volume_linear: float=1.0):
	playsound(streams[randi_range(0, streams.size() - 1)], volume_linear)
