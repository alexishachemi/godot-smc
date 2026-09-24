# Godot - State Machine & Components

SMC is a Godot plugin that adds dependency injection systems with an integrated finite state machine.

**For Godot 4.7+**

## Installation

To add the addon, copy the `addons` folder into the root of your project. Then, in *Project Settings*, tick the enabled box.

Optionally, you may include a copy of the `script_templates` folder into the root of your project to be able to use the
provided templates when creating scripts.

## Scripts

This part lists the scripts that are meant to be subclassed when creating custom nodes for the plugin.

- <img src="addons\smc\icons\state.png" width="15"/> **SMCState**

    States allows for isolated code to run under certain conditions.
	Any user-created state must subclass the *SMCState* class to work with the state machine. The class contains common data and helper methods as well as the methods to override when creating a new state (i.e. _initialize, _enter, _exit...).

- <img src="addons\smc\icons\component.png" width="15"/> **SMCComponent**

    Components are used to break down systems and data into individual parts that can then be reused for multiple entites.
	Any user-created component must subclass the *SMCComponent* class to work with the component manager. Having a base class allows the component manager to handle dependencies with other components/services.

- <img src="addons\smc\icons\service.png" width="15"/> **SMCService**

    A scoped-context object that provides functionality to other SMC nodes within a scene tree. Services are cascading dependencies. Meaning that Services higher in the scene tree can be requested as well.
	Any user-created service must subclass the *SMCService* class to work with the service manager. Having a base class allows the service manager to handle dependencies with other services.

## Nodes

This part lists the custom nodes that are added by the plugin and can be found in the node selection menu of the editor.

- <img src="addons\smc\icons\state_machine.png" width="15"/> **SMCStateMachine**

	The root of the FSM system, used to manipulate states and state groups. Manage the transition between states and the signaling to outside sources. Can also manage states without the need for them to be in a state group.

- <img src="addons\smc\icons\state_group.png" width="15"/> **SMCStateGroup**

	Container for states. Handles transitions. multiple groups can be active in a single machine, allowing for multiple states to be active at the same time if they are in different groups. (for example, you can have a movement group with *idle*, *run*, *jump*, *dash* and a combat group with *idle*, *punch*, *kick*, *block*).

- <img src="addons\smc\icons\state_label.png" width="15"/> **SMCStateLabel**

	State display utility. Will automatically show the current state of a state machine/group.

- <img src="addons\smc\icons\component_manager.png" width="15"/> **SMCComponentManager**

	Container for components. Used by the FSM. Can also be used without it.


- <img src="addons\smc\icons\service_manager.png" width="15"/> **SMCServiceManager**

	Container for services. Used by the FSM and the component system. Can also be used without it.


# Dependency management

States and components can require other component to be present in the state machine to function. The state machine and component manager can handle dependency management automatically when using the custom property hint _PROPERTY_HINT_COMPONENT_:

```gdscript

@export_custom(SMCService.PROPERTY_HINT_SERVICE, "", SMCService.PROPERTY_USAGE_SERVICE)
var audio: AudioService

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var health: HealthComponent

func _ready() -> void:
	# NOT usable in _ready

func _initialize() -> void:
	# use audio & health here (or in any other SMCState related callback)
	health.value = 5
	audio.play_music(&"level_begin")
```

Properties marked with this hint will be set automatically by its managing node. Both `SMCComponent` and `SMCState` can have `PROPERTY_HINT_SERVICE` and `PROPERTY_HINT_COMPONENT` exports but within `SMCService`, only `PROPERTY_HINT_SERVICE` can be used.
