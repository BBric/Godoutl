
# Menu
#
# Regroupe les options de tri et de visibilité des éléments de la structure.
#
#
# ** MÉTHODES ****************************************
#
# get_member_mode .................	Récupére le mode d'afichage d'un type de membre
# get_order .......................	Récupére l'ordre des types
# group ...........................	Détermine si les éléments doivent être groupés
# show_private ....................	Détermine si les éléments qui commencent par _ doivent être affichés
# sort ............................	Détermine si les éléments doivent être triés alphabétiquement
#
#
# ** SIGNAUX *****************************************
#
# changed .........................	Distribué quand une option est modifiée
#
#............................................................................................................

extends HBoxContainer

#............................................................................................................

const constants = preload("constants.gd")

signal changed

var order setget set_order, get_order # IntArray

var _left # HBoxContainer
var _right # HBoxContainer
var _expand # StateButton
var _buttons # [StateButton]

#............................................................................................................

func get_member_mode(type): # int : int

	if type >= constants.MEMBER_FUNC and type <= constants.MEMBER_SIGNAL:
		return 2 - _right.get_child(type).current
	return 2

#............................................................................................................

func get_order(): # : IntArray (getter)

	var o = IntArray()
	o.append_array(order)
	return o

#............................................................................................................

func set_order(value): return

#............................................................................................................

func group(): return _left.get_child(0).current == 1 # : bool

#............................................................................................................

func show_private(): return _left.get_child(2).current == 1 # : bool

#............................................................................................................

func sort(): return _left.get_child(1).current == 1 # : bool

#............................................................................................................

func _on_button_released(b): # StateButton

	b.next()
	emit_signal("changed")

#............................................................................................................

func _init_button(b):

	b.set_custom_minimum_size(Vector2(20, 20))
	b.connect("released", self, "_on_button_released", [b])

#............................................................................................................

func free():

	for i in _left.get_children(): _left.remove_child(i)
	for i in _right.get_children(): _right.remove_child(i)
	for i in _buttons: i.free()
	_left.free()
	_right.free()
	_buttons.clear()
	.free()

#............................................................................................................

func _init(icon_picker):

	order = IntArray([constants.MEMBER_CONST, constants.MEMBER_VAR, constants.MEMBER_SIGNAL,
					  constants.MEMBER_STATIC, constants.MEMBER_FUNC, constants.MEMBER_CLASS])

	_left = HBoxContainer.new()
	_left.add_constant_override("separation", 0)

	_right = HBoxContainer.new()
	_right.set_alignment(BoxContainer.ALIGN_END)
	_right.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	_right.add_constant_override("separation", 0)
	var b

	for i in range(6):

		b = StateButton.new(icon_picker.get_icon(i, 0), icon_picker.get_icon(i, 1), icon_picker.get_icon(i, 2))
		_init_button(b)
		_right.add_child(b)

	b = StateButton.new(icon_picker.get_icon(0, 3), icon_picker.get_icon(1, 3)) # grouper
	_init_button(b)
	b.next()
	_left.add_child(b)

	b = StateButton.new(icon_picker.get_icon(2, 3), icon_picker.get_icon(3, 3)) # tri alphabétique
	_init_button(b)
	_left.add_child(b)

	b = StateButton.new(icon_picker.get_icon(4, 3), icon_picker.get_icon(5, 3)) # membres privés
	_init_button(b)
	b.next()
	_left.add_child(b)

	add_child(_left)
	add_child(_right)

#............................................................................................................

class StateButton:

	#........................................................................................................

	extends TextureButton

	#........................................................................................................

	var current setget set_current # int
	var _icons # [ImageTexture]

	#........................................................................................................

	func next():

		if current == _icons.size() - 1: current = 0
		else: current += 1
		set_normal_texture(_icons[current])

	#........................................................................................................

	func set_current(value): return

	#........................................................................................................

	func free():

		_icons.clear()
		.free()

	#........................................................................................................

	func _init(i1, i2 = null, i3 = null): # ImageTexture, ImageTexture, ImageTexture

		_icons = [i1]
		if i2 != null: _icons.append(i2)
		if i3 != null: _icons.append(i3)
		current = 0
		set_normal_texture(_icons[0])
		set_click_on_press(true)