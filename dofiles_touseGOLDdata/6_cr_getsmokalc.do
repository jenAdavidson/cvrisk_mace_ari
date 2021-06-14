/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population covariates

DATASETS USED:			Denom_SensStudyPop

NEXT STEPS:				7.1_getethnicity_hes

==============================================================================*/

use $datadir\SensStudyPop, clear
keep patid studystartdate exclmain


********************
***SMOKING STATUS***
********************

preserve
run $dodir\pr_getsmokingstatus
noi pr_getsmokingstatus, clinicalfile($rawdatadir\Clinical_extract_ari_cvd_1) ///
 additionalfile($rawdatadir\Additional_extract_ari_cvd_1) smokingcodelist($codelistdir\smokingcodes) ///
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
 
run $dodir\pr_getalcoholstatus
noi pr_getalcoholstatus, clinicalfile($rawdatadir\Clinical_extract_ari_cvd_1) ///
additionalfile($rawdatadir\Additional_extract_ari_cvd_1) ///
alcoholcodelist($codelistdir\alcoholcodes) alcoholstatusvar(alcstatus) ///
alcohollevelvar(alclevel) index(studystartdate)

replace alclevel=. if alclevel==0 | alclevel==-1
replace alclevel=. if alcstatus==0 | alcstatus==2

save $datadir\SensStudyPop_alcohol, replace

drop if exclmain==1
save $datadir\StudyPop_alcohol, replace
