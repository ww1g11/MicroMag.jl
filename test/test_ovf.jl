using JuMag
using Test

mesh = FDMesh(nx = 2, ny = 1, nz = 1, dx = 1e-9, dy = 1e-9, dz = 1e-9)
sim = Sim(mesh, name = "test_ovf1")
set_Ms(sim, 8.0e5)
init_m0(sim, (0.6,0.8,0))
save_ovf(sim, "test_ovf", dataformat = "binary")

JuMag.cuda_using_double(true)
sim = Sim(mesh, name = "test_ovf3")
set_Ms(sim, 8.0e5)
read_ovf("test_ovf",sim)
println(sim.spin)
@test sim.spin[1] == 0.6
@test sim.spin[2] == 0.8
@test sim.spin[3] == 0.0