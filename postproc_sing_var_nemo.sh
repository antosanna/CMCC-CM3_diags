#!/bin/sh -l
set -euvx  
machine=$1
expid1=$2
utente1=$3
core1=$4
#
expid2=$5
utente2=${6}
core2=${7}
#
startyear=${8}
finalyear=${9}
cmp2mod=${10}

here=${11}
var=${12}
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
export lasty=$finalyear
user=$utente1
    # model components
if [[ $cmp2mod -eq 1 ]]
then
   cmp2obs=0
   explist="$expid1 $expid2"
   export tmpdir2=$dirdiag/$utente2/$expid2/
   mkdir -p $tmpdir2
fi
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

allvars_oce="tos sos zos heatc saltc";
    
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

for yyyy in `seq -f "%04g" $startyear $finalyear`
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
           
   listaf+=" $ymfilevar"
done #loop on years
echo "your last year "$lasty
echo "your list of files "$listaf
         #serie di valori annui
ymeanfilevar=$tmpdir/${expid1}.$realm.$var.$startyear-$lasty.ymean.nc
if [[ ! -f $tmpdir/${expid1}_${freq}_${var}.$startyear.nc ]]
then
   continue
fi
if [[ ! -f $ymeanfilevar ]]
then
   cdo yearmean -mergetime $listaf $ymeanfilevar
fi
         #ciclo annuo
anncycfilevar=$tmpdir/${expid1}.$realm.$var.$startyear-$lasty.anncyc.nc
if [[ ! -f $anncycfilevar ]]
then
   cdo ymonmean -mergetime $listaf $anncycfilevar
fi
#now field mean
inpfile=$tmpdir/${expid1}.$comp.$var.$startyear-${lasty}.ymean.fldmean.nc
if [[ ! -f $inpfile ]]
then 
   head=`basename $ymeanfilevar|rev|cut -d '.' -f2-|rev`
   cdo -setctomiss,0 ${ymeanfilevar} $tmpdir/${head}_miss.nc
   cdo mul $tmpdir/${head}_miss.nc $tmpdir/tarea_surf_miss.nc $tmpdir/${head}_miss_wg.nc
   cdo fldsum $tmpdir/${head}_miss_wg.nc $tmpdir/${head}_sum_miss.nc
   cdo div $tmpdir/${head}_sum_miss.nc $tmpdir/tarea_surf_sum_miss.nc $inpfile
fi
