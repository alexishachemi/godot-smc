# Godot - State Machine & Components

SMC is a plugin that adds nodes and scripts for the implementation of finite state machines using the Composition design pattern.

**For Godot 4.6+**

## Installation

To add the addon, copy the `addons` folder into the root of your project. Then, in *Project Settings*, tick the enabled box.

Optionally, you may include a copy of the `script_templates` folder into the root of your project to be able to use the
provided templates when creating scripts.

## Nodes

This part lists the custom nodes that are added by the plugin and can be found in the node selection menu of the editor.

- <img src="addons\smc\icons\icon_state_machine.png" width="10"/> **SMCStateMachine**

	The root of the FSM system, used to manipulate states and state groups. Manage the transition between states and the signaling to outside sources. Can also manage states without the need for them to be in a state group.

- <img src="addons\smc\icons\icon_state_group.png" width="10"/> **SMCStateGroup**

	Container for states, handles transitions, updating and dependency resolving. multiple groups can be active in a single machine, allowing for multiple states to be active at the same time if they are in different groups. (for example, you can have a movement group with *idle*, *run*, *jump*, *dash* and a combat group with *idle*, *punch*, *kick*, *block*).

- <img src="addons\smc\icons\icon_component_manager.png" width="10"/> **SMCComponentManager**

	Container for components, handle access from outside sources and the FSM as well as dependency resolving.

- <img src="addons\smc\icons\icon_state_label.png" width="10"/> **SMCStateLabel**

	State display utility. Will automatically show the current state of a state machine/group.

## Scripts

This part lists the scripts that are meant to be subclassed when creating custom nodes for the plugin.

- <img src="addons\smc\icons\icon_state.png" width="10"/> **SMCState**

	Any user-created state must subclass the *SMCState* class to work with the state machine. The class contains common data and helper methods as well as the methods to override when creating a new state (i.e. _initialize, _enter, _exit...). Since a state can request a transition for any group (and to avoid confusion).

- <img src="addons\smc\icons\icon_component.png" width="10"/> **SMCComponent**

	Any user-created component must subclass the *SMCComponent* class to work with the component manager. Components are nodes that contain logic meant to be modular and reusable. The scale of their content can vary based on context. Having a base class allows the component manager to handle dependencies with other components.


# Dependency management

States and components can require other component to be present in the state machine to function. The state machine and component manager can handle dependency management automatically when using the custom property hint _PROPERTY_HINT_COMPONENT_:

```gdscript
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var health: HealthComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var ai: AIComponent

func _ready() -> void:
	# NOT usable in _ready

func _initialize() -> void:
	# use health and ai here (or any other SMCState related callback)
```

Properties marked with this hint will be set automatically by the state machine/component manager that manages the state/component. Generates an error when a state or component needs a specific component that is not present.
