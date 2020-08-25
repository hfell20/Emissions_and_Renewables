clear
cd "Q:\My Drive\Energy Data\baa"
global path "Q:\My Drive\Energy Data"
global path_result "Q:\My Drive\Energy Data\results"


use "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"

keep if Region=="CAL"|Region=="SW"|Region=="NW"

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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade SW NW Region BalanceNGDTI BalanceTITrade BalanceNG TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade SW NW BalanceNGDTI BalanceTITrade BalanceNG TI, i(year month day hour) j(Region, string)

gen renEXT = solarNW+windNW+solarSW+windSW
gen loadEXT = loadNW+loadSW
gen solarEXT = solarNW+solarSW
gen windEXT = windNW+windSW

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarCA/loadCA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windCA/loadCA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeCA)/loadC
sum trade_load
scalar trade_mean = r(mean)

gen dcut = 0
replace dcut = 1 if year>2019
replace dcut = 1 if year==2019 & month>8

rename loadCAL loadHome
rename solarCAL	solarHome
rename windCAL windHome


gen d_exp_ngNW = loadNW+SumTradeNW-netgenNW
gen d_exp_ngSW = loadSW+SumTradeSW-netgenSW
gen d_exp_ngCA = loadHome+SumTradeCAL-netgenCAL

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

reg ngCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel replace ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg coalCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg hydroCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg nucCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg SumTradeCAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg TICAL loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

/*
reg ngCAL loadHome solarHome windHome  i.hour#i.dow i.month#i.year  if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California)

reg coalCAL loadHome solarHome windHome i.hour#i.dow i.month#i.year  if dcut==0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California)

reg hydroCAL loadHome solarHome windHome i.hour#i.dow i.month#i.year  if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California)

reg SumTradeCAL loadHome solarHome windHome i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California)
*/
reg so2CAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.hour#i.dow i.month#i.year if dcut==0 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg noxCAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)

reg co2CAL loadHome solarHome windHome loadEXT solarEXT windEXT  i.hour#i.dow i.month#i.year if dcut==0  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, California, Notes, Cut Weird Hydro Dates)



clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="CAR"|Region =="MIDA"|Region=="SE"|Region=="TEN"

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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI MIDA SE TEN




reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI MIDA SE TEN, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge
replace windMIDA = PJM_Wind
drop d1 d1utc

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
gen trade_load = abs(SumTradeCAR)/loadCAR
sum trade_load
scalar trade_mean = r(mean)

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

rename loadCAR loadHome
rename solarCAR solarHome	
rename windCAR	windHome
drop if windEXT==0

*drop if d1utc>1893452400000 & d1utc<1898812800000

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

sum nucCAR, detail
gen dnuc = (nucCAR<`=scalar(r(p10))')

reg ngCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg coalCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg hydroCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg nucCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg SumTradeCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)
reg TICAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

drop if so2CAR==0|noxCAR==0|co2CAR==0
reg so2CAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg noxCAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)

reg co2CAR loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CAR)




clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="FLA"|Region=="SE"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI , i(year month day hour) j(Region, string)

gen renEXT = solarSE+windSE
gen loadEXT = loadSE
gen solarEXT = solarSE
gen windEXT = windSE

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarFLA/loadFLA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windFLA/loadFLA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeFLA)/loadFLA
sum trade_load
scalar trade_mean = r(mean)

rename loadFLA loadHome
rename solarFLA solarHome	
rename windFLA	windHome
bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

reg ngFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg coalFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg hydroFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg nucFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg SumTradeFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
reg TIFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

/*
reg ngFLA loadHome solarHome windHome  i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg coalFLA loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg hydroFLA loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)

reg SumTradeFLA loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
*/
drop if so2FLA==0|noxFLA==0|co2FLA==0
reg so2FLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
reg noxFLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)
reg co2FLA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, FLA)



clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="CENT"|Region=="MIDW"|Region=="NW"|Region=="SW"|Region=="CAL"|Region=="TEX"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI CENT NW SW MIDW CAL TEX

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI NW SW MIDW CENT CAL TEX, i(year month day hour) j(Region, string)

gen renEXT = solarMIDW+windMIDW+solarNW+windNW+solarSW+windSW
gen loadEXT = loadMIDW+loadNW+loadSW
gen solarEXT = solarMIDW+solarNW+solarSW
gen windEXT = windMIDW+windNW+windSW

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarCENT/loadCENT
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windCENT/loadCENT
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeCENT)/loadCENT
sum trade_load
scalar trade_mean = r(mean)

rename loadCENT loadHome
rename solarCENT solarHome	
rename windCENT	windHome

drop if coalCENT==0|ngCENT==0
bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2



reg ngCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngCENT>0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg coalCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if coalCENT>0 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg hydroCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg nucCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg SumTradeCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if SumTradeCENT>-2000 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
reg TICENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if SumTradeCENT>-2000 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
/*
reg ngCENT loadHome solarHome windHome  i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg coalCENT loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg hydroCENT loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)

reg SumTradeCENT loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
*/
drop if so2CENT==0|noxCENT==0|co2CENT==0
reg so2CENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
reg noxCENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)
reg co2CENT loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, CENT)


foreach i in co2 nox so2 load solar wind {
    gen `i'NWSW = `i'NW+`i'SW+`i'CAL
	
}

