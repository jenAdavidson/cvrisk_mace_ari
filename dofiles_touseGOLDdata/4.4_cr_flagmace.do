/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					24/06/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			MACE combined

NEXT STEPS:				5_cr_getenddate

==============================================================================*/

*****************************************
***MAJOR ADVERSE CARDIOVASCULAR EVENTS***
*****************************************

///
***COMBINE WITH PATIENT DATASET WITH STUDY START DATE
use $datadir\mace_combined.dta, clear
merge 1:1 patid using $intermediatedatadir\Denom_Exclusion, keep(match) keepusing(studystartdate) nogen

***DROP IF EVENT BEFORE STUDY START DATE
drop if macedate<studystartdate

drop studystartdate

save $datadir\mace_afterstart, replace