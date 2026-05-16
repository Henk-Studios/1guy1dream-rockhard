## Main menu UI with play, settings, and quit options
extends Control
class_name Menu

@export var play_classic_button: Button
@export var play_infinite_button: Button
@export var play_infinite_rising_lava_button: Button
@export var play_race_to_space_button: Button
@export var play_race_to_riches_button: Button
@export var continue_button: Button
@export var load_game_save_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var seed_input: LineEdit
@export var name_input: LineEdit
@export var dev_button: Button
@export var pr_left: RichTextLabel
@export var pr_right: RichTextLabel
@export var username_label: RichTextLabel
@export var username_field: LineEdit
@export var upload_scores_button: Button
@export var refresh_leaderboard_button: Button
@export var leaderboard_title_label: RichTextLabel
@export var leaderboard_left: RichTextLabel
@export var leaderboard_right: RichTextLabel

@export var set_seed_leaderboards_button: Button
@export var random_seed_leaderboards_button: Button
@export var classic_leaderboard_button: Button
@export var infinite_leaderboard_button: Button
@export var rising_lava_leaderboard_button: Button
@export var race_to_space_leaderboard_button: Button
@export var race_to_riches_leaderboard_button: Button

@export var settings_menu: SettingsMenu
@export var load_menu: LoadMenu

# Username storage constants
const LEADERBOARD_SECTION := "leaderboard"
const USERNAME_KEY := "player_username"

# Leaderboard tab tracking
var current_seed_type: int = 1
var current_game_type: int = 0
var leaderboard_entries: Array = [] # Cache the downloaded entries
var _leaderboard_refresh_token: int = 0
var _upload_token: int = 0

var saved_username: String = ""

func _ready() -> void:
	play_classic_button.pressed.connect(_on_play_button_pressed.bind(Manager.utility.GameType.CLASSIC))
	play_infinite_button.pressed.connect(_on_play_button_pressed.bind(Manager.utility.GameType.INFINITE))
	play_infinite_rising_lava_button.pressed.connect(_on_play_button_pressed.bind(Manager.utility.GameType.INFINITE_RISING_LAVA))
	play_race_to_space_button.pressed.connect(_on_play_button_pressed.bind(Manager.utility.GameType.RACE_TO_SPACE))
	play_race_to_riches_button.pressed.connect(_on_play_button_pressed.bind(Manager.utility.GameType.RACE_TO_RICHES))
	continue_button.pressed.connect(_on_continue_button_pressed)
	load_game_save_button.pressed.connect(_on_load_game_save_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_classic_button.mouse_entered.connect(_on_button_mouse_entered)
	play_infinite_button.mouse_entered.connect(_on_button_mouse_entered)
	play_infinite_rising_lava_button.mouse_entered.connect(_on_button_mouse_entered)
	play_race_to_space_button.mouse_entered.connect(_on_button_mouse_entered)
	play_race_to_riches_button.mouse_entered.connect(_on_button_mouse_entered)
	continue_button.mouse_entered.connect(_on_button_mouse_entered)
	load_game_save_button.mouse_entered.connect(_on_button_mouse_entered)
	settings_button.mouse_entered.connect(_on_button_mouse_entered)
	quit_button.mouse_entered.connect(_on_button_mouse_entered)
	dev_button.pressed.connect(_on_dev_button_pressed)
	set_pr_label()
	settings_menu.player_data_cleared.connect(set_pr_label)
	settings_menu.player_data_cleared.connect(_update_username_ui)
	upload_scores_button.pressed.connect(_on_upload_scores_button_pressed)
	refresh_leaderboard_button.pressed.connect(_on_refresh_leaderboard_button_pressed)
	
	# Initialize username UI based on whether a username exists
	_update_username_ui()
	
	# Leaderboard tab buttons
	set_seed_leaderboards_button.pressed.connect(_on_set_seed_tab_pressed)
	random_seed_leaderboards_button.pressed.connect(_on_random_seed_tab_pressed)
	classic_leaderboard_button.pressed.connect(_on_classic_tab_pressed)
	infinite_leaderboard_button.pressed.connect(_on_infinite_tab_pressed)
	rising_lava_leaderboard_button.pressed.connect(_on_rising_lava_tab_pressed)
	race_to_space_leaderboard_button.pressed.connect(_on_race_to_space_tab_pressed)
	race_to_riches_leaderboard_button.pressed.connect(_on_race_to_riches_tab_pressed)
	
	# Set initial button states
	random_seed_leaderboards_button.button_pressed = true
	classic_leaderboard_button.button_pressed = true
	
	play_classic_button.grab_focus()

	await get_tree().create_timer(2.0).timeout
	load_leaderboard()

func set_pr_label() -> void:
	var classic_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.CLASSIC, Manager.utility.SeedType.SET))
	var classic_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.CLASSIC, Manager.utility.SeedType.RANDOM))
	var infinite_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.INFINITE, Manager.utility.SeedType.SET))
	var infinite_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.INFINITE, Manager.utility.SeedType.RANDOM))
	var lava_pr_set = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.INFINITE_RISING_LAVA, Manager.utility.SeedType.SET))
	var lava_pr_random = Manager.utility.format_time(Manager.utility.get_personal_record(Manager.utility.GameType.INFINITE_RISING_LAVA, Manager.utility.SeedType.RANDOM))
	var race_to_space_pr_set = Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_SPACE, Manager.utility.SeedType.SET)
	var race_to_space_pr_random = Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_SPACE, Manager.utility.SeedType.RANDOM)
	var race_to_riches_pr_set: int = int(Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_RICHES, Manager.utility.SeedType.SET))
	var race_to_riches_pr_random: int = int(Manager.utility.get_personal_record(Manager.utility.GameType.RACE_TO_RICHES, Manager.utility.SeedType.RANDOM))

	var left_text = "Random Seed:"
	left_text += "\n[left]Classic:[/left]"
	left_text += "\n[left]Infinite:[/left]"
	left_text += "\n[left]Rising Lava:[/left]"
	left_text += "\n[left]Race to Space:[/left]"
	left_text += "\n[left]Race to Riches:[/left]"
	left_text += "\n\nSet Seed:"
	left_text += "\n[left]Classic:[/left]"
	left_text += "\n[left]Infinite:[/left]"
	left_text += "\n[left]Rising Lava:[/left]"
	left_text += "\n[left]Race to Space:[/left]"
	left_text += "\n[left]Race to Riches:[/left]"
	
	var right_text = ""
	right_text += "\n[right]%s[/right]" % classic_pr_random
	right_text += "\n[right]%s[/right]" % infinite_pr_random
	right_text += "\n[right]%s[/right]" % lava_pr_random
	right_text += "\n[right]%.2f[/right]" % race_to_space_pr_random
	right_text += "\n[right]%s[/right]" % race_to_riches_pr_random
	right_text += "\n\n"
	right_text += "\n[right]%s[/right]" % classic_pr_set
	right_text += "\n[right]%s[/right]" % infinite_pr_set
	right_text += "\n[right]%s[/right]" % lava_pr_set
	right_text += "\n[right]%.2f[/right]" % race_to_space_pr_set
	right_text += "\n[right]%s[/right]" % race_to_riches_pr_set
	
	pr_left.text = left_text
	pr_right.text = right_text


