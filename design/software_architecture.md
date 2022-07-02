# Gamestate
This is a data structure which fully defines the gamestate. Meaning all cards, stats, action queues should be in here.
Generally speaking it should not provide any other mutation options other than setting or removing state.

Implemented using the entity object from nodeworks.

The object is in generally mutable with the option of cloning if needed.

# Game
The game object is the primary object through which interactions with the game occurs. This is where things like attack, damage and card draw is defined.
Furthermore it should also facilitate quering the state in various ways.

It is constructructed using a system context and a gamestate object. The context is for broadcasting events.

Optionally should be copyable for speculative evaluation.

# Systems in general

Systems should in general be defined as ecs world systems via a single function. RPC functionality should be provided by decorating the context with functionality. Other systems way call said functionality by retrieving the context and calling the function.

E.g. collision system with moving.

# Card UI

Should be defined as a system. Should only deal with visualization and animation.

Should be querable for things like mouse hitboxes.
