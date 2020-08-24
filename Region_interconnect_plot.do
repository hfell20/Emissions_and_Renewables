clear
cd "Q:\My Drive\Energy Data\baa"
global path "Q:\My Drive\Energy Data"
global path_result "Q:\My Drive\Energy Data\results"
use "Q:\My Drive\Energy Data\baa\Region_data_clean.dta"


drop if Region=="TEX"

gen double d1utc = dofc(UTCTime)
gen double utc_ceil = ceil(UTCTime)
gen hour = hh(utc_ceil)
gen year = year(d1utc)
gen month = month(d1utc)
gen day = day(d1utc)



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
rename so2_masslbs so2
rename nox_masslbs nox
rename co2_mass co2

replace coal = 0 if coal==.
replace hydro = 0 if hydro==.
replace solar = 0 if solar==.
replace ng = 0 if ng==.
replace wind = 0 if wind==.
replace load = 0 if load==.
replace so2=0 if so2==.
replace nox = 0 if nox==.
replace co2=0 if co2==.
replace nuc = 0 if nuc==.

keep year month day hour coal nuc oil hydro solar ng wind other unk so2 nox co2 ///
load netgen SumTrade TI CAR CENT FLA MIDA MIDW NE NY SE TEN CAN NW SW CAL Region gencoal genng genpetrol

reshape wide coal nuc oil hydro solar ng wind other unk so2 nox co2 gencoal genng genpetrol ///
load netgen SumTrade TI CAR CENT FLA MIDA MIDW NE NY SE TEN CAN NW SW CAL, i(year month day hour) j(Region, string)

merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Trade.dta"
drop _merge
merge 1:1 year month day hour using "Q:\My Drive\Energy Data\baa\PJM_Wind.dta"
drop _merge
replace windMIDA = PJM_Wind
drop d1 d1utc
replace coalNY = gencoalNY

global east "CAR CENT FLA MIDA MIDW NE NY SE TEN"


gen dcut = 0
gen east_so2 = 0
gen east_nox = 0
gen east_co2 = 0
gen east_coal = 0
gen east_ng = 0
gen east_hydro = 0
gen east_wind = 0
gen east_solar = 0
gen east_load = 0
gen east_nuc = 0
gen d1 = mdy(month, day,year)
gen dow = dow(d1)
gen wk = week(d1)
egen wk_samp = group(wk year)

foreach i in CAR CENT FLA MIDA MIDW NE NY SE TEN {
 

replace east_so2 = so2`i'+east_so2
replace east_nox = nox`i'+east_nox
replace east_co2 = co2`i'+east_co2
replace east_coal = coal`i'+east_coal
replace east_ng = ng`i'+east_ng
replace east_hydro = hydro`i'+east_hydro
replace east_wind = wind`i'+east_wind
replace east_solar = solar`i'+east_solar
replace east_load = east_load+load`i'
replace east_nuc = east_nuc+nuc`i'
}
drop if east_solar>20000
drop if east_nox==0

gen other_so2 = 0
gen other_nox = 0
gen other_co2 = 0
gen other_coal = 0
gen other_ng = 0
gen other_hydro = 0
gen other_wind = 0
gen other_solar = 0
gen other_load = 0
gen other_nuc = 0
gen windHome = 0
gen solarHome = 0
gen loadHome = 0
gen d1utc = dhms(d1,hour,0,0)
gen ddrop = 0
gen sol_min_home = 0
foreach i in CAR CENT FLA MIDA MIDW NE NY SE TEN {

replace other_so2 = east_so2-so2`i'
replace other_nox = east_nox-nox`i'
replace other_co2 = east_co2-co2`i'
replace other_coal = east_coal - coal`i'
replace other_ng = east_ng - ng`i'
replace other_hydro = east_hydro - hydro`i'
replace other_wind = east_wind-wind`i'
replace other_solar = east_solar-solar`i'
replace other_load = east_load-load`i'
replace other_nuc = east_nuc-nuc`i'
replace windHome = wind`i'
replace solarHome = solar`i'
replace loadHome = load`i'

replace ddrop = 0
replace ddrop = 1 if (coal`i'==0|ng`i'==0)
drop sol_min_home
bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
replace ddrop = 1 if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum other_solar, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum other_load, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum other_wind, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

