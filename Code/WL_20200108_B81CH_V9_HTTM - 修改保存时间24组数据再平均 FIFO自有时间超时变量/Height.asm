include HT45F391.INC
include	MACRO.INC
include	define.asm
INCLUDE MEASURE.INC
include USER.inc
INCLUDE CONFIGURE.INC
INCLUDE	UART.INC
;;checksum B552H
;;checkcode 8E97H

RAMBANK		0	RAMBANK0
RAMBANK0	.SECTION	'data'

;R_TEMPL					DB		?
;R_TEMPH					DB		?
;__R_DISTANCE0_H			DB		?
;__R_DISTANCE0_L			DB		?
;
;__R_DISTANCE_ACC_L		DB		?
;__R_DISTANCE_ACC_H		DB		?	
;__R_CHECKSUM			DB		?
;__R_DISTANCE1_H			DB		?
;__R_DISTANCE1_L			DB		?
;__R_DISTANCE2_H			DB		?
;__R_DISTANCE2_L			DB		?
;__R_DISTANCE3_H			DB		?
;__R_DISTANCE3_L			DB		?
;__R_DISTANCE4_H			DB		?
;__R_DISTANCE4_L			DB		?

__R_BACKUP_STATUS		   DB		?
__R_BACKUP_ACC		 	   DB		?

__R_DISTANCE_TIMES		   DB		?
__R_HEIGHT_DISTANCE_H	   	DB		?
__R_HEIGHT_DISTANCE_L	   	DB		?
__R_HEIGHT_DISTANCE		   DB		?
__R_MAX_DISTANCE_H		   DB		?
__R_MAX_DISTANCE_L		   DB		?
__BUFF_DISTANCE_L           	 DB	    24	DUP(0)   ;;存放24组距离的低位
__BUFF_DISTANCE_H           	 DB	    24	DUP(0)   ;;存放24组距离的高位
__BUFF_DISTANCE_ADDRH        	DB	    ?
__BUFF_DISTANCE_ADDRL       	 DB	    ?
__R_COURT                   	 DB	    ?
;__R_CHECKSUM_H			   DB		? 
;__R_CHECKSUM_L			   DB		?
__R_DISTANCE_TIME		   DB		?
__R_ZERO                   	DB		?

__R_TOM			           DB		?

;;-----------------
F_MY_TEST				DBIT ;;TEST+
F_MY_TEST_VAR			DBIT ;;TEST+
;;--------------

F_MIN_MAX				DBIT
f_cmd_distance			DBIT			;transmit distance data command
f_cmd_disconnect		DBIT			;disconnect
err_byte				DBIT			;data receive error
flag_num_0				DBIT
F_AVERAGE				DBIT
F_GET_TEMPERATURE_DATA	DBIT
;F_CLEAR              	DBIT
;F_DETEC              	DBIT
;F_QUERY              	DBIT
;;--------------------------------------------
CS	.SECTION	at  000H 'CODE'
	ORG		000H
	JMP		main_start
	ORG		004H
	;;JMP AEC_INT
	RETI
	ORG		008H
	;JMP		FIFO_INT
	RETI
	ORG		00CH
	JMP		CCRA_CTM_INT		
	ORG		010H
	RETI	
	ORG		014H
	RETI
	ORG		018H
	RETI	 
	ORG		01CH
	RETI	
	ORG		020H
	RETI	
	ORG		024H
	RETI	
	ORG		028H
	RETI	

;;--------------------------------------------
main_start:	
;	CLR	   PBC0
;	SET	   PB0             	
;	CLR	   PBC2
;	SET	   PB2
;	CLR    __R_MAX_DISTANCE_H
;	CLR    __R_MAX_DISTANCE_L
;	CLR    __R_HEIGHT_DISTANCE_H	
;    CLR    __R_HEIGHT_DISTANCE_L
;    CLR    __R_HEIGHT_DISTANCE
;    CLR    __R_ZERO
;    MOVF    __R_DISTANCE_TIME,32		  
	CALL   __SBR_SYS_INIT
	CALL	SBR_USER_INIT
		
