
	/* TASK 1 *** load new datafile @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
libname sasload '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 3';	
	data Engineering; set sasload.s_pml_donor_hw_v3; run;

ods select variables; /* Visual check of dataset */
	proc contents data=Engineering; run;

%let FE1_var = LIFETIME_GIFT_AMOUNT;
/* data data610.eng_load; set Engineering; run; */

	/* Question 1 */
proc means data=Engineering n nmiss min max mean std;
    var &FE1_var; run;
proc freq data=Engineering;
    tables &FE1_var / missing norow nocol nopercent; run;
proc sgplot data=Engineering;
    histogram &FE1_var;
    density &FE1_var / type=normal;
    title "LIFETIME_GIFT_AMOUNT distribution with Normal Curve"; run;
proc univariate data=Engineering;
    var &FE1_var;
    histogram &FE1_var / normal;
    inset n nmiss min mean median max std skewness kurtosis / position=ne;
run;

	/* Question 2 */
	/* [1] PROC EYEBALL Distribution Examination ************/
data ENG_eye_chk; set Engineering; run;
proc sgplot data=ENG_eye_chk;
  	histogram &FE1_var / binwidth = 100; run;
proc sgplot data=ENG_eye_chk;
	hbox &FE1_var; 
run;

proc univariate data=ENG_eye_chk; var &FE1_var;
  	histogram &FE1_var; 
run; 

/* data data610.ENG_eye_chk; set ENG_eye_chk; run; */
/* will use for each EV check*/

	/* Eyeball suggests around 700 as a cutoff value for high extremes =>
  	  62 obs with LIFETIME_GIFT_AMOUNT > 700 = 62/19372 = 0.32%  */
proc sql; select count(*) from ENG_eye_chk where &FE1_var > 700; quit;	
proc freq data=ENG_eye_chk; tables &FE1_var; 
run;

	/* [2] Top/Bottom 1% - Automatic method *****************/
proc means data=ENG_eye_chk p1 p99; var &FE1_var; 
	output out = ENG_top1_chk p1=bot1 p99=top1; run; 
proc print data=ENG_top1_chk; 
run;

data df_show; set ENG_eye_chk; rows = _n_; run; 
proc print data=df_show (firstobs=1 obs=20); var rows; run;
data stats_show; set ENG_top1_chk; rows = _n_; run; 
proc print data=stats_show (firstobs=1 obs=20); var rows; 
run;

data one_topbot; set ENG_eye_chk; if _n_ = 1 then set ENG_top1_chk; run;
proc print data=one_topbot (firstobs=1 obs=20); var _TYPE_ _FREQ_ bot1 top1; 
run;
	/* for execution of the top/bottom technique */
data one_topbot; set ENG_eye_chk; if _n_ = 1 then set ENG_top1_chk; 
	if &FE1_var > top1 then ev_gift1 = 1; 
	else if &FE1_var < bot1 then ev_gift1 = 1; 
	else ev_gift1 = 0; run;
proc print data=one_topbot (firstobs=1 obs=20); 
	var &FE1_var bot1 top1 ev_gift1; run;
proc freq data=one_topbot; tables ev_gift1; run; 	

/* data data610.ENG_TOP_chk; set one_topbot; run; */

	/* [3] Interquartile Range (IQR) ************************/ 
proc univariate data=ENG_eye_chk; var &FE1_var; run;
proc sgplot data=ENG_eye_chk; hbox &FE1_var; run;
proc means data=ENG_eye_chk q1 q3 qrange; 
	var &FE1_var; output out = IQR_stats q1=Q1 q3=Q3 qrange=IQR; run; 
proc print data=IQR_stats (firstobs=1 obs=20); 
run;
 	
%let iqr_mult = 3; 
data ENG_IQR_chk; set ENG_eye_chk; if _n_ = 1 then set IQR_stats;  
	if &FE1_var > q3 + &iqr_mult*iqr then ev_gift2 = 1; 
	else if &FE1_var < q1 - &iqr_mult*iqr then ev_gift2 = 1; 
	else ev_gift2 = 0; 
	upper_cutoff = q3 + &iqr_mult*iqr;
	lower_cutoff = q1 - &iqr_mult*iqr;
run; 
	/* how many extreme values are there? */
proc freq data=ENG_IQR_chk; tables ev_gift2; run; 
proc sql; select count(*) from ENG_IQR_chk where &FE1_var > upper_cutoff; quit;
proc sql; select count(*) from ENG_IQR_chk where &FE1_var < lower_cutoff; quit;

/* data data610.ENG_IQR_chk; set ENG_IQR_chk; run; */

	/* [4] Clustering ***************************************/
%include '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Programs/Macros/ExtremeValueMacro.sas';
%clust_ev(ENG_eye_chk, &FE1_var, .008, ENG_CLST_chk);

proc freq data=ENG_CLST_chk; tables _extreme_; run; 
proc sql; select count(*) from ENG_CLST_chk where _extreme_ > 0; quit; 

/* data data610.ENG_CLST_chk; set ENG_CLST_chk; run; */

	/* [5] Grubb's Test done in R */  
proc export data=data610.eng_eye_chk
   	outfile="/home/u64005990/ANA610/wk3_for_R.csv"; run;

	/*** EXTRA: *** visual comparison with below MACRO*/
data eng_hyp;
	set ENGINEERING;
	/* Run 491, 430, 402 for diff methods */	
	where (LIFETIME_GIFT_AMOUNT < 402); run;
proc univariate data=eng_hyp;
    var &FE1_var;
    histogram &FE1_var / normal;
    title "Distribution after IQR"; 
    inset n nmiss min mean median max std skewness kurtosis / position=ne;
run;

	/* Task 2 *** Question 1 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

/* data Engineering; set data610.eng_load; run; */
%let FE2_var = RECENT_STAR_STATUS;

	/* Question 1.a. */
proc means data=Engineering n nmiss min max mean std;
    var &FE2_var; run;
proc freq data=Engineering;
    tables &FE2_var / missing nocum nopercent; run;
proc sgplot data=Engineering;
    histogram &FE2_var;
    density &FE2_var / type=normal;
    title "RECENT_STAR_STATUS distribution with Normal Curve"; run;
proc univariate data=Engineering;
    var &FE2_var;
    histogram &FE2_var / normal;
    inset n nmiss min mean median max std skewness kurtosis / position=ne;
run;

	/* 2.b. */
proc contents data=ENGINEERING noprint out=ENG_CARD; run;
proc sql noprint;
    select name into :vars separated by ' ' from ENG_CARD; 
    select type into :type separated by ' ' from ENG_CARD; quit;
%include '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Programs/Macros/SimpleCardinalityMacro.sas';
%SimpleCardinality(ENGINEERING, RECENT_STAR_STATUS, &type);	

	/* 2.c. Recode RECENT_STAR_STATUS into dum vars using threshold of 30*/
	/* Step 1: Create Dummy Variables for each level of RECENT_STAR_STATUS */
data ENG_STAR_DUM; set ENGINEERING;
    DUM_STAR_TOTAL1 = (RECENT_STAR_STATUS = 0);
    DUM_STAR_TOTAL2 = (RECENT_STAR_STATUS = 1);
    DUM_STAR_TOTAL3 = (RECENT_STAR_STATUS = 2);
    DUM_STAR_TOTAL4 = (RECENT_STAR_STATUS = 3);
    DUM_STAR_TOTAL5 = (RECENT_STAR_STATUS = 4);
    DUM_STAR_TOTAL6 = (RECENT_STAR_STATUS = 5);
    DUM_STAR_TOTAL7 = (RECENT_STAR_STATUS = 6);
    DUM_STAR_TOTAL8 = (RECENT_STAR_STATUS = 7);
    DUM_STAR_TOTAL9 = (RECENT_STAR_STATUS = 8);
    DUM_STAR_TOTAL10 = (RECENT_STAR_STATUS = 9);
    DUM_STAR_TOTAL11 = (RECENT_STAR_STATUS = 10);
    DUM_STAR_TOTAL12 = (RECENT_STAR_STATUS = 11);
    DUM_STAR_TOTAL13 = (RECENT_STAR_STATUS = 12);
    DUM_STAR_TOTAL14 = (RECENT_STAR_STATUS = 13);
    DUM_STAR_TOTAL15 = (RECENT_STAR_STATUS = 14);
    DUM_STAR_TOTAL16 = (RECENT_STAR_STATUS = 15);
    DUM_STAR_TOTAL17 = (RECENT_STAR_STATUS = 16);
    DUM_STAR_TOTAL18 = (RECENT_STAR_STATUS = 17);
    DUM_STAR_TOTAL19 = (RECENT_STAR_STATUS = 18);
    DUM_STAR_TOTAL20 = (RECENT_STAR_STATUS = 19);
    DUM_STAR_TOTAL21 = (RECENT_STAR_STATUS = 20);
    DUM_STAR_TOTAL22 = (RECENT_STAR_STATUS = 21);
    DUM_STAR_TOTAL23 = (RECENT_STAR_STATUS = 22); 
run;

%let STAR_dums = DUM_STAR_TOTAL1 DUM_STAR_TOTAL2 DUM_STAR_TOTAL3 DUM_STAR_TOTAL4 DUM_STAR_TOTAL5 DUM_STAR_TOTAL6 DUM_STAR_TOTAL7 
	DUM_STAR_TOTAL8 DUM_STAR_TOTAL9	DUM_STAR_TOTAL10 DUM_STAR_TOTAL11 DUM_STAR_TOTAL12 DUM_STAR_TOTAL13 DUM_STAR_TOTAL14 DUM_STAR_TOTAL15 
	DUM_STAR_TOTAL16 DUM_STAR_TOTAL17 DUM_STAR_TOTAL18 DUM_STAR_TOTAL19 DUM_STAR_TOTAL20 DUM_STAR_TOTAL21 DUM_STAR_TOTAL22 DUM_STAR_TOTAL23; 

proc print data=ENG_STAR_DUM (firstobs=1 obs=25); var &FE2_var &STAR_dums; 
run;

proc means data=ENG_STAR_DUM min mean max sum; var &STAR_dums; run;	 
proc freq data=ENG_STAR_DUM; table &FE2_var / out=freq; run;
proc print data=ENG_STAR_DUM (firstobs=1 obs=20); 
run;

	/* [Step 2]  Merge counts onto the master dataset */ 
proc sort data=freq; by &FE2_var; run; 
proc sort data=ENG_STAR_DUM; by &FE2_var; run; 
data ENG_FREQ_DUM; merge ENG_STAR_DUM (in=a) freq (in=b); by &FE2_var; if a; run; 
proc print data=ENG_FREQ_DUM (firstobs=1 obs=25); var &FE2_var count; 
run;	

	/*[Step 3: DIRECT APPROACH] */
data ENG_THRESH_DUM; set ENG_FREQ_DUM;
    if DUM_STAR_TOTAL1 and count >= 30 then DUM_STAR_TOTAL1 = 1; else DUM_STAR_TOTAL1 = 0; 
    if DUM_STAR_TOTAL2 and count >= 30 then DUM_STAR_TOTAL2 = 1; else DUM_STAR_TOTAL2 = 0;
    if DUM_STAR_TOTAL3 and count >= 30 then DUM_STAR_TOTAL3 = 1; else DUM_STAR_TOTAL3 = 0;
    if DUM_STAR_TOTAL4 and count >= 30 then DUM_STAR_TOTAL4 = 1; else DUM_STAR_TOTAL4 = 0;
    if DUM_STAR_TOTAL5 and count >= 30 then DUM_STAR_TOTAL5 = 1; else DUM_STAR_TOTAL5 = 0;
    if DUM_STAR_TOTAL6 and count >= 30 then DUM_STAR_TOTAL6 = 1; else DUM_STAR_TOTAL6 = 0;
    if DUM_STAR_TOTAL7 and count >= 30 then DUM_STAR_TOTAL7 = 1; else DUM_STAR_TOTAL7 = 0;
    if DUM_STAR_TOTAL8 and count >= 30 then DUM_STAR_TOTAL8 = 1; else DUM_STAR_TOTAL8 = 0;
    if DUM_STAR_TOTAL9 and count >= 30 then DUM_STAR_TOTAL9 = 1; else DUM_STAR_TOTAL9 = 0;
    if DUM_STAR_TOTAL10 and count >= 30 then DUM_STAR_TOTAL10 = 1; else DUM_STAR_TOTAL10 = 0;
    if DUM_STAR_TOTAL11 and count >= 30 then DUM_STAR_TOTAL11 = 1; else DUM_STAR_TOTAL11 = 0;
    if DUM_STAR_TOTAL12 and count >= 30 then DUM_STAR_TOTAL12 = 1; else DUM_STAR_TOTAL12 = 0;
    if DUM_STAR_TOTAL13 and count >= 30 then DUM_STAR_TOTAL13 = 1; else DUM_STAR_TOTAL13 = 0;
    if DUM_STAR_TOTAL14 and count >= 30 then DUM_STAR_TOTAL14 = 1; else DUM_STAR_TOTAL14 = 0;
    if DUM_STAR_TOTAL15 and count >= 30 then DUM_STAR_TOTAL15 = 1; else DUM_STAR_TOTAL15 = 0;
    if DUM_STAR_TOTAL16 and count >= 30 then DUM_STAR_TOTAL16 = 1; else DUM_STAR_TOTAL16 = 0;
    if DUM_STAR_TOTAL17 and count >= 30 then DUM_STAR_TOTAL17 = 1; else DUM_STAR_TOTAL17 = 0;
    if DUM_STAR_TOTAL18 and count >= 30 then DUM_STAR_TOTAL18 = 1; else DUM_STAR_TOTAL18 = 0;
    if DUM_STAR_TOTAL19 and count >= 30 then DUM_STAR_TOTAL19 = 1; else DUM_STAR_TOTAL19 = 0;
    if DUM_STAR_TOTAL20 and count >= 30 then DUM_STAR_TOTAL20 = 1; else DUM_STAR_TOTAL20 = 0;
    if DUM_STAR_TOTAL21 and count >= 30 then DUM_STAR_TOTAL21 = 1; else DUM_STAR_TOTAL21 = 0;
    if DUM_STAR_TOTAL22 and count >= 30 then DUM_STAR_TOTAL22 = 1; else DUM_STAR_TOTAL22 = 0;
    if DUM_STAR_TOTAL23 and count >= 30 then DUM_STAR_TOTAL23 = 1; else DUM_STAR_TOTAL23 = 0;
/* Step 2: Create the 'other' category if none of the dummy variables are set */
    if sum(of DUM_STAR_TOTAL1-DUM_STAR_TOTAL23) = 0 then DUM_STAR_OTHER0 = 1; 
    else DUM_STAR_OTHER0 = 0;
run;

	/* 1.e.ii.  Verify it worked as intended */
proc means data=ENG_THRESH_DUM min mean max std maxdec=3; 
	var DUM_STAR_TOTAL1-DUM_STAR_TOTAL23 DUM_STAR_OTHER0;
run;

	/* data data610.ENG_threshold; set ENG_THRESH_DUM; run; */

	/* 1.f.i Show that each dum_var that passed the threshold test has at least 30 */
