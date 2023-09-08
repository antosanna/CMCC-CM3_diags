#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J timeseries
#BSUB -e logs/timeseries_%J.err
#BSUB -o logs/timeseries_%J.out
#BSUB -q s_long

#ALBEDO=(FSUTOA)/SOLIN  [ con SOLIN=FSUTOA+FSNTOA]
#https://atmos.uw.edu/~jtwedt/GeoEng/CAM_Diagnostics/rcp8_5GHGrem-b40.20th.track1.1deg.006/set5_6/set5_ANN_FLNT_c.png

set -eux  
# SECTION TO BE MODIFIED BY USER
machine="juno"
do_ocn=0
do_atm=1
do_ice=0
do_lnd=0
do_timeseries=0
do_znl_lnd=0
do_znl_atm=1
do_znl_atm2d=0
do_2d_plt=0
do_anncyc=1

# model to diagnose
#export expid1=cm3_cam116d_2000_1d32l_t1
#export expid1=SPS3.5_2000_cont
export expid1=cm3_cam122_cpl2000-bgc_t01
#export expid1=cm3_cam122d_2000_1d32l_t8
#utente1=$USER
utente1=dp16116
#cam_nlev1=32
cam_nlev1=83
core1=FV
#
# second model to compare with
#expid2=cam109d_cm3_1deg_amip1981-bgc_t2
#utente2=mb16318
export expid2=cm3_cam116d_2000_1d32l_t1
utente2=$USER
cam_nlev2=32
core2=FV
#
export startyear="0001"
export finalyear="0090"
export startyear_anncyc="0001" #starting year to compute 2d map climatology
export nyrsmean=20   #nyear-period for mean in timeseries
# select if you compare to model or obs 
export cmp2obs=1
export cmp2mod=0
# END SECTION TO BE MODIFIED BY USER

export mftom1=1
export varobs
export cmp2obstimeseries=0
i=1
do_compute=1
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

export pltype="x11"
export units
export title
#allvars_atm="ALBEDO ALBEDOS AODVIS BURDENBC BURDENSOA BURDENPOM BURDENSO4 BURDENDUST BURDEN1 BURDENdn1  BURDEN2 BURDENdn2 BURDEN3 BURDENdn3 BURDEN4 BURDENdn4 BURDENB  BURDENDUST BURDENPOM BURDENSEASALT BURDENSOA  BURDENSO4 CLDLOW CLDMED CLDHGH  CLDTOT EnBalSrf FLUT FLUTC FLDS FSDSC FLNS FLNSC FSNSC FSNTOA FSNS FSDS FSNT FLNT ICEFRAC  LHFLX SHFLX LWCF SWCF SOLIN RESTOM EmP PRECT PRECC PS QFLX TREFHT TS Z500 Z850 U200"
#allvars_atm="ALBEDO CLDLOW CLDMED CLDHGH  CLDTOT EnBalSrf FLUT FLUTC FLDS FSDSC FLNS FLNSC FSNSC FSNTOA FSNS FSDS FSNT FLNT ICEFRAC  LHFLX SHFLX LWCF SWCF SOLIN RESTOM EmP PRECT PRECC PS QFLX TREFHT TS Z500 Z850 U200 T U Z3"
allvars_atm="U010" #ALBEDO CLDLOW CLDMED CLDHGH  CLDTOT FLUT FLUTC FLDS FSDSC FLNS FLNSC FSNSC FSNTOA FSNS FSDS FSNT FLNT ICEFRAC  LHFLX SHFLX LWCF SWCF SOLIN RESTOM EmP PRECT PRECC PS QFLX TREFHT TS Z010 Z100 Z500 Z700 Z850 U010 U100 U200 U700 T U Z3"
allvars_lnd="SNOWDP FSH TLAI FAREA_BURNED";
allvars_ice="aice snowfrac ext Tsfc fswup fswdn flwdn flwup congel fbot albsni hi";
allvars_oce="tos sos zos heatc saltc";
    
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
   export comp
   for comp in $comps
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
            atm) allvars=$allvars_atm;realm=cam;;
            lnd) allvars=$allvars_lnd; realm=clm2;;
            ice) allvars=$allvars_ice;realm=cice;;
         esac
         inpdir=$inpdirroot/$comp/hist
         if [[ $do_compute -eq 1 ]]
         then
            echo $allvars
         
            for yyyy in `seq -f "%04g" $startyear $finalyear`
            do
                echo "-----going to postproc year $yyyy"
                yfile=$tmpdir/${exp}.$realm.$ftype.$yyyy.nc
                if [[ $ftype == "h0" ]] || [[ $ftype == "h" ]]
                then #merge h0
                   if [[ `ls $inpdir/${exp}.$realm.$ftype.$yyyy-??.nc |wc -l` -eq 12 ]]
                   then
                      if [[ ! -f $yfile ]]
                      then
         #1 anno e 12 mesi
                         ncrcat -O $inpdir/${exp}.$realm.$ftype.$yyyy-??.nc $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp.nc
                         cdo settaxis,$yyyy-01-01,12:00:00,1mon $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp.nc $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp1.nc
                         cdo setreftime,$yyyy-01-01,12:00:00 $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp1.nc $yfile
                         if [[ -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp.nc ]]
                         then
                            rm -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp.nc
                         fi
                         if [[ -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp1.nc ]]
                         then
                            rm -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp1.nc
                         fi
                      fi
         #1 anno e 12 mesi e una var
                   fi
                fi 
   
                if [[ ! -f $yfile ]]
                then
                   echo "yearly file $yfile not produced "
                   break
                fi 
                export lasty=$yyyy
            done #loop on years
            for var in $allvars
            do
         
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
         #check if var is present
   # SECTION VARIABLES TO BE  COMPUTED
                      if [[ $var == "SOLIN" ]]
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
            done   #loop on var
         fi
      done
   done
   finalyearplot[$i]=$lasty
   i=$(($i + 1))
