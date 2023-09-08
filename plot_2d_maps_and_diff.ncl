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
  expid=getenv("expname1")
  expid2=getenv("expname2")
  name_from_ext=getenv("name_from_here")
  units_from_ext=getenv("units_from_here")
  modfile=getenv("inpfile")
  comp=getenv("comp")
  cmp2obs=toint(getenv("cmp2obs_ncl"))
  cmp2mod=toint(getenv("cmp2mod_ncl"))
  sea=getenv("sea")
  pltname=getenv("pltname")
  pltype=getenv("pltype")
  varmod=getenv("varmod")
  varobs=getenv("varobs")
  cf=tofloat(getenv("cf"))
  mf=tofloat(getenv("mf"))
  print(mf)
  in = addfile(modfile,"r")
  print("----model file "+modfile)
  t=rm_single_dims(in->$varmod$)
  latmod=in->lat
  lonmod  = in->lon
  rad=4.0*atan(1.0)/180.0
  wgty_mod= cos(latmod*rad)
  print("")
  print("----season is "+sea)
  if(sea.eq."ANN") then
     tclim=dim_avg_n(t,0)
  end if
  if (sea.eq."JJA") then
     tclim=dim_avg_n(t(5:7,:,:),0)
  end if
  if (sea.eq."DJF") then
     nn=dimsizes(t(0,:,:))
     tmpmod=new((/3,nn(0),nn(1)/),typeof(t))
     tmpmod(1,:,:)=t(1,:,:)
     tmpmod(2,:,:)=t(11,:,:)
     tclim=dim_avg_n(tmpmod,0)
     delete(tmpmod)
  end if
  tclim=(tclim+cf)*mf
  printMinMax(tclim,0)
  copy_VarMeta(t(0,:,:),tclim)
  tclim!0="lat"
  tclim!1="lon"
  tclim&lat=latmod
  tclim&lon=lonmod
  printVarSummary( wgty_mod)
  printVarSummary(tclim)
  if(cmp2mod.eq.1)then
     modfile2=getenv("modfile")
     print("----compare to model file "+modfile2)
     in = addfile(modfile2,"r")
     lonmod2  = in->lon
     latmod2 = in->lat
     wgty_mod2= cos(latmod2*rad)
     t2=in->$varmod$
     if(sea.eq."ANN") then
        tclim2=dim_avg_n(t2,0)
     end if
     if (sea.eq."JJA") then
        tclim2=dim_avg_n(t2(5:7,:,:),0)
     end if
     if (sea.eq."DJF") then
        nn=dimsizes(t2(0,:,:))
        tmpmod=new((/3,nn(0),nn(1)/),typeof(t2))
        tmpmod(1,:,:)=t2(1,:,:)
        tmpmod(2,:,:)=t2(11,:,:)
        tclim2=dim_avg_n(tmpmod,0)
        delete(tmpmod)
     end if
     tclim2=(tclim2+cf)*mf
     printMinMax(tclim2,0)
  end if
  if(cmp2obs.eq.1)then
     obsfile=getenv("obsfile")
     print("----observations file "+obsfile)
     in = addfile(obsfile,"r")
     lon  = in->lon
     lat  = in->lat
     if(varmod.eq."EnBalSrf".or.varmod.eq."ALBEDOS" .or. varmod.eq."SHFLX" .or. varmod.eq."LHFLX" .or. varobs.eq."var167".or.varmod.eq."CLDTOT".or.varmod.eq."CLDHGH".or.varmod.eq."CLDMED".or.varmod.eq."CLDLOW".or.varmod.eq."FSDS".or.varmod.eq."FSNS".or.varmod.eq."FSNT".or.varmod.eq."FSNTOA".or.varmod.eq."TS".or.varmod.eq."FLDS")then
        tobs  = in->$varobs$(:,::-1,:)
        lat  = in->lat(::-1)
     else if (varmod.eq."FLNT" .or. varmod.eq."FLNS")then
        tobs  = -(in->$varobs$(:,::-1,:)) ; different sign convention for longwave radiation btw era5 and cam
        lat  = in->lat(::-1)
     else if (varobs.eq."Z" .or. varobs.eq."U".or.varobs.eq."var131".or.varobs.eq."var129")then
        lev=toint(getenv("ncl_lev"))
        print("level index "+lev)
        tobs  = in->$varobs$(:,lev,:,:)
        if (varobs.eq."var131".or.varobs.eq."var129")then
           lat  = in->lat(::-1)
           tobs  = in->$varobs$(:,lev,::-1,:)
           if (varobs.eq."var129")then
              tmp=tobs/9.8065
              copy_VarMeta(tobs,tmp)
              tobs=tmp
           end if
        end if
        if (varobs.eq."Z")then
           tmp=tobs*100
           copy_VarMeta(tobs,tmp)
           tobs=tmp
           printMinMax(tobs,0)
           delete(tmp)
        end if
     else
        tobs  = in->$varobs$
     end if
     end if
     end if
     if(sea.eq."ANN") then
        tobsclim=dim_avg_n(tobs,0)
     else if (sea.eq."JJA") then
        tobsclim=dim_avg_n(tobs(5:7,:,:),0)
     else if (sea.eq."DJF") then
        nn=dimsizes(tobs(0,:,:))
        tmpobs=new((/3,nn(0),nn(1)/),typeof(tobs))
        tmpobs(1,:,:)=tobs(1,:,:)
        tmpobs(2,:,:)=tobs(11,:,:)
        tobsclim=dim_avg_n(tmpobs,0)
        delete(tmpobs)
     end if
     end if
     end if
     if(varmod.eq."TREFHT".or.varmod.eq."TS")then
        tobsclim=(tobsclim+cf)*mf
        copy_VarMeta(tobs(0,:,:),tobsclim)
     end if
     wgty_obs=cos(lat*rad)
     printVarSummary(wgty_obs)
     printVarSummary(tobsclim)
     printMinMax(tobsclim,0)
  end if
