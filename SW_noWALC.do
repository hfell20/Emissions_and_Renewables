clear
cd "Q:\My Drive\Energy Data\baa"
global pathW "Q:\My Drive\Energy Data\BAA files"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="SW"|Region=="CAL"|Region=="NW"


gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)

drop if SumNG==.|SumNG==0

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
rename genng ng
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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "$pathW\WALC_data.dta"

replace coalSW = coalSW-coalW
replace nucSW = nucSW-nucW
replace ngSW = ngSW-ngW
replace hydroSW = hydroSW-hydroW
replace solarSW = solarSW-solarW
replace windSW = windSW-windW
replace loadSW = loadSW-loadW
replace so2SW = so2SW-so2W
replace co2SW = co2SW-co2W
replace noxSW = noxSW-noxW
replace TISW = TISW-TI_out


gen renEXT = solarCAL+windCAL+solarNW+windNW
gen loadEXT = loadCAL+loadNW
gen solarEXT = solarCAL+solarNW
gen windEXT = windCAL+windNW

gen d1 = mdy(month,day,year)
gen double d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarSW/loadSW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windSW/loadSW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeSW)/loadSW
sum trade_load
scalar trade_mean = r(mean)

rename loadSW loadHome
rename solarSW solarHome	
rename windSW	windHome




reg ngSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r
outreg2 using "$path_result\SW_noWALC", excel replace ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg coalSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if coalSW>0  , cl(wk_samp) r
outreg2 using "$path_result\SW_noWALC", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg hydroSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg nucSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg SumTradeSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg TISW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg so2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg noxSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  if ngSW>0, cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg co2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSW>0 , cl(wk_samp) r  
outreg2 using "$path_result\SW_noWALC", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

keep year month day hour loadHome TISW nucSW hydroSW solarHome windHome  so2SW noxSW co2SW coalSW ngSW
rename loadHome loadSWa
rename TISW TISWa
rename hydroSW hydroSWa
rename windHome windSWa
rename solarHome solarSWa
rename so2SW so2SWa
rename noxSW noxSWa
rename co2SW co2SWa
rename coalSW coalSWa
rename ngSW ngSWa
save "$pathW\SW_noWALC.dta", replace