get_dvcm:
    SET	   PAPU6
    SET	   PAC6
    CLR	   PAC4
    SET    PA4
    CLR	   PBC0
	SET	   PB0             	
	CLR	   PBC2
	SET	   PB2
    CLR	   __BUFF_DISTANCE_ADDRH       
    CLR     __BUFF_DISTANCE_ADDRL        
	CLR    __R_MAX_DISTANCE_H
	CLR    __R_MAX_DISTANCE_L
	CLR    __R_HEIGHT_DISTANCE_H	
    CLR    __R_HEIGHT_DISTANCE_L
    CLR    __R_HEIGHT_DISTANCE
    CLR    __R_ZERO
    MOVF    __R_DISTANCE_TIME,24
;	CALL	__SBR_GET_DVCM
    MOVF	DVCM,80h
	CALL	__SBR_GET_BIAS	
	CLR		F_AVERAGE
	CLR		F_GET_TEMPERATURE_DATA
;	SET	SCFCTL.6
Main_Loop:

	call	TM0_internal_setting	
	call	SBR_INIT_TM1_UART
	;;TEST+
	CLR __BUFF_DATA[0]
	CLR F_MY_TEST_VAR
	CLR	__F_GET_DISTANCE  ;;TEST+
IF 0 ;;TEST
wait_1ms_lowpulse:	
	
	clr	__R_TIMER_100US
	
waiting_filter:

	CLR	WDT
	sz	pa.6
	jmp	wait_1ms_lowpulse
	
	mov	a,__R_TIMER_100US	
	sub	a,9
	snz	C
	jmp	waiting_filter

wait_highpulse:
	
	mov	a,__R_TIMER_100US
	sub	a,15
	sz	C
	jmp	wait_1ms_lowpulse
	
	CLR	WDT
	
	snz	pa.6
	jmp	wait_highpulse	
 
wait_high_over:

	mov	a,__R_TIMER_100US
	sub	a,25
	sz	C
	jmp	wait_1ms_lowpulse
	
	CLR	WDT
	
	sz	pa.6
	jmp	wait_high_over	

wait_100us_high:
	
Read_data_command:
	
	clr	WDT
	call	SBR_UART_READ
;***************************************************

	clr	WDT
	
	
;***************************************************		
	mov	a,RX_DATA
	xor	a,55h
	snz	Z
	jmp	wait_1ms_lowpulse
;jmp	wait_1ms_lowpulse
ENDIF ;;TEST

;;
;;Det_Loop: 循环进行测温，发送触发超波40KHZ测距，执行Det_Loop循环24次得到24组数据,退出并处理数据.
;;
;;__F_TIMEUP延时20ms,这里延时20ms和 L__SBR_DISTANCE_MEASURE_EXIT: 也延时20ms，
;;所以每发射4个触发脉冲测量一次距离至少需要40ms为一个周期,
;;	即发送脉冲测距到下次再次发送脉冲测距时间差40ms。
;;因此：
;;完成24组测量距离需要时间为:40ms*24=960ms,即一个大周期至少为960ms
Det_Loop: 
	call	 SBR_INIT_TM1_T	;;定时1.02ms
	call	TM0_external_setting	;;定时计数，外部时钟100KHz，定时器初始化100us

    CLR	    T0ON
	SET	    T0ON
	CLR     __R_TIMER_20MS
$0:
	CLR		WDT	
	MOV     A, __R_TIMER_20MS
;	SUB     A, 1 ;;TEST-
	SUB     A, 2  ;;TEST+
	SNZ     C 
	JMP     $0 ;;delay 20ms
	CLR     __R_TIMER_20MS
	JMP     L_GET_RES_DISCHARGE_TIME 
L_GET_RES_DISCHARGE_TIME:

	SZ		F_GET_TEMPERATURE_DATA
	JMP		L_DISTANCE_MEASURE
	
	CALL	SBR_INIT_TM1
	SET		F_GET_NTC
	CALL	SBR_GET_TEMPERATURE
	MOVF	R_RES_DISCHARGE_TIME_H,R_TEMP1
	MOVF	R_RES_DISCHARGE_TIME_L,R_TEMP0		
	CLR		F_GET_NTC
	CALL	SBR_GET_TEMPERATURE
	CALL	SBR_CALC_TEMPERATURE
	CALL	__SBR_CALC_SOUND_SPEED
	SET		F_GET_TEMPERATURE_DATA	
    
