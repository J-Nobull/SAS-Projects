
	/*TASK1 *** load new datafile @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
libname sasload '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 2';	
data donor_hw_load; set sasload.s_pml_donor_hw_v3; 
run;

	/* Question 1*/
data donor_hw_init; set donor_hw_load;
	base_date = '01AUG1998'd;    		/* Base date for the analysis */
    ENTRY_DATE = intnx('month', base_date, -MONTHS_SINCE_ORIGIN);
    FIRST_GIFT_DATE = intnx('month', base_date, -MONTHS_SINCE_FIRST_GIFT);
    LAST_GIFT_DATE = intnx('month', base_date, -MONTHS_SINCE_LAST_GIFT);
    format ENTRY_DATE FIRST_GIFT_DATE LAST_GIFT_DATE mmddyy10.; 
run;

	/*a. What is the date of the most recent file entry?  
	Sort dataset dates by smallest, but also ran freq on MONTHS_SINCE_xyz to verify 4 months is smallest*/
proc freq data=donor_hw_init; 
	tables MONTHS_SINCE_ORIGIN MONTHS_SINCE_FIRST_GIFT MONTHS_SINCE_LAST_GIFT / norow nocol nopercent; 
run;

	/*d. What is the median length of time (in months) between the first and last gift?*/
data donor_hw_init; set donor_hw_init;
    time_between_gifts = MONTHS_SINCE_FIRST_GIFT - MONTHS_SINCE_LAST_GIFT;
proc means data=donor_hw_init median;
    var time_between_gifts; run;
data donor_hw_imp; set donor_hw_init;
    drop time_between_gifts;
run;

	/*Question 2.a.*/
proc univariate data=donor_hw_init noprint;
    var ENTRY_DATE FIRST_GIFT_DATE;
    histogram ENTRY_DATE FIRST_GIFT_DATE;
    format ENTRY_DATE FIRST_GIFT_DATE year4.; 
run;

	/*b. to display irregularity*/
proc sgplot data=donor_hw_init;
	histogram FIRST_GIFT_DATE/transparency=.75;
	histogram ENTRY_DATE/transparency=.75;
run;

data donor_hw_init; set donor_hw_init;
    ENTRY_DATE_YEAR = year(ENTRY_DATE);
    FIRST_GIFT_DATE_YEAR = year(FIRST_GIFT_DATE);
    LAST_GIFT_DATE_YEAR = year(LAST_GIFT_DATE);
run;

	/*Question 3.a.*/
proc freq data=donor_hw_init; 
	tables ENTRY_DATE_YEAR / norow nocol nopercent;
    where ENTRY_DATE_YEAR = 1998;
run;

	/*b. Which year had the lowest mean LAST_GIFT_AMT?*/
proc means data=donor_hw_init mean;
    class LAST_GIFT_DATE_YEAR;
    var LAST_GIFT_AMT;
run;

	/*c. What was the mean LAST_GIFT_AMT?*/
proc means data=donor_hw_init mean; 
    var LAST_GIFT_AMT;
    where CLUSTER_CODE = 9 and LAST_GIFT_DATE_YEAR = 1997;
run;

	/*TASK2 *** Question 1 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
proc means data=donor_hw_init n nmiss min max mean std;
    var DONOR_AGE;
run;

	/*look at FREQ for missing, odd, low and high extreme values */
proc freq data=donor_hw_init;
    tables DONOR_AGE / missing norow nocol nopercent;
run;

	/* Histogram of Donor_Age */
proc sgplot data=donor_hw_init;
    histogram DONOR_AGE;
    density DONOR_AGE / type=normal;
    title "Distribution of DONOR_AGE with Normal Curve";
run;

	/* detect outliers */
proc univariate data=donor_hw_init;
    var DONOR_AGE;
    histogram DONOR_AGE / normal;
    inset n nmiss min mean median max std skewness kurtosis / position=ne;
run;

	/*Question 2*/
data donor_hw_filtered; set donor_hw_init;
	if missing(DONOR_AGE) or DONOR_AGE >= 18;
run;

	/* Create MV flag */
data donor_hw_imp; set donor_hw_filtered;
    if missing(DONOR_AGE) then flag_miss_age = 1;
    else flag_miss_age = 0;
	WORKING_AGE = DONOR_AGE;
run;
	
	/*will use donor_hw_imp for every step 1*/
	/* [0] Get observed values to compare to imputation methods */
	/* First, create imputation variable */

