/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Raw Clinical, Referral & Therapy data extracts from CPRDFast

CODELISTS:				Diabetes_Gold_Jul19.dta
						DiabetesMeds_Gold_Jul19.dta

NEXT STEPS:				2.17_cr_getneurodiseaseexclusion.do

==============================================================================*/

**************
***DIABETES*** 
**************

***CLINICAL

use "$rawdatadir\Clinical_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Diabetes_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen diabetesdate=min(eventdate)
format diabetesdate %td
by patid: egen diabetesdate_ppv_def=min(eventdate) if diabetes_ppv_def==1
format diabetesdate_ppv_def %td
by patid: egen diabetesdate_ppv_pos=min(eventdate) if diabetes_ppv_pos==1  
format diabetesdate_ppv_pos %td

drop if diabetesdate>d(31aug2018)
replace diabetes_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
replace diabetesdate_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
replace diabetes_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)
replace diabetesdate_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid diabetes diabetes_ppv_def diabetes_ppv_pos diabetesdate diabetesdate_ppv_def diabetesdate_ppv_pos

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid diabetes_ppv_def diabetes_ppv_pos
duplicates drop patid, force
unique patid // 119,750

save "$intermediatedatadir\Clinical_Diabetes.dta", replace

***REFERRAL

use "$rawdatadir\Referral_extract_ari_cvd_1.dta", clear
merge m:1 medcode using "$codelistdir\Diabetes_Gold_Jul19.dta", keep(match) nogen

*CREATE EARLIEST DATE FOR ANY DIAG & DROP IF BEYOND STUDY PERIOD END
sort patid eventdate
by patid: egen diabetesdate=min(eventdate)
format diabetesdate %td
by patid: egen diabetesdate_ppv_def=min(eventdate) if diabetes_ppv_def==1
format diabetesdate_ppv_def %td
by patid: egen diabetesdate_ppv_pos=min(eventdate) if diabetes_ppv_pos==1  
format diabetesdate_ppv_pos %td

drop if diabetesdate>d(31aug2018)
replace diabetes_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
replace diabetesdate_ppv_def=. if diabetesdate_ppv_def>d(31aug2018)
replace diabetes_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)
replace diabetesdate_ppv_pos=. if diabetesdate_ppv_pos>d(31aug2018)

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid diabetes diabetes_ppv_def diabetes_ppv_pos diabetesdate diabetesdate_ppv_def diabetesdate_ppv_pos

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid diabetes_ppv_def diabetes_ppv_pos
duplicates drop patid, force
count // 14,248

save "$intermediatedatadir\Referral_Diabetes.dta", replace

***COMBINE CLINICAL & REFERRAL

append using "$intermediatedatadir\Clinical_Diabetes.dta"

*CREATE EARLIEST DATE FOR ANY DIAG AGAIN AS THERE MAY BE DIFFERENT COMBINATIONS OF DATA BETWEEN CLINICAL & REFERRAL
sort patid diabetesdate
by patid: egen diabetesdate1=min(diabetesdate)
format diabetesdate1 %td
sort patid diabetesdate_ppv_def
by patid: egen diabetesdate_ppv_def1=min(diabetesdate_ppv_def)
format diabetesdate_ppv_def1 %td
sort patid diabetesdate_ppv_pos
by patid: egen diabetesdate_ppv_pos1=min(diabetesdate_ppv_pos)
format diabetesdate_ppv_pos1 %td

drop diabetesdate diabetesdate_ppv_def diabetesdate_ppv_pos
rename diabetesdate1 diabetesdate
rename diabetesdate_ppv_def1 diabetesdate_ppv_def
rename diabetesdate_ppv_pos1 diabetesdate_ppv_pos

*ONLY KEEP ONE OBSERVATION PER PATIENT, THE ONE WITH THE EARLIEST EVENT DATE
sort patid diabetes_ppv_def diabetes_ppv_pos
duplicates drop patid, force
count // 119,835

label variable diabetesdate "earliest diabetes diag date"
label variable diabetesdate_ppv_def "earliest medicated (temp or perm) diabetes date"
label variable diabetes_ppv_pos "earliest non-diet only diabetes date"

save "$intermediatedatadir\ClinicalReferral_Diabetes.dta", replace

***THERAPY

