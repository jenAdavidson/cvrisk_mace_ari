/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				KidneyDisease_Aurum_Mar20.dta

NEXT STEPS:				2.16_cr_getdiabetesexclusion.do

==============================================================================*/


***********************************************
***APPLY EXCLUSIONS - CHRONIC KIDNEY DISEASE***
***********************************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\KidneyDisease_Aurum_Mar20.dta", keep(match) nogen
	
	*DROP DATA & VARIABLES NOT NEEDED
	drop if ckd_1_2==1 // this is only for covariate analysis
	drop ckd_1_2 ckd_3_5 ckd_4_5 dialysis 
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen kidneyfludate=min(obsdate) 
	format kidneyfludate %td
	by patid: egen kidneyppvdate=min(obsdate) if kidney_ppv==1
	format kidneyppvdate %td
	drop if kidneyfludate>d(31aug2018)
	replace kidney_ppv=. if kidneyppvdate>d(31aug2018)
	replace kidneyppvdate=. if kidneyppvdate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid kidneyfludate kidney_flu kidneyppvdate kidney_ppv

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	sort patid kidney_ppv kidneyfludate
	duplicates drop patid, force
	
	tempfile observation_CKD_`x'_`y'
	save `observation_CKD_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_CKD_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_CKD_`x'_`y''
	}
	if _rc==111{
	continue
	}

	sort patid kidney_ppv
	by patid: replace kidney_ppv=kidney_ppv[1]
	sort patid kidneyppvdate
	by patid: replace kidneyppvdate=kidneyppvdate[1]

	sort patid kidneyfludate
	duplicates drop patid, force
	tempfile observation_CKD_`x'
	save `observation_CKD_`x'', replace
	}

use `observation_CKD_1', clear	
forvalues x=2/9 {
	append using `observation_CKD_`x''
	}	
	
	rename kidney_ppv kidneyppv
	rename kidney_flu kidneyflu

save "$intermediatedatadir\observation_ChronicKidney.dta", replace


***"TEST"
clear

**Based on way programme is written and my files are saved (in batches) can't see a easy way to run - due to need to state number of files - other than write out multiple times

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_1") obsfilesnum(8) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_1") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_2") obsfilesnum(7) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_2") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_3") obsfilesnum(7) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_3") patientfile("$rawdatadir/ari_cvd_extract_patient_1")	

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_4") obsfilesnum(8) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_4") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_5") obsfilesnum(8) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_5") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_6") obsfilesnum(7) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_6") patientfile("$rawdatadir/ari_cvd_extract_patient_1")	

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_7") obsfilesnum(7) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_7") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_8") obsfilesnum(6) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_8") patientfile("$rawdatadir/ari_cvd_extract_patient_1")	

do "$dodir/prog_getSCr_Aurum.do"
prog_getSCr_Aurum, obsfile("$rawdatadir/ari_cvd_extract_observation_9") obsfilesnum(10) serum_creatinine_codelist("$codelistdir/codelist_SCr_cprd_aurum") savefile("$intermediatedatadir/Test_getSCr_9") patientfile("$rawdatadir/ari_cvd_extract_patient_1")

use "$intermediatedatadir/Test_getSCr_1"
forvalues x=2/9 {
append using "$intermediatedatadir/Test_getSCr_`x'"
}

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid obsdate ckd 
drop if ckd==0 | ckd==.
gen scr_ppv=1 if ckd==4 | ckd==5
gen scr_flu=1 
sort patid obsdate
by patid: egen scrdate_ppv=min(obsdate) if scr_ppv==1
format scrdate_ppv %td
by patid: egen scrdate_flu=min(obsdate) if scr_flu==1
format scrdate_flu %td

count if scrdate_ppv<scrdate_flu // no illogical dates 
drop if scrdate_flu>d(31aug2018)
replace scr_ppv=. if scrdate_ppv>d(31aug2018)
replace scrdate_ppv=. if scrdate_ppv>d(31aug2018)

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WIHT THE EARLIEST EVENT DATE
sort patid scr_ppv scrdate_flu
duplicates drop patid, force
count 
unique patid

label variable scrdate_ppv "earliest CKD s4-5 date from SCr"
label variable scrdate_flu "earliest CKD s3-5 date from SCr"

drop obsdate ckd

*RENAME DATES FOR LOOPS TO WORK
rename scrdate_ppv scrppvdate
rename scrdate_flu scrfludate
rename scr_ppv scrppv
rename scr_flu scrflu

save "$intermediatedatadir/Test_Kidney.dta", replace

	
