/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					12/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Denom_Exclusion, mace, onsdeaths

NEXT STEPS:				6_cr_getsmokalc

==============================================================================*/




**CALCULATE SEPARATELY FOR MAIN & SENSITIVITY STUDY POPS AS DIFFERENT VARIABLES NEEDED SO NO LOOP


use $intermediatedatadir\Denom_Exclusion, clear
drop if exclsensitivity==1
**MERGE IN MACE OUTCOME & ONS DEATHS DATA
merge 1:1 patid using $datadir\mace_afterstart, nogen keep(master match)
merge 1:1 patid using $datadir\ons_deaths, nogen keep(master match) keepusing(dod)

**DROP PATIENTS WHO HAVE A ONS DEATH DATE BEFORE START OF FOLLOW-UP
drop if dod<studystartdate

gen endfudate1=min(enddate, cvddate, liverdate, spleendate, lungdate, hivdate, transplantdate, permcmidate, kidneyppvdate, /*scrppvdate,*/ diabetesppvdate, ppvvaccdate, aplasticdatefu, bonemarrowdatefu, malignancydatefu, fluvaccdatefu, othercmidatefu, chemoradiodatefu, immunosuppressantdatefu, oralsteroiddatefu, dod, birthday65, d(31/08/2018))
format endfudate1 %td
gen fuduration1=round((endfudate1-studystartdate)/365.25, 0.1)
label variable endfudate1 "Patient end of follow-up date for ARI outcome"
label variable fuduration1 "Patient length of follow-up in years for ARI outcome"

/*gen endfudate2=min(endfudate1, macedate)
format endfudate2 %td
gen fuduration2=round((endfudate2-studystartdate)/365.25, 0.1)
label variable endfudate2 "Patient end of follow-up date for MACE outcome"
label variable fuduration2 "Patient length of follow-up in years for MACE outcome"*/

foreach var of varlist mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath { 
gen endfudate2_`var'=min(endfudate1, `var'date)
format endfudate2_`var' %td
gen fuduration2_`var'=round((endfudate2_`var'-studystartdate)/365.25, 0.1)
}

foreach var of varlist mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath { 
replace `var'=. if `var'date>endfudate2_`var'
replace `var'date=. if `var'==.
}

preserve
keep if mace==1
keep patid mace macedate macesevere maceseveredate mi midate angina anginadate acs acsdate hf hfdate ali alidate stroke strokedate tia tiadate stroketia stroketiadate cvddeathdate cvddeath
save $datadir\SensStudyPop_mace, replace
restore

keep patid gender dob studystartdate enddate exclmain bmipriordate bmiafterdate bmipriorstatus bmiafterstatus endfudate1 fuduration1 endfudate2* fuduration2*  
save $datadir\SensStudyPop, replace



use $intermediatedatadir\Denom_Exclusion, clear
drop if exclmain==1
**MERGE IN MACE OUTCOME & ONS DEATHS DATA
merge 1:1 patid using $datadir\mace_afterstart, nogen keep(master match)
merge 1:1 patid using $datadir\ons_deaths, nogen keep(master match) keepusing(dod)

**DROP PATIENTS WHO HAVE A ONS DEATH DATE BEFORE START OF FOLLOW-UP
drop if dod<studystartdate

gen endfudate1=min(enddate, cvddate, liverdate, spleendate, lungdate, hivdate, transplantdate, permcmidate, kidneyfludate, /*scrfludate,*/ diabetesfludate, neurodate, mobeseafterdate, ppvvaccdate, asthmadatefu, aplasticdatefu, bonemarrowdatefu, malignancydatefu, fluvaccdatefu, othercmidatefu, chemoradiodatefu, immunosuppressantdatefu, oralsteroiddatefu, dod, birthday65, d(31/08/2018))
format endfudate1 %td
gen fuduration1=round((endfudate1-studystartdate)/365.25, 0.1)
label variable endfudate1 "Patient end of follow-up date for ARI outcome"
label variable fuduration1 "Patient length of follow-up in years for ARI outcome"

/*gen endfudate2=min(endfudate1, macedate)
format endfudate2 %td
gen fuduration2=round((endfudate2-studystartdate)/365.25, 0.1)
label variable endfudate2 "Patient end of follow-up date for MACE outcome"
label variable fuduration2 "Patient length of follow-up in years for MACE outcome"*/

foreach var of varlist mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath { 
gen endfudate2_`var'=min(endfudate1, `var'date)
format endfudate2_`var' %td
gen fuduration2_`var'=round((endfudate2_`var'-studystartdate)/365.25, 0.1)
}

foreach var of varlist mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath { 
replace `var'=. if `var'date>endfudate2_`var'
replace `var'date=. if `var'==.
}

preserve
keep if mace==1
keep patid mace macedate macesevere maceseveredate mi midate angina anginadate acs acsdate hf hfdate ali alidate stroke strokedate tia tiadate stroketia stroketiadate cvddeathdate cvddeath
save $datadir\StudyPop_mace, replace
restore

keep patid gender dob studystartdate enddate exclmain bmipriordate bmiafterdate bmipriorstatus bmiafterstatus endfudate1 fuduration1 endfudate2* fuduration2*  
save $datadir\StudyPop, replace

****ADD IN EXCLUSION OF EXTRA PATIENTS BASED ON EGFR
use $datadir\SensStudyPop, clear
merge 1:1 patid using "$intermediatedatadir\Test_Kidney.dta", nogen keep(master match)
gen exclscrppv=1 if scrppvdate<=studystartdate
drop if exclscrppv==1
drop scrppv scrppvdate scrflu scrfludate exclscrppv
save $datadir\SensStudyPop, replace

use $datadir\StudyPop, clear
merge 1:1 patid using "$intermediatedatadir\Test_Kidney.dta", nogen keep(master match)
gen exclscrflu=1 if scrfludate<=studystartdate
drop if exclscrflu==1
drop scrppv scrppvdate scrflu scrfludate exclscrflu
save $datadir\StudyPop, replace