done #expid
export tmpdir=$tmpdir1
for comp in $comps
do
   case $comp in
#      atm)typelist="h0";; 
#      lnd)typelist="h0";; 
#      ice)typelist="h";; 
# ALBEDOC
         atm) allvars=$allvars_atm;realm=cam;;
         lnd) allvars=$allvars_lnd;
             realm=clm2;;
         ice) allvars=$allvars_ice;realm=cice;;
      esac
   for ftype in $typelist
   do
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
   
      export varmod
   
      units=""
      echo $allvars
      for varmod in $allvars
      do
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
#   "atm" 
# units only for vars that need conversion
         export ncl_lev
         export cmp2mod_ncl
         export cmp2obs_ncl
         case $varmod in
                BURDENSEASALT)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENBC)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENSOA)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENPOM)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENSO4)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;export delta=0.2;;
                BURDENDUST)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;export delta=0.2;;
                BURDEN4)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENdn4)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDEN3)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENdn3)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDEN2)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;export delta=0.01;;
                BURDENdn2)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;export delta=0.01;;
                BURDEN1)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENdn1)cmp2mod_ncl=0;cmp2obs_ncl=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                EnBalSrf)varobs=ftot;units="W/m2";export maxplot=20.;export minplot=-20.;export delta=2.;title="Surface Radiative Balance";name_from_here=1;units_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;export deltadiff=1.;export cmp2obs_ncl=$cmp2obs;obsfile="$dir_obs3/ftot_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                AODVIS)cmp2mod_ncl=0;cmp2obs_ncl=0;;
                ICEFRAC)cf=0;units="frac";obsfile="";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;title2="ERA5 $climobs";export maxplot=0.95;export minplot=0.15;export delta=.05;units_from_here=0; title="Sea-Ice Fraction";name_from_here=1;;
                TREFHT)varobs=T2M;cf=-273.15;units="Celsius deg";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=4;units_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                U200)varobs=U;units="m/s";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;export delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                U010)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;export delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                U700)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;export delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                U100)varobs=var131;units="m/s";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;export delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                Z500)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=3;title2="ERA5 $climobs";export maxplot=5900.;export minplot=4800;export delta=100;units_from_here=1;export maxplotdiff=50;export minplotdiff=-50;export deltadiff=5.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                Z700)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=3200.;export minplot=2600;export delta=100;units_from_here=1;export maxplotdiff=100;export minplotdiff=-100;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                Z010)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=31600.;export minplot=28800;export delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                Z100)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=16800.;export minplot=15000;export delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                Z850)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=5;title2="ERA5 $climobs";export maxplot=1550.;export minplot=1050.;export delta=50;units_from_here=1;export maxplotdiff=50.;export minplotdiff=-50;export deltadiff=5.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                TS)varobs=var235;cf=-273.15;units="Celsius deg";obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=4;units_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
