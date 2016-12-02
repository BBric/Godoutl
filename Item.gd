
# Item
#
# Un élément structurel.
#
#............................................................................................................

extends VBoxContainer # VBox pour ClassItem

#............................................................................................................

var member setget set_member

#............................................................................................................

func set_member(value): # setter

	if member != null or value == null: return
	member = value
	add_child(value)

#............................................................................................................

func free():

	if member != null: member.free()
	.free()

#............................................................................................................

func _init(member = null): set_member(member)