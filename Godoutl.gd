
tool
extends EditorPlugin

#............................................................................................................

const V_SCROLL_BAR = "VScrollBar"
const EXIT_TREE = "exit_tree"
const CURSOR_CHANGED = "cursor_changed"
const CURSOR_CHANGED_HANDLER = "on_cursor_changed"
const EXIT_TREE_HANDLER = "on_script_exit_tree"
const TEXT_CHANGED = "text_changed"
const TEXT_CHANGED_HANDLER = "on_text_changed"
const constants = preload("constants.gd")

var editor_tabs # TabContainer
var editor_script # TextEdit
var editor_vscrollbar # VScrollbar
var dock # MarginContainer
var structure #  Structure.gd
var timer # Timer
var changed # bool
var script_path # [String]
var v21 # bool

#............................................................................................................

func on_show(line):

	if editor_script == null: return

	if editor_vscrollbar == null or editor_vscrollbar.get_page() == 0:
		return editor_script.cursor_set_line(line, true) # si false la ligne n'est pas sélectionnée

	var n = editor_script.get_line_count()

	editor_vscrollbar.set_value(editor_vscrollbar.get_max()) # scroll_past_end_of_file true ou false
	editor_script.cursor_set_line(line - 1, true)
	editor_script.cursor_set_line(line)
	editor_script.cursor_set_column(editor_script.get_line(line).length())

#............................................................................................................

func on_script_exit_tree(): unregister_script()

#............................................................................................................

func on_tab_changed(tab): find_editor_script()

#............................................................................................................

func on_text_changed():

	if changed: return

	changed = true
	if timer != null: timer.start()

#............................................................................................................

func on_cursor_changed(): if changed and timer != null: timer.start()

#............................................................................................................

func update():

	if not changed: return

	if timer != null: timer.stop()
	if editor_script != null and structure != null:	structure.parse(editor_script, v21)
	changed = false

#............................................................................................................

func unregister_script():

	if structure != null: structure.reset_scrolling()
	editor_vscrollbar = null

	if editor_script != null:

		editor_script.disconnect(EXIT_TREE, self, EXIT_TREE_HANDLER)
		editor_script.disconnect(TEXT_CHANGED, self, TEXT_CHANGED_HANDLER)
		editor_script.disconnect(CURSOR_CHANGED, self, CURSOR_CHANGED_HANDLER)
		editor_script = null
		structure.clear()

#.............................................................................................................

func find_editor_script(): # : TextEdit

	unregister_script()
	var o = editor_tabs.get_current_tab_control()
	for i in script_path: o = find_node(o, i)

	if o == null: return

	editor_vscrollbar = find_node(o, V_SCROLL_BAR)
	editor_script = o
	o.connect(EXIT_TREE, self, EXIT_TREE_HANDLER)
	o.connect(TEXT_CHANGED, self, TEXT_CHANGED_HANDLER)
	o.connect(CURSOR_CHANGED, self, CURSOR_CHANGED_HANDLER)
	structure.reset_scrolling()
	changed = true

	return update()

#............................................................................................................

func find_editor_tabs():

	var o = get_editor_viewport()

	for i in ["ScriptEditor", "HSplitContainer", "TabContainer"]:

		o = find_node(o, i)
		if o == null: return

	editor_tabs = o
	o.connect("tab_changed", self, "on_tab_changed")

#............................................................................................................

func find_node(node, type): # Node, String

	if node != null: for i in node.get_children(): if i.get_type() == type: return i


#.. Node ....................................................................................................

func _enter_tree():

	constants = preload("constants.gd")
	var Structure = preload("Structure.gd")
	if constants == null: return OS.alert("constants.gd not found", "Godoutl plugin")
	if Structure == null: return OS.alert("Structure.gd not found", "Godoutl plugin")
	if preload("IconPicker.gd") == null: return OS.alert("IconPicker.gd not found", "Godoutl plugin")
	if preload("Menu.gd") == null: return OS.alert("Menu.gd not found", "Godoutl plugin")
	if preload("Item.gd") == null: return OS.alert("Item.gd not found", "Godoutl plugin")
	if preload("ClassItem.gd") == null: return OS.alert("ClassItem.gd not found", "Godoutl plugin")
	if preload("Member.gd") == null: return OS.alert("Member.gd not found", "Godoutl plugin")

	script_path = ["CodeTextEditor", "TextEdit"]
	var v = OS.get_engine_version()
	v21 = float(v.major + "." + v.minor) < 2.2
	if v21: script_path.pop_front()

	find_editor_tabs()
	if editor_tabs == null: return OS.alert("Unable to find editor tabs", "Godoutl plugin")

	dock = MarginContainer.new()
	dock.add_constant_override("margin_left", 0)
	dock.set_name("Outliner")

	timer = Timer.new()
	timer.set_wait_time(3.5)
	timer.set_one_shot(true)
	timer.connect("timeout", self, "update")
	get_base_control().add_child(timer)

	structure = Structure.new()
	structure.connect(constants.SIGNAL_SHOW, self, "on_show")
	structure.connect(constants.SIGNAL_MOUSE_ENTER, self, "update")

	var v = VBoxContainer.new()
	v.set_area_as_parent_rect(0)
	v.add_child(structure.menu)
	v.add_child(structure)
	dock.add_child(v)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	find_editor_script()

#............................................................................................................

func _exit_tree():

	unregister_script()

	if timer != null:

		if timer.get_parent() != null: timer.get_parent().remove_child(timer)
		timer.disconnect("timeout", self, "update")
		timer.free()

	if structure != null:

		if structure.get_parent() != null: structure.get_parent().remove_child(structure)
		structure.disconnect(constants.SIGNAL_SHOW, self, "on_show")
		structure.disconnect(constants.SIGNAL_MOUSE_ENTER, self, "update")
		structure.free()

	if dock != null:

		remove_control_from_docks(dock)
		dock.free()

	if editor_tabs != null:

		editor_tabs.disconnect("tab_changed", self, "on_tab_changed")
		editor_tabs = null