;---Common definitions
;  FillPalette     = "gui_default"    ; set color map
  FillPalette     = read_colormap_file("amwg") 
  if(varmod.eq."CLDTOT".or.varmod.eq."CLDLOW".or.varmod.eq."CLDMED".or.varmod.eq."CLDHGH".or.varmod.eq."H2OSNO".or.varmod.eq."SNOWDP".or.varmod.eq."hi".or.varmod.eq."aice")then
      delete(FillPalette)
;      cmap = read_colormap_file("WhiteBlue")
;      FillPalette     = cmap(::-1,:)
      FillPalette     = read_colormap_file("amwg") 
  end if
  if(varmod.eq."H2OSNO".or.varmod.eq."SNOWDP")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.05,tclim@_FillValue,tclim)
     if(cmp2mod.eq.1) then
        tclim2@_FillValue=-999.
        tclim2=where(tclim2.lt.0.05,tclim2@_FillValue,tclim2)
     end if
  end if
  if(varmod.eq."QOVER")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.00005,tclim@_FillValue,tclim)
     if(cmp2mod.eq.1) then
        tclim2@_FillValue=-999.
        tclim2=where(tclim2.lt.0.00005,tclim2@_FillValue,tclim2)
     end if
  end if
  if(varmod.eq."ICEFRAC")then
     tclim@_FillValue=-999.
     tclim=where(tclim.lt.0.1,tclim@_FillValue,tclim)
     if(cmp2mod.eq.1) then
        tclim2@_FillValue=-999.
        tclim2=where(tclim2.lt.0.1,tclim2@_FillValue,tclim2)
     end if
  end if
  if(comp.eq."lnd")then
     OceanFillColor      = "grey"
     MissingValFillColor = "grey"
  end if
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
    RightString=units
 end if

  wks = gsn_open_wks(pltype,pltname)
  if(cmp2obs.eq.1.or.cmp2mod.eq.1)then 
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

     if(comp.eq."lnd")then
        res@cnMissingValFillColor =MissingValFillColor
        res@mpOceanFillColor      = OceanFillColor
     end if

     res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
     res@cnMinLevelValF       = tofloat(getenv("minplot"))             ; min level
     res@cnMaxLevelValF       = tofloat(getenv("maxplot"))            ; max level
     res@cnLevelSpacingF      = tofloat(getenv("delta"))             ; contour interval
