#implement the Heun (Modified Euler) algorithm,
#https://en.wikipedia.org/wiki/Heun%27s_method

# k1 = f(t_n, y_n)
# k2 = f(t_n+1, y_n + h*k1)
# y_n+1 = y_n + 1/2*h*(k1+k2)

#To use this integrator, one needs to provide:
#   - A simulation instance with field "spin" and "prespin"
#   - A call back function

mutable struct ModifiedEuler <: Integrator
   t::Float64
   step::Float64
   nsteps::Int64
   k1::Array{Float64, 1}
   k2::Array{Float64, 1}
   rhs_fun::Function
end

function ModifiedEuler(nxyz::Int64, rhs_fun, step::Float64)
  k1 = zeros(Float64,3*nxyz)
  k2 = zeros(Float64,3*nxyz)
  return ModifiedEuler(0.0, step, 0, k1, k2, rhs_fun)
end

function advance_step(sim::AbstractSim, integrator::ModifiedEuler)
    h = integrator.step
    k1 =  integrator.k1
    k2 =  integrator.k2

    #compute k1
    integrator.rhs_fun(sim, k1, sim.spin, integrator.t)

    #compute k2
    sim.prespin .= sim.spin .+  h.*k1
    integrator.rhs_fun(sim, k2, sim.prespin, integrator.t+h)

    sim.prespin .= sim.spin
    sim.spin .+= (1/2*h) .* (k1 .+ k2)

    normalise(sim.spin, sim.nxyz)
    integrator.nsteps += 1
    integrator.t = integrator.nsteps*h

end
