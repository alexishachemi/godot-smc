@icon("res://addons/smc/icons/icon_component.png")
@abstract
class_name SMCComponent 
extends Node

## A component that holds reusable data and systems.
##
## Components are used to break down systems and data into individual parts that
## can then be reused for multiple entites.
## [br][br]
## For example, a [i]HealthComponent[/i] containing an exported health value,
## a signal indicating when the value change and other helper functions could be
## used for the player and for enemies without changing the code of the 
## component itself.
## [br][br]
## Although technically not necessary, components are meant to be added as
## direct child of [SMCComponentManager] nodes to ensure that all features such
## as querying and dependency management are handled.
## [br][br]
##[b]Component Dependencies[/b]:[br]
## You may have components that depends on others to function with said
## dependency being one-way only (e.g. a [i]DamageableComponent[/i] that needs
## a [i]HealthComponent[/i] to function but the [i]HealthComponent[/i] itself 
## does not need a [i]DamageableComponent[/i]). [br]
## An easy way of providing such behaviour is to simply export said component
## so it can be added from the editor:
## [codeblock]
## @export var health: HealthComponent
## [/codeblock][br]
## Another way of doing it is using the added [constant PROPERTY_HINT_COMPONENT]
## that flags an exported variable as a component dependency. Such values will
## be resolved automatically by the [SMCComponentManager]:
## [codeblock]
## @export_custom(PROPERTY_HINT_COMPONENT, "", 0) var health: HealthComponent
## [/codeblock][br]
## With that line, you can then use [param health] as is in your code, the
## component manager will take care of setting the value before the component
## is ready, handling error handling as well.
## [br][br]
## [b]Note[/b]: The property usage should be set to [code]0[/code] like in the
## example. Since the value will be set automatically by the component manager,
## we don't need to show it in the editor or serialize it with the scene.
## [br][br]
## [b]Usage Example[/b]:
## [codeblock]
## class_name HealthComponent
## extends SMCComponent
##
## signal changed
## signal depleated
##
## @export var amount: int = 3:
## 	set = set_health
##
## func set_health(value: int) -> void:
## 	amount = max(0, value)
## 	if amount == 0:
## 		depleated.emit()
## 	else:
## 		changed.emit()
## [/codeblock]
## [codeblock]
## class_name DamageableComponent
## extends SMCComponent
##
## signal damaged
##
## @export_custom(PROPERTY_HINT_COMPONENT, "", 0) 
## var health: HealthComponent
##
## func _ready() -> void:
## 	health.depleated.connect(die)
##
## func take_damage(amount: int) -> void:
##		...
##
## func die() -> void:
## 	...
## [/codeblock]

## Custom [enum PropertyHint] used to flag component exports as dependencies.[br]
## These dependencies will be set automatically by the component manager owning 
## this component. [br]
## [b]Example[/b]:
## [codeblock]
## @export_custom(PROPERTY_HINT_COMPONENT, "", 0) var health: HealthComponent
## [/codeblock]
const PROPERTY_HINT_COMPONENT: int = PROPERTY_HINT_MAX + _PROPERTY_HINT_MAGIC

const _PROPERTY_HINT_MAGIC: int = 193469992
