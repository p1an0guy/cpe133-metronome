# TODO

## Backend Tasks

- [ ] beats per measure module, using tempo_generator.sv as input and emitting downbeats
- [ ] main "backend" module generating downbeats and other beats
- [ ] moore FSM logic for start/stop states (not just reset, but actually start and stop) with on-board switches
- [ ] figure out how to interface with buttons, and use them to increment/decrement counts
- [ ] left-right buttons modify tempo, up-down buttons modify beats per measure(?)

## Frontend Tasks

- [ ] indicate beats (either using 7SD or blinking LED)
- [ ] indicate downbeats with all LED's turning on(??)
- [ ] retrieve beats per minute and time signature from other modules
- [ ] find out if we can just export beats per minute without setting it as a module output
- [ ] MUX (with switch input) to choose between displaying BPM or time signature on 7SD
