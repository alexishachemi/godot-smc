# meta-name: Default
# meta-description: Base template for SMCState with default callbacks.
# meta-default: true

extends _BASE_


# Define component dependencies like follows:
#
# @export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", 0)
# var my_component: MyComponent 
#


# Called when the state is added into a state group.
func _initialize():
	pass


# Called when the state is transitioned into.
func _enter(previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
	pass


# Called when the state transitions into another.
func _exit(next_state: StringName, next_state_args: Dictionary[StringName, Variant]) -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Called every physics frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass
