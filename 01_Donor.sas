/*In general, how do we classify?  
	1. Look at the data 
	2. Look at variable name 
	3. Look at PROC MEANS 
	4. Look at the data dictionary
	5. Look at PROC FREQ 
file info
	Numeric ======> 
	Date =========> 	
	Categorical ==> 
	Character ====>	
*/

	/*	load SAS file*/
libname sasload '/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 1';
   data data610.CNSSfile; set sasload.donor_census2; run;

	/*	load csv files */
proc import datafile='/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 1/donor_history2.csv'
out=data610.HISTfile; run;

proc import datafile='/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 1/donor_profile2.csv'
out=data610.PROfile; run;

proc import datafile='/home/u64005990/my_shared_file_links/kevinduffy-deno1/Datafiles/Homework 1/donor_survey2.csv'
out=data610.SURVfile; run;

	/*look at all files*/
proc contents data=data610.CNSSfile; run;
proc contents data=data610.HISTfile; run;
proc contents data=data610.PROfile; run;
proc contents data=data610.SURVfile; run;

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	Analyze first datafile*/

ods select Variables;				
proc contents data=data610.CNSSfile; run;
/*
#		Variable		Type	Len
1	CONTROL_NUMBER		Char	8
2	WEALTH_RATING		Num		8
3	MEDIAN_HOME_VALUE	Num		8
4	MEDIAN_HHOLD_INCOME	Num		8
5	PCT_OWNER_OCCUPIED	Num		8
6	PCT_VIETNAM_VETS	Num		8
7	PER_CAPITA_INCOME	Num		8
*/

proc print data=data610.CNSSfile (firstobs = 1 obs = 10); run;
/*
Obs	CONTROL_NUMBER	WEALTH_RATING	MEDIAN_HOME_VALUE	MEDIAN_HOUSEHOLD_INCOME	PCT_OWNER_OCCUPIED	PCT_VIETNAM_VETERANS	PER_CAPITA_INCOME
1	00000005			.				554					294							76						0				11855
2	00000012			3				334					212							72						21				10385
3	00000037			9				2388				405							63						26				30855
4	00000038			4				1688				153							3						32				16342
5	00000041			5				514					328							90						36				12107
6	00000052			.				452					182							51						38				6851
7	00000053			7				376					122							68						11				5900
8	00000067			.				1004				189							95						49				12667
9	00000070			.				361					180							56						45				8132
10	00000071			.				399					307							86						33				11428

	WLTH_RATE:	(1) DICTIONARY => Measures wealth relative to others within state
				(2) PROC PRINT => Suggestive of ratio values, and "relative to others"
				(3) PROC MEANS => Range from 0-9, 8810 missing values, possibly categorical
				(4) Classification: analytic numeric

 	MED_HM_VAL:	(1) DICTIONARY => census data
 				(2)	PROC PRINT => suggestive of home prices in thousands of dollars
				(3) PROC MEANS => range from 75 to 6,000
				(4) PROC FREQ => around 3,000 different values, 218 valued 0, which suggests missing data
				(5) Classification: analytic numeric

	MED_HH_INC:	(1) DICTIONARY => census data
				(2)	PROC PRINT => suggestive of combined income in thousands of dollars
				(3) PROC MEANS => range from 50 to 1,500
				(4) PROC FREQ =>  924 different values, 174 valued 0, which suggests missing data
				(5) Classification: analytic numeric

	%OWNR_OCC:	(1) DICTIONARY => census data
				(2)	PROC PRINT => suggestive of percent of house owned
				(3) PROC MEANS => range from 0 to 100
				(4) PROC FREQ =>  100 different values, 218 valued 0, which suggests renters--but could be missing
				(5) Classification: analytic numeric

 	%VIET_VET:	(1) DICTIONARY => census data
				(2) PROC MEANS => range from 0 to 100
				(3) PROC FREQ =>  89 different values, but it only makes sense to be a yes or no
				(4) Classification: analytic numeric (see notes)

	PER_CAP_INC:(1) DICTIONARY => census data
				(2)	PROC PRINT => suggests salary for one household individual
				(3) PROC MEANS => range from 0 to 174,523
				(4) PROC FREQ =>  over 11,000 different values, 173 valued 0, which suggests unemployed spouse
				(5) Classification: analytic numeric
*/
	/* USE macro variable */
%let VFW_var 	= CONTROL_NUMBER;
%let VFW_ds1	= data610.CNSSfile;

proc means data=&VFW_ds1 n nmiss min median max mean std; var &VFW_var; run;
proc freq data=&VFW_ds1; tables &VFW_var; run;
proc sql; select count(distinct &VFW_var) from &VFW_ds1; quit;
proc sql; select count(*) from &VFW_ds1; quit; /*run both SQL to compare, should be 1:1 */
proc univariate data=&VFW_ds1 noprint; histogram &VFW_var; run;

/*	CONTROL_NUM:(1) DICTIONARY => ID
				(2) PROC PRINT => suggests a number stored as a character
				(3) PROC SQL => # distinct values = total row count
				(4) Classification: analytic character: (a) too many distinct values to classify as
					categorical and (b) labled as a field to identify customers

file info analytic:
	Numeric ======> WEALTH_RATING; MEDIAN_HOME_VALUE; MEDIAN_HOUSEHOLD_INCOME;
					PCT_OWNER_OCCUPIED; PCT_VIETNAM_VETERANS; PER_CAPITA_INCOME;
	Date =========> 
	Categorical ==> 
	Character ====>	CONTROL_NUMBER;
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	Analyze second datafile */

ods select Variables;
proc contents data=data610.SURVfile; run;
/*
#	Variable		Type	Len	  Format	Informat
1	CONTROL_NUMBER	Num		8	  BEST12.	BEST32.
2	SURVEY_VALUE	Num		8	  BEST12.	BEST32.
3	SURVEY_QUESTION	Char	27	  $27.		$27.
*/

proc print data=data610.SURVfile (firstobs = 1 obs = 10); run;
/*
Obs	CONTROL_NUMBER	survey_question					survey_value
1			5		causes donated to last year			2
2			5		familiarity with programs			1
3			5		willingness to recommend			7
4			12		causes donated to last year			4
5			12		familiarity with programs			3
6			12		willingness to recommend			9
7			37		causes donated to last year			4
8			37		familiarity with programs			4
9			37		willingness to recommend			9
10			38		causes donated to last year			1

	CONTROL_NUM:(1) DICTIONARY => ID
				(2) PROC PRINT => suggests an identification stored as a number
				(3)	PROC FREQ => 3 rows for each value: for the 3 survey questions
				(4) PROC SQL => frequensy is 3 times the number of distinct numbers: for the 3 survey questions
				(5) Classification: analytic character because (a) too many distinct values to classify as
					categorical and (b) labled as a field to identify customers, add leading 00's

	SURVEY_VAL:	(1) DICTIONARY => The 3 survey questions: number of donations, scale 0-4, scale 1-10
				(2) PROC PRINT => 3 answers for each control_number
				(3) PROC MEANS => Range from 0-10
				(4) PROC SQL   => 3 times the number of control_numbers
				(5) Classification: combination of analytic--numeric (see notes), categorical, categorical--will need to transpose questions
*/
	/* USE macro variable */
%let VFW_var 	= CONTROL_NUMBER;
%let VFW_ds2	= data610.SURVfile;

proc means data=&VFW_ds2 n nmiss min median max mean std; var &VFW_var; run;
proc freq data=&VFW_ds2; tables &VFW_var; run;
proc sql; select count(distinct &VFW_var) from &VFW_ds2; quit;
proc sql; select count(*) from &VFW_ds2; quit; /*run both SQL to compare, should be 1:1 */
proc univariate data=&VFW_ds2 noprint; histogram &VFW_var; run;

/*	SURVEY_?s:	(1) DICTIONARY => The 3 survey question descriptions
				(2) PROC PRINT => 3 questions for each control_number
				(4) PROC SQL   => 3 times the number of control_numbers
				(5) Classification: analytic character

file info analytic:
	Numeric ======> 
	Date =========> 
	Categorical ==> SURVEY_VALUE;
	Character ====>	CONTROL_NUMBER; 	SURVEY_QUESTIONS;
	
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	Analyze third datafile */

ods select Variables;				
proc contents data=data610.PROfile; run;
/*
#	Variable			Type	Len	   Format	Informat
1	CONTROL_NUMBER		Num		 8	   BEST12.	BEST32.
2	CLUSTER_CODE		Num		 8	   BEST12.	BEST32.
3	DONOR_AGE			Num		 8	   BEST12.	BEST32.
4	INCOME_GROUP		Num		 8	   BEST12.	BEST32.
5	RECENT_STAR_STATUS	Num		 8	   BEST12.	BEST32.
6	DONOR_GENDER		Char	 1	   $1.		$1.
7	HOME_OWNER			Char	 1	   $1.		$1.
8	SES					Char	 1	   $1.		$1.
9	URBANICITY			Char	 1	   $1.		$1.
*/

