/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				CV risk level defining

DATASETS USED:			StudyPop & SensStudyPop

NEXT STEPS:				11.1_cr_getari_cprd

==============================================================================*/

*************************
***HYPERTENSION STATUS***
*************************

***OBSERVATION

forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	merge m:1 medcodeid using "$codelistdir\Hypertension_Aurum_Mar20.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid obsdate
by patid: egen hypertensdate=min(obsdate) 
format hypertensdate %td
drop if hypertensdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET 
keep patid hypertensdate hypertens

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop

	tempfile observation_hypertens_`x'_`y'
	save `observation_hypertens_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_hypertens_`x'_1', clear
	forvalues y=2/10 {
	capture noisily append using `observation_hypertens_`x'_`y''
	}
	if _rc==111{
	continue
	}
	sort patid hypertensdate
	duplicates drop patid, force
	tempfile observation_hypertens_`x'
	save `observation_hypertens_`x'', replace
	}

use `observation_hypertens_1', clear	
forvalues x=2/9 {
	append using `observation_hypertens_`x''
	}
	
save "$datadir\hypertens.dta", replace

***ASSIGN IN DATASET
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use `pop', clear
	keep patid studystartdate endfudate1 endfudate2*
	merge 1:1 patid using $datadir\hypertens, keep(master match) nogen
	gen bhypertens=1 if hypertensdate<=studystartdate
	replace bhypertens=0 if bhypertens==.
	label values bhypertens hypertens
	label variable bhypertens "Patient hypertension status at baseline from pre-baseline records"
	gen fuhypertens1=1 if hypertensdate<endfudate1
	replace fuhypertens1=0 if fuhypertens1==.
	label values fuhypertens1 hypertens
	label variable fuhypertens1 "Patient hypertension status from pre-baseline & follow-up records for ARI outcome"
	local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath
	foreach cond of local outcome {
	gen fuhypertens2_`cond'=1 if hypertensdate<endfudate2_`cond'
	replace fuhypertens2_`cond'=0 if fuhypertens2_`cond'==.
	label values fuhypertens2_`cond' hypertens
	label variable fuhypertens2_`cond' "Patient hypertension status from pre-baseline & follow-up records for MACE outcome"
	}
	label define hypertens 0 "No hypertension" 1 "Hypertension"
	save "$datadir/`pop'_hypertens", replace
	}


******************
***QRISK2 SCORE***
******************
***RUN DIFFERENTLY TO GOLD, WITH JUST SENSITIVITY ANALYSIS DATASET DUE TO SIZE
use $intermediatedatadir\Denom_Exclusion, clear // need to run on full dataset as program falls over if no patients with a condition
	merge 1:1 patid using $rawdatadir\ari_cvd_extract_patient_1, keep(match) keepusing(batch) nogen
	merge 1:1 patid using $datadir\SensStudyPop
	replace endfudate1 = d(31aug2018) if endfudate1==. // dummy date for those who are not included in study but need here for algorithm to run
	keep patid studystartdate endfudate1 endfudate2* exclmain batch _merge
	rename studystartdate indexdate
	rename endfudate1 enddate
	rename _merge pop
	forvalues n=1/9 {
	preserve
	keep if batch==`n'
	save "$datadir/torunqrisk_`n'", replace
	restore
	}
	
do $dodir\cr_qriskscores_aurum	
	
forvalues n=1/9 {
	use "$datadir/qriskraw_`n'", clear
	label define qriskcat 0 "QRISK2 score <10%" 1 "QRISK2 score >=10%"
	drop if score_update==. // not a full year has past since last score & end of follow-up so no update given
	drop if score==. // 107 obs from 15 patients without sex
	drop if pop==1 // excluded patients removed again
		
	gen bqrisk=1 if score>=10 & score_update==indexdate
	replace bqrisk=0 if score<10 & score_update==indexdate
	label values bqrisk qriskcat
	label variable bqrisk "Patient QRISK2 score at baseline from pre-baseline records"
	tab bqrisk

	gen fuqrisk1=1 if score>=10
	replace fuqrisk1=0 if score<10
	label values fuqrisk1 qriskcat
	label variable fuqrisk1 "Patient QRISK2 score from pre-baseline & follow-up records for ARI outcome"
	tab fuqrisk1

	local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath
	foreach cond of local outcome {
	gen fuqrisk2_`cond'=1 if score>=10 & score_update<=endfudate2_`cond'
	replace fuqrisk2_`cond'=0 if score<10 & score_update<=endfudate2_`cond'
	label values fuqrisk2_`cond' qriskcat
	label variable fuqrisk2_`cond' "Patient QRISK2 score from pre-baseline & follow-up records for MACE outcome"
	}

	sort patid score_update
	by patid: gen qriskorder=_n
	label variable qriskorder "Date order of QRISK2 scores"
	by patid: egen maxqriskorderlow=max(qriskorder) if fuqrisk1==0
	label variable maxqriskorderlow "Latest low QRISK2 score"
	by patid: egen maxqriskorderhigh=max(qriskorder) if fuqrisk1==1
	label variable maxqriskorderhigh "Latest high QRISK2 score"
	gen qriskreverse=1 if maxqriskorderlow>maxqriskorderhigh & maxqriskorderlow!=. 
	label variable qriskreverse "Patient had low QRISK2 score after latest high score"
	tab qriskreverse // none (though some do switch back & forth during follow-up)

	save "$datadir/qrisk_allrecords_`n'", replace
	}

	
