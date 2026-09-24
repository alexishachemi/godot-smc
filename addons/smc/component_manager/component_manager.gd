@icon("../icons/component_manager.png")
class_name SMCComponentManager
extends Node

## Store and manages components [SMCComponent] nodes.
##
## Component manager may be iterated like other containers:
## [codeblock]
## for component in component_manager:
## 	...
## [/codeblock]

#region Private Variables ------------------------------------------------------

var _components: Dictionary[StringName, SMCComponent]
var _service_manager: SMCServiceManager


# Flags if we have already looked for a service manager.
# This is so we search for it only the first time a component actually requires
# it. If no component requires it, we never look for the nearest service 
# manager since we do not need it.
var _service_manager_searched: bool = false

#endregion
#region Static Methods ---------------------------------------------------------

## Finds a [SMCComponentManager] from [param node]'s children. Returns it if
## found. Otherwise, returns [code]null[/code].
static func from_node(node: Node) -> SMCComponentManager:
	if not is_instance_valid(node):
		return null
	for child in node.get_children():
		if child is SMCComponentManager:
			return child
	return null

#endregion
#region Built-in Methods -------------------------------------------------------

func _enter_tree() -> void:
	_load_components_from_children()


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

#endregion
#region Public Methods ---------------------------------------------------------

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


## Resolve the component and service dependencies of a node by checking
## properties with the [constant SMCComponent.PROPERTY_HINT_COMPONENT] and 
## [constant SMCService.PROPERTY_HINT_SERVICE] hints and setting the 
## appropriate properties that it manages. If a component or service needed 
## to resolve a dependency is not present in the manager, raises an error.[br][br]
func resolve_dependencies(node: Node) -> void:
	for property in node.get_property_list():
		match property.hint:
			SMCComponent.PROPERTY_HINT_COMPONENT:
				var component: SMCComponent = get_component(property.class_name)
				assert(
					component,
					"Failed to resolve dependency of %s. Missing component %s" %
					[node, property.class_name]
				)
				node.set(property.name, component)
			SMCService.PROPERTY_HINT_SERVICE:
				var service_manager: SMCServiceManager = _get_service_manager()
				assert(
					service_manager,
					"Failed to resolve dependency of %s. Missing service manager" %
					node
				)
				var service: SMCService = _service_manager.get_service(property.class_name)
				assert(
					service,
					"Failed to resolve dependency of %s. Missing service %s" %
					[node, property.class_name]
				)
				node.set(property.name, service)


#endregion
#region Private Methods --------------------------------------------------------


func _add_component(component: SMCComponent) -> void:
	assert(component, "Failed to add component. Got null value.")
	var script: Script = component.get_script()
	assert(script, "Failed to add component. Missing script.")
	var key: StringName = script.get_global_name()
	assert(
		not key.is_empty() and key != "SMCComponent",
		"Failed to add component. Expected a named subclass of SMCComponent."
	)
	assert(
		not _components.has(key),
		"Failed to add component. Duplicate component %s" % key
	)
	_components[key] = component


func _load_components_from_children() -> void:
	for component in get_children():
		if component is SMCComponent:
			_add_component(component)
	for component: SMCComponent in _components.values():
		resolve_dependencies(component)


func _get_service_manager() -> SMCServiceManager:
	if not _service_manager_searched:
		_service_manager = SMCServiceManager.find_nearest(get_parent())
		_service_manager_searched = true
	return _service_manager


#endregion
