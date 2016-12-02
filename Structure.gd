
# Structure
#
# Contenu défilant de la structure. Elle centralise le référencement et l'instanciation des éléments.
#
#
# ** MÉTHODES *****************************************
#
# clear ...................	Vide l'affichage et réinitialise tous les éléments
# parse ...................	Génére la structure d'un script
# reset_scrolling .........	Réinitialise le défilement à 0
#
#
# ** SIGNAUX ******************************************
#
# show (line) .............	Lorsqu'un identifiant a été cliqué
#
#............................................................................................................

extends Panel

#............................................................................................................

const Item = preload("Item.gd")
const Member = preload("Member.gd")
const ClassItem = preload("ClassItem.gd")
const constants = preload("constants.gd")

const _REGEX_22_KEYWORD_FIX = ["fu", "st", "cl", "va", "co", "si"]

signal show (line)

var menu setget set_menu # Menu.gd

var _container # ScrollContainer
var _root # ClassItem
var _empty # CenterContainer
var _citems # [ClassItem]
var _mitems # [Item]
var _icons # [{ImageTexture:bool}]
var _re # RegEx
var _blocks # Array
var _icon_picker # IconPicker.gd

#............................................................................................................

func clear():

	if _root.is_empty(): return

	_root.clear()
	for i in _icons: if i != null: for j in i: i[j] = false
	_update_empty()

#............................................................................................................

# Génére la structure d'un script.

func parse(script, v21): # TextEdit, bool

	clear()
	_blocks.resize(2) # blocs imbriqués [bloc parent (classe/méthode), indentation (0 pour _blocks[1])]
	var h = script.get_line_count()
	var n = 2 # taille de _blocks
	var b = _blocks[0] # bloc parent courant
	var u = 0 # indentation de p
	var i = 0 # ligne courante
	var v = 0 # indentation de la ligne courante
	var c = true # le bloc courant est une classe
	var s # code complet d'une ligne
	var m # membre
	var r # [String]

	# - hors classe une déclaration n'est jamais indentée sans erreur
	# - dans une classe une déclaration n'est jamais non-indentée sans erreur
	# - l'indentation d'une déclaration est toujours supérieure à celle de son bloc parent (sauf hors classe)
	# - une classe, une méthode, une constante ou un signal sont toujours hors méthode
	# - toutes les lignes d'un bloc ont la même indentation mais celle-ci peut avoir n'importe quelle valeur
	# - un bloc contient un seul type d'indentation, deux blocs peuvent avoir deux types différents
	# - un bloc parent ne peut pas être vide sans erreur
	# - une classe n'accepte pas un pass seul

	while i < h:

		s = script.get_line(i)
		r = _search(s, v21)

		if r == null: # code non déclarant

			i += 1
			continue

		v = r[0] # >= 0

		while v <= u and n > 2: # déclaration externe

			n -= 2
			_blocks.resize(n)
			b = _blocks[n - 2]
			u = _blocks[n - 1]
			c = ClassItem.instance_has(b)

		if not c: # le bloc en cours est une méthode
			i += 1
			continue

		m = _get_item(i, r[1], r[2])
		b.add_item(m) # référencement en tant que déclaration

		if ClassItem.instance_has(m):
			c = true

		elif m.member.is_method():
			c = false

		else: # membre

			i += 1
			continue # c inchangé

		_blocks.append(m) # référencement en tant que parent
		_blocks.append(v)
		b = m
		u = v
		n += 2
		i += 1

	_update()

#............................................................................................................

func reset_scrolling():

	_container.set_v_scroll(0)
	_container.set_h_scroll(0)

#............................................................................................................

func set_menu(): return # setter

#............................................................................................................

func _get_item(l, k, n): # int, String, String : MemberItem | ClassItem

	var t = constants.NAMES.find(k)

	if t == constants.MEMBER_CLASS:

		for i in _citems: # ClassItem

			if i.member.line < 0:

				i.member.line = l
				i.member.label = n
				return i # les classes conservent leur icône

		var i = ClassItem.new(n, _icon_picker.get_icon(6, 1))
		i.member.line = l
		i.member.icon = _get_icon(t)
		_citems.append(i)
		return i

	else:

		for i in _mitems: # Item

			if i.member.line < 0:

				i.member.type = t
				i.member.line = l
				i.member.label = n
				i.member.icon = _get_icon(t)
				return i

		var i = Item.new(Member.new(l, t, n))
		i.member.icon = _get_icon(t)
		_mitems.append(i)
		return i

#............................................................................................................

func _get_icon(type): # int : ImageTexture

	type = clamp(type, constants.MEMBER_FUNC, constants.MEMBER_SIGNAL)
	var d = _icons[type]

	if d == null:

		d = {}
		_icons[type] = d

	for i in d:

		if not d[i]:

			d[i] = true
			return i

	var i = _icon_picker.get_icon(type, 0)
	d[i] = true
	return i

#............................................................................................................

func _on_menu_changed(): _update()

#............................................................................................................