foreach i in co2 so2 nox {
    reg `i'NWSW windHome loadHome windNWSW loadNWSW solarNWSW i.hour#i.dow i.month#i.year, r cl(wk_samp)
	outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle("`i'WEST") noast keep(loadHome solarHome windHome) addtext(Region, CENT)
reg `i'TEX windHome loadHome windTEX solarTEX loadTEX i.hour#i.dow i.month#i.year, r cl(wk_samp)
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle("`i'TEX") noast keep(loadHome solarHome windHome) addtext(Region, CENT)
	}




clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="MIDA"|Region=="MIDW"|Region=="CAR"|Region=="NY"|Region=="TEN"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI MIDW CAR NY TEN MIDA gencoal genng

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI MIDW CAR NY TEN MIDA gencoal genng, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge
replace windMIDA = PJM_Wind
drop d1 d1utc

gen renEXT = solarMIDW+windMIDW+solarCAR+windCAR+solarNY+windNY+solarTEN+windTEN
gen loadEXT = loadMIDW+loadCAR+loadCAR+loadNY+loadTEN
gen solarEXT = solarMIDW+solarCAR+solarNY+solarTEN
gen windEXT = windMIDW+windCAR+windNY+windTEN

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarMIDA/loadMIDA
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windMIDA/loadMIDA
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeMIDA)/loadMIDA
sum trade_load
scalar trade_mean = r(mean)

drop if ngMIDA==0|coalMIDA==0


rename loadMIDA loadHome
rename solarMIDA solarHome	
rename windMIDA	windHome

*drop if d1utc>1893452400000 & d1utc<1898812800000

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

sum nucMIDA, detail
gen dnuc = (nucMIDA<`=scalar(r(p10))')

gen doct = 0
replace doct = 1 if year==2020
replace doct = 1 if year==2019 & month>11
replace doct = 1 if year==2019 & month==11 & day==31 & hour>=5
gen TIMIDA_R = CARMIDA*(1-2*doct)+TENMIDA*(1-2*doct)+MIDWMIDA*(1-2*doct)+NYMIDA*(1-2*doct)
gen SumTrade_R = MIDACAR*-1+MIDATEN*-1+MIDAMIDW*-1+MIDANY*-1 


reg ngMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg coalMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg hydroMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg nucMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg SumTradeMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
reg TIMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg SumTradePJM loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(SumTradePJM) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg TIMIDA_R loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI_R) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)

reg SumTrade_R loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI_R) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)




drop if so2MIDA==0|noxMIDA==0|co2MIDA==0
reg so2MIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
reg noxMIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)
reg co2MIDA loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDA)


clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="MIDW"|Region=="MIDA"|Region=="CENT"|Region=="SE"|Region=="TEN"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI MIDW MIDA CENT SE TEN gencoal genng

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI MIDW MIDA CENT SE TEN gencoal genng, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge
replace windMIDA = PJM_Wind
drop d1 d1utc

gen renEXT = solarMIDA+windMIDA+solarCENT+windCENT+solarSE+windSE+solarTEN+windTEN
gen loadEXT = loadMIDA+loadCENT+loadSE+loadTEN
gen solarEXT = solarMIDA+solarCENT+solarSE+solarTEN
gen windEXT = windMIDA+windCENT+windSE+windTEN

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarMIDW/loadMIDW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windMIDW/loadMIDW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeMIDW)/loadMIDW
sum trade_load
scalar trade_mean = r(mean)

rename loadMIDW loadHome
rename solarMIDW solarHome	
rename windMIDW	windHome
drop if coalMIDW<=0|ngMIDA<=0
drop if windMIDA==0
*drop if d1utc>1893452400000 & d1utc<1898812800000

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

*drop if month==4 & year==2020



reg ngMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg coalMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg hydroMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg nucMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg oilMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(oil) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg SumTradeMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
reg TIMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
/*
reg ngMIDW loadHome solarHome windHome  i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg coalMIDW loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg hydroMIDW loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg oilMIDW loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(oil) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)

reg SumTradeMIDW loadHome solarHome windHome i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
*/
drop if so2MIDW==0|noxMIDW==0|co2MIDW==0
reg so2MIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
reg noxMIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)
reg co2MIDW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, MIDW)



clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="NE"|Region=="NY"



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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

gen renEXT = solarNY+windNY
gen loadEXT = loadNY
gen solarEXT = solarNY
gen windEXT = windNY

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNE/loadNE
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNE/loadNE
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeNE)/loadNE
sum trade_load
scalar trade_mean = r(mean)

rename loadNE loadHome
rename solarNE solarHome	
rename windNE	windHome
bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

sum nucNE, detail
gen dnuc = (nucNE<`=scalar(r(p10))')

reg ngNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg coalNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg hydroNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg nucNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)

