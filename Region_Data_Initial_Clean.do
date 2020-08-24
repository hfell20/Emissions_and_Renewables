clear
cd "Q:\My Drive\Energy Data\baa"
global path "Q:\My Drive\Energy Data"
global path_result "Q:\My Drive\Energy Data\results"
use "Q:\My Drive\Energy Data\baa\Region_data.dta"
local reg_list "CAL CAR CENT FLA MIDA MIDW NE NW NY SE SW TEN TEX"
gen double utc_ceil1 = ceil(UTCTime)
gen d1 = dofc(utc_ceil1)
gen renew = NGSUN+NGWND
bysort Region: egen wmean = mean(NGNG)
foreach i in `reg_list' {
sum utc_ceil1 if SumNG!=. & SumNG>0 & Region=="`i'"
drop if utc_ceil1<`=scalar(r(min))' & Region=="`i'"
sum utc_ceil1 if Region=="`i'" & renew>0
drop if utc_ceil1<`=scalar(r(min))' & Region=="`i'"
sum wmean if Region=="`i'"
*if `=scalar(r(mean))'>0 {
*sum d1 if NGNG==0 & Region=="`i'"
*drop if d1>=`=r(min)' & d1<=`=r(max)'
*}
}


save "Q:\My Drive\Energy Data\baa\Region_data_clean.dta", replace