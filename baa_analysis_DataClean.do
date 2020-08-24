cd "Q:\My Drive\Energy Data\BAA files"
global path "Q:\My Drive\Energy Data\results"
use baa_data.dta,clear

local home "AECI"
local baas "AECI MISO SWPP SPA"

keep if baa=="AECI"|baa=="MISO"|baa=="SWPP"|baa=="SPA"

drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)
gen wind_ext = windMISO+windSWPP+windSPA
gen solar_ext = solarMISO+solarSWPP+solarSPA
gen load_ext = loadMISO+loadSWPP+loadSPA
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)




gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if windSWPP==0 & ng_home!=.
bysort year month day: egen min_sol = min(solar_ext)
drop if min_sol>50


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}

sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel replace noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*AVA
local home "AVA"
local baas "AVA GCPD IPCO PACW CHPD NWMT"
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="AVA"|baa=="GCPD"|baa=="IPCO"|baa=="PACW"|baa=="CHPD"|baa=="NWMT"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)
gen wind_ext = windGCPD+windIPCO+windPACW+windCHPD+windNWMT
gen solar_ext = solarGCPD+solarIPCO+solarPACW+solarCHPD+solarNWMT
gen load_ext = loadGCPD+loadIPCO+loadPACW+loadCHPD+loadNWMT
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen gtot=0
gen ltot = 0
scalar dmin = 0
foreach i in `baas' {
replace gtot = wind`i'+solar`i'
sum gtot
scalar gm = r(mean)
replace ltot = load`i'
sum ltot
scalar lm = r(mean)
if gm>0 {
sum d1 if gtot>0 & d1<21300
scalar dmin = max(dmin,r(min))
}
if lm>0 {
sum d1 if ltot>0 & d1<21300
scalar dmin = max(dmin,r(min))
}
}
keep if d1>`=scalar(dmin)'

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if solar_ext>650 & ng_home!=.
drop if load_ext<4000
bysort year month day: egen sum_sol = sum(solar_home)
drop if sum_sol==1
drop if solar_home>25


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