replace ddrop=1 if loadHome>`=scalar(p99_lh)'*10
replace ddrop=1 if loadHome<`=scalar(p1_lh)'/2
replace ddrop=1 if solarHome>`=scalar(p99_sh)'*10
replace ddrop=1 if solarHome<`=scalar(p1_sh)'/2
replace ddrop=1 if windHome>`=scalar(p99_wh)'*10
replace ddrop=1 if windHome<`=scalar(p1_wh)'/2
replace ddrop=1 if other_load>`=scalar(p99_le)'*10
replace ddrop=1 if other_load<`=scalar(p1_le)'/2
replace ddrop=1 if other_solar>`=scalar(p99_se)'*10
replace ddrop=1 if other_solar<`=scalar(p1_se)'/2
replace ddrop=1 if other_wind>`=scalar(p99_we)'*10
replace ddrop=1 if other_wind<`=scalar(p1_we)'/2

replace ddrop = 0 if "`i'"=="TEN"
reg other_ng hydro`i' nuc`i'  loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0, cl(wk_samp) r
estimates store ng`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(ng) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

reg other_coal hydro`i' nuc`i'   loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0 , cl(wk_samp) r
estimates store coal`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(coal) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

reg other_hydro hydro`i' nuc`i'   loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0 , cl(wk_samp) r
estimates store hydro`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(hydro) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

reg other_so2 hydro`i' nuc`i' loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0 , cl(wk_samp) r
estimates store so2`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(so2) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

reg other_nox hydro`i' nuc`i'   loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0 , cl(wk_samp) r
estimates store nox`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(nox) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

reg other_co2 hydro`i' nuc`i'  loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if ddrop==0  , cl(wk_samp) r
estimates store co2`i'
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(co2) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')
}


gen west_so2 = 0
gen west_nox = 0
gen west_co2 = 0
gen west_coal = 0
gen west_ng = 0
gen west_hydro = 0
gen west_wind = 0
gen west_solar = 0
gen west_load = 0

merge 1:1 year month day hour using "$path\BAA files\SW_noWALC.dta"

local west "NW SW CAL"

replace coalSW = gencoalSW
replace ngSW = genngSW
replace windSW = windSWa
replace solarSW = solarSWa

foreach i in NW SW CAL {
replace west_so2 = so2`i'+west_so2
replace west_nox = nox`i'+west_nox
replace west_co2 = co2`i'+west_co2
replace west_coal = coal`i'+west_coal
replace west_ng = ng`i'+west_ng
replace west_hydro = hydro`i'+west_hydro
replace west_wind = wind`i'+west_wind
replace west_solar = solar`i'+west_solar
replace west_load = west_load+load`i'
}



