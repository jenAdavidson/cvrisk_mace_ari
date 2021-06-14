/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					23/06/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 

DATASETS USED:			ARI episode datasets

NEXT STEPS:				12_an_baselinecharacteristics

==============================================================================*/

**********************************
***ACUTE RESPIRATORY INFECTIONS***
**********************************

///
***CREATE ARI EPISODES

local denom StudyPop SensStudyPop
local file ari ari_pneumo ari_flu
foreach pop of local denom {
foreach name of local file {
	use `pop', clear
	keep patid studystartdate endfudate1
	
	merge 1:m patid using `name'episodes, keep(match) nogen
	drop if aridate<studystartdate
	drop if aridate>endfudate1
	sort patid aridate
	by patid: gen `name'_n=_n
	by patid: gen `name'count=_N
	save `pop'_`name'episodes, replace
	
}
}