import numpy as np
from fidimag.atomistic import Sim
from fidimag.common import CuboidMesh
from fidimag.atomistic import DMI, UniformExchange, Demag, Anisotropy
import fidimag.common.constant as const

np.random.seed(10000)

def mu_s(pos):
    x, y, z = pos
    x0, y0, r = 20, 20, 25

    if (x - x0)**2 + (y - y0)**2 <= r**2:
        return const.mu_s_1
    else:
        return 0

def init_m(pos):
    return 2*np.random.random(3)-1


def relax_system():

    mesh = CuboidMesh(nx=39, ny=11, nz=3, dx=0.5, dy=0.5, dz=0.5, unit_length=1e-9)

    sim = Sim(mesh, name='relax_skx')
    sim.driver.gamma=const.gamma

    sim.driver.alpha = 1.0

    sim.mu_s = mu_s

    sim.set_m(init_m)

    J = 50.0 * const.k_B
    exch = UniformExchange(J)
    sim.add(exch)

    D = 0.09 * J
    dmi = DMI(D)
    sim.add(dmi)

    K = 5e-3 * J
    anis = Anisotropy(K, axis=(0, 0, 1), name='Ku')
    sim.add(anis)

    demag = Demag()
    sim.add(demag)


    sim.relax(dt=1e-12, stopping_dmdt=0.1,
              max_steps=10, save_m_steps=100, save_vtk_steps=100)

    # np.save('m0.npy',sim.spin)

    fd = demag.compute_field(sim.spin)
    fe = exch.compute_field(sim.spin)
    fdmi = dmi.compute_field(sim.spin)
    fanis = anis.compute_field(sim.spin)
    np.savetxt("test_fields_atomistic.txt",np.transpose(
                        [np.concatenate((sim.mu_s, sim.mu_s, sim.mu_s, [0.0])),
                         np.concatenate((sim.spin,[0])),
                         np.concatenate((fd,[demag.compute_energy()])),
                         np.concatenate((fe,[exch.compute_energy()])),
                         np.concatenate((fdmi,[dmi.compute_energy()])),
                         np.concatenate((fanis,[anis.compute_energy()]))]),
              header="Generated by Fidimag. nx=72, ny=29, nz=3, dx=0.5e-9, dy=0.6e-9, dz=0.7e-9, mu_s=mu_s_1" +
              "J=50k_B  D/J=0.09,  Ku/J =5e*-3 axis=(0,0,1).\n  mu_s "+"".ljust(20)+  " m0 "+"".ljust(20)+"demag" +
              "".ljust(20)+"exch" + "".ljust(22)+"dmi" + "".ljust(22) + "anis")


if __name__ == '__main__':

    relax_system()