;     res@mpLandFillColor      = "white"       ; make land white
     if(varmod.eq."PRECC".or.varmod.eq."PRECT".or.varmod.eq."PRECL")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/.2,.5,1,2.,3.0,4.0,5.,6.,7.,8.,9.,10.,12.,14.,17./)
     end if
     if(varmod.eq."ICEFRAC")then
        delete(res@cnLevelSelectionMode)
        res@cnLevelSelectionMode="ExplicitLevels"
        delete(res@cnLevels)
        res@cnLevels     = (/.2,.3,.4,.5,.6,.7,.8,.9/)
     end if

     res@gsnCenterString = CenterString
     res@gsnLeftString   = LeftString
     res@gsnRightString   = RightString

     plot(0) = gsn_csm_contour_map(wks,tclim, res)

     if(cmp2obs.eq.1)then
        res@gsnCenterString = getenv("title2")
        tobsclim!0="lat"
        tobsclim!1="lon"
        tobsclim&lat=lat
        tobsclim&lon=lon
        tobsclim&lat@units="degree_N"
        tobsclim&lon@units="degree_E"
        delete(res@gsnLeftString)
        delete(res@gsnRightString)
        plot(1) = gsn_csm_contour_map(wks,tobsclim, res)
     else if (cmp2mod.eq.1)then
        tclim2!0="lat"
        tclim2!1="lon"
        tclim2&lat=latmod2
        tclim2&lon=lonmod2
        tclim2&lat@units="degree_N"
        tclim2&lon@units="degree_E"
        delete(res@gsnLeftString)
        delete(res@gsnRightString)
        res@gsnCenterString = getenv("title2mod")
        plot(1) = gsn_csm_contour_map(wks,tclim2, res)
     end if
     end if
     lbhid = createLabelBar(wks, plot, lbvres)

    ;********************************
    ; Hist (Rightmost column)
    ;********************************
     if(cmp2obs.eq.1)then
        res@gsnCenterString = "Model - Observations"
     else if (cmp2mod.eq.1)then
        res@gsnCenterString = expid+" - "+expid2
     end if
     end if
     res@cnMinLevelValF       =  0.0            ; set min contour level
     res@cnMaxLevelValF       = 26.0            ; set max contour level
     res@cnLevelSpacingF      =  1.0            ; set contour spacing

     delete(res@cnFillPalette)
     cmap1 = read_colormap_file("hotcold_18lev")
     res@cnFillPalette     = cmap1
     if(varmod.eq."TREFHT".or.varmod.eq."TS")then
        res@cnLevelSelectionMode="ExplicitLevels"
;        res@cnLevels     = (/-5.,-3.,-2.,-1.,-.25,.25,1.,2,3,5/)
        res@cnLevels     = (/-4.,-2.,-1.5,-1.,-.5,.5,1.,1.5,2,4/)
     else
        res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
        res@cnMinLevelValF       = tofloat(getenv("minplotdiff"))             ; min level
        res@cnMaxLevelValF       = tofloat(getenv("maxplotdiff"))            ; max level
        res@cnLevelSpacingF      = tofloat(getenv("deltadiff"))             ; contour interval
     end if
     if(varmod.eq."PRECT")then
        delete(res@cnFillPalette)
        cmap2 = read_colormap_file("hotcold_18lev")
