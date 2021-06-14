////////////////
//MACE OUTCOME//
////////////////


local cvrisk hypertens qrisk
local exposure ari ari_pneumo ari_flu
local outcome mace macesevere mi angina acs hf ali stroke tia stroketia cvddeath

foreach risk of local cvrisk {
foreach infect of local exposure {

use "$datadir/StudyPop_`infect'_mace_`risk'_gold", clear
append using "$datadir/StudyPop_`infect'_mace_`risk'_aurum"

gen riskgroup = "`risk'"

replace gender=. if gender==3
merge m:1 patid2 using "$datadir/StudyPop_smoking", nogen keep (master match)
merge m:1 patid2 using "$datadir/StudyPop_alcohol", nogen keep (master match)
merge m:1 patid2 using "$datadir/ethnicity_final", nogen keep (master match) keepusing(eth5)
replace eth5=. if eth5==5
merge m:1 patid2 using "$datadir/townsend2001", nogen keep (master match) keepusing(townsend2001_5)

local explanatory2 fluvacc ppvvacc

foreach covariate2 of local explanatory2 {
merge m:1 patid2 indexdate using "$datadir/StudyPop_`infect'_mace_`covariate2'", nogen keep (master match) keepusing(`covariate2')
}

drop if fluvacc==1 | ppvvacc==1

egen newid = group(patid2)

replace endfudate_mace=endfudate_mace+1 if indexdate==endfudate_mace // gives 1 day follow up to those who enter and exit on the same date

foreach cond of local outcome {

stset endfudate_mace, fail(`cond'==1) origin(time indexdate) enter(time indexdate) id(newid) scale(365.25) // note those with MACE on earlier follow up will have further follow ups excluded. 

log using "$logdir/mace_after_ari/`infect'_`cond'_`risk'_excl.log", replace

strate `risk', per(1000) cluster(newid) output("$outputdir/mace_after_ari/output_StudyPop_`infect'_`cond'_`risk'_excl", replace)

*file for model development
cap file close textfile 
noi file open textfile using "$outputdir/mace_after_ari/StudyPop_`infect'_`cond'_`risk'_excl.csv", write replace
noi file write textfile "sep=;" _n
noi file write textfile "Effect of `risk' on `cond' after `infect'" _n _n

*crude
stcox i.`risk', vce(cluster newid) base
local hr_cru=exp(_b[1.`risk'])
local lci_cru=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_cru=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Crude HR (95% CI)" ";" %3.2f (`hr_cru') " (" %3.2f (`lci_cru') "-" %3.2f (`uci_cru') ")" _n 
est save "$datadir/mace_after_ari/StudyPop_`infect'_`cond'_`risk'_crude_excl"

if riskgroup=="hypertens" {

*age & sex adjusted
stcox i.`risk' i.gender, vce(cluster newid) base
local hr_agesex=exp(_b[1.`risk'])
local lci_agesex=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_agesex=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted HR (95% CI)" ";" %3.2f (`hr_agesex') " (" %3.2f (`lci_agesex') "-" %3.2f (`uci_agesex') ")" _n 
est save "$datadir/mace_after_ari/StudyPop_`infect'_`cond'_`risk'_agesex_excl"

*"univariable"
stcox i.`risk' i.gender i.eth5, vce(cluster newid) base
local hr_eth=exp(_b[1.`risk'])
local lci_eth=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_eth=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted + ethnicity HR (95% CI)" ";" %3.2f (`hr_eth') " (" %3.2f (`lci_eth') "-" %3.2f (`uci_eth') ")" _n 

stcox i.`risk' i.gender i.townsend2001_5, vce(cluster newid) base
local hr_ses=exp(_b[1.`risk'])
local lci_ses=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_ses=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted + SES HR (95% CI)" ";" %3.2f (`hr_ses') " (" %3.2f (`lci_ses') "-" %3.2f (`uci_ses') ")" _n 

stcox i.`risk' i.gender i.bmipriorstatus, vce(cluster newid) base
local hr_bmi=exp(_b[1.`risk'])
local lci_bmi=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_bmi=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted + BMI HR (95% CI)" ";" %3.2f (`hr_bmi') " (" %3.2f (`lci_bmi') "-" %3.2f (`uci_bmi') ")" _n 

stcox i.`risk' i.gender i.alchigh, vce(cluster newid) base
local hr_alc=exp(_b[1.`risk'])
local lci_alc=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_alc=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted + excess alcohol HR (95% CI)" ";" %3.2f (`hr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 

stcox i.`risk' i.gender i.smokstatus, vce(cluster newid) base
local hr_smok=exp(_b[1.`risk'])
local lci_smok=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_smok=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted + smoking HR (95% CI)" ";" %3.2f (`hr_smok') " (" %3.2f (`lci_smok') "-" %3.2f (`uci_smok') ")" _n 

*fully-adjusted
stcox i.`risk' i.gender i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus, vce(cluster newid) base 
local hr_full=exp(_b[1.`risk'])
local lci_full=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_full=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Fully-adjusted HR (95% CI)" ";" %3.2f (`hr_full') " (" %3.2f (`lci_full') "-" %3.2f (`uci_full') ")" _n
est save "$datadir/mace_after_ari/StudyPop_`infect'_`cond'_`risk'_full_excl"

}

else {

stcox i.`risk' i.alchigh, vce(cluster newid) base
local hr_alc=exp(_b[1.`risk'])
local lci_alc=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_alc=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Excess alcohol HR (95% CI)" ";" %3.2f (`hr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 
est save "$datadir/mace_after_ari/StudyPop_`infect'_`cond'_`risk'_full_excl"

}

capture file close textfile 

log close

}
}
}
