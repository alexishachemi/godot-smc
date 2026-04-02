@tool
@icon("res://addons/smc/icons/icon_state_machine.png")
class_name SMCStateMachine
extends Node

## The main component of the FSM system
##
## Manages the states/state groups dependencies and automatically registers states.
## The state machine also has an internal state group allowing states to be directly
## added as child of the machine when making a single-group state pattern.

#region Signals ----------------------------------------------------------------

## Emitted when a group is added to the state machine.
signal state_group_added(group: SMCStateGroup)
## Emitted when a group is removed from the state machine.
signal state_group_removed(group: SMCStateGroup)
## Emitted when a state is changed within a group. [param group] may be the 
## internal state group. You can check if that is the case by comparing its
## name with [constant INTERNAL_STATE_GROUP_NAME].
signal state_changed(group: SMCStateGroup, old: SMCState, new: SMCState)
## Emitted when a state is added to the state machine's internal group.
signal state_added(state: SMCState)
## Emitted when a state is removed from the state machine's internal group.
signal state_removed(state: SMCState)

#endregion
#region Constants --------------------------------------------------------------

## The name that will be given to the internal state group. Using it for another
## state group added to this machine will result in an error.
const INTERNAL_STATE_GROUP_NAME: StringName = "_internal_state_group"

#endregion
#region Exports ----------------------------------------------------------------

## The component manager used to resolve the component dependencies of
## [SMCState] nodes. If set, it is propagated through all state groups. See also
## [method SMCComponentManager.resolve_dependencies].
@export var component_manager: SMCComponentManager:
	set = set_component_manager
@export var reload_groups_on_start: bool = true
## The initial state of the internal group. Used only if the state machine has
## [SMCState] nodes in its children.
@export var initial_state: StringName:
	set = set_initial_state
## The arguments of the initial state. Used only when [member initial_state]
## is not empty and the state machine has [SMCState] nodes in its children.
@export var initial_args: Dictionary[StringName, Variant]
## Wether to add states that are children of the state machine to its internal 
## group when ready. See [method add_state]. Used only if the state machine has
## [SMCState] nodes in its children.
@export var reload_states_on_start: bool = true

#endregion
#region Private Variables ------------------------------------------------------

var _groups: Dictionary[StringName, SMCStateGroup]
var _internal_group: SMCStateGroup = SMCStateGroup.new()
var _show_internal_group_exports: bool = false

#endregion
#region Public Methods ---------------------------------------------------------


## Changes the current state of the group to the one named [param state_name]. 
## Only states present in this group are supported unlike
## [method SMCState.transition_to].
#func transition_to(
	#state_name: StringName,
	#group_name: StringName = "",
	#args: Dictionary[StringName, Variant] = {}
#) -> void:
	#var group: SMCStateGroup
	#if group_name.is_empty():
		#group = _internal_group
	#else:
		#group = 


## Adds a state group to the state machine.
## Does nothing if the group is already present.
func add_state_group(group: SMCStateGroup) -> void:
	if _groups.has(group.name):
		return
	_groups[group.name] = group
	group.current_state_changed.connect(state_changed.emit.bind(group))
	group.component_manager = component_manager
	group.initialize()
	state_group_added.emit(group)


## Removes a state group from the state machine.
## Returns [code]false[/code] is the group was not found inside the state
## machine and [code]true[/code] if it was successfully removed.
func remove_state_group(group: SMCStateGroup) -> bool:
	if not _groups.erase(group.name):
		return false
	group.current_state_changed.disconnect(state_changed.emit.bind(group))
	state_group_removed.emit(group)
	return true


## Removes all state groups from the state machine.
func clear_state_groups(free_groups: bool = false) -> void:
	var groups: Array[SMCStateGroup] = _groups.values().duplicate()
	_groups.clear()
	for group in groups:
		group.current_state_changed.disconnect(state_changed.emit.bind(group))
		state_group_removed.emit(group)
		if free_groups:
			group.queue_free()


## Returns the state group named [param group_name] or [code]null[/code]
## if it was not found.
func get_state_group(group_name: StringName) -> SMCStateGroup:
	return _groups.get(group_name)


