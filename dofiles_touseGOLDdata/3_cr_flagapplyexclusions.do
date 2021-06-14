/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					09/04/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population by applying inclusion & 
						exclusion criteria for objective 1-3 (part 1)

DATASETS USED:			Denomin_Inclusion.dta

NEXT STEPS:				4_cr_getenddate.do

==============================================================================*/

*********************
***FLAG EXCLUSIONS***
*********************

***ADD CODELISTS WITH EVER DIAGNOSIS/TREATMENT EXCLUSIONS
use "$intermediatedatadir\Denom_Inclusion.dta", clear
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_CVD.dta", nogen
unique patid if cvddate<=studystartdate // 58,710
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Liver.dta", nogen
unique patid if liverdate<=studystartdate // 4,697
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Spleen.dta", nogen
unique patid if spleendate<=studystartdate // 8,305
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Lung.dta", nogen
unique patid if lungdate<=studystartdate // 25,285
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_HIV.dta", nogen
unique patid if hivdate<=studystartdate // 2,099
merge 1:1 patid using"$intermediatedatadir\ClinicalReferral_Transplant.dta", nogen
unique patid if transplantdate<=studystartdate // 1,616
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_PermCMI.dta", nogen
unique patid if permcmidate<=studystartdate // 41
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Kidney.dta", nogen
merge 1:1 patid using "$intermediatedatadir\Test_Kidney.dta", nogen
unique patid if kidneyppvdate<=studystartdate | scrppvdate<=studystartdate // 5,570
unique patid if kidneyfludate<=studystartdate | scrfludate<=studystartdate // 50,050
merge 1:1 patid using "$intermediatedatadir\ClinicalReferralTherapy_Diabetes.dta", nogen
unique patid if diabetesppvdate<=studystartdate // 67,402
unique patid if diabetesfludate<=studystartdate // 79,205
**Need to add coding for metformin only
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Neuro.dta", nogen
merge 1:1 patid using "$intermediatedatadir\BMI.dta", nogen
merge 1:1 patid using "$intermediatedatadir\ClinicalReferralImmunisationTherapy_PPV.dta", nogen
unique patid if ppvvaccdate<=studystartdate // 109,566
unique patid if ppvvaccdate<=studystartdate & ppvvaccconflict!=1 // 109,547

***CREATE FLAGS FOR EVER DIAGNOSIS/TREATMENT EXCLUSIONS IF EARLIEST DATE FOR CONDITION IS BEFORE INDEX DATE
foreach var of varlist cvd liver spleen lung hiv transplant permcmi kidneyppv kidneyflu scrppv scrflu diabetesflu diabetesppv neuro ppvvacc {
	gen excl`var'=1 if `var'date<=studystartdate
	}

replace excldiabetesppv=. if metformin_onlyppv==1 & gender==2
replace	excldiabetesflu=. if metformin_onlyflu==1 & gender==2
replace diabetesppvdate=. if metformin_onlyppv==1 & gender==2
replace	diabetesfludate=. if metformin_onlyflu==1 & gender==2
unique patid if excldiabetesppv==1 // 64,275
unique patid if excldiabetesflu==1 // 76,078
	
