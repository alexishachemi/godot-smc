# Godot - State Machine & Components

A plugin that adds nodes and scripts for the implementation of finite state machines using the Composition design pattern.

**Made in Godot 4.3** (probably works in older Godot 4 versions)

## Installation

To add the addon, copy the `addons` folder into the root of your project. Then, in *Project Settings*, tick the enabled box.

## Nodes

This part lists the custom nodes that are added by the plugin and can be found in the node selection menu of the editor.

- <img src="addons\smc\icons\icon_state_machine.png" width="10"/> **StateMachine**

    The root of the FSM system, used to manipulate states and state groups. Manage the transition between states and the signaling to outside sources. Can also manage states without the need for them to be in a state group.

- <img src="addons\smc\icons\icon_state_group.png" width="10"/> **StateGroup**

    Container for states, handles transitions, updating and dependency resolving. multiple groups can be active in a single machine, allowing for multiple states to be active at the same time if they are in different groups. (for example, you can have a movement group with *m_idle*, *run*, *jump*, *dash* and a combat group with *c_idle*, *punch*, *kick*, *block*).

- <img src="addons\smc\icons\icon_component_manager.png" width="10"/> **ComponentManager**

    Container for components, handle access from outside sources and the FSM as well as dependency resolving.

## Scripts

This part lists the scripts that are mean to be subclassed when creating custom nodes for the plugin.

- <img src="addons\smc\icons\icon_state.png" width="10"/> **State**

    Any user-created state must subclass the *State* class to work with the state machine. The class contains common data and helper methods as well as the methods to override when creating a new state (i.e. enter, exit, update, physics_update...). Since a state can request a transition for any group (and to avoid confusion), states within the same machine cannot share the same name.

- <img src="addons\smc\icons\icon_component.png" width="10"/> **Component**

    Any user-created component must subclass the *Component* class to work with the component manager. Components are nodes that contain logic meant to be modular and reusable. The scale of their content can vary based on context. Having a base class allows the component manager to handle dependencies with other components.
