#!/bin/sh -l
export infileA="/work/csp/sps-dev/CESM2/archive/cm3_cam122d_1d32l_t11b/atm/hist/cm3_cam122d_1d32l_t11b.cam.h0." 
export infileL="/work/csp/sps-dev/CESM2/archive/cm3_cam122d_1d32l_t11b/lnd/hist/cm3_cam122d_1d32l_t11b.clm2.h0."
# this is necessary to use compute_total_mass_and_plot_with_IClnd.ncl 
#export infileL0="/work/csp/dp16116/CESM2/archive/cm3_lndHIST_t02e/lnd/hist/cm3_lndHIST_t02e.clm2.h0."

export infileO="/work/csp/sps-dev/CESM2/archive/cm3_cam122d_1d32l_t11b/ocn/hist/cm3_cam122d_1d32l_t11b_1m_" #0001${mm}01_0001${mm}??_scalar.nc` 
export infileI="/work/csp/sps-dev/CESM2/archive/cm3_cam122d_1d32l_t11b/ice/hist/cm3_cam122d_1d32l_t11b.cice.h." 

export nyears=7
export pltype="png"
export freq="monthly"
export freq="yearly"
export pltname="total_ocean_mass_and_ssh_cm3_cam122d_1d32l_t11b_${nyear}years_${freq}"
ncl compute_total_mass_and_plot.ncl 