## Returns all state groups registered to this state machine. This includes the 
## internal state group which will have the name 
## [constant INTERNAL_STATE_GROUP_NAME].
func get_state_groups() -> Array[SMCStateGroup]:
	return _groups.values()


func reload_state_groups_from_children() -> void:
	clear_state_groups()
	for node in get_children():
		if node is SMCStateGroup:
			add_state_group(node)

##########################
## Internal State Group ##
##########################

## Adds a state to the internal group. Does nothing if a state with the same 
## name is already present in it. See also [method SMCStateGroup.add_state].
func add_state(state: SMCState) -> void:
	_internal_group.add_state(state)


## Removes a state from the internal group. Returns [code]true[/code] if the
## state was successfully removed. [code]false[/code] otherwise. 
## See also [method SMCStateGroup.remove_state].
func remove_state(state: SMCState) -> bool:
	return _internal_group.remove_state(state)


## Returns the state named [param state_name] present in the internal group or
## [code]null[/code] if not found. See also [method SMCStateGroup.get_state].
func get_state(state_name: StringName) -> SMCState:
	return _internal_group.get_state(state_name)


## Returns an array containing all states managed by the internal group.
## See also [method SMCStateGroup.get_states].
func get_states() -> Array[SMCState]:
	return _internal_group.get_states()


## Returns the current active state of the internal group 
## or [code]null[/code] if there isn't any.
## See also [method SMCStateGroup.get_current_state].
func get_current_state() -> SMCState:
	return _internal_group.get_current_state()


## Removes all states from the internal group. If [param free_states] is 
## [code]true[/code], calls [method Node.queue_free] on each state.
## See also [method SMCStateGroup.clear_state].
func clear_states(free_states: bool = false) -> void:
	_internal_group.clear_states(free_states)


## Clears all states, then add all states that are direct child of the state
## machine to its internal group. See also 
## [method SMCStateGroup.reload_states_from_children].
func reload_states_from_children() -> void:
	clear_states()
	for node in get_children():
		if node is SMCState:
			add_state(node)


#endregion
#region Private Methods --------------------------------------------------------

func _ready() -> void:
	var update_properties: Callable = func(_x: Variant) -> void:
		if Engine.is_editor_hint():
			notify_property_list_changed()
	child_entered_tree.connect(update_properties)
	child_exiting_tree.connect(update_properties)
	if Engine.is_editor_hint():
		return
	for node in get_children():
		if node is SMCState:
			node.reparent(_internal_group)
	_internal_group.state_added.connect(state_added.emit)
	_internal_group.state_removed.connect(state_removed.emit)
	_internal_group.name = INTERNAL_STATE_GROUP_NAME
	_internal_group.reload_states_on_start = reload_states_on_start
	_internal_group.initial_state = initial_state
	_internal_group.initial_args = initial_args
	add_child(_internal_group)
	if reload_groups_on_start:
		reload_state_groups_from_children()
	else:
		add_state_group(_internal_group)

func _validate_property(property: Dictionary) -> void:
	match property.name:
		"initial_state":
			var names: Array[StringName] = []
			for node in get_children():
				if node is SMCState:
					names.append(node.name)
			_show_internal_group_exports = not names.is_empty()
			if not _show_internal_group_exports:
				property.usage ^= PROPERTY_USAGE_EDITOR
				return
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(names)
		"initial_args":
			if not _show_internal_group_exports:
				property.usage ^= PROPERTY_USAGE_EDITOR
		"reload_states_on_start":
			if not _show_internal_group_exports:
				property.usage ^= PROPERTY_USAGE_EDITOR

#endregion
#region Setters & Getters ------------------------------------------------------

func set_component_manager(manager: SMCComponentManager) -> void:
	component_manager = manager
	if component_manager:
		for group: SMCStateGroup in _groups.values():
			group.component_manager = component_manager


func set_initial_state(state_name: StringName) -> void:
	if not is_node_ready():
		initial_state = state_name
		return
	var names: Array[StringName] = [""]
	for node in get_children():
		if node is SMCState:
			names.append(node.name)
	if not names.has(state_name):
		state_name = names[0]
	initial_state = state_name

#endregion
