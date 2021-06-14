/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			HES extract sent by CPRD

NEXT STEPS:				4.3_cr_getmace_combined

==============================================================================*/

*****************************************
***MAJOR ADVERSE CARDIOVASCULAR EVENTS***
*****************************************

use "$datadir\hes_epi.dta"
rename icd code
merge m:1 code using "$codelistdir\MACE_HES.dta", keep(match) nogen

*DROP DUPLCATES & RECORDS BEYOND STUDY PERIOD END
drop if epistart>d(31aug2018)

keep patid epistart mi_hes angina_hes acs_hes hf_hes stroke_hes tia_hes ali_hes mace_hes macesevere_hes stroketia_hes
duplicates drop

sort patid epistart


*CREATE EARLIEST DATES PER MACE TYPE
foreach var of varlist mace_hes mi_hes angina_hes acs_hes hf_hes stroke_hes tia_hes ali_hes stroketia_hes macesevere_hes {
	sort patid epistart
	by patid: egen `var'date=min(epistart) if `var'==1
	sort patid `var'date
	by patid: replace `var'date=`var'date[1]
	format `var'date %td
	} 

foreach var of varlist mace_hes mi_hes angina_hes acs_hes hf_hes stroke_hes tia_hes ali_hes stroketia_hes macesevere_hes {
	sort patid `var'
	by patid: replace `var'=`var'[1]
	}
	
drop epistart
duplicates drop

///
***SAVE MASTER COPY OF ALL MATCHES	
save "$datadir\mace_hes.dta", replace
