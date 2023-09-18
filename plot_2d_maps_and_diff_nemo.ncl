;----------------------------------------------------------------------
; panel_15.ncl
;
; Concepts illustrated:
;   - Combining two sets of paneled plots on one page
;----------------------------------------------------------------------
; This script is similar to panel_15_old.ncl, except a function called
; "panel_two_sets" was used to make it easier to panel two sets of
; plots.
;
; This function enables you to panel two sets of contour plots on the
; same page, each with its own labelbar. The function will determine
; whether to use horizontal or vertical labelars, depending on how
; the two sets of plots are laid out in terms of rows and columns.
;----------------------------------------------------------------------
; You must download panel_two_sets.ncl for this script to run.
;----------------------------------------------------------------------
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

undef("createLabelBar")
function createLabelBar(wks: graphic, plt:graphic, lbres:logical)
begin
   getvalues plt@contour               ; object from which info extracted
      "cnFillColors"   : fill_colors   ; get the colors used
      "lbLabelStrings" : lbstrings     ; get the labels used
   end getvalues
   lbres@lbFillColors = fill_colors    ; associate with input lnres argument
   lbid = gsn_create_labelbar(wks,dimsizes(lbstrings)+1,lbstrings,lbres)
   return(lbid)
end

begin
  expid=getenv("expid1")
  name_from_ext=getenv("name_from_here")
  units_from_ext=getenv("units_from_here")
  modfile=getenv("inpfile")
  cmp2obs=toint(getenv("cmp2obs_ncl"))
  if(cmp2obs.eq.1)then
     obsfile=getenv("obsfile")
     print("----observations file "+obsfile)
  end if
  sea=getenv("sea")
  pltname=getenv("pltname")
  pltype=getenv("pltype")
  varmod=getenv("varmod")
  varobs=getenv("varobs")
  cf=tofloat(getenv("cf"))
  mf=tofloat(getenv("mf"))
  mftom1=getenv("mftom1")
  in = addfile(modfile,"r")
  print("----model file "+modfile)
  t=in->$varmod$
  nav_lat=in->nav_lat
  nav_lon  = in->nav_lon
  rad=4.0*atan(1.0)/180.0
  print("")
  print("----season is "+sea)
  if(sea.eq."ANN") then
     tclim=dim_avg_n(t,0)
  end if
  if (sea.eq."JJA") then
     tclim=dim_avg_n(t(5:7,:,:),0)
  end if
  if (sea.eq."DJF") then
     tclim=(t(0,:,:)+t(1,:,:)+t(11,:,:))/3.
  end if
  tclim=(tclim+cf)*mf*1./tofloat(mftom1)
  printMinMax(tclim,0)
  copy_VarMeta(t(0,:,:),tclim)
  printVarSummary(tclim)
  if(cmp2obs.eq.1)then
     in = addfile(obsfile,"r")
     lon  = in->lon
     lat  = in->lat
     tobs  = in->$varobs$
     if(sea.eq."ANN") then
        tobsclim=dim_avg_n(tobs,0)
     else if (sea.eq."JJA") then
        tobsclim=dim_avg_n(tobs(5:7,:,:),0)
     else if (sea.eq."DJF") then
        tobsclim=(tobs(0,:,:)+tobs(1,:,:)+tobs(11,:,:))/3.
     end if
     end if
     end if
     wgty_obs=cos(lat*rad)
     printVarSummary(wgty_obs)
     printVarSummary(tobsclim)
     
  end if
; interpolate to reg grid
  dir_lsm=getenv("dir_lsm")
  lsmFileName = dir_lsm+"lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc"
  lsmfile = addfile(lsmFileName,"r")
  lsm=lsmfile->LANDFRAC
  latmod=lsmfile->lat
  wgty_mod= cos(latmod*rad)
  printVarSummary( wgty_mod)
  nlat=dimsizes(latmod)
  lonmod=lsmfile->lon
  nlon=dimsizes(lonmod)

;---Output (and input) files
  srcGridName = getenv("srcGridName") ;"ORCA_SCRIP_gridT.nc"
  dstGridName = getenv("dstGridName"); "World1deg_SCRIP_gridT.nc"
  wgtFile     = getenv("wgtFile") ;"ORCA_2_World_SCRIP_gridT.nc"

