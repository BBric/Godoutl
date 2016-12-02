
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
# add_item ................	Référence un élément sans l'afficher
# clear ...................	Vide l'occurrence
# close ...................	Masque les membres
# is_empty ................	Détermine si l'occurrence ne contient aucun membre
# is_white ................	Détermine si tous les membres sont masqués
# open ....................	Affiche les membres
# size ....................	Récupére le nombre d'éléments référencés
# update ..................	Actualise l'affichage
#
#.............................................................................................................

extends "Item.gd"

#.............................................................................................................

const _CLICKED_HANDLER = "_on_clicked"
const _TITLES = ["Methods", "Static Methods", "Classes", "Variables", "Constants", "Signals"]
const _TITLE = "%s (%d)"

const constants = preload("constants.gd") # GDScript

var _container # MarginContainer
var _children # VBoxContainer
var _groups # [Item] # groupes d'éléments dans l'ordre du script

#.............................................................................................................

func add_item(item):

	if not get_script().instance_has(item):
		item.member.connect(constants.SIGNAL_CLICKED, self, _CLICKED_HANDLER)

	var n = _groups.size()
	var i = n - 1
	var l = true # le groupe en cours est le dernier
	var e # premier groupe vide
	var p # groupe de même type précédent
	var g

	while i > -1:

		g = _groups[i]

		if g.type == null:
			e = g

		elif g.type != item.member.type:
			l = false

		elif l:
			return g.items.append(item)

		else:
			p = g
			break

		i -= 1

	if e != null:

		g = e
		g.type = item.member.type

	else: # nouveau groupe

		g = Group.new(item.member.type)
		_groups.append(g)

	if p != null:

		g.previous = weakref(p)
		p.next = weakref(g)

	g.items.append(item)

#.............................................................................................................

# Vide l'occurrence. Les classes ne sont pas fermées.

func clear():

	if member != null: member.clear()

	for i in _groups: # Group

		if i.get_parent() != null: i.get_parent().remove_child(i)

		for j in i.items: # Item

			if j.member.is_connected(constants.SIGNAL_CLICKED, self, _CLICKED_HANDLER):
				j.member.disconnect(constants.SIGNAL_CLICKED, self, _CLICKED_HANDLER)

			if get_script().instance_has(j): j.clear()
			else: j.member.clear()

		i.clear() # appelle unsummarize()

#.............................................................................................................

func close():

	if _container.get_parent() == null or member == null: return
	remove_child(_container)
	_dispatch(constants.CALLBACK_CLOSED)

#.............................................................................................................

func is_empty(): return _groups[0].type == null

#.............................................................................................................

func is_white(): return _groups[0].type != null and _children.get_child_count() == 0

#.............................................................................................................

func open(): if _container.get_parent() == null and _children.get_child_count() > 0: add_child(_container)

#.............................................................................................................

func size(): # : int

	var n = 0
	for i in _groups: if i.type != null: n += i.items.size()
	return n

#.............................................................................................................

func update(menu): # Menu.gd

	for i in _children.get_children(): _children.remove_child(i)
	for i in _groups: i.empty() # si group() change les éléments doivent être séparés avant

	if member != null and menu.get_member_mode(constants.MEMBER_CLASS) == constants.NUMBER_ONE: return

	if menu.group():

		for i in menu.order: # int

			if menu.get_member_mode(i) == constants.NUMBER_NONE: continue

			for j in _groups: # Group

				if j.type == i:

					j.update(menu)
					if j.get_child_count() > 0: _children.add_child(j)
					break

	else:

		var g = [] # groupes ignorés
		var l # groupes liés
		var j = 0

		for i in _groups:

			if i.type == null: break # groupe vide

			if menu.get_member_mode(i.type) == constants.NUMBER_NONE or g.find(i) > -1:

				g.erase(i)
				j += 1
				continue

			l = _get_linked_groups(menu, j)
			for k in l: g.append(k)
			i.update(menu, l)
			if i.get_child_count() > 0: _children.add_child(i)
			j += 1

	# même vide la classe reste ouverte pour une mise à jour ulérieure
	if member != null: member.set_white(is_white())

#.............................................................................................................

# PRIVATE

#.............................................................................................................

func _on_closed(): queue_sort()

#.............................................................................................................

func _on_clicked(member, icon):

	if icon: # member != null

		if get_child_count() == 1: open()
		else: close()

	else:

		_dispatch(constants.CALLBACK_SHOW, [member.line])

