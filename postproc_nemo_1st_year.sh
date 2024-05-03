#!/bin/sh -l
set -euvx  
machine=juno
expid1=cm3_cam122_cpl2000-bgc_t11b
utente1=dp16116
core1=FV
#
#
startyear=0001

here=$PWD
i=1
dir_SE=$PWD/SPS3.5
dirdiag=/work/$DIVISION/$USER/diagnostics/
mkdir -p $dirdiag
if [[ $machine == "juno" ]]
then
set +euvx  
   . $PWD/mload_cdo_juno
set -euvx  
elif [[ $machine == "zeus" ]]
then
set +euvx  
   . $PWD/mload_cdo_zeus
set -euvx  
fi

#
export rootinpfileobs
user=$utente1
    # model components
tmpdir1=$dirdiag/$utente1/$expid1/
if [[ $core1 == "SE" ]]
then
   tmpdir1=$dirdiag/$utente1/$expid1/
fi
mkdir -p $tmpdir1
mkdir -p $tmpdir1/scripts

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$tmpdir1/plots
mkdir -p $pltdir
mkdir -p $pltdir/ocn $pltdir/namelists

#allvars_oce="tos sos zos heatc saltc";
var=zos
    
tmpdir=$tmpdir1   #TMP
if [ ! -f $tmpdir/tarea_surf_sum_miss.nc ]
then
     maskfile=/data/inputs/CESM/inputdata/ocn/nemo/tn0.25v3/grid/ORCA025L75_domain_cfg.nc
     cdo sellevidx,1 $maskfile $tmpdir/mesh_mask_surf.nc
     cdo expr,'area=(e1t*e2t*tmask)' $tmpdir/mesh_mask_surf.nc $tmpdir/tarea_surf.nc
     rm $tmpdir/mesh_mask_surf.nc
     cdo -setctomiss,0 $tmpdir/tarea_surf.nc $tmpdir/tarea_surf_miss.nc
     rm $tmpdir/tarea_surf.nc
     cdo fldsum $tmpdir/tarea_surf_miss.nc $tmpdir/tarea_surf_sum_miss.nc
fi
comp=ocn
ftype="grid_T"
freq="1m"
listaf=" "
opt=" "
echo "-----going to postproc variable $var"

for yyyy in  $startyear
do
   yfile=$tmpdir/${expid1}_${freq}_${yyyy}_${ftype}.nc
   ymfilevar=$tmpdir/${expid1}_${freq}_${var}.${yyyy}.nc
   if [[ ! -f $ymfilevar ]]
   then
      ret1=`ncdump -v $var ${yfile}|head -1`
      if [[ "$ret1" == "" ]]; then
         continue
      fi
      cdo $opt -selvar,$var $yfile $ymfilevar
   fi
           
done #loop on years
echo "your postprocessed year "$yyyy
         #serie di valori annui
inpfile=$tmpdir/${expid1}.$comp.$var.$yyyy.fldmean.nc
if [[ ! -f $inpfile ]]
then 
   head=`basename $ymfilevar|rev|cut -d '.' -f2-|rev`
   cdo -setctomiss,0 ${ymfilevar} $tmpdir/${head}_miss.nc
   cdo mul $tmpdir/${head}_miss.nc $tmpdir/tarea_surf_miss.nc $tmpdir/${head}_miss_wg.nc
   cdo fldsum $tmpdir/${head}_miss_wg.nc $tmpdir/${head}_sum_miss.nc
   cdo div $tmpdir/${head}_sum_miss.nc $tmpdir/tarea_surf_sum_miss.nc $inpfile
fi
