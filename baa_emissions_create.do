cd "Q:\My Drive\Energy Data"
clear
use BAA_emissions.dta

replace d1utc = d1utc+3600000

gen d1 = dofc(d1utc)
gen year = year(d1)
gen month  = month(d1)
gen day = day(d1)
gen hour = hh(d1utc)
keep baa so2_masslbs nox_masslbs co2_masstons year month day hour
save "Q:\My Drive\Energy Data\BAA files\baa_emissions.dta", replace
