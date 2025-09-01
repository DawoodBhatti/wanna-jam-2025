#tile_effects_manager.gd
# this script is designed to manage the in game behaviour of tiles which have been placed 
# within the game level(s).

# as well as adding things to the effect queue!

#and a placeholder for future animation calls

extends Node

func _ready() -> void:
	print("loading the tile manager in :)")
	SignalBus.connect("queue_end_turn_tile_effects", Callable(self, "_continuity"))
	

func _continuity() -> void:
	SignalBus.emit_logged("end_turn_tile_effects_queued")
	
	

#todo:
#hook the logic flow in somewhere. here and gamestate, probably?

#call to find unresolved structures 

#handling and resolution of unresolved structures.

#general logic of what I need to do:
#resolve the structure effects this turn:

#on the appropriate signal we advance any building progress 
#we queue any building effects that are ready to be fired
#we trigger animations etc

#also likely need an effect calculation phase? 

#phase changed: Turn Effects 
#lets just use "calculating structure effects"
#ideally should link into new signal resolving structure effects which triggers something
#within this code to update the structure state and generate any effects to be applied. 


#TODO: can think about this...

#we can define custom structure effects somewhere? a child node for now
#with a note that we are likely to want to allow these structures to 
#inherit properties from somewhere which we can 
#modify as is customary for roguelike games...
