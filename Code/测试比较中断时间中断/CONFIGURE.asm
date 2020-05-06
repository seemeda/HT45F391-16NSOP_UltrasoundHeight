INCLUDE		HT45F391.INC
;#define		P_BUZZ				PA.2
;;CHECKSUM A932H
;;CHECKCODE 609BH
;400us为一级，1ms=17cm,400us=17/2.5=6.8cm	; GAIN * 0.5DB = X DB
;#define		GAIN_0				    2	
;#define		GAIN_1					4	
;#define		GAIN_2					6 	
;#define		GAIN_3					8 
;#define		GAIN_4					10 	
;#define		GAIN_5					12	
;#define	 	GAIN_6					14 	
;#define		GAIN_7					16
;#define		GAIN_8					32
;#define		GAIN_9					34	
;#define		GAIN_10					36
;#define		GAIN_11					38
;#define		GAIN_12					40	
;#define	    GAIN_13                 42
;#define	    GAIN_14                 44
;#define	    GAIN_15                 46
;#define	    GAIN_16                 34
;#define	    GAIN_17                 36
;#define	    GAIN_18                 38
;#define	    GAIN_19                 40
;#define	    GAIN_20                 42
;#define	    GAIN_21                 44
;#define	    GAIN_22                 46
;#define	    GAIN_23                 48
;#define	    GAIN_24                 50
;#define	    GAIN_25                 52
;#define	    GAIN_26                 54
;#define	    GAIN_27                 56
;#define	    GAIN_28                 58
;#define	    GAIN_29                 60  
;#define	    GAIN_30                 62
;#define	    GAIN_31                 62
;;;32cm-52cm会重叠5-9
;;;32cm-52cm会重叠5-9
#define		GAIN_0				    1;
#define		GAIN_1					1;
#define		GAIN_2					2; 	
#define		GAIN_3					2;
#define		GAIN_4					3;	
#define		GAIN_5					6;
#define	 	GAIN_6					22;	
#define		GAIN_7					23;
#define		GAIN_8					25;
#define		GAIN_9					26;	
#define		GAIN_10					28;   ;;80cm-160cm,11-23变小
#define		GAIN_11					30;
#define		GAIN_12					34;
#define	    GAIN_13                 34;
#define	    GAIN_14                 34;35;
#define	    GAIN_15                 35;
#define	    GAIN_16                35;
#define	    GAIN_17                35;34;
#define	    GAIN_18                36;35; 
#define	    GAIN_19                37;35;
#define	    GAIN_20                38;35; 
#define	    GAIN_21                38;35; v4 36 
#define	    GAIN_22                38;35;  
#define	    GAIN_23                38;35;  
;#define	    GAIN_24                36; 
;#define	    GAIN_25                 37;38; 
;#define	    GAIN_26                 38;39; 
;#define	    GAIN_27                 39;40; 
;#define	    GAIN_28                 40;41;
;#define	    GAIN_29                 41;42;
;#define	    GAIN_30                 42;43;
;#define	    GAIN_31                 43;44;
#define	    GAIN_24                 38 ; 
#define	    GAIN_25                 40 ;
#define	    GAIN_26                 40 ;
#define	    GAIN_27                 44 ; 
#define	    GAIN_28                 48 ;
#define	    GAIN_29                 52 ;
#define	    GAIN_30                 56 ;
#define	    GAIN_31                 56 ;

