# DU-EZ-Factory
A simple industry monitoring script that requires only a link to the core

WIP.  Json export coming once it's more finished

## Instructions
1. Setup a Programming Board and Screen
2. Link the Prog Board to the Screen
3. Link the Prog Board to the Core
4. Create unit.Start event, and paste in ezfactory Start.lua
5. Create unit.Tick event, put "industry" in the tick argument, and paste in ezfactory.lua
6. Create MouseDown event on the slot that has your screen (it should be the only slot that lets you put this event).  Make it say `mouseDown( *, * )` and paste in ezfactory MouseDown.lua

That's it.  Turn on the board and screen, and you should see information about your factory.

### Notes 

Products that are measured in Liters do not display values properly, so no values are displayed for them

It is beneficial to change your industry units from infinite to Maintain a very high number - this allows it to show you the amount in storage, without having to link to a container

Transfer Units do not give schematic information and are not shown