**********************************************************
*AZPS
local home "AZPS"
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="AZPS"|baa=="PNM"|baa=="WACM"|baa=="SRP"|baa=="WALC"|baa=="LDWP"|baa=="CISO"|baa=="PACE"|baa=="TEPC"|baa=="IID"
local exts "PNM WACM SRP WALC LDWP CISO PACE TEPC IID"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if solar_home>800
drop if load_home>8000|load_home<1000
drop if load_ext<20000


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 & `=scalar(r(mean))'>0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*BANC
use baa_data.dta,clear
local home "BANC"
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="BANC"|baa=="BPAT"|baa=="CISO"|baa=="TIDC"
local exts "BPAT CISO TIDC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
bysort year month day: egen min_sol = min(solar_ext)
drop if min_sol>2000
drop if load_home<1000
drop if load_ext<20000
gen ng_hydro = ng_home+hydro_home
drop if ng_hydro==0




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean)
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*BPAT
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="BPAT"|baa=="PSEI"|baa=="AVA"|baa=="AVRN"|baa=="CISO"|baa=="GCPD"|baa=="PGE"|baa=="DOPD"|baa=="PACW"|baa=="CHPD"|baa=="SCL"|baa=="TPWR"|baa=="LDWP"|baa=="NEVP"|baa=="NWMT"|baa=="BANC"|baa=="GRID"

local home "BPAT"
local exts "PSEI AVA AVRN CISO GCPD PGE DOPD PACW CHPD SCL TPWR LDWP NEVP NWMT BANC GRID"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if load_ext<30000
drop if wind_home>2800
drop if load_home<1000
drop if hydro_home<1000


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean)
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*CISO
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="CISO"|baa=="AZPS"|baa=="SRP"|baa=="WALC"|baa=="BPAT"|baa=="PACW"|baa=="LDWP"|baa=="NEVP"|baa=="CFE"|baa=="TIDC"|baa=="BANC"|baa=="IID"

local home "CISO"
local exts "AZPS SRP WALC BPAT PACW LDWP NEVP TIDC BANC IID"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if wind_ext>4000
drop if solar_ext>4000
drop if load_ext<4000
drop if hydro_home==.


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*CPLE
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="CPLE"|baa=="DUK"|baa=="PJM"|baa=="SC"|baa=="SCEG"|baa=="YAD"
local home "CPLE"
local exts "DUK PJM SC SCEG YAD"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if load_home<4000
drop if wind_ext==0 & ng_home!=.
drop if load_ext<50000|load_ext>200000
bysort d1: egen sol_sum = sum(solarPJM)
drop if sol_sum==0 & ng_home!=.



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************



**********************************************************
*DUK
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="CPLW"|baa=="DUK"|baa=="PJM"|baa=="SOCO"|baa=="SCEG"|baa=="CPLE"|baa=="SC"|baa=="SEPA"|baa=="TVA"|baa=="YAD"
local home "DUK"
local exts "PJM SOCO SCEG CPLE SC SEPA TVA YAD"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if solar_ext>1000
drop if load_home<5000
drop if load_ext<5000
drop if hydro_home==.




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

**********************************************************
*EPE
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="EPE"|baa=="SWPP"|baa=="PNM"|baa=="TEPC"
local home "EPE"
local exts "SWPP PNM TEPC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
bysort year month day: egen sol_min = min(solar_ext)
drop if sol_min>50
drop if windSWPP==0 & ng_home!=.
drop if load_home<500
drop if load_ext<500
drop if ng_home>1500



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*ERCOT
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="ERCO"|baa=="SWPP"|baa=="CEN"|baa=="CFE"
local home "ERCO"
local exts "SWPP"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if windSWPP==0 & ng_home!=.
drop if ng_home<1000 & ng_home!=.
drop if load_home<2000



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*FMPP
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="FMPP"|baa=="FPC"|baa=="FPL"|baa=="JEA"|baa=="TEC"
local home "FMPP"
local exts "FPC FPL JEA TEC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if solar_home>30
drop if load_home<1000|load_home>4000
drop if load_ext<10000
drop if solar_ext>2630
drop if coal_home>3000



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*FPC
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="FPC"|baa=="SOCO"|baa=="FPL"|baa=="TAL"|baa=="FMPP"|baa=="SEC"|baa=="GVL"|baa=="NSB"
local home "FPC"
local exts "SOCO FPL TAL FMPP SEC GVL NSB"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if load_home<100
drop if load_ext<20000
drop if ng_home<2000





sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


**********************************************************
*FPL
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="FPC"|baa=="SOCO"|baa=="FPL"|baa=="JEA"|baa=="TEC"|baa=="SEC"|baa=="GVL"|baa=="NSB"|baa=="FMPP"|baa=="HST"
local home "FPL"
local exts "FPC SOCO JEA TEC SEC GVL NSB FMPP HST"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
drop if solar_home>2000
drop if solar_ext>2500
drop if load_home<5000
drop if load_ext<20000



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}

outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

**********************************************************
*IID
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="IID"|baa=="AZPS"|baa=="WALC"|baa=="CISO"
local home "IID"
local exts "AZPS WALC CISO"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5

drop if solar_home>300
drop if load_home<100


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*IPCO
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="IPCO"|baa=="AVA"|baa=="PACE"|baa=="PACW"|baa=="NEVP"|baa=="NWMT"
local home "IPCO"
local exts "AVA PACE PACW NEVP NWMT"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5

drop if load_home<1000
drop if load_ext<1000
drop if hydro_home>2000




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*ISNE
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="ISNE"|baa=="NYIS"|baa=="HQT"|baa=="NBSO"
local home "ISNE"
local exts "NYIS"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home!=. ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*LDWP
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="LDWP"|baa=="AZPS"|baa=="WALC"|baa=="BPAT"|baa=="CISO"|baa=="PACE"
local home "LDWP"
local exts "AZPS WALC BPAT CISO PACE"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*MISO
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="MISO"|baa=="AECI"|baa=="SWPP"|baa=="SPA"|baa=="LGEE"|baa=="EEI"|baa=="PJM"|baa=="SOCO"|baa=="AEC"|baa=="TVA"|baa=="IESO"|baa=="MHEB"
local home "MISO"
local exts "AECI SWPP SPA LGEE EEI PJM SOCO AEC TVA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'

gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*NEVP
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="NEVP"|baa=="WALC"|baa=="CISO"|baa=="IPCO"|baa=="PACE"|baa=="LDWP"
local home "NEVP"
local exts "WALC CISO IPCO PACE LDWP"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'

gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if wind_home>200
drop if solar_ext>1500
tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph 


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*NWMT
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="NWMT"|baa=="WAUW"|baa=="BPAT"|baa=="AESO"|baa=="GWA"|baa=="WWA"
local home "NWMT"
local exts " BPAT GWA WWA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if load_home<900

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*PACE
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PACE"|baa=="WACM"|baa=="AZPS"|baa=="LDWP"|baa=="NEVP"|baa=="NWMT"
local home "PACE"
local exts "WACM AZPS LDWP NEVP NWMT"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if solar_home==0 & load_home>0
tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph
drop if coal_home>10000
drop if hydro_home<-200


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*PACW
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PACW"|baa=="BPAT"|baa=="AVA"|baa=="CISO"|baa=="GCPD"|baa=="IPCO"|baa=="PACE"|baa=="PGE"
local home "PACW"
local exts "BPAT AVA CISO GCPD IPCO PACE PGE"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph

drop if load_ext<25000
drop if solar_ext>1400
drop if load_home<1000

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*PJM
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PJM"|baa=="MISO"|baa=="LGEE"|baa=="CPLW"|baa=="DUK"|baa=="CPLE"|baa=="TVA"|baa=="NYIS"
local home "PJM"
local exts "MISO LGEE CPLW DUK CPLE TVA NYIS"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa MISO LGEE CPLW DUK CPLE TVA NYIS PJM
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2 MISO LGEE CPLW DUK CPLE TVA NYIS PJM, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*PNM
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PNM"|baa=="SWPP"|baa=="EPE"|baa=="PSCO"|baa=="WACM"|baa=="AZPS"|baa=="TEPC"
local home "PNM"
local exts "SWPP EPE PSCO WACM AZPS TEPC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph

drop if windSWPP==0 & ng_home!=.

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*PSCO
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PSCO"|baa=="SWPP"|baa=="PNM"|baa=="WACM"
local home "PSCO"
local exts "SWPP PNM WACM"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if min_sol>100
drop if windSWPP==0 & ng_home!=.

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
scalar sl = r(mean) 
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if hydro_home>30 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*PSEI
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="PSEI"|baa=="BPAT"|baa=="CHPD"|baa=="SCL"|baa=="TPWR"
local home "PSEI"
local exts "BPAT CHPD SCL TPWR"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*SCEG
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="SCEG"|baa=="DUK"|baa=="SOCO"|baa=="CPLE"|baa=="SC"|baa=="SEPA"
local home "SCEG"
local exts "DUK SOCO CPLE SC SEPA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph

drop if load_ext<25000

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
**********************************************************************
*SC
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="SCEG"|baa=="DUK"|baa=="SOCO"|baa=="CPLE"|baa=="SC"|baa=="SEPA"
local home "SC"
local exts "DUK SOCO CPLE SCEG SEPA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph

drop if load_ext<25000

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph
drop if ti_home<500


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************

*********************************************************
*SOCO
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="SOCO"|baa=="MISO"|baa=="DUK"|baa=="FPC"|baa=="FPL"|baa=="SC"|baa=="SEPA"|baa=="SCEG"|baa=="AEC"|baa=="TAL"|baa=="TVA"
local home "SOCO"
local exts "MISO DUK FPC FPL SC SEPA SCEG AEC TAL TVA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph
drop if ti_home<-10000


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*SRP
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="SRP"|baa=="AZPS"|baa=="WALC"|baa=="CISO"|baa=="TEPC"|baa=="DEAA"|baa=="HGMA"
local home "SRP"
local exts "AZPS WALC CISO TEPC DEAA HGMA"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph
drop if ti_home<0


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*SWPP
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="SWPP"|baa=="MISO"|baa=="EPE"|baa=="ERCO"|baa=="PNM"|baa=="PSCO"|baa=="SPA"|baa=="SPC"|baa=="WACM"|baa=="WAUW"
local home "SWPP"
local exts "MISO EPE ERCO PNM PSCO SPA  WACM "

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*TAL
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="TAL"|baa=="SOCO"|baa=="FPC"
local home "TAL"
local exts "SOCO FPC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
replace hydro_home=.
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5

bysort year month day: egen min_sol = min(solar_ext) if ng_home!=.
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*TEC
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="TEC"|baa=="FPC"|baa=="FPL"|baa=="FMPP"|baa=="SEC"
local home "TEC"
local exts "FPC FPL FMPP SEC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if solar_ext>2000

tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

*********************************************************
*TEPC
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="TEPC"|baa=="EPE"|baa=="PNM"|baa=="AZPS"|baa=="SRP"|baa=="WALC"
local home "TEPC"
local exts "EPE PNM AZPS SRP WALC"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph



sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*WACM
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="WACM"|baa=="SWPP"|baa=="PNM"|baa=="PSCO"|baa=="WAUW"|baa=="AZPS"|baa=="WALC"|baa=="PACE"
local home "WACM"
local exts "SWPP PNM PSCO  AZPS WALC PACE"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'


gen double d1h = dhms(d1,hour,0,0)
tsset d1h
sum load_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_ext< (`=scalar(outl)')/1.5
scalar outl = r(p99)
drop if load_ext> (`=scalar(outl)')*1.5
sum load_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p1)
drop if load_home< (`=scalar(outl)')/2
scalar outl = r(p99)
drop if load_home> (`=scalar(outl)')*1.5
sum solar_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_home> (`=scalar(outl)')*1.5
sum solar_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if solar_ext> (`=scalar(outl)')*1.5
sum ng_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if ng_home> (`=scalar(outl)')*1.5
sum hydro_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if hydro_home> (`=scalar(outl)')*1.5
sum wind_home if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_home>(`=scalar(outl)')*1.5
sum wind_ext if ng_home!=.|coal_home!=.|hydro_home!=., detail
scalar outl = r(p99)
drop if wind_ext>(`=scalar(outl)')*1.5
bysort year month day: egen min_sol = min(solar_ext)
sum min_sol, detail
scalar outl = r(p99)
drop if min_sol>(`=scalar(outl)')*1.5
tsline load_ext, saving(load_ext,replace)
tsline solar_ext, saving(solar_ext,replace)
tsline wind_ext, saving(wind_ext,replace)
tsline load_home, saving(load_home,replace)
tsline solar_home, saving(solar_home,replace)
tsline wind_home, saving(wind_home,replace)
graph combine load_ext.gph solar_ext.gph wind_ext.gph load_home.gph solar_home.gph wind_home.gph
drop if windSWPP==0 & ng_home!=.


tsline ng_home, saving(ng_home, replace)
tsline coal_home, saving(coal_home, replace)
tsline hydro_home, saving(hydro_home, replace)
tsline ti_home, saving(ti_home, replace)
graph combine ng_home.gph coal_home.gph hydro_home.gph ti_home.gph


sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
*gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


*********************************************************
*WALC
use baa_data.dta,clear
drop Localdate Hour Localtime Timezone Generationonly DF D NG TI ImputedD ImputedNG ImputedTI NGCOL NGNG NGNUC NGOIL NGWAT NGSUN NGWND NGOTH NGUNK ImputedCOLGen ImputedNGGen ImputedNUCGen ImputedOILGen ImputedWATGen ImputedSUNGen ImputedWNDGen ImputedOTHGen ImputedUNKGen ///
AdjustedOTHGen SubregionCOAS SubregionEAST SubregionFWES SubregionNRTH SubregionNCEN SubregionSOUT SubregionSCEN SubregionWEST  Subregion0001 Subregion0004 SubregionPGAE SubregionSDGE SubregionSCE SubregionVEA  Subregion0006 Subregion0027 Subregion0035 Subregion8910 Subregion4004 Subregion4001 Subregion4002 Subregion4008 Subregion4005 Subregion4006 Subregion4003 Subregion4007   AdjustedUNKGen SubregionAP SubregionAEP SubregionATSI SubregionAE SubregionBC SubregionCE SubregionDAY SubregionDPL SubregionDOM SubregionDEOK SubregionDUQ SubregionEKPC SubregionJC SubregionME SubregionPE SubregionPN SubregionPL SubregionPEP SubregionPS SubregionRECO  SubregionFrep SubregionJica SubregionKAFB SubregionKCEC SubregionLAC SubregionNTUA SubregionPNM SubregionTSGT  SubregionCSWS SubregionSPRM SubregionEDE SubregionGRDA SubregionINDN SubregionMPS SubregionKACY SubregionKCPL SubregionLES SubregionNPPD SubregionOKGE SubregionOPPD SubregionSPS SubregionSECI SubregionWR SubregionWAUE SubregionWFEC 

keep if baa=="WALC"|baa=="WACM"|baa=="AZPS"|baa=="SRP"|baa=="LDWP"|baa=="NEVP"|baa=="IID"|baa=="GRIF"

local home "WALC"
local exts "WACM AZPS SRP LDWP NEVP IID GRIF"

rename AdjustedSUNGen solar
rename AdjustedWNDGen wind

rename AdjustedCOLGen coal
rename AdjustedNGGen ng
rename AdjustedNUCGen nuc
rename AdjustedOILGen oil
rename AdjustedWATGen hydro
rename AdjustedTI ti
rename AdjustedD load

merge 1:1 baa year month day hour using baa_emissions.dta
drop if _merge==2
drop _merge
 
bysort baa: egen msol = mean(solar)
bysort baa: egen mwind = mean(wind)
bysort baa: egen outl = mean(load)

replace wind = 0 if wind==.
replace solar = 0 if solar==.
replace load = 0 if load==.

keep baa load ti coal ng nuc oil hydro solar wind hour year month day so2_masslbs nox_masslbs co2_masstons baa
rename so2 so2
rename co2 co2
rename nox nox
reshape wide load ti coal ng nuc oil hydro solar wind so2 nox co2, i(year month day hour) j(baa,string)

gen wind_ext = 0
gen solar_ext = 0
gen load_ext = 0

foreach x of local exts {  
replace wind_ext = wind_ext+wind`x'
replace solar_ext = solar_ext+solar`x'
replace load_ext = load_ext+load`x'
}
gen d1 = mdy(month,day,year)
gen wk = week(d1)
egen wk_samp = group(wk year)
gen dow = dow(d1)

gen load_home = load`home'
gen wind_home = wind`home'
gen solar_home = solar`home'
gen coal_home = coal`home'
gen ng_home = ng`home'
gen hydro_home = hydro`home'
gen ti_home = ti`home'
gen co2_home = co2`home'
gen so2_home = so2`home'
gen nox_home = nox`home'




sum ng_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg ng_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year  if ng_home>0,  cl(wk_samp) r
sum solar_home if e(sample)
scalar sm = r(mean)
sum wind_home if e(sample)
scalar wm = r(mean)
sum load_home if e(sample)
scalar lm = r(mean)
bysort year month day: egen wd = sum(wind_home)
bysort year month day: egen ld = sum(load_home)
gen wl = wd/ld
sum wl if e(sample)
scalar wl = r(mean)
bysort year month day: egen sd = sum(solar_home)
gen sl = sd/ld
sum sl if e(sample)
scalar sl = r(mean)
gen sl_day = solar_home/load_home if solar_home>0 & e(sample)
sum sl_day if e(sample)
scalar sl_day = r(mean) 
scalar rho =0
if `=scalar(sl)'>0 {
corr solar_home solar_ext if solar_home>0 & e(sample)
scalar rho = r(rho)
}
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ng) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home', ///
Avg. Hourly Solar,`=scalar(sm)', Avg. Hourly Wind, `=scalar(wm)', Avg. Hourly Load,`=scalar(lm)',Avg Daily W/L,`=scalar(wl)', Avg Daily S/L,`=scalar(sl)', ///
Avg S/L if S>0, `=scalar(sl_day)', Solar Corr, `=scalar(rho)')
}
sum coal_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg coal_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if coal_home>0 ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(coal) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}
sum hydro_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg hydro_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year   ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(hydro) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum ti_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
gen renew = solar_home+wind_home
gen double d1h = dhms(d1,hour,0,0)
tsset d1h
gen drenew = renew-renew[_n-1]
sum d1 if drenew!=0 & drenew!=.
scalar dmin =r(min)
reg ti_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)'  ,  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(ti) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum so2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg so2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(so2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}

sum nox_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg nox_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(nox) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}


sum co2_home if year>=2018
if `=scalar(r(N))'>0 & `=scalar(r(mean))'!=0 {
reg co2_home load_home wind_home solar_home wind_ext solar_ext load_ext  i.hour#i.dow i.month#i.year if d1>=`=scalar(dmin)',  cl(wk_samp) r
outreg2 using "$path\baa_results_061220.xls", excel append noas ctitle(co2) keep(load_home wind_home solar_home wind_ext solar_ext load_ext)  addtext(BAA ID, `home')
}




