func _update_username_ui() -> void:
	saved_username = Manager.utility.load_player_data(LEADERBOARD_SECTION, USERNAME_KEY, "")
	
	if saved_username.is_empty():
		# No username saved yet - show input field, hide label
		username_field.visible = true
		username_field.editable = true
		username_field.text = ""
		username_label.visible = false
	else:
		# Username already set - hide input field, show label
		username_field.visible = false
		username_field.editable = false
		username_label.visible = true
		username_label.text = "Username: %s" % saved_username
			
func _on_play_button_pressed(game_mode: int) -> void:
	Manager.audio.play_click_sfx()
	var params := {}
	if seed_input.text != "":
		params["seed"] = seed_input.text
	if name_input.text != "":
		params["name"] = name_input.text
	params["gamemode"] = game_mode
	Manager.scene.change_scene("res://scenes/world.tscn", params)

func _on_continue_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	# Try to load the most recent saved world and pass it to the world scene as params
	var entry = Manager.utility.get_latest_save_entry()
	if entry.is_empty():
		Manager.message.info("No saved game found")
		return
	var data: Dictionary = entry["data"]
	var params := {}
	if data.has("seed") and data["seed"] != null:
		params["seed"] = data["seed"]
	params["save_path"] = entry["path"]
	params["load_data"] = data
	Manager.scene.change_scene("res://scenes/world.tscn", params)

func _on_load_game_save_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	load_menu.show_menu()

func _on_settings_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	settings_menu.show_settings()

func _on_quit_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	get_tree().quit()

func _on_upload_scores_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	var uname = saved_username
	if uname.is_empty():
		if username_field.text.is_empty():
			Manager.message.info("Please enter a username to upload scores")
			return
		else:
			uname = username_field.text.strip_edges()
			if uname.is_empty():
				Manager.message.info("Please enter a username to upload scores")
				return
	
	_upload_token += 1
	var upload_token = _upload_token
	upload_scores_button.disabled = true
	Manager.message.info("Uploading scores...")
	
	var success = await Manager.utility.upload_scores(uname)
	upload_scores_button.disabled = false
	if upload_token != _upload_token:
		return
	
	if success:
		# Save the username for future uploads
		saved_username = uname
		Manager.utility.save_player_data(LEADERBOARD_SECTION, USERNAME_KEY, uname)
		# Update UI to reflect that username is now set
		_update_username_ui()
		load_leaderboard()
		Manager.message.info("Scores uploaded successfully!")
	else:
		Manager.message.info("Failed to upload scores")

func _on_refresh_leaderboard_button_pressed() -> void:
	Manager.audio.play_click_sfx()
	load_leaderboard()

