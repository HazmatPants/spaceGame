extends Control

var death_message ="> HEART FIBRILLATION DETECTED\n> ATTEMPTING DEFIBRILLATION..."

var revive_fail = "
> ATTEMPT UNSUCCESSFUL
> USER DEATH CONFIRMED
> WRITING POST MORTEM TO BLACK BOX...
> SHUTTING DOWN...
"

var idx: int = -1

var revive: bool = false

func _ready() -> void:
	$AudioStreamPlayer.volume_linear = 0.01
	$AudioStreamPlayer.play()
	await type(death_message)
	await get_tree().create_timer(1.0).timeout
	if randf() > 1.0:
		# revive success?
		pass
	else:
		await type(revive_fail)
		await get_tree().create_timer(0.2).timeout
		$TextEdit.text = "Broadcast message from root@%s on pts/2\n\nThe system will poweroff now!\n" % randi_range(10000, 99999) 
		await get_tree().create_timer(randf()).timeout
		$TextEdit.text += "\n[%s.%s] watchdog: watchdog0: watchdog did not stop!" % [randi_range(10000, 99999), randi_range(10000, 99999)]
		await get_tree().create_timer(0.2).timeout
		for i in range(20):
			$AudioStreamPlayer.volume_linear = randf_range(0.001, 0.01)
			$TextEdit.modulate.a = randf_range(0.5, 1.0)
			await get_tree().process_frame
		$AudioStreamPlayer.volume_linear = 0.0
		$TextEdit.modulate.a = 0.0

func type(text: String):
	for i in text:
		if i == "\n":
			await get_tree().create_timer(0.75).timeout
		$TextEdit.text += i
		await get_tree().process_frame
