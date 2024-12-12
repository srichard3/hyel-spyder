# Tasklist

- [x] Sounds
    - SKAction for onetimes
- [x] Haptics
    - Note that some crasing occurs if abusing the haptic engine with very short interval
- [ ] Particles
    - Should keep moving after death, since the universe's flow of time isn't halted by a meager car crash 
    - Ensure they adapt to game speed! It looks very weird if they don't 
- [x] Small tutorial type thing in the beginning
    - [ ] Add swipe indicator arrows
- [x] Small explanations for the power ups
- [ ] Game over animation
- [ ] Polish everything
- [ ] Black background for score text --do this next
    - Use the 4-dupe trick, it's fine...
- [ ] Music (?)
- [ ] Make sure rest of game is bug free (Yeah Sam... Sure...)

- Handle labels/particles by instantiating the nodes inside the configurer class

# Problems

## (Solved) How do we handle multiple powerups and their labels?

Desired look:
- Labels stacked on top of each other
- Each label has its own powerup's respective color 
    - We will need multiple nodes for this...
- When a powerup is done, its individual label is removed 
    - Use a stack!

### Solution

That desired look is kind of overkill... The extra stuff required to have a stack of powerups is too much for how little of them we have

Let's just:
- Check what powerups are active when collecting new one
- Concatenate indicators strings on one line when setting effect should there be multiple
- On unset, we do the same; check what's active once this powerup's expended and modify the string as necessary
- If no powerups left, just hide it

This comes at the cost of not really being able to do colors, but that's a tradeoff I'm willing to make
It'll look good when I add the 4-way background anyway
