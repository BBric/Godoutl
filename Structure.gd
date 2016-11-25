
# Structure
#
# Contenu défilant de la structure. Elle centralise le référencement et l'instanciation des éléments.
#
#
# ** MÉTHODES *****************************************
#
# clear ...................	Vide l'affichage et réinitialise tous les éléments
# add_line ................	Ajoute une ligne
#
#............................................................................................................

extends Panel

#............................................................................................................

const _NAMES = ["class", "static func", "func", "var", "const", "signal"]
const _STATIC = "static"

var ClassItem setget set_read_only # GDScript
var MemberItem setget set_read_only # GDScript

signal id_clicked (line)

var _container # ScrollContainer
var _root # ClassItem
var _empty # CenterContainer
var _citems # [CLassItem]
var _mitems # [MemberItem]
var _icons # [{ImageTexture:bool}]
var _re # RegEx
var _path # String
var _file # File
var _blocks # Array

#............................................................................................................

func clear():

	if _root.get_child_count() == 0: return

	_root.clear()
	for i in _icons: for j in i: i[j] = false
	_empty.set_hidden(false)

#............................................................................................................

func parse(script): # TextEdit

	clear()
	_blocks.resize(2) # blocs imbriqués [bloc parent (classe ou méthode), indentation (toujours 0 pour b[1])]
	var h = script.get_line_count()
	var n = 2 # taille de _blocks
	var b = _blocks[0] # bloc parent courant
	var u = 0 # indentation de p
	var i = 0 # ligne courante
	var v = 0 # indentation de la ligne courante
	var c = true # le bloc courant est une classe
	var s # code complet d'une ligne
	var t # type de membre
	var m # membre

	# - hors classe une déclaration n'est jamais indentée sans erreur
	# - dans une classe une déclaration n'est jamais non-indentée sans erreur
	# - l'indentation d'une déclaration est toujours supérieure à celle de son bloc parent (sauf hors classe)
	# - une classe, une méthode, une constante ou un signal sont toujours hors méthode
	# - toutes les lignes d'un bloc ont la même indentation mais celle-ci peut avoir n'importe quelle valeur
	# - un bloc contient un seul type d'indentation, deux blocs peuvent avoir deux types différents
	# - un bloc parent ne peut pas être vide sans erreur

	while i < h:

		s = script.get_line(i)

		if _re.find(s) < 0: # code non déclarant

			i += 1
			continue

		t = _re.get_capture(2) # mot-clef
		v = s.length() - _re.get_capture(1).length() # >= 0

		while v <= u and n > 2: # déclaration externe

			n -= 2
			_blocks.resize(n)
			b = _blocks[n - 2]
			u = _blocks[n - 1]
			c = ClassItem.instance_has(b)

		if not c: # le bloc en cours est une méthode
			i += 1
			continue

		m = _get_item(i, t, _re.get_capture(3))
		b.add_item(m) # référencement en tant que déclaration

		if ClassItem.instance_has(m):
			c = true

		elif m.is_method():
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

	_empty.set_hidden(_root.get_child_count() > 0)

#............................................................................................................

func reset_scrolling():

	_container.set_v_scroll(0)
	_container.set_h_scroll(0)

#............................................................................................................

func set_read_only(): return # setter

#............................................................................................................

func _get_item(l, k, n): # int, String, String : MemberItem | ClassItem

	var t = _NAMES.find(k)

	if t == MemberItem.CLASS:

		for i in _citems: # ClassItem

			if i.get_parent() == null:

				i.line = l
				i.text = n
				i.icon = _get_icon(t, k)
				return i

		var i = ClassItem.new(n)
		i.line = l
		i.icon = _get_icon(t, k)
		_citems.append(i)
		return i

	else:

		for i in _mitems: # MemberItem

			if i.get_parent() == null:

				i.type = t
				i.line = l
				i.text = n
				i.icon = _get_icon(t, k)
				return i

		var i = MemberItem.new(l, t, n)
		i.icon = _get_icon(t, k)
		_mitems.append(i)
		return i

#............................................................................................................

func _get_icon(t, k): # int, String : ImageTexture

	var d = _icons[t]

	for i in d: if not d[i]: return i

	var i

	if t == MemberItem.STATIC: i = _get_image(_STATIC)
	else: i = _get_image(k)

	d[i] = true
	return i

#............................................................................................................

func _get_image(n):

	var p = _path % n
	var t
	if _file.file_exists(p): t = load(p)

	if t != null:

		t.set_size_override(Vector2(16, 16))

	else:

		var i = Image(1, 1, false,Image.FORMAT_RGB)
		i.put_pixel(0, 0, Color(1, 0, 1))
		t = ImageTexture.new()
		t.create_from_image(i.resized(16, 16))

	return t

#............................................................................................................

func _on_id_clicked(line): emit_signal("id_clicked", line)

#............................................................................................................

func _on_item_closed(): _container.queue_sort()

#............................................................................................................

func _on_mouse_enter(): emit_signal("mouse_enter")

#.. CanvasItem ..............................................................................................

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


#.. Object ..................................................................................................

func free():

	if _root.get_parent() != null: _root.get_parent().remove_child(_root)
	_root.disconnect("id_clicked", self, "_on_id_clicked")
	_root.disconnect("closed", self, "_on_item_closed")
	_root.disconnect("mouse_enter", self, "_on_mouse_enter")
	_root.free()
	_root = null

	for i in _icons: i.clear()
	_icons.clear()
	_icons = null

	_citems.clear()
	_citems = null

	_mitems.clear()
	_mitems = null

	if _empty.get_parent() != null: _empty.get_parent().remove_child(_empty)
	_empty.free()
	_empty = null

	.disconnect("draw", self, "_on_draw")
	if _container.get_parent() != null: _container.get_parent().remove_child(_container)
	_container.free()
	_container = null

	_blocks.clear()
	_blocks.free()
	_blocks = null

	_file = null
	_re = null

#............................................................................................................

func _init():

	ClassItem = preload("ClassItem.gd")
	MemberItem = preload("MemberItem.gd")
	if ClassItem == null: return OS.alert("ClassItem.gd not found", "Outliner plugin")
	if MemberItem == null: return OS.alert("MemberItem.gd not found", "Outliner plugin")

	_citems = []
	_mitems = []
	_icons = []

	_root = ClassItem.new(null)
	_root.connect("id_clicked", self, "_on_id_clicked")
	_root.connect("closed", self, "_on_item_closed")
	_root.connect("mouse_enter", self, "_on_mouse_enter")

	_blocks = [_root, 0]
	_path = get_script().get_path().get_base_dir() + "/%s.png"
	_file = File.new()
	for i in _NAMES: _icons.append({})

	# 0: tout, 1: code non indenté, 2: mot-clef, 3: identifiant
	_re = RegEx.new()
	_re.compile("^(?:\t| )*((func|static func|var|const|class|signal)(?: |\t)+([_a-zA-Z]+[_a-zA-Z0-9]*).*)")

	_empty = CenterContainer.new()
	_empty.set_area_as_parent_rect(0)
	_empty.set_ignore_mouse(true)

	var t = TextureFrame.new()
	t.set_texture(_get_image("empty"))
	t.set_ignore_mouse(true)
	_empty.add_child(t)

	set_area_as_parent_rect(0)
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
	_container.connect("mouse_enter", self, "_on_mouse_enter")
	_container.set_area_as_parent_rect(0)
	_container.add_child(m)
	_container.move_child(m, 0)
	add_child(_empty)
	add_child(_container)
	connect("draw", self, "_on_draw")