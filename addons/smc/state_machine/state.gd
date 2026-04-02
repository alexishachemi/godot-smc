@icon("res://addons/smc/icons/icon_state.png")
class_name SMCState
extends Node

## A state managed by the state machine
##
## States allows for isolated code to run under certain conditions.
## Only specific transition from one state to another may be done.
## No state should share the same name within the same state machine

#region Signals ----------------------------------------------------------------

## Emitted when a transition is requested to the overseeing [SMCStateMachine].
## (i.e. [method transition_to] is called)
signal requested_transition(
	state_group: StringName,
	state_name: StringName,
	args: Dictionary[StringName, Variant],
)

#endregion
#region Public Method ----------------------------------------------------------

## Initializes the state. This method is called after the state is ready but
## before it is entered (if the state is meant to be activated on start).
## Adding custom behaviour at this step is useful since component dependencies
## are not available when [method Node._ready] is called while they are here.
## [br][br]
## [b]Note[/b]: This method is [b]called automatically[/b] by the group that
## owns this state. To add custom behaviour at initialization, you should 
## override the [method _initialize] method.
func initialize() -> void:
	_initialize()

## Activates the state. This effectively enables processing, physics 
## processing and input handling (i.e. [method Node._process], 
## [method Node._physics_process] and [method Node._input]) will be enabled.[br]
## This method is called automatically by the [SMCStateGroup] that owns it 
## when transitioning to this state. [br][br]
## Custom behaviour can be added by overriding the [method _enter] method:
## [codeblock]
## func _enter(previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
## 	...
## [/codeblock]
func enter(previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
	_set_enabled(true)
	_enter(previous_state, args)


## Deactivates the state. This effectively disables processing, physics 
## processing and input handling (i.e. [method Node._process], 
## [method Node._physics_process] and [method Node._input]) will be disabled and 
## won't be called. [br]
## This method is called automatically by the [SMCStateGroup] that owns it 
## when transitioning to this state.[br][br]
## Custom behaviour can be added by overriding the [method _exit] method:
## [codeblock]
## func _exit(next_state: StringName, next_state_args: Dictionary[StringName, Variant]) -> void:
## 	...
## [/codeblock]
func exit(next_state: StringName, next_state_args: Dictionary[StringName, Variant]) -> void:
	_exit(next_state, next_state_args)
	_set_enabled(false)


## Requests a transition to the [SMCStateGroup] that owns this state or the overseeing
## [SMCStateMachine]. [param path] may be the name of a sibling state:
## [codeblock]
## transition_to("Idle")
## [/codeblock][br]
## Or a state group name along with a state name separated by a [code]/[/code]:
## [codeblock]
## # Group/State
## transition_to("Upper/Aim")
## [/codeblock][br]
func transition_to(path: StringName, args: Dictionary[StringName, Variant] = {}) -> void:
	var path_split: PackedStringArray = path.strip_edges().split("/", false)
	var size: int = path_split.size()
	if size == 1:
		requested_transition.emit("", path_split[0], args)
	elif size == 2:
		requested_transition.emit(path_split[0], path_split[1], args)
	else:
		assert(false, "Failed to transition state. Invalid path")

#endregion
#region Private Method ---------------------------------------------------------

func _ready() -> void:
	_set_enabled(false)


func _set_enabled(enabled: bool) -> void:
	set_process(enabled)
	set_physics_process(enabled)
	set_process_input(enabled)

#endregion
#region Overridable ------------------------------------------------------------

## Override this method to add custom behaviour when the state is initialized 
## (i.e. when [method initialize] is called).
## This is ran after [method Node._ready] but before any state is activated. 
## Component dependencies are guaranteed to be resolved when this is called, 
## unlike [method Node._ready].
func _initialize() -> void:
	pass


## Override this method to add custom behaviour when the state is activated 
## (i.e. when [method enter] is called).
@warning_ignore("unused_parameter")
func _enter(previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
	pass


## Override this method to add custom behaviour when the state is deactivated 
## (i.e. when [method exit] is called).
@warning_ignore("unused_parameter")
func _exit(next_state: StringName, next_state_args: Dictionary[StringName, Variant]) -> void:
	pass

#endregion