L_DISTANCE_MEASURE:	
    
	MOVF	__R_GENERATE_ULTRASONIC_NUM,4;4 
	CALL	__SBR_DISTANCE_MEASURE	
	CALL 	__MY_CALC_TIME ;;TEST+
	;;CALL	__SBR_CALC_DISTANCE ;;TEST-
;;;;;;;;;;;;;
;;存放24组测量到的距离数据   
    MOV     A , OFFSET __BUFF_DISTANCE_H     
    ADD     A , __BUFF_DISTANCE_ADDRH
    MOV     MP0 , A
    MOVF    IAR0 , __R_DISTANCE_H
 
    MOV     A , OFFSET __BUFF_DISTANCE_L 
    ADD     A , __BUFF_DISTANCE_ADDRL
    MOV     MP0 , A 
    MOVF    IAR0 , __R_DISTANCE_L
  
    INC     __BUFF_DISTANCE_ADDRL
    INC     __BUFF_DISTANCE_ADDRH

;	MOV     A,__R_DISTANCE_L
;	ADDM    A ,__R_HEIGHT_DISTANCE_L
;	MOV     A,__R_DISTANCE_H 
;	ADCM    A ,__R_HEIGHT_DISTANCE_H
;	SNZ     C
;	JMP     $0
;	INC __R_HEIGHT_DISTANCE
$0:	
   
	SDZ     __R_DISTANCE_TIME
	JMP		Det_Loop;Main_Loop

    MOVF    __R_DISTANCE_TIME, 24  
;     MOVF	RX_DATA,0ffh
;	CALL	SBR_UART_SND
 
EXSORT_LOOP:
    CLR	      WDT
    MOVF    __R_COURT,23
    MOVF     MP0 , OFFSET __BUFF_DISTANCE_L 
    MOVF     MP1 , OFFSET __BUFF_DISTANCE_H 
    
;$7:	
;
;    CLR	     WDT
;   	MOVF	RX_DATA,IAR0
;	CALL	SBR_UART_SND
;	MOVF	RX_DATA,IAR1
;	CALL	SBR_UART_SND
;    INC    MP0
;    INC    MP1
;    SDZ     __R_COURT
;	JMP		$7
;	 MOVF	RX_DATA,0DDh
;	CALL	SBR_UART_SND
;	MOVF    __R_COURT,23
;	MOVF     MP0 , OFFSET __BUFF_DISTANCE_L 
;    MOVF     MP1 , OFFSET __BUFF_DISTANCE_H
;;
;;24组距离，把距离按从小到大顺序排序
;;
INSORT_LOOP: 
    CLR	     WDT
    CLR     __R_TEMP0
    CLR     __R_TEMP1
    CLR     __R_TEMP2
    CLR     __R_TEMP3
    
    MOVF    __R_TEMP0, IAR0
    INC      MP0
    MOVF    __R_TEMP1, IAR0 
    
    MOVF    __R_TEMP2, IAR1
    INC      MP1
    MOVF    __R_TEMP3, IAR1
    
    MOV     A,__R_TEMP3
    XOR     A,__R_TEMP2
    SNZ     Z
    JMP     $1     
    MOV     A,__R_TEMP1
    SUB     A,__R_TEMP0  ;;;
    SNZ     C
    JMP     $2        
    JMP     $3        
$1:  
    MOV    A, __R_TEMP3
    SUB    A, __R_TEMP2 
    SNZ    C
    JMP     $2       ;;    
    JMP     $3       ;;    
$2:    
    MOVF   IAR1,__R_TEMP2  
    MOVF   IAR0,__R_TEMP0 
    DEC    MP1
    DEC    MP0
    MOVF   IAR1,__R_TEMP3  
    MOVF   IAR0,__R_TEMP1
    INC    MP1
    INC    MP0
$3:
    SDZ     __R_COURT
	JMP		INSORT_LOOP
	;;TEST+---
	IF 0
	SZ F_MY_TEST_VAR
	JMP MY_EXSORT_LOOP_TIME
	ENDIF
	;;TEST+---
	SDZ     __R_DISTANCE_TIME 
	JMP		EXSORT_LOOP 
	MOVF    __R_DISTANCE_TIME, 16	
	MOV     A , OFFSET __BUFF_DISTANCE_L    
	ADD     A,4
	MOV      MP0 ,A
    MOV     A , OFFSET __BUFF_DISTANCE_H   
    ADD     A,4
	MOV     MP1 ,A
