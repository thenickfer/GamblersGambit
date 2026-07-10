extends Node

const STARTING_COINS: int = 20
const WIN_COINS: int = 100

var player_coins: int = STARTING_COINS
var selected_cpu_assertiveness: float = 0.2
var current_match_cost: int = 0

func can_afford_coins(amount: int) -> bool:
	return player_coins >= amount

func spend_coins(amount: int) -> bool:
	if not can_afford_coins(amount):
		return false
	player_coins -= amount
	return true

func set_selected_difficulty(assertiveness: float) -> void:
	selected_cpu_assertiveness = clampf(assertiveness, 0.0, 1.0)

func set_selected_match(cost: int, assertiveness: float) -> void:
	current_match_cost = maxi(0, cost)
	set_selected_difficulty(assertiveness)

func resolve_match(player_won: bool) -> void:
	if player_won:
		player_coins += current_match_cost * 2
	current_match_cost = 0

func has_no_coins() -> bool:
	return player_coins <= 0

func has_winning_coins() -> bool:
	return player_coins >= WIN_COINS
