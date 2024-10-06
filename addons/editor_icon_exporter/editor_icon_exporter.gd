tool
extends WindowDialog

# WANING!!: Re-acrivate plugin if you reload this script

# colors from https://github.com/godotengine/godot/blob/c98d6142d0c8cf4ac284a595ad1156a4b74736ad/editor/editor_themes.cpp#L546-L548
const _ERROR_COLOR:=Color(1,0.47,0.42)
const _SUCCESS_COLOR:=Color(0.45,0.95,0.5)
const _STATUS_COLOR:=Color(1.0,1.0,1.0)
const _CACHE_DIR:="user://cache/"
const _FORMAT_CACHE_FILENAME:="editor_icon_list_cache.{0}.var"
const _KEEP_LOWERCASE:=[
	"bool",
	"float",
	"int",
]

const _class_IconPreview:GDScript=preload("res://addons/editor_icon_exporter/icon_preview.gd")

var _version_str:String
var _icons:PoolStringArray
var _previews:Dictionary
var _progress:int
var _selected_icon:IconPreview


func _init():
	_icons=PoolStringArray()
	_previews={}


func _ready():
	if !Engine.editor_hint:
		popup_centered(Vector2(800,600))


func _process(_delta):
	if _icons.size()==_progress:
		$MarginContainer/VBoxContainer/HBoxrContainer/ProgressBar.visible=false
		return
	
	var g:GridContainer=$MarginContainer/VBoxContainer/ScrollContainer/GridContainer
	var start_time:=OS.get_ticks_msec()
	while _progress<_icons.size():
		var icon_name:=_icons[_progress]
		if has_icon(icon_name,"EditorIcons"):
			var preview:_class_IconPreview=preload("res://addons/editor_icon_exporter/icon_preview.tscn").instance()
			preview.connect("selected",self,"_on_IconPreview_selected")
			preview.setup(icon_name,get_icon(icon_name,"EditorIcons"))
			_previews[icon_name]=preview
			g.add_child(preview)
		else:
			push_error("editor icon not found: "+icon_name)
		_progress+=1
		
		if 15<=OS.get_ticks_msec()-start_time:
			break
	
	var pb:ProgressBar=$MarginContainer/VBoxContainer/HBoxrContainer/ProgressBar
	pb.value=_progress
	if _icons.size()==_progress:
		_set_status("")


func _on_WindowDialog_about_to_show():
	_fetch_icons()


func _get_icon_cache()->PoolStringArray:
	var dir:=Directory.new()
	if !dir.dir_exists(_CACHE_DIR):
		dir.make_dir(_CACHE_DIR)
	
	var cache_file:=_CACHE_DIR+_FORMAT_CACHE_FILENAME.format([_version_str])
	if dir.file_exists(cache_file):
		var cache:=File.new()
		if cache.open(cache_file, File.READ)==OK:
			var data:PoolStringArray=cache.get_var()
			cache.close()
			return data
	
	return PoolStringArray()


func _fetch_icons():
	_set_status("Fetching editor icons from repository...")
	
	var version_info:=Engine.get_version_info()
	print_debug(version_info)
	if version_info["build"]!="official":
		push_warning("This editor is not official build which may cause an unexpected behavior")
	
	if version_info["major"]!=3:
		push_error("This plugin only works on Godot3")
		return
	
	if version_info["patch"]==0:
		_version_str="3.{minor}-{status}".format(version_info)
	else:
		_version_str="3.{minor}.{patch}-{status}".format(version_info)
	
	_icons=_get_icon_cache()
	
	if _icons.size()==0:
		var api_url:="https://api.github.com/repos/godotengine/godot/git/trees/{0}?recursive=1".format([_version_str])
		#var api_url:="https://api.github.com/repos/godotengine/godot/git/trees/{0}".format([_version_str])
		var request:HTTPRequest=$HTTPRequest
		request.request(api_url)
	else:
		_load_icons()