;	MOVF    __R_DISTANCE_TIME, 24	
;	MOV     A , OFFSET __BUFF_DISTANCE_L    
;	MOV      MP0 ,A
;    MOV     A , OFFSET __BUFF_DISTANCE_H      
;	MOV      MP1 ,A
;	MOVF	RX_DATA,0aah
;	CALL	SBR_UART_SND
;;
;; 这里$4循环累加24组距离中16组数据，从第四组开始，即：第4组~19组，
;; 把累加距离存放在__R_HEIGHT_DISTANCE, __R_HEIGHT_DISTANCE_H, __R_HEIGHT_DISTANCE_L
;;
$4:	
    CLR	     WDT
    MOV     A,IAR0
	ADDM    A ,__R_HEIGHT_DISTANCE_L
	MOV     A,IAR1 
	ADCM    A ,__R_HEIGHT_DISTANCE_H
	SNZ     C
	JMP     $6
	INC     __R_HEIGHT_DISTANCE
  ;  CLR	     WDT
;   	MOVF	RX_DATA,IAR0
;	CALL	SBR_UART_SND
;	MOVF	RX_DATA,IAR1
;	CALL	SBR_UART_SND
$6:	
   ;  MOVF	RX_DATA,IAR0
;	CALL	SBR_UART_SND
;	MOVF	RX_DATA,IAR1
;	CALL	SBR_UART_SND
    INC    MP0
    INC    MP1
    SDZ     __R_DISTANCE_TIME
	JMP		$4

;;
;;下面求累加16组距离的平均值
;;	
	CLR     C      
	RRC     __R_HEIGHT_DISTANCE                       
	RRC     __R_HEIGHT_DISTANCE_H
	RRC     __R_HEIGHT_DISTANCE_L
	CLR     C 
	RRC     __R_HEIGHT_DISTANCE                              
	RRC     __R_HEIGHT_DISTANCE_H
	RRC     __R_HEIGHT_DISTANCE_L
	CLR     C     
	RRC     __R_HEIGHT_DISTANCE                         
	RRC     __R_HEIGHT_DISTANCE_H
	RRC     __R_HEIGHT_DISTANCE_L
	CLR     C 
	RRC     __R_HEIGHT_DISTANCE                            
	RRC     __R_HEIGHT_DISTANCE_H
	RRC     __R_HEIGHT_DISTANCE_L
;	CLR     C       
;	RRC     __R_HEIGHT_DISTANCE                      
;	RRC     __R_HEIGHT_DISTANCE_H
;	RRC     __R_HEIGHT_DISTANCE_L

	;SNZ     __F_GET_DISTANCE    ;;;;;测不到距离，那么距离为0，所以不能减29
;	JMP     $5
;	MOV    A, __R_HEIGHT_DISTANCE_L
;	SUB    A,29
;	MOV    __R_HEIGHT_DISTANCE_L,A
;	MOV    A, __R_HEIGHT_DISTANCE_H
;	SBC    A,__R_ZERO
;	MOV    __R_HEIGHT_DISTANCE_H,A
	
$5:	

;;TEST++++++++++++
IF 1

	MOVF	__R_TIME_H, __R_HEIGHT_DISTANCE_H
	MOVF	__R_TIME_L, __R_HEIGHT_DISTANCE_L
	CALL	MY_CALC_DISTANCE
	
ENDIF
;;TEST++++++++++++++++++++

;***********數據顯示******************

    MOVF    __R_DISTANCE_H ,__R_HEIGHT_DISTANCE_H
    MOVF    __R_DISTANCE_L ,__R_HEIGHT_DISTANCE_L
    CLR     __R_HEIGHT_DISTANCE_H
    CLR     __R_HEIGHT_DISTANCE_L
    MOVF    __R_DISTANCE_TIME ,24
    CLR	    __BUFF_DISTANCE_ADDRH       
    CLR     __BUFF_DISTANCE_ADDRL  
;	MOVF	RX_DATA,__R_ADCOMPARE_VALUE 
;	CALL	SBR_UART_SND
;   JMP		Main_Loop

    ;;TEST+------------------------------------ 
    IF 0
    ;;先获取3个距离数据，然后从小到大排序,再比较大小，最符合范围的数据累加后平均输出.
   