*COMBINE DATASETS
use "$rawdatadir\Therapy_extract_ari_cvd_1.dta", clear
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
append using "$rawdatadir\Therapy_extract_ari_cvd_2.dta"
drop sysdate consid staffid dosageid qty numdays numpacks packtype issueseq
merge m:1 prodcode using "$codelistdir\DiabetesMeds_Gold_Jul19.dta", keep(match) nogen

*DROP IF DATE OF EVENT IS AFTER STUDY PERIOD END
drop if eventdate>d(31aug2018)

*CREATE EARLIEST DATE FOR ANY TX  
sort patid eventdate
by patid: egen diabetesmeddate=min(eventdate)
format diabetesmeddate %td
*drop if diabetesmeddate>d(31aug2018) 

*CREATE EARLIEST DATE FOR INSULIN TX
by patid: egen insulindate=min(eventdate) if insulin==1
format insulindate %td
*replace insulin=. if insulindate>d(31aug2018)
*replace insulindate=. if insulindate>d(31aug2018)

*CREATE EARLIEST DATE FOR OAD TX
by patid: egen oaddate=min(eventdate) if oad==1 
format oaddate %td
*replace oad=. if oaddate>d(31aug2018)
*replace metformin=. if oaddate>d(31aug2018)
*replace oaddate=. if oaddate>d(31aug2018)

*CREATE EARLIEST DATE FOR NON-METFORMIN OAD TX
by patid: egen oaddate_notmetformin=min(eventdate) if oad==1 & metformin!=1
format oaddate_notmetformin %td

*CREATE EARLIEST & LATEST DATE FOR METFORMIN TX
by patid: egen metformindate=min(eventdate) if metformin==1
format metformindate %td

by patid: egen metformindate_latest=max(eventdate) if metformin==1
format metformindate_latest %td

*EXPAND VARIABLES ACROSS ALL OBSERVATIONS FOR THE PATIENT
sort patid insulin
by patid: replace insulin=insulin[1]
sort patid insulindate
by patid: replace insulindate=insulindate[1]
sort patid oad
by patid: replace oad=oad[1]
sort patid oaddate
by patid: replace oaddate=oaddate[1]
sort patid oaddate_notmetformin
by patid: replace oaddate_notmetformin=oaddate_notmetformin[1]
sort patid metformin
by patid: replace metformin=metformin[1]
sort patid metformindate
by patid: replace metformindate=metformindate[1]
sort patid metformindate_latest
by patid: replace metformindate_latest=metformindate_latest[1]

*ONLY KEEP VARIABLES NEEDED FOR MERGING & CODING WITH PATIENT DATASET FOR EXCLUSION
keep patid insulin oad metformin diabetesmeddate insulindate oaddate oaddate_notmetformin metformindate metformindate_latest

*ONLY KEEP ONE OBSERVATION PER PATIENT
duplicates drop patid, force
count // 106,489

*FLAG IF ONLY TX IS METFORMIN
gen metformin_only=1 if metformin==1 & insulin==. & oaddate_notmetformin==.

save "$intermediatedatadir\Therapy_Diabetes.dta", replace

***COMBINE CLINICAL & REFERRAL WITH THERAPY

merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Diabetes.dta"

gen metformin_onlyflu=metformin_only
replace metformin_onlyflu=. if diabetes==1
gen metformin_onlyppv=metformin_only
replace metformin_onlyppv=. if diabetes_ppv_pos==1

gen diabetes_flu=1 if diabetes==1 | insulin==1 | oad==1
gen diabetes_ppv=1 if diabetes_ppv_def==1 | insulin==1 | oad==1 

gen diabetesdate_flu=diabetesdate
replace diabetesdate_flu=diabetesmeddate if diabetesmeddate<diabetesdate_flu
format diabetesdate_flu %td

gen diabetesdate_ppv=diabetesdate_ppv_def
replace diabetesdate_ppv=diabetesmeddate if diabetesmeddate<diabetesdate_ppv_def
format diabetesdate_ppv %td

keep patid diabetes_flu diabetes_ppv diabetesdate_flu diabetesdate_ppv metformin_onlyflu metformin_onlyppv metformindate metformindate_latest

*RENAME DATES FOR LOOPS TO WORK
rename diabetesdate_ppv diabetesppvdate
rename diabetesdate_flu diabetesfludate
rename diabetes_flu diabetesflu
rename diabetes_ppv diabetesppv

count // 125,293
unique patid // 125,293

save "$intermediatedatadir\ClinicalReferralTherapy_Diabetes.dta", replace