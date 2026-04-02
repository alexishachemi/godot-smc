@icon("../icons/icon_state_label.png")
class_name SMCStateLabel
extends Label

## A custom label that displays states
##
## State Labels automatically display the current state of a state machine/group.
## If no state group is attached to it, it will look for a state machine among its
## sibbling and use its internal state group if found.

@export var prefix: String = ""
@export var state_group: SMCStateGroup = null

func _ready() -> void:
	if state_group == null:
		for child in get_parent().get_children():
			if child is SMCStateMachine:
				state_group = child._internal_group
				_set_state(child.initial_state)
				break
	if state_group == null:
		text = "[no group/machine]"
	else:
		state_group.current_state_changed.connect(_on_state_changed)

func _set_state(state_name: StringName) -> void:
	if prefix != "":
		text = "%s: %s" % [prefix, state_name]
	else:
		text = state_name

func _on_state_changed(_old: SMCState, new: SMCState) -> void:
	_set_state(new.name)
