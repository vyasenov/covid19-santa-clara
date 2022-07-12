clear all
set more off

************
************ LOAD & CLEAN DATA
************

import delimited "https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"

keep if state == "California"

/* clean up date variable */
gen day = date(date, "YMD")
format day %td

/* generate new cases and deaths */
sort county day
by county: gen cases_new = cases - cases[_n-1]
by county: gen deaths_new = deaths - deaths[_n-1]

encode county, gen(cnty)
xtset cnty day

* GENERATE MOVING AVERAGES

tssmooth ma cases_new_ma = cases_new, window(3 1 3)
tssmooth ma deaths_new_ma = deaths_new, window(3 1 3)

order date day county cnty state fips cases* deaths*

* GENERATE BAY AREA DUMMY

gen bay_area = inlist(county, "Santa Clara", "San Mateo", "San Francisco", "Alameda", "Napa", "Contra Costa", "Marin", "Solano", "Sonoma")
tab county if bay_area == 1

gen month = mofd(day)
format month %tm
*keep if month >= 732

**************
************** AGGREGATE & PLOT: CALIFORNIA
**************

preserve 
collapse (sum) cases_new deaths_new, by(day)

tsset day

tssmooth ma cases_new_ma = cases_new, window(3 1 3)
tssmooth ma deaths_new_ma = deaths_new, window(3 1 3)

* NEW CASES
twoway (bar cases_new day, color(gs11)) ///
	(line cases_new_ma day, lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Cases") ///
	title("New Daily Cases in California") ///
	name(fiv, replace)

* NEW DEATHS
twoway (bar deaths_new day, color(gs11)) ///
	(line deaths_new_ma day, lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Deaths") ///
	title("New Daily Deaths in California")	///
	name(six, replace)
restore

graph combine fiv six, imargin(small) 

**************
************** AGGREGATE & PLOT: BAY AREA
**************	

* NEW CASES
preserve
collapse (sum) cases_new deaths_new if bay_area == 1, by(day)

tsset day

tssmooth ma cases_new_ma = cases_new, window(3 1 3)
tssmooth ma deaths_new_ma = deaths_new, window(3 1 3)

keep if cases_new >= 0

twoway (bar cases_new day, color(gs11)) ///
	(line cases_new_ma day, lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Cases") ///
	title("New Daily Cases in the Bay Area")	///
	name(one, replace)

* NEW DEATHS	
twoway (bar deaths_new day, color(gs11)) ///
	(line deaths_new_ma day, lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Deaths") ///
	title("New Daily Deaths in the Bay Area")	///
	name(two, replace)	
restore

graph combine one two, imargin(small) 

**************
************** AGGREGATE & PLOT: SANTA CLARA
************** 	

* NEW CASES
twoway (bar cases_new day if county == "Santa Clara", color(gs11)) ///
	(line cases_new_ma day if county == "Santa Clara", lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Cases") ///
	title("New Daily Cases in Santa Clara County")	///
	name(thr, replace)
	
* NEW DEATHS
twoway (bar deaths_new day if county == "Santa Clara", color(gs11)) ///
	(line deaths_new_ma day if county == "Santa Clara", lwidth(thick)), ///
	legend(off) ///
	xtitle("") ///
	ytitle("Number of Deaths") ///
	title("New Daily Deaths in Santa Clara County")	///
	name(fou, replace)

graph combine thr fou, imargin(small) 
