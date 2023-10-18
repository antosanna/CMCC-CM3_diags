#!/bin/sh -l

#ALBEDO=(FSUTOA)/SOLIN  [ con SOLIN=FSUTOA+FSNTOA]
#https://atmos.uw.edu/~jtwedt/GeoEng/CAM_Diagnostics/rcp8_5GHGrem-b40.20th.track1.1deg.006/set5_6/set5_ANN_FLNT_c.png

set -eux  
# SECTION TO BE MODIFIED BY USER
machine=$1

# model to diagnose
export expid1=$2
utente1=$3
cam_nlev1=$4
core1=$5
#
# second model to compare with
export expid2=$6
utente2=$7
cam_nlev2=$8
core2=$9
#
export startyear=${10}
export finalyear=${11}
export startyear_anncyc=${12} #starting year to compute 2d map climatology
export nyrsmean=20   #nyear-period for mean in timeseries
# select if you compare to model or obs 
export cmp2obs=${13}
export cmp2mod=${14}
export pltype=${15}
export var=${16}
export comp=${17}
export do_timeseries=${18}
export do_znl_lnd=${19}
export do_znl_atm2d=${20}
export do_2d_plt=${21}
export do_anncyc=${22}
export do_atm=${23}
export do_lnd=${24}
export do_ice=${25}
# END SECTION TO BE MODIFIED BY USER

export mftom1=1
export varobs
export cmp2obstimeseries=0
i=1
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
export climobscld=1980-2019
export climobs=1979-2018
export iniclim=$startyear

#
export rootinpfileobs
icelist=""
atmlist=""
lndlist=""
ocnlist=""
export lasty=$finalyear
export autoprec=True
user=$USER
    # model components
comps=""
if [[ $do_atm -eq 1 ]]
then
    comps="atm"
fi
if [[ $do_ice -eq 1 ]]
then
    comps+=" ice"
fi
if [[ $do_lnd -eq 1 ]]
then
    comps+=" lnd"
fi
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
    