MY_MANAGE_DISTANCE: 	
	;;__BUFF_DATA[1]~__BUFF_DATA[3]:数据高位
	;;__BUFF_DATA[4]~__BUFF_DATA[6]:数据低位
    INC 	__BUFF_DATA[0]
    MOV     A , OFFSET __BUFF_DATA     
    ADD     A , __BUFF_DATA[0]
    MOV     MP0 , A
    MOVF    IAR0 , __R_DISTANCE_H

    MOV     A , OFFSET __BUFF_DATA[3]     
    ADD     A , __BUFF_DATA[0]
    MOV     MP0 , A
    MOVF    IAR0 , __R_DISTANCE_L
    
    MOV 	A,2
    SUB 	A,__BUFF_DATA[0]
    SZ		C
    JMP		Det_Loop 
  
    SET 	F_MY_TEST_VAR
    MOVF 	__R_DISTANCE_TIME,3
MY_EXSORT_LOOP:      
    CLR		WDT
    MOVF	__R_COURT,2
    MOVF	MP0 , OFFSET __BUFF_DATA[4] 
    MOVF	MP1 , OFFSET __BUFF_DATA[1] 
    JMP		INSORT_LOOP
    
MY_EXSORT_LOOP_TIME:
 	SDZ     __R_DISTANCE_TIME 
	JMP		MY_EXSORT_LOOP 
	CLR 	F_MY_TEST_VAR

MY_CMP_DATA:
	;;这个数是排序后的中间值用来做比较值，跟其他数据作比较
	MOVF	__R_TEMP0,__BUFF_DATA[5]	;;L
	MOVF	__R_TEMP1,__BUFF_DATA[2]	;;H
	
	;;3个数据之间误差都不在范围内，则直接选用排序后的中间值
	MOVF    __R_DISTANCE_L,__BUFF_DATA[5]	;;L
	MOVF    __R_DISTANCE_H,__BUFF_DATA[2]	;;H
		
	;;比较大小，把符合误差范围的数据累加后做平均
    CLR 	__R_TEMP8 ;;用来记录符合误差范围的数据个数
    MOVF    __R_COURT,3
    MOVF     MP0 , OFFSET __BUFF_DATA[4] ;;L
    MOVF     MP1 , OFFSET __BUFF_DATA[1] ;;H

$0: 
   	CLR	     WDT
    MOVF    __R_TEMP2, IAR0 ;;L
    INC      MP0 
    MOVF    __R_TEMP3, IAR1 ;;H
    INC     MP1
       
    MOV     A,__R_TEMP3
    XOR     A,__R_TEMP1
    SNZ     Z
    JMP     $6    ;;高位不相等,直接进行下一比较循环 
    MOV     A,__R_TEMP2
    SUB     A,__R_TEMP0  ;;;
    SNZ     C
    JMP     $2        ;;__R_TEMP2 < __R_TEMP0
    JMP     $3        ;;__R_TEMP2 > __R_TEMP0

$2:    
	MOV A,__R_TEMP0
	SUB A,__R_TEMP2
	JMP $4
$3:	
	MOV A,__R_TEMP2
	SUB A,__R_TEMP0
$4:	
	SUB A,6 ;;5mm误差范围
    SNZ     C
    JMP     $5        ;;在误差范围内
    JMP     $6		  ;;超出误差范围，进行下一循环
  
$5:  
    CLR	     WDT
    INC     __R_TEMP8
    
    MOV     A,__R_TEMP2
	ADDM    A ,__R_HEIGHT_DISTANCE_L
	MOV     A,__R_TEMP3 
	ADCM    A ,__R_HEIGHT_DISTANCE_H
	SNZ     C
	JMP     $6
	INC     __R_HEIGHT_DISTANCE	
$6:  
	SDZ __R_COURT
	JMP $0  
	