;;;;阀值设置
#define		ADJ_THRESHOLD_VALUE_0		30
#define		ADJ_THRESHOLD_VALUE_1		30 
#define		ADJ_THRESHOLD_VALUE_2		30		 
#define		ADJ_THRESHOLD_VALUE_3		30
#define		ADJ_THRESHOLD_VALUE_4		30
#define		ADJ_THRESHOLD_VALUE_5		30 
#define		ADJ_THRESHOLD_VALUE_6		30
#define		ADJ_THRESHOLD_VALUE_7		30
#define		ADJ_THRESHOLD_VALUE_8		30
#define		ADJ_THRESHOLD_VALUE_9		30
#define		ADJ_THRESHOLD_VALUE_10		30
#define		ADJ_THRESHOLD_VALUE_11		30
#define		ADJ_THRESHOLD_VALUE_12		30	
#define	    ADJ_THRESHOLD_VALUE_13      30
#define	    ADJ_THRESHOLD_VALUE_14      30
#define	    ADJ_THRESHOLD_VALUE_15      30
#define	    ADJ_THRESHOLD_VALUE_16      30
#define	    ADJ_THRESHOLD_VALUE_17      30 ;29  
#define	    ADJ_THRESHOLD_VALUE_18      30 ;29
#define	    ADJ_THRESHOLD_VALUE_19      30
#define	    ADJ_THRESHOLD_VALUE_20      30
#define	    ADJ_THRESHOLD_VALUE_21      30
#define	    ADJ_THRESHOLD_VALUE_22      30
#define	    ADJ_THRESHOLD_VALUE_23      33
;#define	    ADJ_THRESHOLD_VALUE_24      40
;#define	    ADJ_THRESHOLD_VALUE_25      40
;#define	    ADJ_THRESHOLD_VALUE_26      40
;#define	    ADJ_THRESHOLD_VALUE_27      40
;#define	    ADJ_THRESHOLD_VALUE_28      40
;#define	    ADJ_THRESHOLD_VALUE_29      40
;#define	    ADJ_THRESHOLD_VALUE_30      40
;#define	    ADJ_THRESHOLD_VALUE_31	    40
#define	    ADJ_THRESHOLD_VALUE_24      33
#define	    ADJ_THRESHOLD_VALUE_25      33
#define	    ADJ_THRESHOLD_VALUE_26      33
#define	    ADJ_THRESHOLD_VALUE_27      33
#define	    ADJ_THRESHOLD_VALUE_28      28
#define	    ADJ_THRESHOLD_VALUE_29      24
#define	    ADJ_THRESHOLD_VALUE_30      24
#define	    ADJ_THRESHOLD_VALUE_31	    24
	
#define		C_ECHO_REFERENCE_ADJ		5 ;5
#define		C_ECHO_REFERENCE_ADJ_MAX	20 ;65;60
#define		C_AFTERSHOCK_TIME_ADJ		1 ;5
#define		C_DISTANCE_ADJ				50 ;

;限定余震的最大和最小值
#define		C_MAX_AFTERSHOCK_TIME		25
#define		C_MIN_AFTERSHOCK_TIME		12

CONFIG		.SECTION	AT LASTPAGE	'CODE'
CFG_GAIN:
DW	GAIN_0
DW	GAIN_1
DW	GAIN_2
DW	GAIN_3
DW	GAIN_4
DW	GAIN_5
DW	GAIN_6
DW	GAIN_7
DW	GAIN_8
DW	GAIN_9
DW	GAIN_10
DW	GAIN_11
DW	GAIN_12
DW	GAIN_13
DW	GAIN_14
DW	GAIN_15
DW	GAIN_16
DW	GAIN_17
DW	GAIN_18
DW	GAIN_19
DW	GAIN_20
DW	GAIN_21
DW	GAIN_22
DW	GAIN_23
DW	GAIN_24
DW	GAIN_25
DW	GAIN_26
DW	GAIN_27
DW	GAIN_28
DW	GAIN_29
DW	GAIN_30
DW	GAIN_31
CFG_THRESHOLD_VALUE:
DW	ADJ_THRESHOLD_VALUE_0
DW	ADJ_THRESHOLD_VALUE_1
DW	ADJ_THRESHOLD_VALUE_2
DW	ADJ_THRESHOLD_VALUE_3
DW	ADJ_THRESHOLD_VALUE_4
DW	ADJ_THRESHOLD_VALUE_5
DW	ADJ_THRESHOLD_VALUE_6
DW	ADJ_THRESHOLD_VALUE_7
DW	ADJ_THRESHOLD_VALUE_8
DW	ADJ_THRESHOLD_VALUE_9
DW	ADJ_THRESHOLD_VALUE_10
DW	ADJ_THRESHOLD_VALUE_11
DW	ADJ_THRESHOLD_VALUE_12
DW	ADJ_THRESHOLD_VALUE_13
DW	ADJ_THRESHOLD_VALUE_14
DW	ADJ_THRESHOLD_VALUE_15
DW	ADJ_THRESHOLD_VALUE_16
DW	ADJ_THRESHOLD_VALUE_17
DW	ADJ_THRESHOLD_VALUE_18
DW	ADJ_THRESHOLD_VALUE_19
DW	ADJ_THRESHOLD_VALUE_20
DW	ADJ_THRESHOLD_VALUE_21
DW	ADJ_THRESHOLD_VALUE_22
DW	ADJ_THRESHOLD_VALUE_23
DW	ADJ_THRESHOLD_VALUE_24
DW	ADJ_THRESHOLD_VALUE_25
DW	ADJ_THRESHOLD_VALUE_26
DW	ADJ_THRESHOLD_VALUE_27
DW	ADJ_THRESHOLD_VALUE_28
DW	ADJ_THRESHOLD_VALUE_29
DW	ADJ_THRESHOLD_VALUE_30
DW	ADJ_THRESHOLD_VALUE_31

