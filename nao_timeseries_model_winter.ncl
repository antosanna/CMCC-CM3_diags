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
pathfile="/work/cmcc/as34319/diagnostics/dp16116/cm3_cam122_cpl2000-bgc_t01c/"
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
nt=NN(1)   ; 12 months
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
mslp_DJF=new((/ny-1,3,nlat,nlon/),typeof(mslpMOD))
mslp_DJF(0:ny-2,1:2,:,:)=mslpMOD(1:ny-1,0:1,:,:)
mslp_DJF(0:ny-2,0,:,:)=mslpMOD(0:ny-2,11,:,:)
mslp_winter=dim_avg_n_Wrap(mslp_DJF,1)
stdmslp_winter=dim_stddev_n_Wrap(mslp_winter,0)

NAO_winter=mslp_winter(:,0,0)
do y=0,ny-2
   NAO_winter(y)  = dim_avg_n(dim_avg_n(mslp_winter(y,{inilatposi:endlatposi},{inilon:endlon})/stdmslp_winter({inilatposi:endlatposi},{inilon:endlon}),0),0)-dim_avg_n(dim_avg_n(mslp_winter(y,{inilatnega:endlatnega},{inilon:endlon})/stdmslp_winter({inilatnega:endlatnega},{inilon:endlon}),0),0)
end do


time=new((/ny-1/),"float",-999)
do t=0,(ny)-2
   time(t)=t
end do



; ------ plot seetings
colors = (/"red","black"/)

wks = gsn_open_wks("x11","plots/CMCC-CM3_NAOI_winter")

res = True

res@gsnDraw               = True             ; don't draw yet
res@gsnFrame              = True
res@gsnMaximize           = True 
res@trYMinF                  = -4.5
res@trYMaxF                  = 4.5
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
;res@tmXBMode   = "Explicit"
;res@tmXBValues = "f"     ; choose first 13 timesteps

res@xyLineColor     = "Black"
res@xyLineThicknessF= 2

plot = gsn_csm_y (wks,NAO_winter,res)

;overlay(plot,plot2)
exit

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

draw(plot)
frame(wks)

end
