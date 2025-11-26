# GridManager.gd
extends Node2D

@export var grid_size: int = 64  # 每个网格的像素大小
@export var grid_width: int = 20 # 网格宽度（格子数）
@export var grid_height: int = 15 # 网格高度（格子数）

# 网格线可视化
var grid_lines: Array[Line2D] = []
var is_grid_visible: bool = false

func _ready():
    create_grid_visual()
    hide_grid()

func create_grid_visual():
    # 创建垂直线
    for x in range(grid_width + 1):
        var line = Line2D.new()
        line.width = 2
        line.default_color = Color(1, 1, 1, 0.3)
        line.add_point(Vector2(x * grid_size, 0))
        line.add_point(Vector2(x * grid_size, grid_height * grid_size))
        add_child(line)
        grid_lines.append(line)
    
    # 创建水平线
    for y in range(grid_height + 1):
        var line = Line2D.new()
        line.width = 2
        line.default_color = Color(1, 1, 1, 0.3)
        line.add_point(Vector2(0, y * grid_size))
        line.add_point(Vector2(grid_width * grid_size, y * grid_size))
        add_child(line)
        grid_lines.append(line)

func show_grid():
    for line in grid_lines:
        line.visible = true
    is_grid_visible = true

func hide_grid():
    for line in grid_lines:
        line.visible = false
    is_grid_visible = false

func toggle_grid():
    if is_grid_visible:
        hide_grid()
    else:
        show_grid()

# 世界坐标转换为网格坐标
func world_to_grid(world_pos: Vector2) -> Vector2i:
    var local_pos = to_local(world_pos)
    return Vector2i(
        floor(local_pos.x / grid_size),
        floor(local_pos.y / grid_size)
    )

# 网格坐标转换为世界坐标
func grid_to_world(grid_pos: Vector2i) -> Vector2:
    return Vector2(
        grid_pos.x * grid_size + grid_size / 2,
        grid_pos.y * grid_size + grid_size / 2
    )
