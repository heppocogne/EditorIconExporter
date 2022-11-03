tool
extends WindowDialog

# colors from https://github.com/godotengine/godot/blob/c98d6142d0c8cf4ac284a595ad1156a4b74736ad/editor/editor_themes.cpp#L546-L548
const error_color:=Color(1,0.47,0.42)
const success_color:=Color(0.45,0.95,0.5)

onready var texture_rect:TextureRect=$MarginContainer/VBoxContainer/CenterContainer/TextureRect
onready var error_message:Label=$MarginContainer/VBoxContainer/ErrorMessage


func _on_LineEdit_text_changed(new_text:String):
	if has_icon(new_text,"EditorIcons"):
		texture_rect.texture=get_icon(new_text,"EditorIcons")
	else:
		texture_rect.texture=null


func set_error(msg:String):
	error_message.add_color_override("font_color",error_color)
	error_message.text=msg


func set_success(msg:String):
	error_message.add_color_override("font_color",success_color)
	error_message.text=msg


func _on_ExportButton_pressed():
	if texture_rect.texture==null:
		set_error("Invalid icon name")
	else:
		$FileDialog.popup_centered(Vector2(600,400))


func _on_FileDialog_file_selected(path:String):
	var img:Image=texture_rect.texture.get_data()
	var save_error:int
	if path.ends_with(".png"):
		save_error=img.save_png(path)
	elif path.ends_with(".exr"):
		save_error=img.save_exr(path)
	elif path.ends_with(".tres") or path.ends_with(".res"):
		save_error=ResourceSaver.save(path,img)
	else:
		# not reachable
		set_error("Not-supported file format")
		return
	
	if save_error==OK:
		set_success("Save OK")
	else:
		set_error("Save Error (Error code:%d)"%[save_error])
