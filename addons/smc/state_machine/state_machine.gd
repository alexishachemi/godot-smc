@tool
@icon("../icons/icon_state_machine.png")
class_name SMCStateMachine
extends Node

## The main component of the FSM system
##
## Manages the states/state groups dependencies and automatically registers states.
## The state machine also has an internal state group allowing states to be directly
## added as child of the machine when making a single-group state pattern.

#region Signals ----------------------------------------------------------------

## Emitted when a state is changed within a group. [param group] may be the 
## internal state group. You can check if that is the case by comparing its
## name with [constant INTERNAL_STATE_GROUP_NAME].
signal state_changed(old: SMCState, new: SMCState, group: SMCStateGroup)

#endregion
#region Constants --------------------------------------------------------------

## The name that will be given to the internal state group. Using it for another
## state group added to this machine will result in an error.
const INTERNAL_STATE_GROUP_NAME: StringName = "_internal_state_group"

#endregion
#region Exports ----------------------------------------------------------------

## The initial state of the internal group. Used only if the state machine has
## [SMCState] nodes in its children.
@export var initial_state: StringName:
	set = _set_initial_state

## The arguments of the initial state. Used only when [member initial_state]
## is not empty and the state machine has [SMCState] nodes in its children.
@export var initial_args: Dictionary[StringName, Variant]

#endregion
#region Private Variables ------------------------------------------------------

var _groups: Dictionary[StringName, SMCStateGroup]
var _internal_group: SMCStateGroup = SMCStateGroup.new()
var _show_internal_group_exports: bool = false
var _component_manager: SMCComponentManager

#endregion
#region Built-in Methods -------------------------------------------------------


func _ready() -> void:
	var update_properties: Callable = func(_x: Variant) -> void:
		if Engine.is_editor_hint():
			notify_property_list_changed()
	child_entered_tree.connect(update_properties)
	child_exiting_tree.connect(update_properties)
	if Engine.is_editor_hint():
		return
	var use_internal: bool = false
	for node in get_children():
		if node is SMCState:
			node.reparent(_internal_group)
			use_internal = true
	_internal_group.name = INTERNAL_STATE_GROUP_NAME
	if use_internal:
		_internal_group.initial_state = initial_state
		_internal_group.initial_args = initial_args
	add_child(_internal_group)
	_component_manager = _find_component_manager()
	_load_state_groups_from_children()


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
#region Public Methods ---------------------------------------------------------


## Changes a the state of a group according to [param path] with the given 
## [param args]. The path should be either the state name if the state is
## managed by the internal state group (i.e. the states were directly attached
## to the state machine), or in the format <Group>/<State> (e.g. "Body/Idle").
## See also [method transition_group_to].
func transition_to(
	path: StringName,
	args: Dictionary[StringName, Variant] = {}
) -> void:
	var group_name: StringName
	var state_name: StringName
	var path_split: PackedStringArray = path.strip_edges().split("/", false)
	var size: int = path_split.size()
	if size == 1:
		group_name = INTERNAL_STATE_GROUP_NAME
		state_name = path_split[0]
	elif size == 2:
		group_name = path_split[0]
		state_name = path_split[1]
	else:
		assert(false, "Failed to transition state. Invalid path")
	transition_group_to(group_name, state_name, args)


## Changes a the state of the group [param group_name] to be the state
## [param state_name] passing [param args] in the transition. [br]
## This method is called by [method transition_to] and its use should be
## prefered when directly calling these methods from [SMCStateMachine] nodes.
func transition_group_to(
	group_name: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant] = {}
) -> void:
	var group: SMCStateGroup = get_state_group(group_name)
	assert(
		group, 
		"Failed to transition group %s to %s. Missing group." %
		[group_name, state_name]
	)
	group.transition_to(state_name, args)


## Returns the state group named [param group_name] or [code]null[/code]
## if it was not found.
func get_state_group(group_name: StringName) -> SMCStateGroup:
	return _groups.get(group_name)


## Returns all state groups registered to this state machine. This includes the 
## internal state group which will have the name 
## [constant INTERNAL_STATE_GROUP_NAME].
func get_state_groups() -> Array[SMCStateGroup]:
	return _groups.values()


##########################
## Internal State Group ##
##########################


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


#endregion
#region Private Methods --------------------------------------------------------


func _add_state_group(group: SMCStateGroup) -> void:
	assert(
		not _groups.has(group.name),
		"Failed to add state group. Duplicate group %s" % group.name
	)
	_groups[group.name] = group
	group.state_changed.connect(state_changed.emit.bind(group))
	group.transition_requested.connect(transition_group_to)
	group._component_manager = _component_manager


func _load_state_groups_from_children() -> void:
	for node in get_children():
		if node is SMCStateGroup:
			_add_state_group(node)
	for group: SMCStateGroup in _groups.values():
		group._initialize()


func _find_component_manager() -> SMCComponentManager:
	return SMCComponentManager.from_node(get_parent())


func _set_initial_state(state_name: StringName) -> void:
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
