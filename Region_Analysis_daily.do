clear
cd "Q:\My Drive\Energy Data\baa"
global path "Q:\My Drive\Energy Data"
global path_result "Q:\My Drive\Energy Data\results"
use Region_data_clean.dta
keep if Region=="CAL"|Region=="SW"|Region=="NW"

gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*8
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge



rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2


collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, i(year month day) j(Region, string)

gen renEXT = solarNW+windNW+solarSW+windSW
gen loadEXT = loadNW+loadSW
gen solarEXT = solarNW+solarSW
gen windEXT = windNW+windSW

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarCA/loadCA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windCA/loadCA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TICA)/loadC
sum trade_load
scalar trade_mean = r(mean)

gen dcut = 0
replace dcut = 1 if year>2019
replace dcut = 1 if year==2019 & month>8

rename loadCAL loadHome
rename solarCAL	solarHome
rename windCAL windHome

keep  if (solarHome!=0|windHome!=0)
drop if solarHome>200000
drop if loadHome<500000
drop if so2CAL==0|co2CAL==0|noxCAL==0




reg ngCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel replace ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)

reg coalCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)

reg hydroCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)

reg TICAL loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)


reg so2CAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)

reg noxCAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)

reg co2CAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cutting weird hydro)



clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="CAR"|Region =="MIDA"|Region=="SE"|Region=="TEN"

gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*5
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2



collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 


drop if Region==""

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDA+windMIDA+solarSE+windSE+solarTEN+windTEN
gen loadEXT = loadMIDA+loadSE+loadTEN
gen solarEXT = solarMIDA+solarSE+solarTEN
gen windEXT = windMIDA+windSE+windTEN


gen sol_demand = solarCAR/loadCAR
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windCAR/loadCAR
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TICAR)/loadCAR
sum trade_load
scalar trade_mean = r(mean)

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

rename loadCAR loadHome
rename solarCAR solarHome	
rename windCAR	windHome
keep  if (solarHome!=0|windHome!=0)
drop if windEXT==0
drop if solarEXT>40000
drop if loadEXT<2000000
drop if loadHome<400000
drop if solarHome<1000
drop if noxCAR==0|co2CAR==0|so2CAR==0
*drop if d1>21915 & d1<21975
*replace loadHome = loadHome-nucCAR
*replace loadEXT = loadEXT-nucSE-nucMIDA-nucTEN

reg ngCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year, cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg coalCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg hydroCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg TICAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
/*
reg ngCAR loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg coalCAR loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg hydroCAR loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg TICAR loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
*/
reg so2CAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year   , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg noxCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg co2CAR loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)


clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="FLA"|Region=="SE"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarSE+windSE
gen loadEXT = loadSE
gen solarEXT = solarSE
gen windEXT = windSE

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarFLA/loadFLA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windFLA/loadFLA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TIFLA)/loadFLA
sum trade_load
scalar trade_mean = r(mean)

rename loadFLA loadHome
rename solarFLA solarHome	
rename windFLA	windHome
keep  if (solarHome!=0|windHome!=0)
drop if loadEXT<200000
drop if loadHome<400000
drop if co2FLA==0|noxFLA==0|so2FLA==0



reg ngFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg coalFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg hydroFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg TIFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

/*
reg ngFLA loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg coalFLA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg hydroFLA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg TIFLA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
*/
reg so2FLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
reg noxFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
reg co2FLA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)



clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="CENT"|Region=="MIDW"|Region=="NW"|Region=="SW"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDW+windMIDW+solarNW+windNW+solarSW+windSW
gen loadEXT = loadMIDW+loadNW+loadSW
gen solarEXT = solarMIDW+solarNW+solarSW
gen windEXT = windMIDW+windNW+windSW

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarCENT/loadCENT
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windCENT/loadCENT
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TICENT)/loadCENT
sum trade_load
scalar trade_mean = r(mean)

rename loadCENT loadHome
rename solarCENT solarHome	
rename windCENT	windHome
keep  if (solarHome!=0|windHome!=0)


reg ngCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg coalCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg hydroCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg TICENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
/*
reg ngCENT loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg coalCENT loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg hydroCENT loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg TICENT loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
*/
reg so2CENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
reg noxCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
reg co2CENT loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)





clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="MIDA"|Region=="MIDW"|Region=="CAR"|Region=="NY"|Region=="TEN"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=8
drop if year==2018 & month==9 & day<20

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDW+windMIDW+solarCAR+windCAR+solarNY+windNY+solarTEN+windTEN
gen loadEXT = loadMIDW+loadCAR+loadCAR+loadNY+loadTEN
gen solarEXT = solarMIDW+solarCAR+solarNY+solarTEN
gen windEXT = windMIDW+windCAR+windNY+windTEN

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarMIDA/loadMIDA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windMIDA/loadMIDA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TIMIDA)/loadMIDA
sum trade_load
scalar trade_mean = r(mean)