#.............................................................................................................

func _dispatch(m, a = null):

	var p = get_parent()

	while p != null:

		if p.has_method(m):

			if a != null: p.callv(m, a)
			else: p.call(m)

		if p.has_meta(constants.META_STOP): return
		p = p.get_parent()

#.............................................................................................................

# Récupére les groupes indirectement groupés lorsque Menu::group() vaut false et que des groupes masqués sont
# intercalés entre des groupes de même type. Le tableau renvoyé ne contient pas le groupe initial.

func _get_linked_groups(m, i): # Menu.gd, int : [Group]

	var n = _groups.size()
	var t = _groups[i].type
	var l = []
	var g
	i += 1

	while i < n:

		g = _groups[i]
		if g.type == t: l.append(g)
		elif g.type == null or m.get_member_mode(g.type) != constants.NUMBER_NONE: return l
		i += 1

	return l


#.. Object ..................................................................................................

func free():

	clear()

	if member != null:

		if member.get_parent() != null: member.get_parent().remove_child(_children)
		member.disconnect(constants.SIGNAL_CLICKED, self, _CLICKED_HANDLER)
		member.free()

	for i in _groups: i.free()
	_groups.clear()

	if _children.get_parent() != null: _children.get_parent().remove_child(_children)
	_children.free()

	if _container.get_parent() != null: _container.get_parent().remove_child(_container)
	_container.free()

	.free()

#............................................................................................................

func _init(name, white_icon): # String, ImageTexture

	add_constant_override("separation", 0)
	_container = MarginContainer.new()
	_children = VBoxContainer.new()
	_children.add_constant_override("separation", 0)
	_children.set_area_as_parent_rect(0)
	_container.add_child(_children)
	_groups = [Group.new(null)] # taille non nulle pour is_empty()

	if name == null: # racine

		_container.add_constant_override("margin_left", 0)
		add_child(_container)
		return

	_container.add_constant_override("margin_left", 16)
	set_member(preload("Member.gd").new(0, constants.MEMBER_CLASS, name, white_icon)) # affiché
	member.connect(constants.SIGNAL_CLICKED, self, _CLICKED_HANDLER)

#............................................................................................................

# Une séquence d'éléments de même type. Le type ne peut être modifié que lorsque le groupe est vide.

class Group:

	#........................................................................................................

	extends VBoxContainer

	#........................................................................................................

	var items setget set_items # []
	var type setget set_type # int
	var previous # WeakRef<Group>
	var next # WeakRef<Group>

	#........................................................................................................

	func clear():

		empty()
		items.clear()
		type = null
		previous = null
		next = null

	#........................................................................................................

	func empty():

		unsummarize()
		for i in get_children(): remove_child(i)

	#........................................................................................................

	func unsummarize(): if get_child_count() > 0: get_child(0).member.set_alias(null)

	#........................................................................................................

	func update(menu, groups = null): # Menu.gd, [Group]

		unsummarize()
		for i in get_children(): remove_child(i)
		if menu.group() and previous != null: return

		var l1 = [] # éléments potentiels

		if groups == null:

			groups = []
			var g = self

			while g != null:

				groups.append(g)
				if not menu.group(): break
				if g.next != null: g = g.next.get_ref()
				else: break

		else:

			groups.push_front(self)

		for i in groups: for j in i.items: if menu.show_private() or not j.member.is_private(): l1.append(j)

		if l1.size() == 0: return
		var l2 = [] # éléments à afficher
		var t

		if menu.sort():

			var k

			for i in l1: # Item

				k = 0
				t = i.member.label

				for j in l2: # Item

					if t.casecmp_to(j.member.label) < 0: break
					k += 1

				l2.insert(k, i)

		else:

			l2 = l1

		t = menu.get_member_mode(type) == 1 # >= 0

		for i in l2: # Item

			if i.member.type == constants.MEMBER_CLASS: i.update(menu)
			add_child(i)
			if t: return i.member.set_alias(_TITLE % [_TITLES[type], l1.size()])

	#........................................................................................................

	func set_items(value): return # setter

	#........................................................................................................

	func set_type(value): if items.size() == 0: type = value

	#........................................................................................................

	func free():

		empty()
		for i in items: i.free()
		items.clear()
		previous = null
		next = null

	#........................................................................................................

	func _init(type):

		items = []
		set_type(type)
		add_constant_override("separation", 0)