gen exclmobesity=1 if bmipriorstatus==4
unique patid if exclmobesity==1 // 42,639
unique patid if mobesepriordate!=. & bmipriorstatus!=. & bmipriorstatus!=4 // 15,560 who have previously been morbidly obese but not at latest pre-baseline measure (but only 9,511 when exclude other perm baseline exclusions)
*replace mobesitydate=. if mobesitydate<=studystartdate // those who were morbidly obese in the past but this wasn't there latest measure before baseline

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - ASTHMA FIRST
merge 1:1 patid using "$intermediatedatadir\ClinicalReferral_Asthma.dta", nogen
merge 1:m patid using "$intermediatedatadir\Therapy_Asthma.dta", nogen	

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid asthmasteroid_n
gen days_start_tosteroid=asthmasteroiddate-studystartdate
gen steroidin365days=1 if days_start_tosteroid>-366 & days_start_tosteroid<=0
by patid: egen num_steroidin365days=sum(steroidin365days)
unique patid if num_steroidin365days>1 & asthma_steroid==1 & asthma==1 // 75,758 (was 36,272 when only BNF codes included)
gen exclasthma=1 if num_steroidin365days>1 & asthma_steroid==1 & asthma==1
replace exclasthma=1 if asthmahosp==1 & asthmahospdate<=studystartdate
unique patid if exclasthma==1 // 76,459 (37,937)

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: gen flag_steroidin365days=asthmasteroiddate-asthmasteroiddate[_n-1]
by patid: egen asthmadatefu=min(asthmasteroiddate) if flag_steroidin365days<366 & flag_steroidin365days>=0 & days_start_tosteroid>0 & days_start_tosteroid!=.
format asthmadatefu %td
replace asthmadatefu=asthmahospdate if asthmahospdate>studystartdate & asthmahosp==1 & asthmahospdate<asthmadatefu
replace asthmadatefu=. if asthma==.
replace asthmadatefu=. if exclasthma==1
sort patid asthmadatefu
by patid: replace asthmadatefu=asthmadatefu[1]
drop asthmasteroiddate days_start_tosteroid steroidin365days num_steroidin365days flag_steroidin365days asthmasteroid_N asthmasteroiddate_earliest
drop if asthmasteroid_n!=1 & asthma_steroid==1
drop asthmasteroid_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - APLASTIC ANAEMIA	
merge 1:m patid using "$intermediatedatadir\ClinicalReferral_AplasticAnaemia.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid aplasticdate
gen days_start_toaplastic=aplasticdate-studystartdate
gen exclaplastic=1 if days_start_toaplastic>-731 & days_start_toaplastic<=0
sort patid exclaplastic
by patid: replace exclaplastic=exclaplastic[1]
unique patid if exclaplastic==1 // 15

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen aplasticdatefu=min(aplasticdate) if aplasticdate>studystartdate
format aplasticdatefu %td
sort patid aplasticdatefu
by patid: replace aplasticdatefu=aplasticdatefu[1]
replace aplasticdatefu=. if exclaplastic==1
drop aplasticdate aplasticdate_earliest days_start_toaplastic aplastic_N 
drop if aplastic_n!=1 & aplastic==1
drop aplastic_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - BONE MARROW OR STEM CELL TRANSPLANT
merge 1:m patid using "$intermediatedatadir\ClinicalReferral_BoneMarrowStemCell.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid bonemarrowdate
gen days_start_tobonemarrow=bonemarrowdate-studystartdate
gen exclbonemarrow=1 if days_start_tobonemarrow>-731 & days_start_tobonemarrow<=0
sort patid exclbonemarrow
by patid: replace exclbonemarrow=exclbonemarrow[1]
unique patid if exclbonemarrow==1 // 102

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen bonemarrowdatefu=min(bonemarrowdate) if bonemarrowdate>studystartdate
format bonemarrowdatefu %td
sort patid bonemarrowdatefu
by patid: replace bonemarrowdatefu=bonemarrowdatefu[1]
replace bonemarrowdatefu=. if exclbonemarrow==1
drop bonemarrowdate bonemarrowdate_earliest days_start_tobonemarrow bonemarrow_N 
drop if bonemarrow_n!=1 & bonemarrow==1
drop bonemarrow_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - HAEMATOLOGICAL MALIGNANCIES
merge 1:m patid using "$intermediatedatadir\ClinicalReferral_HaematologicalMalignancies.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid malignancydate
gen days_start_tomalignancy=malignancydate-studystartdate
gen exclmalignancy=1 if days_start_tomalignancy>-731 & days_start_tomalignancy<=0
sort patid exclmalignancy
by patid: replace exclmalignancy=exclmalignancy[1]
unique patid if exclmalignancy==1 // 1,547

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen malignancydatefu=min(malignancydate) if malignancydate>studystartdate
format malignancydatefu %td
sort patid malignancydatefu
by patid: replace malignancydatefu=malignancydatefu[1]
replace malignancydatefu=. if exclmalignancy==1
drop malignancydate malignancydate_earliest days_start_tomalignancy malignancy_N 
drop if malignancy_n!=1 & malignancy==1
drop malignancy_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - FLU VACCINE
merge 1:m patid using "$intermediatedatadir\ClinicalReferralImmunisationTherapy_FluVac.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid fluvaccdate
gen days_start_tofluvac=fluvaccdate-studystartdate
gen exclfluvacc=1 if days_start_tofluvac>-366 & days_start_tofluvac<=0
unique patid if exclfluvacc==1 // 188,246
unique patid if exclfluvacc==1 & fluconflict!=1 // 188,140
gen exclfluconflict=1 if fluconflict==1 & exclfluvacc==1
sort patid exclfluvacc
by patid: replace exclfluvacc=exclfluvacc[1]
sort patid exclfluconflict
by patid: replace exclfluconflict=exclfluconflict[1]

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen fluvaccdatefu=min(fluvaccdate) if fluvaccdate>studystartdate 
format fluvaccdatefu %td
gen fluconflictfu=1 if fluvaccdatefu!=. & fluconflict==1 & fluvaccdatefu==fluvaccdate
by patid: egen fluvaccdatefu_noconflict=min(fluvaccdate) if fluvaccdate>studystartdate & fluconflict!=1
format fluvaccdatefu_noconflict %td
sort patid fluvaccdatefu
by patid: replace fluvaccdatefu=fluvaccdatefu[1]
sort patid fluconflictfu
by patid: replace fluconflictfu=fluconflictfu[1]
sort patid fluvaccdatefu_noconflict
by patid: replace fluvaccdatefu_noconflict=fluvaccdatefu_noconflict[1]
replace fluvaccdatefu=. if exclfluvacc==1
replace fluconflictfu=. if exclfluvacc==1
replace fluvaccdatefu_noconflict=. if exclfluvacc==1
drop fluvaccdate fluconflict days_start_tofluvac 
drop if fluvacc_n!=1 & fluvacc==1
drop fluvacc_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - OTHER CMI
merge 1:m patid using "$intermediatedatadir\ClinicalReferral_OtherCMI.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid othercmidate
gen days_start_toothercmi=othercmidate-studystartdate
gen exclothercmi=1 if days_start_toothercmi>-366 & days_start_toothercmi<=0
sort patid exclothercmi
by patid: replace exclothercmi=exclothercmi[1]
unique patid if exclothercmi==1 // 261

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen othercmidatefu=min(othercmidate) if othercmidate>studystartdate 
format othercmidatefu %td
sort patid othercmidatefu
by patid: replace othercmidatefu=othercmidatefu[1]
replace othercmidatefu=. if exclothercmi==1
drop othercmidate days_start_toothercmi othercmidate_earliest othercmi_N
drop if othercmi_n!=1 & othercmi==1
drop othercmi_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - OTHER CMI
merge 1:m patid using "$intermediatedatadir\ClinicalReferral_ChemoRadioTherapy.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid chemoradiodate
gen days_start_tochemoradio=chemoradiodate-studystartdate
gen exclchemoradio=1 if days_start_tochemoradio>-366 & days_start_tochemoradio<=0
sort patid exclchemoradio
by patid: replace exclchemoradio=exclchemoradio[1]
unique patid if exclchemoradio==1 // 2,344

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen chemoradiodatefu=min(chemoradiodate) if chemoradiodate>studystartdate 
format chemoradiodatefu %td
sort patid chemoradiodatefu
by patid: replace chemoradiodatefu=chemoradiodatefu[1]
replace chemoradiodatefu=. if exclchemoradio==1
drop chemoradiodate days_start_tochemoradio chemoradiodate_earliest chemoradio_N
drop if chemoradio_n!=1 & chemoradio==1
drop chemoradio_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS -IMMUNOSUPPRESSANTS
merge 1:m patid using "$intermediatedatadir\Therapy_Immunosuppressants.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid immunosuppressantdate
gen days_start_toimmunosuppressant=immunosuppressantdate-studystartdate
gen exclimmunosuppressant=1 if days_start_toimmunosuppressant>-366 & days_start_toimmunosuppressant<=0
sort patid exclimmunosuppressant
by patid: replace exclimmunosuppressant=exclimmunosuppressant[1]
unique patid if exclimmunosuppressant==1 // 11,683

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: egen immunosuppressantdatefu=min(immunosuppressantdate) if immunosuppressantdate>studystartdate
format immunosuppressantdatefu %td
sort patid immunosuppressantdatefu
by patid: replace immunosuppressantdatefu=immunosuppressantdatefu[1]
replace immunosuppressantdatefu=. if exclimmunosuppressant==1
drop immunosuppressantdate days_start_toimmunosuppressant immunosuppressantdate_earliest immunosuppressant_N
drop if immunosuppressant_n!=1 & immunosuppressant==1
drop immunosuppressant_n
unique patid // 1,650,476

