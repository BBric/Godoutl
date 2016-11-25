
# ClassItem
#
# Un élément qui représente une classe. Elle contient un élément membre talon si elle n'est pas racine.
# Elle peut contenir des éléments membres et/ou classes.
#
#
# ** PROPRIÉTÉS ***************************************
#
# (voir MemberItem)
#
#
# ** MÉTHODES *****************************************
#
# add_item ................	Ajoute un élément
# clear ...................	Masque les membres et les déréférence récursivement
# close ...................	Masque les membres
# open ....................	Affiche les membres
#
#
# ** SIGNAUX ******************************************
#
# id_clicked (line) .......	Lorsqu'un identifiant a été cliqué
# closed ..................	Lorsqu'une classe est fermée (l'occurrence ou un descendant)
#
#.............................................................................................................

extends VBoxContainer

#.............................................................................................................

const _MEMBER_CLICKED_HANDLER = "_on_member_clicked"
const _CLASS_CLICKED_HANDLER = "_on_class_clicked"
const _CLASS_CLOSED_HANDLER = "_on_class_closed"
const _MOUSE_ENTER_HANDLER = "_on_mouse_enter"
const _PROPERTIES = ["line", "type", "text", "icon"]

signal id_clicked (line) # int
signal closed () # int

var _container # MarginContainer
var _children # VBoxContainer
var _stub # Member

#.............................................................................................................

func add_item(item):

	if item == null or _children.is_a_parent_of(item): return

	if get_script().instance_has(item):

		item.connect("id_clicked", self, _CLASS_CLICKED_HANDLER)
		item.connect("closed", self, _CLASS_CLOSED_HANDLER)

	else:

		item.connect("clicked", self, _MEMBER_CLICKED_HANDLER)
		item.connect("mouse_enter", self, _MOUSE_ENTER_HANDLER)

	_children.add_child(item)
	if _stub == null and _container.get_parent() == null: add_child(_container)

#.............................................................................................................

func clear():

	close()
	if _stub != null: _stub.icon = null
	var i

	while _children.get_child_count() > 0:

		i = _children.get_child(0)

		if get_script().instance_has(i):

			i.clear()
			i.disconnect("id_clicked", self, _CLASS_CLICKED_HANDLER)
			i.disconnect("closed", self, _CLASS_CLOSED_HANDLER)

		else:

			i.disconnect("clicked", self, _MEMBER_CLICKED_HANDLER)
			i.disconnect("mouse_enter", self, _MOUSE_ENTER_HANDLER)

		_children.remove_child(i)

#.............................................................................................................

func close():

	if _container.get_parent() == null: return
	remove_child(_container)
	emit_signal("closed")

#.............................................................................................................

func open():

	if _container.get_parent() == null and _children.get_child_count() > 0:	add_child(_container)

#.............................................................................................................

func set_stub(value): return # setter

#.............................................................................................................

func _on_class_closed():

	queue_sort()
	emit_signal("closed")

#.............................................................................................................

func _on_class_clicked(line): emit_signal("id_clicked", line)

#.............................................................................................................

func _on_member_clicked(member, icon):

	if icon:

		if get_child_count() == 1: open() # _stub != null
		else: close()

	else:

		emit_signal("id_clicked", member.line)

#............................................................................................................

func _on_mouse_enter(): emit_signal("mouse_enter")


#.. Object ..................................................................................................

func _get(property):

	if _stub == null or _PROPERTIES.find(property) < 0: return
	return _stub.get(property)

#............................................................................................................

func _set(property, value):

	var i = _PROPERTIES.find(property)
	if i < 0: return false
	if _stub != null: _stub.set(property, value)
	return true

#............................................................................................................

func free():

	clear()

	if _stub != null:

		_stub.disconnect("clicked", self, _MEMBER_CLICKED_HANDLER)
		_stub.disconnect("mouse_enter", self, _MOUSE_ENTER_HANDLER)
		_stub.free()
		_stub = null

	if _children.get_parent() != null: _children.get_parent().remove_child(_children)
	_children.free()
	_children = null

	if _container.get_parent() != null: _container.get_parent().remove_child(_container)
	_container.free()
	_container = null

	.free()

#.............................................................................................................

func _init(name): # String

	add_constant_override("separation", 0)
	_container = MarginContainer.new()
	_children = VBoxContainer.new()
	_children.add_constant_override("separation", 0)
	_container.add_child(_children)

	if name == null: # racine

		_container.add_constant_override("margin_left", 0)
		return

	_container.add_constant_override("margin_left", 16)
	var MemberItem = preload("MemberItem.gd")
	_stub = MemberItem.new(0, MemberItem.CLASS, name)
	_stub.connect("clicked", self, _MEMBER_CLICKED_HANDLER)
	_stub.connect("mouse_enter", self, _MOUSE_ENTER_HANDLER)
	add_child(_stub)