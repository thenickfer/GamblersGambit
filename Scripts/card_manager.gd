extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.2

var card_being_dragged
var screen_size
var is_hovering_on_card
var player_hand_reference
var game_manager_reference

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	game_manager_reference = get_parent()
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		var screen_mouse_pos = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
		card_being_dragged.position = card_being_dragged.position.lerp(screen_mouse_pos, 8.0 * delta)

func start_drag(card):
	card.scale = Vector2(1, 1)
	card_being_dragged = card

func finish_drag():
	card_being_dragged.scale = Vector2(1.05, 1.05)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and card_slot_found.is_player_slot:
		var result = game_manager_reference.try_play_player_card(card_being_dragged)
		if result.accepted:
			player_hand_reference.remove_card_from_hand(card_being_dragged)
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			if not result.went_to_board:
				if card_slot_found.card_in_slot and is_instance_valid(card_slot_found.card_node):
					card_slot_found.card_node.queue_free()
				card_being_dragged.global_position = card_slot_found.get_card_snap_position()
				card_slot_found.card_in_slot = true
				card_slot_found.card_node = card_being_dragged
		else:
			player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	else:
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card):
	if !is_hovering_on_card and (!card_being_dragged or card_being_dragged == card):
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if card_being_dragged == card:
		return
	highlight_card(card, false)
	var new_card_hovered = raycast_check_for_card()
	if new_card_hovered:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false

func highlight_card(card, hovered):
	if card.get_meta("on_temp_board", false):
		return
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		for hit in result:
			var slot = hit.collider.get_parent()
			if slot.is_player_slot:
				return slot
		return result[0].collider.get_parent()
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
