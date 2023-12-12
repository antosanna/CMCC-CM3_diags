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


varf="TREFHT"
print("plotting composites with "+varf)
all_filep=pathfile+"cm3_cam122_cpl2000-bgc_t01c.cam."+varf+"."+anno+".nc"
fallp=addfiles(all_filep,"r")
ListSetType(fallp,"join")
prec=fallp[:]->$varf$

;ny=NN(0)
;nt=NN(1)   ; 12 months
;nlat=NN(2)
;nlon=NN(3)
; remove one year to have a complete DJF series
prec_DJF=new((/ny-1,3,nlat,nlon/),typeof(NAO_winter))
prec_DJF(0:ny-2,1:2,:,:)=prec(1:ny-1,0:1,:,:)
prec_DJF(0:ny-2,0,:,:)=prec(0:ny-2,11,:,:)
prec_winter=dim_avg_n_Wrap(prec_DJF,1)
mean_prec_winter=dim_avg_n_Wrap(prec_winter,0)
prec_comp_posi=new((/nlat,nlon/),typeof(prec_winter))
prec_comp_nega=new((/nlat,nlon/),typeof(prec_winter))

prec_comp_posi=0.
prec_comp_nega=0.
icp=0
icn=0
do it=0,ny-2
   if(NAO_winter(it).gt.0.5 )then
      prec_comp_posi(:,:)=prec_comp_posi(:,:)+prec_winter(it,:,:)
      icp=icp+1 
   end if
   if(NAO_winter(it).lt.-0.5 )then
      prec_comp_nega(:,:)=prec_comp_nega(:,:)+prec_winter(it,:,:)
      icn=icn+1 
   end if
end do
if(varf.eq."TREFHT")then
   cf=1
  cmap = read_colormap_file("temp_diff_18lev")
end if
if(varf.eq."PRECT")then
   cf=86400*1000
  cmap = read_colormap_file("precip_diff_12lev")
end if
prec_comp_posi=(prec_comp_posi/tofloat(icp)-mean_prec_winter)*cf
prec_comp_nega=(prec_comp_nega/tofloat(icn)-mean_prec_winter)*cf
copy_VarMeta(prec(0,0,:,:),prec_comp_posi)
copy_VarMeta(prec(0,0,:,:),prec_comp_nega)

 wks = gsn_open_wks("png","/work/csp/as34319/diagnostics/dp16116/cm3_cam122_cpl2000-bgc_t01c/plots/indices/NAO/"+varf+"_composites_on_winter_NAO")              ; send graphics to PNG file


  plot = new(2,graphic)                          ; create a plot array
  
  res                     = True
  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnFillOn            = True            ; turn on color
  res@cnFillPalette       = cmap
  res@cnLineLabelsOn      = False
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@mpMinLatF            = 20
  res@mpMaxLatF            = 90
  res@mpMinLonF            = -80
  res@mpMaxLonF            = 50

; to have a common label bar, both plots should be set to the same interval
; b/c the label bar is drawn by default from the interval of the first plot.
  res@cnLevelSelectionMode="ExplicitLevels"
  res@cnLevels     = (/-2.5,-2,-1.5,-1,-.5,-0.2,0.2,.5,1,1.5,2,2.5/)
 


  res@gsnCenterString = "Positive Phase"
  if(varf.eq."PRECT")then
     res@gsnRightString   = "[mm/day]"
     res@gsnLeftString   = "PRECT"
  end if
  if(varf.eq."TREFHT")then
     res@gsnRightString   = "[Celsius deg]"
     res@gsnLeftString   = "T2m"
  end if
  plot(0) = gsn_csm_contour_map (wks,prec_comp_posi,res)
  res@gsnCenterString = "Negative Phase"
  plot(1) = gsn_csm_contour_map (wks,prec_comp_nega,res)


  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString = "Composites on NAO winter model index (Li and Wang)"

  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.01               ; make labels smaller

  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

end