func _on_mouse_enter():

	var p = get_parent()

	while p != null:

		p.emit_signal(constants.SIGNAL_MOUSE_ENTER)
		p = p.get_parent()

#............................................................................................................

func _on_closed(): _container.queue_sort()

#............................................................................................................

func _on_show(line): emit_signal(constants.SIGNAL_SHOW, line)

#............................................................................................................

# Utilisée pour empêcher les barres de défilement de se chevaucher.

func _on_draw():

	var v = _container.get_child(2)
	var h = _container.get_child(1)

	if v.get_page() > 0 and not v.is_hidden():

		if h.get_page() > 0 and not h.is_hidden():

			var s = h.get_size()
			v.set_size(Vector2(v.get_size().width, get_size().height - s.height))
			h.set_size(Vector2(get_size().width - v.get_size().width, s.height))

		else:

			v.set_size(Vector2(v.get_size().width, get_size().height))

	elif h.get_page() > 0 and not h.is_hidden():

		h.set_size(Vector2(get_size().width, h.get_size().height))

#............................................................................................................

# Récupére une recherche sous la forme [indentation, mot-clef, identifiant].

func _search(s, v21): # String, bool : [String]

	if not v21:

		if s.length() == 0: return
		var r = _re.search(s) # Condition ' p_start >= p_text.length() ' is true. returned: __null
		if r == null: return
		var a = [s.length() - r.get_string(1).length(), r.get_string(2), r.get_string(3)]

		if a[1].length() == 0:
			a[1] = constants.NAMES[_REGEX_22_KEYWORD_FIX.find(r.get_string(1).substr(0, 2))]

		return a

	elif _re.find(s) >= 0:

		return [s.length() - _re.get_capture(1).length(), _re.get_capture(2), _re.get_capture(3)]

#............................................................................................................

func _update():

	_root.update(menu)
	_update_empty()

#............................................................................................................

func _update_empty():

	_empty.get_child(1).set_hidden(not _root.is_white())
	_empty.get_child(0).set_hidden(not _root.is_empty())
	_container.queue_sort()


#.. Object ..................................................................................................

func free():

	_blocks.clear()

	for i in _icons:
		if i != null:
			for j in i: VS.free_rid(j)

	_icons.clear()

	if _root.get_parent() != null: _root.get_parent().remove_child(_root)
	_root.free()
	VS.free_rid(_root)

	for i in _citems:
		i.free()
		VS.free_rid(i)
	_citems.clear()

	for i in _mitems:
		i.free()
		VS.free_rid(i)
	_mitems.clear()

	for i in _empty.get_children():
		_empty.remove_child(i)
		VS.free_rid(i)
	if _empty.get_parent() != null: _empty.get_parent().remove_child(_empty)
	_empty.free()
	VS.free_rid(_empty)

	disconnect("draw", self, "_on_draw")
	if _container.get_parent() != null: _container.get_parent().remove_child(_container)
	_container.free()
	VS.free_rid(_container)

	_re = null
	.free()

#............................................................................................................

func _init():

	_icon_picker = preload("IconPicker.gd").new()
	menu = preload("Menu.gd").new(_icon_picker)
	menu.connect("changed", self, "_on_menu_changed")
	set_meta(constants.META_STOP, true)
	set_custom_minimum_size(Vector2(50, 50))
	set_v_size_flags(Control.SIZE_EXPAND_FILL) # sinon hauteur minimale

	_citems = []
	_mitems = []
	_icons = [{}, null, null, {}, null, null]

	_root = ClassItem.new(null, null)
	_blocks = [_root, 0]

	# 0: tout, 1: code non indenté, 2: mot-clef, 3: identifiant
	_re = RegEx.new()
	_re.compile("^(?:\t| )*((func|static func|var|const|class|signal)(?: |\t)+([_a-zA-Z]+[_a-zA-Z0-9]*).*)")

	_empty = CenterContainer.new()
	_empty.set_area_as_parent_rect(0)
	_empty.set_ignore_mouse(true)

	var t = TextureFrame.new()
	t.set_texture(_icon_picker.get_icon(6, 0)) # vide
	t.set_ignore_mouse(true)
	_empty.add_child(t)

	t = TextureFrame.new()
	t.set_texture(_icon_picker.get_icon(6, 1)) # blanc
	t.set_ignore_mouse(true)
	t.set_hidden(true)
	_empty.add_child(t)

	var m = MarginContainer.new()
	m.set_area_as_parent_rect(0)
	m.add_constant_override("margin_top", 8)
	m.add_constant_override("margin_left", 2)
	m.add_constant_override("margin_right", 12)
	m.add_constant_override("margin_bottom", 16)
	m.set_margin(MARGIN_RIGHT, 12)
	_root.set_area_as_parent_rect(0)
	m.add_child(_root)

	_container = ScrollContainer.new()
	_container.connect(constants.SIGNAL_MOUSE_ENTER, self, "_on_mouse_enter")
	_container.set_area_as_parent_rect(0)
	_container.add_child(m)
	_container.move_child(m, 0)
	add_child(_empty)
	add_child(_container)
	connect("draw", self, "_on_draw")