data imput_0; set donor_hw_imp;
	DONOR_AGE_OBS = DONOR_AGE;
run;

proc means data=imput_0 n nmiss min mean median max std; var DONOR_AGE_OBS; run;
proc sgplot data=imput_0; histogram DONOR_AGE_OBS; run;
proc corr data=imput_0; var DONOR_AGE_OBS; with MONTHS_SINCE_ORIGIN; 
run;

	/* [1] Single Mean Unconditional Imputation */
	/***** Step 1: Calculate the mean of non-missing DONOR_AGE */
data donor_hw_imp; set donor_hw_filtered; /*will use donor_hw_imp for every step 1*/
	WORKING_AGE = DONOR_AGE;
run;

data imput_1; set donor_hw_imp;
	IMP_AGE_MEAN = WORKING_AGE;
run;

	/***** Step 2 replace all MV with mean*/
data imput_1; set imput_1;
    if missing(IMP_AGE_MEAN) then IMP_AGE_MEAN = 59.587;
run;

	/***** Step 3 -- USE macro */
%let VFW_age = WORKING_AGE;
%let VFW_imputed = IMP_AGE_MEAN;
%let VFW_ds	= imput_1;

proc means data=&VFW_ds nmiss n min mean median max std; 
	var &VFW_age &VFW_imputed; run;
proc univariate data=&VFW_ds; var &VFW_age &VFW_imputed; 
	histogram &VFW_age &VFW_imputed; run;
proc sgplot data=&VFW_ds; 
	title "DONOR_AGE: Observed & Imputed (MEANS)";
	histogram &VFW_age / binwidth=5 transparency=.5 legendlabel="Observed Variable";
	histogram &VFW_imputed / binwidth=5 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&VFW_ds; title "DONOR_AGE BOXPLOT (Mean)";
	hbox &VFW_age / transparency=.5 legendlabel="Observed Variable"; 
	hbox &VFW_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&VFW_ds; var &VFW_age &VFW_imputed; with MONTHS_SINCE_ORIGIN ; 
run;

	/* [2] Hot-deck Conditional Imputation */
data imput_2; set donor_hw_imp;
    IMP_AGE_HOT = WORKING_AGE; run;
proc surveyimpute data=imput_2 seed=12345 method=hotdeck(selection=srswr);
    class IN_HOUSE PEP_STAR; 
    var IMP_AGE_HOT MONTHS_SINCE_ORIGIN LIFETIME_CARD_PROM LIFETIME_PROM MONTHS_SINCE_FIRST_GIFT; 
    output out=imput_2; 
run;

	/***** Step 3 -- USE macro */
%let VFW_age 	= WORKING_AGE;
%let VFW_imputed = IMP_AGE_HOT;
%let VFW_ds	= imput_2;

proc means data=&VFW_ds nmiss n min mean median max std; 
	var &VFW_age &VFW_imputed; run;
proc univariate data=&VFW_ds; var &VFW_age &VFW_imputed; 
	histogram &VFW_age &VFW_imputed; run;
proc sgplot data=&VFW_ds; 
	title "DONOR_AGE: Observed & Imputed (Hot-deck)";
	histogram &VFW_age / binwidth=5 transparency=.5 legendlabel="Observed Variable";
	histogram &VFW_imputed / binwidth=5 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&VFW_ds; title "DONOR_AGE BOXPLOT (Hot-deck)";
	hbox &VFW_age / transparency=.5 legendlabel="Observed Variable"; 
	hbox &VFW_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&VFW_ds; var &VFW_age &VFW_imputed; with MONTHS_SINCE_ORIGIN ; 
run;

	/*	[3] Single (Stochastic regression) imputation  */
data imput_3; set donor_hw_imp;
    IMP_AGE_STO = WORKING_AGE; run;
%let STO_vars = MONTHS_SINCE_ORIGIN IN_HOUSE PEP_STAR 
	LIFETIME_CARD_PROM LIFETIME_PROM MONTHS_SINCE_FIRST_GIFT;
proc mi data=imput_3 nimpute=1 seed=12345 out=imput_3;
	fcs nbiter=1;
	var IMP_AGE_STO &STO_vars; run;

	/***** Step 3 -- USE macro */
%let VFW_age 	= WORKING_AGE;
%let VFW_imputed = IMP_AGE_STO;
%let VFW_ds	= imput_3;