for exp in $explist
do
   case $exp in
      $expid1)utente=$utente1;core=$core1 ;;
      $expid2)utente=$utente2;core=$core2 ;;
   esac
   model=CMCC-CM3
   if [[ $machine == "zeus" ]]
   then
       model=CESM2
      if [[ $utente == "dp16116" ]]
      then 
         model=CMCC-CM
      fi   
      if [[ $core == "SE" ]]
      then
         model=CESM
      fi
      rundir=/work/$DIVISION/$utente/$model/$exp/run
      export inpdirroot=/work/csp/$utente/$model/archive/$exp
      if [[ $utente == "dp16116" ]]
      then
         export inpdirroot=/work/csp/$utente/CESM2/archive/$exp
      fi
   else
      rundir=/work/$DIVISION/$utente/CMCC-CM/$exp/run
      export inpdirroot=/work/csp/$utente/CMCC-CM/archive/$exp
   fi
   export tmpdir=$dirdiag/$utente/$exp/
   mkdir -p $tmpdir
   var2plot=" "
   for comp in $comp
   do
      case $comp in
         atm)typelist="h0";; 
         lnd)typelist="h0";; 
         ice)typelist="h";; 
      esac
      for ftype in $typelist
      do
         echo "-----going to postproc $comp"
         case $comp in
   # ALBEDOC
            atm) realm=cam;;
            lnd) realm=clm2;;
            ice) realm=cice;;
         esac
         inpdir=$inpdirroot/$comp/hist
         
         case $var in
             TSOI) opt="-sellevidx,8";;     # select a specific value
             H2OSOI) opt="-sellevidx,10";;     # select a specific value
             *) opt="";opt1="";;
         esac
         listaf=" "
         listaf_anncyc=" "
         echo "-----going to postproc variable $var"
         for yyyy in `seq -f "%04g" $startyear $lasty`
         do
            yfile=$tmpdir/${exp}.$realm.$ftype.$yyyy.nc
            echo "-----going to produce $yfile"
            if [[ ! -f $yfile ]]
            then
               echo "yearly file $yfile not produced "
               break
            fi 
            ymfilevar=$tmpdir/${exp}.$realm.$var.$yyyy.nc
            if [[ ! -f $ymfilevar ]]
            then
   # SECTION VARIABLES TO BE  COMPUTED
               if [[ $var == "SOLIN" ]]
               then
         #check if var is present
                  ret1=`ncdump -v FSUTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then 
                     continue
                  fi   
                  ret1=`ncdump -v FSNTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then 
                     continue
                  fi   
                  cdo $opt -select,name=FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'SOLIN=FSUTOA+FSNTOA' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               elif [[ $var == "EnBalSrf" ]]
               then
                  if [[ ! -f $tmpdir/${exp}.lsm.nc ]]
                  then
                     echo "comp " $comp
                     echo "realm " $realm
                     cdo selvar,LANDFRAC $yfile $tmpdir/${exp}.lsm.tmp.nc
                     cdo -expr,'LANDFRAC = ((LANDFRAC>=0.5)) ? 1.0 : LANDFRAC/0.0' $tmpdir/${exp}.lsm.tmp.nc $tmpdir/${exp}.lsm.nc
                  fi
                  ret1=`ncdump -v FSNS ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FLNS ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v SHFLX ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v LHFLX ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=FSNS,FLNS,LHFLX,SHFLX $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'EnBalSrf=FSNS-FLNS-SHFLX-LHFLX' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc 
                  cdo mul $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc $tmpdir/${exp}.lsm.nc $ymfilevar
               elif [[ $var == "ALBEDO" ]]
               then
                  ret1=`ncdump -v FSUTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FSNTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'ALBEDO=FSUTOA/(FSNTOA+FSUTOA)' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               elif [[ $var == "ALBEDOS" ]]
               then
                  ret1=`ncdump -v FSDS ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FSNS ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=FSDS,FSNS $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'ALBEDOS=(FSDS-FSNS)/FSDS' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               elif [[ $var == "ALBEDOC" ]]
               then
                  ret1=`ncdump -v FSUTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FSNTOA ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FSNTOAC ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=FSNTOAC,FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'ALBEDOC=(FSNTOA+FSUTOA-FSNTOAC)/(FSNTOA+FSUTOA)' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               elif [[ $var == "RESTOM" ]]
               then
   #RESTOM=FSNT-FLNT
                  ret1=`ncdump -v FSNT ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  ret1=`ncdump -v FLNT ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=FSNT,FLNT $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'RESTOM=FSNT-FLNT' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               elif [[ $var == "EmP" ]]
               then
                  ret1=`ncdump -v QFLX ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -select,name=QFLX,PRECT $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                  cdo expr,'EmP=QFLX/1000-PRECT' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
               else
                  ret1=`ncdump -v $var ${yfile}|head -1`
                  if [[ "$ret1" == "" ]]; then
                     continue
                  fi
                  cdo $opt -selvar,$var $yfile $ymfilevar
               fi
               if [[ -f $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc ]]
               then
                  rm -f $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc 
               fi
               if [[ -f $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc ]]
               then
                  rm -f $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
               fi
            fi
           
            listaf+=" $ymfilevar"
            if [[ $((10#$yyyy)) -ge $((10#$startyear_anncyc)) ]]
            then
               listaf_anncyc+=" $ymfilevar"
            fi
            export lasty=$yyyy
            export finalyear=$lasty
         done #loop on years
         echo "your last year "$lasty
         echo "your list of files "$listaf
         #serie di valori annui
         ymeanfilevar=$tmpdir/${exp}.$realm.$var.$startyear-$lasty.ymean.nc
         if [[ ! -f $tmpdir/${exp}.$realm.$var.$startyear.nc ]]
         then
            continue
         fi
         if [[ ! -f $ymeanfilevar ]]
         then
            cdo yearmean -mergetime $listaf $ymeanfilevar
         fi
         #ciclo annuo
         anncycfilevar=$tmpdir/${exp}.$realm.$var.$startyear_anncyc-$lasty.anncyc.nc
         cdo ymonmean -mergetime $listaf_anncyc $anncycfilevar
      done
   done
   finalyearplot[$i]=$lasty
   i=$(($i + 1))
done #expid
export tmpdir=$tmpdir1
outnml=$tmpdir1/nml
   # copy locally the namelists
mkdir -p $outnml
if [[  `ls $rundir/namelist* |wc -l` -gt 0 ]]
then
         rsync -auv $rundir/namelist* $outnml
fi
if [[  `ls $rundir/file_def*xml |wc -l` -gt 0 ]]
then
         rsync -auv $rundir/file_def*xml  $outnml
fi
   
export varmod=$var
   
units=""
export units_from_here=0
export name_from_here=0
if [[ $varmod == "PS" ]] || [[ $varmod == "T" ]] || [[ $varmod == "Z3" ]]|| [[ $varmod == "U" ]] || [[ $varmod == "V" ]]
then
            continue
fi 
if [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
then
            continue
fi
if [[ $comp == "atm" ]]
then
             atmlist+=" \"$varmod\","
elif [[ $comp == "lnd" ]]
then
             lndlist+=" \"$varmod\","
elif [[ $comp == "ice" ]]
then
             icelist+=" \"$varmod\","
fi
export cf=0
export mf=1
export yaxis
export title=""
export title2=""
export units=""
export varmod2=""
export ncl_plev=0
export obsfile
export computedvar=""
export compute=0
export cmp2obs=1
if [[ $cmp2mod -eq 1 ]]
then
   export modfile=$tmpdir2/${expid2}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
   cmp2obs=0
fi
export ncl_lev=0
export cmp2mod_ncl
export cmp2obs_ncl
export delta
export deltadiff
export maxplot
export minplot
export maxplotdiff
export minplotdiff
export cmp2obs_anncyc=$cmp2obs
case $varmod in
   ALBEDO)units="fraction";export maxplot=0.9;export minplot=0.1;delta=0.1;title="Albedo";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;cmp2obs_anncyc=0;export maxplotdiff=0.3;export minplotdiff=-0.3;deltadiff=.03;;
   ALBEDOS)varobs=albedos;units="fraction";export maxplot=0.9;export minplot=0.1;delta=0.1;title="Surf Albedo";units_from_here=1;name_from_here=1;export maxplotdiff=0.3;export minplotdiff=-0.3;deltadiff=.03;obsfile="$dir_obs3/albedos_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   ALBEDOC)units="fraction";export maxplot=0.9;export minplot=0.1;delta=0.1;title="Albedo Clear Sky";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   AODVIS)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;;
   BURDEN1)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;delta=0.5;;
   BURDEN2)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;delta=0.01;;
   BURDEN3)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;delta=0.5;;
   BURDEN4)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;delta=0.1;;
   BURDENBC)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;delta=0.1;;
   BURDENdn1)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;delta=0.5;;
   BURDENdn2)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;delta=0.01;;
   BURDENdn3)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;delta=0.5;;
   BURDENdn4)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;delta=0.1;;
   BURDENDUST)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;delta=0.2;;
   BURDENPOM)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;delta=0.1;;
   BURDENSEASALT)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;delta=0.5;;
   BURDENSO4)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;delta=0.2;;
   BURDENSOA)cmp2mod_ncl=0;cmp2obs_ncl=0;cmp2obs_anncyc=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;delta=0.1;;
   CLDHGH)varobs=var188;export maxplot=0.9;export minplot=0.1;delta=.1;title="High-level cloud 50-400hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldhgh_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=$cmp2obs;;
   CLDLIQ)varobs=var186;export maxplot=0.001;export minplot=0.;delta=.0001;title="Liquid water cloud content";units_from_here=1;units="kg/kg";name_from_here=1;export maxplotdiff=0.0001;export minplotdiff=-0.0001;deltadiff=.00001;obsfile="$dir_obs2/cldlow_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2obs_ncl=0;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;;
   CLDICE)varobs=var186;export maxplot=0.0001;export minplot=0.;delta=.00001;title="Ice water cloud content";units_from_here=1;units="kg/kg";name_from_here=1;export maxplotdiff=0.00001;export minplotdiff=-0.00001;deltadiff=.000001;obsfile="$dir_obs2/cldlow_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2obs_ncl=0;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;;
   CLDLOW)varobs=var186;export maxplot=0.9;export minplot=0.1;delta=.1;title="Low-level cloud 700-1200hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=0.6;export minplotdiff=-0.6;deltadiff=.1;obsfile="$dir_obs2/cldlow_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=$cmp2obs;cmp2mod_ncl=$cmp2mod;;
   CLDMED)varobs=var187;export maxplot=0.9;export minplot=0.1;delta=.1;title="Mid-level cloud 400-700hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldmed_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;cmp2obs_anncyc=$cmp2obs;;
   CLDTOT)varobs=var164;export maxplot=0.9;export minplot=0.1;delta=.1;title="Total cloud cover";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;deltadiff=.1;obsfile="$dir_obs2/cldtot_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   EmP)varobs=var167;mf=86400000;units="mm/d";export maxplot=10.;export minplot=-10.;delta=2.;title="Evaporation - Precipitation";units_from_here=1;name_from_here=1;cmp2obs_anncyc=0;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;export maxplotdiff=3.;export minplotdiff=-3.;deltadiff=.5;;
   EnBalSrf)varobs=ftot;units="W/m2";export maxplot=20.;export minplot=-20.;delta=2.;title="Surface Radiative Balance";name_from_here=1;units_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;export cmp2obs_ncl=$cmp2obs;obsfile="$dir_obs3/ftot_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
   FLUT)varobs=FLUT;export maxplot=300;export minplot=120;delta=20.;export maxplotdiff=40;export minplotdiff=-40;deltadiff=10.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up lw Top of Model";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FSH)varobs=var167;export maxplot=100.;export minplot=-100.;delta=10.;title="Sensible Heat";units_from_here=1;name_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
   H2OSOI) title="Volumetric Soil Water at 1.36m";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   ICEFRAC)cf=0;units="frac";obsfile="";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;cmp2obs_anncyc=0;title2="ERA5 $climobs";export maxplot=0.95;export minplot=0.15;delta=.05;units_from_here=0; title="Sea-Ice Fraction";name_from_here=1;minplotdiff=-0.5;maxplotdiff=0.5;deltadiff=0.05;;
   H2OSNO)varobs=sd; title="Snow Depth (liquid water)";varobs=var167;mf=0.01;export maxplot=10;export minplot=0.5;delta=0.5;units_from_here=1;units="m";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   TGCLDCWP)varobs=T2M;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=0.25;export minplot=0;delta=.05;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;cmp2obs_anncyc=0.;maxplotdiff=0.05;minplotdiff=-0.05;deltadiff=0.005;;
   TGCLDIWP)varobs=T2M;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=0.07;export minplot=0;delta=.001;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;cmp2obs_anncyc=0;maxplotdiff=0.008;minplotdiff=-0.008;deltadiff=0.001;;
   TGCLDLWP)varobs=T2M;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=0.25;export minplot=0;delta=.05;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;cmp2obs_anncyc=0;maxplotdiff=0.05;minplotdiff=-0.05;deltadiff=0.005;;
   TREFHT)varobs=T2M;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   U010)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=1;export cmp2obs_ncl=$cmp2obs;;
   U100)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   U200)varobs=U;units="m/s";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   U700)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;deltadiff=2.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z010)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=31600.;export minplot=28800;delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;deltadiff=20.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z100)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=16800.;export minplot=15000;delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;deltadiff=20.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z500)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=3;title2="ERA5 $climobs";export maxplot=5900.;export minplot=4800;delta=100;units_from_here=1;export maxplotdiff=50;export minplotdiff=-50;deltadiff=5.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z700)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=3200.;export minplot=2600;delta=100;units_from_here=1;export maxplotdiff=100;export minplotdiff=-100;deltadiff=20.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   Z850)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=5;title2="ERA5 $climobs";export maxplot=1550.;export minplot=1050.;delta=50;units_from_here=1;export maxplotdiff=50.;export minplotdiff=-50;deltadiff=5.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=$cmp2obs;;
   TS)varobs=var235;cf=-273.15;units="Celsius deg";obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;delta=4;units_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
#   TS)varobs=SST;cf=-273.15;units="Celsius deg";export maxplot=36;export minplot=-20;delta=2.;units_from_here=1;obsfile=$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc;export cmp2obs=1;export title2="ERA5 $climobs";;
   PRECT)varobs=precip;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;delta=2.;export maxplotdiff=5.;export minplotdiff=-5.;deltadiff=1.;obsfile="$dir_obs5/gpcp_1979-2015_1deg_anncyc.nc";export title2="GPCP 1979-2015";title="Total precipitation";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   PRECC)varobs=var167;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;delta=2.;title="Convective precipitation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;;
   PSL)varobs=MSL;mf=0.01;units="hPa";export maxplot=1030;export minplot=990;delta=4.;export maxplotdiff=8;export minplotdiff=-8;deltadiff=2.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   QFLX)varobs=var167;mf=1000000;units="10^-6 kgm-2s-1";export maxplot=100.;export minplot=0.;delta=10.;title="Surface Water Flux";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;export maxplotdiff=10.;export minplotdiff=-10.;deltadiff=1.;;
   RESTOM)varobs=var167;export maxplot=100.;export minplot=-100.;delta=25.;units="W/m2";title="Residual energy Top of the Model";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;export maxplotdiff=20.;export minplotdiff=-20.;deltadiff=2.5;;
   SOLIN)varobs=var167;units="W/m2";export maxplot=450;export minplot=60;delta=30.;title="Insolation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;maxplotdiff=0.00005;export minplotdiff=-0.00005;deltadiff=.00001;;
   FLDS)varobs=var175;export maxplot=400;export minplot=100;delta=50.;name_from_here=1;title="Down lw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/strd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FLNT)varobs=var179;export maxplot=310;export minplot=115;delta=15.;name_from_here=1;title="Net lw Top of Model";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/tntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld" ;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FLNSC)varobs=var167;export maxplot=300;export minplot=120;delta=20.;name_from_here=1;title="Net clear-sky lw Top of Model";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   FLUTC)varobs=FLUTC;export maxplot=300;export minplot=120;delta=20.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up clear-sky lw Top of Model";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;minplotdiff=-8.;maxplotdiff=8;deltadiff=1;;
   FSDS)varobs=var169;export maxplot=300;export minplot=25;delta=25.;name_from_here=1;title="Downward sw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FSNS)varobs=var176;export maxplot=300;export minplot=25;delta=25.;name_from_here=1;title="Net sw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/snsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FSNSC)varobs=var167;export maxplot=300;export minplot=25;delta=25.;name_from_here=1;title="Net sw clear-sky surface";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   FSNTOA)varobs=var178;export maxplot=420;export minplot=30;delta=30.;name_from_here=1;title="Net sw Top of the Atmosphere";export maxplotdiff=40;export minplotdiff=-40;deltadiff=10.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FSNT)varobs=var178;export maxplot=420;export minplot=30;delta=30.;name_from_here=1;title="Net sw Top of Model";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   FLNS)varobs=var177;export maxplot=200.;export minplot=0.;delta=20.;name_from_here=1;title="Net lw surface";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/sntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   LHFLX)varobs=var147;export maxplot=300;export minplot=-20;delta=20.;name_from_here=1;title="Latent Heat Flux";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/slhf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   LWCF)varobs=LWCF;export maxplot=80;export minplot=0;delta=10.;name_from_here=1;title="Long Wave Cloud Forcing";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   SHFLX)varobs=var146;export maxplot=300;export minplot=-20;delta=20.;name_from_here=1;title="Sensible Heat Flux";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs3/sshf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
   SWCF)varobs=SWCF;export maxplot=40;export minplot=-100;delta=20.;name_from_here=1;title="Short Wave Cloud Forcing";export maxplotdiff=20;export minplotdiff=-20;deltadiff=5.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;

   SNOW) title="Atmospheric Snow";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   SNOWDP)title="Snow Depth ";varobs=sd;export maxplot=3.;export minplot=0.1;delta=.1;units_from_here=1;name_from_here=1;units="m";obsfile="$dir_obs1/ERA5T/sd/sd_1993-2017.ymean.nc";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;maxplotdiff=5;minplotdiff=-5;deltadiff=1;;
   TWS) title="Total Water Storage";cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   TSOI) title="Soil Temp at 80cm";name_from_here=1;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   TLAI)varobs=var167;export maxplot=11.;export minplot=1.;delta=1.;cmp2mod_ncl=$cmp2mod;cmp2obs_anncyc=0;export cmp2obs_ncl=0;;
   QOVER)title="Total Surface Runoff";export maxplot=0.0003;export minplot=0.;delta=.00005;name_from_here=1;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
   *)title="";delta=0.;name_from_here=0;cmp2obs_anncyc=0;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
esac
#            export taxis="$varmod $units"
export inpfile=$tmpdir1/${expid1}.$comp.$varmod.$startyear-${lasty}.ymean.fldmean
comppltdir=$pltdir/${comp}
mkdir -p $comppltdir
export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear-${lasty}.TS_3
export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export SH=0;export bland=0;export boce=0
export hplot="0.3"
if [[ $do_timeseries -eq 1 ]]
then
			for ts_gzm_boxes in Global NH SH 
			do
#               inpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$ts_gzm_boxes.nc
#               echo "obs to compare timeseries " $inpfileobs
#               rootinpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`
       case $ts_gzm_boxes in
          Global)export lat0=-90;export lat1=90;export bglo=1;;
          NH)export lat0=0;export lat1=90;export bNH=1;;
          SH)export lat0=-90;export lat1=0;export bSH=1;;
       esac
