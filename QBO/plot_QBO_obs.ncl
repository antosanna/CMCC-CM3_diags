; ===============================================
; h_time_6.ncl              
; ===============================================
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
; This file still has to be loaded manually 
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 
begin

 yrStrt   = 1980
 yrLast   = 1982
 nyrs     = yrLast-yrStrt+1
 YYYYMM   = yyyymm_time(yrStrt, yrLast, "integer")
 YYYYMMF  = yyyymm_to_yyyyfrac(YYYYMM, 0.0)
 NTIM     = dimsizes(YYYYMM)

 f    = addfile ("/work/csp/as34319/scratch/Amip_L83/hybrid_cam_hist1980_cm3_lndHIST_IC1980.1980-1984.QBO5.nc" , "r")
 time_tmp = f->time     ; (time)   days since Jan 1980-01-01
 time=time_tmp
 time=time_tmp-1
 date = cd_calendar(time, -1)

 format = "%y%N"   ; replace format_string with the desired format string
 stime  = cd_string(time, format)
 print(stime)
 
 NT=dimsizes(stime)
 
 ;;;READ txt file
 nrows=791
 ncols=9
 data  = asciiread("qbo_dat.txt",(/nrows,ncols/),"float")
 time_table=data(:,1)

 time_table_ind0=ind(time_table.eq.stime(0))
 time_table_indF=ind(time_table.eq.stime(NT-1))

 UOBS_first=data(time_table_ind0:time_table_indF,2:8)
 UOBS=0.1*UOBS_first(:,::-1)
 printVarSummary(UOBS)
 print(time_table(time_table_ind0:time_table_indF))

;70hPaN 50hPaN 40hPaN 30hPaN 20hPaN 15hPaN 10hPaN
; plev=(/70,50,40,30,20,15,10/)
 plev=(/10.,15.,20.,30.,40.,50.,70./)
 plev@units="hPa"
 UOBS!0="time"
 UOBS&time=time
 UOBS!1="plev"
 UOBS&plev=plev
 printVarSummary(UOBS)

 UQ_OBS=UOBS(plev|:,time|:)
 printVarSummary(UQ_OBS)


; UQ_OBS = smth9(UQ_OBS, 0.50, 0.25, False)
 
 klev = dimsizes(plev)
 ntim = dimsizes(time)

 U    = new ( (/klev,NTIM/), typeof(UQ_OBS), getFillValue(UQ_OBS)) 

 ntStrt = ind(date(0).eq.YYYYMM)
 ntLast = ind(date(ntim-1).eq.YYYYMM)
 print(YYYYMM)
 print(date)
 U(:,ntStrt:ntLast) = (/ UQ_OBS(plev|: , time|:) /) 
 U!0  = "plev"
 U!1  = "time"
 U&plev = plev    
 U&time = YYYYMMF
 printVarSummary (U)

 nmos   = 12
 nyrplt = nyrs                    ; number of yrs/(contour plot)
 nmoplt = nyrplt*nmos           ; number of months/(contour plot)
 npltfrm= nyrs/nyrplt           ; # (contour plots)/frame 
                                ; same as number decades/plot

 plot   = new ( npltfrm, "graphic")
 wks    = gsn_open_wks ("pdf", "QBO_OBS"+tostring(yrStrt)+"-"+tostring(yrLast))  ; send graphics to PNG file
                                ; resources which do not change
 res            = True
 res@gsnDraw    = False         ; Don't draw the plot or advance the
 res@gsnFrame   = False         ; Don't advance frame
 res@vpWidthF   = .90
 res@vpHeightF  = .25 
 res@vpXF       = .10



 res@tmXTOn               = False
 res@tmXBMode             = "Explicit"     
 res@cnLineLabelsOn       = True 
 res@cnInfoLabelOn        = False      ; Turn off info label.
 res@cnMinLevelValF       = -40.
 res@cnMaxLevelValF       =  40.
 res@cnLevelSpacingF      =  10.     
 res@cnLineLabelDensityF   = 1.5    
 res@cnLineLabelInterval=1 
 res@cnLineLabelFontHeightF=0.01
 
; res@cnFillOn             = True
 ;res@cnFillPalette        = "amwg"     ; set color map
 res@lbLabelBarOn         = False      ; turn off individual lb's

 resP                     = True                ; modify the panel plot
 resP@gsnFrame            = False               ; do not advance the frame
 resP@gsnPanelMainString  = "QBO: Equatorial Zonal Wind (OBS)"
 resP@gsnPanelBottom      = 0.03                ; extra space at bottom
 resP@gsnMaximize         = True                ; max plot foot print
 resP@gsnPanelYWhiteSpacePercent = 0.0          ; 1.0 is the default
; resP@gsnPanelLabelBar    = True                ; add common colorbar
; resP@lbLabelFontHeightF  = 0.012
 res@tmXBTickSpacingF     = 5
 res@cnLevelSelectionMode = "ManualLevels"

 source = "Source: http://www.geo.fu-berlin.de/en/met/ag/strat/produkte/qbo/"

 txres                    = True                ; additional info
 txres@txFontHeightF      = 0.010               ; size of meta data
 txres@txJust             = "CenterCenter"

 nplt   = 0
 nn     = 1
 if (nyrplt.gt.15) then
     nn = 2                         ; better spacing
 end if
 
 do nt=0,ntim-1,nmoplt              ; start months
    res@tmXBLabels = YYYYMM(nt:nt+nmoplt-1:nmos*nn)/100
    res@tmXBValues = YYYYMMF(nt:nt+nmoplt-1:nmos*nn)
    res@tmXBMinorValues = YYYYMMF(nt+nmos:nt+nmoplt-1:nmos)
    res@trYMinF=10.
    res@trYMaxF=70.

    plot(nplt)     = gsn_csm_pres_hgt (wks, U({7:110},nt:nt+nmoplt-1), res )
    opt = True
    opt@gsnShadeHigh = "LightGrey"                               ; Use fill color #52 (blue)
    plot(nplt) = gsn_contour_shade(plot(nplt),-999,0, opt)   ; Shade contours below -5
 delete(opt@gsnShadeHigh)

    delete (res@tmXBLabels)         ; size may change
    delete (res@tmXBValues)
    delete (res@tmXBMinorValues)

    nplt           = nplt+1              
    if (nplt.eq.npltfrm) then
        gsn_panel(wks,plot,(/npltfrm,1/),resP)  
        gsn_text_ndc  (wks, source, 0.50, 0.02, txres)
        frame(wks)
        exit

        nplt = 0
        NMOPLT = NMOPLT-1           
        print ("====> New Frame/Page")
    end if
 end do

 gsn_panel(wks,plot(0:nplt-1),(/npltfrm,1/),resP)  
 gsn_text_ndc  (wks, source, 0.50, 0.02, txres)
 frame(wks)

end
