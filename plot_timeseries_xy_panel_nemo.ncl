; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
cmp2obs=getenv("cmp2obstimeseries")
npl=0
nyrsmean=getenv("nyrsmean")
name_from_ext=getenv("name_from_here")
units_from_ext=getenv("units_from_here")
compute=getenv("compute")
expid=getenv("expname1")
inpfile1=getenv("inpfile")
print("--- going to read "+inpfile1)
rootinpfileobs=getenv("rootinpfileobs")
cf=tofloat(getenv("cf"))
mf=tofloat(getenv("mf"))
mftom1=getenv("mftom1")
ncurves=1
if (cmp2obs.eq.1) then
      inpfileobs1=rootinpfileobs+".Global.nc"
      varobs=getenv("varobs")
      ncurves=ncurves+1
end if
npl=npl+1
print("add a panel for Global")
yend=getenv("lasty")
yini=getenv("startyear")
varmod=getenv("varmod")
if(compute.eq.1)then
    varmod2=getenv("varmod2")
end if
print("---going to plot "+varmod)
autoprec=getenv("autoprec")
inpdir=getenv("inpdir")
plotdir=getenv("plotdir")
pltype=getenv("pltype")

print("panel "+npl)
print("curves per panel "+ncurves)
print("iniy "+yini)
print("lasty "+yend)
uplot   = new ((/npl,ncurves,toint(yend)-toint(yini)+1/),"float")   ; convert integer YYYYMM to float
ndims=dimsizes(uplot)
utitle   = new (npl,"string")   ; convert integer YYYYMM to float
i=0
f     = addfile (inpfile1,"r")
utmp     = f->$varmod$
if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
end if
u= rm_single_dims(utmp)
printVarSummary(u)
printVarSummary(uplot)
uplot(i,0,:)=u(0:ndims(2)-1)
if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobs1,"r")
       uplot(i,1,:)=rm_single_dims(fobs->$varobs$)
end if
utitle(i)="Global " 
name=utmp@long_name
taxis=varmod+" ["+utmp@units+"]"
delete(utmp)
delete(u)
if(name_from_ext.eq.1)then
    delete(name)
    name=getenv("title")
end if
if(units_from_ext.eq.1) then
    units=getenv("units")
;    taxis=varmod+" "+getenv("right")
    taxis=varmod+" ["+units+"]"
    print("----for variable "+varmod+" got units from script: "+units)
end if
if(compute.eq.1) then
    varmod=getenv("computedvar")
    taxis=varmod+" ["+units+"]"
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

print("y axis "+taxis)
res@tiYAxisString        = taxis
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

dateF   = new ((/toint(yend)-toint(yini)+1/),float)   ; convert integer YYYYMM to float
 m=1
yyyy      = toint(yini)
do n=0,dimsizes(dateF)-1
    dateF(n) = yyyy
    yyyy=yyyy+1
end do

if(autoprec.eq."False")then
    res@tmYLPrecision=2
end if

plots = new(npl,graphic)
res@gsnFrame          = False                      ; don't advance frame yet
res@gsnDraw   = False
tmp=(uplot+cf)*mf*1./tofloat(mftom1)
printVarSummary(uplot)
printVarSummary(tmp)
uplot=rm_single_dims(tmp)
copy_VarMeta(tmp,uplot)
delete(tmp)
res@vpWidthF         = 0.8                      ; set width and height
res@tiMainFontHeightF  = 0.015
res@vpHeightF        = tofloat(getenv("hplot"))
nn=dimsizes(uplot)
nt=nn(2)-1
ini=nt-toint(nyrsmean)+1
if (ini.lt.0) then
   ini=0
   nyrsmean=sprinti("%2i",nt)
end if
do i=0,npl-1
     res@gsnLeftString      = utitle(i)+" last "+nyrsmean+" yy="+sprintf("%6.3f",dim_avg(uplot(i,0,ini:nt)))
     res@gsnRightString=name
     plots(i)  = gsn_csm_xy (wks,dateF,uplot(i,:,:),res)            ; create plot
end do
pres=True
pres@gsnPanelMainString     = expid+" "+yini+"-"+yend
gsn_panel(wks,plots,(/npl,1/),pres) ; Draw as one plot

end