#               if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
#               then  
#                  continue
#               fi
       if [[ $core == "SE" ]]
       then
          export srcFileName=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc 
          export outfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc 
          if [[ ! -f $outfile ]]
          then
             ncl $dir_SE/regridSE_CAMh0.ncl
          fi
          cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $outfile $inpfile.$ts_gzm_boxes.nc
       else
          cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
       fi
#               if [[ ! -f $inpfileobs ]]
#               then
#                  cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $obsfile $inpfileobs
#               fi
    done
      # do plot_timeseries
    cp plot_timeseries_xy_panel.ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
    ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
    if [[ $pltype == "x11" ]]
    then
       exit
    fi  
    export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear-${lasty}.TS_5
    export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export bSH=0;export bland=0;export boce=0
    export hplot="0.15"
    for ts_gzm_boxes in 70N-90N 30N-70N 30S-30N 30S-70S 70S-90S
    do
       case $ts_gzm_boxes in
          70N-90N)export lat0=70; export lat1=90;export b7090=1;;
          30N-70N)export lat0=30; export lat1=70;export b3070=1;;
          30S-30N)export lat0=-30;export lat1=30;export b3030=1;;
          30S-70S)export lat0=-70; export lat1=30;export b3070S=1;;
          70S-90S)export lat0=-90;export lat1=-70;export b7090S=1;;
       esac
       if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [ ! -f $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc -a ! -f $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc ]
       then  
          continue
       fi
       if [[ $core == "SE" ]]
       then
          export srcFileName=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc 
          export outfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc 
          if [[ ! -f $outfile ]]
          then
             ncl $dir_SE/regridSE_CAMh0.ncl
          fi
          cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $outfile $inpfile.$ts_gzm_boxes.nc
       else
          cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
       fi
     done
      # do plot_timeseries
     ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
    if [[ $realm == "cam" ]]
    then
       if [[ $core == "SE" ]]
       then
          lsmfile=/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc
       else
          lsmfile=$tmpdir1/${expid1}.lsm.nc
          if [[ ! -f $lsmfile ]]
          then
             yfile=$tmpdir1/${expid1}.$realm.$ftype.$yyyy.nc
            echo "comp " $comp
            echo "realm " $realm
             cdo selvar,LANDFRAC $yfile $tmpdir1/${expid1}.lsm.tmp.nc
             cdo -expr,'LANDFRAC = ((LANDFRAC>=0.5)) ? 1.0 : LANDFRAC/0.0' $tmpdir1/${expid1}.lsm.tmp.nc $tmpdir1/${expid1}.lsm.nc
          fi
       fi
       slmfile=$tmpdir1/$expid1.slm.nc
       if [[ ! -f $slmfile ]]
       then
          yfile=$tmpdir1/${expid1}.$realm.$ftype.$yyyy.nc
          if [[ $core == "SE" ]]
          then
             echo "comp " $comp
             echo "realm " $realm
             echo "yfile " $yfile
             cdo -expr,'LANDFRAC = (( LANDFRAC==0.0)) ? 2.0: 1.0' /work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc $tmpdir1/$expid1.tmpslm.nc
             cdo -expr,'LANDFRAC = (( LANDFRAC==2.0)) ? 1.0: 0.0' $tmpdir1/$expid1.tmpslm.nc $slmfile
             rm $tmpdir/$expid1.tmpslm.nc
          else
             echo "comp " $comp
             echo "realm " $realm
             cdo selvar,LANDFRAC $yfile $tmpdir1/${expid1}.lsm.tmp.nc
             cdo -expr,'LANDFRAC = ((LANDFRAC<0.5)) ? 1.0 : LANDFRAC/0.0' $tmpdir1/${expid1}.lsm.tmp.nc $slmfile
          fi #for core=FV
       fi   #slmfile
