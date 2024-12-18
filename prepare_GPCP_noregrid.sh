#!/bin/sh -l
. /users_home/csp/sp2/SPS/CMCC-SPS3.5/src/templates/load_cdo
set -euvx
GPCPdir=/work/csp/sps-dev/scratch/ANTO
cd $GPCPdir
yyyy=1992
cdo selmon,12 -selyear,1992 precip.mon.mean.nc precip_199212.nc
for yyyy in {1993..2016}
do
   cdo selmon,1 -selyear,$yyyy precip.mon.mean.nc precip_${yyyy}01.nc
   cdo selmon,2 -selyear,$yyyy precip.mon.mean.nc precip_${yyyy}02.nc
   cdo selmon,12 -selyear,$yyyy precip.mon.mean.nc precip_${yyyy}12.nc
done
   
for yyyy in {1993..2016}
do
#   yyyym1=$(($yyyy - 1))
   cdo mergetime precip_${yyyy}01.nc precip_${yyyy}02.nc precip_${yyyy}12.nc precip_GPCP.DJFtmp.$yyyy.nc
   cdo timmean precip_GPCP.DJFtmp.$yyyy.nc precip_GPCP.DJF.$yyyy.nc
   rm precip_GPCP.DJFtmp.$yyyy.nc
done
cdo mergetime precip_GPCP.DJF.????.nc precip_GPCP.DJF.1993-2016.nc
