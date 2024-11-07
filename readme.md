# Code Design Rules 

This is a small set of principles in how the code should be treated!

## Owner Independence

- A component of a larger object should always be **completely agnostic** of its parent
- If a property is needed by multiple unrelated objects (`deltaTime`, `globalScale`, etc.), pass it as a parameter when needed to avoid global variables

## Composition Over Inheritance

- `Entity` classes hold info and functionality related to the physical object in the game world 
    - i.e. the `SKSpriteNode` pertaining to the object, and any properties we want to have operate on top of that 
- `Player, Spider, etc...` (the dedicated classes) hold functionality that works on top of the entity, e.g. `Player` changes position via inputs
    - i.e. Each dedicated class will hold an entity, and then what works on top of that 

## One Thing, One Task 

- Specific bits of functionality (e.g. car spawning, score keeping, game speed handling) should all be handled by **their own respective object**
    - i.e. a `ScoreKeeper` to handle score *and* a `SpeedKeeper` to handle game speed, as opposed to one class that does both