proc print data=data610.PROfile (firstobs = 1 obs = 10); run;
/*
Obs	CONTROL_NUMBER	DONOR_AGE	URBANICITY	SES		CLUSTER_CODE	HOME_OWNER	DONOR_GENDER	INCOME_GROUP	RECENT_STAR_STATUS
1			5			87			?		 ?			.				H			M				2					0
2			12			79			R		 2			45				H			M				7					1
3			37			75			S		 1			11				H			F				5					1
4			38			.			U		 2			4				H			F				6					0
5			41			74			R		 2			49				U			F				2					0
6			52			63			U		 3			8				U			M				3					0
7			53			71			R		 3			50				H			M				5					4
8			67			79			C		 2			28				H			F				1					0
9			70			41			C		 3			30				H			F				4					0
10			71			63			R		 2			43				H			F				4					1

	CONTROL_NUM:(1) DICTIONARY => ID
				(2) PROC PRINT => suggests an identification stored as a number
				(3) PROC SQL => # distinct values = total row count
				(4) Classification: analytic character because (a) too many distinct values to classify as
					categorical and (b) labled as a field to identify customers; add leading 00's

 	CLSTR_CODE:	(1) DICTIONARY => Socio-Economic Cluster Code
				(2)	PROC PRINT => suggestive of numbers between 1-50, with missing data
				(3) PROC MEANS => range from 1 to 53, with 454 missing data fields
				(4) PROC FREQ => around 3,000 different values, 218 valued 0, which suggests additional missing data
				(4) Classification: analytic character because (a) over 50 distinct values
					but, (b) will need to confirm value meanings

	DONOR_AGE:	(1) DICTIONARY => Donor age
				(2)	PROC PRINT => suggestive of age, with missing data
				(3) PROC MEANS => range from 0 to 87
				(4) PROC FREQ =>  80 unique values, missing 4795, lots of values from 0-18, will need a closer inspection
				(5) Classification: analytic numeric

	INCOME_GRP:	(1) DICTIONARY => Income Bracket, from 1 to 7
				(2)	PROC PRINT => suggestive of different economic classes by number
				(3) PROC MEANS => range from 1 to 7, missing values for 4392
				(5) Classification: analytic categorical

 	R_STAR_STAT:(1) DICTIONARY => STAR status flag, since June 1994
				(2)	PROC PRINT => suggestive of scale numbers
				(3) PROC MEANS => range from 0 to 22
				(4) PROC FREQ =>  heavy on 0 and 1, could be number of years that donor has reached star status
				(5) Classification: analytic numeric, need confirmation what numbers mean
*/
	/* USE macro variable */
%let VFW_var 	= CONTROL_NUMBER;
%let VFW_ds3	= data610.PROfile;

proc means data=&VFW_ds3 n nmiss min median max mean std; var &VFW_var; run;
proc freq data=&VFW_ds3; tables &VFW_var; run;
proc sql; select count(distinct &VFW_var) from &VFW_ds3; quit;
proc sql; select count(*) from &VFW_ds3; quit; /*run both SQL to compare, should be 1:1 */
proc univariate data=&VFW_ds3 noprint; histogram &VFW_var; run;

/*	DONOR_SEX:	(1) DICTIONARY => Donor gender
				(2) PROC PRINT => suggests gender split by Male and Female
				(3) PROC SQL => 4 total values: A, F, M, U
				(4) Classification: analytic categorical 

	HOME_OWNER:	(1) DICTIONARY => Home Owner flag
				(2) PROC PRINT => suggests binary choice 
				(3) PROC SQL => 2 values: H, U
				(4) Classification: analytic categorical

	SES:		(1) DICTIONARY => A clustering of the levels of CLUSTER_CODE
				(2) PROC PRINT => suggests a limited number of values
				(3) PROC SQL => 4 distinct values and 454 labeled ?, matches missing CLUSTER_CODE
				(4) Classification: analytic categorical

	URBANICITY:	(1) DICTIONARY => Categorization of residency
				(2) PROC PRINT => suggests a limited option for values
				(3) PROC SQL => 5 distinct values and 454 labeled ?
				(4) Classification: analytic categorical

file info analytic:
	Numeric ======>  DONOR_AGE; RECENT_STAR_STATUS;
	Date =========> 
	Categorical ==> INCOME_GROUP; DONOR_GENDER; HOME_OWNER; SES; URBANICITY;
	Character ====>	CONTROL_NUMBER; CLUSTER_CODE;

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	Analyze fourth datafile */

