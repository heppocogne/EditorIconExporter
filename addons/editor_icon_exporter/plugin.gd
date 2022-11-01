tool
extends EditorPlugin

var _base_control:Control
var icon_exporter_window:WindowDialog


func _enter_tree():
	assert(Engine.get_version_info().major >= 3)
	
	icon_exporter_window=preload("res://addons/editor_icon_exporter/editor_icon_exporter.tscn").instance()
	_base_control=get_editor_interface().get_base_control()
	_base_control.add_child(icon_exporter_window)
	
	add_tool_menu_item("Export Editor Icon",icon_exporter_window,"popup_centered",Vector2(300,158))


func _exit_tree():
	remove_tool_menu_item("Export Editor Icon")
	if icon_exporter_window:
		icon_exporter_window.queue_free()
