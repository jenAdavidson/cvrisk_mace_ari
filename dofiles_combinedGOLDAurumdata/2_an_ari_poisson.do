
///////////////////////////////////////
//ACUTE RESPIRATORY INFECTION OUTCOME//
///////////////////////////////////////

local cvrisk hypertens qrisk 
local outcome ari ari_pneumo ari_flu
local denom StudyPop SensStudyPop

preserve
use "$golddir/ethnicity_final", clear
tostring patid, replace
gen patid2=patid+"G"
append using "$aurumdir/ethnicity_final"
replace patid2=patid+"A" if patid2==""
save "$datadir/ethnicity_final", replace
restore

preserve
use "$golddir/townsend2001", clear
tostring patid, replace
gen patid2=patid+"G"
append using "$aurumdir/townsend2001"
replace patid2=patid+"A" if patid2==""
save "$datadir/townsend2001", replace
restore

foreach pop of local denom {

preserve
use "$golddir/`pop'_smoking", clear
tostring patid, replace
gen patid2=patid+"G"
append using "$aurumdir/`pop'_smoking"
replace patid2=patid+"A" if patid2==""
save "$datadir/`pop'_smoking", replace
restore

preserve
use "$golddir/`pop'_alcohol", clear
tostring patid, replace
gen patid2=patid+"G"
append using "$aurumdir/`pop'_alcohol"
replace patid2=patid+"A" if patid2==""
gen alchigh=1 if alclevel==3
replace alchigh=0 if alcstatus!=. & alchigh==.
label define alchigh 0 "not high" 1 "high"
label values alchigh alchigh
save "$datadir/`pop'_alcohol", replace
restore

preserve
use "$golddir/`pop'_cons", clear
tostring patid, replace
gen patid2=patid+"G"
append using "$aurumdir/`pop'_cons"
replace patid2=patid+"A" if patid2==""
save "$datadir/`pop'_cons", replace
restore
*/
foreach cond of local outcome {
foreach risk of local cvrisk {
use "$datadir/`pop'_`cond'_`risk'_poisson_gold", clear
append using "$datadir/`pop'_`cond'_`risk'_poisson_aurum"
sort patid startdate_`cond'

gen riskgroup = "`risk'"

replace gender=. if gender==3
merge m:1 patid2 using "$datadir/`pop'_smoking", nogen keep (master match)
merge m:1 patid2 using "$datadir/`pop'_alcohol", nogen keep (master match)
merge m:1 patid2 using "$datadir/ethnicity_final", nogen keep (master match) keepusing(eth5)
replace eth5=. if eth5==5
merge m:1 patid2 using "$datadir/townsend2001", nogen keep (master match) keepusing(townsend2001_5)
merge m:1 patid2 using "$datadir/`pop'_cons", nogen keep (master match) keepusing(cons_catpriorb)

egen newid = group(patid2)

*stsplit by age group
stset endfudate_`cond', fail(`cond'==1) origin(time dob) enter(time startdate_`cond') exit(time .) id(newid) scale(365.25)
assert _st!=0
stsplit curragegrp, at(40(5)65)

*stsplit by cv risk
stset endfudate_`cond', fail(`cond'==1) origin(time `risk'date) enter(time startdate_`cond') exit(time .) id(newid) scale(365.25)
*assert _st!=0 - only those with hypertension before/during follow-up will be included for this split, which is fine as is not the final set for analysis 
stsplit _`risk', at(0.001) 
gen `cond'`risk'=0 if _`risk'==0 | _`risk'==.
replace `cond'`risk'=1 if `cond'`risk'!=0
label values `cond'`risk' `risk'

*final set for calendar time
stset endfudate_`cond', fail(`cond'==1) origin(time startdate_`cond') enter(time startdate_`cond') exit(time .) id(newid) scale(365.25) 
assert _st!=0

gen time=_t-_t0 // need this as cannot use stset with xtpois & need xtpois as panel data
assert time!=.

log using "$logdir/ari/`pop'_`cond'_`risk'.log", replace

*file for model development
cap file close textfile 
noi file open textfile using "$outputdir/ari/`pop'_`cond'`risk'_poisson.csv", write replace
noi file write textfile "sep=;" _n
noi file write textfile "Effect of `risk' on `cond'" _n _n

*crude
xtpois _d i.`cond'`risk', re e(time) i(newid) irr base
local irr_cru=exp(_b[1.`cond'`risk'])
local lci_cru=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_cru=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Crude IRR (95% CI)" ";" %3.2f (`irr_cru') " (" %3.2f (`lci_cru') "-" %3.2f (`uci_cru') ")" _n 
est save "$datadir/ari/`pop'_`cond'`risk'_crude"

if riskgroup=="hypertens" {

*age & sex adjusted
xtpois _d i.`cond'`risk' i.currage i.gender, re e(time) i(newid) irr base
local irr_agesex=exp(_b[1.`cond'`risk'])
local lci_agesex=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_agesex=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted IRR (95% CI)" ";" %3.2f (`irr_agesex') " (" %3.2f (`lci_agesex') "-" %3.2f (`uci_agesex') ")" _n 
est save "$datadir/ari/`pop'_`cond'`risk'_agesex"
estat ic

*"univariable"
xtpois _d i.`cond'`risk' i.currage i.gender i.eth5, re e(time) i(newid) irr base
local irr_eth=exp(_b[1.`cond'`risk'])
local lci_eth=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_eth=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + ethnicity IRR (95% CI)" ";" %3.2f (`irr_eth') " (" %3.2f (`lci_eth') "-" %3.2f (`uci_eth') ")" _n 

xtpois _d i.`cond'`risk' i.currage i.gender i.townsend2001_5, re e(time) i(newid) irr base
local irr_ses=exp(_b[1.`cond'`risk'])
local lci_ses=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_ses=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + SES IRR (95% CI)" ";" %3.2f (`irr_ses') " (" %3.2f (`lci_ses') "-" %3.2f (`uci_ses') ")" _n 

xtpois _d i.`cond'`risk' i.currage i.gender i.bmipriorstatus, re e(time) i(newid) irr base
local irr_bmi=exp(_b[1.`cond'`risk'])
local lci_bmi=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_bmi=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + BMI IRR (95% CI)" ";" %3.2f (`irr_bmi') " (" %3.2f (`lci_bmi') "-" %3.2f (`uci_bmi') ")" _n 

xtpois _d i.`cond'`risk' i.currage i.gender i.alchigh, re e(time) i(newid) irr base
local irr_alc=exp(_b[1.`cond'`risk'])
local lci_alc=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_alc=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + excess alcohol IRR (95% CI)" ";" %3.2f (`irr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 

xtpois _d i.`cond'`risk' i.currage i.gender i.smokstatus, re e(time) i(newid) irr base
local irr_smok=exp(_b[1.`cond'`risk'])
local lci_smok=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_smok=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + smoking IRR (95% CI)" ";" %3.2f (`irr_smok') " (" %3.2f (`lci_smok') "-" %3.2f (`uci_smok') ")" _n 

xtpois _d i.`cond'`risk' i.currage i.gender i.cons_catpriorb, re e(time) i(newid) irr base
local irr_confreq=exp(_b[1.`cond'`risk'])
local lci_confreq=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_confreq=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Age sex-adjusted + cons freq IRR (95% CI)" ";" %3.2f (`irr_confreq') " (" %3.2f (`lci_confreq') "-" %3.2f (`uci_confreq') ")" _n 

*minimally-adjusted
xtpois _d i.`cond'`risk' i.gender i.currage i.cons_catpriorb i.eth5, re e(time) i(newid) irr base
local irr_min=exp(_b[1.`cond'`risk'])
local lci_min=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_min=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Minimally-adjusted IRR (95% CI)" ";" %3.2f (`irr_min') " (" %3.2f (`lci_min') "-" %3.2f (`uci_min') ")" _n

*fully-adjusted
xtpois _d i.`cond'`risk' i.gender i.currage i.cons_catpriorb i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus, re e(time) i(newid) irr base 
local irr_full=exp(_b[1.`cond'`risk'])
local lci_full=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_full=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Fully-adjusted IRR (95% CI)" ";" %3.2f (`irr_full') " (" %3.2f (`lci_full') "-" %3.2f (`uci_full') ")" _n
est save "$datadir/ari/`pop'_`cond'`risk'_full"
estat ic

xtpois _d i.`cond'`risk' i.gender i.currage i.cons_catpriorb i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus, re e(time) i(newid) irr base 
est store a
xtpois _d i.gender i.currage i.cons_catpriorb i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus, re e(time) i(newid) irr base 
est store b
lrtest a b

}

else {

xtpois _d i.`cond'`risk' i.alchigh, re e(time) i(newid) irr base
local irr_alc=exp(_b[1.`cond'`risk'])
local lci_alc=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_alc=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Excess alcohol IRR (95% CI)" ";" %3.2f (`irr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 

xtpois _d i.`cond'`risk' i.cons_catpriorb, re e(time) i(newid) irr base
local irr_confreq=exp(_b[1.`cond'`risk'])
local lci_confreq=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_confreq=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Cons freq IRR (95% CI)" ";" %3.2f (`irr_confreq') " (" %3.2f (`lci_confreq') "-" %3.2f (`uci_confreq') ")" _n 

*fully-adjusted
xtpois _d i.`cond'`risk' i.cons_catpriorb i.alchigh, re e(time) i(newid) irr base 
local irr_full=exp(_b[1.`cond'`risk'])
local lci_full=exp(_b[1.`cond'`risk']-1.96*_se[1.`cond'`risk']) 
local uci_full=exp(_b[1.`cond'`risk']+1.96*_se[1.`cond'`risk'])	
noi file write textfile "Fully-adjusted IRR (95% CI)" ";" %3.2f (`irr_full') " (" %3.2f (`lci_full') "-" %3.2f (`uci_full') ")" _n
est save "$datadir/ari/`pop'_`cond'`risk'_full"
estat ic

xtpois _d i.`cond'`risk' i.cons_catpriorb i.alchigh, re e(time) i(newid) irr base 
est store a
xtpois _d i.cons_catpriorb i.alchigh, re e(time) i(newid) irr base 
est store b
lrtest a b

}

capture file close textfile 
log close
}
}
}