reg SumTradeNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
reg TINE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
drop if so2NE==0|noxNE==0|co2NE==0
reg so2NE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
reg noxNE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)
reg co2NE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NE)



clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="NY"|Region=="MIDA"|Region=="NE"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge
replace windMIDA = PJM_Wind
drop d1 d1utc

gen renEXT = solarMIDA+windMIDA+solarNE+windNE
gen loadEXT = loadMIDA+loadNE
gen solarEXT = solarMIDA+solarNE
gen windEXT = windMIDA+windNE

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNY/loadNY
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNY/loadNY
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeNY)/loadNY
sum trade_load
scalar trade_mean = r(mean)

rename loadNY loadHome
rename solarNY solarHome	
rename windNY	windHome
drop if windMIDA==0|ngMIDA<=0|coalMIDA<=0
drop if loadHome<1000
*drop if d1utc>1893452400000 & d1utc<1898812800000

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

sum nucNY, detail
gen dnuc = (nucNY<`=scalar(r(p10))')

reg ngNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg coalNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg hydroNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg nucNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)

reg SumTradeNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
reg TINY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
drop if so2NY==0|noxNY==0|co2NY==0
reg so2NY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
reg noxNY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)
reg co2NY loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NY)



clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="NW"|Region=="CAL"|Region=="CENT"|Region=="SW"



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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade CAL SW Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2  CAL SW ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

gen renEXT = solarCAL+windCAL+solarCENT+windCENT+solarSW+windSW
gen loadEXT = loadCAL+loadCENT+loadSW
gen solarEXT = solarCAL+solarCENT+solarSW
gen windEXT = windCAL+windCENT+windSW

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarNW/loadNW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windNW/loadNW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeNW)/loadNW
sum trade_load
scalar trade_mean = r(mean)

rename loadNW loadHome
rename solarNW solarHome	
rename windNW	windHome
bysort year month day: egen sol_min_home = min(solarHome)

sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10

bysort year month day: egen sol_min_ext = min(solarEXT)
sum sol_min_ext, detail
scalar p99 = r(p99)
drop if sol_min_ext>`=scalar(p99)'*10

sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2


reg ngNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg coalNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg hydroNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg nucNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)

reg SumTradeNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
reg TINW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
drop if so2NW==0|noxNW==0|co2NW==0
reg so2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
reg noxNW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)
reg co2NW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, NW)




clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"
keep if Region=="MIDW"|Region=="CAR"|Region=="FLA"|Region=="SE"|Region=="TEN"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

gen renEXT = solarMIDW+windMIDW+solarCAR+windCAR+solarSE+windSE+solarTEN+windTEN+solarFLA+windFLA
gen loadEXT = loadMIDW+loadCAR+loadFLA+loadSE+loadTEN
gen solarEXT = solarMIDW+solarCAR+solarSE+solarTEN+solarFLA
gen windEXT = windMIDW+windCAR+windSE+windTEN+windFLA

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarSE/loadSE
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windSE/loadSE
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeSE)/loadSE
sum trade_load
scalar trade_mean = r(mean)

rename loadSE loadHome
rename solarSE solarHome	
rename windSE	windHome

gen dout = 0
replace dout =1 if so2SE>30000
replace dout = 1 if coalSE<200|ngSE<200
bysort year month day hour: egen sdout = sum(dout)

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10

