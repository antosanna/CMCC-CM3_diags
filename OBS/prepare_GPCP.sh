#!/bin/sh -l
GPCPdir=/work/csp/sp2/VALIDATION/monthly/precip
. /users_home/csp/sps-dev/CPS/CMCC-CPS1/src/utils/load_cdo
for yyyy in {1993..2016}
do
   yyyym1=$(($yyyy - 1))
   cdo mergetime precip_${yyyy}01.nc precip_${yyyy}02.nc precip_${yyyym1}12.nc precip_GPCP.DJF.$yyyy.nc
done
