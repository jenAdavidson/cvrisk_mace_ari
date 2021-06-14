/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					23/06/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify CPRD recorded outcomes objective 1-3 (part 1)

DATASETS USED:			HES extract sent by CPRD

NEXT STEPS:				11.3_cr_getari_combined

==============================================================================*/

**********************************
***ACUTE RESPIRATORY INFECTIONS***
**********************************

///
***IDENTIFY EVENTS IN HES DATA RECEIVED
use "$datadir\hes_epi.dta"
rename icd code
merge m:1 code using "$codelistdir\ARI_HES.dta", keep(match) nogen

*DROP DUPLCATES & RECORDS BEYOND STUDY PERIOD END
drop if epistart>d(31aug2018)

keep patid epistart ari_hes ari_pneumo_hes ari_flu_hes
duplicates drop

sort patid epistart
rename epistart aridate_hes

///
***SAVE MASTER COPY OF ALL MATCHES
save "$datadir\ari_hes.dta", replace
