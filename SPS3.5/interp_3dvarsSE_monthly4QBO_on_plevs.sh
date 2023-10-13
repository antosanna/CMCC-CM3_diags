#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J 3dvarsSE
#BSUB -e logs/3dvarsSE_%J.err
#BSUB -o logs/3dvarsSE_%J.out
#BSUB -q s_long


set -eux  
# SECTION TO BE MODIFIED BY USER
machine="zeus"
do_atm=1

# model to diagnose
export expid1=SPS3.5_2000_cont
#export expid1=cm3_cam109d_2000_t1
utente1=$USER
cam_nlev1=46
core1=SE
#
export var
export startyear="0001"
export finalyear="0040"
# END SECTION TO BE MODIFIED BY USER

i=1
do_compute=1
export expname1=${expid1}_${cam_nlev1}
dir_SE=$PWD/SPS3.5
dir_SE=$PWD
dirdiag=/work/$DIVISION/$USER/diagnostics/
mkdir -p $dirdiag
set +euvx  
   . ../mload_cdo_zeus
   . ../mload_nco_zeus
set -euvx  
   export dir_lsm=/work/csp/sps-dev/CESMDATAROOT/CMCC-SPS3.5/regrid_files/
   dir_obs1=/data/inputs/CESM/inputdata/cmip6/obs/
   dir_obs2=/data/delivery/csp/ecaccess/ERA5/monthly/025/
   dir_obs3=/work/csp/mb16318/obs/ERA5
   dir_obs4=/work/csp/as34319/obs/ERA5
export iniclim=$startyear

#
atmlist=""
export lasty=$finalyear
user=$USER
    # model components
comps=""
if [[ $do_atm -eq 1 ]]
then
    comps="atm"
fi
    # read arguments
echo 'Experiment : ' $expid1
echo 'Processing year(s) period : ' $startyear ' - ' $finalyear
#
opt=""
if [[ $core1 == "SE" ]]
then
   tmpdir1=$dirdiag/$utente1/$expid1/
fi
mkdir -p $tmpdir1

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$tmpdir1/plots
mkdir -p $pltdir
mkdir -p $pltdir/atm 
export tmpdir=$tmpdir1
export ncl_lev
export ncl_plev
export cf=0
export mf=1
export computedvar=""
export compute=0

allvars="U"
    
for exp in $expid1
do
   case $exp in
      $expid1)utente=$utente1;core=$core1 ;;
   esac
   model=CESM
   rundir=/work/$DIVISION/$utente/$model/$exp/run
   export inpdirroot=/work/csp/$utente/$model/archive/$exp
   export tmpdir=$dirdiag/$utente/$exp/
   mkdir -p $tmpdir
   var2plot=" "
   export comp
   for comp in $comps
   do
      case $comp in
         atm)typelist="h0";; 
      esac
      for ftype in $typelist
      do
         echo "-----going to postproc $comp"
         realm=cam;
         inpdir=$inpdirroot/$comp/hist
         if [[ $do_compute -eq 1 ]]
         then
            echo $allvars
         
            for yyyy in `seq -f "%04g" $startyear $finalyear`
            do
                echo "-----going to postproc year $yyyy"
                yfile=$tmpdir/${exp}.$realm.$ftype.$yyyy.nc
                if [[ $ftype == "h0" ]]
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
                for var in $allvars
                do
         
                   opt="";opt1="";
                   echo "-----going to postproc variable $var"
                   ymfilevar=$tmpdir/${exp}.$realm.$var.$yyyy.nc
                   if [[ ! -f $ymfilevar ]]
                   then
                      ret1=`ncdump -v $var ${yfile}|head -1`
                      if [[ "$ret1" == "" ]]; then
                         continue
                      fi
                      cdo $opt -selvar,$var $yfile $ymfilevar
                   fi
           
                   for ncl_plev in 850 700 500 250 200 100 75 50 25 10 5
                   do
                      export inpfile=$ymfilevar
                      export phisFileName=$inpdir/${expid1}.$realm.h0.0001-01.nc 
                      export psFileName=$tmpdir1/${expid1}.$realm.PS.$yyyy.nc
                      export tFileName=$tmpdir1/${expid1}.$realm.T.$yyyy.nc
                      export srcFileName=$tmpdir1/${expid1}.$realm.$var.$yyyy.nc
                      export outfile=$tmpdir1/${expid1}.$realm.${var}`printf '%.3i' ${ncl_plev}`.$yyyy.reg1x1.nc 
                      if [[ $var == "Z3" ]]
                      then
                         export outfile=$tmpdir1/${expid1}.$realm.Z`printf '%.3i' ${ncl_plev}`.$yyyy.reg1x1.nc 
                      fi
                      if [[ ! -f $outfile ]]
                      then
                         ncl $dir_SE/interp_3dvarsSE.ncl
                         if [[ $var == "Z3" ]]
                         then
                            ncrename -h -O -v $var,Z`printf '%.3i' ${ncl_plev}` $outfile $outfile.tmp
                         else
                            ncrename -h -O -v $var,${var}`printf '%.3i' ${ncl_plev}` $outfile $outfile.tmp
                         fi
                         mv $outfile.tmp $outfile
                      fi
                   done  #loop on ncl_plev
                done  #loop on var
        
            done   #loop on years
         fi
      done   #loop on ftype
   done   #loop on comp
done   #loop on expid

