;*************************************************
; xy_11.ncl
;
; Concepts illustrated:
;   - Drawing an XY plot with just Y values
;   - Changing the precision of the tickmark labels
;   - Adding labels to the right Y axis
;
;************************************************
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin
;************************************************
; read in netCDF file model
;************************************************
  expid=getenv("expid1")
  var=getenv("varmod")
  sea=getenv("sea")
  infile=getenv("obsfile")
  clim3d=getenv("clim3d")
  pltype=getenv("pltype")
  pltname=getenv("pltname")
  a = addfile(infile,"r")
  if(clim3d.eq."MERRA2")then
     plev=a->lev
     lat=a->lat
  else
     plev=a->plev(::-1)/100
     lat=a->lat(::-1)
  end if
  lon=a->lon
  rad  = 4.0 * atan(1.0) / 180.0
  if(var.eq."Z3")then
; reverse vertical levels and latitudes
     tmp=a->Z(:,::-1,::-1,:)/9.81
  else
; reverse vertical levels and latitudes
     tmp=a->$var$(:,::-1,::-1,:)
     if(clim3d.eq."MERRA2")then
        tmp=a->$var$
     end if
  end if
  if(sea.eq."ANN") then
     u=dim_avg_n(dim_avg_n(tmp,3),0)
  else if(sea.eq."JJA") then
     u=dim_avg_n(dim_avg_n(tmp(5:7,:,:,:),3),0)
  else if(sea.eq."DJF") then
     tmp1=dim_avg_n(dim_avg_n(tmp(0:1,:,:,:),3),0)
     tmp2=dim_avg_n(tmp(11,:,:,:),2)
     u=(tmp1+tmp2)/2.
     delete(tmp1)
     delete(tmp2)
  end if
  end if
  end if
  delete(tmp)
  u!0="lev"
  u&lev=plev
  u!1="lat"
  u&lat=lat
  u&lev@units="hPa"
;***********************************************
; now model
;***********************************************
  Tfile=getenv("Tfile")
  print("-----going to get PS from "+Tfile)
  f = addfile(Tfile,"r")
  PSfile=getenv("PSfile")
  print("-----going to get PS from "+PSfile)
  d = addfile(PSfile,"r")
  infile=getenv("modfile")
  b = addfile(infile,"r")
  ilev=36
  latmod=b->lat
  lonmod=b->lon
  tmp=b->$var$;(:,ilev:,:,:)
  if(sea.eq."ANN") then
     umod2d=dim_avg_n(tmp,0)
     tbot=dim_avg_n(f->T(:,0,:,:),0)
     PSmod=dim_avg_n(d->PS,0)
  else if(sea.eq."JJA") then
     umod2d=dim_avg_n(tmp(5:7,:,:,:),0)
     tbot=dim_avg_n(f->T(5:7,0,:,:),0)
     PSmod=dim_avg_n(d->PS(5:7,:,:),0)
  else if(sea.eq."DJF") then
     tmp1=dim_avg_n(tmp(0:1,:,:,:),0)
     tmp2=tmp(11,:,:,:)
     umod2d=(tmp1+tmp2)/2.
     tbot=(dim_avg_n(f->T(0:1,0,:,:),0)+f->T(11,0,:,:))/2.
     PSmod=(dim_avg_n(d->PS(0:1,:,:),0)+d->PS(11,:,:))/2.
  end if
  end if
  end if
