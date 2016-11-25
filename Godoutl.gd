
tool
extends EditorPlugin

#............................................................................................................

const CODE_TEXT_EDITOR = "CodeTextEditor"
const TEXT_EDIT = "TextEdit"
const V_SCROLL_BAR = "VScrollBar"
const EXIT_TREE = "exit_tree"
const CURSOR_CHANGED = "cursor_changed"
const CURSOR_CHANGED_HANDLER = "on_cursor_changed"
const EXIT_TREE_HANDLER = "on_script_exit_tree"
const TEXT_CHANGED = "text_changed"
const TEXT_CHANGED_HANDLER = "on_text_changed"

var editor_tabs # TabContainer
var editor_script # TextEdit
var editor_vscrollbar # VScrollbar
var dock # MarginContainer
var structure #  Structure.gd
var timer # Timer
var changed # bool

#............................................................................................................

func on_id_clicked(line):

	if editor_script == null: return

	if editor_vscrollbar == null or editor_vscrollbar.get_page() == 0:
		return editor_script.cursor_set_line(line)

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
	if editor_script != null and structure != null:	structure.parse(editor_script)
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
	var t = editor_tabs.get_current_tab_control()
	if t == null: return

	for i in t.get_children():

		if i.get_type() == TEXT_EDIT:

			for j in i.get_children():

				if j.get_type() == V_SCROLL_BAR:

					editor_vscrollbar = j
					break

			editor_script = i
			i.connect(EXIT_TREE, self, EXIT_TREE_HANDLER)
			i.connect(TEXT_CHANGED, self, TEXT_CHANGED_HANDLER)
			i.connect(CURSOR_CHANGED, self, CURSOR_CHANGED_HANDLER)
			structure.reset_scrolling()
			changed = true
			return update()

#.............................................................................................................

func find_editor_tabs():

	for i in get_editor_viewport().get_children():

		if i.get_type() == "ScriptEditor":

			for j in i.get_children():

				if j.get_type() == "HSplitContainer":

					for k in j.get_children():

						if k.get_type() == "TabContainer":

							editor_tabs = k
							k.connect("tab_changed", self, "on_tab_changed")
							return

					return

			return

#.. Node ....................................................................................................

func _enter_tree():

	var Structure = preload("Structure.gd")
	if Structure == null: return OS.alert("Structure.gd not found", "Outliner plugin")

	find_editor_tabs()
	if editor_tabs == null: return OS.alert("Unable to find editor tabs", "Outliner plugin")

	dock = MarginContainer.new()
	dock.add_constant_override("margin_left", 0)
	dock.set_area_as_parent_rect(0)
	dock.set_name("Outliner")

	timer = Timer.new()
	timer.set_wait_time(3.5)
	timer.set_one_shot(true)
	timer.connect("timeout", self, "update")
	get_base_control().add_child(timer)

	structure = Structure.new()
	structure.connect("id_clicked", self, "on_id_clicked")
	structure.connect("mouse_enter", self, "update")
	dock.add_child(structure)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	find_editor_script()

#............................................................................................................

func _exit_tree():

	unregister_script()

	if timer != null:

		if timer.get_parent() != null: timer.get_parent().remove_child(timer)
		timer.disconnect("timeout", self, "update")
		timer.free()
		timer = null

	if structure != null:

		if structure.get_parent() != null: structure.get_parent().remove_child(structure)
		structure.disconnect("id_clicked", self, "on_id_clicked")
		structure.disconnect("mouse_enter", self, "update")
		structure.free()
		structure = null

	if dock != null:

		remove_control_from_docks(dock)
		dock.free()
		dock = null

	if editor_tabs != null:

		editor_tabs.disconnect("tab_changed", self, "on_tab_changed")
		editor_tabs = null