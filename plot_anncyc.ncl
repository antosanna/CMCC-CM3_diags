; ***********************************************
;************************************************
begin
;************************************************
; read in data
;************************************************
print("executing plot_anncyc.ncl")
cmp2obs=getenv("cmp2obs_anncyc")
ncl_lev=toint(getenv("ncl_lev"))
npl=0
nyrsmean=getenv("nyrsmean")
name_from_ext=getenv("name_from_here")
units_from_ext=getenv("units_from_here")
compute=getenv("compute")
expid=getenv("expname1")
inpfile=getenv("inpfileanncyc")
print("--- going to read "+inpfile)
rootinpfileobs=getenv("rootinpfileobs")
cf=tofloat(getenv("cf"))
mf=tofloat(getenv("mf"))
mftom1=getenv("mftom1")
bglo=getenv("bglo")
print(bglo)
bNH=getenv("bNH")
bSH=getenv("bSH")
bu010=getenv("bu010")
bextraTNH_E=getenv("bextraTNH_E")
bextraTNH_W=getenv("bextraTNH_W")
bAfricaNH=getenv("bAfricaNH")
bAfricaSH=getenv("bAfricaSH")
bAmazon=getenv("bAmazon")
varobs=getenv("varobs")
ncurves=1
if(bglo.eq.1)then
   inpfile1=inpfile+".Global.nc"
   if (cmp2obs.eq.1) then
      inpfileobs1=rootinpfileobs+".Global.nc"
      ncurves=ncurves+1
   end if
   npl=npl+1
end if
if(bNH.eq.1)then
   inpfileNH=inpfile+".NH.nc"
   npl=npl+1
   if (cmp2obs.eq.1) then
      inpfileobsNH=rootinpfileobs+".NH.nc"
   end if
end if
if(bSH.eq.1)then
   inpfileSH=inpfile+".SH.nc"
   npl=npl+1
   if (cmp2obs.eq.1) then
      inpfileobsSH=rootinpfileobs+".SH.nc"
   end if
end if
if(bu010.eq.1)then
   inpfileu010=inpfile+".u010.nc"
   npl=npl+1
   if (cmp2obs.eq.1) then
      inpfileobsu010=rootinpfileobs+".u010.nc"
   end if
end if
;print("numero plot "+npl)
if(bextraTNH_W.eq.1)then
   inpfileextraTNH_W=inpfile+".extraTNH_W.nc"
   if (cmp2obs.eq.1) then
      ncurves=ncurves+1
      inpfileobsextraTNH_W=rootinpfileobs+".extraTNH_W.nc"
   end if
   npl=npl+1
end if
if(bextraTNH_E.eq.1)then
   inpfileextraTNH_E=inpfile+".extraTNH_E.nc"
   if (cmp2obs.eq.1) then
      inpfileobsextraTNH_E=rootinpfileobs+".extraTNH_E.nc"
   end if
   npl=npl+1
end if
if(bAfricaSH.eq.1)then
   inpfileAfricaSH=inpfile+".AfricaSH.nc"
   if (cmp2obs.eq.1) then
      inpfileobsAfricaSH=rootinpfileobs+".AfricaSH.nc"
   end if
   npl=npl+1
end if
if(bAfricaNH.eq.1)then
   inpfileAfricaNH=inpfile+".AfricaNH.nc"
   if (cmp2obs.eq.1) then
      inpfileobsAfricaNH=rootinpfileobs+".AfricaNH.nc"
   end if
   npl=npl+1
end if
if(bAmazon.eq.1)then
   inpfileAmazon=inpfile+".Amazon.nc"
   if (cmp2obs.eq.1) then
      inpfileobsAmazon=rootinpfileobs+".Amazon.nc"
   end if
   npl=npl+1