$7:
;	CLR __R_DISTANCE_L
;	CLR __R_DISTANCE_H
	MOV A,__R_TEMP8
	SUB A,2
	SNZ C
	JMP $8
	
	;;求平均值
	;;被除数
	MOVF	__R_TEMP5,__R_HEIGHT_DISTANCE_L
	MOVF	__R_TEMP4,__R_HEIGHT_DISTANCE_H
	MOVF	__R_TEMP3,__R_HEIGHT_DISTANCE
	CLR		__R_TEMP2
	CLR		__R_TEMP1
	CLR		__R_TEMP0
	;;除数
	CLR		__R_TEMP6
	CLR		__R_TEMP7
	;MOVF	__R_TEMP8
	CALL	__SBR_DIVIDE_6BY3
	MOVF	__R_HEIGHT_DISTANCE,__R_TEMP3
    MOVF    __R_DISTANCE_H ,__R_TEMP4
    MOVF    __R_DISTANCE_L ,__R_TEMP5
    
$8:

    MOVF    __R_DISTANCE_TIME ,24
    CLR	    __BUFF_DISTANCE_ADDRH       
    CLR     __BUFF_DISTANCE_ADDRL
   ENDIF 
   ;;TEST+-----------------------------------
    
    CALL    L_MANAGE_DATA
;	JMP	    L_TRANSMIT_DATA

;---------------------------------------------------	
;;
;;测量身高范围:5cm~200cm
;;
IF 1 ;;TEST+
	clr	C
	mov	a,low(2008)
	sub	a,__R_MAX_DISTANCE_L

	mov	a,high(2008)	
	sbc	a,__R_MAX_DISTANCE_H
	
	snz	C
;	jmp	Main_Loop
	jmp	Send_hight_0_temputer

	clr	C
	mov	a,low(49)
	sub	a,__R_MAX_DISTANCE_L

	mov	a,high(49)	
	sbc	a,__R_MAX_DISTANCE_H
	
	sz	C
;	jmp	Main_Loop	
	jmp	Send_hight_0_temputer
ENDIF ;;TEST+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 	
L_TRANSMIT_DATA:

	clr	EMI			

	call	SBR_INIT_TM1_UART	
	
	MOVF	   MP0,OFFSET __BUFF_DATA
	MOVF    __R_TEMP2 , 5;8;12 ;;TEST-
	;;MOVF      __R_TEMP2 , 7;;TEST+
$0:
    CLR     WDT
	MOVF	RX_DATA,IAR0 
	CALL	SBR_UART_SND
	
	CALL	__SBR_DELAY_1MS
	CALL	__SBR_DELAY_1MS	
	CALL	__SBR_DELAY_1MS
	CALL	__SBR_DELAY_1MS	
	CALL	__SBR_DELAY_1MS				
	INC     MP0
	SDZ	    __R_TEMP2
	JMP     $0


	
	call	 SBR_INIT_TM1_T		
	SET	EMI	
	JMP		Main_Loop	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;数据处理函数
L_MANAGE_DATA:	
    CLR		WDT	

    MOVF   __R_MAX_DISTANCE_H,  __R_DISTANCE_H
    MOVF   __R_MAX_DISTANCE_L,  __R_DISTANCE_L
    MOVF   __R_TEMP1 ,__R_MAX_DISTANCE_L
;====================================================== 
IF 0 ;;TEST-
    sub	a,78
    mov		__R_TEMP1 ,A
    mov	__R_MAX_DISTANCE_L,a
    

    clr	__r_temp0
    
    MOV    A, __R_MAX_DISTANCE_H
	sbc	a,__r_temp0
	mov	__R_MAX_DISTANCE_H,a
ENDIF ;;+

IF 1 ;;--------------------TEST+
    sub	a,0 ;;78
    mov		__R_TEMP1 ,A
    mov	__R_MAX_DISTANCE_L,a
    
    clr	__r_temp0
    
    MOV    A, __R_MAX_DISTANCE_H
	sbc	a,__r_temp0
	mov	__R_MAX_DISTANCE_H,a
ENDIF ;;---------------------TEST+

;======================================================
    CALL   __SBR_Bin_to_BCD_16bit
    IF 1 ;;TEST+
    MOVF   __BUFF_DATA[0] , __R_TEMP3
    MOVF   __BUFF_DATA[1] , __R_TEMP2
    MOVF   __BUFF_DATA[2] , __R_TEMP1
    MOVF   __BUFF_DATA[3] , __R_TEMP0
    MOVF   __BUFF_DATA[4] , R_TEMPERATURE_L
    ELSE
    MOVF   __BUFF_DATA[0] , __R_DISTANCE_H
    MOVF   __BUFF_DATA[1] , __R_DISTANCE_L
    MOVF   __BUFF_DATA[2] , __R_TIME_H
    MOVF   __BUFF_DATA[3] , __R_TIME_L
    MOVF   __BUFF_DATA[4] , __R_SOUND_SPEED_L
    ENDIF ;;TEST+

    
 ;   MOVF   __BUFF_DATA[0] , 'S'
;    MOVF   __BUFF_DATA[1] , '='
;    MOV     A , 030H
;    ADDM    A , __R_TEMP3
;    MOVF    __BUFF_DATA[2] , __R_TEMP3
;    MOV     A , 030H
;    ADDM    A , __R_TEMP2
;    MOVF    __BUFF_DATA[3] , __R_TEMP2
;    MOV     A , 030H
;    ADDM    A , __R_TEMP1
;    MOVF    __BUFF_DATA[4] , __R_TEMP1
;    MOVF    __BUFF_DATA[5] , '.'
;    MOV     A , 030H
;    ADDM    A , __R_TEMP0
;    MOVF    __BUFF_DATA[6] , __R_TEMP0
;    MOVF    __BUFF_DATA[7] ,'\n'    ;换行
 
L_MANAGE_DATA_EXIT:   
    RET	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Send_hight_0_temputer:
    MOVF   __BUFF_DATA[0] , 0
    MOVF   __BUFF_DATA[1] , 0
    MOVF   __BUFF_DATA[2] , 0
    MOVF   __BUFF_DATA[3] , 0
    MOVF   __BUFF_DATA[4] , R_TEMPERATURE_L	
    jmp		L_TRANSMIT_DATA
    
L_DELAY_200US:
	MOVF	__R_DISTANCE_TIMES,200
	CLR		WDT		
	SDZ		__R_DISTANCE_TIMES	
	JMP		$-2	
	RET
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CCRA_CTM_INT:
	PUSH

	JMP	__SYS_TM0_INT

__SYS_TM0_INT_BACK:
	POP
	RETI

;*****************************************************

;*****************************************************
IF  0
AEC_INT:
	PUSH
	SET		PB2 ;;TEST+
	CLR ENVCMPF
	SET F_MY_TEST
	SET		T0PAU	;;	暂停TM0计数器,保存时间					
	MOVF	__R_TIME_H,__R_TIMER_100US 
	MOVF	__R_TIME_M,TM0DH
	MOVF	__R_TIME_L,TM0DL
	CLR		T0PAU   ;;	运行TM0计数器
__SYS_AEC_INT_BACK:
	CLR ENVCMPE
	POP
	RETI
	
	
FIFO_INT:
	PUSH
	CLR FIFO10F
	SET F_MY_TEST
	SET		__F_GET_DISTANCE
	SET		T0PAU	;;	暂停TM0计数器,保存时间					
	MOVF	__R_TIME_H,__R_TIMER_100US 
	MOVF	__R_TIME_M,TM0DH
	MOVF	__R_TIME_L,TM0DL
	CLR		T0PAU   ;;	运行TM0计数器
__SYS_FIFO_INT_BACK:
	;;CLR FIFO10E
	POP
	RETI
ENDIF ;;TEST+


IF 1 ;;TEST+---------------------

__MY_CALC_TIME:	
	CLR	WDT
	CLR	__R_DISTANCE_L
	CLR	__R_DISTANCE_H
	SNZ	__F_GET_DISTANCE
	JMP	__MY_CALC_TIME_EXIT
;=============================================================
;;TEST+
;;s = v*T/2
;;INPUT: __R_TIME_H,__R_TIME_L
;;		 __R_SOUND_SPEED_H,__R_SOUND_SPEED_L
;;	v(cm/s)
;;	T(时间__R_TIME_L的精度10us，__R_TIME_H的精度100us)
;;OUTPUT:
;;	s = v*T/20000 则距离的单位为mm
L_CALC_TIME:
	CLR		__R_TEMP8
	MOV		A,10
	CLR		__R_TEMP8	
	MOV		__R_TEMP9,A
	CLR		__R_TEMP5
	CLR		__R_TEMP6
	MOVF	__R_TEMP7,__R_TIME_H
	CALL	__SBR_MULTIi_3BY2
	MOV		A,__R_TIME_L
	ADDM	A,__R_TEMP4
	MOV		A,0
	ADCM	A,__R_TEMP3	
				
	MOVF	__R_TEMP7,__R_TEMP4
	MOVF	__R_TEMP6,__R_TEMP3
	MOVF	__R_TEMP5,__R_TEMP2
	MOVF	__R_DISTANCE_L,__R_TEMP4
	MOVF	__R_DISTANCE_H,__R_TEMP3 
	
