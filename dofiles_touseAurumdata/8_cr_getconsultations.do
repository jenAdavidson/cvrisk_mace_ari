/*=========================================================================

AUTHOR:					Jennifer Davidson
DATE:					05/10/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Aurum study population covariates

DATASETS USED:			Denom_SensStudyPop.dta

NEXT STEPS:				9_cr_getatrialfibrillation
						
*=========================================================================*/

**USE CONSULTATION DATASET

forvalues x=1/9 {
use "$rawdatadir\ari_cvd_extract_consultation_`x'_1", clear
append using "$rawdatadir\ari_cvd_extract_consultation_`x'_2"
keep patid consid consdate conssourceid consmedcodeid
drop if consdate==""
drop if conssourceid==""
*see $codelistdir/ConsultationCodes_cwg for codes kept & not kept (list too long to include here)
foreach p in 41 44 79 83 85 90 99 102 229 306 364 366 390 392 397 422 423 424 425 426 427 428 429 435 476 527 666 931 1006 1018 1048 1081 1119 1127 1170 1261 1292 1293 1304 1463  1508 1561 1678 1679 1712 1727 1717 1734 1736 1945 1956 1981 1986 1988 1992 2027 2174 2324 2355 2390 2395 2447 2448 2469 2534 2561 2563 2564 2627 2630 2810 2823 2915 2917 3016 3051 3086 3111 3175 3208 3215 3218 3221 3305 3316 3318 3338 3339 3346 3347 3352 3421 3463 3483 3488 3489 3490 3491 3492 3493 3494 3495 3500 3515 3551 3585 3586 3587 3588 3589 3590 3591 3614 3615 3616 3617 3618 3630 3634 3648 3649 3650 3651 3652 3653 3654 3655 3656 3657 3658 3659 3660 3661 3662 3663 3664 3665 3666 3712 3731 3938 4031 4043 4071 4387 4813 4815 4898 4959 4998 5072 5105 5112 5155 5191 5464 5484 5517 5580 5673 5675 5759 5885 5898 6022 6030 6031 6032 6033 6034 6052 6056 6062 6063 6064 6065 6066 6096 6157 6159 6160 6161 6173 6207 6297 6338 6339 6354 6370 6488 6641 6727 6728 6731 6913 7240 7395 7406 7413 7424 7435 7514 7533 7570 7571 7573 7924 7980 7985 8012 8155 8358 8366 8373 8400 8465 8466 8467 8468 8469 8470 8471 8472 8473 8488 8503 8504 8505 8506 8539 8602 8669 8703 8763 8764 8765 8766 8767 8768 8779 8794 8795 8796 8839 8878 8917 8933 9060 9061 9066 9201 9218 9417 9498 9555 9766 9815 9819 9824 9831 9877 9901 9993 10014 10028 10116 10118 10125 10131 10359 10493 15106 16305 47617 53390 53424 {
drop if conssourceid=="`p'"
}
tempfile cons_`x'
save `cons_`x'', replace	
	}

use `cons_1', clear	
forvalues x=2/9 {
	append using `cons_`x''
	}

merge m:1 conssourceid using "$datadir/ConsSource_Lookup", keep(master match) nogen	
drop if description=="Awaiting review"


**DROP DUPLICATES (WHERE RECORDED ON THE SAME DATE)
drop conssourceid description
duplicates drop

**SAVE A TEMPORARY DATASET
tempfile consultations
save `consultations'


**************************************
**STUDY POPULATION CONSULTATION RATE**
**************************************

**MERGE WITH STUDY POPULATION DATASET
use $datadir/SensStudyPop.dta, clear
keep patid studystartdate exclmain
merge 1:m patid using `consultations', keep(match master) nogen
sort patid consdate

**CONSULTATIONS IN THE YEAR PRIOR TO BASELINE
gen consdate2=date(consdate, "DMY")
format consdate2 %td
drop consdate
rename consdate2 consdate
gen cons_priorb=1 if (studystartdate-consdate)<366 & (studystartdate-consdate)>=0
by patid: egen cons_countpriorb=count(cons_priorb)
drop consdate cons_priorb consid
duplicates drop
label var cons_countpriorb "Number of consultations in the year prior to baseline"
gen cons_catpriorb = cons_countpriorb
recode cons_catpriorb 0/4=0 5/9=1 10/19=2 20/max=3 
label define cons_cat 0 "0-4" 1 "5-9" 2 "10-19" 3 "20+"  
label values cons_catpriorb cons_cat
label var cons_catpriorb "Grouped number of consultations in the year prior to baseline"


**SAVE
save $datadir/SensStudyPop_cons.dta, replace

drop if exclmain==1
drop exclmain
save $datadir/StudyPop_cons.dta, replace
