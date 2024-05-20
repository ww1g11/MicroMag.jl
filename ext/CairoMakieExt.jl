
module CairoMakieExt

using MicroMag
using Printf
using CairoMakie
using JLD2

#TODO: find a better sampling method
function calculate_sampling(nx::Int, step::Int)
    start = step > 1 ? (step ÷ 2) : 1
    num_samples = (nx - start) ÷ step + 1
    return start, step, num_samples
end

function calculate_start_step(nx::Int, n::Int)
    step = nx > n ? div(nx, n) : 1
    start = (nx - step * (n - 1)) ÷ 2 + 1
    if start <= 0
        start = 1
    end
    return start, step
end

"""
    MicroMag.plot_m(spin; dx=1.0, dy=1.0, k=1, component='z', arrows=(-1, -1), figsize=(500, -1), fig=nothing, ax=nothing, colorrange=[-1, 1])

Create a plot for the given magnetization.

# Arguments
- `spin::Array{Float64, 4}`: An array with dimensions (3, nx, ny, nz) representing the magnetization.

# Keyword Arguments
- `dx::Float64`: The spacing in the x-direction (default: 1.0).
- `dy::Float64`: The spacing in the y-direction (default: 1.0).
- `k::Int`: The layer index to plot (starting from 1) (default: 1).
- `component::Char`: The magnetization component to plot ('x', 'y', or 'z') (default: 'z').
- `arrows::Tuple{Int, Int}`: The number of arrows to plot, specified as a tuple. By default, arrows=(-1, -1), which auto-scales the number of arrows.
- `figsize::Tuple{Int, Int}`: The size of the figure, specified as a tuple (width, height). For example, figsize=(500, 400) or figsize=(500, -1) where -1 means auto-scaled height (default: (500, -1)).
- `fig`: An existing figure to plot on. If nothing, a new figure is created (default: nothing).
- `ax`: An existing axis to plot on. If nothing, a new axis is created (default: nothing).
- `colorrange`: The range of colors for the heatmap (default: nothing).

# Returns
- `fig`: The figure containing the plot.

# Examples
```julia
spin = randn(3, 10, 10, 5)  # Example spin data
# Creates a plot with default settings
MicroMag.plot_m(spin, colorrange=[-1, 1]) 

# Creates a plot for the x-component of the second layer with custom settings
MicroMag.plot_m(spin, dx=0.5, dy=0.5, k=2, component='x', arrows=(5, 5), figsize=(600, 400))
"""
function MicroMag.plot_m(spin; dx=1.0, dy=1.0, k=1, component='z', arrows=(-1, -1), figsize=(500, -1), fig=nothing, ax=nothing, colorrange=nothing)
    (_, nx, ny, nz) = size(spin)
    scale_factor = 10^floor(log10(dx))
    dx = dx / scale_factor
    dy = dy / scale_factor
    xs = [i * dx for i in 1:nx]
    ys = [j * dy for j in 1:ny]

    mx = spin[1, :, :, k]
    my = spin[2, :, :, k]
    mz = spin[3, :, :, k]
    lml = sqrt.(mx.^ 2 .+ my.^ 2 .+ mz.^2)
    mx[lml .< 0.1] .= NaN
    my[lml .< 0.1] .= NaN
    mz[lml .< 0.1] .= NaN

    size_x = figsize[1]
    size_y = figsize[2]
    if (size_y < 0)
        aspect_ratio = ny * dy / (nx * dx)
        size_y = Int(ceil(size_x * aspect_ratio))
    end

    max_arrows = 40

    arrow_nx = arrows[1]
    arrow_ny = arrows[2]

    if arrows[1] < 0 && arrows[2] > 0
        start_y, step_y = calculate_start_step(ny, arrow_ny)
        start_x, step_x, arrow_nx = calculate_sampling(nx, step_y)
    elseif arrows[1] > 0 && arrows[2] < 0
        start_x, step_x = calculate_start_step(nx, arrow_nx)
        start_y, step_y, arrow_ny = calculate_sampling(ny, step_x)
    elseif arrows[1] < 0 && arrows[2] < 0
        _, step_size = calculate_start_step(max(nx, ny), max_arrows)
        start_x, step_x, arrow_nx = calculate_sampling(nx, step_size)
        start_y, step_y, arrow_ny = calculate_sampling(ny, step_size)
    else
      start_y, step_y = calculate_start_step(ny, arrow_ny)
      start_y, step_y, arrow_ny = calculate_sampling(ny, step_y)
      start_x, step_x = calculate_start_step(nx, arrow_nx)
      start_x, step_x, arrow_nx = calculate_sampling(nx, step_x)
    end

    I = start_x .+ (0:(arrow_nx - 1)) .* step_x
    J = start_y .+ (0:(arrow_ny - 1)) .* step_y

    Dx = dx * step_x
    Dy = dy * step_y

    if fig === nothing
        fig = Figure(; size=(size_x, size_y), backgroundcolor=:white)
    end

    if ax == nothing
        ax = Axis(fig[1, 1]; width=size_x, height=size_y)
    end
    hidedecorations!(ax)
    
    if component == 'x'
      mm = mx
    elseif component == 'y'
      mm = my
    else
      mm = mz
    end

    #TODO: how to set automatic to colorrange???
    if colorrange == nothing
      heatmap!(ax, xs, ys, mm; alpha=0.5)
    else
      heatmap!(ax, xs, ys, mm; alpha=0.5, colorrange=colorrange)
    end
    #scatter!(ax, [(x, y) for x in xs for y in ys], color=:white, strokecolor=:black, strokewidth=0.5)

    lengthscale = 0.3 * sqrt(Dx^2 + Dy^2)
    #FIXME: it seems that align=:center does not work well for some situations?
    arrows!(ax, xs[I], ys[J], mx[I, J], my[I, J]; linewidth=2.0, color=:gray36,
            lengthscale=lengthscale, align=:center)

    return fig
