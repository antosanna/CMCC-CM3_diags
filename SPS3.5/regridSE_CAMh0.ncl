;***************************************************************
; NCL script
; regrid 6hr vars from ne60np4 to reg1x1
; for masked variables define and apply the mask after interpolation
;***************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  srcFileName   = getenv("srcFileName") 
;"/work/csp/ar26521/CESM/archive/SPS3.5_2000_continuous/atm/hist/SPS3.5_2000_continuous.cam.h0.2045-02.nc"
  auxFileName   = srcFileName
  repogrid="/work/csp/as34319/regridSE_SPS3.5"
  srcGridName="/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/srcGrd_ne60.nc"
; --- Define grid
  outputgrid="reg1x1"
  dstGridName="/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/dstGrd_reg1x1.nc"
  wgtFileName="/work/csp/sp1/CESMDATAROOT/CMCC-SPS3.5/regrid_files/CAMSE05_2_reg1x1.nc"
;  lsmFileName=repogrid+"/lsm_sps3.5_cam_h1_reg1x1_0.5_359.5.nc"
;  wgtFileName   = getenv("wgtFileName")
;  srcGridName   = getenv("srcGridName")
;  dstGridName   = getenv("dstGridName")

; output required precision
  C3S_type="double"

  print("Beginning to regrid "+srcFileName)


; 0. Set the source/destination file names, 
;    open the source file for reading, 
;    create a destination file for regridded data.
;------------------------------------------------

  print(" ")
  print("Regridding: ")
  print("SRC:"+srcFileName)
  src_file=addfile(srcFileName,"r")
  aux_file=addfile(auxFileName,"r")

;
; 1. Generate a description file for the source grid (SE).
;---------------------------------------------------
  if(isfilepresent(srcGridName)) then
      print("Found srcGrid description "+srcGridName)
  else
      print("Creating srcGrid description "+srcGridName)
      Opt               =True
      Opt@ForceOverWrite=True
      Opt@Title         ="SE Grid"  
      Opt@Debug         =False ; True
      Opt@PrintTimings  =False ; True
      unstructured_to_ESMF(srcGridName,src_file->lat,src_file->lon,Opt)
      delete(Opt)
  end if

;
; 2. Generate a description file for the destination grid.
;-----------------------------------------------------
  if(isfilepresent(dstGridName)) then
      print("Found dstGrid description "+dstGridName)
  else
      print("Creating dstGrid description "+dstGridName)
      if(outputgrid.eq."reg1x1") then
        Opt                = True
        Opt@LLCorner       = (/-89.5,0.5 /)
        Opt@URCorner       = (/ 89.5, 359.5 /)
        Opt@ForceOverwrite = True
        Opt@PrintTimings   = True
        Opt@Title          = "World grid 1.x1. degree resolution"

        latlon_to_SCRIP(dstGridName,"1deg",Opt)

;---Clean up
        delete(Opt)
      else
        Opt               =True
        Opt@ForceOverWrite=True
        Opt@Debug         =False ; True
        Opt@PrintTimings  =False ; True
        lats              =latGlobeF(ny,"lat","latitude" ,"degrees_north")
        lons              =lonGlobeF(nx,"lon","longitude","degrees_east" )
        rectilinear_to_SCRIP(dstGridName,lats,lons,Opt)
        delete(lats)
        delete(lons)
        delete(Opt)
    end if
  end if

;
; 3. Generate the weights file, using the source and 
;    destination files created in #1 and #2.
;-----------------------------------------------------
  if(isfilepresent(wgtFileName)) then
      print("Found WeightFile "+wgtFileName)
  else
      print("Creating WeightFile "+wgtFileName)
      Opt               = True
      Opt@InterpMethod  ="bilinear" ; "patch", "conserve"
      Opt@ForceOverWrite=True
      Opt@SrcESMF       =True   
      Opt@Debug         =False ; True
      Opt@PrintTimings  =False ; True
      ESMF_regrid_gen_weights(srcGridName,dstGridName,wgtFileName,Opt)
      delete(Opt)
  end if

