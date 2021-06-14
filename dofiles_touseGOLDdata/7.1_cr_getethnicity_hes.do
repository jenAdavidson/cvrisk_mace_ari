/*==============================================================================

AUTHOR:					Jennifer Davidson
DATE:					26/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population covariates

DATASETS USED:			Denom_SensStudyPop.dta

NEXT STEPS:				7.2_getethnicity_cprd

==============================================================================*/

use "$datadir\hes_ethnicity", clear

**KEEP VARIABLES FOR ETHNICITY
tab gen_ethnicity

**Ethnicity in 5 categories
gen heseth5=0 if gen_ethnicity=="White"
replace heseth5=1 if gen_ethnicity=="Indian" | gen_ethnicity=="Pakistani" | gen_ethnicity=="Oth_Asian"| gen_ethnicity=="Bangladesi"
replace heseth5=2 if gen_ethnicity=="Bl_Afric" | gen_ethnicity=="Bl_Carib" | gen_ethnicity=="Bl_Other"
replace heseth5=3 if gen_ethnicity=="Other" | gen_ethnicity=="Chinese"
replace heseth5=4 if gen_ethnicity=="Mixed"
replace heseth5=5 if gen_ethnicity=="Unknown"
tab heseth5 gen_ethnicity, missing

label define heseth5 0 "White" 1 "South Asian" 2 "Black" 3 "Other" 4 "Mixed" 5 "Not Stated"
label values heseth5 heseth5
tab gen_ethnicity heseth5

gen heseth16=.
replace heseth16=8 if gen_ethnicity=="Indian"
replace heseth16=9 if gen_ethnicity=="Pakistani"
replace heseth16=10 if gen_ethnicity=="Bangladesi"
replace heseth16=11 if gen_ethnicity=="Oth_Asian"
replace heseth16=12 if gen_ethnicity=="Bl_Carib"
replace heseth16=13 if gen_ethnicity=="Bl_Afric"
replace heseth16=14 if gen_ethnicity=="Bl_Other"
replace heseth16=15 if gen_ethnicity=="Chinese"
replace heseth16=16 if gen_ethnicity=="Other"
replace heseth16=17 if gen_ethnicity=="Unknown"
replace heseth16=18 if gen_ethnicity=="White"
replace heseth16=19 if gen_ethnicity=="Mixed"

label define heseth16 8 "Indian" 9 "Pakistani" 10 "Bangladeshi" 11 "Other Asian" 12 "Caribbean" 13 "African" 14 "Other Black" 15 "Chinese" 16 "Other ethnic group" 17 "Unknown" 18 "White" 19 "Mixed"
label values heseth16 heseth16
tab heseth16

save "$datadir\ethnicity_hes", replace