;  SKIP_ORCA_SCRIP_GEN  = False
;  SKIP_WORLD_SCRIP_GEN = False
;  SKIP_WGT_GEN         = False
   ;----------------------------------------------------------------------
   ; Convert ORCA to SCRIP file.
   ;----------------------------------------------------------------------
;  if(.not.SKIP_ORCA_SCRIP_GEN) then
  if(.not.isfilepresent(srcGridName)) then
       ;---Convert to an SCRIP Convention file.
     Opt                = True
     Opt@ForceOverwrite = True
     Opt@PrintTimings   = True
     Opt@Mask2D         = where(.not.ismissing(tclim),1,0)

     curvilinear_to_SCRIP(srcGridName,nav_lat,nav_lon,Opt)

   ;---Clean up
     delete(Opt)
  end if
   ;----------------------------------------------------------------------
   ; Convert 1 degree world grid to SCRIP file
   ;----------------------------------------------------------------------
;  if(.not.SKIP_WORLD_SCRIP_GEN)then
  if(.not.isfilepresent(dstGridName)) then
      Opt                = True
      Opt@LLCorner       = (/-89.5,-179.5 /)
      Opt@URCorner       = (/ 89.5, 179.5 /)
      Opt@ForceOverwrite = True
      Opt@PrintTimings   = True
      Opt@Title          = "World grid 1x1 degree resolution"

      latlon_to_SCRIP(dstGridName,"1deg",Opt)

   ;---Clean up
      delete(Opt)
  end if

   ;----------------------------------------------------------------------
   ; Generate interpolation weights for ORCA Grid to World Grid
   ;----------------------------------------------------------------------
;  if(.not.SKIP_WGT_GEN) then
  if(.not.isfilepresent(wgtFile)) then
     Opt                      = True
     Opt@SrcESMF              = False
     Opt@DstESMF              = False
     Opt@ForceOverwrite       = True
     Opt@PrintTimings         = True

     ESMF_regrid_gen_weights(srcGridName, dstGridName, wgtFile, Opt)

   ;---Clean up
     delete(Opt)
  end if

   ;----------------------------------------------------------------------
   ; Interpolate data from ORCA to World 1-degree grid.
   ;----------------------------------------------------------------------

  Opt              = True
   ;       Opt@Debug        = True
  Opt@PrintTimings = True

  tmp = ESMF_regrid_with_weights(tclim,wgtFile,Opt)
  delete(tclim)
  tclim=tmp
  tclim@_FillValue=-999.
  printVarSummary(tclim)
  printVarSummary(lsm)
  tclim=where(lonFlip(lsm(0,:,:)).eq.1.,tclim@_FillValue,tclim)

;---Common definitions
;  FillPalette     = "gui_default"    ; set color map
  FillPalette     = read_colormap_file("amwg") 
  CenterString = getenv("title1")
  LeftString   = t@long_name
  RightString   = t@units

 if(name_from_ext.eq.1)then
    delete(LeftString)
    LeftString=getenv("title")
 end if
 if(units_from_ext.eq.1)then
    units=getenv("units")
    delete(RightString)
    RightString=getenv("right")
    print(RightString)
 end if

  wks = gsn_open_wks(pltype,pltname)
  if(cmp2obs.eq.1)then 
     plot = new(3,graphic)
     res                   = True             ; plot mods desired

     res@gsnDraw               = False
     res@gsnFrame              = False
     res@gsnAddCyclic          = True    ; data is regional

     res@cnFillOn              = True     ; turn on color fill
     res@cnLinesOn             = False    ; turn of contour lines
     res@cnLineLabelsOn        = False    ; turn of contour line labels
     res@cnFillPalette  = FillPalette

     res@lbLabelBarOn          = False

    ; res@tmYLLabelsOn          = False    ; turn off lat labels
    ; res@tmXBLabelsOn          = False    ; turn off lon labels

; Set up labelbar resources for the 2 vertical labelbars
; Some of these may change depending upon the nrow and ncols 
;****************************************************************************
     lbres                     = True                ; common resources for both
                                                  ; horizontal and vertical bars
     lbres@lbPerimOn           = False               ; no label bar box
     lbres@lbLabelFontHeightF  = 0.012               ; label font height
     lbres@lbLabelAlignment    = "InteriorEdges"     ; where to label
     lbres@lbMonoFillPattern   = True                ; solid fill

