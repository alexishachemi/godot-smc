@icon("res://addons/smc/icons/icon_component_manager.png")
class_name SMCComponentManager
extends Node

## Store and manages components [SMCComponent] nodes.
##
## Component manager may be iterated like other containers:
## [codeblock]
## for component in component_manager:
## 	...
## [/codeblock]

## Emitted when a component is added
signal component_added(component: SMCComponent)
## Emitted when a component is removed
signal component_removed(component: SMCComponent)

## Wether to call [method reload_components_from_children] when the manager 
## enters the scene tree.
@export var reload_components_on_start: bool = true

var _components: Dictionary[StringName, SMCComponent]


## Query a component from the manager using the given [param query].[br]
## [param query] supports multiple types:[br]
## - [String] (and [StringName]): The name of the component's [code]class_name[/code].
## [codeblock]
## manager.get_component("HealthComponent") # Valid
## [/codeblock][br]
## - [Script]: The class of the component.
## [codeblock]
## manager.get_component(HealthComponent) # Valid
## [/codeblock][br]
## [b]Note[/b]: It is only possible to query components that have a custom 
## [code]class_name[/code]. Components extending [SMCComponent] without having
## a custom [code]class_name[/code] will raise an error.
## [codeblock]
## manager.get_component(SMCComponent) # Error
## [/codeblock]
func get_component(query: Variant) -> SMCComponent:
	var key: StringName = ""
	if query is Script:
		key = query.get_global_name()
	elif query is String or query is StringName:
		key = query
	else:
		assert(false, "Invalid query type. Expected class (Script) or string. Got %s" % query)
	assert(
		not key.is_empty() and key != "SMCComponent",
		"Invalid query. Expected a subclass of SMCComponent with class_name or the name of such class."
	)
	return _components.get(key)


## Adds [param component] to the manager. if [param resolve_dependencies] is 
## [code]true[/code] (default), the manager will resolve its dependecies using
## [method resolve_component_dependencies].
## [br][br]
## [b]Note[/b]: Changing the component registry at runtime will not update the
## resolved dependencies of other components. You may need to use the
## [signal component_added] signal along with 
## [method resolve_component_dependencies] if you need to be able to change 
## component dependecies at runtime.
func add_component(component: SMCComponent, resolve_component_dependencies: bool = true) -> bool:
	assert(component, "Failed to add component. Got null value.")
	var script: Script = component.get_script()
	assert(component, "Failed to add component. Missing script.")
	var key: StringName = script.get_global_name()
	assert(
		not key.is_empty() and key != "SMCComponent",
		"Failed to add component. Expected a subclass of SMCComponent."
	)
	if _components.has(key):
		return false
	_components[key] = component
	if resolve_component_dependencies:
		resolve_dependencies(component)
	component_added.emit(component)
	return true


## Removes a component from the manager. The component won't be queryable and
## won't be used for dependency management.
## [br][br]
## [param query] supports multiple types:[br]
## - [String] (and [StringName]): The name of the component's [code]class_name[/code].
## [codeblock]
## manager.remove_component("HealthComponent") # Valid
## [/codeblock][br]
## - [Script]: The class of the component.
## [codeblock]
## manager.remove_component(HealthComponent) # Valid
## [/codeblock][br]
## - Reference to a component.
## [codeblock]
## var my_component: HealthComponent = manager.get_component(HealthComponent)
## manager.remove_component(my_component) # Valid
## [/codeblock][br]
## [b]Note[/b]: It is only possible to remove components that have a custom 
## [code]class_name[/code]. Components extending [SMCComponent] without having
## a custom [code]class_name[/code] will raise an error.
## [codeblock]
## manager.remove_component(SMCComponent) # Error
## [/codeblock]
## [br][br]
## [b]Note[/b]: Changing the component registry at runtime will not update the
## resolved dependencies of other components. You may need to use the
## [signal component_removed] signal along with 
## [method resolve_component_dependencies] if you need to be able to change 
## component dependecies at runtime.
func remove_component(query: Variant) -> bool:
	var key: StringName
	if query is String or query is StringName:
		key = query
	elif query is Script:
		key = query.get_global_name()
	elif query is SMCComponent:
		var script: Script = query.get_script()
		assert(script, "Failed to remove component. Missing script.")
		key = script.get_global_name()
	else:
		assert(
			false, 
			"Invalid query type. Expected SMCComponent , Class (Script) or string. Got %s" % query
		)
	assert(
		not key.is_empty() and key != "SMCComponent",
		"Failed to remove component. Expected a subclass of SMCComponent."
	)
	var component: SMCComponent = _components.get(key)
	if component:
		_components.erase(key)
		component_removed.emit(component)
		return true
	return false


## Clear all components from the manager and if [code]free_components[/code]
## is [code]true[/code], calls [Node.queue_free] on them.[br]
## If not freed, components that are still children of the manager can
## be re-added using [method reload_components_from_children]
func clear_components(free_components: bool = false) -> void:
	if _components.is_empty():
		return
	var removed: Array[SMCComponent]
	removed.assign(_components.values().duplicate())
	_components.clear()
	for component in removed:
		component_removed.emit(component)
		if free_components:
			component.queue_free()


## Clears all components from the manager then add them from its children.
## See also [method add_component].
func reload_components_from_children(resolve_components_dependencies: bool = true) -> void:
	clear_components()
	for component in get_children():
		if component is SMCComponent:
			var result: bool = add_component(component, false)
			assert(result, "Failed to add component. duplicate component %s" % component)
	if resolve_components_dependencies:
		for component: SMCComponent in _components.values():
			resolve_dependencies(component)


## Resolve the dependencies of a node by checking properties with the 
## [constant SMCComponent.PROPERTY_HINT_COMPONENT] hint and setting the 
## appropriate properties to components that it manages. If a component needed 
## to resolve a dependency is not present in the manager, raises an error.[br][br]
## See how to declare a component dependency below:
## [codeblock]
## @export_custom(PROPERTY_HINT_COMPONENT, "", 0) var health: HealthComponent
## [/codeblock]
func resolve_dependencies(node: Node) -> void:
	for property in node.get_property_list():
		if property.hint != SMCComponent.PROPERTY_HINT_COMPONENT:
			continue
		var component: SMCComponent = get_component(property.class_name)
		assert(
			component,
			"Failed to resolve dependency of %s. Missing component %s" %
			[node, property.class_name]
		)
		node.set(property.name, component)


func _enter_tree() -> void:
	reload_components_from_children()


func _iter_init(iter: Array) -> bool:
	if _components.is_empty():
		return false
	iter[0] = _components.values()
	return true


func _iter_next(iter: Array) -> bool:
	iter[0].pop_front()
	return not iter[0].is_empty()


func _iter_get(iter: Variant) -> Variant:
	return iter.front()
