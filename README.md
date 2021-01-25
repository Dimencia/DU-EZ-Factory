# DU-EZ-Factory
A simple industry monitoring script that requires only a link to the core

WIP

## Instructions
1. Setup a Programming Board and Screen
2. Link the Prog Board to the Screen.  Edit Lua on the board, and rename that slot to 'screen'
3. Link the Prog Board to the Core.  Edit the Lua on the board, and rename that slot to 'core'
4. Create unit.Start event, and paste in ezfactory Start.lua
5. Create unit.Tick event, put "industry" in the tick argument, and paste in ezfactory.lua
6. Create screen.MouseDown and paste in ezfactory MouseDown.lua

That's it.  Turn on the board and screen, and you should see information about your factory.

### Notes 

Products that are measured in Liters do not display values properly, so no values are displayed for them

It is beneficial to change your industry units from infinite to Maintain a very high number - this allows it to show you the amount in storage, without having to link to a container

Transfer Units do not give schematic information and are not shown
