load "./panel_two_sets.ncl"
begin

; input variables
expid    = getenv("expid")
clim    = getenv("clim")
iniyrun=getenv("yini")
iniy=getenv("yiniplot")
endy=getenv("yendplot")
var    = getenv("varmod")
varobs    = getenv("varobs")
cmp2obs    = getenv("cmp2obs")
pltype=getenv("pltype")
pltname=getenv("pltname")
inpfile=getenv("inpfileznl")
obsfile=getenv("obsfile")
sea=getenv("sea")
;;;;;;;;input files
hfile_nc   = addfile(inpfile,"r") 
time    = hfile_nc->time    ; variable to translate
sno    = hfile_nc->$var$    ; variable to translate
lonmod=hfile_nc->lon
latmod=hfile_nc->lat
copy_VarMeta(sno(0,0,:,:),snowplot)
if(var.eq."H2OSNO")then
   snowplot=where(snowplot.lt.5.,sno@_FillValue,snowplot)
end if
delete(sno)

npl=1
if(cmp2obs.eq.1)then
   hfile_nc   = addfile(obsfile,"r")
;;;;;;;;input files

sno    = hfile_nc->$varobs$(:,::-1,:)    ; variable to translate
lon    = hfile_nc->lon
lat    = hfile_nc->lat(::-1)

sno@_FillValue=1.e36         ; define _FillValue (missing in .r. files!)
sno=where(sno.ge.1.e35,sno@_FillValue,sno)
if(sea.eq."ANN")then
   snowobs=dim_avg_n(sno,0)*1000
else if(sea.eq."JJA")then
   snowobs=dim_avg_n(sno(5:7,:,:),0)*1000
else if(sea.eq."DJF")then
   snowobs=(dim_avg_n(sno(0:1,:,:),0)+sno(11,:,:))/2.
   snowobs=snowobs*1000
end if
end if
end if
copy_VarMeta(sno(1,:,:),snowobs)
if(var.eq."H2OSNO")then
;   snowobs=where(lsm.ne.1.,sno@_FillValue,snowobs)
   snowobs=where(snowobs.lt.5,sno@_FillValue,snowobs)
end if
delete(sno)
   npl=npl+1
end if

;---Create first two individual plots
  wks = gsn_open_wks(pltype,pltname)
  plot = new(npl,graphic)
  res                   = True             ; plot mods desired
  res@mpOceanFillColor      = "grey"       ; make land white
  res@cnFillOn          = True             ; turn on color
  res@cnLinesOn         = False            ; turn off contour lines
  res@cnLineLabelsOn    = False            ; turn off contour lines
  cmap = read_colormap_file("precip4_11lev")
  res@cnFillPalette     = cmap(::-1,:)
  res@lbLabelBarOn      = False            ; turn off individual label bars
  res@gsnDraw           = False            ; don't draw yet
  res@gsnFrame          = False            ; don't advance frame yet
  res@gsnAddCyclic      = True            ; data already has cyclic point

  if(var.eq."H2OSNO")then
     res@cnLevelSelectionMode="ExplicitLevels"
     res@cnLevels     = (/50,100,150,200,250,300,350,400,1000,2500,5000/)
  end if
 ; res@mpLandFillColor      = "white"       ; make land white
  res@mpOceanFillColor      = "grey"       ; make land white

  res@gsnCenterString = sea+ " "+expid+" "+iniy+"-"+endy
  res@gsnLeftString=""
  res@gsnRightString=""
  plot(0)  = gsn_csm_hov(wks, snowplot, res ) 
  if(npl.eq.2)then
     res@gsnCenterString = sea+" ERA5 reanalysis "+clim
     plot(1) = gsn_csm_hov(wks,snowobs,res)
  end if

;---Create third individual plots
;  res@cnFillPalette     = "amwg_blueyellowred"    ; set color map
  delete(res@cnFillPalette)
  cmapdiff = read_colormap_file("hotcold_18lev")
  res@cnFillPalette     = cmapdiff(::-1,:)
  res@cnLevelSelectionMode="ExplicitLevels"
  delete(res@cnLevels)
  res@cnLevels     = (/-500.,-300.,-200.,-100.,-25,25,100.,200,300,500/)
;  res@cnMinLevelValF       = -5             ; min level
;  res@cnMaxLevelValF       = 5            ; max level
;  res@cnLevelSpacingF      = 0.5             ; contour interval
;  res@gsnSpreadColors = True
  res@gsnCenterString = "Model-ERA5"
  tclim_in_obs = linint2_Wrap (lonmod,latmod,snowplot, True, lon,lat, 0)
  diff=tclim_in_obs-snowobs
  copy_VarMeta(snowobs,diff)
  plot2 = gsn_csm_contour_map(wks,diff,res)

;---Panel the two sets of plots
  pres1 = True        ; Resources specific to first set of paneled plots
  pres2 = True        ; Resources specific to second set of paneled plots
  pres  = True        ; For setting the area of paneled plots

  pres1@pmLabelBarOrthogonalPosF = -0.02    ; Move closer to plots
  pres2@pmLabelBarOrthogonalPosF = -0.02

; pres@gsnPanelTop    = 1.0  ; set these if desired
; pres@gsnPanelBottom = 0.0  ; must be between 0 and 1
; pres@gsnPanelLeft   = 0.0
; pres@gsnPanelRight  = 1.0
 pres@gsnCenterString  = sea

  panel_two_sets(wks,plot,plot2,(/2,1/),(/1,1/),pres1,pres2,pres)
end


