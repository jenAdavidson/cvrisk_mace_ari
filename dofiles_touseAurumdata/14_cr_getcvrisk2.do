/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					04/12/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			MACE & CV risk datasets

NEXT STEPS:				21.1_an_mace_crude2

==============================================================================*/

*************************
***HYPERTENSION STATUS***
*************************

local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop
foreach pop of local denom {
foreach cond of local file {

use $datadir/`pop'_`cond'_mace, clear

keep patid indexdate  
merge m:1 patid using $datadir\hypertens, keep(master match) keepusing(hypertensdate) nogen

gen hypertens=1 if hypertensdate<=indexdate
replace hypertens=0 if hypertens==.

label values hypertens hypertens
label variable hypertens "Patient hypertension status at baseline from pre-baseline records"

save $datadir/`pop'_`cond'_mace_hypertens, replace
}
}
	
******************
***QRISK2 SCORE***
******************

***CREATE TEMP ENDDATES TO GET QRISK ALGORITHM TO RUN (FINAL DATES ONCE HES ADDED COULD BE EARLIER BUT WILL NOT BE LATER)

local file ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop
foreach pop of local denom {
foreach cond of local file {

use $datadir/`pop'_`cond'_mace, clear

keep patid indexdate  
merge m:m patid using $datadir/`pop'_qrisk, keep(master match) keepusing(qriskdate) nogen

gen qrisk=1 if qriskdate<=indexdate
replace qrisk=0 if qrisk==.

label values qrisk qriskcat
label variable qrisk "Patient hypertension status at baseline from pre-baseline records"

save $datadir/`pop'_`cond'_mace_qrisk, replace
	
}
}
