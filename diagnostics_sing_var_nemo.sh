#!/bin/sh -l
set -eux  
machine=$1
export expid1=$2
utente1=$3
core1=$4
export expid2=$5
utente2=$6
core2=$7
export startyear=$8
export finalyear=$9
export startyear_anncyc=${10} #starting year to compute 2d map climatology
export nyrsmean=${11}   #nyear-period for mean in timeseries
export cmp2obs=${12}
here=${13}
export varmod=${14}
do_timeseries=${15}
do_2d_plt=${16}
do_anncyc=${17}

#
export cmp2mod=1
if [[ $cmp2obs -eq 1 ]]
then
   export cmp2mod=0
fi

export mftom1=1
export varobs
export cmp2obstimeseries=0
#export expname1=${expid1}_${cam_nlev1}  inherited from main
#export expname2=${expid2}_${cam_nlev2}
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
comp=nemo
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
if [[ ! -f $tmpdir/${expid1}.$comp.$varmod.$startyear-${lasty}.ymean.nc ]]
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
export inpfile=$tmpdir/${expid1}.ocn.$varmod.$startyear-${lasty}.ymean.fldmean.nc
comppltdir=$pltdir/ocn
mkdir -p $comppltdir
export pltname=$comppltdir/${expid1}.ocn.$varmod.$startyear-${lasty}.TS_1
export hplot="0.3"
if [[ $do_timeseries -eq 1 ]]
then
      # do plot_timeseries
   rsync -auv plot_timeseries_xy_panel_nemo.ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
   ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
# now plot only land and only sea points means
fi #do_timeseries
export varobs
   # now 2d maps
if [[ $do_2d_plt -eq 1 ]]
then
   echo "---now plotting 2d $varmod"
   export inpfile=$tmpdir/${expid1}.$comp.$varmod.$iniclim-$lasty.anncyc.nc
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
     export pltname=$comppltdir/${expid1}.ocn.$varmod.map_${sea}.$iniclim-$lasty.png
     rsync -auv plot_2d_maps_and_diff_nemo.ncl $tmpdir1/scripts/plot_2d_maps_and_diff_nemo.$varmod.ncl
     ncl $tmpdir1/scripts/plot_2d_maps_and_diff_nemo.$varmod.ncl
     if [[ $pltype == "x11" ]]
     then
        exit
     fi  
   done
fi

exit 0