**CREATE SENSITIVITY ANALYSIS DATASET	
	use "$datadir/qrisk_allrecords_1", clear	
	forvalues n=2/9 {
	append using "$datadir/qrisk_allrecords_`n'"
	}
	
	sort patid
	by patid: egen qriskdate=min(score_update) if fuqrisk1==1
	format qriskdate %td
	label variable qriskdate "Date of earliest high QRISK2 score"
	sort patid qriskdate
	by patid: replace qriskdate=qriskdate[1]

	foreach var of varlist fuqrisk1 fuqrisk2* {
	gsort patid -`var'
	by patid: replace `var'=`var'[1]
	}
	sort patid qriskorder
	keep if qriskorder==1
	
	rename indexdate studystartdate 
	rename enddate endfudate1
	
	keep patid studystartdate endfudate1 endfudate2* qriskdate bqrisk fuqrisk1 fuqrisk2* exclmain

	save "$datadir/SensStudyPop_qrisk", replace

	
**CREATE ANALYSIS DATASET		

	use "$datadir/qrisk_allrecords_1", clear	
	forvalues n=2/9 {
	append using "$datadir/qrisk_allrecords_`n'"
	}
	
	drop enddate endfudate2* exclmain

	merge m:1 patid using $datadir\StudyPop, keep(match) nogen
	drop if score_update>endfudate1
	
	sort patid
	by patid: egen qriskdate=min(score_update) if fuqrisk1==1
	format qriskdate %td
	label variable qriskdate "Date of earliest high QRISK2 score"
	sort patid qriskdate
	by patid: replace qriskdate=qriskdate[1]

	foreach var of varlist fuqrisk1 fuqrisk2* {
	gsort patid -`var'
	by patid: replace `var'=`var'[1]
	}
	sort patid qriskorder
	keep if qriskorder==1
	
	keep patid studystartdate endfudate1 endfudate2* qriskdate bqrisk fuqrisk1 fuqrisk2*

	save "$datadir/StudyPop_qrisk", replace

**RECORDED SCORE**
forvalues x=1/9 {
forvalues y=1/10 {
	capture noisily use "$rawdatadir\ari_cvd_extract_observation_`x'_`y'.dta", clear
	if _rc==601{
	continue
	}
	keep if medcodeid=="1656451000006117" | medcodeid=="1126121000000112" | medcodeid=="2115691000000116" | medcodeid=="664421000000119" | medcodeid=="1656461000006115" | medcodeid=="8463841000006110"
	keep if obsdate>d(31dec2014) & obsdate<d(01jan2018)
	keep patid obsdate medcodeid value
 
	rename value risk_score
	drop if risk_score==""
		
	tempfile observation_qrisk_rec_`x'_`y'
	save `observation_qrisk_rec_`x'_`y'', replace
	}
	}

forvalues x=1/9 {
use `observation_qrisk_rec_`x'_1', clear
forvalues y=2/10 {
capture noisily append using `observation_qrisk_rec_`x'_`y''
}
if _rc==111{
continue
}
sort patid obsdate
duplicates drop patid, force
tempfile observation_qrisk_rec_`x'
save `observation_qrisk_rec_`x'', replace
}

use `observation_qrisk_rec_1', clear	
forvalues x=2/9 {
append using `observation_qrisk_rec_`x''
}
	 
label define qrisk 0 "QRISK2 score <10%" 1 "QRISK2 score >=10%"
destring risk_score, replace
gen qrisk_rec=0 if risk_score<10
replace qrisk_rec=1 if risk_score>=10
label values qrisk_rec qrisk
sort patid obsdate
by patid: egen highqriskdate_rec=min(obsdate) if qrisk_rec==1
format highqriskdate_rec %td
gsort patid -highqriskdate_rec
by patid: replace highqriskdate_rec=highqriskdate_rec[1]
sort patid obsdate
by patid: egen startdate_qrisk_rec=min(obsdate)
format startdate_qrisk_rec %td
save "$datadir/qrisk_recorded", replace

local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'_qrisk", clear
	keep patid studystartdate endfudate1 endfudate2_mace bqrisk fuqrisk1 fuqrisk2_mace qriskdate
	merge 1:m patid using "$datadir/qrisk_recorded", keep(match) keepusing(qrisk_rec highqriskdate_rec startdate_qrisk_rec) nogen
	
	drop if startdate_qrisk_rec>endfudate1
	replace highqriskdate_rec=. if highqriskdate_rec>endfudate1
		
	replace startdate_qrisk_rec=studystartdate if studystartdate>startdate_qrisk_rec
	replace qrisk_rec=1 if highqriskdate_rec<startdate_qrisk_rec
	
	sort patid startdate_qrisk_rec
	duplicates drop patid, force
	
	drop studystartdate
	save "$datadir/`pop'_qrisk_recorded", replace
}	
	