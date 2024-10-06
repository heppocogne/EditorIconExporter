tool
class_name IconPreview
extends PanelContainer

signal selected(ref_self)

var _is_selected:=false
var icon_name:String #setget _set_icon_name
var icon_texture:Texture #setget _set_icon_texture


func _gui_input(event:InputEvent):
	if event is InputEventMouseButton:
		var mb:=event as InputEventMouseButton
		if mb.pressed and mb.button_index==BUTTON_LEFT:
			if _is_selected:
				unselect()
				emit_signal("selected",null)
			else:
				_is_selected=true
				add_stylebox_override("panel", preload("res://addons/editor_icon_exporter/panel_style_selected.tres"))
				emit_signal("selected",self)


func _set_icon_name(new_name:String):
	$VBoxLayout/Label.text=new_name
	icon_name=new_name


func _set_icon_texture(new_texture:Texture):
	$VBoxLayout/CenterContainer/TextureRect.texture=new_texture
	icon_texture=new_texture


func setup(new_name:String,new_texture:Texture):
	$VBoxLayout/Label.text=new_name
	icon_name=new_name
	$VBoxLayout/CenterContainer/TextureRect.texture=new_texture
	icon_texture=new_texture


func unselect():
	_is_selected=false
	add_stylebox_override("panel", preload("res://addons/editor_icon_exporter/panel_style_normal.tres"))
