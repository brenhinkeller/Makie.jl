#version 330 core
// {{GLSL_VERSION}}
// {{GLSL_EXTENSIONS}}

in vec2 vertices;

flat out vec3 o_normal;
out vec3 o_uvw;
flat out int o_side;
out vec2 o_tex_uv;

out vec3 o_camdir;
out vec3 o_world_pos;

uniform mat4 model;
uniform mat3 world_normalmatrix;
uniform mat4 projectionview;
uniform vec3 eyeposition;
uniform isampler3D voxel_id;
uniform float depth_shift;

const vec3 unit_vecs[3] = vec3[]( vec3(1, 0, 0), vec3(0, 1, 0), vec3(0, 0, 1) );
const mat2x3 orientations[3] = mat2x3[](
    mat2x3(0, 1, 0, 0, 0, 1), // xy -> _yz (x normal)
    mat2x3(1, 0, 0, 0, 0, 1), // xy -> x_z (y normal)
    mat2x3(1, 0, 0, 0, 1, 0)  // xy -> xy_ (z normal)
);

void main() {
    /* How this works:
    To simplify lets consider a 2d grid of pixel where the voxel surface would
    be the square outline of around a data point x.
        +---+---+---+
        | x | x | x |
        +---+---+---+
        | x | x | x |
        +---+---+---+
        | x | x | x |
        +---+---+---+
    Naively we would draw 4 lines for each point x, coloring them based on the
    data attached to x. This would result in 4 * N^2 lines with N^2 = number of
    pixels. We can do much better though by drawing a line for each column and
    row of pixels:
      1 +---+---+---+
        | x | x | x |
      2 +---+---+---+
        | x | x | x |
      3 +---+---+---+
        | x | x | x |
      4 +---+---+---+
        5   6   7   8
    This results in 2 * (N+1) lines. We can adjust the color of the line by
    sampling a Texture containing the information previously attached to vertices.

    Generalized to 3D voxels, lines become planes and the texture becomes 3D.
    We draw the planes through instancing. So first we will need to map the
    instance id to a dimension (xy, xz or yz plane) and an offset (in z, y or
    x direction respectively).
    Note that the render order of planes can make a significant impact on
    performance. It may be worth it to adjust this based on eyeposition.

    For now we alternate x, y, z planes and start from the center.
    */
    ivec3 size = textureSize(voxel_id, 0);
    int dim = 0, id = gl_InstanceID;
    if (gl_InstanceID > size.x + size.y + 1) {
        dim = 2;
        id = gl_InstanceID - (size.x + size.y + 2);
    } else if (gl_InstanceID > size.x) {
        dim = 1;
        id = gl_InstanceID - (size.x + 1);
    }

    // plane placement
    vec3 offset = 0.5 * vec3(size);
    vec3 displacement = (id - offset[dim]) * unit_vecs[dim];
    vec3 voxel_pos = size * (orientations[dim] * vertices) + displacement;
    vec4 world_pos = model * vec4(voxel_pos, 1.0f);
    o_world_pos = world_pos.xyz;
    gl_Position = projectionview * world_pos;
    gl_Position.z += gl_Position.w * depth_shift;

    // For each plane the normal is constant and its direction is given by the
    // `displacement` direction, i.e. `n = unit_vecs[dim]`. We just need to derive
    // whether it's +n or -n.
    // If we assume the viewer to be outside of a voxel, the normal direction
    // should always be facing them. Thus:
    vec3 n = world_normalmatrix * unit_vecs[dim];
    o_camdir = eyeposition - world_pos.xyz / world_pos.w;
    float normal_dir = sign(dot(o_camdir, n));
    o_normal = normalize(normal_dir * n);

    // The texture coordinate can also be derived. `voxel_pos` effectively gives
    // an integer index into the chunk, shifted to be centered. We can convert
    // this to a float index into the voxel_id texture by normalizing.
    // The minor ceveat here is that because planes are drawn between voxels we
    // would be sampling between voxels like this. To fix this we want to shift
    // the uvw coordinate to the relevant voxel center, which we can do using the
    // normal direction.
    // Here we want to shift in -normal direction to get a front face. Consider
    // this example with 1, 2 solid, 0 air and v the viewer:
    // | 1 | 2 | 0 |   v
    // If we shift in +normal direction (towards viewer) the planes would sample
    // from the id closer to the viewer, drawing a backface.
    o_uvw = (voxel_pos - 0.5 * o_normal) / size + 0.5;

    // normal in: -x -y -z +x +y +z direction
    o_side = dim + 3 * (1 + int(normal_dir));

    // map voxel_pos (-w/2 .. w/2 scale) back to 2d (scaled 0 .. w)
    // if the normal is negative invert range (w .. 0)
    o_tex_uv = transpose(orientations[dim]) * (normal_dir * voxel_pos + offset);

    // TODO:
    // - verify idx
}