extends Node2D
class_name Bridge

@onready var line_2d: Line2D = $Line2D
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D

@export var max_health: float = 100.0

var grid_manager: GridManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grid_manager = get_node("/root/Main/GridManager")
	if not grid_manager:
		printerr("错误: 找不到GridManager")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# 设置桥梁段并将其注册到GridManager
func setup_segment(grid_pos: Vector2i):
	if not grid_manager:
		grid_manager = get_node("/root/Main/GridManager")

	if grid_manager:
		grid_manager.set_grid_occupied(grid_pos, self)
	else:
		printerr("无法注册桥梁段: 找不到GridManager")
