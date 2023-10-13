#!/bin/sh -l
#BSUB -M 85000   #if you get BUS error increase this number
#BSUB -P 0566
#BSUB -J timeseries
#BSUB -e logs/timeseries_%J.err
#BSUB -o logs/timeseries_%J.out
#BSUB -q s_long

set -eux  
# SECTION TO BE MODIFIED BY USER
machine="zeus"
do_atm=1
do_timeseries=1
do_znl_atm=0
do_znl_atm2d=0
do_2d_plt=1
do_anncyc=1

# model to diagnose
export expid1=SPS3.5_2000_cont
#export expid1=cm3_cam122_cpl2000-bgc_t01
utente1=$USER
#utente1=dp16116
cam_nlev1=46
#cam_nlev1=83
core1=SE
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
export finalyear="0040"
export startyear_anncyc="0001" #starting year to compute 2d map climatology
export nyrsmean=20   #nyear-period for mean in timeseries
# select if you compare to model or obs 
cmp2obs=1
cmp2mod=0
export cmp2obs_ncl
export cmp2mod_ncl
# END SECTION TO BE MODIFIED BY USER

export mftom1=1
export varobs
export varmod
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
atmlist=""
export lasty=$finalyear
export autoprec=True
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

export pltype="png"
export units
export title
allvars_atm="Z010 Z100 Z200 Z500 Z700 Z850 U010 U100 U200 U700"
    
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
done #expid

export tmpdir=$tmpdir1
comp=atm
allvars=$allvars_atm;realm=cam
units=""
echo $allvars
for var in $allvars
do
   export units_from_here=0
   export name_from_here=0
   if [[ ! -f $tmpdir/${expid1}.$realm.$var.$startyear-${lasty}.ymean.reg1x1.nc ]]
   then
      echo $tmpdir/${expid1}.$realm.$var.$startyear-${lasty}.ymean.reg1x1.nc
      continue
   fi
   atmlist+=" \"$var\","
   export mf=1
   export yaxis
   export title=""
   export title2=""
   export units=""
   export varmod2=""
   export ncl_plev=0
   export obsfile=dummy
   export computedvar=""
   export compute=0
   export cmp2obs=1
   if [[ $cmp2mod -eq 1 ]]
   then
      export modfile=$tmpdir2/${expid2}.$realm.$var.$iniclim-$lasty.anncyc.nc
      cmp2obs=0
   fi
