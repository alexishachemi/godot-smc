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

#region Signals ----------------------------------------------------------------

## Emitted when an operation that affect the other SMC nodes depending on this
## one is made.[br][br]
## For example, moving or deleting the manager would break the dependency chain.
## This signal is then emitted, and SMC managers relying on it will update and 
## recompute accordingly. [br][br]
## Since emitting this signal can cause a lot of nodes to recompute, it is
## recommended to change services at runtime sparingly.[br][br]
## [b]Note[/b]: Said updates are made in the next frame.
signal modified

#endregion
#region Private Variables ------------------------------------------------------

var _parent: SMCServiceManager
var _services: Dictionary[StringName, SMCService]

#endregion
#region Static Methods ---------------------------------------------------------


## Finds a [SMCServiceManager] from [param node]'s children. Returns it if
## found. Otherwise, returns [code]null[/code].
## [br][br]
## [b]Note[/b]: Only searches within [param node] direct children.
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
	replacing_by.connect(modified.emit)
	tree_exited.connect(modified.emit)
	_update_parent()
	_load_services_from_children()


func _ready() -> void:
	_resolve_all_dependencies()


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
## [param query] must be one of:[br][br]
## - [String] (and [StringName]): The name of the service's [code]class_name[/code].
## [codeblock]
## manager.get_service("AudioService")
## [/codeblock][br]
## - [Script]: The class of the service.
## [codeblock]
## manager.get_service(AudioService)
## [/codeblock][br][br]
## If the manager does not have the required service, it will instead query the
## nearest manager upwards in the node tree for it, which will itself do the same
## if it does not have it.[br][br]
## [b]Note[/b]: It is only possible to query services that have a custom 
## [code]class_name[/code]. Services extending [SMCService] without having
## a custom [code]class_name[/code] will raise an error.
## [codeblock]
## manager.get_service(SMCService) # Error
## [/codeblock]
func get_service(query: Variant) -> SMCService:
	var key: StringName = _resolve_query(query)
	assert(not key.is_empty(), "Failed to get service. Invalid query %s." % query)
	return _get_service(key)


## Returns all attached services.
func get_all_services() -> Array[SMCService]:
	var services: Array[SMCService]
	services.assign(_services.values())
	return services


## Attaches [param service] to this manager.
## [br][br]
## Causes an error if a service of this type is already attached to the manager.
## [br][br]
## [param service] must be a valid sub-class of [SMCService], anything else will
## cause an error.
## [br][br]
## [b]See also[/b]: [method replace_service]
func attach_service(service: SMCService) -> void:
	_attach_service(service, false)
	_resolve_all_dependencies()
	modified.emit()


## Attaches multiple services to this manager.
## [br][br]
## Causes an error if the type of any service in the array is already present in
## the manager.
## [br][br]
## Each service must be a valid sub-class of [SMCService], anything else will
## cause an error.
func attach_services(services: Array[SMCService]) -> void:
	for service in services:
		_attach_service(service, false)
	_resolve_all_dependencies()
	modified.emit()


## Detaches a service from this manager.
## [br][br]
## [param query] must be one of:[br][br]
## - [String] (and [StringName]): The name of the service's [code]class_name[/code].
## [codeblock]
## manager.detach_service("AudioService")
## [/codeblock][br]
## - [Script]: The class of the service.
## [codeblock]
## manager.detach_service(AudioService)
## [/codeblock][br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## service that was needed somewhere in the chain will cause an error.
func detach_service(query: Variant) -> void:
	_detach_service(query)
	_resolve_all_dependencies()
	modified.emit()


## Detaches multiple services from this manager.
## [br][br]
## Each member of [param queries] must be one of:[br][br]
## - [String] (and [StringName]): The name of the service's [code]class_name[/code].
## [codeblock]
## manager.detaches_services(["AudioService", "ScoreService"])
## [/codeblock][br]
## - [Script]: The class of the service.
## [codeblock]
## manager.detaches_services([AudioService, ScoreService)]
## [/codeblock][br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## service that was needed somewhere in the chain will cause an error.
func detach_services(queries: Array[Variant]) -> void:
	for query: Variant in queries:
		_detach_service(query)
	_resolve_all_dependencies()
	modified.emit()


## Detaches all services from this manager.
## [br][br]
## [b]Note[/b]: This operation will refresh dependencies, meaning that removing a
## service that was needed somewhere in the chain will cause an error.
func detach_all_services() -> void:
	for query in _services:
		_detach_service(query)
	modified.emit()


## Attaches [param service] to this manager.
## [br][br]
## If a service of its type is already attached, it is instead replaced by
## [param service].
## [br][br]
## [param service] must be a valid sub-class of [SMCService], anything else will
## cause an error.
func replace_service(service: SMCService) -> void:
	_attach_service(service, true)
	_resolve_all_dependencies()
	modified.emit()


## Attaches multiple services to this manager.
## [br][br]
## If any service has its type already attached, the already attached service
## is replaced.
## [br][br]
## Each service must be a valid sub-class of [SMCService], anything else will
## cause an error.
func replace_services(services: Array[SMCService]) -> void:
	for service in services:
		_attach_service(service, true)
	_resolve_all_dependencies()
	modified.emit()


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
		var service: SMCService = _get_service(property.class_name)
		assert(
			service,
			"Failed to resolve dependency of %s. Missing service %s" %
			[node, property.class_name]
		)
		node.set(property.name, service)


#endregion
#region Private Methods --------------------------------------------------------


func _get_service(key: StringName) -> SMCService:
	if _services.has(key):
		return _services[key]
	if _parent:
		return _parent._get_service(key)
	return null


func _attach_service(service: SMCService, replace: bool) -> void:
	assert(is_instance_valid(service), "Failed to attach service. Invalid instance.")
	assert(service.get_script(), "Failed to attach service. Missing script.")
	var key: StringName = service.get_script().get_global_name()
	assert(not key.is_empty(), "Failed to attach service. Missing global name.")
	assert(key != "SMCService", "Failed to attach service. Invalid global name.")
	if replace and _services.has(key):
		_detach_service(key)
	elif not replace:
		assert(not _services.has(key), "Failed to attach service. Duplicate service %s." % key)
	_services[key] = service


func _detach_service(query: Variant) -> void:
	var key: StringName = _resolve_query(query)
	assert(not key.is_empty(), "Failed to detach service. Invalid query %s." % query)
	_services.erase(key)


func _resolve_query(query: Variant) -> StringName:
	var key: StringName = ""
	if query is Script:
		key = query.get_global_name()
	elif query is String or query is StringName:
		key = query
	return key


func _load_services_from_children() -> void:
	for service in get_children():
		if service is SMCService:
			_attach_service(service, false)


func _resolve_all_dependencies() -> void:
	for service: SMCService in _services.values():
		if SMCService.has_dependency(service):
			resolve_dependencies(service)


func _update_parent() -> void:
	var node: Node = get_parent()
	if node:
		node = node.get_parent()
	if node:
		_parent = find_nearest(node)
	if _parent:
		_parent.modified.connect(
			_on_parent_modified,
			CONNECT_ONE_SHOT | CONNECT_DEFERRED
		)


func _on_parent_modified() -> void:
	_update_parent()
	_resolve_all_dependencies()
	modified.emit()


#endregion
