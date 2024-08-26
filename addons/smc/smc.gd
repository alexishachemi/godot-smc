@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"ComponentManager",
		"Node",
		preload("res://addons/smc/component_manager/component_manager.gd"),
		preload("res://addons/smc/icons/icon_component_manager.png")
	)
	add_custom_type(
		"StateGroup",
		"Node",
		preload("res://addons/smc/state_machine/state_group.gd"),
		preload("res://addons/smc/icons/icon_state_group.png")
	)
	add_custom_type(
		"StateMachine",
		"Node",
		preload("res://addons/smc/state_machine/state_machine.gd"),
		preload("res://addons/smc/icons/icon_state_machine.png")
	)

func _exit_tree():
	remove_custom_type("ComponentManager")
	remove_custom_type("StateGroup")
	remove_custom_type("StateMachine")
