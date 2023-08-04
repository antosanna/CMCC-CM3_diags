#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J timeseries
#BSUB -e logs/timeseries_%J.err
#BSUB -o logs/timeseries_%J.out
#BSUB -q s_long

. ~/utils/load_cdo
. ~/utils/load_nco
#ALBEDO=(FSUTOA)/SOLIN  [ con SOLIN=FSUTOA+FSNTOA]
#https://atmos.uw.edu/~jtwedt/GeoEng/CAM_Diagnostics/rcp8_5GHGrem-b40.20th.track1.1deg.006/set5_6/set5_ANN_FLNT_c.png

set -eux  
# SECTION TO BE MODIFIED BY USER
machine="zeus"
do_ocn=0
do_atm=1
do_ice=0
do_lnd=1
do_timeseries=1
do_znl_lnd=0
do_znl_atm=1
do_2d_plt=1

# model to diagnose
export expid1=SPS3.5_2000_cont
utente1=sps-dev
cam_nlev1=46
core1=SE
#
# second model to compare with
expid2=cam109d_cm3_1deg_amip1981-bgc_t2
utente2=mb16318
cam_nlev2=32
core2=FV
#
export startyear="0001"
export finalyear="0009"
# select if you compare to model or obs 
export cmp2obs=1
export cmp2mod=0
# END SECTION TO BE MODIFIED BY USER

i=1
do_compute=1
export expname1=${expid1}_${cam_nlev1}
export expname2=${expid2}_${cam_nlev2}
dir_SE=$PWD/../SPS3.5
if [[ $machine == "juno" ]]
then
   export dir_lsm=/work/csp/as34319/CMCC-SPS3.5/regrid_files/
   dir_obs1=/work/csp/as34319/obs
   dir_obs2=$dir_obs1/ERA5
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
set +euvx  
   . ~/utils/load_ncl
set -euvx  
elif [[ $machine == "zeus" ]]
then
   export dir_lsm=/work/csp/sps-dev/CESMDATAROOT/CMCC-SPS3.5/regrid_files/
   dir_obs1=/data/inputs/CESM/inputdata/cmip6/obs/
   dir_obs2=/data/delivery/csp/ecaccess/ERA5/monthly/025/
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
fi
export climobscld=1980-2019
export climobs=1979-2018
export iniclim=$startyear

#
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
   export tmpdir2=/work/$DIVISION/$USER/scratch/$utente2/$expid2/
   mkdir -p $tmpdir2
fi

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=/work/$DIVISION/$USER/scratch/$utente1/$expid1/plots
mkdir -p $pltdir
mkdir -p $pltdir/atm $pltdir/lnd $pltdir/ice $pltdir/ocn

export pltype="png"
export units
export title
allvars_atm="ALBEDO ALBEDOS AODVIS BURDENBC BURDENSOA BURDENPOM BURDENSO4 BURDENDUST BURDEN1 BURDENdn1  BURDEN2 BURDENdn2 BURDEN3 BURDENdn3 BURDEN4 BURDENdn4 BURDENB  BURDENDUST BURDENPOM BURDENSEASALT BURDENSOA  BURDENSO4 CLDLOW CLDMED CLDHGH  CLDTOT EnBalSrf FLUT FLUTC FLDS FSDSC FLNS FLNSC FSNSC FSNTOA FSNS FSDS FSNT FLNT ICEFRAC  LHFLX SHFLX SOLIN RESTOM EmP PRECT PRECC PS QFLX TREFHT TS Z500 Z850 U200"
allvars_lnd="FSH TLAI SNOWDP FAREA_BURNED";
allvars_ice="aice snowfrac ext Tsfc fswup fswdn flwdn flwup congel fbot albsni hi";
    
