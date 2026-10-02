@tool
@icon("../icons/state_group.png")
class_name SMCStateGroup
extends Node

## A group of states managed by a [SMCStateMachine]
##
## State groups allow for basic behavioural separation within the state machine.
## In each group, only one state can be active at a time. This allows for
## multiple states to be active at one time as long as they are in different groups.
## any state from any group can request a transition to any state from any other groups.
## If the requested state is from a different group then the state making the request
## won't be changed and the requested state will be activated in its respective group. 

#region Signals ----------------------------------------------------------------

## Emitted when the current state is changed. See [method transition_to].
signal state_changed(old: SMCState, new: SMCState)

## Emitted when a state requested a transition in another state group.
signal transition_requested(
	group_name: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant],
)

#endregion
#region Exports ----------------------------------------------------------------

## The initial state the group should start with.
@export var initial_state: StringName:
	set = _set_initial_state

## The arguments of the initial state. Used only when [member initial_state]
## is not empty.
@export var initial_args: Dictionary[StringName, Variant]

#endregion
#region Private Variables ------------------------------------------------------

var _states: Dictionary[StringName, SMCState]
var _current_state: SMCState
var _component_manager: SMCComponentManager
var _service_manager: SMCServiceManager
var _transition_queue: Array[Array]
var _transitioning: bool = false

#endregion
#region Built-in Methods -------------------------------------------------------


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		child_entered_tree.connect(notify_property_list_changed)
		child_exiting_tree.connect(notify_property_list_changed)
		return


func _validate_property(property: Dictionary) -> void:
	if property.name == "initial_state":
		var names: Array[StringName] = []
		for node in get_children():
			if node is SMCState:
				names.append(node.name)
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(names)


#endregion
#region Public Methods ---------------------------------------------------------


## Changes the current state of the group to the one named [param state_name]. 
## Only states present in this group are supported unlike
## [method SMCState.transition_to].
func transition_to(state_name: StringName, args: Dictionary[StringName, Variant] = {}) -> void:
	_transition_queue.append([state_name, args])
	if _transitioning:
		return
	_transitioning = true
	while not _transition_queue.is_empty():
		_transition.callv(_transition_queue.pop_front())
	_transitioning = false


## Returns the state named [param state_name] present in the group or
## [code]null[/code] if not found.
func get_state(state_name: StringName) -> SMCState:
	return _states.get(state_name)


## Returns an array containing all states managed by this group.
func get_all_states() -> Array[SMCState]:
	var states: Array[SMCState]
	states.assign(_states.values())
	return states


## Returns the current active state or [code]null[/code] if there isn't any.
func get_current_state() -> SMCState:
	return _current_state


## Attaches [param state] to this group.
## [br][br]
## Causes an error if a state with the same name is already attached to the state group.
## [br][br]
## [b]See also[/b]: [method replace_state]
func attach_state(state: SMCState) -> void:
	_attach_state(state, false)


## Attaches multiple states to this group.
## [br][br]
## Causes an error if the name of a state is the same as one already attached.
func attach_states(states: Array[SMCState]) -> void:
	for state in states:
		_attach_state(state, false)


## Detaches the state named [param state_name] from this group.
## [br][br]
## If no state with this name is attached to the group, does nothing.
func detach_state(state_name: StringName) -> void:
	_detach_state(state_name)


## Detaches multiple states from this group.
## [br][br]
## Names not matching attached states are ignored.
func detach_states(state_names: Array[StringName]) -> void:
	for state_name in state_names:
		_detach_state(state_name)


## Detaches all groups from this machine.
func detach_all_states() -> void:
	for state_name in _states:
		_detach_state(state_name)


## Attaches [param state] to this group.
## [br][br]
## If a state of its type is already attached, it is instead replaced by
## [param state].
func replace_state(state: SMCState) -> void:
	_attach_state(state, true)


## Attaches multiple states to this group.
## [br][br]
## If any states has its type already attached, the already attached states
## is replaced.
func replace_states(states: Array[SMCState]) -> void:
	for state in states:
		_attach_state(state, false)


#endregion
#region Private Methods --------------------------------------------------------


func _initialize() -> void:
	_load_states_from_children()
	for state: SMCState in _states.values():
		state.initialize()
	if not initial_state.is_empty():
		transition_to(initial_state, initial_args)


func _attach_state(state: SMCState, replace: bool) -> void:
	assert(is_instance_valid(state), "Failed to attach state. Invalid instance.")
	if replace and _states.has(state.name):
		_detach_state(state.name)
	elif not replace:
		assert(not _states.has(state.name), "Failed to attach state. Duplicate state %s." % state.name)
	_states[state.name] = state
	state.transition_requested.connect(_on_state_transition_requested)
	_resolve_dependencies(state, true, true)


func _detach_state(state_name: StringName) -> void:
	var state: SMCState = _states.get(state_name)
	if not state:
		return
	_states.erase(state_name)
	state.transition_requested.disconnect(transition_requested.emit)


func _resolve_all_dependencies(
	resolve_components: bool,
	resolve_services: bool
) -> void:
	for state: SMCState in _states.values():
		_resolve_dependencies(state, resolve_components, resolve_services)


func _resolve_dependencies(
	state: SMCState,
	resolve_components: bool,
	resolve_services: bool
) -> void:
	if resolve_components and SMCComponent.has_dependency(state):
		assert(_component_manager, "Cannot resolve component dependency. Missing component manager.")
		_component_manager.resolve_dependencies(state)
	if resolve_services and SMCService.has_dependency(state):
		assert(_service_manager, "Cannot resolve service dependency. Missing service manager.")
		_service_manager.resolve_dependencies(state)


func _load_states_from_children() -> void:
	for node in get_children():
		if node is SMCState:
			_attach_state(node, false)


func _on_state_transition_requested(
	group_name: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant]
) -> void:
	if group_name.is_empty() or group_name == name:
		transition_to(state_name, args)
	else:
		transition_requested.emit(group_name, state_name, args)


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


func _transition(state_name: StringName, args: Dictionary[StringName, Variant]) -> void:
	var state: SMCState = _states.get(state_name)
	assert(state, "Group %s failed to transition to %s. State not found." % [name, state_name])
	var previous_state: SMCState = _current_state
	if _current_state:
		_current_state.exit(state_name, args)
	_current_state = state
	var previous_state_name: StringName = ""
	if previous_state:
		previous_state_name = previous_state.name
	_current_state.enter(previous_state_name, args)
	state_changed.emit(previous_state, _current_state)


#endregion