# now plot only land and only sea points means
       if [[ $core == "SE" ]]
       then 
          cdo -setctomiss,0 -mul -selname,$varmod $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc -selname,LANDFRAC $lsmfile $tmpdir1/$expid1.$realm.$varmod.$startyear-${lasty}.ymean.land.nc
       else
          cdo -mul $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $lsmfile $tmpdir1/$expid1.$realm.$varmod.$startyear-${lasty}.ymean.land.nc
       fi
       cdo fldmean $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.land.nc $inpfile.land.nc
       if [[ $core == "SE" ]]
       then 
          cdo -mul $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc $tmpdir1/${expid1}.slm.nc $tmpdir1/$expid1.$realm.$varmod.$startyear-${lasty}.ymean.oce.nc
       else
          cdo -mul $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $tmpdir1/${expid1}.slm.nc $tmpdir1/$expid1.$realm.$varmod.$startyear-${lasty}.ymean.oce.nc
       fi
       cdo fldmean $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.oce.nc $inpfile.oce.nc
       export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear-${lasty}.TS_2
       export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export bSH=0; export bland=1;export boce=1
       export hplot="0.4"
       ncl $tmpdir1/scripts/plot_timeseries_xy_panel.$varmod.ncl
    fi
fi #do_timeseries
export varobs
comppltdir=$pltdir/${comp}
   # now 2d maps
