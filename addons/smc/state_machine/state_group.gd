@tool
@icon("../icons/icon_state_group.png")
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

## Emitted when a state is added to the group.
signal state_added(state: SMCState)
## Emitted when a state is removed from the group.
signal state_removed(state: SMCState)
## Emitted when the current state is changed. See [method transition_to].
signal current_state_changed(old: SMCState, new: SMCState)
## Emitted when a state requested a transition in another state group.
signal requested_transition(
	group_name: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant],
)

#endregion
#region Exports ----------------------------------------------------------------

## The initial state the group should start with.
@export var initial_state: StringName:
	set = set_initial_state
## The arguments of the initial state. Used only when [member initial_state]
## is not empty.
@export var initial_args: Dictionary[StringName, Variant]
## Wether to add states that are children of this group when ready.
## See [method add_state].
@export var reload_states_on_start: bool = true

#endregion
#region Public Variables -------------------------------------------------------

## The component manager used by this state group to resolve its states' component dependencies.
## [br][br]
## [b]Note[/b]: This is [b]automatically set[/b] by the state machine managing this group.
var component_manager: SMCComponentManager:
	set = set_component_manager

#endregion
#region Private Variables ------------------------------------------------------

var _states: Dictionary[StringName, SMCState]
var _current_state: SMCState

#endregion
#region Public Methods ---------------------------------------------------------

## Initializes the group. Includes reloading states from children and 
## transitioning to the initial state.
## [br][br]
## [b]Note[/b]: This method is [b]called automatically[/b] by the state machine
## that manages this group.
func initialize() -> void:
	if reload_states_on_start:
		reload_states_from_children()
	if not initial_state.is_empty():
		transition_to(initial_state, initial_args)

## Changes the current state of the group to the one named [param state_name]. 
## Only states present in this group are supported unlike
## [method SMCState.transition_to].
func transition_to(state_name: StringName, args: Dictionary[StringName, Variant] = {}) -> void:
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
	current_state_changed.emit(previous_state, _current_state)


## Adds a state to the group. Does nothing if a state with the same name is 
## already present in it.
func add_state(state: SMCState) -> void:
	if _states.has(state.name):
		return
	_states[state.name] = state
	state.requested_transition.connect(_on_state_transition_requested)
	if component_manager:
		component_manager.resolve_dependencies(state)
	state.initialize()
	state_added.emit(state)


## Removes a state from the group. Returns [code]true[/code] if the
## state was successfully removed. [code]false[/code] otherwise. 
func remove_state(state: SMCState) -> bool:
	if not _states.has(state.name):
		return false
	_states.erase(state.name)
	state.requested_transition.disconnect(_on_state_transition_requested)
	state_removed.emit(state)
	return true


## Returns the state named [param state_name] present in the group or
## [code]null[/code] if not found.
func get_state(state_name: StringName) -> SMCState:
	return _states.get(state_name)


## Returns an array containing all states managed by this group.
func get_states() -> Array[SMCState]:
	return _states.values()


## Returns the current active state or [code]null[/code] if there isn't any.
func get_current_state() -> SMCState:
	return _current_state


## Removes all states from the group. If [param free_states] is 
## [code]true[/code], calls [method Node.queue_free] on each state.
func clear_states(free_states: bool = false) -> void:
	var states: Array[SMCState] = _states.values().duplicate()
	_states.clear()
	for state in states:
		state.requested_transition.disconnect(_on_state_transition_requested)
		state_removed.emit(state)
		if free_states:
			state.queue_free()


## Clears all states, then add all states that are child of this group.
func reload_states_from_children() -> void:
	clear_states()
	for node in get_children():
		if node is SMCState:
			add_state(node)

#endregion
#region Private Methods --------------------------------------------------------

func _ready() -> void:
	child_entered_tree.connect(notify_property_list_changed)
	child_exiting_tree.connect(notify_property_list_changed)


func _validate_property(property: Dictionary) -> void:
	if property.name == "initial_state":
		var names: Array[StringName] = []
		for node in get_children():
			if node is SMCState:
				names.append(node.name)
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(names)


func _on_state_transition_requested(
	group_name: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant]
) -> void:
	if group_name.is_empty() or group_name == name:
		transition_to(state_name, args)
	else:
		requested_transition.emit(group_name, state_name, args)

#endregion
#region Setters & Getters ------------------------------------------------------

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


func set_component_manager(manager: SMCComponentManager) -> void:
	component_manager = manager
	if component_manager:
		for state: SMCState in _states.values():
			manager.resolve_dependencies(state)

#endregion
