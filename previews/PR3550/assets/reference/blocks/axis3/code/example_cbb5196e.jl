# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure(backgroundcolor = :gray97)
b = Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
translate!(b.blockscene, Vec3f(0,0,-10_000)) # move behind Axis3
Axis3(fig[1, 1], protrusions = 100, viewmode = :stretch,
    title = "protrusions = 100")
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_cbb5196e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_cbb5196e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_cbb5196e.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide