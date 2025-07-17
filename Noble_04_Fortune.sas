   data master_file; set data610.master_file; run;

proc contents data=master_file; run;
proc print data=Master_file (firstobs = 1 obs = 25); 
run;

	/* TASK 3 *** Deduplicate @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	/* 1. *** remove duplicate observations */
proc sort data=Master_file out=df_dedup 
	nodupkey; by employee_no; 
run;

proc sql;
    create table row_counts as
    select "Master_file" as Datafile, count(*) as Row_Count 
    from Master_file
    union
    select "df_dedup" as Datafile, count(*) as Row_Count 
    from df_dedup; quit;
proc print data=row_counts; 
run;

	/* 2. *** create AGE and TENURE variables */
data df_AGETEN; set df_dedup;
    analysis_date = '01JUN2018'd;
    /* Calculate AGE, accounting for missing values */
    if not missing(birth_dt) 
    then AGE = floor(yrdif(birth_dt, analysis_date, 'AGE'));
    else AGE = .;
    /* Calculate TENURE, accounting for whether depart_dt is missing */
    if not missing(hire_dt) then do;
        if missing(depart_dt) 
        then TENURE = floor(yrdif(hire_dt, analysis_date, 'AGE'));
        else TENURE = floor(yrdif(hire_dt, depart_dt, 'AGE')); end;
    else TENURE = .;
run;
	/* Verify results */
proc freq data=df_AGETEN;
    tables birth_dt age tenure hire_dt depart_dt / missing nopercent; 
run;
	/* output with N, MEAN and MEDIAN for AGE and TENURE.*/
proc means data=df_AGETEN n mean median maxdec=3;
    var AGE TENURE;
run;

	/* 3. *** Creating ATT_Q in deduped dataset */

data df_ATTQ; set df_AGETEN;
    if not missing(JobLevel) then do;    /* Create target variable ATT_Q */
        if not missing(depart_dt) 
        then ATT_Q = 1;               /* Took the survey and attritioned */
        else ATT_Q = 0; end;    /* Took the survey and did not attrition */
    else ATT_Q = .; run;      /* Did not take the survey, set to missing */
proc freq data=df_ATTQ;
    tables ATT_Q / missing nopercent;
run;

	/* 4. Impute AGE missing values using PMM */
data df_IMPUTE; set df_ATTQ;
    /* Create a missing indicator variable for AGE */
    if missing(AGE) then FULL_AGE = 0;  /* Indicates that AGE is missing */
    else FULL_AGE = 1;                  /* Indicates that AGE is not missing */
run;

data df_IMPUTE; set df_IMPUTE;
    AGE_PMM = AGE; run;
proc mi data=df_IMPUTE nimpute=1 seed=1234 out=ALL_AGE;
	fcs regpmm(AGE_PMM = EDUCATION HIRE_DT);
	var AGE_PMM EDUCATION HIRE_DT; 
run;

proc means data=ALL_AGE n min mean median max std;
    var AGE AGE_PMM; run;
proc sgplot data=ALL_AGE; 
	title "AGE: Observed & Imputed with PMM";
	histogram AGE / binwidth=1 transparency=.5 legendlabel="Observed Variable";
	histogram AGE_PMM / binwidth=1 transparency=.5 legendlabel="Imputed Variable"; run;
proc sgplot data=ALL_AGE; title "AGE BOXPLOT (Predictive Mean Matching)";
	hbox AGE / transparency=.5 legendlabel="Observed Variable"; 
	hbox AGE_PMM / transparency=.5 legendlabel="Imputed Variable"; run;
proc corr data=ALL_AGE; var AGE AGE_PMM; with EDUCATION HIRE_DT;
run;

 	/* TASK 4 ***  */
	/* Equal height */
proc hpbin data=ALL_AGE numbin = 7 pseudo_quantile;
	input AGE_PMM; ods output mapping=mapping; run;
proc hpbin data=ALL_AGE woe bins_meta=mapping;
	target ATT_Q/level=nominal order=desc; 
run; 

proc hpbin data=ALL_AGE numbin = 4 pseudo_quantile;
	input TENURE; ods output mapping=mapping; run;
proc hpbin data=ALL_AGE woe bins_meta=mapping;
	target ATT_Q/level=nominal order=desc; 
run; 

	/* Equal width */
ods output mapping=mapping;
proc hpbin data=ALL_AGE numbin=4 bucket; input AGE_PMM; run;
proc hpbin data=ALL_AGE woe bins_meta=mapping; target ATT_Q; 
run;      

ods output mapping=mapping;
proc hpbin data=ALL_AGE numbin=2 bucket; input TENURE; run;
proc hpbin data=ALL_AGE woe bins_meta=mapping; target ATT_Q; 
run;      

proc hpbin data=ALL_AGE output=df_bin numbin=10 bucket; input AGE_PMM; run;

	/* 4. Create dummy variables  */
data AGE_DUM; set ALL_AGE;
	if AGE_PMM in(.) then age_dum_miss = 1; else age_dum_miss = 0; 
	if AGE_PMM > 0 and age_PMM< 30 then age_dum_less30 = 1; else age_dum_less30 = 0; 
	if AGE_PMM ge 30 and age_PMM< 33 then age_dum_30_33 = 1; else age_dum_30_33 = 0; 
	if AGE_PMM ge 33 and age_PMM< 36 then age_dum_33_36 = 1; else age_dum_33_36 = 0; 
	if AGE_PMM ge 36 and age_PMM< 39 then age_dum_36_39 = 1; else age_dum_36_39 = 0;
	if AGE_PMM ge 39 and age_PMM< 44 then age_dum_39_44 = 1; else age_dum_39_44 = 0; 
	if AGE_PMM ge 44 and age_PMM< 50 then age_dum_44_50 = 1; else age_dum_44_50 = 0; 
	if AGE_PMM ge 50 then age_dum_50_61 = 1; else age_dum_50_61 = 0; 
