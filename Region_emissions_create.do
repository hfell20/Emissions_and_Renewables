cd "Q:\My Drive\Energy Data"
clear
use BAA_emissions

merge m:1 baa using baa_region.dta
drop if _merge==2
drop _merge

collapse (sum) so2_masslbs nox_masslbs co2_masstons, by(Region d1utc y_utc m_utc wk_utc day_utc hour_utc)

replace d1utc = d1utc+3600000

gen d1 = dofc(d1utc)
gen year = year(d1)
gen month  = month(d1)
gen day = day(d1)
gen hour = hh(d1utc)

*rename y_utc year
*rename m_utc month
*rename day_utc day
*rename hour_utc hour

replace Region = "CAL" if Region=="California"
replace Region = "CAR" if Region=="Carolinas"
replace Region = "CENT" if Region=="Central"
replace Region = "FLA" if Region=="Florida"
replace Region = "MIDA" if Region=="Mid-Atlantic"
replace Region = "MIDW" if Region=="Midwest"
replace Region = "NE" if Region=="New England"
replace Region = "NY" if Region=="New York"
replace Region = "SW" if Region=="Southwest"
replace Region = "NW" if Region=="Northwest"
replace Region = "SE" if Region=="Southeast"
replace Region = "TEN" if Region=="Tennessee"
replace Region = "TEX" if Region=="Texas"

save Region_emissions.dta, replace
