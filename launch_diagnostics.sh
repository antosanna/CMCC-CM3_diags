#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J timeseries_parallel
#BSUB -e logs/timeseries_parallel_%J.err
#BSUB -o logs/timeseries_parallel_%J.out
#BSUB -q s_long

#ALBEDO=(FSUTOA)/SOLIN  [ con SOLIN=FSUTOA+FSNTOA]
#https://atmos.uw.edu/~jtwedt/GeoEng/CAM_Diagnostics/rcp8_5GHGrem-b40.20th.track1.1deg.006/set5_6/set5_ANN_FLNT_c.png

set -eux  
# SECTION TO BE MODIFIED BY USER
debug=0
nmaxproc=6
sec1=0  #flag to execute section1 (1=yes; 0=no)
sec2=0  #flag to execute section2 (1=yes; 0=no)
sec3=1  #flag to execute section3 (1=yes; 0=no)
sec4=0  #flag for section4 (=nemo postproc) (1=yes; 0=no)
sec5=0  #flag for section5 (=QBO postproc) (1=yes; 0=no)
machine="juno"
do_atm=1
do_ice=0
do_lnd=1
do_timeseries=1
do_znl_lnd=0
do_znl_atm=1
do_znl_atm2d=0
do_2d_plt=1
do_anncyc=1

# model to diagnose
export expid1=cm3_cam122d_2000_1d32l_t9b
#export expid1=cm3_cam116d_2000_t1
#export expid1=SPS3.5_2000_cont
#export expid1=cm3_cam122_cpl2000-bgc_t09c
#export expid1=SPS3.5_2000_cont
#utente1=cp1
#utente1=sps-dev
utente1=dp16116
cam_nlev1=32
#cam_nlev1=83
core1=FV
#
# second model to compare with
#expid2=cam109d_cm3_1deg_amip1981-bgc_t2
#utente2=mb16318
#export expid2=cm3_cam122_cpl2000-bgc_t01
export expid2=cm3_cam116d_2000_1d32l_t1
utente2=cp1
cam_nlev2=32
core2=FV
#
export startyear="0001"
export finalyear="0020"
export startyear_anncyc="0001" #starting year to compute 2d map climatology
export nyrsmean=20   #nyear-period for mean in timeseries
# select if you compare to model or obs 
export cmp2obs=1
# END SECTION TO BE MODIFIED BY USER

if [[ $cmp2obs -eq 0 ]]
then
   export cmp2mod=1
else
   export cmp2mod=0
fi
here=$PWD
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
mkdir -p $tmpdir1/scripts

    # time-series zonal plot (3+5)
 
    ## NAMELISTS
pltdir=$tmpdir1/plots
mkdir -p $pltdir
mkdir -p $pltdir/atm $pltdir/lnd $pltdir/ice $pltdir/ocn $pltdir/namelists

export pltype="png"
if [[ $debug -eq 1 ]]
then
   pltype="x11"
fi
export units
export title
#allvars_atm="AODVIS BURDENBC BURDENSOA BURDENPOM BURDENSO4 BURDENDUST BURDEN1 BURDENdn1  BURDEN2 BURDENdn2 BURDEN3 BURDENdn3 BURDEN4 BURDENdn4 BURDENB  BURDENDUST BURDENPOM BURDENSEASALT BURDENSOA  BURDENSO4"
allvars_atm="ALBEDO ALBEDOS CLDLOW CLDMED CLDHGH CLDTOT CLDICE CLDLIQ FLUT FLUTC FLDS FSDSC FLNS FLNSC FSNSC FSNTOA FSNS FSDS FSNT FLNT ICEFRAC  LHFLX SHFLX LWCF SWCF SOLIN RESTOM EmP PRECT PRECC PS QFLX TGCLDCWP TGCLDLWP TGCLDIWP TREFHT TS Z010 Z100 Z500 Z700 Z850 U010 U100 U200 U700 T U Z3"
allvars_lnd="SNOWDP FSH TLAI FAREA_BURNED";
allvars_ice="aice snowfrac ext Tsfc fswup fswdn flwdn flwup congel fbot albsni hi";
allvars_oce="tos sos zos heatc saltc";
    
############################################
#  First section: postprocessing
############################################
if [[ $sec1 -eq 1 ]]
then
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
               bsub -P 0566 -M 5000 -q s_medium -J postproc_single_var_${var} -e logs/postproc_single_var_${var}_%J.err -o logs/postproc_single_var_${var}_%J.out $here/postproc_single_var.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $startyear_anncyc $nyrsmean $cmp2obs $cmp2mod $here $comp $exp $var 
         
               while `true`
               do
                  njob=`bjobs -w|grep postproc_single_var_|wc -l`
                  if [[ $njob -gt $nmaxproc ]]
                  then
                     sleep 20
                  else
                     break
                  fi
               done
            done   #loop on var
         fi
      done
   done
   finalyearplot[$i]=$lasty
   i=$(($i + 1))