run; 

data TEN_DUM; set ALL_AGE;
	if TENURE in(.) then ten_dum_miss = 1; else ten_dum_miss = 0; 
	if TENURE > 0 and TENURE< 5 then ten_dum_0_5 = 1; else ten_dum_0_5 = 0; 
	if TENURE ge 5 and TENURE< 7 then ten_dum_5_7 = 1; else ten_dum_5_7 = 0; 
	if TENURE ge 7 and TENURE< 11 then ten_dum_7_11 = 1; else ten_dum_7_11 = 0; 
	if TENURE ge 11 then ten_dum_11_40 = 1; else ten_dum_11_40 = 0; 
run; 

	/* 4.b. produce a tall and skinny table for AGE*/
proc means data=AGE_DUM noprint;
    class ATT_Q;  /* Segment the results by the target variable ATT_Q */
    var age_dum_miss age_dum_less30 age_dum_30_33 age_dum_33_36 
    age_dum_36_39 age_dum_39_44 age_dum_44_50 age_dum_50_61;
    output out=AGE_SUMS(drop=_TYPE_ _FREQ_) sum=; run;
	/* Transpose to get a tall and skinny format */
proc transpose data=AGE_SUMS 
	out=AGE_TALL(rename=(_NAME_=Bin Sum1=ATT_Q_0 Sum2=ATT_Q_1 Sum3=ATT_Q_2));
    by ATT_Q; 				/* Specify the target variable */
    var age_dum_miss age_dum_less30 age_dum_30_33 age_dum_33_36 
    age_dum_36_39 age_dum_39_44 age_dum_44_50 age_dum_50_61; run;
proc print data=AGE_TALL;
run;

	/*  produce a tall and skinny table for TENURE */
proc means data=TEN_DUM noprint;
    class ATT_Q; 		 /* Segment results by variable ATT_Q */
    var ten_dum_miss ten_dum_0_5 ten_dum_5_7 ten_dum_7_11 ten_dum_11_40;
    output out=TEN_SUMS(drop=_TYPE_ _FREQ_) sum=; run;
proc transpose data=TEN_SUMS 
	out=TEN_TALL(rename=(_NAME_=Bin Sum1=ATT_Q_0 Sum2=ATT_Q_1 Sum3=ATT_Q_2));
    by ATT_Q;
    var ten_dum_miss ten_dum_0_5 ten_dum_5_7 ten_dum_7_11 ten_dum_11_40; run;
proc print data=TEN_TALL;
run;

	/* TASK 5 *** Run Final CORR*/
	/* Calculate correlations for AGE dummy variables */
proc corr data=AGE_DUM noprint outp=AGE_CORR;
    var age_dum_miss age_dum_less30 age_dum_30_33 age_dum_33_36 
    age_dum_36_39 age_dum_39_44 age_dum_44_50 age_dum_50_61;
    with ATT_Q; run;
proc transpose data=AGE_CORR out=AGE_CORR_TALL;
    where _TYPE_ = 'CORR'; /* Select only correlation rows */
    id _NAME_; /* This will make ATT_Q the column header */
    var age_dum_miss age_dum_less30 age_dum_30_33 age_dum_33_36 
    age_dum_36_39 age_dum_39_44 age_dum_44_50 age_dum_50_61; run;
data PRINT_AGE_CORR;
    set AGE_CORR_TALL;
    rename COL1=Correlation; run;
proc print data=PRINT_AGE_CORR noobs;
run;

	/* Calculate correlations for TENURE dummy variables */
	/*proc corr data=TEN_DUM nosimple;
    	var ten_dum_miss ten_dum_0_5 ten_dum_5_7 ten_dum_7_11 ten_dum_11_40;
    	with ATT_Q; run;     I did not like the horizontal output */

proc corr data=TEN_DUM noprint outp=TEN_CORR;
    var ten_dum_miss ten_dum_0_5 ten_dum_5_7 ten_dum_7_11 ten_dum_11_40;
    with ATT_Q; run;
proc transpose data=TEN_CORR out=TEN_CORR_TALL;
    where _TYPE_ = 'CORR'; 
    id _NAME_; run;
data PRINT_TEN_CORR;
    set TEN_CORR_TALL;
    rename COL1=Correlation; run;
proc print data=PRINT_TEN_CORR noobs;
run;

	/* EXTRA CREDIT *** */
data Hire_outlier;
    set ALL_AGE;
    if tenure = 0 then output;
    keep employee_no tenure hire_dt depart_dt; run;
proc print data=Hire_outlier noobs;
run;
	/* 2. */
%include '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Programs/Macros/ExtremeValueMacro.sas';
%clust_ev(ALL_AGE, TENURE, .005, TEN_CLUS);

proc fastclus data=ALL_AGE maxclusters=40 pmin=0.005 out=cluster_output;
    var tenure;
run;
	/* 3. */
proc contents data=ALL_AGE; run;

data EC_three;
    set ALL_AGE;
    where ATT_Q in (0, 1);
    drop SSN EDUCATIONFIELD GENDER BIRTH_STATE DEPARTMENT 
    OVERTIME BUSINESSTRAVEL MARITALSTATUS FIRST_NAME;
run;
proc freq data=ALL_AGE; tables tenure; run;
proc means data=all_age n nmiss min mean max std;
	var tenure;
run;


/* end */