#   "atm" 
# units only for vars that need conversion
   export ncl_lev
   export mf
   export cf
   export comp=atm
   cmp2obs_ncl=$cmp2obs
   cmp2mod_ncl=$cmp2mod
   case $var in
                U010)varobs=var131;export cf=0;export mf=1;units="m";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=0;title2="ERA5 $climobs";export maxplot=60.;export minplot=-20;export delta=10;units_from_here=0;export maxplotdiff=8;export minplotdiff=-8;export deltadiff=2.;export cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=U;;
                U100)varobs=var131;export cf=0;export mf=1;units="m";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30;export delta=10;units_from_here=0;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;export cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=U;;
                U700)varobs=var131;export cf=0;export mf=1;units="m";obsfile="$dir_obs4/uplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30;export delta=10;units_from_here=0;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;export cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=U;;
                U200)varobs=U;export cf=0;export mf=1;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=1;title2="ERA5 $climobs";export maxplot=30.;export minplot=-30;export delta=10;units_from_here=0;export maxplotdiff=10;export minplotdiff=-10;export deltadiff=2.;export cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=U;;
                Z010)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=1;title2="ERA5 $climobs";mf=1.;export maxplot=31600.;export minplot=28800;export delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=Z3;;
                Z100)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=2;title2="ERA5 $climobs";mf=1.;export maxplot=16800.;export minplot=15000;export delta=100;units_from_here=1;export maxplotdiff=200;export minplotdiff=-200;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=Z3;;
                Z700)varobs=var129;cf=0;units="m";obsfile="$dir_obs4/Zplev_era5_1979-2018_anncyc.nc";ncl_lev=4;title2="ERA5 $climobs";mf=1.;export maxplot=3200.;export minplot=2600;export delta=20;units_from_here=1;export maxplotdiff=100;export minplotdiff=-100;export deltadiff=20.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=Z3;;
                Z500)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=3;title2="ERA5 $climobs";mf=1.;export maxplot=5900.;export minplot=4800;export delta=100;units_from_here=1;export maxplotdiff=50;export minplotdiff=-50;export deltadiff=5.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=Z3;;
                Z850)varobs=Z;cf=0;units="m";obsfile="$dir_obs1/ERA5_1m_clim_1deg_1979-2018_prlev.nc";ncl_lev=5;title2="ERA5 $climobs";mf=1;export maxplot=1550.;export minplot=1050.;export delta=50;units_from_here=1;export maxplotdiff=50.;export minplotdiff=-50;export deltadiff=5.;cmp2mod_ncl=$cmp2mod;export cmp2obs_ncl=$cmp2obs;varmod=Z3;;

   esac
   export inpfile=$tmpdir1/${expid1}.$comp.$var.$startyear-${lasty}.ymean.fldmean
   comppltdir=$pltdir/${comp}
   mkdir -p $comppltdir
   if [[ $do_timeseries -eq 1 ]]
   then
      export pltname=$comppltdir/${expid1}.$comp.$var.$startyear-${lasty}.TS_3
      export b7090=0;export b3070=0;export b3030=0;export b3070S=0;export b7090S=0;export bglo=0;export bNH=0;export SH=0;export bland=0;export boce=0
      export hplot="0.3"
      for ts_gzm_boxes in Global NH SH 
      do
#         inpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$ts_gzm_boxes.nc
#         echo "obs to compare timeseries " $inpfileobs
#         rootinpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`
         case $ts_gzm_boxes in
            Global)export lat0=-90;export lat1=90;export bglo=1;;
            NH)export lat0=0;export lat1=90;export bNH=1;;
            SH)export lat0=-90;export lat1=0;export bSH=1;;
         esac
#         if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [[ ! -f $tmpdir1/${expid1}.$realm.$varmod.$startyear-${lasty}.ymean.nc ]]
#         then  
#            continue
#         fi
         if [[ $core == "SE" ]]
         then
            export srcFileName=$tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.nc 
            export outfile=$tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.reg1x1.nc 
            if [[ ! -f $outfile ]]
            then
               ncl $dir_SE/regridSE_CAMh0.ncl
            fi
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $outfile $inpfile.$ts_gzm_boxes.nc
         else
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
         fi
#         if [[ ! -f $inpfileobs ]]
#         then
#            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $obsfile $inpfileobs
#         fi
      done
      # do plot_timeseries
      ncl plot_timeseries_xy_panel.ncl
      if [[ $pltype == "x11" ]]
      then
         exit
      fi  
      export pltname=$comppltdir/${expid1}.$comp.$var.$startyear-${lasty}.TS_5
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
         if [[ -f ${inpfile}.$ts_gzm_boxes.nc ]] || [ ! -f $tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.nc -a ! -f $tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.reg1x1.nc ]
         then  
            continue
         fi
         if [[ $core == "SE" ]]
         then
            export srcFileName=$tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.nc 
            export outfile=$tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.reg1x1.nc 
            if [[ ! -f $outfile ]]
            then
               ncl $dir_SE/regridSE_CAMh0.ncl
            fi
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $outfile $inpfile.$ts_gzm_boxes.nc
         else
            cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $tmpdir1/${expid1}.$realm.$var.$startyear-${lasty}.ymean.nc $inpfile.$ts_gzm_boxes.nc
         fi
       done
      # do plot_timeseries
       ncl plot_timeseries_xy_panel.ncl
   fi #do_timeseries
   export varobs
   comppltdir=$pltdir/${comp}
   # now 2d maps
   if [[ $do_2d_plt -eq 1 ]]
   then
      echo "---now plotting 2d $var"
      if [[ $core == "FV" ]]
      then
         export inpfile=$tmpdir1/${expid1}.$realm.$var.$iniclim-$lasty.anncyc.nc
      else
         export inpfile=$tmpdir1/${expid1}.$realm.$var.$iniclim-$lasty.anncyc.reg1x1.nc
      fi
      if [[ ! -f $inpfile ]]
      then
            echo "your file $inpfile does not exist"
            continue
      fi