#                TS)varobs=SST;cf=-273.15;units="Celsius deg";export maxplot=36;export minplot=-20;export delta=2.;units_from_here=1;obsfile=$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc;export cmp2obs=1;export title2="ERA5 $climobs";;
                PRECT)varobs=precip;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;export delta=2.;export maxplotdiff=5.;export minplotdiff=-5.;export deltadiff=1.;obsfile="$dir_obs5/gpcp_1979-2015_1deg_anncyc.nc";export title2="GPCP 1979-2015";title="Total precipitation";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                EmP)varobs=var167;mf=86400000;units="mm/d";export maxplot=10.;export minplot=-10.;export delta=2.;title="Evaporation - Precipitation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;export maxplotdiff=3.;export minplotdiff=-3.;export deltadiff=.5;;
                QFLX)varobs=var167;mf=1000000;units="10^-6 kgm-2s-1";export maxplot=100.;export minplot=0.;export delta=10.;title="Surface Water Flux";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;export maxplotdiff=-10.;export minplotdiff=-10.;export deltadiff=1.;;
                PRECC)varobs=var167;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;export delta=2.;title="Convective precipitation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;;
                PSL)varobs=MSL;mf=0.01;units="hPa";export maxplot=1030;export minplot=990;export delta=4.;export maxplotdiff=8;export minplotdiff=-8;export deltadiff=2.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                FLUT)varobs=FLUT;export maxplot=300;export minplot=120;export delta=20.;export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up lw Top of Model";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                SOLIN)varobs=var167;units="W/m2";export maxplot=450;export minplot=60;export delta=30.;title="Insolation";units_from_here=1;name_from_here=1;cmp2obs_ncl=0;cmp2mod_ncl=$cmp2mod;;
                ALBEDO)units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Albedo";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;export maxplotdiff=0.3;export minplotdiff=-0.3;export deltadiff=.03;;
                ALBEDOS)varobs=albedos;units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Surf Albedo";units_from_here=1;name_from_here=1;export maxplotdiff=0.3;export minplotdiff=-0.3;export deltadiff=.03;obsfile="$dir_obs3/albedos_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                ALBEDOC)units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Albedo Clear Sky";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                RESTOM)varobs=var167;export maxplot=100.;export minplot=-100.;export delta=25.;units="W/m2";title="Residual energy Top of the Model";units_from_here=1;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;export maxplotdiff=20.;export minplotdiff=-20.;export deltadiff=2.5;;
                FLUTC)varobs=FLUTC;export maxplot=300;export minplot=120;export delta=20.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up clear-sky lw Top of Model";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                FLDS)varobs=var175;export maxplot=400;export minplot=100;export delta=50.;name_from_here=1;title="Down lw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/strd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                #FSDS)varobs=var169;export maxplot=300;export minplot=120;export delta=20.;name_from_here=1;title="Down sw surface";cmp2obs=1;export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FSNSC)varobs=var167;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Net sw clear-sky surface";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                FSNS)varobs=var176;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Net sw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/snsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
               FSDS)varobs=var169;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Downward sw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                FSNTOA)varobs=var178;export maxplot=420;export minplot=30;export delta=30.;name_from_here=1;title="Net sw Top of the Atmosphere";export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                FSNT)varobs=var178;export maxplot=420;export minplot=30;export delta=30.;name_from_here=1;title="Net sw Top of Model";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                FLNT)varobs=var179;export maxplot=310;export minplot=115;export delta=15.;name_from_here=1;title="Net lw Top of Model";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/tntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld" ;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
             
              FLNSC)varobs=var167;export maxplot=300;export minplot=120;export delta=20.;name_from_here=1;title="Net clear-sky lw Top of Model";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
              FLNS)varobs=var177;export maxplot=200.;export minplot=0.;export delta=20.;name_from_here=1;title="Net lw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/sntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
             SHFLX)varobs=var146;export maxplot=300;export minplot=-20;export delta=20.;name_from_here=1;title="Sensible Heat Flux";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/sshf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;

             LHFLX)varobs=var147;export maxplot=300;export minplot=-20;export delta=20.;name_from_here=1;title="Latent Heat Flux";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/slhf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
             SWCF)varobs=SWCF;export maxplot=40;export minplot=-100;export delta=20.;name_from_here=1;title="Short Wave Cloud Forcing";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
             LWCF)varobs=LWCF;export maxplot=80;export minplot=0;export delta=10.;name_from_here=1;title="Long Wave Cloud Forcing";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";export title2="CERES 2000-2009";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;