if [[ $do_2d_plt -eq 1 ]]
then
   if [[ $comp == "ice" ]]
   then
      continue
   fi
   echo "---now plotting 2d $varmod"
   if [[ $core == "FV" ]]
   then
      export inpfile=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
   else
      export srcFileName=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
      export outfile=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.reg1x1.nc
      if [[ ! -f $outfile ]]
      then
         ncl $dir_SE/regridSE_CAMh0.ncl
      fi
      export inpfile=$outfile
   fi
   if [[ ! -f $inpfile ]]
   then
      continue
   fi
#units defined only where conversion needed
   if [[ $cmp2mod -eq 1 ]]
   then
      export title2mod="$expname2    $iniclim-${finalyearplot[2]}"
   fi
   export title1="$iniclim-${finalyearplot[1]}"
   export right="[$units]"
   export left="$varmod"
   export sea
   for sea in ANN DJF JJA
   do
      export pltname=$comppltdir/${expid1}.$comp.$varmod.map_${sea}.$startyear-${lasty}.png
      cp plot_2d_maps_and_diff.ncl $tmpdir1/scripts/plot_2d_maps_and_diff.$varmod.ncl
      ncl $tmpdir1/scripts/plot_2d_maps_and_diff.$varmod.ncl
      if [[ $pltype == "x11" ]]
      then
         exit
      fi  
   done
