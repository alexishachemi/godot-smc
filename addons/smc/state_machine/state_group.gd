@icon("res://addons/smc/icons/icon_state_group.png")
class_name StateGroup
extends Node
## A group of states
##
## State groups allow for basic behavioural separation within the state machine.
## In each group, only one state can be active at a time. This allows for
## multiple states to be active at one time as long as they are in different groups.
## any state from any group can request a transition to any state from any other groups.
## If the requested state is from a different group then the state making the request
## won't be changed and the requested state will be set active in its respective group. 

@export var initial_state: StringName = ""
@export var initial_params: Dictionary = {}

var states: Array[State]
var current_state: State : set = _set_current_state
var previous_state: State

func add_state(state: State, cmanager: ComponentManager):
	states.append(state)
	var dep_dict := state.get_dependencies()
	var dep_comp: Component = null
	for dep_name in dep_dict:
		dep_comp = cmanager.get_component_by_class(dep_name)
		if not dep_comp:
			push_warning("component manager could not find dependency [%s] of state [%s]" \
				% [dep_name, state.name])
		state.set(dep_dict[dep_name], dep_comp)

func reload_states(cmanager: ComponentManager):
	states = []
	for node in get_children():
		if node is State:
			add_state(node, cmanager)
	if initial_state != "":
		transition_to(initial_state, initial_params)

func _get_prev_state_name() -> StringName:
	if previous_state:
		return previous_state.name
	return ""

func transition_to(state_name: StringName, params: Dictionary = {}) -> bool:
	for state in states:
		if state.name == state_name:
			if current_state:
				current_state._exit()
			current_state = state
			current_state._enter(_get_prev_state_name(), params)
			return true
	return false

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _set_current_state(new_state: State):
	previous_state = current_state
	current_state = new_state
