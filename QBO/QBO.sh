#!/bin/sh -l
#BSUB  -J QBO_diag
#BSUB  -q s_short
#BSUB  -o logs/QBO_diag.out.%J
#BSUB  -e logs/QBO_diag.err.%J  
#BSUB  -P 0566
#BSUB -R "rusage[mem=8000]"

. ../mload_cdo_juno
. ../mload_ncl_juno

set -uevx
#exp_name=hybrid_cam_hist1980_cm3_lndHIST_IC1980
#exp_name=hybrid_cam_hist1980_cm3_lndHIST_IC1980c
exp_name=cm3_cam122_cpl2000-bgc_t01
utente=dp16116
DIR_OUT="/work/csp/$USER/diagnostics/$utente/$exp_name/"
mkdir -p ${DIR_OUT}
export iniy=0001
export lasty=0018
listamerge=""
for yyyy in `seq -w $iniy $lasty`
do
   listamerge+=" $DIR_OUT/${exp_name}.cam.U.${yyyy}.nc"
done
if [[ ! -f $DIR_OUT/${exp_name}.cam.U.${iniy}-$lasty.nc ]]
then
   cdo -O mergetime ${listamerge} ${DIR_OUT}/${exp_name}.cam.U.${iniy}-$lasty.nc
fi
export infile=$DIR_OUT/${exp_name}.cam.QBO.${iniy}-$lasty.nc
if [[ ! -f $DIR_OUT/${exp_name}.cam.QBO.${iniy}-$lasty.nc ]]
then
   cdo -O fldmean -sellonlatbox,0,360,-2,2 ${DIR_OUT}/${exp_name}.cam.U.${iniy}-$lasty.nc $infile
fi
export pltname=QBO_${exp_name}.$iniy-$lasty
#export iniy=$(($iniy + 2000))
ncl plot_QBO_bw.ncl
echo "QBO done ${exp_name}.${iniy}-$lasty"|mail -a $pltname.png antonella.sanna@cmcc.it
echo "all done"
