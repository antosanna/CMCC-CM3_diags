begin
    nyears=toint(getenv("nyears"))
    pltype=getenv("pltype")
    pltname=getenv("pltname")
    freq=getenv("freq")
    print(freq)

; constants from CMCC-CM3 components
    rsph =6378160 ;Earth radius in m
    rho=1000 ; kg/m3 in clm
    rhoi=917 ; kg/m3
    rhos=250 ; kg/m3  in clm
;
; conversion factor from degrees to radinas
    d2r=atan(1)*4./180.

;input file atmosphere
    infileA=getenv("infileA")
    fcam=addfile(infileA+"0001-01.nc","r")
    lat=fcam->lat
    lon=fcam->lon
    nlat=dimsizes(lat)
    nlon=dimsizes(lon)
    massA=new(nyears*12,typeof(lat))
    massL=new(nyears*12,typeof(lat))
    massL@_FillValue=-999.
    massO=new(nyears*12,typeof(lat))
    massI=new(nyears*12,typeof(lat))
    massI@_FillValue=-999.
    ssh=new(nyears*12,typeof(lat))
    steric=new(nyears*12,typeof(lat))
    all_masses=new((/7,nyears*12/),typeof(massA))
    y_all_masses=new((/7,nyears,12/),typeof(massA))
    areaA=new((/nlat,nlon/),typeof(lat))
    do i=1,nlat-1
       do j=1,nlon-1
          qlat = (/ 0, lat(i)-lat(i-1), lat(i)-lat(i-1), 0./)  ;degrees
          qlon = (/0.,0.,lon(j)-lon(j-1),lon(j)-lon(j-1)/);degrees

          areaA(i,j) = area_poly_sphere(qlat, qlon, rsph)*cos(d2r*lat(i))
       end do
    end do
    areaA(0,:)=areaA(1,:) ; in m2
    areaA(:,0)=areaA(:,1)
    ic=0
    do iy=1,nyears
    do m=1,12
       fcam=addfile(infileA+sprinti("%0.4i",iy)+"-"+sprinti("%0.2i",m)+".nc","r")
       precwat=fcam->TMQ(0,:,:)  ;kg/m2
       massA(ic)=dim_sum_n(dim_sum_n(precwat*areaA,0),0)
       y_all_masses(2,iy-1,m-1)=dim_sum_n(dim_sum_n(precwat*areaA,0),0)
       ic=ic+1
    end do
    end do
    all_masses(2,:)=massA
;    print(massA)

    
;input file land
    infileL=getenv("infileL")
    fclm=addfile(infileL+"0001-01.nc","r")
    areaL_km2=fclm->area    ;km2
    areaL=areaL_km2*1000000
    ic=0
    do iy=1,nyears
    do m=1,12
       fclm=addfile(infileL+sprinti("%0.4i",iy)+"-"+sprinti("%0.2i",m)+".nc","r")
       tws=fclm->TWS(0,:,:)*0.001  ;TWS in mm
       tmp=tws*areaL*rho
       tmp=where(tmp.gt.1.e20,-999.,tmp)
       tmp@_FillValue=-999.
       massL(ic)=dim_sum_n(dim_sum_n(tmp,0),0)
       y_all_masses(3,iy-1,m-1)=dim_sum_n(dim_sum_n(tmp,0),0)
       delete(tmp)
       ic=ic+1
    end do
    end do
;    print(massL)
    all_masses(3,:)=massL

;input file ocean
    infileO=getenv("infileO")
    gg=(/31,28,31,30,31,30,31,31,30,31,30,31/)
    ic=0
    do iy=1,nyears
    do m=1,12
       inpfile=infileO+sprinti("%0.4i",iy)+sprinti("%0.2i",m)+"01_"+sprinti("%0.4i",iy)+sprinti("%0.2i",m)+sprinti("%0.2i",gg(m-1))+"_scalar.nc"
       print(inpfile)
       fnemo=addfile(inpfile,"r")
       massO(ic)=fnemo->masso  ;kg
       y_all_masses(4,iy-1,m-1)=fnemo->masso
       ssh(ic)=fnemo->sshtot  ;m
       y_all_masses(0,iy-1,m-1)=fnemo->sshtot
       steric(ic)=fnemo->zostoga  ;m
       y_all_masses(1,iy-1,m-1)=fnemo->zostoga
       ic=ic+1
    end do
    end do
