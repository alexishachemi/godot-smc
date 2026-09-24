class_name SMCService
extends Node

## A scoped-context object that provides functionality to other SMC nodes in 
## a scene tree.
##
## Services are meant as an alternative to most autoloads.
## What mainly differenciate [SMCService] from [SMCComponent] is its
## context-based system to expose features to other [SMCComponent], [SMCState],
## and [SMCService] down the scene tree.[br][br]
## 
## A service has to be a direct child of a [SMCServiceManager] to work. [br][br]
##
## Cascading services allows each scene to only instantiate the required
## systems to work and can prevent situations where you have your 
## [code]LootTableRegistry[/code] running in your main menu because you set it
## as an autoload to be able to access it from deep in the scene tree.[br][br]
##
## Example:
## [codeblock]
## Game
## ├── SMCServiceManager
## │   ├── AudioService
## │   └── SaveService
## │
## └── Gameplay
##     ├── SMCServiceManager
##     │   ├── ItemWorldService
##     │   └── CombatService
##     │
##     └── Dungeon
##         ├── SMCServiceManager
##         │   └── LootService
##         └── [You are here]
## [/codeblock]
## In this example, if you have a node in [code]Dungeon[/code] query its
## [SMCServiceManager] for [code]AudioService[/code], the managers will query 
## upwards until the first manager that has the service is found, and returns it.
## Or it was not found. [br][br]
##
## To indicate that a component, state, or service depends on a specific service,
## you can add a variable typed as the required service and mark it with
## [constant PROPERTY_HINT_SERVICE]:
##
## [codeblock]
## @export_custom(SMCService.PROPERTY_HINT_SERVICE, SMCService.PROPERTY_USAGE_SERVICE)
## var audio: AudioService
## [/codeblock]

## Custom [enum PropertyHint] used to flag services exports as dependencies.[br]
## These dependencies will be set automatically by the service manager owning 
## this service. [br]
## [b]Example[/b]:
## [codeblock]
## @export_custom(SMCService.PROPERTY_HINT_SERVICE, SMCService.PROPERTY_USAGE_SERVICE)
## var save: SaveService
## [/codeblock]
const PROPERTY_HINT_SERVICE: int = PROPERTY_HINT_MAX + _PROPERTY_HINT_MAGIC

## Custom [enum PropertyUsage] used to flag services exports as dependencies.[br]
## These dependencies will be set automatically by the service manager owning 
## this service. [br]
## [b]Example[/b]:
## [codeblock]
## @export_custom(SMCService.PROPERTY_HINT_SERVICE, SMCService.PROPERTY_USAGE_SERVICE)
## var save: SaveService
## [/codeblock]
## Note: This [enum PropertyUsage] flag is optional, but prevents the property 
## from showing in the editor.
const PROPERTY_USAGE_SERVICE: int = PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_SCRIPT_VARIABLE

const _PROPERTY_HINT_MAGIC: int = 1307