; Bottom Vertical Label bar (Projection)
     lbhres                    = lbres
     lbhres@lbOrientation      = "Vertical"        ; orientation
     lbhres@vpXF               = 0.78
     lbhres@vpYF               = 0.30
     lbhres@vpWidthF           = 0.05                ; size
     lbhres@vpHeightF          = 0.22

; Right Vertical Label bar (Hist)
     lbvres                    = lbres
     lbvres@lbOrientation      = "Vertical"          ; orientation
     lbvres@vpXF               = 0.78   
     lbvres@vpYF               = 0.9
     lbvres@vpWidthF           = 0.05                ; size
     lbvres@vpHeightF          = 0.5

;****************************************************************************
; Generate panel entries
;****************************************************************************
     plot = new(3 , "graphic")
   

    ;********************************
    ; Future Projection changes
    ;********************************
     res@cnMinLevelValF       =  0.0            ; set min contour level
     res@cnMaxLevelValF       = 12.0            ; set max contour level
     res@cnLevelSpacingF      =  1.0            ; set contour spacing


     res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
     res@cnMinLevelValF       = tofloat(getenv("minplot"))             ; min level
     res@cnMaxLevelValF       = tofloat(getenv("maxplot"))            ; max level
     res@cnLevelSpacingF      = tofloat(getenv("delta"))             ; contour interval
     res@mpLandFillColor      = "white"       ; make land white
     if(varmod.eq."PRECC".or.varmod.eq."PRECT".or.varmod.eq."PRECL")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/.2,.5,1,2.,3.0,4.0,5.,6.,7.,8.,9.,10.,12.,14.,17./)
     end if

     res@gsnCenterString = CenterString
     res@gsnLeftString   = LeftString
     res@gsnRightString   = RightString

     plot(0) = gsn_csm_contour_map(wks,tclim, res)

    ;********************************
    ; Horizontal labelbar: Extract info needed for horizontal labelbar
    ;********************************
                                                  ; 2nd column
     if (varmod.eq."FSNT") then
          res@gsnLeftString   = "Net sw Top of the Atmosphere"
     end if
     res@gsnCenterString = getenv("title2")
     tobsclim!0="lat"
     tobsclim!1="lon"
     tobsclim&lat=lat
     tobsclim&lon=lon
     tobsclim&lat@units="degree_N"
     tobsclim&lon@units="degree_E"
     plot(1) = gsn_csm_contour_map(wks,tobsclim, res)
     lbhid = createLabelBar(wks, plot, lbvres)

    ;********************************
    ; Hist (Rightmost column)
    ;********************************
     res@gsnCenterString = "Model - Observations"
     res@cnMinLevelValF       =  0.0            ; set min contour level
     res@cnMaxLevelValF       = 26.0            ; set max contour level
     res@cnLevelSpacingF      =  1.0            ; set contour spacing

     delete(res@cnFillPalette)
     cmap1 = read_colormap_file("hotcold_18lev")
     res@cnFillPalette     = cmap1
     if(varmod.eq."tos")then
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/-5.,-3.,-2.,-1.,-.25,.25,1.,2,3,5/)
     else
        res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
        res@cnMinLevelValF       = tofloat(getenv("minplotdiff"))             ; min level
        res@cnMaxLevelValF       = tofloat(getenv("maxplotdiff"))            ; max level
        res@cnLevelSpacingF      = tofloat(getenv("deltadiff"))             ; contour interval
     end if
     if(varmod.eq."PRECT")then
        delete(res@cnLevels)
        res@cnMinLevelValF=-5.
        res@cnMaxLevelValF=5.
        res@cnLevelSpacingF      = 1.
     end if
     res@gsnCenterString = "Model - Observations"
