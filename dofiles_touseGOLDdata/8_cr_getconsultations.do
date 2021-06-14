/*=========================================================================

AUTHOR:					Jennifer Davidson
DATE:					26/05/2020

STUDY:					PhD Study 1 - risk of MACE by CVD risk level

PURPOSE:				Identify Gold study population covariates

DATASETS USED:			Denom_SensStudyPop.dta

NEXT STEPS:				9_cr_getatrialfibrillation
						
*=========================================================================*/

**USE CONSULTATION DATASET
use "$rawdatadir\Consultation_extract_ari_cvd_1.dta", clear
keep patid eventdate constype
rename eventdate cons_date
drop if cons_date==.

**REMOVE CONSULTATION TYPES NOT WANTED
tab constype
/* The codes below are excluded consultation types (ie not a in-person or telephone consultation)	
	0	Data Not Entered
	5	Mail from patient
	10	Telephone call from a patient
	12	Discharge details
	13	Letter from Outpatients
	14	Repeat Issue
	15	Other
	16	Results recording
	17	Mail to patient
	19	Administration
	20	Casualty Attendance
	23	Hospital Admission
	24	Children's Home Visit
	25	Day Case Report
	26	GOS18 Report
	29	NHS Direct Report
	38	Minor Injury Service
	39	Medicine Management
	40	Community Clinic
	41	Community Nursing Note
	42	Community Nursing Report
	43	Data Transferred from other system
	44	Health Authority Entry
	45	Health Visitor Note
	46	Health Visitor Report
	47	Hospital Inpatient Report
	48	Initial Post Discharge Review
	49	Laboratory Request
	51	Radiology Request
	52	Radiology Result
	53	Referral Letter
	54	Social Services Report
	56	Template Entry
	57	GP to GP communication transaction
	58	Non-consultation medication data
	59	Non-consultation data
	60	ePharmacy message
	
The codes below are included consultation types
	1	Clinic
	2	Night visit, Deputising service
	3	Follow-up/routine visit
	4	Night visit, Local rota
	6	Night visit, practice
	7	Out of hours, Practice
	8	Out of hours, Non Practice
	9	Surgery consultation
	11	Acute visit
	18	Emergency Consultation
	21	Telephone call to a patient
	22	Third Party Consultation
	27	Home Visit
	28	Hotel Visit
	30	Nursing Home Visit
	31	Residential Home Visit
	32	Twilight Visit
	33	Triage
	34	Walk-in Centre
	35	Co-op Telephone advice
	36	Co-op Surgery Consultation
	37	Co-op Home Visit
	50	Night Visit
	55	Telephone Consultation
	61	Extended Hours*/

foreach x in 0 5 10 12 13 14 15 16 17 19 20 23 24 25 26 29 38 39 40 41 42 43 44 45 46 47 48 49 51 52 53 54 56 57 58 59 60 {
drop if constype==`x'
}

**DROP DUPLICATES (WHERE RECORDED ON THE SAME DATE)
drop constype
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
sort patid cons_date

**CONSULTATIONS IN THE YEAR PRIOR TO BASELINE
gen cons_priorb=1 if (studystartdate-cons_date)<366 & (studystartdate-cons_date)>=0
by patid: egen cons_countpriorb=count(cons_priorb)
drop cons_date cons_priorb
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