bysort year month day: egen sol_min_ext = min(solarEXT)
sum sol_min_ext, detail
scalar p99 = r(p99)
drop if sol_min_ext>`=scalar(p99)'*10

sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

reg ngSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg coalSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg hydroSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg nucSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)

reg SumTradeSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
reg TISE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year   , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
drop if so2SE==0|noxSE==0|co2SE==0
reg so2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
reg noxSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)
reg co2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE)


reg ngSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if ngSE>200, cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)

reg coalSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if coalSE>200 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)

reg hydroSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year   , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)

reg nucSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year   , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)

reg SumTradeSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)
reg TISE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)

reg so2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if so2SE<25000 , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)
reg noxSE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)
reg co2SE loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SE, Notes, Take out low ng/coal & hi so2)



clear
cd "Q:\My Drive\Energy Data\baa"
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
load netgen SumTrade TI , i(year month day hour) j(Region, string)

gen renEXT = solarCAL+windCAL+solarNW+windNW
gen loadEXT = loadCAL+loadNW
gen solarEXT = solarCAL+solarNW
gen windEXT = windCAL+windNW

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

merge 1:1 year month day hour using "$path\BAA Files\SW_noWALC.dta"

gen sol_demand = solarSWa/loadSW
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windSWa/loadSW
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeSW)/loadSW
sum trade_load
scalar trade_mean = r(mean)

rename loadSW loadHome
rename solarSWa solarHome	
rename windSWa	windHome



gen dcut = 0
drop if hydroSW>2000 | hydroSW<-1000
drop if ngSW==0|coalSW==0

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10

bysort year month day: egen sol_min_ext = min(solarEXT)
sum sol_min_ext, detail
scalar p99 = r(p99)
drop if sol_min_ext>`=scalar(p99)'*10

sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2

sum nucSW, detail
gen dnuc=(nucSW<`=scalar(r(p10))')

reg ngSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,  Notes,No WALC)

reg coalSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW,  Notes,No WALC)

reg hydroSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg nucSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)

reg SumTradeSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg TISW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
drop if so2SW==0|noxSW==0|co2SW==0
reg so2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg noxSW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)
reg co2SW loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, SW)






clear
cd "Q:\My Drive\Energy Data\baa"
use  "Q:\My Drive\Energy Data\baa\Region_data.dta"
keep if Region=="TEX"|Region=="CENT"


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

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade Region TI

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI, i(year month day hour) j(Region, string)

gen renEXT = solarCENT+windCENT
gen loadEXT = loadCENT
gen solarEXT = solarCENT
gen windEXT = windCENT

gen d1 = mdy(month,day,year)
gen d1utc = dhms(d1,hour,0,0)
tsset d1utc
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

gen sol_demand = solarTEX/loadTEX
sum sol_demand
scalar sol_mean = r(mean)
gen wind_demand = windTEX/loadTEX
sum wind_demand
scalar wind_mean = r(mean)
gen trade_load = abs(SumTradeTEX)/loadTEX
sum trade_load
scalar trade_mean = r(mean)

rename loadTEX loadHome
rename solarTEX solarHome	
rename windTEX	windHome

bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
drop if sol_min_home>`=scalar(p99)'*10

bysort year month day: egen sol_min_ext = min(solarEXT)
sum sol_min_ext, detail
scalar p99 = r(p99)
drop if sol_min_ext>`=scalar(p99)'*10

sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum solarEXT, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum loadEXT, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum windEXT, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

drop if loadHome>`=scalar(p99_lh)'*10
drop if loadHome<`=scalar(p1_lh)'/2
drop if solarHome>`=scalar(p99_sh)'*10
drop if solarHome<`=scalar(p1_sh)'/2
drop if windHome>`=scalar(p99_wh)'*10
drop if windHome<`=scalar(p1_wh)'/2
drop if loadEXT>`=scalar(p99_le)'*10
drop if loadEXT<`=scalar(p1_le)'/2
drop if solarEXT>`=scalar(p99_se)'*10
drop if solarEXT<`=scalar(p1_se)'/2
drop if windEXT>`=scalar(p99_we)'*10
drop if windEXT<`=scalar(p1_we)'/2
reg ngTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year, cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg coalTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year if coalTEX>100 , cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg hydroTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(hydro) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg nucTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nuc) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg SumTradeTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(Net Exp) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
reg TITEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(TI) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
drop if so2TEX==0|noxTEX==0|co2TEX==0
reg so2TEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(so2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
reg noxTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(nox) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)
reg co2TEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year  , cl(wk_samp) r  
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(co2) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX)

reg ngTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year, cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(ng) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX, Notes, Remove if ng<100)

reg coalTEX loadHome solarHome windHome loadEXT solarEXT windEXT i.hour#i.dow i.month#i.year, cl(wk_samp) r
outreg2 using "$path_result\Regional_analysis_PJMWIND", excel append ctitle(coal) noast keep(loadHome solarHome windHome loadEXT solarEXT windEXT)  addstat("% Solar",`=scalar(sol_mean)',"% Wind",`=scalar(wind_mean)',"% Trade",`=scalar(trade_mean)') addtext(Region, TEX, Notes, Remove if coal<100)
