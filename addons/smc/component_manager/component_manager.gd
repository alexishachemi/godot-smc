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

#region Signals ----------------------------------------------------------------

## Emitted when an operation that affect the other SMC nodes depending on this
## one is made.[br][br]
## For example, moving or deleting the manager would break the dependency chain.
## This signal is then emitted, and SMC managers relying on it will update and 
## recompute accordingly. [br][br]
## [b]Note[/b]: Updates are made in the next frame.
signal dependency_chain_modified

#endregion
#region Private Variables ------------------------------------------------------

var _components: Dictionary[StringName, SMCComponent]
var _service_manager: SMCServiceManager

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
	replacing_by.connect(dependency_chain_modified.emit)
	tree_exited.connect(dependency_chain_modified.emit)
	_update_service_manager()
	_load_components_from_children()
	_resolve_all_dependencies()


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

## Query a component from the manager using the given [param query].[br][br]
## [param query] must be one of:[br][br]
## - [String] (and [StringName]): The name of the component's [code]class_name[/code].
## [codeblock]
## manager.get_component("HealthComponent")
## [/codeblock][br]
## - [Script]: The class of the component.
## [codeblock]
## manager.get_component(HealthComponent)
## [/codeblock][br][br]
## If the manager does not have the required component, this method returns 
## [code]null[/code] instead.[br][br]
## [b]Note[/b]: It is only possible to query components that have a custom 
## [code]class_name[/code]. Components extending [SMCComponent] without having
## a custom [code]class_name[/code] will raise an error.
## [codeblock]
## manager.get_component(SMCComponent) # Error
## [/codeblock]
func get_component(query: Variant) -> SMCComponent:
	var key: StringName = _resolve_query(query)
	assert(not key.is_empty(), "Failed to get component. Invalid query %s." % query)
	return _components.get(key)


## Returns all attached components.
func get_all_components() -> Array[SMCComponent]:
	var components: Array[SMCComponent]
	components.assign(_components.values())
	return components


## Attaches [param component] to this manager.
## [br][br]
## Causes an error if a component of this type is already attached to the manager.
## [br][br]
## [param component] must be a valid sub-class of [SMCComponent], anything else will
## cause an error.
## [br][br]
## [b]See also[/b]: [method replace_component]
func attach_component(component: SMCComponent) -> void:
	_attach_component(component, false)
	_resolve_dependencies(component, true, true)


## Attaches multiple components to this manager.
## [br][br]
## Causes an error if the type of any component in the array is already present in
## the manager.
## [br][br]
## Each component must be a valid sub-class of [SMCComponent], anything else will
## cause an error.
func attach_components(components: Array[SMCComponent]) -> void:
	for component in components:
		_attach_component(component, false)
		_resolve_dependencies(component, true, true)


## Detaches a component from this manager.
## [br][br]
## [param query] must be one of:[br][br]
## - [String] (and [StringName]): The name of the component's [code]class_name[/code].
## [codeblock]
## manager.detach_component("HealthComponent")
## [/codeblock][br]
## - [Script]: The class of the component.
## [codeblock]
## manager.detach_component(HealthComponent)
## [/codeblock][br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## component that was needed somewhere else will cause an error.
func detach_component(query: Variant) -> void:
	if _detach_component(query):
		_resolve_all_dependencies(true, false)
		dependency_chain_modified.emit()


## Detaches multiple components from this manager.
## [br][br]
## Each member of [param queries] must be one of:[br][br]
## - [String] (and [StringName]): The name of the component's [code]class_name[/code].
## [codeblock]
## manager.detaches_components(["HealthComponent", "DamageableComponent"])
## [/codeblock][br]
## - [Script]: The class of the component.
## [codeblock]
## manager.detaches_components([HealthComponent, DamageableComponent)]
## [/codeblock][br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## component that was needed somewhere else will cause an error.
func detach_components(queries: Array[Variant]) -> void:
	for query: Variant in queries:
		if _detach_component(query):
			_resolve_all_dependencies(true, false)
			dependency_chain_modified.emit()


