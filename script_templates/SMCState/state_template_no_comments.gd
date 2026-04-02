# meta-name: Default without comments
# meta-description: Base template for SMCState with default callbacks.

extends _BASE_


func _initialize():
	pass


func _enter(previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
	pass


func _exit(next_state: StringName, next_state_args: Dictionary[StringName, Variant]) -> void:
	pass


func _process(delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	pass
