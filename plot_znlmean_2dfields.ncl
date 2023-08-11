; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
npl=1
cmp2obs=toint(getenv("cmp2obs"))
units_from_ext=getenv("units_from_here")
expid=getenv("expname1")
inpfile=getenv("inpfileznl")
print("--- going to read "+inpfile)
sea=getenv("sea")
inpfileobs=getenv("obsfileznl")
cf=tofloat(getenv("cf"))
mf=tofloat(getenv("mf"))
ncurves=1
if (cmp2obs.eq.1) then
   ncurves=2
   npl=3
end if
 yend=getenv("lasty")
 yini=getenv("startyear")
 varmod=getenv("varmod")
 print("---going to plot "+varmod)
; autoprec=getenv("autoprec")
 plotdir=getenv("plotdir")
 pltype=getenv("pltype")

 print("curves per panel "+ncurves)
 print("iniy "+yini)
 print("lasty "+yend)
 utitle   = new (npl,"string")   ; convert integer YYYYMM to float
 i=0
 f     = addfile (inpfile,"r")
 utmp     = f->$varmod$
 lat     = f->lat
 u= rm_single_dims(utmp)
 printVarSummary(u)
 uplot   = new ((/npl,ncurves,dimsizes(lat)/),"float")   ; convert integer YYYYMM to float
 printVarSummary(uplot)
 uplot(i,0,:)=u
;    utitle(i)="Global"
 name=utmp@long_name
 delete(utmp)
 delete(u)
 if(name_from_ext.eq.1)then
    delete(name)
    name=getenv("title")
 end if
 if(units_from_ext.eq.1) then
    units=getenv("units")
    taxis=varmod+" ["+units+"]"
    print("----for variable "+varmod+" got units from script: "+units)
 end if
;************************************************
; to plot multiple lines, you must put them into
; a multidimensional array
;************************************************
;************************************************
; create plot
;************************************************
 system("mkdir -p "+plotdir)
 pltname   = getenv("pltname")
 wks   = gsn_open_wks (pltype,pltname)

 res                   = True                       ; plot mods desired
; res@gsnFrame          = False                      ; don't advance frame yet
; res@gsnDraw   = False

 res@xyDashPattern  = 0                         ; Make curves all solid
 res@xyMarkLineMode = "MarkLines"               ; Markers *and* lines
 res@xyMarker      = 1
 res@xyMarkerSizeF=0.03
 res@xyMarkerColors := (/"blue","red","green","magenta","grey","orange"/) ; 3 different colors
 res@tmXBLabelAngleF=45
; add a legend
 if(cmp2obs.eq.1)then
    res@pmLegendDisplayMode    = "Always"              ; turn on legend
 end if
 
 res@pmLegendSide           = "Top"                 ; Change location of 
 res@pmLegendParallelPosF   = 1.15                   ; move units right
 res@pmLegendOrthogonalPosF = -0.8                  ; more neg = down
 
 res@pmLegendWidthF         = 0.12                  ; Change width and
 res@pmLegendHeightF        = 0.25                  ; height of legend.
 res@lgLabelFontHeightF     = .02                   ; change font height
 res@lgPerimOn              = False                 ; no box around
; labels for the legend
 res@xyExplicitLegendLabels = (/expid, "observations", "t02d", "t02e", "t03c","t03d","obs"/)

; if(autoprec.eq."False")then
;    res@tmYLPrecision=2
; end if

 plots = new(npl,graphic)
 res@gsnFrame          = False                      ; don't advance frame yet
 res@gsnDraw   = False
 tmp=(uplot+cf)*mf
 printVarSummary(uplot)
 printVarSummary(tmp)
 uplot=tmp
 copy_VarMeta(tmp,uplot)
 delete(tmp)
 res@vpWidthF         = 0.8                      ; set width and height
 res@tiMainFontHeightF  = 0.015
; res@vpHeightF        = tofloat(getenv("hplot"))
 do i=0,npl-1
     res@gsnLeftString      = utitle(i)
     res@gsnRightString=name
     plots(i)  = gsn_csm_xy (wks,lat,uplot(i,:,:),res)            ; create plot
 end do
 pres=True
 pres@gsnPanelMainString     = expid+" "+yini+"-"+yend
 gsn_panel(wks,plots,(/npl,1/),pres) ; Draw as one plot

end
