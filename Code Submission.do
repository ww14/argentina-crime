************** WWS508c PS5 *************
*  Spring 2018			                      *
*  Author: William Willoughby          *
*  Email: ww14@princeton.edu           *
****************************************

**Housekeeping
clear all
cd "D:\ps5"
set more off
ssc install outreg2

**Create log
capture log close
log using argentinacrime.log, replace

**Open dataset
use "wws508c_crime_ps5.dta", clear

********************************************************************************
**                                   Section 1                                **
********************************************************************************

*Summarize variables
tab birthyr, missing

sum  
sum, det 

sum conscripted
sum crimerate
sum property
sum murder
sum drug
sum sexual
sum threat
sum arms
sum whitecollar
sum argentine
sum indigenous
sum naturalized

*Take a look at crime and conscription rates by birth year
sort birthyr
tab birthyr, sum(crimerate)
tab birthyr, sum(conscripted)


/*Crime rates look close to an untrained eye.
People born in 1958 seem much more likely to get conscripted,
especially compared to 1959-60.*/

**Comparisons of means
mvtest means crimerate, by(birthyr) heterogeneous
mvtest means conscripted, by(birthyr) heterogeneous

/*Crime rates and conscription rates differ by birth year, especially 
conscription rates.*/


********************************************************************************
**                                   Section 2                                **
********************************************************************************

*Run regresssions of conscripted on crimes w/controls and birthyear FE
xtreg crimerate conscripted argentine indigenous naturalized, i(birthyr) fe robust
 outreg2 using s2reg.xls, ///
 label tex(fragment pretty) ctitle(crimerate) addtext(Birth Year FE, YES) replace

foreach var of varlist property murder drug sexual threat arms whitecollar{
xtreg `var' conscripted argentine indigenous naturalized, i(birthyr) fe robust
 outreg2 using s2reg.xls, ///
 label tex(fragment pretty) ctitle(`var') addtext(Birth Year FE, YES) append
}

/* Exempted young men are likely correlated with omitted variables.
For example, wealthier men may be work the system and claim medical excuses or 
that family members are dependent upon them.
Those going into religious service may differ in their likelihood later in life.

Because of timing of data, we are only looking at crimes committed later in 
life (ages 38-47),which may be more likely to be white collar crime and less 
likely to be 'crimes of passion'
*/

********************************************************************************
**                                   Section 3                                **
********************************************************************************

**Generate binary variable for eligibility
gen eligible=0
replace eligible=1 if (draftnumber>=175 & birthyr==1958)
replace eligible=1 if (draftnumber>=320 & birthyr==1959)
replace eligible=1 if (draftnumber>=341 & birthyr==1960)
replace eligible=1 if (draftnumber>=350 & birthyr==1961)
replace eligible=1 if (draftnumber>=320 & birthyr==1962)

**Regress conscription on eligibility (first stage)
reg conscripted eligible, r
 outreg2 using fsreg.xls, ///
 label tex(fragment pretty) ctitle(No Controls) replace

reg conscripted eligible argentine indigenous naturalized, r
 outreg2 using fsreg.xls, ///
 label tex(fragment pretty) ctitle(Controls)  append

xtreg conscripted eligible argentine indigenous naturalized, i(birthyr) fe robust
 outreg2 using fsreg.xls, ///
 label tex(fragment pretty) ctitle(Controls) addtext(Birth Year FE, YES) append

/*
Shouldn't need to incude ethnic compostion because eligibility random by year.
However, eligibility differs by birth year so we think should include birth year.

Coefficient doesn't change when including either.

Thinking ahead to 2SLS, instrument should be unrelated to any variables that 
affect crime rate if it is going to be a valid instrument.
Promising that coefficent doesn't change; seems to confirm instrument exogeneity
condition/exclusion restriction.
However, because eligibility differs by birth year, exclusion restriction 
may not hold if birth year affects crime rates

For now, we are going to include birth year and not ethnic composition.

Instead of completing a first stage-reduced form IV estimate, proceed with 2SLS
Run 2SLS 
*/

*Generate dummy for birthyr
forvalues i=1958(1)1962 {
 gen b`i'= 0
 replace b`i'=1 if birthyr==`i'
}

*Run 2SLS
ivregress 2sls crimerate (conscripted = eligible) argentine indigenous ///
 naturalized b1962 b1961 b1960 b1959, r
 outreg2 using 2slsreg.xls,  replace

foreach var of varlist property murder drug sexual threat arms whitecollar{
 ivregress 2sls `var' (conscripted = eligible) argentine indigenous ///
 naturalized b1962 b1961 b1960 b1959, r
 outreg2 using 2slsreg.xls, append
}


cap log close 


 
 
