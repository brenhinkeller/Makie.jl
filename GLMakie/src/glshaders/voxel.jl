@nospecialize
function draw_voxels(screen, main::VolumeTypes, data::Dict)
    geom = Rect2f(Point2f(-0.5), Vec2f(1.0))
    to_opengl_mesh!(data, const_lift(GeometryBasics.triangle_mesh, geom))
    shading = pop!(data, :shading, FastShading)
    @gen_defaults! data begin
        voxel_id = main => Texture
        instances = const_lift(t -> sum(size(t)) + 3, voxel_id)
        model = Mat4f(I)
        transparency = false
        backlight = 0f0
        color = nothing => Texture
        color_map = nothing => Texture
        shader = GLVisualizeShader(
            screen,
            "voxel.vert",
            "fragment_output.frag", "voxel.frag", "lighting.frag",
            view = Dict(
                "shading" => light_calc(shading),
                "MAX_LIGHTS" => "#define MAX_LIGHTS $(screen.config.max_lights)",
                "MAX_LIGHT_PARAMETERS" => "#define MAX_LIGHT_PARAMETERS $(screen.config.max_light_parameters)",
                "buffers" => output_buffers(screen, to_value(transparency)),
                "buffer_writes" => output_buffer_writes(screen, to_value(transparency))
            )
        )
    end

    return assemble_shader(data)
end
@specialize