
extends Node2D

@export var speed: float = 150.0

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		position.x += speed * delta

	if Input.is_action_pressed("ui_left"):
		position.x -= speed * delta
