#!/bin/sh -l
set -euvx
tmpdir=$1
machine=$2
expid1=$3
utente1=$4
core1=$5
expid2=$6
utente2=$7
core2=$8
startyear=$9
finalyear=${10}
cmp2mod=${11}
here=${12}
typelist=${13}
inpdirroot=${14}
freqlist=${15}
allvars_oce=${16}
nmaxproc=${17}
debug=${18}
############################################
#  postprocessing for Nemo
############################################
do_anncyc=0 #not yet implemented
comp=ocn
inpdir=$inpdirroot/$comp/hist
export realm="nemo"
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
      rundir=/work/cmcc/$utente1/CMCC-CM/$expid1/run
      export inpdirroot=/work/cmcc/$utente1/CMCC-CM/archive/$expid1
fi
for ftype in $typelist
do
   inpdir=$inpdirroot/$comp/hist
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
         if [[ $debug -eq 1 ]]
         then
            $here/postproc_sing_var_nemo.sh $machine $expid1 $utente1 $core1 $expid2 $utente2 $core2 $startyear $finalyear $cmp2mod $here $var
         else
            bsub -P 0566 -M 8000 -q s_medium -J postproc_sing_var_nemo_${var} -e logs/postproc_sing_var_nemo_${var}_%J.err -o logs/postproc_sing_var_nemo_${var}_%J.out $here/postproc_sing_var_nemo.sh $machine $expid1 $utente1 $core1 $expid2 $utente2 $core2 $startyear $finalyear $cmp2mod $here $var
         fi
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
         
      done   #loop on vars
   done  #loop freq
done   #loop type
while `true`
do
   njob=`bjobs -w|grep postproc_sing_var_nemo|wc -l`
   if [[ $njob -gt 0 ]]
   then
      sleep 20
   else
      break
   fi
done

#outnml=$tmpdir1/nml
   # copy locally the namelists
#mkdir -p $outnml
   
for varmod in $allvars
do
   if [[ $debug -eq 1 ]]
   then
      $here/diagnostics_sing_var_nemo.sh $machine $expid1 $utente1 $core1 $expid2 $utente2 $core2 $startyear $finalyear $startyear_anncyc $nyrsmean $cmp2obs $here $varmod $do_timeseries $do_2d_plt $do_anncyc
   else
      bsub -P 0566 -M 5000 -q s_medium -J diagnostics_sing_var_nemo_${var} -e logs/diagnostics_sing_var_nemo_${var}_%J.err -o logs/diagnostics_sing_var_nemo_${var}_%J.out $here/diagnostics_sing_var_nemo.sh $machine $expid1 $utente1 $core1 $expid2 $utente2 $core2 $startyear $finalyear $startyear_anncyc $nyrsmean $cmp2obs $here $varmod $do_timeseries $do_2d_plt $do_anncyc
   fi
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
############################################