;---Read from the weight file the method used to derive the remap weights
  wgt_file       = addfile(wgtFileName, "r")
  dst_grid_dims  = wgt_file->dst_grid_dims
  dst_mlon       = dst_grid_dims(0)
  dst_nlat       = dst_grid_dims(1)
  dst_lat        = wgt_file->yc_b(::dst_mlon)
  dst_lon        = wgt_file->xc_b(:dst_mlon-1)


;---Use the destination grid info on the weight file to create lat/lon
  lat       = dst_lat                  ; get from weight file
  lat!0     = "lat"
  lat@units = "degrees_north"
  lat@units = "degrees_north" ;
  lat@long_name = "latitude" ;
  lat@standard_name = "latitude" ;
  lat@axis = "Y" ;
  lat@valid_min = -90. ;
  lat@valid_max = 90. ;
  lat&lat   =  lat
  nlat      = dimsizes(lat)            ; same as dst_nlat

  lon       = dst_lon
  lon!0     = "lon"
  lon&lon   =  lon
  lon@units = "degrees_east" ;
  lon@long_name = "longitude" ;
  lon@standard_name = "longitude" ;
  lon@axis = "X" ;
  lon@valid_min = 0. ;
  lon@valid_max = 360. ;
  mlon      = dimsizes(lon)            ; same as dst_mlon

  Opt_RGRD  = True

;===================================================================
; get the coordinate dimension names and their sizes
;===================================================================
  dNames   = getvardims(src_file)       ; get level info from source file
  dSizes   = getfiledimsizes(src_file)
  it       = ind(dNames.eq."time")
;_________________________________________
; other needed vars for vinth2p_ecmwf
; PHIS,PS,hyam,hybm,P0mb=1000
;_________________________________________
  var3d=0
; =====================================================================
; Define input var list and output var and realm list 
; =====================================================================

;  varin=(/"T","Z3","Q","U","V","OMEGA","PSL","CLDTOT","TS","TREFHT","FSNS","PRECC","PRECL"/)
  varin=getenv("varmod") ;"TREFHT"
  if ( varin.eq."T".or.varin.eq."Z3".or.varin.eq."Q".or.varin.eq."U".or.varin.eq."V".or.varin.eq."OMEGA") then
     var3d=1
     ia       = ind(dNames.eq."lev" )   ; # of levels
     klev     = dSizes(ia)
     PHIS= ESMF_regrid_with_weights(src_file->PHIS,wgtFileName,Opt_RGRD)
     PSFC= ESMF_regrid_with_weights(src_file->PS,wgtFileName,Opt_RGRD)
     hyam= aux_file->hyam
     hybm= aux_file->hybm
     P0mb=1000.
     intyp=2   ;log interp
     kxtrp = True                          ; True=extrapolate
     tbot=ESMF_regrid_with_weights(src_file->T(:,klev-1,:),wgtFileName,Opt_RGRD)
     nt     = dSizes(it)
     time=src_file->time
     time@long_name = "Verification time of the forecast" ;
     time@standard_name = "time" ;
     varflg=0
     if( varin.eq."T") then
        varflg=1
     end if
     if( varin.eq."Z3") then
        varflg= -1
     end if
   end if
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                    PREDEFINE MODE
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    

  if (var3d.eq.1)then
     plev       = toint(getenv("plev"))
  else
     plev=0     
  end if
  print(" ")


  if (var3d.eq.1)then
        var1x1= ESMF_regrid_with_weights(src_file->$varin$,wgtFileName,Opt_RGRD)
        var = (/ vinth2p_ecmwf(var1x1, hyam,hybm,plev,PSFC, intyp, P0mb,1,kxtrp,varflg,tbot,PHIS) /)
  else
        var = ESMF_regrid_with_weights(src_file->$varin$,wgtFileName,Opt_RGRD)
  end if
  outfile=getenv("outfile")
  if(isfilepresent(outfile)) then
     system("rm "+outfile)
  end if
  outf=addfile(outfile,"c")
  outf->$varin$=var
  outf->lon=lon
  outf->lat=lat
  outf->time=time

end
