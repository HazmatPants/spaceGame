extends Node

func playsound(stream: AudioStream):
	var ap = AudioStreamPlayer.new()
	ap.stream = stream
	add_child(ap)
	ap.play()
	ap.finished.connect(ap.queue_free)