#units defined only where conversion needed
      if [[ $cmp2mod -eq 1 ]]
      then
         export title2mod="$expname2    $iniclim-${finalyearplot2}"
      fi
      export title1="$iniclim-${finalyear}"
      export right="[$units]"
      export left="$var"
      export sea
      for sea in ANN DJF JJA
      do
                 export pltname=$comppltdir/${expid1}.$comp.$var.map_${sea}.png
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
         export inpfile=$tmpdir1/${expid1}.$realm.$var.$iniclim-$lasty.anncyc.nc
      else
         export inpfile=$tmpdir1/${expid1}.$realm.$var.$iniclim-$lasty.anncyc.reg1x1.nc
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
            if [[ "$obsfile" != "dummy" ]]
            then
            regfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev`.$reg.nc
            if [[ ! -f $regfileobs ]]
            then
               cdo fldmean -sellonlatbox,0,360,$lat0,$lat1 $obsfile $regfileobs
            fi
            fi
         fi
      done
      export rootinpfileobs=$tmpdir1/`basename $obsfile|rev|cut -d '.' -f2-|rev` 
      export inpfileanncyc=$tmpdir1/`basename $inpfile|rev|cut -d '.' -f2-|rev` 
      export pltname=$comppltdir/${expid1}.$comp.$var.$startyear_anncyc-$lasty.anncyc_3.png
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
                  export inpfileznl=$tmpdir1/${expid1}.$comp.$var.$startyear-${lasty}.znl.$sea.nc
                  if [[ ! -f $inpfileznl ]]
                  then
                     inpfileznl=$tmpdir1/${expid1}.$comp.$var.$startyear-${lasty}.znlmean.$sea.nc
                     if [[ ! -f $inpfileznl ]]
                     then
                        if [[ $core == "FV" ]]
                        then
                           anncycfile=$tmpdir1/${expid1}.$realm.$var.$startyear-$lasy.anncyc.nc 
                        else
                           anncycfile=$tmpdir1/${expid1}.$realm.$var.$startyear-$lasy.anncyc.reg1x1.nc 
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
                     obsfileznl=$scratchdir/$var.obs.$sea.znlmean.nc1
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
      done  #loop on varmod
        

#ymeanfilevar=$tmpdir/${expid1}.$realm.$var.$startyear-$lasty.ymean.nc

#add loop on exp
tmpdir=$tmpdir1   #TMP


if [[ -f $pltdir/index.html ]]
then
   rm -f $pltdir/index.html
fi
sed -e 's/DUMMYCLIM/'$startyear-${lasty}'/g;s/DUMMYEXPID/'$expid1'/g;s/atmlist/'"$atmlist"'/g;s/lndlist/'""'/g;s/icelist/'""'/g;s/ocnlist/'""'/g' index_tmpl.html > $pltdir/index.html
cd $pltdir
if [[ $cmp2mod -eq 0 ]] 
then
   tar -cvf $expid1.$startyear-${lasty}.plev.VSobs.tar atm index.html
   gzip -f $expid1.$startyear-${lasty}.plev.VSobs.tar
else
   tar -cvf $expid1.$startyear-${lasty}.plev.tar atm index.html
   gzip -f $expid1.$startyear-${lasty}.plev.tar
fi

#echo "all done plots $expid1 $startyear-$lasty" |mail -a plots.$startyear-${lasty}.tar.gz antonella.sanna@cmcc.it

exit
