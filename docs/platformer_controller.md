# PlayerController2D

The player script is the main controller for the player in a 2D sidescroller game. It handles all of the inputs and utilizes the StateMachine to transition between states. The states themselves contain all of the logic for the movement. The Hands are used to handle attacks using left and right hands through Hand class. And finally the Camera script is used to handle the camera movement.

Actions:

- forward
- backward
- left
- right
- jump
- dash
- interact
- crouch
- sprint

states:

- idle: standing
- moving: regular movement
- jumping: jump height varies when holding jump
- dashing: moves the player in the last horizontal direction of movement
- falling: coyote time, gravity application

hierarchy:

- Player (Player)
- - AnimatedSprite2D: currently only has "idle" and "run" animations
- - CollisionShape2D
- - Camera2D

Player:
handles all input and communication with Camera and StateMachine.

PlayerConfig:
stores all of the player settings such as movement speed, jump force, camera sensitivity etc.

Camera:
Camera movement that follows the player. Optional: Screen shake, fov controls (increase fov when speed is high)

StateMachine:
Handles the state transitions between the states.
