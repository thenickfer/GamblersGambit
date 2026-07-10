extends SceneTree

func _initialize():
	var checks = {
		"menu":         "res://Assets/Audio/Music/menu_theme.ogg",
		"combat":       "res://Assets/Audio/Music/combat_theme.ogg",
		"card_attack":  "res://Assets/Audio/SFX/card_attack.ogg",
		"card_fireball":"res://Assets/Audio/SFX/card_fireball.ogg",
		"hit":          "res://Assets/Audio/SFX/hit.ogg",
		"button_click": "res://Assets/Audio/SFX/button_click.ogg",
	}
	for k in checks:
		var p = checks[k]
		var exists = ResourceLoader.exists(p)
		var s = load(p) if exists else null
		var info = "NULL"
		if s:
			info = s.get_class()
			if "loop" in s:
				info += " loop=" + str(s.loop)
			info += " %.1fs" % s.get_length()
		print("%-14s exists=%s -> %s" % [k, exists, info])
	quit()