; now get same levels as obs
  intyp=1
  kxtrp = True
  varflg=0
  if(var.eq."Z3")then
     intyp=2
     varflg=-1
  end if
  if(var.eq."T")then
     varflg=1
  end if
  c = addfile(getenv("auxfile"),"r")
  print("-----going to get auxiliary vars from "+getenv("auxfile"))
  PHIS=c->PHIS(0,:,:)
  hyam=c->hyam
  hybm=c->hybm
  ;lev=(/1000,925,850,700,500,300,250,200,100,10/)
  nplev=dimsizes(plev)
  lev=plev(0:nplev-2)
  P0mb=1000.
  umod2obs=vinth2p_ecmwf(umod2d, hyam,hybm,lev,PSmod, intyp, P0mb,1,kxtrp,varflg,tbot,PHIS)
  printVarSummary(umod2obs)
  umod2obs_orig_latlon = dim_avg_n(umod2obs,2)
  umod2obsregrid = linint2_Wrap (lonmod,latmod,umod2obs, True, lon,lat, 0)
  umod=dim_avg_n(umod2obsregrid,2)
  uobs=new((/dimsizes(lev),dimsizes(lat)/),typeof(u))
  uobs@_Fillvalue=-999.
  nn=dimsizes(u)
  print(nn)
  print(dimsizes(lat))
  uobs=u(0:dimsizes(lev)-1,:)
  udiff=umod-uobs
  copy_VarMeta(umod2obsregrid(:,:,0),umod)
  copy_VarMeta(umod2obsregrid(:,:,0),udiff)
  copy_VarMeta(umod2d(:,:,0),umod2obs_orig_latlon)
  udiff@_Fillvalue=uobs@_Fillvalue
  printVarSummary(umod)
  if(clim3d.eq."MERRA2")then
     umod&lev@units="hPa"
     udiff&lev@units="hPa"
  else
     umod&lev_p@units="hPa"
     udiff&lev_p@units="hPa"
  end if
;************************************************
; create plot
;************************************************
  wks = gsn_open_wks(pltype,pltname)

  plot = new(2,graphic)  
  res                      = True                 ; plot mods desired

  res@gsnDraw             = False           ; don't draw
  res@gsnFrame            = False           ; don't advance frame
  res@cnLevelSelectionMode = "ManualLevels"       ; manually select levels
  if(var.eq."Z3")then
     res@cnLevelSpacingF      = 1500.0                  ; contour spacing
     res@cnMinLevelValF       = 0.                 ; min level
     res@cnMaxLevelValF       =  30000.
  end if
  if(var.eq."T")then
     res@cnLevelSpacingF      = 10.0                  ; contour spacing
     res@cnMinLevelValF       = 200.                 ; min level
     res@cnMaxLevelValF       =  300.
  end if
  if(var.eq."U")then
     res@cnLevelSpacingF      = 5.0                  ; contour spacing
     res@cnMinLevelValF       = -40.                 ; min level
     res@cnMaxLevelValF       =  40.
  end if
  res@cnLineLabelsOn       = True                 ; turn on line labels
  res@cnFillOn             = True                 ; turn on color fill
  res@cnFillPalette        = "BlWhRe"
  res@lbLabelBarOn        = True 

;  res@tmYRMode             = "Automatic"          ; turn off special labels on right axis

; note u is already on pressure levels. If this were model data, it
; would be necessary to interpolate from the hybrid coordinates to 
; pressure levels.
  
  printVarSummary(u)
  res@tiMainString         = expid
  res@trYMinF=30
;  plot(0)  = gsn_csm_pres_hgt(wks, umod, res )   ; plaace holder
  umod2obs_orig_latlon!0="lev"
  umod2obs_orig_latlon&lev=lev
  umod2obs_orig_latlon&lev@units="hPa"
  plot(0)  = gsn_csm_pres_hgt(wks, umod2obs_orig_latlon, res )   ; plaace holder
  res@tiMainString         = expid +" - "+clim3d+" reanalysis"
  if(var.eq."T")then
     res@cnLevelSpacingF      = 1.                  ; contour spacing
     res@cnMinLevelValF       = -10.                 ; min level
     res@cnMaxLevelValF       =  10.
  end if
  if(var.eq."U")then
     res@cnLevelSpacingF      = 1.5                  ; contour spacing
     res@cnMinLevelValF       = -15.                 ; min level
     res@cnMaxLevelValF       =  15.
  end if
  if(var.eq."Z3")then
     res@cnLevelSpacingF      = 30.                  ; contour spacing
     res@cnMinLevelValF       = -300.                 ; min level
     res@cnMaxLevelValF       =  300.
  end if
  plot(1) = gsn_csm_pres_hgt(wks, udiff, res )   ; plaace holder
;************************************************
; create panel
;************************************************
  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString = "Zonal average "+var+" "+sea

  resP@gsnPanelLabelBar    = False                ; add common colorbar
  resP@lbLabelFontHeightF  = 0.007               ; make labels smaller

  gsn_panel(wks,plot,(/1,2/),resP)               ; now draw as one plot
  
end

