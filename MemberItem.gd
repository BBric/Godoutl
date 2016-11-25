
# MemberItem
#
# Un élément qui représente un membre. Il peut être une classe, une méthode statique, une méthode d'instance,
# une variable, une constante ou un signal. Il contient une icône et un texte qui peuvent être cliqués.
# Le type modifie l'icône.
#
#
# ** CONSTANTES ***************************************
#
# CLASS .......................	Type classe
# STATIC ......................	Type méthode statique
# FUNC ........................	Type méthode
# VAR .........................	Type variable
# CONST .......................	Type constante
# SIGNAL ......................	Type signal
#
#
# ** PROPRIÉTÉS ***************************************
#
# type ........................	Code du type (RW)
# text ........................	Identifiant texte (RW)
# line ........................	Indice de la ligne (RW)
# icon ........................	Icône (RW)
#
#
# ** MÉTHODES *****************************************
#
# is_method ...................	Détermine si l'occurrence est une méthode
#
#
# ** SIGNAUX ******************************************
#
# clicked (member, icon) ......	Lorsque l'icône (icon = true) ou le texte sont cliqués.
#
#.............................................................................................................

extends HBoxContainer

#.............................................................................................................

const CLASS = 0
const STATIC = 1
const FUNC = 2
const VAR = 3
const CONST = 4
const SIGNAL = 5

const _FUNC_SUFFIX = "()"

#.............................................................................................................

var type setget set_type # int
var text setget set_text, get_text # LinkButton
var line setget set_line # int
var icon setget set_icon, get_icon # Button

signal clicked (member, icon) # MemberItem, bool

#.........................................................................................................

func is_method(): return type == FUNC or type == STATIC

#.........................................................................................................

func get_icon(): return icon.get_button_icon() # getter

#.........................................................................................................

func set_icon(value): icon.set_button_icon(value) # setter

#.........................................................................................................

func set_line(value): line = max(0, int(value)) # setter

#.........................................................................................................

func get_text(): return text.get_text() # : getter

#.........................................................................................................

func set_text(value): # setter

	if type == FUNC or type == STATIC or type == SIGNAL: value += _FUNC_SUFFIX
	text.set_text(value)

#.........................................................................................................

func set_type(value): # setter

	if value < 0 or value > 5: type = FUNC
	else: type = value

	var s = text.get_text()

	if type == FUNC or type == STATIC or type == SIGNAL:

		if not s.ends_with(_FUNC_SUFFIX): text.set_text(s + _FUNC_SUFFIX)
		icon.set_ignore_mouse(true)

	else:

		if s.ends_with(_FUNC_SUFFIX): text.set_text(s.substr(0, s.length() - 2))
		icon.set_ignore_mouse(type != CLASS)

#.........................................................................................................

func _on_released(i): emit_signal("clicked", self, i)

#.........................................................................................................

func _on_mouse_enter(): emit_signal("mouse_enter")

#.............................................................................................................

func free():

	if icon.get_parent() != null: icon.get_parent().remove_child(icon)
	icon.disconnect("released", self, "_on_released", [true])
	icon.disconnect("mouse_enter", self, "_on_mouse_enter")
	icon.free()
	icon = null

	if text.get_parent() != null: text.get_parent().remove_child(text)
	text.disconnect("released", self, "_on_released")
	text.disconnect("mouse_enter", self, "_on_mouse_enter")
	text.free()
	text = null

	.free()

#.............................................................................................................

func _init(line, type, name): # int, int, String

	icon = Button.new()
	icon.set_flat(true)
	icon.add_style_override("focus", StyleBoxEmpty.new())
	icon.set_click_on_press(true)
	icon.connect("released", self, "_on_released", [true])
	icon.connect("mouse_enter", self, "_on_mouse_enter")
	add_child(icon)

	var c = CenterContainer.new() # centrage vertical
	c.set_ignore_mouse(true)

	text = LinkButton.new()
	text.set_underline_mode(LinkButton.UNDERLINE_MODE_ON_HOVER)
	text.set_click_on_press(true)
	text.connect("released", self, "_on_released", [false])
	text.connect("mouse_enter", self, "_on_mouse_enter")
	c.add_child(text)
	add_child(c)

	set_line(line)
	set_type(type)
	set_text(name)