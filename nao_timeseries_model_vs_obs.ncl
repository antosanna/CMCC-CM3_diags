begin

;------ Select IOD-W and IOD-E regions
inilatposi=34
endlatposi=36
inilatnega=64
endlatnega=66
inilon=-80
endlon=30

;=======================================================
; constants
;=======================================================
  deg2rad=4.*atan(1.)/180.

;------ Load model files
varf="PSL"
year=ispan(1,30,1)
anno=sprinti("%0.4i", year)
pathfile="/work/csp/as34319/diagnostics/dp16116/cm3_cam122_cpl2000-bgc_t01c/"
all_filem=pathfile+"cm3_cam122_cpl2000-bgc_t01c.cam.PSL."+anno+".nc"

fallm=addfiles(all_filem,"r")
ListSetType(fallm,"join")
mslptmp=fallm[:]->$varf$
mslptmp = lonFlip(mslptmp)
lat=fallm[:]->lat(0,:)
lon=fallm[:]->lon(0,:)
wgt = sqrt(cos(tofloat(lat)*deg2rad))
mslptmp=mslptmp*conform(mslptmp, wgt, 2)
NN=dimsizes(mslptmp)
ny=NN(0)
nt=NN(1)
print(nt)
nlat=NN(2)
nlon=NN(3)
; --- flip longitude coordinate
lon0 = lon
lonn = lon({lon(nlon/2):lon(nlon-1)})
lonn = (/lonn-360./)
nlonn = dimsizes(lonn)
lonp = lon({lon(0):lon(nlon/2-1)})
nlonp = dimsizes(lonp)
lon0(0:nlonn-1) = lonn
lon0(nlonn:nlon-1) = lonp

mslp_clim=dim_avg_n_Wrap(mslptmp,0)
mslpMOD=mslptmp
do y=0,ny-1
   mslpMOD(y,:,:,:)=mslptmp(y,:,:,:)-mslp_clim
end do

;---- Calculate Model standard yearly deviation 
stdmslpMOD=dim_stddev_n_Wrap(mslpMOD,0)

;=====================================================
; compute the 3 NAOI for model
;=====================================================
NAO_mod=mslpMOD(:,:,0,0)
do y=0,ny-1
   NAO_mod(y,:)  = dim_avg_n(dim_avg_n(mslpMOD(y,:,{inilatposi:endlatposi},{inilon:endlon})/stdmslpMOD(:,{inilatposi:endlatposi},{inilon:endlon}),1),1)-dim_avg_n(dim_avg_n(mslpMOD(y,:,{inilatnega:endlatnega},{inilon:endlon})/stdmslpMOD(:,{inilatnega:endlatnega},{inilon:endlon}),1),1)
end do

NAO_mod_reshape=reshape(NAO_mod,(/ny*nt/))
NAO_mod_runavg=runave_n_Wrap(NAO_mod_reshape,3,0,0)


time=new((/ny*nt/),"float",-999)
do t=0,(ny*nt)-1
   time(t)=t
end do
time@units = "months since 1993-01-01 00:00:0.0"
ntime=dimsizes(time)

tstart = 1993
tend   = 2022

yyyymm   = yyyymm_time(tstart, tend, "integer")
yyyyfrac = yyyymm_to_yyyyfrac(yyyymm,0)   ; create fractional years for 


NAO_mod_reshape!0="time"
NAO_mod_reshape&time=time
print(NAO_mod_reshape)

; ---- Load Observation files
varfo="var151"
year_obs=ispan(1993,2022,1)
anno_obs=sprinti("%0.4i", year_obs)
pathfile_obs="/work/csp/ab00920/ERA5/monthly/mslp/"
all_fileo=pathfile_obs+"mslp_era5_"+anno_obs+".nc"

fallo=addfiles(all_fileo,"r")
ListSetType(fallo,"join")
mslptmp_obs=fallo[:]->$varfo$
mslptmp_obs = lonFlip(mslptmp_obs)
latobs=fallo[:]->lat(0,:)
lonobs=fallo[:]->lon(0,:)
wgtobs = sqrt(cos(tofloat(latobs)*deg2rad))
mslptmp_obs=mslptmp_obs*conform(mslptmp_obs, wgtobs, 2)
NNO=dimsizes(mslptmp_obs)
nyo=NNO(0)
nto=NNO(1)
nlato=NNO(2)
nlono=NNO(3)

