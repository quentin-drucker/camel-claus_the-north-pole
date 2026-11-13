extends SceneTree
## One-off migration to the Workshop Tin theme: clears per-node font-size/outline/color overrides left from
## the old pixel theme and assigns theme roles (type variations) instead. Godot re-saves the scenes.
## Run: godot --headless --path . -s <abs path>/art_src/tools/apply_tin_roles.gd

## scene -> {node path: variation ("" = plain role, just clear overrides)}
const ROLES: Dictionary = {
	"res://scenes/ui/pause_menu.tscn": {
		"Center/MainPanel/Title": "TitleLabel",
		"Center/MainPanel/Columns/BuildPanel/VBox/Heading": "HeaderLabel",
		"Center/MainPanel/Columns/StatsPanel/VBox/Heading": "HeaderLabel",
		"Center/MainPanel/Columns/BuildPanel/VBox/Details": "",
		"Center/MainPanel/Columns/StatsPanel/VBox/HpLine": "MutedLabel",
		"Center/MainPanel/Buttons/ResumeButton": "PrimaryButton",
		"Center/MainPanel/Buttons/SettingsButton": "",
		"Center/MainPanel/Buttons/RestartButton": "",
		"Center/MainPanel/Buttons/MenuButton": "",
	},
	"res://scenes/ui/settings_panel.tscn": {
		"VBox/Title": "TitleLabel",
		"VBox/ResetButton": "DangerButton",
		"VBox/BackButton": "PrimaryButton",
	},
	"res://scenes/ui/end_screen.tscn": {
		"Center/Panel/VBox/ResultLabel": "TitleLabel",
		"Center/Panel/VBox/Summary": "",
		"Center/Panel/VBox/Buttons/EndlessButton": "",
		"Center/Panel/VBox/Buttons/RestartButton": "PrimaryButton",
		"Center/Panel/VBox/Buttons/MenuButton": "",
	},
}
const CLEAR: Array[StringName] = [&"font_size", &"normal_font_size"]


func _initialize() -> void:
	var failed: int = 0
	for path: String in ROLES:
		var packed: PackedScene = load(path)
		var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		for node_path: String in ROLES[path]:
			var node: Control = root.get_node_or_null(node_path)
			if node == null:
				push_error("%s: no node %s" % [path, node_path])
				failed += 1
				continue
			for key in CLEAR:
				node.remove_theme_font_size_override(key)
			node.remove_theme_constant_override(&"outline_size")
			for key in [&"font_color", &"default_color"]:
				node.remove_theme_color_override(key)
			node.theme_type_variation = StringName(ROLES[path][node_path])
		var out := PackedScene.new()
		out.pack(root)
		print(path, " -> ", ResourceSaver.save(out, path))
		root.free()
	quit(failed)