CFG_MAX_AFTERSHOCK_TIME:
DW	C_MAX_AFTERSHOCK_TIME

CFG_MIN_AFTERSHOCK_TIME:
DW	C_MIN_AFTERSHOCK_TIME

CFG_DISTANCE_ADJ:
DW	C_DISTANCE_ADJ

CFG_AFTERSHOCK_TIME_ADJ:
DW	C_AFTERSHOCK_TIME_ADJ

CFG_ECHO_REFERENCE_ADJ_MAX:
DW	C_ECHO_REFERENCE_ADJ_MAX

CFG_ECHO_REFERENCE_ADJ:
DW	C_ECHO_REFERENCE_ADJ

CFG_SYS:
;    BIT7   BIT6     BIT5     BIT4     BIT3     BIT2     BIT1     BIT0
;   SYSCLK   --       --       --       --       --       --     SENSORFRQ   
;SYSCLK
;0:timer0 使用内部fsys/16时钟源
;1:timer0 使用外部100k时钟源
;
;SENSORFRQ
;0:40K, 1:58K
DW	10000000B

R_T_TAB:

;温度
;	-20		-19
DW	63582,	60647
;	-18		-17		-16		-15		-14		-13
DW	57873,	55249,	52766,	50416,	48191,	46082
;DW	63957,	60700,	57631,	54740
;;	-12		-11		-10		-9		-8		-7
DW	44083,	42187,	40388,	38679,	37055,	35512
;DW	52014,	49444,	47018,	44729,	42567,	40521
;;	-6		-5		-4		-3		-2		-1
DW	34044,	32647,	31316,	30048,	28840,	27687
;DW	38594,	36769,	35043,	33410,	31864,	30400
;;	0		1		2		3		4		5
DW	26587,	25559,	24553,	23574,	22627,	21712		
;DW	29014,	27700,	26455,	25274,	24153,	23090
;;	6		7		8		9		10		11
DW	20833,	19991,	19185,	18416,	17682,	16984
;DW	22081,	21123,	20212,	19347,	18525,	17743
;;	12		13		14		15		16		17
DW	16319,	15686,	15083,	14510,	13964,	13443
;DW	16999,	16291,	15618,	15552,	14365,	13783
;;	18	 	19		20		21		22		23
DW	12947,	12472,	12018,	11582,	11164,	10762
;DW	13228,	12700,	12195,	11714,	11255,	10817
;;	24		25		26		27		28		29
DW	10374,	10000,	9577,	9234,	8853,	8512
;DW	10399,	10000,	9618,	9253,	8905,	8572
;;	30		31		32		33		34		35
DW	8185,	7865,	7583,	7313,	7063,	6869
;DW	8253,	7948,	7656,	7377,	7110 ,	6854
;;	36		37		38		39		40		41
DW	6641,	6404,	6177,	5958,	5749,	5548	
;DW	6609,	6374,	6149,	5933,	5726,	5528
;;	42		43		44		45		46		47
DW	5355,	5170,	4992,	4822,	4658,	4500
;DW	5337,	5154,	4979,	4811,	4649,	4494
;;	48		49		50		51		52		53
DW	4349,	4204,	4065,	3931,	3802,	3678
;DW	4345,	4201,	4064,	3931,	3804,	3681
;;	54		55		56		57		58		59
DW	3559,	3445,	3335,	3229,	3127,	3029
;DW	3564,	3450,	3341,	3236,	3135,	3038







PUBLIC	R_T_TAB
PUBLIC	CFG_GAIN
PUBLIC  CFG_THRESHOLD_VALUE
PUBLIC	CFG_MAX_AFTERSHOCK_TIME
PUBLIC	CFG_MIN_AFTERSHOCK_TIME
PUBLIC	CFG_DISTANCE_ADJ
PUBLIC	CFG_AFTERSHOCK_TIME_ADJ
PUBLIC	CFG_ECHO_REFERENCE_ADJ_MAX
PUBLIC	CFG_ECHO_REFERENCE_ADJ
PUBLIC	CFG_SYS