fi   # end 2d maps
if [[ $do_anncyc -eq 1 ]]
then
   if [[ $core == "FV" ]]
   then
      export inpfile=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
   else
      export srcFileName=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.nc
      export outfile=$tmpdir1/${expid1}.$realm.$varmod.$iniclim-$lasty.anncyc.reg1x1.nc
      export inpfile=$outfile
      if [[ ! -f $inpfile ]]
      then
         ncl $dir_SE/regridSE_CAMh0.ncl
      fi
   fi
   list_reg_anncyc="Global NH SH"
   if [[ $varmod == "U010" ]]
   then
      list_reg_anncyc="Global NH SH u010"
   fi
   export bextraTNH_W=0;export bAfricaSH=0;export bAfricaNH=0;export bAmazon=0;export bextraTNH_E=0;export bglo=0;export bNH=0;export SH=0;export bland=0;export boce=0;export bu010=0
   for reg in $list_reg_anncyc
   do
      case $reg in
         Global)export lat0=-90;export lat1=90;export bglo=1;;
         NH)export lat0=0;export lat1=90;export bNH=1;;
         SH)export lat0=-90;export lat1=0;export bSH=1;;
         u010)export lat0=59.5;export lat1=60.5;export bu010=1;;
      esac
      regfile=$tmpdir1/`basename $inpfile|rev|cut -d '.' -f2-|rev`.$reg.nc
      if [[ ! -f $regfile ]]
      then
         cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $inpfile $regfile
      fi
      if [[ $cmp2obs_ncl -eq 1 ]]
      then
         regfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$reg.nc
         if [[ ! -f $regfileobs ]]
         then
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $obsfile $regfileobs
         fi
      fi
   done
   export rootinpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev` 
   export inpfileanncyc=$tmpdir1/`basename $inpfile|rev|cut -d '.' -f2-|rev` 
   export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear_anncyc-$lasty.anncyc_3.png
   cp plot_anncyc.ncl $tmpdir1/scripts/plot_anncyc.$varmod.ncl
   ncl $tmpdir1/scripts/plot_anncyc.$varmod.ncl
   if [[ $pltype == "x11" ]]
   then
      exit
   fi
   export lat0; export lat1; export lon0;export lon1
   export bglo=0;export bNH=0;export bSH=0;export bextraTNH_E=0;export bextraTNH_W=0;export AfricaSH=0;export AfricaNH=0;export Amazon=0
   list_reg_anncyc="extraTNH_E extraTNH_W AfricaSH AfricaNH Amazon"
   if [[ $varmod == "SNOWDP" ]]
   then
      list_reg_anncyc="extraTNH_E extraTNH_W"
   fi
   for reg in $list_reg_anncyc
   do
      case $reg in
         extraTNH_E)lat0=45;lat1=90;lon0=30;lon1=180;bextraTNH_E=1;;
         extraTNH_W)lat0=45;lat1=90;lon0=-180;lon1=-30;bextraTNH_W=1;;
         AfricaNH)lat0=0;lat1=35;lon0=-20;lon1=35;bAfricaNH=1;;
         AfricaSH)lat0=-36;lat1=0;lon0=10;lon1=35;bAfricaSH=1;;
         Amazon)lat0=-50;lat1=12;lon0=-76;lon1=-45;bAmazon=1;;
      esac
      regfile=$tmpdir1/`basename $inpfile|rev|cut -d '.' -f2-|rev`.$reg.nc
      if [[ ! -f $regfile ]]
      then
         cdo fldmean -sellonlatbox,$lon0,$lon1,$lat0,$lat1 $inpfile $regfile
      fi
      if [[ $cmp2obs_ncl -eq 1 ]]
      then
         regfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$reg.nc
         if [[ ! -f $regfileobs ]]
         then
            cdo fldmean -sellonlatbox,$lon0,$lon1,$lat0,$lat1 $obsfile $regfileobs
         fi
      fi
   done
   export rootinpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`
   export inpfileanncyc=$tmpdir1/`basename $inpfile|rev|cut -d '.' -f2-|rev`
   export pltname=$comppltdir/${expid1}.$comp.$varmod.$startyear_anncyc-$lasty.anncyc_5.png
   ncl $tmpdir1/scripts/plot_anncyc.$varmod.ncl
   if [[ $pltype == "x11" ]]
   then
      exit
   fi
