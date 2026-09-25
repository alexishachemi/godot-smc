class_name AudioService
extends SMCService


const LIBRARY: Dictionary[StringName, AudioStream] = {
	&"impact": preload("uid://br6chpamfqruj"),
	&"jump": preload("uid://suphii0sdagu")
}


func play(sound: StringName) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = LIBRARY[sound]
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