end

"""
    MicroMag.plot_m(sim::MicroMag.AbstractSim; kwargs...)

Create a plot for the given magnetization in a simulation object.

# Arguments
- `sim::MicroMag.AbstractSim`: A simulation object containing the magnetization data and mesh information.

# Keyword Arguments
This function forwards all keyword arguments to `MicroMag.plot_m`. Refer to `MicroMag.plot_m` for detailed descriptions of the keyword arguments.

# Returns
- `fig`: The figure containing the plot.

# Examples
 
sim = MicroMag.create_simulation()  # Example simulation object
MicroMag.plot_m(sim)
# Creates a plot with default settings

MicroMag.plot_m(sim, k=2, component='x', arrows=(5, 5), figsize=(600, 400))
# Creates a plot for the x-component of the second layer with custom settings
"""
function MicroMag.plot_m(sim::MicroMag.AbstractSim; kwargs...)
    mesh = sim.mesh
    nx, ny, nz = mesh.nx, mesh.ny, mesh.nz
    m = Array(sim.spin)
    m = reshape(m, 3, nx, ny, nz)
    fig = plot_m(m; dx=mesh.dx, dy=mesh.dy, kwargs...)
    return fig
end

"""
  ovf2png(ovf_name, output=nothing; k=1, arrows=(-1, -1), figsize=(500, -1))

Create a png from the given ovf file.
`k` indicates the layer index (starting from 1) 
`arrows` is the number of arrows, should be a Tuple of integers. By default, arrows=(-1, -1).
`figsize` should be a Tuple of integers, for example, figsize=(500, 400) or figsize=(500, -1).
"""
function MicroMag.ovf2png(ovf_name, output=nothing; k=1, arrows=(-1, -1), figsize=(500, -1))
    if output === nothing
        output = endswith(ovf_name, ".ovf") ? ovf_name[1:(end - 4)] : ovf_name
    end
    ovf = read_ovf(ovf_name)
    spin = reshape(ovf.data, 3, ovf.xnodes, ovf.ynodes, ovf.znodes)
    fig = MicroMag.plot_m(spin; dx=ovf.xstepsize, dy=ovf.ystepsize, k=k, arrows=arrows,
                 figsize=figsize)
    save(output * ".png", fig)
    return fig
end

"""
  jdl2movie(jdl_file; framerate=12, output=nothing, kwargs...)

Create a moive from the given jdl2 file.

`output`` is the filename of the video and the support formats are 'mp4', 'avi' and 'gif'.
"""
function MicroMag.jdl2movie(jdl_file; framerate=12, output=nothing, figsize=(500, -1), kwargs...)
  if output===nothing
    base_name = jdl_file[1:length(jdl_file)-5]
    output = @sprintf("%s.mp4", base_name)
  end

  data = JLD2.load(jdl_file)
  steps = data["steps"]
  save_m_every = data["save_m_every"]
  nx, ny, nz = data["mesh/nx"], data["mesh/ny"], data["mesh/nz"]
  if save_m_every < 0
    @info @sprintf("save_m_every is %d, which is negative, exiting~", save_m_every)
    return
  end

  dx, dy, dz = data["mesh/dx"], data["mesh/dy"], data["mesh/dz"]

  size_x = figsize[1]
  size_y = figsize[2]
  if (size_y < 0)
      aspect_ratio = ny * dy / (nx * dx)
      size_y = Int(ceil(size_x * aspect_ratio))
  end

  fig = Figure(; size=(size_x, size_y), backgroundcolor=:white)

  ax = Axis(fig[1, 1]; width=size_x, height=size_y)
  hidedecorations!(ax)

  function update_function(i)
    index = @sprintf("m/%d", i)
    m = reshape(data[index], 3, nx, ny, nz)
    plot_m(m; dx=dx, dy=dy, fig=fig, ax=ax, kwargs...)
  end

  record(update_function, fig, output, 0:save_m_every:steps; framerate = framerate)
end

end
