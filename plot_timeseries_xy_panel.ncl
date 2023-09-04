; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
cmp2obs=0
 npl=0
nyrsmean=getenv("nyrsmean")
name_from_ext=getenv("name_from_here")
units_from_ext=getenv("units_from_here")
compute=getenv("compute")
expid=getenv("expname1")
inpfile=getenv("inpfile")
print("--- going to read "+inpfile)
inpfileobs=getenv("inpfileobs")
cf=tofloat(getenv("cf"))
mf=tofloat(getenv("mf"))
mftom1=getenv("mftom1")
bglo=getenv("bglo")
print(bglo)
bNH=getenv("bNH")
bSH=getenv("bSH")
b7090=getenv("b7090")
b7090S=getenv("b7090S")
b3070=getenv("b3070")
b3070S=getenv("b3070S")
b3030=getenv("b3030")
bland=getenv("bland")
boce=getenv("boce")
ncurves=1
if(bglo.eq.1)then
   inpfile1=inpfile+".Global.nc"
   if (cmp2obs.eq.1) then
      inpfileobs1=inpfileobs+".Global.nc"
      cmp2obs=0
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(bNH.eq.1)then
   inpfileNH=inpfile+".NH.nc"
   npl=npl+1
   if (cmp2obs.eq.1) then
      inpfileobsNH=inpfileobs+".NH.nc"
      ncurves=ncurves+1
   end if
end if
if(bSH.eq.1)then
   inpfileSH=inpfile+".SH.nc"
   npl=npl+1
   if (cmp2obs.eq.1) then
      inpfileobsSH=inpfileobs+".SH.nc"
      ncurves=ncurves+1
   end if
end if
if(b7090.eq.1)then
   inpfile7090=inpfile+".70N-90N.nc"
   if (cmp2obs.eq.1) then
      inpfileobs7090=inpfileobs+".70N-90N.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(b3070.eq.1)then
   inpfile3070=inpfile+".30N-70N.nc"
   if (cmp2obs.eq.1) then
      inpfileobs3070=inpfileobs+".30N-70N.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(b3030.eq.1)then
   inpfile3030=inpfile+".30S-30N.nc"
   if (cmp2obs.eq.1) then
      inpfileobs3030=inpfileobs+".30S-30N.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(b3070S.eq.1)then
   inpfile3070S=inpfile+".30S-70S.nc"
   if (cmp2obs.eq.1) then
      inpfileobs3070S=inpfileobs+".30S-70S.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(b7090S.eq.1)then
   inpfile7090S=inpfile+".70S-90S.nc"
   if (cmp2obs.eq.1) then
      inpfileobs7090S=inpfileobs+".70S-90S.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(bland.eq.1)then
   inpfileland=inpfile+".land.nc"
   if (cmp2obs.eq.1) then
      inpfileobsland=inpfileobs+".land.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(boce.eq.1)then
   inpfileoce=inpfile+".oce.nc"
   if (cmp2obs.eq.1) then
      inpfileobsoce=inpfileobs+".oce.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
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
 if(bglo.eq.1)then
    f     = addfile (inpfile1,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    printVarSummary(u)
    printVarSummary(uplot)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="Global " 
    name=utmp@long_name
    i=i+1
 end if
 if(bNH.eq.1)then
    f     = addfile (inpfileNH,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="NH" 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsNH,"r")
       uNobs     = (fobs->$varobs$(:,0,0))*1000
       if(varmod.eq."H2OSNO")then
          uplot(i,1,1950-toint(yini):)=uNobs(0:toint(yend)-1950)
       end if
    end if
    i=i+1
 end if
 if(bSH.eq.1)then
    f     = addfile (inpfileSH,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="SH" 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsSH,"r")
       uNobs     = (fobs->$varobs$(:,0,0))*1000
       if(varmod.eq."H2OSNO")then
          uplot(i,1,1950-toint(yini):)=uNobs(0:toint(yend)-1950)
       end if
    end if
    i=i+1
 end if
 if(b7090.eq.1)then
    f     = addfile (inpfile7090,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="70N-90N" 
    delete(u)
    name=utmp@long_name
 end if
 if(b3070.eq.1)then
    f     = addfile (inpfile3070,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="30N-70N" 
    name=utmp@long_name
    i=i+1
 end if
 if(b3030.eq.1)then
    f     = addfile (inpfile3030,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="30S-30N" 
    name=utmp@long_name
    i=i+1
 end if
 if(b3070S.eq.1)then
    f     = addfile (inpfile3070S,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="30S-70S" 
    name=utmp@long_name
    i=i+1
 end if
 if(b7090S.eq.1)then
    f     = addfile (inpfile7090S,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="70S-90S" 
    name=utmp@long_name
    i=i+1
 end if
 if(bland.eq.1)then
    f     = addfile (inpfileland,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="land" 
    name=utmp@long_name
    i=i+1
 end if
 if(boce.eq.1)then
    f     = addfile (inpfileoce,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= rm_single_dims(utmp)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="oce" 
    name=utmp@long_name
    i=i+1
 end if
 if(cmp2obs.eq.1)then
 if(varmod.eq."H2OSNO")then
    fobs     = addfile (obsfileS,"r")
    uSobs     = (fobs->sd(:,0,0))*1000
    uSplot(i,1,1950-toint(yini):)=uSobs(0:toint(yend)-1950)
 end if
 end if
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
; res@gsnFrame          = False                      ; don't advance frame yet
; res@gsnDraw   = False

 print("y axis "+taxis)
 res@tiYAxisString        = taxis
; res@tiYAxisJust          = "CenterLeft"
; res@tiYAxisSide          = "Left"
; res@tiYAxisPosition      = "Bottom"
; res@tiXAxisString="years"
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
 uplot=tmp
 copy_VarMeta(tmp,uplot)
 delete(tmp)
 res@vpWidthF         = 0.8                      ; set width and height
 res@tiMainFontHeightF  = 0.015
 res@vpHeightF        = tofloat(getenv("hplot"))
 nn=dimsizes(uplot)
 nt=nn(2)-1
 do i=0,npl-1
     res@gsnLeftString      = utitle(i)+" last "+nyrsmean+" yy="+sprintf("%5.2f",dim_avg(uplot(i,0,nt-toint(nyrsmean):nt)))
     res@gsnRightString=name
     plots(i)  = gsn_csm_xy (wks,dateF,uplot(i,:,:),res)            ; create plot
 end do
 pres=True
 pres@gsnPanelMainString     = expid+" "+yini+"-"+yend
 gsn_panel(wks,plots,(/npl,1/),pres) ; Draw as one plot

end
