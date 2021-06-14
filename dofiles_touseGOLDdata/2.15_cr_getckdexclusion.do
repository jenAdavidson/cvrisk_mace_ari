/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical, Referral & Test data extracts from CPRDFast

CODELISTS:				KidneyDisease_Gold_Jul19.dta
						medcodes-SCr.dta

NEXT STEPS:				2.16_cr_getdiabetesexclusion.do
							
==============================================================================*/

****************************
***CHRONIC KIDNEY DISEASE***
****************************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\KidneyDisease_Gold_Jul19.dta", keep(match) nogen

*DROP DATA & VARIABLES NOT NEEDED
drop if ckd_1_2==1 // this is only for covariate analysis
drop ckd_1_2 ckd_3_5 ckd_4_5 dialysis 

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen kidneydate_flu=min(eventdate)
format kidneydate_flu %td
by patid: egen kidneydate_ppv=min(eventdate) if kidney_ppv==1
format kidneydate_ppv %td

count if kidneydate_ppv<kidneydate_flu // no illogical dates 
drop if kidneydate_flu>d(31aug2018)
replace kidney_ppv=. if kidneydate_ppv>d(31aug2018)
replace kidneydate_ppv=. if kidneydate_ppv>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid kidneydate_ppv kidney_ppv kidneydate_flu kidney_flu

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WIHT THE EARLIEST EVENT DATE
sort patid kidney_ppv kidneydate_flu
duplicates drop patid, force
count
unique patid // 43,106

save "$intermediatedatadir\Clinical_Kidney.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\KidneyDisease_Gold_Jul19.dta", keep(match) nogen

*DROP DATA & VARIABLES NOT NEEDED
drop if ckd_1_2==1 // this is only for covariate analysis
drop ckd_1_2 ckd_3_5 ckd_4_5 dialysis 

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen kidneydate_flu=min(eventdate)
format kidneydate_flu %td
by patid: egen kidneydate_ppv=min(eventdate) if kidney_ppv==1
format kidneydate_ppv %td

count if kidneydate_ppv<kidneydate_flu // no illogical dates 
drop if kidneydate_flu>d(31aug2018)
replace kidney_ppv=. if kidneydate_ppv>d(31aug2018)
replace kidneydate_ppv=. if kidneydate_ppv>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid kidneydate_ppv kidney_ppv kidneydate_flu kidney_flu

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid kidney_ppv kidneydate_flu
duplicates drop patid, force
count
unique patid // 1,134

save "$intermediatedatadir\Referral_Kidney.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Kidney.dta"

*CREATE EARLIEST DATE FOR ANY DIAG AGAIN AS THERE MAY BE DIFFERENT COMBINATIONS OF DATA BETWEEN CLINICAL & REFERRAL
sort patid kidneydate_flu
by patid: egen kidneydate_flu1=min(kidneydate_flu)
format kidneydate_flu1 %td
sort patid kidneydate_ppv
by patid: egen kidneydate_ppv1=min(kidneydate_ppv)
format kidneydate_ppv1 %td

drop kidneydate_ppv kidneydate_flu
rename kidneydate_ppv1 kidneydate_ppv
rename kidneydate_flu1 kidneydate_flu

count if kidneydate_ppv<kidneydate_flu // no illogical dates 

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid kidney_ppv kidneydate_flu
duplicates drop patid, force
unique patid // 43,172

label variable kidneydate_ppv "earliest CKD s4-5 date"
label variable kidneydate_flu "earliest CKD s3-5 date"

*RENAME VARIABLES FOR LOOPS TO WORK
rename kidneydate_ppv kidneyppvdate
rename kidneydate_flu kidneyfludate
rename kidney_ppv kidneyppv
rename kidney_flu kidneyflu

save "$intermediatedatadir\ClinicalReferral_Kidney.dta", replace

***TEST
clear
do "$dodir/prog_getSCr.do"
prog_getSCr, ///
	testfile("$rawdatadir/Test_extract_ari_cvd") ///
	testfilesnum(1) ///
	codelist("$codelistdir/medcodes-SCr") ///
	savefile("$immediatedatadir/Test_getSCr") ///
	patientfile("$rawdatadir/Patient_extract_ari_cvd_1")

label data "SCr results and calculated eGFR"
	
save "$intermediatedatadir/Test_getSCr.dta", replace

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid eventdate ckd ageAtEvent
rename ageAtEvent scrage
drop if ckd==0 | ckd==.
gen scr_ppv=1 if ckd==4 | ckd==5
gen scr_flu=1 if ckd==2 | ckd==3 | scr_ppv==1
sort patid eventdate
by patid: egen scrdate_ppv=min(eventdate) if scr_ppv==1
format scrdate_ppv %td
by patid: egen scrdate_flu=min(eventdate) if scr_flu==1
format scrdate_flu %td

count if scrdate_ppv<scrdate_flu // no illogical dates 
drop if scrdate_flu>d(31aug2018)
replace scr_ppv=. if scrdate_ppv>d(31aug2018)
replace scrdate_ppv=. if scrdate_ppv>d(31aug2018)

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WIHT THE EARLIEST EVENT DATE
sort patid scr_ppv scrdate_flu
duplicates drop patid, force
count // 83,649
unique patid // 83,649

label variable scrdate_ppv "earliest CKD s4-5 date from SCr"
label variable scrdate_flu "earliest CKD s3-5 date from SCr"

drop eventdate ckd

*RENAME DATES FOR LOOPS TO WORK
rename scrdate_ppv scrppvdate
rename scrdate_flu scrfludate
rename scr_ppv scrppv
rename scr_flu scrflu

save "$intermediatedatadir/Test_Kidney.dta", replace