proc means data=&VFW_ds nmiss n min mean median max std; 
	var &VFW_age &VFW_imputed; run;
proc univariate data=&VFW_ds; var &VFW_age &VFW_imputed; 
	histogram &VFW_age &VFW_imputed; run;
proc sgplot data=&VFW_ds; 
	title "DONOR_AGE: Observed & Imputed (Stochastic)";
	histogram &VFW_age / binwidth=5 transparency=.5 legendlabel="Observed Variable";
	histogram &VFW_imputed / binwidth=5 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&VFW_ds; title "DONOR_AGE BOXPLOT (Stochastic)";
	hbox &VFW_age / transparency=.5 legendlabel="Observed Variable"; 
	hbox &VFW_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&VFW_ds; var &VFW_age &VFW_imputed; with MONTHS_SINCE_ORIGIN ; 
run;

	/*	[4] Single PMM imputation  */
data imput_4; set donor_hw_imp;
    IMP_AGE_PMM = WORKING_AGE; run;
%let PMM_vars = MONTHS_SINCE_ORIGIN IN_HOUSE PEP_STAR 
	LIFETIME_CARD_PROM LIFETIME_PROM MONTHS_SINCE_FIRST_GIFT;
proc mi data=imput_4 nimpute=1 seed=12345 out=imput_4;
	fcs regpmm(IMP_AGE_PMM = &PMM_vars);
	var IMP_AGE_PMM &PMM_vars; run;

	/***** Step 3 -- USE macro, **no univariate */
%let VFW_age 	= WORKING_AGE;
%let VFW_imputed = IMP_AGE_PMM;
%let VFW_ds	= imput_4;

proc means data=&VFW_ds nmiss n min mean median max std; 
	var &VFW_age &VFW_imputed; run;
proc sgplot data=&VFW_ds; 
	title "DONOR_AGE: Observed & Imputed (PMM)";
	histogram &VFW_age / binwidth=5 transparency=.5 legendlabel="Observed Variable";
	histogram &VFW_imputed / binwidth=5 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&VFW_ds; title "DONOR_AGE BOXPLOT (Predictive Mean Matching)";
	hbox &VFW_age / transparency=.5 legendlabel="Observed Variable"; 
	hbox &VFW_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&VFW_ds; var &VFW_age &VFW_imputed; with MONTHS_SINCE_ORIGIN ; 
run;

	/*	Question 3.a. */
data wealth_init; set donor_hw_init;
    if missing(WEALTH_RATING) then flag_miss_wlth = 1;
    else flag_miss_wlth = 0;
	WORKING_WLTH = WEALTH_RATING;
run;

	/* [0] Get observed values to compare to imputation methods */
proc means data=wealth_init n nmiss min max mean median std mode;
    var WEALTH_RATING; run;
proc freq data=wealth_init; tables WEALTH_RATING / missing; run;
proc univariate data=wealth_init; var WEALTH_RATING;
    title "Distribution of WEALTH_RATING with Normal Curve";
    histogram WEALTH_RATING / normal;
    inset n nmiss min mean median max std mode skewness kurtosis / position=ne; 
proc corr data=wealth_init; var WEALTH_RATING; with PER_CAPITA_INCOME ; 
run;

	/* [1] Single MODE unconditional imputation */
data wealth_mode; set wealth_init; 
	WLTH_RATE_MODE = WORKING_WLTH; 
    if missing(WLTH_RATE_MODE) then WLTH_RATE_MODE = 9;
run;

	/***** Step 3 -- USE macro */
%let WLTH_var  = WORKING_WLTH;
%let WLTH_imputed = WLTH_RATE_MODE;
%let WLTH_ds = wealth_mode;

proc means data=&WLTH_ds nmiss n min mean median mode max std; 
	var &WLTH_var &WLTH_imputed; run;
proc univariate data=&WLTH_ds; var &WLTH_var &WLTH_imputed; 
	histogram &WLTH_var &WLTH_imputed; run;
proc sgplot data=&WLTH_ds; 
	title "WEALTH_RATING: Observed & Imputed (MODE)";
	histogram &WLTH_var / binwidth=1 transparency=.5 legendlabel="Observed Variable";
	histogram &WLTH_imputed / binwidth=1 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&WLTH_ds; title "WEALTH_RATING BOXPLOT (Mode)";
	hbox &WLTH_var / transparency=.5 legendlabel="Observed Variable"; 
	hbox &WLTH_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&WLTH_ds; var &WLTH_var &WLTH_imputed; with PER_CAPITA_INCOME; 