;        cmap2 = read_colormap_file("nrl_sirkes")
        res@cnFillPalette     = cmap2(::-1,:)
        delete(res@cnLevels)
        res@cnLevelSelectionMode="ExplicitLevels"
        res@cnLevels     = (/-8,-6,-4,-3,-2,-1,-0.5,0.5,1,2,3,4,6,8/)
;        res@cnMinLevelValF=-5.
;        res@cnMaxLevelValF=5.
;        res@cnLevelSpacingF      = 1.
     end if
;     print(lonmod)
;     print(latmod)
;     print(lon)
;     print(lat)
      if (varmod.eq."FSNT") then
          res@gsnLeftString   = LeftString
     end if
     if(cmp2mod.eq.1)then
        lon=fspan(0.5,359.5,360)
        lat=fspan(-89.5,89.5,180)
        wgty_common= cos(lat*rad)
        tclim_common_grid = linint2_Wrap (lonmod,latmod,tclim, True, lon,lat, 0)
        tclim2_common_grid= linint2_Wrap (lonmod2,latmod2,tclim2, True, lon,lat, 0)
        printMinMax(tclim_common_grid,0)
        diff=tclim_common_grid-tclim2_common_grid
     else if  (cmp2obs.eq.1) then
        tclim_in_obs = linint2_Wrap (lonmod,latmod,tclim, True, lon,lat, 0)
        printMinMax(tclim_in_obs,0)
        diff=tclim_in_obs-tobsclim
     end if
     end if
     diff!0="lat"
     diff!1="lon"
     diff&lat=lat
     diff&lon=lon
     diff&lat@units="degree_N"
     diff&lon@units="degree_E"
     if(varmod.eq."ALBEDOS" .or. varmod.eq."ALBEDO")then
         print("managing NaN in ALBEDO diff")
         diff@_FillValue=-999.
         diff=where(diff.lt.-2.,diff@_FillValue,diff)
         diff=where(diff.gt.2.,diff@_FillValue,diff)
     end if
     res@gsnLeftString   = ""
     res@gsnRightString   = ""
;     delete(res@cnFillPalette)
;     cmap2 = read_colormap_file("hotcold_18lev")
;     res@cnFillPalette     = cmap2(::-1,:)
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
     if(cmp2obs.eq.1)then
        gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tobsclim)),0.82,0.3955,txres)
        gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tobsclim)),0.82,0.3805,txres)
        gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tobsclim, wgty_obs, 1.0, 1)),0.82,0.3655,txres)
        gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(diff, wgty_obs, 1.0, 1)),0.82,0.03,txres)
     else if(cmp2mod.eq.1)then
        gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(tclim2)),0.82,0.3955,txres)
        gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(tclim2)),0.82,0.3805,txres)
        gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(tclim2, wgty_mod, 1.0, 1)),0.82,0.3655,txres)
        gsn_text_ndc(wks,"mean="+sprintf("%7.2f",wgt_areaave_Wrap(diff, wgty_common, 1.0, 1)),0.82,0.03,txres)
     end if
     end if
     gsn_text_ndc(wks,"max="+sprintf("%7.2f",max(diff)),0.82,0.06,txres)
     gsn_text_ndc(wks,"min="+sprintf("%7.2f",min(diff)),0.82,0.045,txres)
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
     if(comp.eq."lnd")then
        res@cnMissingValFillColor =MissingValFillColor
        res@mpOceanFillColor      = OceanFillColor
     end if

     res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
     res@cnMinLevelValF       = tofloat(getenv("minplot"))             ; min level
     res@cnMaxLevelValF       = tofloat(getenv("maxplot"))            ; max level
     res@cnLevelSpacingF      = tofloat(getenv("delta"))             ; contour interval
;     res@mpLandFillColor      = "white"       ; make land white
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
     res@tiMainString  = expid + " "+ sea
     plot = gsn_csm_contour_map(wks,tclim,res)
  end if 
end
