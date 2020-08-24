cd "Q:\My Drive\Energy Data\baa\"

import excel "Region_CAL.xlsx", sheet("Published Hourly Data") firstrow clear
save Region_data.dta, replace

import excel "Region_TEX.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_TEN.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_SW.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_SE.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_NW.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_NY.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_NE.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_MIDW.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_MIDA.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_CENT.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace

import excel "Region_CAR.xlsx", sheet("Published Hourly Data") firstrow clear
append using Region_data.dta
save Region_data.dta, replace
