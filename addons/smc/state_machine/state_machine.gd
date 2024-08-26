@icon("res://addons/smc/icons/icon_state_machine.png")
class_name StateMachine
extends Node
## The main component of the FSM system
##
## Manages the states/state groups dependencies and automatically registers states.
## The state machine also has an internal state group allowing states to be directly
## added as child of the machine when making a single-group state pattern.

## Emitted when a state is changed in the machine, the name of the group affected
## and the name of the new state as StringNames are sent respectively.
signal state_changed(group_name: StringName, state_name: StringName)

@export var component_manager: ComponentManager
@export var initial_state: StringName
@export var initial_params: Dictionary

var internal_group: StateGroup = StateGroup.new()
var groups: Array[StateGroup]

func _ready():
	internal_group.name = "_internal_state_group"
	if not component_manager.is_node_ready():
		await component_manager.ready
	add_child(internal_group)
	reload_groups()

func add_group(group: StateGroup, reload: bool = true):
	groups.append(group)
	if reload:
		group.reload_states(component_manager)
	for state in group.states:
		state.transition_requested.connect(_on_state_transition_request)

func unload_groups():
	for group in groups:
		for state in group.states:
			state.transition_requested.disconnect(_on_state_transition_request)
	groups = []

func reload_groups():
	unload_groups()
	internal_group.states = []
	for node in get_children():
		if node is StateGroup and node != internal_group:
			add_group(node)
		elif node is State:
			internal_group.add_state(node, component_manager)
	add_group(internal_group, false)
	if initial_state != "":
		internal_group.transition_to(initial_state, initial_params)

func get_group(group_name: StringName) -> StateGroup:
	for group in groups:
		if group.name == group_name:
			return group
	return null

func transition_to(state_name: StringName, params: Dictionary = {}):
	for group in groups:
		if group.transition_to(state_name, params):
			state_changed.emit(group.name, state_name)
			return

func _on_state_transition_request(state_name: StringName, params: Dictionary = {}):
	transition_to(state_name, params)
