@icon("res://addons/smc/icons/icon_state.png")
class_name State
extends Node
## A state managed by the state machine
##
## No state should share the same name within the same state machine

signal transition_requested(StringName, Dictionary)

func transition_to(state_name: StringName, params: Dictionary = {}):
	transition_requested.emit(state_name, params)

## If the state needs components to work, this function must
## be overloaded and return a dictionary whose keys are the class
## names of the components needed and the values are the name of the
## property to store the component.
func get_dependencies() -> Dictionary:
	return {}

func _enter(prev_state: StringName, params: Dictionary = {}):
	enter(prev_state, params)

func _exit():
	exit()

func enter(prev_state: StringName, params: Dictionary = {}):
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
