Power-ups:
    - Keep probability table, 1-100
    - A range represents an action
    - Gen. random number and evaluate against this table
        - e.g. 0-10 corresponds to spawning some powerup, so if I roll a 5, I'll do that
Checking ranges:
    - Keep a table of items mapped to a weight w
    - From this initial table, generate new table, where each item will exist w times
    - And now just choose a random item from the table!