func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	print_debug("result=",result,", response_code=",response_code)
	if result==OK and 200<=response_code and response_code<400:
		var response_body:=body.get_string_from_utf8()
		var parse_result:JSONParseResult =JSON.parse(response_body)
		if parse_result.error==OK:
			var obj:Dictionary=parse_result.result
			_icons=PoolStringArray()
			for elem in obj["tree"]:
				var path:String=elem["path"]
				# SVG only
				# icon_snake_case -> CamelCase
				if path.begins_with("editor/icons/icon_") and path.ends_with(".svg"):
					# "editor/icons/icon_": 18 chars, ".svg": 4 chars
					var icon_name:=path.substr(18,path.length()-22).to_lower()
					if !_KEEP_LOWERCASE.has(icon_name):	# primitive type names are lowercase
						icon_name=_snake_to_camel(icon_name)
					
						if 0<=icon_name.rfind("2d"):	# some icons are *_2_d and others are *_2d
							icon_name=icon_name.replace("2d","2D")
						elif 0<=icon_name.rfind("3d"):	# some icons are *_3_d and others are *_3d
							icon_name=icon_name.replace("3d","3D")
					_icons.push_back(icon_name)
			
			if 0<_icons.size():
				_icons.sort()
				
				var cache:=File.new()
				if cache.open(_CACHE_DIR+_FORMAT_CACHE_FILENAME.format([_version_str]),File.WRITE)==OK:
					cache.store_var(_icons)
					cache.close()
				else:
					push_error("failed to save icons list cache")
				
				_load_icons()
				return
	
	_set_error("Failed to fetch icon list")


static func _snake_to_camel(s:String)->String:
	var words:=s.split("_")
	var result:=""
	for word in words:
		result+=word[0].to_upper()+word.substr(1,word.length()-1)
	
	return result


func _load_icons():
	if _progress==_icons.size():
		_set_status("")
		return
	_set_status("Loading icons...")
	var pb:ProgressBar=$MarginContainer/VBoxContainer/HBoxrContainer/ProgressBar
	pb.visible=true
	pb.value=0
	pb.max_value=_icons.size()


func _on_IconPreview_selected(ref_preview:IconPreview):
	if _selected_icon:
		_selected_icon.unselect()
	
	_selected_icon=ref_preview


func _set_error(msg:String):
	var m:Label=$MarginContainer/VBoxContainer/MessageLabel
	m.add_color_override("font_color",_ERROR_COLOR)
	m.text=msg


func _set_status(msg:String):
	var m:Label=$MarginContainer/VBoxContainer/MessageLabel
	m.add_color_override("font_color",_STATUS_COLOR)
	m.text=msg


func _set_success(msg:String):
	var m:Label=$MarginContainer/VBoxContainer/MessageLabel
	m.add_color_override("font_color",_SUCCESS_COLOR)
	m.text=msg


func _on_SearchLineEdit_text_changed(new_text:String):
	if new_text=="" or new_text.count("*")==new_text.length():
		for icon in _icons:
			_previews[icon].visible=true
	
	var filter:=new_text
	if new_text.find("*")<0 and new_text.find("?")<0:
		filter="*"+filter+"*"
	for icon in _icons:
		if _previews[icon].visible and !icon.matchn(filter):
			_previews[icon].visible=false
		else:
			_previews[icon].visible=true


func _on_ExportButton_pressed():
	if _selected_icon:
		$FileDialog.popup_centered(Vector2(600,400))


func _on_FileDialog_file_selected(path:String):
	var img:Image=_selected_icon.icon_texture.get_data()
	var save_error:int
	if path.ends_with(".png"):
		save_error=img.save_png(path)
	elif path.ends_with(".exr"):
		save_error=img.save_exr(path)
	elif path.ends_with(".tres") or path.ends_with(".res"):
		save_error=ResourceSaver.save(path,img)
	
	if save_error==OK:
		_set_success("Save OK: "+path)
	else:
		_set_error("Save Error (Error code:%d)"%[save_error])


func _update_grid_columns():
	var g:GridContainer=$MarginContainer/VBoxContainer/ScrollContainer/GridContainer
	if g.get_child_count()==0:
		return
	
	var child:=g.get_child(0)
	g.columns=max(g.rect_size.x/child.rect_size.x,1)


func _on_WindowDialog_visibility_changed():
	set_process(visible)
	
	if visible:
		_update_grid_columns()
	else:
		$MarginContainer/VBoxContainer/HBoxContainer/SearchLineEdit.text=""
		if _selected_icon:
			_selected_icon.unselect()
			_selected_icon=null


func _on_GridContainer_resized():
	_update_grid_columns()
