#!/bin/sh -l

set -eux  
# SECTION TO BE MODIFIED BY USER

machine=${1}
export expid1=$2
utente1=$3
cam_nlev1=$4
core1=$5
export expid2=$6
utente2=$7
cam_nlev2=$8
core2=$9
#
export startyear=${10}
export finalyear=${11}
export nyrsmean=${12}   #nyear-period for mean in timeseries
# select if you compare to model or obs 
export cmp2obs=${13}
export cmp2mod=${14}
export obsfile=${15}
export varmod=${16}
export PSfile=${17}
export Tfile=${18}
export auxfile=${19}
export pltype=${20}
here=${21}

export varobs
export expname1=${expid1}_${cam_nlev1}
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
export climobscld=1980-2019
export climobs=1979-2018
export iniclim=$startyear

#
export rootinpfileobs
export autoprec=True
user=$USER
    # model components
    # read arguments
echo 'Experiment : ' $expid1
echo 'Processing year(s) period : ' $startyear ' - ' $finalyear
#
opt=""
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

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$tmpdir1/plots
mkdir -p $pltdir
mkdir -p $pltdir/atm $pltdir/lnd $pltdir/ice $pltdir/ocn $pltdir/namelists

export units
export title


# here take PS and hyam
realm=cam
export sea
comp=atm
comppltdir=$pltdir/${comp}
mkdir -p $comppltdir
export modfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-$lasty.anncyc.nc
for sea in ANN DJF JJA 
do  
   export pltname=$comppltdir/$expid1.VS.$clim3d.zonalmean.$varmod.$iniclim-$lasty.$sea.png
   rsync -auv $here/plot_zonalmean_2plots_diff.ncl $tmpdir1/scripts/plot_zonalmean_2plots_diff.$varmod.ncl
   ncl $tmpdir1/scripts/plot_zonalmean_2plots_diff.$varmod.ncl
   if [[ $pltype == "x11" ]]
   then
      exit
   fi  
done

