extends Node2D

var damage_per_hit := 10
var hits_per_second := 5
var width := 0.1
var ray_count := 7
var ray_length := 1000.0

var use_mouse := true

@onready var particle_template := $ParticleEffect # Pre-made particle node

func _physics_process(delta):
    var direction = get_aim_direction()
    if direction == Vector2.ZERO:
        return

    var hits = cast_cone_rays(direction)

    draw_particle_beams(hits)


func get_aim_direction() -> Vector2:
    if use_mouse:
        return (get_global_mouse_position() - global_position).normalized()
    else:
        var input_vec = Vector2(
            Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
            Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
        )
        return input_vec.normalized()


func cast_cone_rays(direction: Vector2) -> Array:
    var space_state = get_world_2d().direct_space_state
    var results := []
    var unique_hits := {}

    var base_angle = direction.angle()

    for i in range(ray_count):
        var t = 0
        if ray_count > 1:
            t = float(i) / (ray_count - 1)
        else:
            t = 0.5
        var angle_offset = lerp(-width, width, t)
        var ray_dir = Vector2.from_angle(base_angle + angle_offset)

        var from = global_position
        var to = from + ray_dir * ray_length

        var query = PhysicsRayQueryParameters2D.create(from, to)
        query.collide_with_areas = true
        query.collide_with_bodies = true

        var result = space_state.intersect_ray(query)

        if result:
            var collider = result.get("collider")
            var position = result.get("position")

            if collider and not unique_hits.has(collider):
                unique_hits[collider] = position
                results.append({
                    "collider": collider,
                    "position": position
                })

    return results


func draw_particle_beams(hits: Array):
    # Clear old beams
    for child in get_children():
        if child.name.begins_with("Beam"):
            child.queue_free()

    for i in range(hits.size()):
        var hit = hits[i]
        var hit_pos: Vector2 = hit["position"]

        var beam = particle_template.duplicate()
        beam.name = "Beam_%d" % i
        add_child(beam)

        # Position at origin
        beam.global_position = global_position

        # Direction & length
        var dir = (hit_pos - global_position)
        var distance = dir.length()
        var angle = dir.angle()

        beam.rotation = angle

        # 🔥 IMPORTANT PART: stretch particles along the ray
        if beam.process_material:
            var mat = beam.process_material

            # Assuming a ParticleProcessMaterial
            if mat is ParticleProcessMaterial:
                mat.direction = Vector3(1, 0, 0) # Emit along X
                mat.initial_velocity_min = distance
                mat.initial_velocity_max = distance

        # Scale visually (fallback if material not used that way)
        beam.scale.x = distance / 100.0 # adjust depending on your texture

        beam.emitting = true