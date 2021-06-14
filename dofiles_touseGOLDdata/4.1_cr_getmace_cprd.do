/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					12/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			Raw Clinical & Referral data extracts from CPRDFast

NEXT STEPS:				4.2_cr_getmace_hes

==============================================================================*/

*****************************************
***MAJOR ADVERSE CARDIOVASCULAR EVENTS***
*****************************************

///
***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\MACE_Gold_Jul19.dta", keep(match) nogen

*DROP DUPLICATES & RECORDS BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)
 
keep patid eventdate mace mi angina acs hf stroke tia
duplicates drop

tempfile mace
save `mace'

///
***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\MACE_Gold_Jul19.dta", keep(match) nogen

*DROP DUPLICATES & RECORDS BEYOND STUDY PERIOD END
drop if eventdate>d(31aug2018)

keep patid eventdate mace mi angina acs hf stroke tia
duplicates drop

///
***COMBINE CLINICAL & REFERRAL
append using `mace'

*DROP DUPLCATES FROM COMBINED FILE
duplicates drop

*CREATE EARLIEST DATES
gen stroketia_cprd=1 if stroke==1 | tia==1
gen macesevere_cprd=1 if mi==1 | hf==1 | stroke==1

foreach var of varlist mace mi angina acs hf stroke tia {
	rename `var' `var'_cprd
	}
	
foreach var of varlist mace_cprd mi_cprd angina_cprd acs_cprd hf_cprd stroke_cprd tia_cprd stroketia_cprd macesevere_cprd {	
	sort patid eventdate
	by patid: egen `var'date=min(eventdate) if `var'==1
	sort patid `var'date
	by patid: replace `var'date=`var'date[1]
	format `var'date %td
	} 

foreach var of varlist mace_cprd mi_cprd angina_cprd acs_cprd hf_cprd stroke_cprd tia_cprd stroketia_cprd macesevere_cprd {
	sort patid `var'
	by patid: replace `var'=`var'[1]
	}
	
drop eventdate
duplicates drop

///
***SAVE MASTER COPY OF ALL MATCHES	
save "$datadir\mace_cprd.dta", replace