; --- flip longitude coordinate
lon0obs = lonobs
lonnobs = lonobs({lonobs(nlono/2):lonobs(nlono-1)})
lonnobs = (/lonnobs-360./)
nlonno = dimsizes(lonnobs)
print(nlonno)
lonpobs = lonobs({lonobs(0):lonobs(nlono/2-1)})
nlonpo = dimsizes(lonpobs)
lon0obs(0:nlonno-1) = lonnobs
lon0obs(nlonno:nlono-1) = lonpobs


mslpobs_clim=dim_avg_n_Wrap(mslptmp_obs,0)
mslpOBS=mslptmp_obs
do y=0,ny-1
   mslpOBS(y,:,:,:)=mslptmp_obs(y,:,:,:)-mslpobs_clim
end do

;---- Calculate Model standard yearly deviation
stdmslpOBS=dim_stddev_n_Wrap(mslpOBS,0)

;=====================================================
; compute the 3 NAOI for observations
;=====================================================
NAO_obs=mslpOBS(:,:,0,0)
do y=0,ny-1
   NAO_obs(y,:)  = dim_avg_n(dim_avg_n(mslpOBS(y,:,{inilatposi:endlatposi},{inilon:endlon})/stdmslpOBS(:,{inilatposi:endlatposi},{inilon:endlon}),1),1)-dim_avg_n(dim_avg_n(mslpOBS(y,:,{inilatnega:endlatnega},{inilon:endlon})/stdmslpOBS(:,{inilatnega:endlatnega},{inilon:endlon}),1),1)
end do

NAO_obs_reshape=reshape(NAO_obs,(/ny*nt/))

NAO_obs_runavg=runave_n_Wrap(NAO_obs_reshape,3,0,0)

time=new((/ny*nt/),"float",-999)
do t=0,(ny*nt)-1
   time(t)=t
end do
NAO_obs_reshape!0="time"
NAO_obs_reshape&time=time

; ------ plot seetings
colors = (/"red","black"/)

wks = gsn_open_wks("png","/work/csp/as34319/diagnostics/dp16116/cm3_cam122_cpl2000-bgc_t01c/plots/indices/NAO/cm3_cam122_cpl2000-bgc_t01c_vs_ERA5_NAOI")

res = True

res@gsnDraw               = False             ; don't draw yet
res@gsnFrame              = False
res@gsnMaximize           = True 
res@trYMinF                  = -3.5
res@trYMaxF                  = 3.5
res@tiMainFontHeightF        = 0.023
res@tiMainString             = ""
res@tmXTBorderOn             = True
res@tmYRBorderOn             = True
res@tmYUseLeft               = True
res@vpXF                     = 0.15
res@vpYF                     = 0.9

res@vpWidthF                 = 0.8
res@vpHeightF                = 0.4
res@tiYAxisString            =  ""
res@tiXAxisString            =   ""
res@gsnLeftString = ""
res@gsnRightString = ""
res@gsnCenterString = "NAO (Li and Wang, 2003)"
res@tmXBLabelDeltaF          = 1
res@tmXBLabelFontHeightF     = 0.015
res@tmXBLabelAngleF          = 90
res@tmXBLabelJust            = "CenterCenter"
res@trXMinF    = 1993
res@trXMaxF    = 2023
res@tmXBMode   = "Explicit"
res@tmXBValues = "f"     ; choose first 13 timesteps

res@xyLineColor     = "Black"
res@xyLineThicknessF= 2

plot = gsn_csm_xy (wks,yyyyfrac,NAO_mod_runavg,res)
res@xyLineColor     = "Red"
res@xyLineThicknessF= 2
plot2 = gsn_csm_xy (wks,yyyyfrac,NAO_obs_runavg,res)

overlay(plot,plot2)

getvalues plot2                      ; Get plot size for use in
  "vpHeightF" : vph                 ; determining size of
  "vpWidthF"  : vpw                 ; labelbar.
end getvalues

;***********************************************
; legend resources
;***********************************************
gres = True
gres@YPosPercent = 95.    ; expressed as %, 0->100, sets position of top border of legend
                            ;  when gres@Position is set to its default setting of "Top" (Default = 95.)
gres@XPosPercent = 5      ; expressed as %, 0->100, sets position of left border of legend(Default = 5.)

lineres = True
lineres@lgLineColors = (/"Red","Black"/) ; line colors
lineres@lgLineThicknesses = 2.5                        ; line thicknesses
lineres@LineLengthPercent = 7.

textres = True
textres@lgLabels = (/"ERA5","CMCC-CM3"/)  ; legend labels (required)

plot2 = simple_legend(wks,plot,gres,lineres,textres)

draw(plot2)
frame(wks)

end