export tmpdir2=/work/$DIVISION/$USER/scratch/$utente2/$expid2/
export tmpdir1=/work/$DIVISION/$USER/scratch/$utente1/$expid1/
mkdir -p $tmpdir1 $tmpdir2
for exp in $explist
do
   case $exp in
      $expid1)utente=$utente1;core=$core1 ;;
      $expid2)utente=$utente2;core=$core2 ;;
   esac
   if [[ $machine == "zeus" ]]
   then
      model=CESM2
      if [[ $core == "SE" ]]
      then
         model=CESM
      fi
      rundir=/work/$DIVISION/$utente/$model/$exp/run
      export inpdirroot=/work/csp/$utente/$model/archive/$exp
   else
      rundir=/work/$DIVISION/$utente/CMCC-CM/$exp/run
      export inpdirroot=/work/csp/$utente/CMCC-CM/archive/$exp
   fi
   export tmpdir=/work/$DIVISION/$USER/scratch/$utente/$exp/
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
                         rm -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp.nc
                         rm -f $tmpdir/${exp}.$realm.$ftype.$yyyy.tmp1.nc
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
               echo "-----going to postproc variable $var"
               for yyyy in `seq -f "%04g" $startyear $lasty`
               do
                   echo "-----going to postproc var $var year $yyyy"
                   yfile=$tmpdir/${exp}.$realm.$ftype.$yyyy.nc
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
                         cdo $opt -select,name=FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'SOLIN=FSUTOA+FSNTOA' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "EnBalSrf" ]]
                      then
                         if [[ ! -f $tmpdir/${exp}.lsm.nc ]]
                         then
                            cdo selvar,LANDFRAC $yfile $tmpdir/${exp}.lsm.tmp.nc
                            cdo -expr,'LANDFRAC = ((LANDFRAC>=0.5)) ? 1.0 : LANDFRAC/0.0' $tmpdir/${exp}.lsm.tmp.nc $tmpdir/${exp}.lsm.nc
                            rm $tmpdir/${exp}.lsm.tmp.nc
                         fi
                         cdo $opt -select,name=FSNS,FLNS,LHFLX,SHFLX $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'EnBalSrf=FSNS-FNDS-SHFLX-LHFLX' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc 
                         cdo mul $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc $tmpdir/${exp}.lsm.nc $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp1.nc $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "ALBEDO" ]]
                      then
                         cdo $opt -select,name=FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'ALBEDO=FSUTOA/(FSNTOA+FSUTOA)' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "ALBEDOS" ]]
                      then
                         cdo $opt -select,name=FSDS,FSNS $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'ALBEDOS=(FSDS-FSNS)/FSDS' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "ALBEDOC" ]]
                      then
                         cdo $opt -select,name=FSNTOAC,FSUTOA,FSNTOA $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'ALBEDOC=(FSNTOA+FSUTOA-FSNTOAC)/(FSNTOA+FSUTOA)' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "RESTOM" ]]
                      then
   #RESTOM=FSNT-FLNT
                         cdo $opt -select,name=FSNT,FLNT $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'RESTOM=FSNT-FLNT' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      elif [[ $var == "EmP" ]]
                      then
   #RESTOM=FSNT-FLNT
                         cdo $opt -select,name=QFLX,PRECT $yfile $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                         cdo expr,'EmP=QFLX/1000-PRECT' $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc  $ymfilevar
                         rm $tmpdir/${exp}.$realm.$var.$yyyy.tmp.nc
                      else
                         ret1=`ncdump -v $var ${yfile}|head -1`
                         if [[ "$ret1" == "" ]]; then
                            continue
                         fi
                         cdo $opt -selvar,$var $yfile $ymfilevar
                      fi
                   fi
           
                   listaf+=" $ymfilevar"
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
                anncycfilevar=$tmpdir/${exp}.$realm.$var.$startyear-$lasty.anncyc.nc
                if [[ ! -f $anncycfilevar ]]
                then
                   cdo ymonmean -mergetime $listaf $anncycfilevar
                fi
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
      export outdia=/work/$DIVISION/$USER/CMCC-CM/diagnostics/$expid1'_diag_'$startyear-$lasty
      mkdir -p $outdia
      outnml=$outdia/nml
   # copy locally the namelists
      mkdir -p $outnml
      rsync -auv $rundir/*_in $outnml
      rsync -auv $rundir/namelist* $outnml
      if [[  `ls $rundir/file_def*xml |wc -l` -gt 0 ]]
      then
         rsync -auv $rundir/file_def*xml  $outnml
      fi
   
      export plotdir=$outdia/plots/
      mkdir -p $plotdir
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
         case $varmod in
#                TREFHT)varobs=var167;cf=-273.15;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="/work/csp/as34319/obs/ERA5/t2m/t2m_era5_${climobs}_clim_anncyc.nc";export cmp2obs=1;export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
                BURDENSEASALT)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENBC)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENSOA)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENPOM)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENSO4)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;export delta=0.2;;
                BURDENDUST)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=3;export minplot=0.;export delta=0.2;;
                BURDEN4)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDENdn4)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=1;export minplot=0.;export delta=0.1;;
                BURDEN3)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENdn3)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDEN2)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;export delta=0.01;;
                BURDENdn2)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=0.1;export minplot=0.;export delta=0.01;;
                BURDEN1)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                BURDENdn1)cmp2mod=0;cmp2obs=0;mf=100000;units="kg/m2*e5";units_from_here=1;export maxplot=5;export minplot=0.;export delta=0.5;;
                EnBalSrf)varobs=ftot;units="W/m2";export maxplot=20.;export minplot=-20.;export delta=2.;title="Surface Radiative Balance";name_from_here=1;units_from_here=1;export maxplotdiff=10.;export minplotdiff=-10.;export deltadiff=1.;cmp2obs=1;obsfile="$dir_obs3/ftot_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                AODVIS)cmp2mod=0;cmp2obs=0;;
                ICEFRAC)varobs=T2M;cf=0;units="frac";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="";export cmp2obs=0;title2="ERA5 $climobs";export maxplot=0.95;export minplot=0.15;export delta=.05;units_from_here=0; title="Sea-Ice Fraction";name_from_here=1;;
                TREFHT)varobs=T2M;cf=-273.15;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
                U200)varobs=U;units="m/s";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30.;export delta=10.;units_from_here=1;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;;
                Z500)varobs=Z;cf=0;units="m";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=3;title2="ERA5 $climobs";mf=0.102;export maxplot=600.;export minplot=300;export delta=20;units_from_here=1;export maxplotdiff=8;export minplotdiff=-8;export deltadiff=2.;;
                Z850)varobs=Z;cf=0;units="m";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=5;title2="ERA5 $climobs";mf=0.102;export maxplot=150.;export minplot=100.;export delta=5;units_from_here=1;export maxplotdiff=8.;export minplotdiff=-8;export deltadiff=2.;;
                TS)varobs=var235;cf=-273.15;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
#                TS)varobs=SST;cf=-273.15;units="Celsius deg";export maxplot=36;export minplot=-20;export delta=2.;units_from_here=1;obsfile=$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc;export cmp2obs=1;export title2="ERA5 $climobs";;
                PRECT)varobs=precip;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;export delta=2.;export maxplotdiff=5.;export minplotdiff=-5.;export deltadiff=1.;obsfile="$dir_obs1/gpcp_cdr_v23rB1_1979-2015_1deg.nc";export title2="GPCP 1979-2015";title="Total precipitation";units_from_here=1;name_from_here=1;;
                EmP)varobs=var167;mf=86400000;units="mm/d";export maxplot=10.;export minplot=-10.;export delta=2.;title="Evaporation - Precipitation";units_from_here=1;name_from_here=1;cmp2obs=0;export maxplotdiff=3.;export minplotdiff=-3.;export deltadiff=.5;;
                QFLX)varobs=var167;mf=1000000;units="10^-6 kgm-2s-1";export maxplot=100.;export minplot=0.;export delta=10.;title="Surface Water Flux";units_from_here=1;name_from_here=1;cmp2obs=0;export maxplotdiff=-10.;export minplotdiff=-10.;export deltadiff=1.;;
                PRECC)varobs=var167;mf=86400000;units="mm/d";export maxplot=18;export minplot=2;export delta=2.;title="Convective precipitation";units_from_here=1;name_from_here=1;cmp2obs=0;;
                PSL)varobs=MSL;mf=0.01;units="hPa";export maxplot=1030;export minplot=990;export delta=4.;export maxplotdiff=8;export minplotdiff=-8;export deltadiff=2.;obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";;
                FLUT)varobs=FLUT;export maxplot=300;export minplot=120;export delta=20.;export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up lw Top of Model";export title2="CERES 2000-2009";;
                SOLIN)varobs=var167;units="W/m2";export maxplot=450;export minplot=60;export delta=30.;title="Insolation";units_from_here=1;name_from_here=1;cmp2obs=0;;
                ALBEDO)units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Albedo";units_from_here=1;name_from_here=1;cmp2obs=0;export maxplotdiff=0.3;export minplotdiff=-0.3;export deltadiff=.03;;
                ALBEDOS)varobs=albedos;units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Surf Albedo";units_from_here=1;name_from_here=1;export maxplotdiff=0.3;export minplotdiff=-0.3;export deltadiff=.03;obsfile="$dir_obs3/albedos_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                ALBEDOC)units="fraction";export maxplot=0.9;export minplot=0.1;export delta=0.1;title="Albedo Clear Sky";units_from_here=1;name_from_here=1;cmp2obs=0;;
                RESTOM)varobs=var167;export maxplot=100.;export minplot=-100.;export delta=25.;units="W/m2";title="Residual energy Top of the Model";units_from_here=1;name_from_here=1;cmp2obs=0;export maxplotdiff=20.;export minplotdiff=-20.;export deltadiff=2.5;;
                FLUTC)varobs=FLUTC;export maxplot=300;export minplot=120;export delta=20.;obsfile="$dir_obs1/CERES-EBAF_1m_1deg_2000-2009.nc";name_from_here=1;title="Up clear-sky lw Top of Model";export title2="CERES 2000-2009";;
                FLDS)varobs=var175;export maxplot=400;export minplot=100;export delta=50.;name_from_here=1;title="Down lw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/strd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                #FSDS)varobs=var169;export maxplot=300;export minplot=120;export delta=20.;name_from_here=1;title="Down sw surface";cmp2obs=1;export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FSNSC)varobs=var167;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Net sw clear-sky surface";cmp2obs=0;;
                FSNS)varobs=var176;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Net sw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/snsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
               FSDS)varobs=var169;export maxplot=300;export minplot=25;export delta=25.;name_from_here=1;title="Downward sw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/ssrd_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FSNTOA)varobs=var178;export maxplot=420;export minplot=30;export delta=30.;name_from_here=1;title="Net sw Top of the Atmosphere";export maxplotdiff=40;export minplotdiff=-40;export deltadiff=10.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FSNT)varobs=var178;export maxplot=420;export minplot=30;export delta=30.;name_from_here=1;title="Net sw Top of Model";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/tnsr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FLNT)varobs=var179;export maxplot=310;export minplot=115;export delta=15.;name_from_here=1;title="Net lw Top of Model";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/tntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld" ;;
             
              FLNSC)varobs=var167;export maxplot=300;export minplot=120;export delta=20.;name_from_here=1;title="Net clear-sky lw Top of Model";cmp2obs=0;;
              FLNS)varobs=var177;export maxplot=200.;export minplot=0.;export delta=20.;name_from_here=1;title="Net lw surface";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/sntr_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;
             SHFLX)varobs=var146;export maxplot=300;export minplot=-20;export delta=20.;name_from_here=1;title="Sensible Heat Flux";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/sshf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;

             LHFLX)varobs=var147;export maxplot=300;export minplot=-20;export delta=20.;name_from_here=1;title="Latent Heat Flux";export maxplotdiff=20;export minplotdiff=-20;export deltadiff=5.;obsfile="$dir_obs3/slhf_era5_1980-2019_mm_ann_cyc.nc";export title2="ERA5 $climobscld";;

#   "lnd"
# title still there but defined in ncl through long_name
                TWS) title="Total Water Storage";cmp2obs=0;;
                TSOI) title="Soil Temp at 80cm";name_from_here=1;cmp2obs=0;;
                H2OSOI) title="Volumetric Soil Water at 1.36m";name_from_here=1;cmp2obs=0;;
                H2OSNO)varobs=sd; title="Snow Depth (liquid water)";varobs=var167;mf=0.01;export maxplot=10;export minplot=0.5;export delta=0.5;units_from_here=1;units="m";name_from_here=1;;
                SNOW) title="Atmospheric Snow";cmp2obs=0;;
                SNOWDP)title="Snow Depth ";varobs=var167;export maxplot=3.;export minplot=0.1;export delta=.05;units_from_here=1;name_from_here=1;units="m";cmp2obs=0;;
                CLDTOT)varobs=var164;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Total cloud cover";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldtot_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";name_from_here=1;;
                CLDMED)varobs=var187;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Mid-level cloud 400-700hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldmed_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";;
                CLDHGH)varobs=var188;export maxplot=0.9;export minplot=0.1;export delta=.1;title="High-level cloud 50-400hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=.6;export minplotdiff=-.6;export deltadiff=.1;obsfile="$dir_obs2/cldhgh_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";;
                CLDLOW)varobs=var186;export maxplot=0.9;export minplot=0.1;export delta=.1;title="Low-level cloud 700-1200hPa";units_from_here=1;units="fraction";name_from_here=1;export maxplotdiff=0.6;export minplotdiff=-0.6;export deltadiff=.1;obsfile="$dir_obs2/cldlow_era5_${climobscld}_ann_cyc.nc";export title2="ERA5 $climobscld";;
                FSH)varobs=var167;export maxplot=100.;export minplot=-100.;export delta=10.;title="Sensible Heat";units_from_here=1;name_from_here=1;cmp2obs=0;export maxplotdiff=10.;export minplotdiff=-10.;export deltadiff=1.;;
                TLAI)varobs=var167;export maxplot=11.;export minplot=1.;export delta=1.;cmp2obs=0;;
                QOVER)title="Total Surface Runoff";export maxplot=0.0003;export minplot=0.;export delta=.00005;name_from_here=1;cmp2obs=0;;
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
               case $ts_gzm_boxes in
                  Global)export lat0=-90;export lat1=90;export bglo=1;;
                  NH)export lat0=0;export lat1=90;export bNH=1;;
                  SH)export lat0=-90;export lat1=0;export bSH=1;;
               esac
               if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
               then  
                  continue
               fi
               if [[ $core == "SE" ]]
               then
                  export srcFileName=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc 
                  export outfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.reg1x1.nc 
                  ncl $dir_SE/regridSE_CAMh0.ncl
                  cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $outfile $inpfile.$ts_gzm_boxes.nc
               else
                  cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
               fi
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
            if [[ $comp == "atm" ]]
            then
              if [[ $core == "SE" ]]
               then
                  lsmfile=/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc
               else
                  lsmfile=$tmpdir1/${expid1}.lsm.nc
                  if [[ ! -f $lsmfile ]]
                  then
                     yfile=$tmpdir1/${expid1}.$realm.$ftype.$yyyy.nc
                     cdo selvar,LANDFRAC $yfile $tmpdir1/${expid1}.lsm.tmp.nc
                     cdo -expr,'LANDFRAC = ((LANDFRAC>=0.5)) ? 1.0 : LANDFRAC/0.0' $tmpdir1/${expid1}.lsm.tmp.nc $tmpdir1/${expid1}.lsm.nc
                  fi
               fi
               slmfile=$tmpdir1/$expid1.slm.nc
               if [[ ! -f $slmfile ]]
               then
                 if [[ $core == "SE" ]]
                  then
                     cdo -expr,'LANDFRAC = (( LANDFRAC==0.0)) ? 2.0: 1.0' /work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc $tmpdir1/$expid1.tmpslm.nc
                     cdo -expr,'LANDFRAC = (( LANDFRAC==2.0)) ? 1.0: 0.0' $tmpdir1/$expid1.tmpslm.nc $slmfile
                     rm $tmpdir/$expid1.tmpslm.nc
                  else
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
#                     ncl plot_hov_lnd.ncl
# testato solo su Zeus VA MOLTO ADATTATO!!
                  done
               fi
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
#                1m)allvars="tos sos zos thetao so";;
                1m)allvars="tos sos zos";;
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
                            ncrename -O -d time_counter,time $tmpdir/${expid1}_${freq}_${yyyy}.tmp.n1c
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
   export outdia=/work/$DIVISION/$USER/CMCC-CM/diagnostics/$expid1'_diag_'$startyear-$lasty
   mkdir -p $outdia
   outnml=$outdia/nml
   # copy locally the namelists
   mkdir -p $outnml
   #   rsync -auv $rundir/*_in $outnml
   #   rsync -auv $rundir/namelist_* $outnml
   #   rsync -auv $rundir/file_def*xml  $outnml
   #
   export plotdir=$outdia/plots/
   mkdir -p $plotdir
   export varmod
   
   units=""
   for varmod in $allvars
   do
      case $varmod in 
         tos)varobs=var235;cf=-273.15;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
         sos)varobs=var235;cf=0;units="PSU";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export cmp2obs=0;export title2="ERA5 $climobs";export maxplot=36.;export minplot=26.;export delta=2.;units_from_here=1;;
         zos)varobs=var235;cf=0;units="m";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs4/ts_era5_1990-2009.anncyc.nc";export cmp2obs=0;export title2="ERA5 $climobs";export maxplot=3.;export minplot=-3.;export delta=0.5;units_from_here=1;;
      esac
      export units_from_here=0
      export name_from_here=0
      if [[ ! -f $tmpdir/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
      then
         continue
      fi
      if [[ $comp == "ocn" ]]
      then
          ocnlist+=" \"$varmod\","
      fi
      export cf=0
#      export mf=1
      export yaxis
      export title=""
      export units=""
      export varmod2=""
      export obsfile
      export computedvar=""
      export compute=0
      export cmp2obs
# units only for vars that need conversion
      case $varmod in
           tos)varobs=SST;units="Celsius deg";export inpfileobs=t2m_era5_1979-2021.yy.fldmean.;export obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_surface.nc";export cmp2obs=1;export title2="ERA5 $climobs";export maxplot=36;export minplot=-20;export delta=2;units_from_here=1;;
      esac
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

export outdia=/work/$DIVISION/$USER/CMCC-CM/diagnostics/$expid1'_diag_'$startyear-$lasty
mkdir -p $outdia


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