done #expid
fi # end of section 1
while `true`
do
   njob=`bjobs -w|grep postproc_single_var_|wc -l`
   if [[ $njob -eq 0 ]]
   then
      break
   fi
done
############################################
#  end of first section
############################################
#
############################################
#  Second: timse-series, 2d maps and annual cycles
############################################
export tmpdir=$tmpdir1
if [[ $sec2 -eq 1 ]]
then
for comp in $comps
do
   case $comp in
      atm) allvars=$allvars_atm;realm=cam;typelist="h0";;
      lnd) allvars=$allvars_lnd;typelist="h0";
          realm=clm2;;
      ice) allvars=$allvars_ice;realm=cice;typelist="h";;
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
      ijob=0
      for varmod in $allvars
      do
         bsub -P 0566 -q s_medium -M 85000 -J diagnostic_single_var_${varmod} -e logs/diagnostic_single_var_${varmod}_%J.err -o logs/diagnostic_single_var_${varmod}_%J.out $here/diagnostics_single_var.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $startyear_anncyc $cmp2obs $cmp2mod $pltype $varmod $comp $do_timeseries $do_znl_lnd $do_znl_atm $do_znl_atm2d $do_2d_plt $do_anncyc
         while `true`
         do
            ijob=`bjobs -w|grep diagnostic_single_var_|wc -l`
            if [[ $ijob -gt $nmaxproc ]]
            then
               sleep 45
            else
               break
            fi
         done
      done
        
   done   #loop on ftype
done   #loop on comp
fi   # end of section2

############################################
#  End of second section
############################################

############################################
#  Third: zonal plot 3d vars
############################################
if [[ $sec3 -eq 1 ]]
then
if [[ $do_znl_atm -eq 1 ]]
then
      comp=atm
      export obsfile=$dir_obs2/Vars_plev_era5_1979-2018_anncyc.nc

      export varmod
      export sea
      export PSfile=$tmpdir1/${expid1}.cam.PS.$startyear-$lasty.anncyc.nc
      export Tfile=$tmpdir1/${expid1}.cam.T.$startyear-$lasty.anncyc.nc
# here take PS and hyam
      realm=cam
      model=CMCC-CM3
      if [[ $machine == "zeus" ]]
      then
          model=CESM2
         if [[ $utente1 == "dp16116" ]]
         then 
            model=CMCC-CM
         fi   
         if [[ $core1 == "SE" ]]
         then
            model=CESM
         fi
         rundir=/work/$DIVISION/$utente1/$model/$expid1/run
         export inpdirroot=/work/csp/$utente1/$model/archive/$expid1
         if [[ $utente1 == "dp16116" ]]
         then
            export inpdirroot=/work/csp/$utente1/CESM2/archive/$expid1
         fi
      else
         rundir=/work/$DIVISION/$utente1/CMCC-CM/$expid1/run
         export inpdirroot=/work/csp/$utente1/CMCC-CM/archive/$expid1
      fi
      export auxfile=$inpdirroot/atm/hist/${expid1}.$realm.h0.$startyear-01.nc
      comppltdir=$pltdir/${comp}
      mkdir -p $comppltdir
      for varmod in Z3 T U
      do
         export modfile=$tmpdir1/${expid1}.$realm.$varmod.$startyear-$lasty.anncyc.nc
         if [[ $debug -eq 1 ]]
         then
            $here/diagnostics_single_var3d.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $nyrsmean $cmp2obs $cmp2mod $obsfile $varmod $PSfile $Tfile $auxfile $pltype $here
            exit
         else
            bsub -P 0566 -q s_medium -M 85000 -J diagnostic_single_var3d_${varmod} -e logs/diagnostic_single_var3d_${varmod}_%J.err -o logs/diagnostic_single_var3d_${varmod}_%J.out $here/diagnostics_single_var3d.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $nyrsmean $cmp2obs $cmp2mod $obsfile $varmod $PSfile $Tfile $auxfile $pltype $here
         fi
      done
fi   #do_znl_atm
fi   # end of sec3
############################################
#  End of section3
############################################


