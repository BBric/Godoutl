
# Member
#
# Un membre de script. Il peut être une classe, une méthode statique, une méthode d'instance,
# une variable, une constante ou un signal. Il contient une icône et un texte qui peuvent être cliqués.
# Le texte doit être définit avant la ligne
#
#
# ** PROPRIÉTÉS ***************************************
#
# type ........................	Code du type (RW)
# line ........................	Indice de la ligne (RW)
# icon ........................	Icône (RW)
# text ........................	Texte initial (R)
# label .......................	Texte affiché (RW)
#
#
# ** MÉTHODES *****************************************
#
# clear .......................	Invalide l'occurrence (ligne à -1)
# is_method ...................	Détermine si l'occurrence est une méthode
# is_private ..................	Détermine si l'identifiant commence par _
# set_alias ...................	Définit un alias coloré
# set_white ...................	Marque l'occurrence comme blanche
#
#
# ** SIGNAUX ******************************************
#
# clicked (member, icon) ......	Lorsque l'icône (icon = true) ou le texte sont cliqués.
# mouse_enter .................	Lorsque l'icône ou le texte est survolée (bubbles)
#
#............................................................................................................

extends HBoxContainer

#............................................................................................................

const _NAME = "%s%s"
const _FUNC_SUFFIX = "()"
const _UNDERLINE = "_"
const _FONT_COLOR = "font_color"
const _LINK_BUTTON = "LinkButton"
const _COLORS = [Color("69a9c3"), Color("6982c3"), Color("c97777"), Color("89be5a"), Color("b177c9"),
				 Color("bfbd31")]
const constants = preload("constants.gd")

#............................................................................................................

var line setget set_line # int
var type setget set_type # int
var icon setget set_icon, get_icon # Button
var text setget set_text # String
var label setget set_label, get_label # LinkButton

signal clicked (member, icon) # MemberItem, bool

var _white # CenterContainer

#............................................................................................................

# Invalide l'occurrence. Hors classe l'icône est également supprimée.

func clear():

	line = -1
	if type != constants.MEMBER_CLASS: set_icon(null)

#............................................................................................................

func is_method(): return type == constants.MEMBER_FUNC or type == constants.MEMBER_STATIC

#............................................................................................................

func is_private(): return text.begins_with(_UNDERLINE)

#............................................................................................................

func get_icon(): return icon.get_button_icon() # getter

#............................................................................................................

# Définit un alias coloré. null restaure le texte initial et sa couleur.

func set_alias(alias): # String

	if alias == null:

		if is_method() or type == constants.MEMBER_SIGNAL: label.set_text(_NAME % [text, _FUNC_SUFFIX])
		else: label.set_text(text)
		label.add_color_override(_FONT_COLOR, label.get_color(_FONT_COLOR, _LINK_BUTTON))

	else:

		label.set_text(alias)
		label.add_color_override(_FONT_COLOR, _COLORS[type])

#............................................................................................................

func set_white(value): # bool

	if type != constants.MEMBER_CLASS or _white == null: return
	if value and _white.get_parent() == null: add_child(_white)
	elif not value and _white.get_parent() != null: remove_child(_white)

#............................................................................................................

func set_icon(value): icon.set_button_icon(value) # setter

#............................................................................................................

func set_line(value): line = max(0, int(value)) # setter

#............................................................................................................

func get_label(): return label.get_text() # : String (getter)

#............................................................................................................

func set_label(value): # String (setter)

	text = str(value)
	if is_method() or type == constants.MEMBER_SIGNAL: label.set_text(_NAME % [text, _FUNC_SUFFIX])
	else: label.set_text(text)

#............................................................................................................

func set_text(value): return # setter

#............................................................................................................

func set_type(value): # setter

	if type == constants.MEMBER_CLASS: return

	type = clamp(int(value), constants.MEMBER_FUNC, constants.MEMBER_SIGNAL)

	if is_method() or type == constants.MEMBER_SIGNAL:

		if text != null: label.set_text(_NAME % [text, _FUNC_SUFFIX])
		icon.set_ignore_mouse(true)

	else:

		if text != null: label.set_text(text)
		icon.set_ignore_mouse(type != constants.MEMBER_CLASS)

#............................................................................................................

# PRIVATE

#............................................................................................................

func _on_released(i): emit_signal(constants.SIGNAL_CLICKED, self, i)

#............................................................................................................

func _on_mouse_enter():

	var p = self

	while p != null:

		p.emit_signal(constants.SIGNAL_MOUSE_ENTER)
		if p.has_meta(constants.META_STOP): return
		p = p.get_parent()

#............................................................................................................

func free():

	if _white != null:

		for i in _white.get_children():

			_white.remove_child(i)
			i.free()

	if icon.get_parent() != null: icon.get_parent().remove_child(icon)
	icon.disconnect("released", self, "_on_released", [true])
	icon.disconnect(constants.SIGNAL_MOUSE_ENTER, self, "_on_mouse_enter")
	icon.free()

	if label.get_parent() != null: label.get_parent().remove_child(label)
	label.disconnect("released", self, "_on_released")
	label.disconnect(constants.SIGNAL_MOUSE_ENTER, self, "_on_mouse_enter")
	label.free()

	for i in get_children():

		self.remove_child(i)
		i.free()

	.free()

#............................................................................................................

func _init(line, type, name, white_icon = null): # int, int, String, ImageTexture

	constants = preload("constants.gd")

	icon = Button.new()
	icon.set_flat(true)
	icon.add_style_override("focus", StyleBoxEmpty.new())
	icon.set_click_on_press(true)
	icon.connect("released", self, "_on_released", [true])
	icon.connect(constants.SIGNAL_MOUSE_ENTER, self, "_on_mouse_enter")
	add_child(icon)

	label = LinkButton.new()
	label.set_underline_mode(LinkButton.UNDERLINE_MODE_ON_HOVER)
	label.set_click_on_press(true)
	label.connect("released", self, "_on_released", [false])
	label.connect(constants.SIGNAL_MOUSE_ENTER, self, "_on_mouse_enter")

	var c = CenterContainer.new() # centrage vertical
	c.set_ignore_mouse(true)
	c.add_child(label)
	add_child(c)

	set_type(type)
	set_label(name)
	set_line(line)

	if type != constants.MEMBER_CLASS or white_icon == null: return

	var t = TextureFrame.new()
	t.set_texture(white_icon)
	_white = CenterContainer.new()
	_white.set_ignore_mouse(true)
	_white.add_child(t)