foreach i in NW SW CAL {

replace other_so2 = west_so2-so2`i'
replace other_nox = west_nox-nox`i'
replace other_co2 = west_co2-co2`i'
replace other_coal = west_coal - coal`i'
replace other_ng = west_ng - ng`i'
replace other_hydro = west_hydro - hydro`i'
replace other_wind = west_wind-wind`i'
replace other_solar = west_solar-solar`i'
replace other_load = west_load-load`i'
replace windHome = wind`i'
replace solarHome = solar`i'
replace loadHome = load`i'

replace ddrop = 0
replace ddrop = 1 if (coal`i'==0|ng`i'==0)
drop sol_min_home
bysort year month day: egen sol_min_home = min(solarHome)
sum sol_min_home, detail
scalar p99 = r(p99)
replace ddrop = 1 if sol_min_home>`=scalar(p99)'*10
sum loadHome, detail
scalar p1_lh = r(p1)
scalar p99_lh = r(p99)
sum solarHome, detail
scalar p1_sh = r(p1)
scalar p99_sh = r(p99)
sum windHome, detail
scalar p1_wh = r(p1)
scalar p99_wh = r(p99)
sum other_solar, detail
scalar p1_se = r(p1)
scalar p99_se = r(p99)
sum other_load, detail
scalar p1_le = r(p1)
scalar p99_le = r(p99)
sum other_wind, detail
scalar p1_we = r(p1)
scalar p99_we = r(p99)

replace ddrop=1 if loadHome>`=scalar(p99_lh)'*10
replace ddrop=1 if loadHome<`=scalar(p1_lh)'/2
replace ddrop=1 if solarHome>`=scalar(p99_sh)'*10
replace ddrop=1 if solarHome<`=scalar(p1_sh)'/2
replace ddrop=1 if windHome>`=scalar(p99_wh)'*10
replace ddrop=1 if windHome<`=scalar(p1_wh)'/2
replace ddrop=1 if other_load>`=scalar(p99_le)'*10
replace ddrop=1 if other_load<`=scalar(p1_le)'/2
replace ddrop=1 if other_solar>`=scalar(p99_se)'*10
replace ddrop=1 if other_solar<`=scalar(p1_se)'/2
replace ddrop=1 if other_wind>`=scalar(p99_we)'*10
replace ddrop=1 if other_wind<`=scalar(p1_we)'/2

reg other_ng loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(ng) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')
estimates store ng`i'

reg other_coal loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(coal) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')
estimates store coal`i'


if "`i'" != "CAL" {
replace dcut = 1 if year>2019
replace dcut = 1 if year==2019 & month>8
}
reg other_hydro loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(hydro) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')
estimates store hydro`i'

replace dcut = 0
reg other_so2 loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(so2) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

estimates store so2`i'

reg other_nox loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(nox) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

estimates store nox`i'

reg other_co2 loadHome solarHome windHome other_load other_solar other_wind i.hour#i.dow i.month#i.year if dcut==0 & ddrop==0 , cl(wk_samp) r
outreg2 using "$path_result\InterConnect.xls", excel append ci ctitle(co2) noast keep(loadHome solarHome windHome)  addtext(Reg, `i')

estimates store co2`i'
}

coefplot (so2CAL, label("CAL")) || so2CENT || so2MIDA || so2MIDW || so2NE || so2NW ||  so2NY || so2SE || so2SW || so2TEX, keep(windHome) title(SO2) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CEN" 3 "MIDA" 4 "MIDW" 5 "NE" 6 "NW" 7 "NY" 8 "SW" 9 "TEX" ) saving(so2_wind.gph, replace)
coefplot (noxCAL, label("CAL")) || noxCENT || noxMIDA || noxMIDW || noxNE || noxNW ||  noxNY || noxSE || noxSW || noxTEX, keep(windHome) title(NOx) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CEN" 3 "MIDA" 4 "MIDW" 5 "NE" 6 "NW" 7 "NY" 8 "SW" 9 "TEX" ) saving(nox_wind.gph, replace)
coefplot (co2CAL, label("CAL")) || co2CENT || co2MIDA || co2MIDW || co2NE || co2NW ||  co2NY || co2SE || co2SW || co2TEX, keep(windHome) title(CO2) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CEN" 3 "MIDA" 4 "MIDW" 5 "NE" 6 "NW" 7 "NY" 8 "SW" 9 "TEX" ) saving(co2_wind.gph, replace)
graph combine so2_wind.gph nox_wind.gph co2_wind.gph, xcommon row(1) saving(wind_emiss_ic.gph, replace)
 graph export "Q:\My Drive\Energy Data\results\figures\wind_emiss_ic.pdf", as(pdf) replace


coefplot (so2CAL, label("CAL")) || (so2CAR, label("CAR")) || so2FLA || so2NW || so2SE || so2SW || so2TEX, keep(solarHome) title(SO2) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CAR" 3 "FLA" 4 "NW" 5 "SE" 6 "SW" 7 "TEX" ) saving(so2_solar.gph, replace)
coefplot (noxCAL, label("CAL")) || (noxCAR, label("CAR")) || noxFLA || noxNW || noxSE || noxSW || noxTEX, keep(solarHome) title(NOx) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CAR" 3 "FLA" 4 "NW" 5 "SE" 6 "SW" 7 "TEX" ) saving(nox_solar.gph, replace)
coefplot (co2CAL, label("CAL")) || (co2CAR, label("CAR")) || co2FLA || co2NW || co2SE || co2SW || co2TEX, keep(solarHome) title(CO2) xline(0) horizontal bycoefs ylabel(1 "CAL" 2 "CAR" 3 "FLA" 4 "NW" 5 "SE" 6 "SW" 7 "TEX" ) saving(co2_solar.gph, replace)

graph combine so2_solar.gph nox_solar.gph co2_solar.gph, xcommon row(1) saving(solar_emiss_ic.gph, replace)
 graph export "Q:\My Drive\Energy Data\results\figures\solar_emiss_ic.pdf", as(pdf) replace

