class_name StatsComponent
extends Component

@export var max_jumps: int
@export_group("physics")
@export var jump_force: int
@export var alt_jump_force: int
@export var acceleration: int
@export var max_speed: int
@export var air_acceleration: int
@export var air_max_speed: int
@export_group("current")
@export var jumps: int

func reset_stat(stat_name: StringName):
	var max_name := "max_" + stat_name
	if get(stat_name) != null and get(max_name) != null:
		set(stat_name, get(max_name))