func load_leaderboard() -> void:
	_leaderboard_refresh_token += 1
	var refresh_token = _leaderboard_refresh_token
	leaderboard_left.text = "Loading leaderboard..."
	leaderboard_right.text = ""
	var results = await Manager.utility.download_leaderboard()
	if refresh_token != _leaderboard_refresh_token:
		return
	if results == null:
		leaderboard_entries = []
		leaderboard_left.text = "Leaderboard unavailable"
		leaderboard_right.text = ""
		return
	leaderboard_entries = results
	_update_leaderboard_display()

func _update_leaderboard_display() -> void:
	if leaderboard_entries.is_empty():
		leaderboard_left.text = "No leaderboard data available"
		return
	
	# Determine which score key to display based on selected tabs
	var score_key: String = Manager.utility.get_score_key(current_game_type, current_seed_type)
	
	# Build the leaderboard text with only the selected tab's data
	var game_type_display = Manager.utility.get_game_display_name(current_game_type)
	var seed_type_display = "Set Seed" if current_seed_type == Manager.utility.SeedType.SET else "Random Seed"
	leaderboard_title_label.text = "[center]%s - %s[/center]" % [game_type_display, seed_type_display]
	var right_text = ""
	var left_text = ""
	
	# Sort entries by score. Order (ascending/descending) comes from the gametype definition.
	var sorted_entries = leaderboard_entries.duplicate()
	if Manager.utility.is_score_higher_better(current_game_type):
		sorted_entries.sort_custom(func(a, b): return b["scores"].get(score_key, 0) < a["scores"].get(score_key, 0))
	else:
		sorted_entries.sort_custom(func(a, b): return a["scores"].get(score_key, INF) < b["scores"].get(score_key, INF))
	
	var rank = 1
	for entry in sorted_entries:
		var player_name = entry["player_name"]
		var value = entry["scores"].get(score_key, INF)
		var value_str = ""
		if Manager.utility.GAME_TYPE_DEFINITIONS[current_game_type].get("format") == Manager.utility.ScoreFormats.TIME:
			value_str = Manager.utility.format_time(value)
		elif Manager.utility.GAME_TYPE_DEFINITIONS[current_game_type].get("format") == Manager.utility.ScoreFormats.HEIGHT:
			value_str = "%.2f" % value
		elif Manager.utility.GAME_TYPE_DEFINITIONS[current_game_type].get("format") == Manager.utility.ScoreFormats.MONEY:
			value_str = "$%s" % str(int(value))
		var color = "white"
		if player_name == Manager.utility.load_player_data(LEADERBOARD_SECTION, USERNAME_KEY, ""):
			color = "cyan"
		elif rank == 1:
			color = "yellow"
		elif rank == 2:
			color = "silver"
		elif rank == 3:
			color = "coral"
		
		left_text += "[left][color=%s]%d. %s[/color][/left]\n" % [color, rank, player_name]
		right_text += "[right][color=%s]%s[/color][/right]\n" % [color, value_str]
		rank += 1
	
	leaderboard_left.text = left_text
	leaderboard_right.text = right_text

func _set_seed_type(seed_type: int) -> void:
	Manager.audio.play_click_sfx()
	current_seed_type = seed_type
	set_seed_leaderboards_button.button_pressed = seed_type == Manager.utility.SeedType.SET
	random_seed_leaderboards_button.button_pressed = seed_type == Manager.utility.SeedType.RANDOM
	_update_leaderboard_display()

func _set_game_type(game_type: int) -> void:
	Manager.audio.play_click_sfx()
	current_game_type = game_type
	classic_leaderboard_button.button_pressed = game_type == Manager.utility.GameType.CLASSIC
	infinite_leaderboard_button.button_pressed = game_type == Manager.utility.GameType.INFINITE
	rising_lava_leaderboard_button.button_pressed = game_type == Manager.utility.GameType.INFINITE_RISING_LAVA
	race_to_space_leaderboard_button.button_pressed = game_type == Manager.utility.GameType.RACE_TO_SPACE
	race_to_riches_leaderboard_button.button_pressed = game_type == Manager.utility.GameType.RACE_TO_RICHES
	_update_leaderboard_display()

func _on_set_seed_tab_pressed() -> void:
	_set_seed_type(Manager.utility.SeedType.SET)

func _on_random_seed_tab_pressed() -> void:
	_set_seed_type(Manager.utility.SeedType.RANDOM)

func _on_classic_tab_pressed() -> void:
	_set_game_type(Manager.utility.GameType.CLASSIC)

func _on_infinite_tab_pressed() -> void:
	_set_game_type(Manager.utility.GameType.INFINITE)

func _on_rising_lava_tab_pressed() -> void:
	_set_game_type(Manager.utility.GameType.INFINITE_RISING_LAVA)

func _on_race_to_space_tab_pressed() -> void:
	_set_game_type(Manager.utility.GameType.RACE_TO_SPACE)

func _on_race_to_riches_tab_pressed() -> void:
	_set_game_type(Manager.utility.GameType.RACE_TO_RICHES)

func _on_button_mouse_entered() -> void:
	Manager.audio.play_hover_sfx()

var dev_click_count: int = 0

func _on_dev_button_pressed() -> void:
	dev_click_count += 1
	if dev_click_count >= 3:
		Manager.message.info("???")
		Manager.dev_mode = true
