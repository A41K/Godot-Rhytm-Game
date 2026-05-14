extends Area2D

@export var limit_left: bool = true
@export var limit_right: bool = true
@export var limit_top: bool = true
@export var limit_bottom: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var camera = body.get_node_or_null("Camera2D")
		if camera:
			var shape = get_node_or_null("CollisionShape2D")
			if shape and shape.shape is RectangleShape2D:
				var extents = shape.shape.size / 2
				
				if limit_left:
					camera.limit_left = int(global_position.x - extents.x)
				if limit_right:
					camera.limit_right = int(global_position.x + extents.x)
				if limit_top:
					camera.limit_top = int(global_position.y - extents.y)
				if limit_bottom:
					camera.limit_bottom = int(global_position.y + extents.y)
			else:
				if limit_left:
					camera.limit_left = int(global_position.x)
				if limit_right:
					camera.limit_right = int(global_position.x)
				if limit_top:
					camera.limit_top = int(global_position.y)
				if limit_bottom:
					camera.limit_bottom = int(global_position.y)
