extends Line2D

export(int) var max_length = 60


func add_point_and_truncate(point: Vector2) -> void:
	self.add_point(point)
	if self.points.size() > max_length:
		self.remove_point(0)