***ADD CODELISTS FOR TIME CONDITIONED EXCLUSIONS - ORAL STEROIDS
merge 1:m patid using "$intermediatedatadir\Therapy_OralSteroids.dta", nogen

*CREATE FLAG FOR EXCLUISON IS TIME CONDITIONS MET
sort patid oralsteroid_n
gen days_start_tosteroid=oralsteroiddate-studystartdate
gen steroidin365days=1 if days_start_tosteroid>-366 & days_start_tosteroid<=0
by patid: egen num_steroidin365days=sum(steroidin365days)
unique patid if num_steroidin365days>1 & steroid==1 // 22,018
gen exclsteroid=1 if num_steroidin365days>1 & steroid==1

*CREATE FLAG FOR WHEN EXCLUSIONS WOULD FIRST APPLY IN FOLLOW UP FOR THESE NOT EXCLUDED AT INDEX
by patid: gen flag_steroidin365days=oralsteroiddate-oralsteroiddate[_n-1]
by patid: egen oralsteroiddatefu=min(oralsteroiddate) if flag_steroidin365days<366  & flag_steroidin365days>=0 & days_start_tosteroid>0
format oralsteroiddatefu %td
replace oralsteroiddatefu=. if exclsteroid==1
sort patid oralsteroiddatefu
by patid: replace oralsteroiddatefu=oralsteroiddatefu[1]
drop oralsteroiddate days_start_tosteroid num_steroidin365days flag_steroidin365days oralsteroiddate_earliest oralsteroid_N steroidin365days
drop if oralsteroid_n!=1 & steroid==1
drop oralsteroid_n
unique patid // 1,650,476


