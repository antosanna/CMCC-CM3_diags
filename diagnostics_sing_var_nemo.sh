#!/bin/sh -l
set -eux  
machine=$1
export expid1=$2
utente1=$3
cam_nlev1=$4
core1=$5
export expid2=$6
utente2=$7
cam_nlev2=$8
core2=$9
export startyear=${10}
export finalyear=${11}
export startyear_anncyc=${12} #starting year to compute 2d map climatology
export nyrsmean=${13}   #nyear-period for mean in timeseries
export cmp2obs=${14}
here=${15}
export varmod=${16}
do_timeseries=${17}
do_2d_plt=${18}
do_anncyc=${19}

#
export cmp2mod=1
if [[ $cmp2obs -eq 1 ]]
then
   export cmp2mod=0
fi

export mftom1=1
export varobs
export cmp2obstimeseries=0
export expname1=${expid1}_${cam_nlev1}
export expname2=${expid2}_${cam_nlev2}
dir_SE=$PWD/SPS3.5
dirdiag=/work/$DIVISION/$USER/diagnostics/
mkdir -p $dirdiag
if [[ $machine == "juno" ]]
then
   export dir_lsm=/work/csp/as34319/CMCC-SPS3.5/regrid_files/
   dir_obs1=/work/csp/as34319/obs
   dir_obs2=$dir_obs1/ERA5
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
   dir_obs5=/work/csp/as34319/obs
set +euvx  
   . $PWD/mload_ncl_juno
   . $PWD/mload_cdo_juno
   . $PWD/mload_nco_juno
set -euvx  
elif [[ $machine == "zeus" ]]
then
set +euvx  
   . $PWD/mload_cdo_zeus
   . $PWD/mload_nco_zeus
set -euvx  
   export dir_lsm=/work/csp/sps-dev/CESMDATAROOT/CMCC-SPS3.5/regrid_files/
   dir_obs1=/data/inputs/CESM/inputdata/cmip6/obs/
   dir_obs2=/data/delivery/csp/ecaccess/ERA5/monthly/025/
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
   dir_obs5=/work/csp/as34319/obs/
fi
export iniclim=$startyear

#
export rootinpfileobs
icelist=""
atmlist=""
lndlist=""
ocnlist=""
export lasty=$finalyear
    # model components
if [[ $cmp2obs -eq 1 ]]
then
   echo 'compare to obs'
   cmp2mod=0
   explist="$expid1"
fi
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

export pltype="png"
export units
export title
allvars_oce="tos sos zos heatc saltc";
    
tmpdir=$tmpdir1   #TMP
export srcGridName="/work/csp/as34319/ESMF/ORCA_SCRIP_gridT.nc"
export dstGridName="/work/csp/as34319/ESMF/World1deg_SCRIP_gridT.nc"
export wgtFile="/work/csp/as34319/ESMF/ORCA_2_World_SCRIP_gridT.nc"
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
outnml=$tmpdir1/nml
   # copy locally the namelists
mkdir -p $outnml
   
export cf=0
export mf=1
export mftom1=1
export cmp2obs_ncl=$cmp2obs
export units_from_here=0
export units
export name_from_here=0
case $varmod in 
   heatc)cmp2obs_ncl=0;units="J/m2*e-10";mftom1=10000000000.;export maxplot=25;export minplot=-5;export delta=2.5;units_from_here=1;;
   saltc)cmp2obs_ncl=0;units="PSU*kg/m2*e-7";mftom1=10000000;export maxplot=25;export minplot=0;export delta=2.5;units_from_here=1;;
   sos)varobs=var235;cf=0;units="PSU";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";cmp2obs_ncl=0;export title2="ERA5 $climobs";export maxplot=36.;export minplot=26.;export delta=2.;units_from_here=1;;
   zos)varobs=var235;cf=0;units="m";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";cmp2obs_ncl=0;export title2="ERA5 $climobs";export maxplot=3.;export minplot=-3.;export delta=0.5;units_from_here=1;;
   tos)varobs=SST;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;cmp2obs_ncl=1;;
esac
echo $units
if [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
then
   continue
fi
export yaxis
export title
export varmod2
export obsfile
export computedvar=""
export compute=0
export cmp2obs
# units only for vars that need conversion
export inpfile=$tmpdir/${expid1}.$comp.$varmod.$startyear-${lasty}.ymean.fldmean
comppltdir=$pltdir/${comp}
mkdir -p $comppltdir
export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear-${lasty}.TS_3
export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export bSH=0;export bland=0;export boce=0
export hplot="0.3"
export lat0; export lat1
if [[ $do_timeseries -eq 1 ]]
then
   for ts_gzm_boxes in Global NH SH 
   do
      case $ts_gzm_boxes in
         Global)lat0=-90;lat1=90;bglo=1;;
         NH)lat0=0;lat1=90;bNH=1;;
         SH)lat0=-90;lat1=0;bSH=1;;
      esac
      if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
      then  
         continue
      fi
      cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
   done
      # do plot_timeseries
   rsync -auv plot_timeseries_xy_panel.ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
   ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
   export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear-${lasty}.TS_5
   export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export bSH=0;export bland=0;export boce=0
   export hplot="0.15"
   for ts_gzm_boxes in 70N-90N 30N-70N 30S-30N 30S-70S 70S-90S
   do
      case $ts_gzm_boxes in
         70N-90N)lat0=70; lat1=90;b7090=1;;
         30N-70N)lat0=30; lat1=70;b3070=1;;
         30S-30N)lat0=-30;lat1=30;b3030=1;;
         30S-70S)lat0=-70; lat1=30;b3070S=1;;
         70S-90S)lat0=-90;lat1=-70;b7090S=1;;
      esac
      if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
      then  
         continue
      fi
      cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
    done
      # do plot_timeseries
    ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
# now plot only land and only sea points means
fi #do_timeseries
export varobs
comppltdir=$pltdir/${comp}
   # now 2d maps
if [[ $do_2d_plt -eq 1 ]]
then
   echo "---now plotting 2d $varmod"
   export inpfile=$tmpdir/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
   if [[ ! -f $inpfile ]]
   then
      continue
   fi
#units defined only where conversion needed
   export title1="$iniclim-$lasty"
   export right="[$units]"
   export left="$varmod"
   export sea
   for sea in ANN DJF JJA
   do
     export pltname=$comppltdir/${expid1}.$comp.$varmod.map_${sea}.png
     rsync -auv plot_2d_maps_and_diff_nemo.ncl $tmpdir1/scripts/plot_2d_maps_and_diff_nemo.$varmod.ncl
     ncl $tmpdir1/scripts/plot_2d_maps_and_diff_nemo.$varmod.ncl
     if [[ $pltype == "x11" ]]
     then
        exit
     fi  
   done
fi

exit 0