fi   # end annual cycle
if [[ $do_znl_atm2d -eq 1 ]]
then
   if [[ $comp == "atm" ]]
   then
      for sea in JJA DJF ANN
      do
         export inpfileznl=$tmpdir1/${expid1}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
         if [[ ! -f $inpfileznl ]]
         then
            inpfileznl=$tmpdir1/${expid1}.$comp.$varmod.$startyear-${lasty}.znlmean.$sea.nc
            if [[ ! -f $inpfileznl ]]
            then
               if [[ $core == "FV" ]]
               then
                  anncycfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-$lasy.anncyc.nc 
               else
                  anncycfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-$lasy.anncyc.reg1x1.nc 
               fi
               if [[ $sea != "ANN" ]]
               then
                  cdo timmean -selseason,$sea -zonmean $anncycfile $inpfileznl
               else
                  cdo timmean -zonmean $anncycfile $inpfileznl
               fi
            fi
         fi
         if [[ $cmp2obs -eq 1 ]]
         then
            obsfileznl=$scratchdir/$varmod.obs.$sea.znlmean.nc1
            if [[ ! -f $obsfileznl  ]]
            then
               if [[ $sea != "ANN" ]]
               then
                  cdo timmean -selseason,$sea -zonmean $obsfile $obsfileznl
               else
                  cdo timmean -zonmean $obsfile $obsfileznl
               fi
            fi
         fi
         cp plot_znlmean_2dfields.ncl $tmpdir1/scripts/plot_znlmean_2dfields.$varmod.ncl
         ncl $tmpdir1/scripts/plot_znlmean_2dfields.$varmod.ncl
      done
   fi
fi
if [[ $do_znl_lnd -eq 1 ]]
then
   if [[ $comp == "lnd" ]]
   then
      varmod=H2OSNO
      # snow over Syberia
      for sea in JJA DJF ANN
      do
         export inpfileznl=$tmpdir1/${expid1}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
         if [[ ! -f $inpfileznl ]]
         then
            listafznl=""
            for yyyy in `seq -f "%04g" $startyear $finalyear`
            do
               inpfileznlyyyy=$tmpdir1/${expid1}.$comp.$varmod.$startyear-${lasty}.znl.$sea.nc
               if [[ ! -f $inpfileznlyyyy ]]
               then
                  cdo selseason,$sea -zonmean -sellonlatbox,90,140,0,90 $tmpdir1/${expid1}.$realm.$varmod.$yyyy.nc $inpfileznlyyyy
               fi
               listafznl+=" $inpfileznlyyyy"
            done
            cdo -mergetime $listafznl $inpfileznl
         fi
# qui dovrebbe essere lanciato 
#                  ncl plot_hov_lnd.ncl
# testato solo su Zeus VA MOLTO ADATTATO!!
      done
   fi
fi