;     print(lonmod)
;     print(latmod)
;     print(lon)
;     print(lat)
      if (varmod.eq."FSNT") then
          res@gsnLeftString   = LeftString
     end if
     tclim_flip=lonFlip(tclim)
     lonmod_flip=where(lonmod.gt.0.,lonmod,lonmod+360.)
     lonmod=lonmod_flip
     copy_VarMeta(tclim,tclim_flip)
     tclim_in_obs = linint2_Wrap (lonmod,latmod,tclim_flip, True, lon,lat, 0)
     printMinMax(tclim_in_obs,0)
     diff=tclim_in_obs-tobsclim
     diff!0="lat"
     diff!1="lon"
     diff&lat=lat
     diff&lon=lon
     diff&lat@units="degree_N"
     diff&lon@units="degree_E"
     if(varmod.eq."PRECT")then
         delete(res@cnFillPalette)
         delete(FillPalette)
         cmap2 = read_colormap_file("hotcold_18lev")
         FillPalette     = cmap2(::-1,:)
         res@cnFillPalette=FillPalette
     end if
     plot(2) = gsn_csm_contour_map(wks,diff, res)
     
    ;********************************
    ; Vertical labelbar: Extract info needed for Hist (right) labelbar
    ;********************************
     lbvid = createLabelBar(wks, plot, lbhres)


;****************************************************************************
; Draw the panel and label bars
;****************************************************************************
     resP = True
     resP@gsnPanelMainString = expid+" "+sea
     resP@gsnMaximize = True
     resP@gsnFrame    = False
 ;resP@gsnPanelRight  = 0.98
     resP@gsnPanelBottom = 0.045 

     gsn_panel(wks,plot,(/3,1/),resP)  ; plots

     draw(lbvid)                             ; vertical label bar
     draw(lbhid)                             ; horizontal label bar
     txres               = True
     txres@txFontHeightF = 0.01
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tclim)),0.82,0.945,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tclim)),0.82,0.93,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tclim, wgty_mod, 1.0, 1)),0.82,0.915,txres)
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tobsclim)),0.82,0.3955,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tobsclim)),0.82,0.3805,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tobsclim, wgty_obs, 1.0, 1)),0.82,0.3655,txres)
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(diff)),0.82,0.06,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(diff)),0.82,0.045,txres)
     gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(diff, wgty_obs, 1.0, 1)),0.82,0.03,txres)
     frame(wks)
  else
     plot = new(1,graphic)
     res                   = True             ; plot mods desired
     res@cnFillOn          = True             ; turn on color
     res@cnLinesOn         = False            ; turn off contour lines
     res@cnLineLabelsOn    = False            ; turn off contour lines
     res@cnFillPalette     = FillPalette    ; set color map
     res@lbLabelBarOn      = True            ; turn off individual label bars
     res@gsnDraw           = True            ; don't draw yet
     res@gsnFrame          = True            ; don't advance frame yet
     res@gsnAddCyclic      = True            ; data already has cyclic point

     res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
     res@cnMinLevelValF       = tofloat(getenv("minplot"))             ; min level
     res@cnMaxLevelValF       = tofloat(getenv("maxplot"))            ; max level
     res@cnLevelSpacingF      = tofloat(getenv("delta"))             ; contour interval
     res@mpLandFillColor      = "white"       ; make land white
     if(varmod.eq."CLDTOT".or.varmod.eq."CLDLOW".or.varmod.eq."CLDMED".or.varmod.eq."CLDHGH")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/.1,.15,.20,.25,.30,.40,.5,.6,.7,.75,.8,.85,.9,.95/)
     end if
     if(varmod.eq."PRECC".or.varmod.eq."PRECT".or.varmod.eq."PRECL")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/.2,.5,1,2.,3.0,4.0,5.,6.,7.,8.,9.,10.,12.,14.,17./)
     end if

     res@gsnCenterString = CenterString
     res@gsnLeftString   = LeftString
     res@gsnRightString   = RightString
     res@lbTitleString  ="max="+sprintf("%7.2f",max(tclim))+" min="+sprintf("%7.2f",min(tclim))+" mean="+sprintf("%7.2f",dim_avg_n(dim_avg_n(tclim,0),0))
     res@lbTitleFontHeightF         = .015
     res@lbTitlePosition            = "Bottom"            ; title position
     res@lbTitleDirection           = "Across"            ; title direction
     res@tiMainString  = expid+" "+sea
     plot = gsn_csm_contour_map(wks,tclim,res)
  end if 
end
