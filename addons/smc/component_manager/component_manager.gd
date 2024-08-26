@icon("res://addons/smc/icons/icon_component_manager.png")
class_name ComponentManager
extends Node
## The node responsible for managing all components in a scene
##
## Manages dependencies and getting components from outside sources.

var components: Array[Component]

func _ready():
	reload_components()

func get_component(comp_name: StringName) -> Component:
	for comp in components:
		if comp.name == comp_name:
			return comp
	return null

## https://stackoverflow.com/questions/76313724/check-if-an-object-is-of-a-class-given-the-class-name-in-string
static func is_instance_of_string(obj: Object, given_class_name: String) -> bool:
	if ClassDB.class_exists(given_class_name):
		return obj.is_class(given_class_name)
	else:
		var class_script : Script
		if ResourceLoader.exists(given_class_name):
			class_script = load(given_class_name) as Script
		if class_script == null:
			for x in ProjectSettings.get_global_class_list():
				if str(x["class"]) == given_class_name:
					class_script = load(str(x["path"]))
					break
		if class_script == null:
			return false
		var check_script : Script = obj.get_script()
		while check_script != null:
			if check_script == class_script:
				return true
			check_script = check_script.get_base_script()
		return false

func get_component_by_class(comp_class_name: StringName) -> Component:
	for comp in components:
		if is_instance_of_string(comp, comp_class_name):
			return comp
	return null

func _load_dependencies(comp: Component):
	var dep_dict = comp.get_dependencies()
	var dep_comp: Component
	for dep_name in dep_dict:
		dep_comp = get_component_by_class(dep_name)
		if not dep_comp:
			push_warning("component manager could not find dependency [%s] of component [%s]" \
				% [dep_name, comp.name])
		comp.set(dep_dict[dep_name], dep_comp)

func reload_components():
	components = []
	for node in get_children():
		if node is Component:
			components.append(node)
	for comp in components:
		_load_dependencies(comp)
