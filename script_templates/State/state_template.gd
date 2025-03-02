extends State

func get_dependencies() -> Dictionary[StringName, StringName]:
	return {}

func enter(prev_state: StringName, params: Dictionary[StringName, Variant] = {}):
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
