class_name StateLabel
extends Label

## A custom label that displays states
##
## State Labels automatically display the current state of a state machine/group.
## If no state group is attached to it, it will look for a state machine among its
## sibbling and use its internal state group if found.

@export var prefix: String = ""
@export var state_group: StateGroup = null

func _ready():
	if state_group == null:
		for child in get_parent().get_children():
			if child is StateMachine:
				state_group = child.internal_group
				_set_state(child.initial_state)
				break
	if state_group == null:
		text = "[no group/machine]"
	else:
		state_group.state_changed.connect(_on_state_changed)

func _set_state(state_name: StringName):
	if prefix != "":
		text = "%s: %s" % [prefix, state_name]
	else:
		text = state_name

func _on_state_changed(state_name: StringName):
	_set_state(state_name)