;    print(massO)
    all_masses(4,:)=massO

;input file sea-ice
    infileI=getenv("infileI")
    fcice=addfile(infileI+"0001-01.nc","r")
    areaI=fcice->tarea ; in m2
    ic=0
    do iy=1,nyears
    do m=1,12
       fcice=addfile(infileI+sprinti("%0.4i",iy)+"-"+sprinti("%0.2i",m)+".nc","r")
       hi=fcice->hi(0,:,:) ;m
       tmpi=hi*areaI*rhoi
       tmpi=where(tmpi.gt.1.e20,-999.,tmpi)
       tmpi@_FillValue=-999.
       hs=fcice->hs(0,:,:) ;m
       tmps=hs*areaI*rhos
       tmps=where(tmps.gt.1.e20,-999.,tmps)
       tmps@_FillValue=-999.
       massI(ic)=dim_sum_n(dim_sum_n(tmpi,0),0)+dim_sum_n(dim_sum_n(tmps,0),0)
       y_all_masses(5,iy-1,m-1)=dim_sum_n(dim_sum_n(tmpi,0),0)+dim_sum_n(dim_sum_n(tmps,0),0)
       delete(tmpi)
       delete(tmps)
       ic=ic+1
    end do
    end do
;    print(massI)
    all_masses(5,:)=massI

    all_masses(6,:)=massO+massL+massI+massA
    y_all_masses(6,:,:)=y_all_masses(2,:,:)+y_all_masses(3,:,:)+y_all_masses(4,:,:)+y_all_masses(5,:,:)
    all_masses(0,:)=ssh
    all_masses(1,:)=steric

    outfile="mass_check.nc"
    system("/bin/rm -f "+outfile)
    ncdf     = addfile(outfile,"c")
    ncdf->massA=precwat*areaA
    tmp=tws*areaL*rho
    tmp=where(tmp.gt.1.e20,-999.,tmp)
    tmp@_FillValue=-999.
    ncdf->massL=tmp
    delete(tmp)
    tmp=hi*areaI*rhoi
    tmp=where(tmp.gt.1.e20,-999.,tmp)
    tmp@_FillValue=-999.
    ncdf->massIice=tmp
    delete(tmp)
    tmp=hs*areaI*rhos
    tmp=where(tmp.gt.1.e20,-999.,tmp)
    tmp@_FillValue=-999.
    ncdf->massIsnow=tmp

    plots=new(7,graphic)
    wks = gsn_open_wks(pltype,pltname)
    res=True
    res@gsnDraw               = False
    res@gsnFrame              = False
    utitle=new(7,string)
    utitle(2)="Atmosphere"
    utitle(3)="Land"
    utitle(4)="Ocean"
    utitle(5)="Sea-Ice"
    utitle(6)="Total Earth"
    utitle(0)="Global average sea level change"
    utitle(1)="Global average steric sea level change"
    yaxis=new(7,string)
    yaxis(2:6)="total mass [kg]"
    yaxis(0:1)="[m]"
    do k=0,6
       res@tiYAxisString     = yaxis(k)
       res@gsnLeftString      = utitle(k)
       if(freq.eq."monthly")then
          res@trYMinF = (min(all_masses(k,:)))-dim_stddev_n(all_masses(k,:),0)
          res@trYMaxF = (max(all_masses(k,:)))+dim_stddev_n(all_masses(k,:),0)
          plots(k)=gsn_csm_y (wks,all_masses(k,:),res)
       else
          ymean=dim_avg_n(y_all_masses(k,:,:),1)
          res@trYMinF = (min(all_masses(k,:)))-dim_stddev_n(ymean,0)
          res@trYMaxF = (max(all_masses(k,:)))+dim_stddev_n(ymean,0)
          plots(k)=gsn_csm_y (wks,ymean,res)
       end if
    end do
    resP = True
    resP@gsnPanelXWhiteSpacePercent=5
;     resP@gsnPanelMainString = " "
     resP@gsnMaximize = True
;     resP@gsnFrame    = False
 ;resP@gsnPanelRight  = 0.98
;     resP@gsnPanelBottom = 0.045

     gsn_panel(wks,plots,(/4,2/),resP)  ; plots
end
