begin
    pltype="png"
    pltname="steric_effect_historical_CMCC-CM2.SR5"

;

;input file ocean
    inpfile="zostoga_Omon_CMCC-CM2-SR5_historical_r1i1p1f1_gn_185001-201412.nc"
    fnemo=addfile(inpfile,"r")
    steric=fnemo->zostoga  ;m
    time=fnemo->time  ;m
    yrfrac= cd_calendar(time,4)
    print(yrfrac)

    wks = gsn_open_wks(pltype,pltname)
    res=True
;    utitle(2)="Atmosphere"
;       res@tiYAxisString     = yaxis(k)
       res@tiMainString      = "CMCC-CM2 SR5 historical"
;          res@trYMinF = (min(all_masses(k,:)))-dim_stddev_n(all_masses(k,:),0)
;          res@trYMaxF = (max(all_masses(k,:)))+dim_stddev_n(all_masses(k,:),0)
    plots=gsn_csm_xy (wks,yrfrac,steric,res)
end
