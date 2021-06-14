/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				CV risk level defining

DATASETS USED:			StudyPop & SensStudyPop

NEXT STEPS:				11.1_cr_getari_cprd

==============================================================================*/

*************************
***HYPERTENSION STATUS***
*************************

***CLINICAL
use $rawdatadir\Clinical_extract_ari_cvd_1, clear
merge m:1 medcode using $codelistdir\Hypertension_Gold_Jul19, keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen hypertensdate=min(eventdate) 
format hypertensdate %td
drop if hypertensdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET 
keep patid hypertensdate hypertens

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop

tempfile hypertension
save `hypertension'


***REFERRAL
use $rawdatadir\Referral_extract_ari_cvd_1, clear
merge m:1 medcode using $codelistdir\Hypertension_Gold_Jul19, keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen hypertensdate=min(eventdate) 
format hypertensdate %td
drop if hypertensdate>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET
keep patid hypertensdate hypertens

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
duplicates drop


***COMBINE CLINICAL & REFERRAL
append using `hypertension'

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid hypertensdate
duplicates drop patid, force

label variable hypertensdate "earliest hypertension date for patient"

save $datadir\hypertens, replace


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

local denom StudyPop SensStudyPop
foreach pop of local denom {
	use $intermediatedatadir\Denom_Exclusion, clear // need to run on full dataset as program falls over if no patients with a condition
	drop _merge // accidentally keep in from Denom_Inclusion creation
	merge 1:1 patid using `pop'
	replace endfudate1 = d(31aug2018) if endfudate1==. // dummy date for those who are not included in study but need here for algorithm to run
	keep patid studystartdate endfudate1 endfudate2* _merge
	rename studystartdate indexdate
	rename endfudate1 enddate
	rename _merge pop
	sort patid
	gen count=_n
	preserve
	keep if _n<500000
	do $dodir\cr_qriskscores
	save "$datadir/`pop'_qrisk_raw", replace
	restore
	keep if _n>=500000
	do $dodir\cr_qriskscores
	append using "$datadir/`pop'_qrisk_raw"
	save "$datadir/`pop'_qrisk_raw", replace
	}
	
local denom StudyPop SensStudyPop
foreach pop of local denom {
	use "$datadir/`pop'_qrisk_raw", clear
	label define qrisk 0 "QRISK2 score <10%" 1 "QRISK2 score >=10%"
	drop if score_update==. // not a full year has past since last score & end of follow-up so no update given
	drop if score==. // 107 obs from 15 patients without sex
	drop if pop==1 // excluded patients removed again
		
	gen bqrisk=1 if score>=10 & score_update==indexdate
	replace bqrisk=0 if score<10 & score_update==indexdate
	label values bqrisk qrisk
	label variable bqrisk "Patient QRISK2 score at baseline from pre-baseline records"
	tab bqrisk

	gen fuqrisk1=1 if score>=10
	replace fuqrisk1=0 if score<10
	label values fuqrisk1 qrisk
	label variable fuqrisk1 "Patient QRISK2 score from pre-baseline & follow-up records for ARI outcome"
	tab fuqrisk1

	local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath
	foreach cond of local outcome {
	gen fuqrisk2_`cond'=1 if score>=10 & score_update<=endfudate2_`cond'
	replace fuqrisk2_`cond'=0 if score<10 & score_update<=endfudate2_`cond'
	label values fuqrisk2_`cond' qrisk
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

	save "$datadir/`pop'_qrisk_allrecords", replace

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
	
	keep patid studystartdate endfudate1 endfudate2* qriskdate bqrisk fuqrisk1 fuqrisk2*

	save "$datadir/`pop'_qrisk", replace
	
	}

	
**RECORDED SCORE**
use "$rawdatadir\Clinical_extract_ari_cvd_1", clear
keep if medcode==104476 | medcode==95948 | medcode==98113
keep if enttype==147 | enttype==372
keep if eventdate>d(31dec2014) & eventdate<d(01jan2018)
keep patid adid eventdate medcode
replace adid = -_n if adid==0
merge 1:1 patid adid using "$rawdatadir\Additional_extract_ari_cvd_1", keep(match) nogen

replace data1=data2 if enttype==147
rename data3 code 
rename data1 risk_score
drop data*
drop if risk_score==.
merge m:1 code using "$datadir\scoremethod_Lookup" , nogen keep(master match)
 
label define qrisk 0 "QRISK2 score <10%" 1 "QRISK2 score >=10%"
gen qrisk_rec=0 if risk_score<10
replace qrisk_rec=1 if risk_score>=10
label values qrisk_rec qrisk
sort patid eventdate
by patid: egen highqriskdate_rec=min(eventdate) if qrisk_rec==1
format highqriskdate_rec %td
gsort patid -highqriskdate_rec
by patid: replace highqriskdate_rec=highqriskdate_rec[1]
sort patid eventdate
by patid: egen startdate_qrisk_rec=min(eventdate)
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