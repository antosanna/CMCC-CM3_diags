#!/bin/sh -l
#BSUB  -J QBO_diag
#BSUB  -q s_short
#BSUB  -o logs/QBO_diag.out.%J
#BSUB  -e logs/QBO_diag.err.%J  
#BSUB  -P 0566
#BSUB -R "rusage[mem=8000]"

. ../mload_cdo_zeus
. ../mload_nco_zeus

set -uevx
export pltype=x11
exp_name=SPS3.5_2000_cont
utente=$USER
DIR_OUT="/work/csp/$USER/diagnostics/$utente/$exp_name/"
mkdir -p ${DIR_OUT}
export iniy=0019
export lasty=0040
listamerge=""
for var in U005 U010 U025 U050 U075 U100 U200 U250 U500 U700 U850
do
   if [[ ! -f $DIR_OUT/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.nc ]]
   then
      listamerge=""
      for yyyy in `seq -w $iniy $lasty`
      do
         listamerge+=" $DIR_OUT/${exp_name}.cam.$var.${yyyy}.reg1x1.nc"
      done
      cdo -O mergetime ${listamerge} ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.nc
      ncrename -h -O -v $var,U ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.nc ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.tmp.nc
      mv ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.tmp.nc ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.nc
   fi
      tmpfile=$DIR_OUT/${exp_name}.cam.QBO.$var.${iniy}-$lasty.reg1x1.nc
      if [[ ! -f $tmpfile ]]
      then
         cdo -O fldmean -sellonlatbox,0,360,-2,2 ${DIR_OUT}/${exp_name}.cam.$var.${iniy}-$lasty.reg1x1.nc $tmpfile
      fi
done
export infile=$DIR_OUT/${exp_name}.cam.QBO.${iniy}-$lasty.reg1x1.nc
if [[ ! -f $infile ]]
then
   ncecat ${DIR_OUT}/${exp_name}.cam.QBO.U???.${iniy}-$lasty.reg1x1.nc $infile
fi
export expname1=$exp_name
export pltname=QBO_${exp_name}.$iniy-$lasty
#export iniy=$(($iniy + 2000))
ncl plot_QBO_SPS3.5_bw.ncl
echo "QBO done ${exp_name}.${iniy}-$lasty"|mail -a $pltname.png antonella.sanna@cmcc.it
echo "all done"