#   "lnd"
# title still there but defined in ncl through long_name
                TWS) title="Total Water Storage";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                TSOI) title="Soil Temp at 80cm";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                H2OSOI) title="Volumetric Soil Water at 1.36m";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                H2OSNO)varobs=sd; title="Snow Depth (liquid water)";varobs=var167;mf=0.01;export maxplot=10;export minplot=0.5;export delta=0.5;units_from_here=1;units="m";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                SNOW) title="Atmospheric Snow";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                SNOWDP)title="Snow Depth ";varobs=sd;export maxplot=3.;export minplot=0.1;export delta=.05;units_from_here=1;name_from_here=1;units="m";obsfile="$dir_obs1/ERA5T/sd/sd_1993-2017.ymean.nc";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                CLDTOT)varobs=var164;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Total cloud cover";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldtot_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                CLDMED)varobs=var187;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Mid-level cloud 400-700hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldmed_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                CLDHGH)varobs=var188;export maxplot=0.9;export minplot=0.1;export delta=.1;title="High-level cloud 50-400hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldhgh_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;;
                CLDLOW)varobs=var186;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Low-level cloud 700-1200hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=0.6;export minplotdiff=-0.6;export deltadiff=.1;obsfile="$dir_obs2/cldlow_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";cmp2obs_ncl=$cmp2obs;;
                FSH)varobs=var167;export maxplot=100.;export minplot=-100.;export delta=10.;title="Sensible Heat";units_from_here=1;name_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;export deltadiff=1.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                TLAI)varobs=var167;export maxplot=11.;export minplot=1.;export delta=1.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
                QOVER)title="Total Surface Runoff";export maxplot=0.0003;export minplot=0.;export delta=.00005;name_from_here=1;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=0;;
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
                  ncl $dir_SE/regridSE_CAMh0.ncl
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
            ncl plot_timeseries_xy_panel.ncl
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
             ncl plot_timeseries_xy_panel.ncl
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
               ncl plot_timeseries_xy_panel.ncl
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
               ncl $dir_SE/regridSE_CAMh0.ncl
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
                 export pltname=$comppltdir/${expid1}.$comp.$varmod.map_${sea}.png
                 ncl plot_2d_maps_and_diff.ncl
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
            for reg in Global NH SH
            do
               case $reg in
                  Global)export lat0=-90;export lat1=90;export bglo=1;;
                  NH)export lat0=0;export lat1=90;export bNH=1;;
                  SH)export lat0=-90;export lat1=0;export bSH=1;;
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
            ncl plot_anncyc.ncl
            if [[ $pltype == "x11" ]]
            then
               exit
            fi
         fi   # end annual cycle
         if [[ $do_znl_atm2d -eq 1 ]]
         then
            if [[ $comp == "atm" ]]
            then
      # snow over Syberia
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
                  ncl plot_znlmean_2dfields.ncl
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
      done  #loop on varmod
        
   done   #loop on ftype
