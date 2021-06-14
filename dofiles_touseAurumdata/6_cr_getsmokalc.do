/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					18/06/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population covariates

DATASETS USED:			SensStudyPop.dta

NEXT STEPS:				6.1_getethnicity_hes

==============================================================================*/

use $datadir\SensStudyPop, clear
keep patid studystartdate exclmain
	 
********************
***SMOKING STATUS***
********************

preserve
run $dodir\pr_getsmokingstatus_aurum
noi pr_getsmokingstatus_aurum, clinicalfile($rawdatadir\ari_cvd_extract_observation) ///
 smokingcodelist($codelistdir\cr_smokingcodes_aurum) ///
 smokingstatusvar(smokstatus) index(studystartdate)

*Recode smoking status
recode smokstatus 12=1

save $datadir\SensStudyPop_smoking, replace

drop if exclmain==1
save $datadir\StudyPop_smoking, replace

restore

*****************
***ALCOHOL USE***
*****************
 
run $dodir\pr_getalcoholstatus_aurum
noi pr_getalcoholstatus_aurum, clinicalfile($rawdatadir\ari_cvd_extract_observation) alcoholcodelist($codelistdir\cr_alcoholcodes_aurum) numunitfile($codelistdir\cr_alcohollevel_aurum) alcoholstatusvar(alcstatus) alcohollevelvar(alclevel) alcohollevelunitvar(alclevelunit) unit_time(unit_time) index(studystartdate)
 
replace alcstatus=1 if alclevel!=. 
 
save $datadir\SensStudyPop_alcohol_update, replace

drop if exclmain==1
save $datadir\StudyPop_alcohol_update, replace