rename loadMIDA loadHome
rename solarMIDA solarHome	
rename windMIDA	windHome
keep  if (solarHome!=0|windHome!=0)
drop if solarEXT>40000
drop if so2MIDA==0|co2MIDA==0|noxMIDA==0
drop if d1>21915 & d1<21975





reg ngMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg coalMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg hydroMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg TIMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
/*
reg ngMIDA loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg coalMIDA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg hydroMIDA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg TIMIDA loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
*/
reg so2MIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
reg noxMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
reg co2MIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)


clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="MIDW"|Region=="MIDA"|Region=="CENT"|Region=="SE"|Region=="TEN"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDA+windMIDA+solarCENT+windCENT+solarSE+windSE+solarTEN+windTEN
gen loadEXT = loadMIDA+loadCENT+loadSE+loadTEN
gen solarEXT = solarMIDA+solarCENT+solarSE+solarTEN
gen windEXT = windMIDA+windCENT+windSE+windTEN

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarMIDW/loadMIDW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windMIDW/loadMIDW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TIMIDW)/loadMIDW
sum trade_load
scalar trade_mean = r(mean)

rename loadMIDW loadHome
rename solarMIDW solarHome	
rename windMIDW	windHome
keep  if (solarHome!=0|windHome!=0)
drop if windMIDA==0
*drop if d1>21915 & d1<21975
drop if so2MIDW==0|co2MIDW==0|noxMIDW==0
*drop if month==4 & year==2020


reg ngMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg coalMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg hydroMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg oilMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(oil) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg TIMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
/*
reg ngMIDW loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg coalMIDW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg hydroMIDW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg oilMIDW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(oil) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg TIMIDW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
*/
reg so2MIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
reg noxMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
reg co2MIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)



clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="NE"|Region=="NY"



gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarNY+windNY
gen loadEXT = loadNY
gen solarEXT = solarNY
gen windEXT = windNY

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNE/loadNE
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNE/loadNE
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TINE)/loadNE
sum trade_load
scalar trade_mean = r(mean)

rename loadNE loadHome
rename solarNE solarHome	
rename windNE	windHome
keep  if (solarHome!=0|windHome!=0)
drop if so2NE==0|co2NE==0|noxNE==0


reg ngNE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg coalNE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg hydroNE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg TINE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
/*
reg ngNE loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg coalNE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg hydroNE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg TINE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
*/
reg so2NE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
reg noxNE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
reg co2NE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)



clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="NY"|Region=="MIDA"|Region=="NE"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

merge 1:1 Region year month day hour using "$path\Region_cems_gen.dta"
drop if _merge==2
drop _merge

rename gencoal coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDA+windMIDA+solarNE+windNE
gen loadEXT = loadMIDA+loadNE
gen solarEXT = solarMIDA+solarNE
gen windEXT = windMIDA+windNE

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNY/loadNY
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNY/loadNY
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TINY)/loadNY
sum trade_load
scalar trade_mean = r(mean)

rename loadNY loadHome
rename solarNY solarHome	
rename windNY	windHome
keep  if (solarHome!=0|windHome!=0)
drop if so2NY==0|noxNY==0|co2NY==0
drop if windMIDA==0
drop if d1>21915 & d1<21975

reg ngNY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg coalNY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg hydroNY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg TINY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg so2NY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
reg noxNY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
reg co2NY loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)


clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="NW"|Region=="CAL"|Region=="CENT"|Region=="SW"



gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2   ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarCAL+windCAL+solarCENT+windCENT+solarSW+windSW
gen loadEXT = loadCAL+loadCENT+loadSW
gen solarEXT = solarCAL+solarCENT+solarSW
gen windEXT = windCAL+windCENT+windSW

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNW/loadNW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNW/loadNW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TINW)/loadNW
sum trade_load
scalar trade_mean = r(mean)

rename loadNW loadHome
rename solarNW solarHome	
rename windNW	windHome
keep  if (solarHome!=0|windHome!=0)
drop if noxNW==0|co2NW==0|so2NW==0
drop if solarEXT>200000


reg ngNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg coalNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg hydroNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg TINW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg so2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
reg noxNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
reg co2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

/*
reg ngNW loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg coalNW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg hydroNW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg TINW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
*/
/*
reg ngNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17   , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW, Notes,LowCorr Hrs)

reg coalNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW, Notes,LowCorr Hrs)

reg hydroNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW, Notes,LowCorr Hrs)

reg TINW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW, Notes,LowCorr Hrs)

reg so2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
reg noxNW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
reg co2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if hour>=17  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
*/


clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="MIDW"|Region=="CAR"|Region=="FLA"|Region=="SE"|Region=="TEN"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarMIDW+windMIDW+solarCAR+windCAR+solarSE+windSE+solarTEN+windTEN+solarFLA+windFLA
gen loadEXT = loadMIDW+loadCAR+loadFLA+loadSE+loadTEN
gen solarEXT = solarMIDW+solarCAR+solarSE+solarTEN+solarFLA
gen windEXT = windMIDW+windCAR+windSE+windTEN+windFLA

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarSE/loadSE
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windSE/loadSE
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TISE)/loadSE
sum trade_load
scalar trade_mean = r(mean)

rename loadSE loadHome
rename solarSE solarHome	
rename windSE	windHome
keep  if (solarHome!=0|windHome!=0)
drop if so2SE==0|noxSE==0|co2SE==0


reg ngSE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg coalSE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg hydroSE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg TISE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

/*
reg ngSE loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg coalSE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg hydroSE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg TISE loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
*/
reg so2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
reg noxSE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
reg co2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)




clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="SW"|Region=="CAL"|Region=="NW"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*7
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

merge 1:1 Region year month day hour using "$path\Region_cems_gen.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI genng gencoal, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI genng gencoal, i(year month day) j(Region, string)

gen renEXT = solarCAL+windCAL+solarNW+windNW
gen loadEXT = loadCAL+loadNW
gen solarEXT = solarCAL+solarNW
gen windEXT = windCAL+windNW

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarSW/loadSW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windSW/loadSW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TISW)/loadSW
sum trade_load
scalar trade_mean = r(mean)



merge 1:1 year month day using "$path\BAA Files\SW_noWALC_daily.dta"
replace solarSW= solarSWa
replace windSW= windSWa
replace coalSW = gencoalSW
replace ngSW = genngSW

rename loadSW loadHome
rename solarSW solarHome	
rename windSW	windHome
keep  if (solarHome!=0|windHome!=0)

gen dcut = 0
*replace dcut = 1 if year==2018 & month<12
*replace dcut = 1 if year==2018 & month==12 & day<8
drop if so2SW==0|noxSW==0|co2SW==0
drop if solarEXT>200000

reg ngSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg coalSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg hydroSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg TISW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg so2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg noxSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg co2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

/*
reg ngSW loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg coalSW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg hydroSW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg TISW loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
*/
reg ngSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW, Notes, After Coal Closure)

reg coalSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)

reg hydroSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)

reg TISW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)

reg so2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)
reg noxSW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)
reg co2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,Notes, After Coal Closure)

/*
reg ngSW loadHome solarHome windHome  i.dow i.month#i.year if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg coalSW loadHome solarHome windHome i.dow i.month#i.year if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg hydroSW loadHome solarHome windHome i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg TISW loadHome solarHome windHome i.dow i.month#i.year if dcut==0, cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
*/





clear
cd "Q:\My Drive\Energy Data\baa"
use Region_data_clean.dta
keep if Region=="TEX"|Region=="CENT"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
replace utc_ceil = utc_ceil-3600000*6
replace d1utc = dofc(utc_ceil)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if year<2018
drop if year==2018 & month<=6
drop if year==2018 & month==7 & day<17

merge 1:1 Region year month day hour using "$path\Region_emissions.dta"
drop if _merge==2
drop _merge

rename NGCOL coal
rename NGNUC nuc
rename NGOIL oil
rename NGWAT hydro
rename NGSUN solar
rename NGNG ng
rename NGWND wind
rename NGOTH other
rename NGUNK unk
rename D load
rename SumNG netgen

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace solar = 0 if solar==.
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

collapse (sum) coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI, by (Region year month day) 

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen TI , i(year month day) j(Region, string)

gen renEXT = solarCENT+windCENT
gen loadEXT = loadCENT
gen solarEXT = solarCENT
gen windEXT = windCENT

gen d1 = mdy(month,day,year)

tsset d1
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarTEX/loadTEX
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windTEX/loadTEX
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(TITEX)/loadTEX
sum trade_load
scalar trade_mean = r(mean)

rename loadTEX loadHome
rename solarTEX solarHome	
rename windTEX	windHome
keep  if (solarHome!=0|windHome!=0)
drop if so2TEX==0|noxTEX==0|co2TEX==0


reg ngTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg coalTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg hydroTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg TITEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg so2TEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
reg noxTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
reg co2TEX loadHome solarHome windHome loadEXT solarEXT windEXT i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

/*
reg ngTEX loadHome solarHome windHome  i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg coalTEX loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg hydroTEX loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg TITEX loadHome solarHome windHome i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_daily.xls", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