done   #loop on comp
if [[ $do_znl_atm -eq 1 ]]
then
      comp=atm
      export obsfile=$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc

      export varmod
      export sea
      export PSfile=$tmpdir1/${expid1}.cam.PS.$startyear-$lasty.anncyc.nc
      export Tfile=$tmpdir1/${expid1}.cam.T.$startyear-$lasty.anncyc.nc
# here take PS and hyam
      realm=cam
      export auxfile=$inpdirroot/atm/hist/${expid1}.$realm.h0.$startyear-01.nc
      comppltdir=$pltdir/${comp}
      mkdir -p $comppltdir
      for varmod in T U Z3
      do
         export modfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-$lasty.anncyc.nc
         for sea in ANN DJF JJA 
         do  
            export pltname=$comppltdir/$expid1.zonalmean.$varmod.$iniclim-$lasty.$sea.png
            ncl plot_zonalmean_2plots_diff.ncl
            if [[ $pltype == "x11" ]]
            then
               exit
            fi  
         done
      done
fi   #do_znl_atm

#ymeanfilevar=$tmpdir/${expid1}.$realm.$var.$startyear-$lasty.ymean.nc

#add loop on exp
tmpdir=$tmpdir1   #TMP
if [[ $do_ocn -eq 1 ]]
then
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
   typelist="grid_T"
   freqlist="1m"
   for ftype in $typelist
   do
      inpdir=$inpdirroot/$comp/hist
      if [[ $do_compute -eq 1 ]]
      then
         export realm="nemo"
         for freq in $freqlist
         do
            case $freq in
                1m)allvars=$allvars_oce;;
            esac
            echo $allvars
            for var in $allvars
            do
               listaf=" "
               echo "-----going to postproc variable $var"
               for yyyy in `seq -f "%04g" $startyear $finalyear`
               do
                   echo "-----going to postproc year $yyyy"
                   yfile=$tmpdir/${expid1}_${freq}_${yyyy}_${ftype}.nc
                   if [[ $freq == "1m" ]] 
                   then #merge h0
                      if [[ `ls $inpdir/${expid1}_${freq}_${yyyy}????_${yyyy}????_${ftype}.nc |wc -l` -eq 12 ]]
                      then
                         if [[ ! -f $yfile ]]
                         then
         #1 anno e 12 mesi
                            ncrcat -O $inpdir/${expid1}_${freq}_${yyyy}????_${yyyy}????_${ftype}.nc $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc
                            ncrename -O -d time_counter,time $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc
                            ncrename -O -v time_counter,time $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc
                            ncks -C -O -x -v time_centered $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc $tmpdir/${expid1}_${freq}_${yyyy}.tmp1.nc
                            ncks -C -O -x -v time_instant $tmpdir/${expid1}_${freq}_${yyyy}.tmp1.nc $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc
                            cdo settaxis,$yyyy-01-01,12:00:00,1mon $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc $tmpdir/${expid1}_${freq}_${yyyy}.tmp1.nc
                            cdo setreftime,$yyyy-01-01,12:00:00 $tmpdir/${expid1}_${freq}_${yyyy}.tmp1.nc $yfile
                            rm $tmpdir/${expid1}_${freq}_${yyyy}.tmp.nc
                            rm $tmpdir/${expid1}_${freq}_${yyyy}.tmp1.nc
                         fi
         #1 anno e 12 mesi e una var
                         lasty=$yyyy
                      fi
                   elif [[ $freq == "1d" ]]
                   then
                      :
   #                   if [[ ! -f $yfile ]]
   #                   then
   #                      cdo monmean $inpdir/${expid1}.$realm.??? $yfile
   #                   fi 
                   fi 
   
                   if [[ ! -f $yfile ]]
                   then
                      echo "yearly file $yfile not produced "
                      break
                   fi
               done
               finalyear=$lasty
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
                   head=`basename $ymeanfilevar|rev|cut -d '.' -f1|rev`
                   cdo -setctomiss,0 ${ymeanfilevar} $tmpdir/${head}_miss.nc
                   cdo mul $tmpdir/${head}_miss.nc $tmpdir/tarea_surf_miss.nc $tmpdir/${head}_miss_wg.nc
                   cdo fldsum $tmpdir/${head}_miss_wg.nc $tmpdir/${head}_sum_miss.nc
                   cdo div $tmpdir/${head}_sum_miss.nc $tmpdir/tarea_surf_sum_miss.nc $inpfile
                fi
            done   #loop on vars
         done  #loop freq
      fi   #do_compute
   done   #loop type