run;

	/*	[2] Single PMM conditional imputation */
data wealth_pmm; set wealth_init;
    WLTH_RATE_PMM = WORKING_WLTH; run;
%let PMM_var = MEDIAN_HOME_VALUE PEP_STAR PER_CAPITA_INCOME;
proc mi data=wealth_pmm nimpute=1 seed=12345 out=wealth_pmm;
	fcs regpmm(WLTH_RATE_PMM = &PMM_var);
	var WLTH_RATE_PMM &PMM_var; 
run;

	/***** Step 3 -- USE macro, **no univariate */
%let WLTH_var = WORKING_WLTH;
%let WLTH_imputed = WLTH_RATE_PMM;
%let WLTH_ds = wealth_pmm;

proc means data=&WLTH_ds nmiss n min mean median mode max std; 
	var &WLTH_var &WLTH_imputed; run;
proc sgplot data=&WLTH_ds; 
	title "WEALTH_RATING: Observed & Imputed (PMM)";
	histogram &WLTH_var / binwidth=1 transparency=.5 legendlabel="Observed Variable";
	histogram &WLTH_imputed / binwidth=1 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=&WLTH_ds; title "WEALTH_RATING BOXPLOT (Predictive Mean Matching)";
	hbox &WLTH_var / transparency=.5 legendlabel="Observed Variable"; 
	hbox &WLTH_imputed / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=&WLTH_ds; var &WLTH_var &WLTH_imputed; with PER_CAPITA_INCOME; 
run;

	/*TASK3 *** Question 1 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ */
data extrme_ds; set donor_hw_init;
	work_xtrm = LIFETIME_GIFT_AMOUNT ;
run;

proc means data=extrme_ds n nmiss min mean median max std; var work_xtrm; run;
proc univariate data=extrme_ds;
    var work_xtrm;
    histogram work_xtrm / normal; run;
proc sgplot data=extrme_ds; histogram work_xtrm;
run;

	/* Question 2 Tukey's Ladder of Power Transformations */
data extreme_TL; set extrme_ds;
	 cube_work_xtrm 	= work_xtrm**3;
	 sq_work_xtrm 		= work_xtrm**2;
	 id_work_xtrm 		= work_xtrm**1;
	 sqrt_work_xtrm 	= work_xtrm**.5;
	 log_work_xtrm 		= log(work_xtrm);
	 inv_sqrt_work_xtrm	= 1/(work_xtrm**.5);
	 inv_id_work_xtrm 	= 1/(work_xtrm**1);
	 inv_sq_work_xtrm 	= 1/(work_xtrm**2);
	 inv_cub_work_xtrm 	= 1/(work_xtrm**3);
run;

	/* Before transformation (original data) */
proc univariate data=extreme_TL;
    var work_xtrm;
    histogram work_xtrm / normal;
    output out=before_stats skewness=skew_before; run;
run;

	/* Transformation, use similar to macro, just replace prefix */
proc univariate data=extreme_TL;
    var  inv_sqrt_work_xtrm;
    histogram  inv_sqrt_work_xtrm / normal;
    output out=inv_sqrt_stats skewness=skew_inv_sqrt; run;
run;
	
	/*Question 3 BoxCox Transformation*/
proc transreg data=extreme_TL;
    model BoxCox(work_xtrm) = identity(work_xtrm);
    output out=extreme_box;
run;

	/* Calculate skewness after the Box-Cox transformation */
proc univariate data=extreme_box;
    var Twork_xtrm;  /* Box-Cox transformed variable */
    histogram Twork_xtrm / normal;
    output out=extreme_stats skewness=skew_boxcox;
run;

proc print data=extreme_stats;
    var skew_boxcox;  /* This will display the skewness after Box-Cox */
run;

proc means data=extreme_TL skew; 
	var cube_work_xtrm sq_work_xtrm id_work_xtrm sqrt_work_xtrm log_work_xtrm
	inv_sqrt_work_xtrm inv_id_work_xtrm inv_sq_work_xtrm inv_cub_work_xtrm; run;
proc univariate data=extreme_TL;
    var log_work_xtrm;  
    histogram log_work_xtrm / normal;
run;

