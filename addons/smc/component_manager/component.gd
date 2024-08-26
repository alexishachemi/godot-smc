@icon("res://addons/smc/icons/icon_component.png")
class_name Component
extends Node
## A component that holds data and functionality for a singular feature.
##
## This is the base class of all components, all new component should inherit from it
## to ensure they are correctly managed by the component manager.

## when a component needs another to function, this function must
## be overloaded and return a dictionary whose keys are the class 
## names of the components needed and the values are the name of the
## property to store the component.
func get_dependencies() -> Dictionary:
	return {}