#   export outdia=/work/$DIVISION/$USER/CMCC-CM/diagnostics/$expid1'_diag_'$startyear-$lasty
#   mkdir -p $outdia
   outnml=$tmpdir1/nml
   # copy locally the namelists
   mkdir -p $outnml
   export varmod
   
   for varmod in $allvars
   do
      export cf=0
      export mf=1
      export mftom1=1
      export cmp2obs_ncl
      export units_from_here=0
      export units
      export name_from_here=0
      case $varmod in 
         heatc)cmp2obs_ncl=0;units="J/m2*e-10";mftom1=10000000000.;export maxplot=25;export minplot=-5;export delta=2.5;units_from_here=1;;
         saltc)units="PSU*kg/m2*e-7";mftom1=10000000;export maxplot=25;export minplot=0;export delta=2.5;units_from_here=1;;
#         tos)varobs=var235;cf=-273.15;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
         sos)varobs=var235;cf=0;units="PSU";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export cmp2obs=0;export title2="ERA5 $climobs";export maxplot=36.;export minplot=26.;export delta=2.;units_from_here=1;;
         zos)varobs=var235;cf=0;units="m";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export cmp2obs=0;export title2="ERA5 $climobs";export maxplot=3.;export minplot=-3.;export delta=0.5;units_from_here=1;;
         tos)varobs=SST;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";export cmp2obs=1;export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
      esac
      echo $units
      if [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
      then
         continue
      fi
      if [[ $comp == "ocn" ]]
      then
          ocnlist+=" \"$varmod\","
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
      export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export SH=0;export bland=0;export boce=0
      export hplot="0.3"
      if [[ $do_timeseries -eq 1 ]]
      then
            for ts_gzm_boxes in Global NH SH 
            do
               case $ts_gzm_boxes in
                  Global)export lat0=-90;export lat1=90;export bglo=1;;
                  NH)export lat0=0;export lat1=90;export bNH=1;;
                  SH)export lat0=-90;export lat1=0;export bSH=1;;
               esac
               if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
               then  
                  continue
               fi
               cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
            done
      # do plot_timeseries
            ncl plot_timeseries_xy_panel.ncl
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
               if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
               then  
                  continue
               fi
               cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
             done
      # do plot_timeseries
             ncl plot_timeseries_xy_panel.ncl
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
                 ncl plot_2d_maps_and_diff_nemo.ncl
                 if [[ $pltype == "x11" ]]
                 then
                    exit
                 fi  
            done
      fi
   done
fi

#export outdia=/work/$DIVISION/$USER/CMCC-CM/diagnostics/$expid1'_diag_'$startyear-$lasty
#mkdir -p $outdia


if [[ -f $pltdir/index.html ]]
then
   rm -f $pltdir/index.html
fi
sed -e 's/DUMMYCLIM/'$startyear-${lasty}'/g;s/DUMMYEXPID/'$expid1'/g;s/atmlist/'"$atmlist"'/g;s/lndlist/'"$lndlist"'/g;s/icelist/'"$icelist"'/g;s/ocnlist/'"$ocnlist"'/g' index_tmpl.html > $pltdir/index.html
cd $pltdir
if [[ $cmp2mod -eq 0 ]] 
then
   tar -cvf $expid1.$startyear-${lasty}.VSobs.tar atm lnd ice ocn index.html
   gzip -f $expid1.$startyear-${lasty}.VSobs.tar
else
   tar -cvf $expid1.$startyear-${lasty}.tar atm lnd ice ocn index.html
   gzip -f $expid1.$startyear-${lasty}.tar
fi

#echo "all done plots $expid1 $startyear-$lasty" |mail -a plots.$startyear-${lasty}.tar.gz antonella.sanna@cmcc.it

exit