********************************************
***GENERATION OVERALL EXCLUSION VARIABLES***
********************************************

gen exclmain=. 
foreach var of varlist exclcvd exclliver exclspleen excllung exclhiv excltransplant exclpermcmi exclkidneyflu exclscrflu excldiabetesflu exclneuro exclppv exclmobesity exclasthma exclaplastic exclbonemarrow exclmalignancy exclfluvacc exclothercmi exclchemoradio exclimmunosuppressant exclsteroid {
	replace exclmain=1 if `var'==1 
	}

gen exclsensitivity=. 
foreach var of varlist exclcvd exclliver exclspleen excllung exclhiv excltransplant exclpermcmi exclkidneyppv exclscrppv excldiabetesppv exclppv exclaplastic exclbonemarrow exclmalignancy exclfluvacc exclothercmi exclchemoradio exclimmunosuppressant exclsteroid {
	replace exclsensitivity=1 if `var'==1 
	}
	
save "$intermediatedatadir\Denom_Exclusion.dta", replace

log using "$logdir\ExclusionCounts.log", replace

foreach var of varlist exclcvd exclliver exclspleen excllung exclhiv excltransplant exclpermcmi exclkidneyflu exclscrflu exclkidneyppv exclscrppv excldiabetesflu excldiabetesppv exclppv exclneuro exclmobesity exclasthma exclaplastic exclbonemarrow exclmalignancy exclfluvacc exclothercmi exclchemoradio exclimmunosuppressant exclsteroid exclmain exclsensitivity {
	tab `var'
	}

log close


**********************************************************
***SAVE DATASETS WITH PATIENT IDS FOR STUDY POPULATIONS***
**********************************************************

keep patid hes_e death_e lsoa_e exclmain exclsensitivity
drop if exclsensitivity==1
drop exclsensitivity
save "$datadir\SensStudyPopIDs", replace
drop if exclmain==1
drop exclmain
save "$datadir\StudyPopIDs", replace