ods select Variables;				
proc contents data=data610.HISTfile; run;
/*
#	Variable					Type	Len	  Format	Informat
1	CONTROL_NUMBER				Num		 8	  BEST12.	BEST32.
2	FREQUENCY_STATUS_97NK		Num		 8	  BEST12.	BEST32.
3	IN_HOUSE					Num		 8	  BEST12.	BEST32.
4	LAST_GIFT_AMT				Num		 8	  BEST12.	BEST32.
5	LIFETIME_AVG_GIFT_AMT		Num		 8	  BEST12.	BEST32.
6	LIFETIME_CARD_PROM			Num		 8	  BEST12.	BEST32.
7	LIFETIME_GIFT_AMOUNT		Num		 8	  BEST12.	BEST32.
8	LIFETIME_GIFT_COUNT			Num		 8	  BEST12.	BEST32.
9	LIFETIME_GIFT_RANGE			Num		 8	  BEST12.	BEST32.
10	LIFETIME_PROM				Num		 8	  BEST12.	BEST32.
11	MONTHS_SINCE_FIRST_GIFT		Num		 8	  BEST12.	BEST32.
12	MONTHS_SINCE_LAST_GIFT		Num		 8	  BEST12.	BEST32.
13	MONTHS_SINCE_LAST_PROM_RESP	Num		 8	  BEST12.	BEST32.
14	MONTHS_SINCE_ORIGIN			Num		 8	  BEST12.	BEST32.
15	PEP_STAR					Num		 8	  BEST12.	BEST32.
16	RECENT_AVG_GIFT_AMT			Num		 8	  BEST12.	BEST32.
17	RECENT_CARD_RESPONSE_COUNT	Num		 8	  BEST12.	BEST32.
18	RECENT_RESPONSE_COUNT		Num		 8	  BEST12.	BEST32.
19	TARGET_B					Num		 8	  BEST12.	BEST32.
20	RECENCY_STATUS_96NK			Char	 1	  $1.		$1.
*/

proc print data=data610.HISTfile (firstobs = 1 obs = 10); run;
/*
Obs	 TARGET_B	CONTROL_NUMBER	MONTHS_SINCE_ORIGIN		IN_HOUSE	PEP_STAR	RECENCY_STATUS_96NK		FREQUENCY_STATUS_97NK	RECENT_AVG_GIFT_AMT		RECENT_RESPONSE_COUNT	RECENT_CARD_RESPONSE_COUNT	MONTHS_SINCE_LAST_PROM_RESP		LIFETIME_CARD_PROM	LIFETIME_PROM	LIFETIME_GIFT_AMOUNT	LIFETIME_GIFT_COUNT		LIFETIME_AVG_GIFT_AMT	LIFETIME_GIFT_RANGE		LAST_GIFT_AMT	MONTHS_SINCE_LAST_GIFT	MONTHS_SINCE_FIRST_GIFT
1	 0			5				101						0			1			A						1						15						1						0							26								19					45				297						35						8.49					15						15				26						92
2	 1			12				137						0			1			S						2						15						4						2							11								32					90				368						25						14.72					20						17				7						122
3	 0			37				113						0			1			S						3						21.67					9						6							14								44					119				603						36						16.75					23						19				6						105
4	 0			38				92						0			1			A						3						13.44					9						4							11								31					96				435						37						11.76					14						15				6						92
5	 0			41				101						0			0			A						1						17.5					2						1							18								30					83				106						12						8.83					20						25				18						92
6	 0			52				101						0			0			A						4						8.33					3						1							19								22					59				128						22						5.82					7						10				19						91
7	 0			53				89						0			1			A						1						18.67					3						3							21								29					72				220						20						11						15						20				21						91
8	 1			67				89						0			1			A						4						5						8						4							12								33					89				101						20						5.05					4						5				9						91
9	 0			70				89						0			1			A						4						5						9						5							17								36					91				171						34						5.03					4						5				17						91
10	 1			71				101						0			1			S						3						8.6						5						4							11								27					62				150						22						6.82					8						8				9						91

	CONTROL_NUM:(1) DICTIONARY => ID
				(2) PROC PRINT => suggests an identification stored as a number
				(3) PROC SQL => # distinct values = total row count
				(4) Classification: analytic character because (a) too many distinct values to classify as
					categorical and (b) labled as a field to identify customers; add leading 00's

 	FREQ_ST_97:	(1) DICTIONARY => Count of Donations between June 1995 and June 1996 (capped at 4)
				(2)	PROC PRINT => suggests a limited number of values
				(3) PROC MEANS => range from 1 to 4
				(4) Classification: analytic numeric, since 2 is twice as much as 1

	IN_HOUSE:	(1) DICTIONARY => Flag for In-House donor program
				(2)	PROC PRINT => suggestive of limited number of values
				(3) PROC MEANS => range from 0 to 1
				(4) Classification: analytic categorical, numerical representation of binary yes/no

	LAST_GIFT:	(1) DICTIONARY => Amount of most recent donation
				(2)	PROC PRINT => suggestive of low numbers for donation amout
				(3) PROC MEANS => range from 0 to 450
				(5) Classification: analytic numeric, dollar values

 	LF_AVG_AMT:	(1) DICTIONARY => Average donation amount, ever
				(2)	PROC PRINT => suggestive of low numbers for donation averages
				(3) PROC MEANS => range from 1.36 to 450
				(5) Classification: analytic numeric, dollar values

	LF_CD_PROM:	(1) DICTIONARY => Number of card promotions, ever
				(2)	PROC PRINT => suggestive of low numbers for responses
				(3) PROC MEANS => range from 2 to 56
				(4) PROC FREQ =>  52 total values
				(5) Classification: analytic numeric, since 2 is twice as much as 1

	LF_GIFT_AMT:(1) DICTIONARY => Total donation amount, ever
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 15 to 3775
				(4) PROC FREQ =>  898 unique values
				(5) Classification: analytic numeric, dollar values

	LF_GIFT_CT:	(1) DICTIONARY => Total number of donations, ever
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 1 to 95
				(4) PROC FREQ =>  74 unique values
				(5) Classification: analytic numeric

	LF_GIFT_RG:	(1) DICTIONARY => Maximum gift amount less minimum gift amount
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 0 to 997
				(4) PROC FREQ =>  226 unique values, 
				(5) Classification: analytic numeric, likely expressed in dollars

	LF_PROM:	(1) DICTIONARY => Count of solicitations ever sent
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 5 to 194
				(4) PROC FREQ =>  143 unique values,
				(5) Classification: analytic numeric, a count of the number of donations from each donor

	MTH_1_GIFT:	(1) DICTIONARY => Months since first donation
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 15 to 260
				(4) PROC FREQ =>  139 unique values
				(5) Classification: analytic numeric

	MTH_LA_GIFT:(1) DICTIONARY => Months since most recent donation
				(2)	PROC PRINT => suggestive of low numbers for values
				(3) PROC MEANS => range from 4 to 27
				(4) PROC FREQ =>  24 unique values
				(5) Classification: analytic numeric

	MTH_PROM_R:	(1) DICTIONARY => Months since last solicitation response
				(2)	PROC PRINT => suggestive of low numbers for values
				(3) PROC MEANS => range from -12 to 36
				(4) PROC FREQ =>  37 unique values, missing 246, (see note)
				(5) Classification: analytic numeric

	MTH_S_ORIG:	(1) DICTIONARY => Months since entry onto the file
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 5 to 137
				(4) PROC FREQ =>  28 unique values
				(5) Classification: analytic numeric

	PEP_STAR:	(1) DICTIONARY => Flag to identify consecutive donors
				(2)	PROC PRINT => suggests a binary option
				(3) PROC MEANS => range from 0 to 1
				(4) PROC FREQ =>  2 unique values
				(5) Classification: analytic categorical, looks to use numbers in place of yes/no

	REC_GIFT_AT:(1) DICTIONARY => Average donation amount to promotions since June 1994
				(2)	PROC PRINT => suggestive of moderate numbers for values
				(3) PROC MEANS => range from 0 to 260
				(4) PROC FREQ =>  814 unique values
				(5) Classification: analytic numeric, likely expressed in dollars

	REC_CARD_CT:(1) DICTIONARY => Count of responses to card promotions since June 1994
				(2)	PROC PRINT => suggestive of low numbers for values
				(3) PROC MEANS => range from 0 to 9
				(4) PROC FREQ =>  10 unique values
				(5) Classification: analytic numeric, even with low number of values, it tracks a count

	REC_RES_CT:	(1) DICTIONARY => Count of responses to promotions since June 1994
				(2)	PROC PRINT => suggestive of low numbers for values
				(3) PROC MEANS => range from 0 to 16
				(4) PROC FREQ =>  17 unique values
				(5) Classification: analytic numeric, even with low number of values, it tracks a count

	TARGET_B:	(1) DICTIONARY => B=Binary, flag for response to 97NK—Target Variable
				(2)	PROC PRINT => binary option
				(3) PROC MEANS => range from 0 to 1
				(4) PROC FREQ =>  2 unique values
				(5) Classification: analytic categorical, (see note)
*/
	/* USE macro variable */
