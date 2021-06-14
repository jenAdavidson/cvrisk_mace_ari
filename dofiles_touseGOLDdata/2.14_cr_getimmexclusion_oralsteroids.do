/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Therapy data extracts from CPRDFast

CODELISTS:				OralSteroids_Gold_Jul19.dta

NEXT STEPS:				2.15_cr_getckdexclusion.do

==============================================================================*/

*******************
***ORAL STEROIDS***
*******************

***THERAPY

*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
merge m:1 prodcode using "$codelistdir\OralSteroids_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate steroid

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)

*CREATE EARLIEST DATE FOR ANY TX & DROP IF BEYOND STUDY PERIOD END
by patid: egen oralsteroiddate_earliest=min(eventdate) 
format oralsteroiddate_earliest %td
rename eventdate oralsteroiddate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen oralsteroid_N=_N
by patid: gen oralsteroid_n=_n

*ONLY KEEP RECORDS FOR PATIENTS IF HAVE 2+ PRESCRIPTIONS
drop if oralsteroid_N==1 

count // 1,685,644
unique patid // 142,032

save "$intermediatedatadir\Therapy_OralSteroids.dta", replace