proc means data=ENG_THRESH_DUM sum maxdec=0; 
	var DUM_STAR_TOTAL1-DUM_STAR_TOTAL23 DUM_STAR_OTHER0;
run;
	/* Task 3 *** Question 1 CLUSTERING @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

%let target_var = TARGET_B;      
proc means data= ENGINEERING noprint nway; 
     class &FE2_var; /* Group by levels of RECENT_STAR_STATUS  */
     var &target_var; 
     output out=level mean = prop; run;
proc sort data=level; by descending prop; run; 
proc print data=level; format prop percent10.2; 
run; 

proc freq data=ENGINEERING; table &FE2_var; run; 
ods output clusterhistory=cluster;
proc cluster data=level method=ward outtree=fortree; 
	freq _freq_; 
	var prop; 
	id &FE2_var; 
run; 

	/* Statistically find optimal number of clusters */
	/* Use FREQ Pearson Chi^2 stat of BRANCH*TARGET_B (23 x 2) contingency table. */ 
proc freq data=ENGINEERING;
    tables &FE2_var * &target_var / chisq;  
    ods output ChiSq=ChiSquareResults; run;
proc print data=ChiSquareResults; 
    title 'Pearson Chi-Square Test for RECENT_STAR_STATUS vs TARGET_B'; run;
proc freq data=ENGINEERING noprint; 
	table &FE2_var*&target_var / chisq; 
	output out=chi(keep=_pchi_) chisq; 
run; 

	/* Use a merge to put Chi^2 stat onto clustering results. Calculate (log)p-value for each cluster. */ 
data cutoff; 
	if _n_=1 then set chi; 
	set cluster; 
	chisquare=_pchi_*rsquared; 
	degfree=numberofclusters-1; 
	logpvalue=logsdf('CHISQ',chisquare,degfree); run; 
	/* Plot the log p-values against number of clusters...at which cluster count is log of p-value a min? */ 
title1 "Plot of the Log of the P-value by Number of Clusters"; 
proc sgplot data=cutoff; 
	series x=numberofclusters y=logpvalue; 
	xaxis values= (1 to 23 by 1); 
run;

proc sql; 
	select 3 into :ncl 
	from cutoff 
	having logpvalue=min(logpvalue); quit; 
	* Create a dataset “clus” with the cluster solution; 
proc tree data=fortree noprint nclusters=&ncl out=clus ; 
	id &FE2_var; run; 
proc sort data=clus; 
	by clusname; run; 
title1 "Levels of Categorical Variable by Cluster"; 
proc print data=clus; 
	by clusname; 
	id clusname; 
run;

	* Merge cluster assignment onto master file and create dummies;
proc sort data=clus; 		    by &FE2_var; run; 
proc sort data=ENGINEERING;   by &FE2_var; run; 
data dummy; merge ENGINEERING clus; by &FE2_var; 
    Med_Val_grp=(cluster=1); Large_Val_grp=(cluster=2); 
    Small_Val_grp=(cluster=3); run; 
proc means data=dummy sum; var Large_Val_grp Med_Val_grp Small_Val_grp; run; 
	/* check frequencies at the target-level */ 
proc sort data=dummy; by &target_var; run; 
proc means data=dummy sum; var Large_Val_grp Med_Val_grp Small_Val_grp;
    output out=tmp_sum (drop = _TYPE_ _FREQ_) 
    sum = Large_Val_grp Small_Val_grp Med_Val_grp;
    by &target_var;
    where not missing(&target_var); 
run; 

proc transpose data=tmp_sum out=tmp_sum_t; id &target_var; run; 
proc print data=tmp_sum_t; 
run;     /* data data610.ENG_3CSTR; set dummy; run; */

	/* ***EXTRA CREDIT*** TASK 1***    Log Transformation@@@@@@@@@@@@@*/
