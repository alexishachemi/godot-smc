@icon("../icons/service_manager.png")
class_name SMCServiceManager
extends Node

## Store and manages services [SMCService] nodes.
##
## A SMCServiceManager defines the service scope of its parent node.
## Parent managers are resolved from ancestor scope nodes. [br][br]
##
## Service managers may be iterated like other containers:
## [codeblock]
## for service in service_manager:
## 	print(service)
## [/codeblock] 

#region Private Variables ------------------------------------------------------

var _parent: SMCServiceManager
var _services: Dictionary[StringName, SMCService]

#endregion
#region Static Methods ---------------------------------------------------------

## Finds a [SMCServiceManager] from [param node]'s children. Returns it if
## found. Otherwise, returns [code]null[/code].
## [br][br]
## Note: Only searches within [param node] direct children.
## See also [method find_nearest].
static func from_node(node: Node) -> SMCServiceManager:
	if not is_instance_valid(node):
		return null
	for child in node.get_children():
		if child is SMCServiceManager:
			return child
	return null


## Finds a [SMCServiceManager] from [param node]'s children. Returns it if
## found. Otherwise, walks up the parents of [param node] and search for the 
## nearest one until it is found or there are no more parents to search.
## In that case, returns [code]null[/code].
static func find_nearest(node: Node) -> SMCServiceManager:
	if not is_instance_valid(node):
		return null
	var manager: SMCServiceManager = null
	while node and not manager:
		manager = from_node(node)
		node = node.get_parent()
	return manager

#endregion
#region Built-in Methods -------------------------------------------------------

func _enter_tree() -> void:
	_parent = _find_parent()
	_load_services_from_children()


func _ready() -> void:
	_resolve_dependencies()


func _iter_init(iter: Array) -> bool:
	if _services.is_empty():
		return false
	iter[0] = _services.values()
	return true


func _iter_next(iter: Array) -> bool:
	iter[0].pop_front()
	return not iter[0].is_empty()


func _iter_get(iter: Variant) -> Variant:
	return iter.front()

#endregion
#region Public Methods ---------------------------------------------------------

## Query a service from the manager using the given [param query].[br][br]
## [param query] supports multiple types:[br]
## - [String] (and [StringName]): The name of the service's [code]class_name[/code].
## [codeblock]
## manager.get_service("ItemFactoryService") # Valid
## [/codeblock][br]
## - [Script]: The class of the service.
## [codeblock]
## manager.get_service(ItemFactoryService) # Valid
## [/codeblock][br][br]
## If the manager does not have the required service, it will instead query the
## nearest manager upwards in the node tree for it, which will itself do the same
## if it does not have it.
## [b]Note[/b]: It is only possible to query services that have a custom 
## [code]class_name[/code]. Services extending [SMCService] without having
## a custom [code]class_name[/code] will raise an error.
## [codeblock]
## manager.get_service(SMCService) # Error
## [/codeblock]
func get_service(query: Variant) -> SMCService:
	var key: StringName = ""
	if query is Script:
		key = query.get_global_name()
	elif query is String or query is StringName:
		key = query
	else:
		assert(false, "Invalid query type. Expected class (Script) or string. Got %s" % query)
	assert(
		not key.is_empty() and key != "SMCService",
		"Invalid query. Expected a subclass of SMCService with class_name or the name of such class."
	)
	return _get_service(key)


## Resolve the dependencies of a node by checking properties with the 
## [constant SMCService.PROPERTY_HINT_SERVICE] hint and setting the 
## appropriate properties to services that it, or its parent manager, manages.
## If a service needed to resolve a dependency is not present in the manager 
## chain, raises an error.[br][br]
## See [constant SMCService.PROPERTY_HINT_SERVICE]
## on how to declare a service dependency.
func resolve_dependencies(node: Node) -> void:
	for property in node.get_property_list():
		if property.hint != SMCService.PROPERTY_HINT_SERVICE:
			continue
		var service: SMCService = get_service(property.class_name)
		assert(
			service,
			"Failed to resolve dependency of %s. Missing service %s" %
			[node, property.class_name]
		)
		node.set(property.name, service)

#endregion
#region Private Methods --------------------------------------------------------


func _get_service(service_name: StringName) -> SMCService:
	if _services.has(service_name):
		return _services[service_name]
	if _parent:
		return _parent._get_service(service_name)
	return null


func _add_service(service: SMCService) -> void:
	assert(service, "Failed to add service. Got null value.")
	var script: Script = service.get_script()
	assert(script, "Failed to add service. Missing script.")
	var key: StringName = script.get_global_name()
	assert(
		not key.is_empty() and key != "SMCService",
		"Failed to add service. Expected a named subclass of SMCService."
	)
	assert(
		not _services.has(key),
		"Failed to add service. Duplicate service %s" % key
	)
	_services[key] = service


func _load_services_from_children() -> void:
	for service in get_children():
		if service is SMCService:
			_add_service(service)


func _resolve_dependencies() -> void:
	for service: SMCService in _services.values():
		resolve_dependencies(service)


func _find_parent() -> SMCServiceManager:
	var node: Node = get_parent()
	if node:
		node = node.get_parent()
	if node:
		return find_nearest(node)
	return null


#endregion