;	MOVF	__R_TEMP8,__R_SOUND_SPEED_H
;	MOVF	__R_TEMP9,__R_SOUND_SPEED_L
;	CALL	__SBR_MULTIi_3BY2		
;	MOVF	__R_DISTANCE_L,__R_TEMP5
;	MOVF	__R_DISTANCE_H,__R_TEMP4 
	IF 0  ;;TEST+

 	clr	EMI			
	MOVF	TM1C0,28H
	MOVF	TM1C1,03H	
    CLR     WDT	
	
	MOVF	RX_DATA,0 
	CALL	SBR_UART_SND
	
    MOVF	RX_DATA,__R_TEMP2 
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA,__R_TEMP3 
	CALL	SBR_UART_SND
	
    MOVF	RX_DATA,__R_TEMP4 
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA,__R_TIME_H 
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA, __R_TIME_L 
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA,0FFH
	CALL	SBR_UART_SND
	
	MOVF	TM1AL,255 ;255				;255
	MOVF	TM1AH,0
	MOVF	TM1C0,00110000B
	MOVF	TM1C1,11000001B		
	SET	EMI	
	ENDIF
	
__MY_CALC_TIME_EXIT:
	RET
	
	
MY_CALC_DISTANCE:

	MOVF	__R_TEMP7,__R_TIME_L
	MOVF	__R_TEMP6,__R_TIME_H
	MOVF	__R_TEMP5,0
	MOVF	__R_TEMP8,__R_SOUND_SPEED_H
	MOVF	__R_TEMP9,__R_SOUND_SPEED_L
	CALL	__SBR_MULTIi_3BY2		
	MOVF	__R_TEMP5,__R_TEMP4
	MOVF	__R_TEMP4,__R_TEMP3
	MOVF	__R_TEMP3,__R_TEMP2
	MOVF	__R_TEMP2,__R_TEMP1
	MOVF	__R_TEMP1,__R_TEMP0
	CLR	__R_TEMP0
																	
	MOVF	__R_TEMP6,00H         
	MOVF	__R_TEMP7,4EH	;;‭4E20H = 20000‬	
	MOVF	__R_TEMP8,20H       
	CALL	__SBR_DIVIDE_6BY3
	
;	MOVF	__R_DISTANCE_L,__R_TEMP5
;	MOVF	__R_DISTANCE_H,__R_TEMP4 
	MOVF	__R_HEIGHT_DISTANCE_L,__R_TEMP5
	MOVF	__R_HEIGHT_DISTANCE_H,__R_TEMP4 
	
__MY_CALC_DISTANCE_EXIT:
	RET
		
ENDIF ;;TEST+-------------
;*****************************************************

;;定时100us
;;定时/计数模式  比较器A匹配
;;外部时钟100KHz
;;
TM0_external_setting:

	MOVF	TM0AL,10 ;10  ;10 100K  200  2M 
	MOVF	TM0AH,0
	MOVF	TM0C1,11000001b
	MOVF	TM0C0,01100000B ;01101000B
	
	ret
;100us
TM0_internal_setting:

	MOVF	TM0AL,100;90h
	MOVF	TM0AH,0;01h
	MOVF	TM0C1,03h
	MOVF	TM0C0,00101000B
	
	ret


;;
;;定时模式: A匹配，1.02ms
;;
SBR_INIT_TM1_T:
	MOVF	TM1AL,255 ;255				;255
	MOVF	TM1AH,0
	MOVF	TM1C0,00110000B
	MOVF	TM1C1,11000001B		
	RET
	
	
;;
;;fclk=fsys/16  -->周期1us
;;比较匹配输出模式，输出无变化
;;CCRP-占空比，CCRA-周期，比较器A匹配
SBR_INIT_TM1_UART:

	MOVF	TM1C0,28H
	MOVF	TM1C1,03H
	RET
	
			
public __SYS_TM0_INT_BACK

;;-----------------
public F_MY_TEST	;;TEST+
;;--------------

END

