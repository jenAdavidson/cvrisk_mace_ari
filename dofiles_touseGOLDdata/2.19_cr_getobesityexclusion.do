/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					15/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Patient_Denom_InclusionApplied.dta
						Raw data extracts from CPRDFast

NEXT STEP: 				2.20_cr_getvaccinesexclusion.do						
						
==============================================================================*/

use "$intermediatedatadir\Denom_Inclusion.dta", clear
keep patid studystartdate
run "J:\EHR-Working\Jennifer\ARI_CVcomplications\Gold\DoFiles\pr_getbmistatus"
run "J:\EHR-Working\Jennifer\ARI_CVcomplications\Gold\DoFiles\pr_getallbmirecords"
noi pr_getbmistatus, index(studystartdate) patientfile($rawdatadir\Patient_extract_ari_cvd_1) ///
	 clinicalfile($rawdatadir\Clinical_extract_ari_cvd_1) ///
	 additionalfile($rawdatadir\Additional_extract_ari_cvd_1)
	 
egen bmi_cat=cut(bmi), at(0,18.5,25,30,40,1000) 
recode bmi_cat 18.5=1
recode bmi_cat 25=2
recode bmi_cat 30=3
recode bmi_cat 40=4
	 
label define bmi_cat 0 "Underweight" 1 "Normal Weight" 2 "Overweight" 3 "Obese" 4 "Morbidly obese"
lab val bmi_cat bmi_cat
tab bmi_cat	

gen bmipriorstart=1 if _distance<0
gen bmiafterstart=1 if _distance>=0 & _distance!=.

by patid: egen bmipriordate=max(dobmi) if bmipriorstart==1
format bmipriordate %td
sort patid bmipriordate
by patid: replace bmipriordate=bmipriordate[1]

by patid: egen bmiafterdate=min(dobmi) if bmiafterstart==1
format bmiafterdate %td
sort patid bmiafterdate
by patid: replace bmiafterdate=bmiafterdate[1]

gen bmipriorstatus=bmi_cat if bmipriordate==dobmi
sort patid bmipriorstatus
by patid: replace bmipriorstatus=bmipriorstatus[1]
label values bmipriorstatus bmi_cat

gen bmiafterstatus=bmi_cat if bmiafterdate==dobmi
sort patid bmiafterstatus
by patid: replace bmiafterstatus=bmiafterstatus[1]
label values bmiafterstatus bmi_cat

by patid: egen mobesepriordate=max(dobmi) if bmipriorstart==1 & bmi_cat==4 
format mobesepriordate %td
sort patid mobesepriordate
by patid: replace mobesepriordate=mobesepriordate[1]
label variable mobesepriordate "Last morbid obesity record before baseline"

by patid: egen mobeseafterdate=min(dobmi) if bmiafterstart==1 & bmi_cat==4 
format mobeseafterdate %td
sort patid mobeseafterdate
by patid: replace mobeseafterdate=mobeseafterdate[1]
label variable mobeseafterdate "First morbid obesity record after baseline"

keep patid mobesepriordate mobeseafterdate bmipriordate bmiafterdate bmipriorstatus bmiafterstatus
duplicates drop
	
compress
	
save "$intermediatedatadir\BMI.dta", replace
