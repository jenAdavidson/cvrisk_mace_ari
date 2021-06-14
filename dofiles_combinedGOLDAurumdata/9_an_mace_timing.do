
////////////////
//MACE OUTCOME//
////////////////

local cvrisk hypertens qrisk
local exposure ari ari_flu ari_pneumo


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

egen newid = group(patid2)

replace endfudate_mace=endfudate_mace+1 if indexdate==endfudate_mace

gen `infect'_days=endfudate_mace-indexdate


tabstat `infect'_days if mace==1, by(`risk') stat(p25 p50 p75)
histogram `infect'_days if mace==1, frequency by(`risk', note("") graphregion(color(white))) bin(18) scheme(s1mono) xtitle(Number of days between infection and outcome) ytitle(Number of patients) ylabel(, angle(45))
graph save "$outputdir\mace_after_ari\graph_hist_`infect'_`risk'", replace
graph hbox `infect'_days, by(`risk', note("") graphregion(color(white))) ytitle(Number of days between infection and outcome)
graph save "$outputdir\mace_after_ari\graph_box_`infect'_`risk'", replace


recode `infect'_days (1/3=1 "1-3 days") (4/7=2 "4-7 days") (8/14=3 "8-14 days") (15/28=4 "15-28 days") (29/91=5 "29-91 days") (92/max=6 "92+ days"), gen(`infect'_days_grp) label(period)

recode `infect'_days (1/7=1 "1-7 days") (8/28=2 "8-28 days") (29/91=3 "29-91 days") (92/max=4 "92+ days"), gen(`infect'_days_grp2) label(period2)


stset endfudate_mace, fail(mace==1) origin(time indexdate) enter(time indexdate) id(newid) scale(365.25)

log using "$logdir/StudyPop_`infect'_`risk'_timingtomace.log", replace

tab `infect'_days_grp `risk'
tab `infect'_days_grp `risk' if mace==1

tab `infect'_days_grp2 `risk'
tab `infect'_days_grp2 `risk' if mace==1

levelsof `infect'_days_grp, local(group)
foreach value of local group {

*file for model development
cap file close textfile 
noi file open textfile using "$outputdir/mace_after_ari/StudyPop_`infect'_`risk'_timingtomace`value'.csv", write replace
noi file write textfile "sep=;" _n
noi file write textfile "Effect of `risk' on MACE after `infect'" _n _n

*crude
stcox i.`risk' if `infect'_days_grp==`value', vce(cluster newid) base
local hr_cru=exp(_b[1.`risk'])
local lci_cru=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_cru=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Crude HR (95% CI)" ";" %3.2f (`hr_cru') " (" %3.2f (`lci_cru') "-" %3.2f (`uci_cru') ")" _n 

if riskgroup=="hypertens" {

*age & sex adjusted
stcox i.`risk' i.gender if `infect'_days_grp==`value', vce(cluster newid) base 
local hr_agesex=exp(_b[1.`risk'])
local lci_agesex=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_agesex=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted HR (95% CI)" ";" %3.2f (`hr_agesex') " (" %3.2f (`lci_agesex') "-" %3.2f (`uci_agesex') ")" _n 

*fully-adjusted
stcox i.`risk' i.gender i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus if `infect'_days_grp==`value', vce(cluster newid) base 
local hr_full=exp(_b[1.`risk'])
local lci_full=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_full=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Fully-adjusted HR (95% CI)" ";" %3.2f (`hr_full') " (" %3.2f (`lci_full') "-" %3.2f (`uci_full') ")" _n

}

else {

stcox i.`risk' i.alchigh if `infect'_days_grp==`value', vce(cluster newid) base
local hr_alc=exp(_b[1.`risk'])
local lci_alc=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_alc=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Excess alcohol HR (95% CI)" ";" %3.2f (`hr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 

}

capture file close textfile 
}

levelsof `infect'_days_grp2, local(group2)
foreach value of local group2 {

*file for model development
cap file close textfile 
noi file open textfile using "$outputdir/mace_after_ari/StudyPop_`infect'_`risk'_timingtomaceredo`value'.csv", write replace
noi file write textfile "sep=;" _n
noi file write textfile "Effect of `risk' on MACE after `infect'" _n _n

*crude
stcox i.`risk' if `infect'_days_grp2==`value', vce(cluster newid) base
local hr_cru=exp(_b[1.`risk'])
local lci_cru=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_cru=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Crude HR (95% CI)" ";" %3.2f (`hr_cru') " (" %3.2f (`lci_cru') "-" %3.2f (`uci_cru') ")" _n 

if riskgroup=="hypertens" {

*age & sex adjusted
stcox i.`risk' i.gender if `infect'_days_grp2==`value', vce(cluster newid) base 
local hr_agesex=exp(_b[1.`risk'])
local lci_agesex=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_agesex=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Age sex-adjusted HR (95% CI)" ";" %3.2f (`hr_agesex') " (" %3.2f (`lci_agesex') "-" %3.2f (`uci_agesex') ")" _n 

*fully-adjusted
stcox i.`risk' i.gender i.eth5 i.townsend2001_5 i.bmipriorstatus i.alchigh i.smokstatus if `infect'_days_grp2==`value', vce(cluster newid) base 
local hr_full=exp(_b[1.`risk'])
local lci_full=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_full=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Fully-adjusted HR (95% CI)" ";" %3.2f (`hr_full') " (" %3.2f (`lci_full') "-" %3.2f (`uci_full') ")" _n

}

else {

stcox i.`risk' i.alchigh if `infect'_days_grp2==`value', vce(cluster newid) base
local hr_alc=exp(_b[1.`risk'])
local lci_alc=exp(_b[1.`risk']-1.96*_se[1.`risk']) 
local uci_alc=exp(_b[1.`risk']+1.96*_se[1.`risk'])	
noi file write textfile "Excess alcohol HR (95% CI)" ";" %3.2f (`hr_alc') " (" %3.2f (`lci_alc') "-" %3.2f (`uci_alc') ")" _n 

}

capture file close textfile 
}
log close

}
}