%let VFW_var 	= TARGET_B;
%let VFW_ds4	= data610.HISTfile;

proc means data=&VFW_ds4 n nmiss min median max mean std; var &VFW_var; run;
proc freq data=&VFW_ds4; tables &VFW_var; run;
proc sql; select count(distinct &VFW_var) from &VFW_ds4; quit;
proc sql; select count(*) from &VFW_ds4; quit; /*run both SQL to compare, should be 1:1 */
proc univariate data=&VFW_ds4 noprint; histogram &VFW_var; run;

/*	REC_STAT_96:(1) DICTIONARY => Categorization of donation patterns
				(2) PROC PRINT => suggests limited options
				(3) PROC SQL => 6 total values: A, E, F, L, N, S
				(4) Classification: analytic categorical 


file info analytic:
Numeric ======>  FREQUENCY_STATUS_97NK; LAST_GIFT_AMT; LIFETIME_AVG_GIFT_AMT;
	LIFETIME_CARD_PROM; LIFETIME_GIFT_AMOUNT; LIFETIME_GIFT_COUNT; 
	LIFETIME_GIFT_RANGE; LIFETIME_PROM; MONTHS_SINCE_FIRST_GIFT; 
	MONTHS_SINCE_LAST_GIFT; MONTHS_SINCE_LAST_PROM_RESP; MONTHS_SINCE_ORIGIN; 
	PEP_STAR; RECENT_AVG_GIFT_AMT; RECENT_CARD_RESPONSE_COUNT; RECENT_RESPONSE_COUNT
Date =========> 
Categorical ==> IN_HOUSE; TARGET_B; RECENCY_STATUS_96NK;
Character ====>	CONTROL_NUMBER;

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 All variables categorized:
 
1---Numeric =======> WEALTH_RATING;  MEDIAN_HOME_VALUE;  MEDIAN_HOUSEHOLD_INCOMEMED_HM_VAL; 	MED_HH_INC; 
					 PCT_OWNER_OCCUPIED;   PCT_VIETNAM_VETERANS;   PER_CAPITA_INCOME;
	Character =====> CONTROL_NUMBER;
	
2---Categorical ===> SURVEY_VALUE;
	Character =====> CONTROL_NUMBER; 	SURVEY_QUESTIONS;

3---Numeric === ===> DONOR_AGE; RECENT_STAR_STATUS;
	Categorical ===> INCOME_GROUP; DONOR_GENDER; HOME_OWNER; SES; URBANICITY;
	Character =====> CONTROL_NUMBER; CLUSTER_CODE;

4---Numeric =======> FREQUENCY_STATUS_97NK; LAST_GIFT_AMT; LIFETIME_AVG_GIFT_AMT;
					 LIFETIME_CARD_PROM; LIFETIME_GIFT_AMOUNT; LIFETIME_GIFT_COUNT; 
					 LIFETIME_GIFT_RANGE; LIFETIME_PROM; MONTHS_SINCE_FIRST_GIFT; 
					 MONTHS_SINCE_LAST_GIFT; MONTHS_SINCE_LAST_PROM_RESP; MONTHS_SINCE_ORIGIN; 
					 PEP_STAR; RECENT_AVG_GIFT_AMT; RECENT_CARD_RESPONSE_COUNT; RECENT_RESPONSE_COUNT
	Categorical ===> IN_HOUSE; TARGET_B; RECENCY_STATUS_96NK;
	Character =====> CONTROL_NUMBER;

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
/*	Notes

missing values:	WEALTH_RATING, MEDIAN_HOME_VALUE(0), MEDIAN_HOUSEHOLD_INCOME(0),
				PCT_OWNER_OCCUPIED(0), CLUSTER_CODE, DONOR_AGE(0), INCOME_GROUP,
				SES, URBANICITY, MONTHS_SINCE_LAST_PROM_RESP
confirm these fields are in dollar amounts: LAST_GIFT_AMT, LIFETIME_GIFT_RANGE,
				LIFETIME_GIFT_AMOUNT, LIFETIME_AVG_GIFT_AMT, LIFETIME_MIN_GIFT_AMT, 
				LIFETIME_MAX_GIFT_AMT, RECENT_AVG_GIFT_AMT
confirm MEDIAN_HOME_VALUE are in $1000's
define relationship between WEALTH_RATING scores?
confirm PCT_OWNER_OCCUPIED definition (percent of mortgage?) and 0 values (renters?)
what does PCT_VIETNAM_VETERANS measure? it seems it should be a binary choice
PER_CAPITA_INCOME : MEDIAN_HOUSEHOLD_INCOME show a difference between their 0 values (173:174)
confirm CONTROL_NUMBER is just a character identification, and does not have any computation meaning
confirm CAUSES_DONATED_TO_LAST_YEAR is numeric or categorical?
what does Socio-Economic CLUSTER_CODE define? should it be categorical or character?
DONOR_AGE has values from 0-18: It does not make sense that babies and minors are donating
need more info on INCOME_GROUP, how does it relate to MEDIAN_INCOME, PER_CAPITA_INCOME, and WEALTH_RATING
needs more explanation for DONOR_GENDER -- A and U and how they should be categorized
need more info on HOME_OWNER, what are categories and confirm it determines home ownership
how does SES relate to CLUSTER_CODE
how does URBANICITY relate to SES and CLUSTER_CODE
confirm LAST_GIFT_AMT does have donations with decimals
MONTHS_SINCE_LAST_PROM_RESP has negative (-) numbers, that does not make sense
how does TARGET_B relate to FREQUENCY_STATUS_97NK
how does MONTHS_SINCE_ORIGIN have a smaller range than MONTHS_SINCE_FIRST_GIFT

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
/*	sort for below processes */
proc sort data=data610.CNSSfile; by control_number; run;
proc sort data=data610.SURVfile; by control_number; run;
proc sort data=data610.HISTfile 
	out=data610.merge_HISTfile; by control_number; run;