tmpdir=$tmpdir1   #TMP
############################################
#  Section4: postprocessing and diagnostics for Nemo
############################################
do_anncyc=0 #not yet implemented
if [[ $sec4 -eq 1 ]]
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
   model=CMCC-CM3
   if [[ $machine == "zeus" ]]
   then
       model=CESM2
      if [[ $utente1 == "dp16116" ]]
      then 
         model=CMCC-CM
      fi   
      if [[ $core1 == "SE" ]]
      then
         model=CESM
      fi
      rundir=/work/$DIVISION/$utente1/$model/$expid1/run
      export inpdirroot=/work/csp/$utente1/$model/archive/$expid1
      if [[ $utente1 == "dp16116" ]]
      then
         export inpdirroot=/work/csp/$utente1/CESM2/archive/$expid1
      fi
   else
      rundir=/work/$DIVISION/$utente1/CMCC-CM/$expid1/run
      export inpdirroot=/work/csp/$utente1/CMCC-CM/archive/$expid1
   fi
   for ftype in $typelist
   do
      inpdir=$inpdirroot/$comp/hist
      export realm="nemo"
      for freq in $freqlist
      do
         case $freq in
            1m)allvars=$allvars_oce;;
         esac
         echo $allvars
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


         for var in $allvars
         do
            bsub -P 0566 -M 8000 -q s_medium -J postproc_sing_var_nemo_${var} -e logs/postproc_sing_var_nemo_${var}_%J.err -o logs/postproc_sing_var_nemo_${var}_%J.out $here/postproc_sing_var_nemo.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $cmp2mod $here $var
         
         done   #loop on vars
      done  #loop freq
   done   #loop type
   while `true`
   do
      njob=`bjobs -w|grep postproc_sing_var_nemo|wc -l`
      if [[ $njob -gt $nmaxproc ]]
      then
         sleep 20
      else
         break
      fi
   done

   outnml=$tmpdir1/nml
   # copy locally the namelists
   mkdir -p $outnml
   
   for varmod in $allvars
   do
      bsub -P 0566 -M 5000 -q s_medium -J diagnostics_sing_var_nemo_${var} -e logs/diagnostics_sing_var_nemo_${var}_%J.err -o logs/diagnostics_sing_var_nemo_${var}_%J.out $here/diagnostics_sing_var_nemo.sh $machine $expid1 $utente1 $cam_nlev1 $core1 $expid2 $utente2 $cam_nlev2 $core2 $startyear $finalyear $startyear_anncyc $nyrsmean $cmp2obs $here $varmod $do_timeseries $do_2d_plt $do_anncyc
      while `true`
      do
         njob=`bjobs -w|grep diagnostics_sing_var_nemo|wc -l`
         if [[ $njob -gt $nmaxproc ]]
         then
            sleep 20
         else
            break
         fi
      done
   done
fi
############################################
#  end of section 4 
############################################

############################################
#  Start section 5 QBO 
############################################
if [[ $sec5 -eq 1 ]]
then
   export iniy=$startyear
   export lasty=$finalyear
   listamerge=""
   for yyyy in `seq -w $iniy $lasty`
   do
      listamerge+=" $tmpdir1/${exp_name}.cam.U.${yyyy}.nc"
   done
   if [[ ! -f $tmpdir1/${exp_name}.cam.U.${iniy}-$lasty.nc ]]
   then
      cdo -O mergetime ${listamerge} ${tmpdir1}/${exp_name}.cam.U.${iniy}-$lasty.ncfi
   export infile=$tmpdir1/${exp_name}.cam.QBO.${iniy}-$lasty.nc
   if [[ ! -f $tmpdir1/${exp_name}.cam.QBO.${iniy}-$lasty.nc ]]
   then
      cdo -O fldmean -sellonlatbox,0,360,-2,2 ${tmpdir1}/${exp_name}.cam.U.${iniy}-$lasty.nc $infile
   fi
   export pltname=$pltdir/atm/QBO_${exp_name}.$iniy-$lasty
   ncl plot_QBO_bw.ncl
fi
############################################
#  end of section 5 QBO 
############################################

cd $here
while `true`
do
   ijob=`bjobs -w|grep diagnostic_single_var|wc -l`
   if [[ $ijob -eq 0 ]]
   then
      break
   fi
   sleep 40
done


if [[ -f $pltdir/index.html ]]
then
   rm -f $pltdir/index.html
fi
for fld in `ls $tmpdir1/plots/atm/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   atmlist+=" \"$fld\","
done
for fld in `ls $tmpdir1/plots/lnd/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   lndlist+=" \"$fld\","
done
for fld in `ls $tmpdir1/plots/ocn/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   ocnlist+=" \"$fld\","
done
for fld in `ls $tmpdir1/plots/ice/*${startyear}-${lasty}*|rev|cut -d '.' -f 4|rev|sort -n |uniq`
do
   icelist+=" \"$fld\","
done
sed -e 's/DUMMYCLIM/'$startyear-${lasty}'/g;s/DUMMYEXPID/'$expid1'/g;s/atmlist/'"$atmlist"'/g;s/lndlist/'"$lndlist"'/g;s/icelist/'"$icelist"'/g;s/ocnlist/'"$ocnlist"'/g' index_tmpl.html > $pltdir/index.html
cd $pltdir
if [[ $cmp2mod -eq 0 ]] 
then
   tar -cvf $expid1.$startyear-${lasty}.VSobs.tar atm lnd ice ocn index.html
   gzip -f $expid1.$startyear-${lasty}.VSobs.tar
else
   tar -cvf $expid1.$startyear-${lasty}.VS$expid2.tar atm lnd ice ocn index.html
   gzip -f $expid1.$startyear-${lasty}.VS$expid2.tar
fi

if [[ -d $tmpdir1/scripts ]]
then
   rm -rf $tmpdir1/scripts
fi

exit