end if
 varmod=getenv("varmod")
 if(compute.eq.1)then
    varmod2=getenv("varmod2")
 end if
 print("---going to plot "+varmod)
 autoprec=getenv("autoprec")
 plotdir=getenv("plotdir")
 pltype=getenv("pltype")

 print("panel "+npl)
 print("curves per panel "+ncurves)
 uplot   = new ((/npl,ncurves,12/),"float")   ; convert integer YYYYMM to float
 ndims=dimsizes(uplot)
 utitle   = new (npl,"string")   ; convert integer YYYYMM to float
 i=0
 if(bglo.eq.1)then
    f     = addfile (inpfile1,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    printVarSummary(u)
    printVarSummary(uplot)
    uplot(i,0,:)=u(0:ndims(2)-1)
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobs1,"r")
       if(ncl_lev.eq.0)then
          tmp=rm_single_dims(tofloat(fobs->$varobs$(:,0,0)))
       else
          tmp=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
       printVarSummary(tmp)
       print(tmp)
       uplot(i,1,:)=tmp
       delete(tmp)
    end if
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
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="NH " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsNH,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
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
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="SH " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsSH,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
 if(bu010.eq.1)then
    f     = addfile (inpfileu010,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="u010@60N " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsu010,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
; if(bextraTNH_E.eq.1)then
;    f     = addfile (inpfileextraTNH_E,"r")
;    utmp     = f->$varmod$
;    if(compute.eq.1) then
;       utmp     = f->$varmod$ - f->$varmod2$
;    end if
;    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
;    uplot(i,0,:)=u(0:ndims(2)-1)
;    utitle(i)="extraTNH_E " 
;    delete(u)
;    name=utmp@long_name
;    if(cmp2obs.eq.1)then
;       fobs     = addfile (inpfileobsextraTNH_E,"r")
;       print("going to read fobs "+inpfileobsextraTNH_E)
;       print("var to read is "+varobs)
;       if(ncl_lev.eq.0)then
;          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
;       else
;          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
;       end if
;       print(uplot(i,1,:))
;    end if
; end if
 if(bextraTNH_W.eq.1)then
    f     = addfile (inpfileextraTNH_W,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="extraTNH_W " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsextraTNH_W,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
 if(bextraTNH_E.eq.1)then
    f     = addfile (inpfileextraTNH_E,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="extraTNH_E " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsextraTNH_E,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
 if(bAfricaNH.eq.1)then
    f     = addfile (inpfileAfricaNH,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="AfricaNH " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsAfricaNH,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
 if(bAfricaSH.eq.1)then
    f     = addfile (inpfileAfricaSH,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="AfricaSH " 
    name=utmp@long_name
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsAfricaSH,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    i=i+1
 end if
 if(bAmazon.eq.1)then
    f     = addfile (inpfileAmazon,"r")
    utmp     = f->$varmod$
    if(compute.eq.1) then
       utmp     = f->$varmod$ - f->$varmod2$
    end if
    u= (rm_single_dims(utmp)+cf)*mf*1./tofloat(mftom1)
    uplot(i,0,:)=u(0:ndims(2)-1)
    utitle(i)="Amazon basin " 
    if(cmp2obs.eq.1)then
       fobs     = addfile (inpfileobsAmazon,"r")
       if(ncl_lev.eq.0)then
          uplot(i,1,:)=tofloat(rm_single_dims(fobs->$varobs$))
       else
          uplot(i,1,:)=rm_single_dims(tofloat(fobs->$varobs$(:,ncl_lev,0,0)))
       end if
    end if
    name=utmp@long_name
    i=i+1
 end if
 if(varmod.eq."TREFHT".or.varmod.eq."TS")then
    uplot(:,1,:)= (uplot(:,1,:)+cf)*mf*1./tofloat(mftom1)
 end if
 if (varmod.eq."FLNT" .or. varmod.eq."FLNS")then
    uplot(:,1,:)= -uplot(:,1,:)
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
 print("plot is "+pltname)
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
 res@xyMarkerColors := (/"blue","red"/) ; 3 different colors
 res@tmXBLabelAngleF=45
; add a legend
 if(cmp2obs.eq.1)then
    res@pmLegendDisplayMode    = "Always"              ; turn on legend
 end if
 
 res@pmLegendSide           = "Top"                 ; Change location of 
 res@pmLegendParallelPosF   = 1.15                   ; move units right
 res@pmLegendOrthogonalPosF = -0.8                  ; more neg = down
 
 res@pmLegendWidthF         = 0.1                  ; Change width and
 res@pmLegendHeightF        = 0.12                  ; height of legend.
 res@lgLabelFontHeightF     = .015                   ; change font height
 res@lgPerimOn              = False                 ; no box around
; labels for the legend
 res@xyExplicitLegendLabels = (/"model", "observations"/)

 if(autoprec.eq."False")then
    res@tmYLPrecision=2
 end if

  plots = new(npl,graphic)
 res@gsnFrame          = False                      ; don't advance frame yet
 res@gsnDraw   = False
 res@vpWidthF         = 0.8                      ; set width and height
 res@tiMainFontHeightF  = 0.015
 res@vpHeightF        = tofloat(getenv("hplot"))
; nn=dimsizes(uplot)
; nt=nn(2)-1
; ini=nt-toint(nyrsmean)
; if (ini.lt.0) then
;   ini=0
;   nyrsmean=sprinti("%2i",nt)
; end if
 do i=0,npl-1
     res@gsnLeftString      = utitle(i)
     res@gsnRightString=name
     plots(i)  = gsn_csm_xy (wks,ispan(1,12,1),uplot(i,:,:),res)            ; create plot
 end do
 pres=True
 pres@gsnPanelMainString     = expid+" annual cycle"
 gsn_panel(wks,plots,(/npl,1/),pres) ; Draw as one plot

end
