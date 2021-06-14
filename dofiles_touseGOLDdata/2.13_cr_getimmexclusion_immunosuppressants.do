/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Therapy data extracts from CPRDFast

CODELISTS:				Immunosuppressants_Gold_Jul19.dta

NEXT STEPS:				2.14_cr_getimmexclusion_oralsteroids.do

==============================================================================*/

************************
***IMMUNOSUPPRESSANTS***
************************

***THERAPY

*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
merge m:1 prodcode using "$codelistdir\Immunosuppressants_Gold_Jul19.dta", keep(match) nogen

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate immunosuppressant

*ONLY KEEP ONE OBSERVATION PER EVENT DATE
sort patid eventdate
duplicates drop
drop if eventdate>d(31aug2018)
count // 1,074,916
unique patid // 26,951

*CREATE EARLIEST DATE FOR ANY TX & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen immunosuppressantdate_earliest=min(eventdate) 
format immunosuppressantdate_earliest %td
rename eventdate immunosuppressantdate

*CREATE FLAGS FOR ORDER OF EVENT DATES & TOTAL NUMBER OF RECORDS PER PATIENT
by patid: gen immunosuppressant_N=_N
by patid: gen immunosuppressant_n=_n

save "$intermediatedatadir\Therapy_Immunosuppressants.dta", replace