#!/bin/sh -l
set -eux  
# SECTION TO BE MODIFIED BY USER
machine=$1
expid1=$2
utente1=$3
cam_nlev1=$4
core1=$5
expid2=$6
utente2=$7
cam_nlev2=$8
core2=$9
startyear=${10}
lastyear=${11}
startyear_anncyc=${12} #starting year to compute 2d map climatology
nyrsmean=${13}   #nyear-period for mean in timeseries
cmp2obs=${14}
cmp2mod=${15}
here=${16}
comp=${17}
exp=${18}
var=${19}
#end input section

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
i=0
export rootinpfileobs
icelist=""
atmlist=""
lndlist=""
ocnlist=""
export lasty=$finalyear
export autoprec=True
user=$USER
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
#      atm) allvars=$allvars_atm;realm=cam;;
#      lnd) allvars=$allvars_lnd; realm=clm2;;
#      ice) allvars=$allvars_ice;realm=cice;;
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
   finalyearplot[$i]=$lasty
   i=$(($i + 1))
done #expid
