/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					02/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw Observation data extracts from CPRDFast
							
CODELISTS:				Diabetes_Aurum_Mar20.dta

NEXT STEPS:				2.17_cr_getneurodiseaseexclusion.do

==============================================================================*/


**************************************************
***APPLY EXCLUSIONS - DIABETES***
**************************************************

**OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\Diabetes_Aurum_Mar20.dta", keep(match) nogen
	
	*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
	sort patid obsdate
	by patid: egen diabetesdate=min(obsdate) 
	format diabetesdate %td
	by patid: egen diabetesdate_ppv_def=min(obsdate) if diabetes_ppv_def==1
	format diabetesdate_ppv_def %td
	by patid: egen diabetesdate_ppv_pos=min(obsdate) if diabetes_ppv_pos==1  
	format diabetesdate_ppv_pos %td
	
	drop if diabetesdate>d(31aug2018)
	replace diabetes_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
	replace diabetesdate_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
	replace diabetes_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)
	replace diabetesdate_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid diabetes diabetes_ppv_def diabetes_ppv_pos diabetesdate diabetesdate_ppv_def diabetesdate_ppv_pos

	*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
	sort patid diabetes_ppv_def diabetes_ppv_pos
	duplicates drop patid, force
	
	tempfile observation_Diabetes_`x'_`y'
	save `observation_Diabetes_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_Diabetes_`x'_1', clear
forvalues y=2/10 {
	capture noisily append using `observation_Diabetes_`x'_`y''
	}
	if _rc==111{
	continue
	}

	sort patid diabetes_ppv_def diabetes_ppv_pos
	duplicates drop patid, force
	tempfile observation_diabetes_`x'
	save `observation_diabetes_`x'', replace
	}

use `observation_diabetes_1', clear	
forvalues x=2/9 {
	append using `observation_diabetes_`x''
	}	
	
save "$intermediatedatadir\observation_Diabetes.dta"

***DRUG ISSUE

forvalues x=1/9 {
forvalues y=1/6 {
	capture noisily use "$rawdatadir\ari_cvd_extract_drugissue_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 prodcodeid using "$codelistdir\DiabetesMeds_Aurum_Mar20.dta", keep(match) nogen
	if _N == 0 continue
	
	*DROP IF BEYOND STUDY PERIOD END
	drop if issuedate>d(31aug2018)

	*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
	keep patid insulin oad metformin issuedate
	duplicates drop
	
	tempfile drugissue_Diabetes_`x'_`y'
	save `drugissue_Diabetes_`x'_`y'', replace
	}
	}

forvalues x=1/9 {	
use `drugissue_Diabetes_`x'_1', clear
forvalues y=2/6 {
	capture noisily append using `drugissue_Diabetes_`x'_`y''
	}
	if _rc==111{
	continue
	}

duplicates drop
sort patid
by patid: gen count=_N
sort patid metformin
by patid metformin: gen metformincount=_N
gen metforminonly=1 if count==metformincount
	
*EXPAND VARIABLES ACROSS ALL OBSERVATIONS FOR THE PATIENT
sort patid insulin
by patid: replace insulin=insulin[1]
sort patid oad
by patid: replace oad=oad[1]

sort patid issuedate
by patid: egen diabetesmeddate=min(issuedate)
format diabetesmeddate %td

drop metformin count metformincount issuedate
duplicates drop
tempfile drugissue_diabetes_`x'
save `drugissue_diabetes_`x'', replace
}

use `drugissue_diabetes_1', clear	
forvalues x=2/9 {
	append using `drugissue_diabetes_`x''
	}	

save "$intermediatedatadir\drugissue_Diabetes.dta"

***COMBINE OBSERVATION & DRUG ISSUE

merge 1:1 patid using "$intermediatedatadir\observation_Diabetes.dta"

gen metforminonlyflu=metforminonly
replace metforminonlyflu=. if diabetes==1
gen metforminonlyppv=metforminonly
replace metforminonlyppv=. if diabetes_ppv_pos==1

gen diabetesflu=1 if diabetes==1 | insulin==1 | oad==1
gen diabetesppv=1 if diabetes_ppv_def==1 | insulin==1 | oad==1 

gen diabetesfludate=diabetesdate
replace diabetesfludate=diabetesmeddate if diabetesmeddate<diabetesdate
format diabetesfludate %td

gen diabetesppvdate=diabetesdate_ppv_def
replace diabetesppvdate=diabetesmeddate if diabetesmeddate<diabetesdate_ppv_def
format diabetesppvdate %td

keep patid diabetesflu diabetesppv diabetesfludate diabetesppvdate metforminonlyflu metforminonlyppv

save "$intermediatedatadir\observationdrugissue_Diabetes.dta"