data ENG_TFORM; set ENGINEERING;
    if &FE1_var > 0 then LOG_GIFT_AMT = log(&FE1_var);
    else LOG_GIFT_AMT = .; /* Assign missing value if amount <= 0 */
run;

%let LOG_var = LOG_GIFT_AMT;
proc means data= ENG_TFORM skewness; /* Calculate Skewness Before and After Transformation */
    var &FE1_var &LOG_var;
run;
	/* Plot the Histograms, adjust scale of log(gist) */
proc sgplot data=ENG_TFORM;
    title "Histogram of Original LIFETIME_GIFT_AMOUNT";
    histogram &FE1_var / binwidth=100 scale=count; 
    xaxis label="LIFETIME_GIFT_AMOUNT" min=0 max=4000;  
    yaxis label="Frequency"; run;
proc sgplot data=ENG_TFORM;
    title "Histogram of Log-Transformed LIFETIME_GIFT_AMOUNT";
    histogram &LOG_var / binwidth=0.2 scale=count; 
    xaxis label="Log(LIFETIME_GIFT_AMOUNT)" min=0 max=10; 
    yaxis label="Frequency";
run;

%include '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Programs/Macros/ExtremeValueMacro.sas';
%clust_ev(ENG_TFORM, &LOG_var, .006, ENG_TFORM_chk);

proc freq data=ENG_TFORM_chk; tables _extreme_; run; 
proc sql; select count(*) from ENG_TFORM_chk where _extreme_ > 0; quit; 

	/* ***E.C.*** Task 2*** FREQ Pearson Chi^ @@@@@@@@@@@@@@@@@@@@@@@@*/
proc freq data=dummy;
    tables cluster * &target_var / chisq;  
    ods output ChiSq=ChiSquareResults; run;
proc print data=ChiSquareResults; 
    title 'Pearson Chi-Square Test for reduced_STAR_STATUS vs TARGET_B'; run;
proc freq data=dummy noprint; 
	table cluster*&target_var / chisq; 
	output out=chi(keep=_pchi_) chisq; 
run; 

	/* ***E.C. Task 3*** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	

	/* ***E.C. Task 4*** @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	/* Calculate frequencies and supervised ratio */
proc sql;
    create table freq_table as
    select 
        RECENT_STAR_STATUS, 
        count(*) as total_count, 
        sum(TARGET_B = 1) as freq_target_b_1, 
        sum(TARGET_B = 0) as freq_target_b_0,
        calculated freq_target_b_1 / calculated total_count as supervised_ratio
    from ENGINEERING
    group by RECENT_STAR_STATUS
    having total_count >= 30; 
quit;

proc print data=freq_table;
    var RECENT_STAR_STATUS total_count freq_target_b_1 freq_target_b_0 supervised_ratio;
run;

	/* ***E.C. Question 2 @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
/* Step 1: Calculate frequencies and supervised ratio */
proc sql;
    create table freq_table as
    select 
        RECENT_STAR_STATUS, 
        count(*) as total_count, 
        sum(TARGET_B = 1) as freq_target_b_1, 
        sum(TARGET_B = 0) as freq_target_b_0,
        calculated freq_target_b_1 / calculated total_count as supervised_ratio
    from ENGINEERING
    group by RECENT_STAR_STATUS
    having total_count >= 30; /* Apply threshold of 30 */
quit;

	/* Display output table with the required columns */
proc print data=freq_table;
    var RECENT_STAR_STATUS total_count freq_target_b_1 freq_target_b_0 supervised_ratio;
run;

	/* Create a dataset where supervised ratio is joined to the original dataset */
proc sql;
    create table engineering_with_ratio as
    select a.*, b.supervised_ratio
    from ENGINEERING as a
    left join freq_table as b
    on a.RECENT_STAR_STATUS = b.RECENT_STAR_STATUS;
quit;

	/* Calculate the correlation between supervised_ratio and TARGET_B */
proc corr data=engineering_with_ratio;
    var supervised_ratio TARGET_B;
run;