proc sort data=data610.PROfile 
	out=data610.merge_PROfile; by control_number; run;

/* 	Transpose DONOR_SURVEY2 into wide file with number of records to match other datasets*/
proc transpose data=data610.SURVfile out=data610.SURVfile_trans;
    by CONTROL_NUMBER;
    id survey_question;  	/* create columns labeled by survey_question */
    var survey_value; run;  /* answers go under the new columns */

data data610.SURVfile_wide;
	set data610.SURVfile_trans;
    rename 
        "causes donated to last year"n = CAUSES_DONATED_TO_LAST_YEAR
        "familiarity with programs"n = FAMILIARITY_WITH_PROGRAMS
        "willingness to recommend"n = WILLINGNESS_TO_RECOMMEND; run;

data data610.merge_SURVfile;
	set data610.SURVfile_wide;
    keep CONTROL_NUMBER CAUSES_DONATED_TO_LAST_YEAR FAMILIARITY_WITH_PROGRAMS WILLINGNESS_TO_RECOMMEND;
run;

/* Convert numeric to character with leading zeros */
data data610.merge_cnssfile;
    set data610.cnssfile;
    CONTROL_NUMBER_num = input(compress(CONTROL_NUMBER), 8.);
    drop CONTROL_NUMBER;
    rename CONTROL_NUMBER_num = CONTROL_NUMBER; run;

/*	merge all 4 files*/

data Merge_3;
    merge data610.merge_CNSSfile (in=a) data610.merge_HISTfile (in=b);
    by CONTROL_NUMBER; run;

data Merge_2;
    merge Merge_3 (in=a) data610.merge_PROfile (in=b);
    by CONTROL_NUMBER; run;

data data610.Donor_Merged;
    merge Merge_2 (in=a) data610.merge_SURVfile (in=b);
    by CONTROL_NUMBER; run;


proc print data=data610.Donor_Merged (firstobs = 1 obs = 25); run;

/*	end	 */
