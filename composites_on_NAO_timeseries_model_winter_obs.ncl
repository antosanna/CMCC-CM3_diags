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

lg_GPCC=0
;------ Load model files
varf="mslp"
year=ispan(1,30,1)
anno=sprinti("%0.4i", year)
pathfile="/work/csp/sp2/VALIDATION/"
filem=pathfile+"ERA5/"+varf+"_ERA5.DJF.1993-2016.nc"

f=addfile(filem,"r")
lat=f->lat
lon=f->lon
wgt = sqrt(cos(tofloat(lat)*deg2rad))
mslp=f->var151
mslptmp=mslp*conform(mslp, wgt, 1)
copy_VarMeta(mslp,mslptmp)
; --- flip longitude coordinate
mslptmp=lonFlip(mslptmp)
NN=dimsizes(mslptmp)
ny=NN(0)
nlat=NN(1)
nlon=NN(2)
lon0 = lon 
lonn = lon({lon(nlon/2):lon(nlon-1)})
lonn = (/lonn-360./)
nlonn = dimsizes(lonn)
lonp = lon({lon(0):lon(nlon/2-1)})
nlonp = dimsizes(lonp)
lon0(0:nlonn-1) = lonn
lon0(nlonn:nlon-1) = lonp

mslp_clim=dim_avg_n_Wrap(mslptmp,0)
delete(mslp)
mslp=mslptmp
do y=0,ny-1
   mslp(y,:,:)=mslptmp(y,:,:)-mslp_clim
end do
copy_VarMeta(mslptmp,mslp)

;---- Calculate Model standard yearly deviation 
stdmslp=dim_stddev_n_Wrap(mslp,0)

;=====================================================
; compute the NAOI 
;=====================================================

NAO_winter=mslp(:,0,0)
printVarSummary(NAO_winter)
printVarSummary(mslp)
printVarSummary(stdmslp)
do y=0,ny-1
   NAO_winter(y)  = dim_avg_n(dim_avg_n(mslp(y,{inilatposi:endlatposi},{inilon:endlon})/stdmslp({inilatposi:endlatposi},{inilon:endlon}),0),0)-dim_avg_n(dim_avg_n(mslp(y,{inilatnega:endlatnega},{inilon:endlon})/stdmslp({inilatnega:endlatnega},{inilon:endlon}),0),0)
end do


time=new((/ny/),"float",-999)
do t=0,ny-1
   time(t)=t
end do


varf="precip"
cf=1.
if(varf.eq."t2m")then
   var2read="var167"
   filep=pathfile+"ERA5/"+varf+"_ERA5.DJF.1993-2016.nc"
   cmap = read_colormap_file("hotcold_18lev")
else if(varf.eq."precip")then
   var2read=varf
   if(lg_GPCC.eq.1)then
      cf=1./30.
      filep=pathfile+"GPCC/prec_GPCC.DJF.1993-2016.nc"
   else
      filep=pathfile+"monthly/precip/precip_GPCP.DJF.1993-2016.nc"
   end if
   cmap = read_colormap_file("precip_diff_12lev")
end if
end if
print("plotting composites with "+varf)
fp=addfile(filep,"r")
prec=fp->$var2read$
lon=fp->lon

;if(lg_GPCC.ne.1)then
;   prec=lonFlip(prec)
;end if

; remove one year to have a complete DJF series
mean_prec_winter=dim_avg_n_Wrap(prec,0)
prec_comp_posi=new((/nlat,nlon/),typeof(prec))
prec_comp_nega=new((/nlat,nlon/),typeof(prec))

prec_comp_posi=0.
prec_comp_nega=0.
icp=0
icn=0
do it=0,ny-2
   if(NAO_winter(it).gt.0.5 )then
      prec_comp_posi(:,:)=prec_comp_posi(:,:)+prec(it,:,:)
      icp=icp+1 
   end if
   if(NAO_winter(it).lt.-0.5 )then
      prec_comp_nega(:,:)=prec_comp_nega(:,:)+prec(it,:,:)
      icn=icn+1 
   end if
end do
;print(prec(:,0,{inilon:inilon}))
printVarSummary(prec)
prec_comp_posi=(prec_comp_posi/tofloat(icp)-mean_prec_winter)*cf
prec_comp_nega=(prec_comp_nega/tofloat(icn)-mean_prec_winter)*cf
copy_VarMeta(prec(0,:,:),prec_comp_posi)
copy_VarMeta(prec(0,:,:),prec_comp_nega)

 wks = gsn_open_wks("x11","/work/csp/sps-dev/diagnostics/obs/plots/indices/NAO/"+varf+"_composites_on_winter_NAO")              ; send graphics to PNG file


  plot = new(2,graphic)                          ; create a plot array
  
  res                     = True
  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnInfoLabelOn       = False           ; turn off cn info label
  res@cnFillOn            = True            ; turn on color
  res@cnFillPalette       = cmap
  res@cnLineLabelsOn      = False
  res@lbLabelBarOn        = False           ; turn off individual cb's
  res@gsnAddCyclic= True
;  res@mpMinLatF            = 20
;  res@mpMaxLatF            = 90
;  res@mpMinLonF            = -80
;  res@mpMaxLonF            = 50

; to have a common label bar, both plots should be set to the same interval
; b/c the label bar is drawn by default from the interval of the first plot.
  res@cnLevelSelectionMode="ExplicitLevels"
  if(varf.eq."t2m") then
     res@cnLevels     = (/2.5,-2,-1.5,-1,-.5,-0.2,0.2,.5,1,1.5,2,2.5/)
  else
     res@cnLevels     = (/-2,-1.5,-1,-.5,-0.2,-0.1,0.1,0.2,.5,1,1.5,2/)
  end if
 


  res@gsnCenterString = "Positive Phase"
  if(varf.eq."precip")then
     res@gsnRightString   = "[mm/day]"
     res@gsnLeftString   = "PRECT"
  end if
  if(varf.eq."t2m")then
     res@gsnRightString   = "[Celsius deg]"
     res@gsnLeftString   = "T2m"
  end if
  plot(0) = gsn_csm_contour_map (wks,prec_comp_posi,res)
  res@gsnCenterString = "Negative Phase"
  plot(1) = gsn_csm_contour_map (wks,prec_comp_nega,res)


  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString = "Composites on NAO winter ERA5 1993-2016 (Li and Wang)"

  resP@gsnPanelLabelBar    = True                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.01               ; make labels smaller

  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

end
