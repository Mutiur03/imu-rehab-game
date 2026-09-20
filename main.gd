
extends Node2D

@onready var player = $Player
@onready var target = $Target
@onready var score_label = $ScoreLabel

var repetitions: int = 0
var start_position: Vector2 = Vector2(150, 300)
var target_radius: float = 5

func _ready() -> void:
	player.position = start_position
	score_label.text = "Repetitions: 0"

func _process(_delta: float) -> void:
	var distance = player.position.distance_to(target.position)

	if distance <= target_radius:
		complete_repetition()

func complete_repetition() -> void:
	repetitions += 1

	score_label.text = "Repetitions: " + str(repetitions)

	player.position = start_position