## Detaches all components from this manager.
## [br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## component that was needed somewhere else (e.g. a SMCState) will cause an error.
func detach_all_components() -> void:
	if _components.is_empty():
		return
	for query in _components:
		_detach_component(query)
	dependency_chain_modified.emit()


## Attaches [param component] to this manager.
## [br][br]
## If a component of its type is already attached, it is instead replaced by
## [param component].
## [br][br]
## [param component] must be a valid sub-class of [SMCComponent], anything else will
## cause an error.
func replace_component(component: SMCComponent) -> void:
	if _attach_component(component, true):
		_resolve_dependencies(component, true, true)
		dependency_chain_modified.emit()


## Attaches multiple components to this manager.
## [br][br]
## If any component has its type already attached, the already attached component
## is replaced.
## [br][br]
## Each component must be a valid sub-class of [SMCComponent], anything else will
## cause an error.
func replace_components(components: Array[SMCComponent]) -> void:
	var replaced: bool = false
	for component in components:
		if _attach_component(component, true):
			replaced = true
	if replaced:
		for component in components:
			_resolve_dependencies(component, true, true)
		dependency_chain_modified.emit()


## Resolve the component and service dependencies of a node by checking
## properties with the [constant SMCComponent.PROPERTY_HINT_COMPONENT] hint and 
## setting the appropriate properties that it manages. If a component needed 
## to resolve a dependency is not present in the manager, raises an error.[br][br]
func resolve_dependencies(node: Node) -> void:
	for property in node.get_property_list():
		if property.hint != SMCComponent.PROPERTY_HINT_COMPONENT:
			continue
		var component: SMCComponent = _components.get(property.class_name)
		assert(
			component,
			"Failed to resolve dependency of %s. Missing component %s" %
			[node, property.class_name]
		)
		node.set(property.name, component)


#endregion
#region Private Methods --------------------------------------------------------


func _attach_component(component: SMCComponent, replace: bool) -> bool:
	assert(is_instance_valid(component), "Failed to attach component. Invalid instance.")
	assert(component.get_script(), "Failed to attach component. Missing script.")
	var key: StringName = component.get_script().get_global_name()
	assert(not key.is_empty(), "Failed to attach component. Missing global name.")
	assert(key != "SMCComponent", "Failed to attach component. Invalid global name.")
	var replaced: bool = false
	if replace and _components.has(key):
		_detach_component(key)
		replaced = true
	elif not replace:
		assert(not _components.has(key), "Failed to attach component. Duplicate component %s." % key)
	_components[key] = component
	return replaced


func _detach_component(query: Variant) -> bool:
	var key: StringName = _resolve_query(query)
	return _components.erase(key)


func _resolve_query(query: Variant) -> StringName:
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
	return key


func _load_components_from_children() -> void:
	for component in get_children():
		if component is SMCComponent:
			_attach_component(component, false)


func _resolve_dependencies(
	component: SMCComponent,
	resolve_components: bool = true,
	resolve_services: bool = true
) -> void:
	if resolve_components and SMCComponent.has_dependency(component):
		resolve_dependencies(component)
	if resolve_services and SMCService.has_dependency(component):
		assert(_service_manager, "Cannot resolve service dependency. Missing service manager.")
		_service_manager.resolve_dependencies(component)


func _resolve_all_dependencies(
	resolve_components: bool = true,
	resolve_services: bool = true
) -> void:
	for component: SMCComponent in _components.values():
		_resolve_dependencies(component, resolve_components, resolve_services)


func _update_service_manager() -> void:
	_service_manager = SMCServiceManager.find_nearest(get_parent())
	if _service_manager:
		_service_manager.dependency_chain_modified.connect(
			_on_service_manager_modified, 
			CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func _on_service_manager_modified() -> void:
	_update_service_manager()
	_resolve_all_dependencies(false, true)


#endregion
