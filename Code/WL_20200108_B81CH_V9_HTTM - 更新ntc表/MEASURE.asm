INCLUDE HT45F391.INC
INCLUDE MACRO.INC
INCLUDE CONFIGURE.INC
INCLUDE USER.INC
INCLUDE	UART.INC
EXTERN __SYS_TM0_INT_BACK	:NEAR

;;TEST+---------------
EXTERN F_MY_TEST:BIT
EXTERN F_MY_TEST_VAR:BIT
EXTERN __MY_FIFO_INT_BACK	:NEAR
;;---------------

RAMBANK		0		RAMBANK0
RAMBANK0	.SECTION	'DATA'

__R_DATA			DB		10		DUP(0)
;__R_GAIN			DB		11		DUP(0)

__R_BUF				DB			?
__R_TIMER_GAIN			DB		?
__R_GAIN_CNT			DB		?
__R_BIAS			DB		?
__R_DISTANCE_L			DB		?
__R_DISTANCE_H			DB		?
__R_TIME_H			DB		?
__R_TIME_M			DB		?
__R_TIME_L			DB		?
__R_AFTERSHOCK_TIME		DB		?
__R_TEMP0			DB		?
__R_TEMP1			DB		?
__R_TEMP2			DB		?
__R_TEMP3			DB		?
__R_TEMP4			DB		?
__R_TEMP5			DB		?
__R_TEMP6			DB		?
__R_TEMP7			DB		?
__R_TEMP8			DB		?
__R_TEMP9			DB		?
__R_TEMPA			DB		?
__R_TEMPB			DB		? 
__R_TEMPC			DB		?
__R_REF_CONTROL			DB		?
__R_TIMER_100US			DB		?
__R_TIMER_50MS			DB		?
__R_TIMER_20MS			DB		?
__R_TIMER_5S			DB		?
__R_ADCOMPARE_VALUE		DB		?
__R_ECHO_REFERENCE_ADJ		DB		?
__R_ECHO_REFERENCE_ADJ_MAX	DB		?

__R_GENERATE_ULTRASONIC_NUM	DB		?

__R_ADJ_MAX_SUMCMP			DB		?

__R_SOUND_SPEED_H		DB		?
__R_SOUND_SPEED_L		DB		?

__R_MAX_DATA		DB		?
__R_DET_CNT		    DB		?
__R_MAXDET_CNT		    DB		?
__R_DET_TIME		    DB		?
__R_DET_TIME_H			DB		?
__R_DET_TIME_M			DB		?
__R_DET_TIME_L			DB		?
__R_MIN_CNT        	DB		?
__R_F_DET_TIME_H			DB		?
__R_F_DET_TIME_L			DB		?
__R_DET_DATA			DB		?
__R_MAX_CNT         	DB		?
__R_STOP_CNT         	DB		?
__R_START_CNT         	DB		?
__F_GET_DOW          DBIT
__F_GET_UP          DBIT

__F_REF_CONTROL			DBIT
__F_TIMEUP			DBIT
__f_get_distance		DBIT

__F_DISTANCE_FAIL			DBIT

__F_PA2					DBIT

__F_TM0_EXTERNAL		DBIT
__F_SENSOR_58K			DBIT
__F_TIMER			DBIT
__F_NOISE			DBIT
__F_CONTINUOUS_NOISE		DBIT
F_GAIN_CONTOLR			DBIT
ROMBANK	0	MEASURE
measure		.SECTION	AT	390H	'CODE';3F0H

__SBR_SYS_INIT:
;;--------------------------------------------
#define		START_Addr			060H
#define		END_Addr_B0			0FFH
;;--------------------------------------------
L_INIT_IO:
	CLR	PBC1
	CLR	PB1
	CLR	__F_PA2
;	MOVF	__R_ECHO_REFERENCE_ADJ,10
;	MOVF	__R_ECHO_REFERENCE_ADJ_MAX,173


	SNZ	TO
	JMP	$+3
	SZ	PDF
	JMP	L_GET_SENSOR_FREQ
	
	
L_INIT_RAM:
r_RAM0:
	CLR	[04H].0
	MOV	A,START_Addr
	MOV	MP0,A
RAM0_rloop:
	CLR	WDT
	CLR	IAR0
	XOR	A,END_Addr_B0
	INC	MP0
	SNZ	Z
	JMP	RAM0_rloop
	CLR	MP0
L_GET_SENSOR_FREQ:
	;选择-->带通滤波器中心频率开关控制位
	MOVF	TBLP,OFFSET CFG_SYS
	TABRDL	ACC
	SZ	ACC.0
	SET	__F_SENSOR_58K
L_INI_WDT:
	;看门狗初始化,使能看门狗，2^18/fsub
	MOV	A,10101111B
	MOV	WDTC,A
	
L_INI_SCF:
	;开关电容滤波器初始化
	CLR	SCFCTL
	SET	SCFOUT
	SZ	__F_SENSOR_58K
	SET	SCBWSL

L_INIT_INT:
	CLR	INTC0
	CLR	INTC1
	CLR	INTC2
	MOV	A,00000010b;00000001b 外部引脚中断PA6
	MOV	INTEDGE,A
		
;;--------------------------------------------
;; Auto-Envelope Processing Unit SET
;;--------------------------------------------	
L_INIT_DVCM:
	MOV	A,10000000B		;;80H=VDD/2
	MOV	DVCM,A
;;--------------------------------------------
L_INIT_SUMCMP:
	MOV	A,10000000B
	MOV	SUMCMP,A
;;;--------------------------------------------
L_INIT_AVPCTRL:
	SET	SAVP
	SNZ	__F_SENSOR_58K
	jmp	$1
	CLR	DN
	SET	KN
	jmp	L_INIT_AVPCTRL_exit
$1:
	SET	DN
	CLR	KN
L_INIT_AVPCTRL_exit:
;;--------------------------------------------
L_INIT_ENVCMP:
	MOV	A,10001000B		;;SUM > Comparator Value 
	MOV	ENVCMP,A	
L_INIT_ADC:
	MOV	A,01101000B		;ACS3-ACS0:0000/AN0,0001/AN1,0010/AN2,0011/AN3		
	MOV	ADCR0,A			;0100/AN4,0101/AN5,0110/AN6,1000/SCF output(MUXIN),1001/DVCM
	MOV	A,00000000B
	MOV	ADCR1,A
	
L_INIT_TIMER0:
;	MOVF	TBLP,OFFSET CFG_SYS
;	TABRDL	ACC
;	SZ	ACC.7
	JMP	L_EXTERNAL_CLK
	;JMP	L_INTERNAL_CLK
L_EXTERNAL_CLK:
	;;外部时钟输入引脚PA3/TCK0
	SET	__F_TM0_EXTERNAL
	MOVF	TM0AL,10 ;10  ;10 100K  200  2M 
	MOVF	TM0AH,0
	MOVF	TM0C1,11000001b
	MOVF	TM0C0,01100000B ;01101000B
	JMP	L_INIT_TIMER0_EXIT
	
L_INTERNAL_CLK:
	CLR	__F_TM0_EXTERNAL
	MOVF	TM0AL,100;90h
	MOVF	TM0AH,0;01h
	MOVF	TM0C1,03h
	MOVF	TM0C0,00101000B
L_INIT_TIMER0_EXIT:
	SET	TA0E
	SET	EMI
L_DELAY:
	MOVF	__R_TEMP0,200
$1:
	CALL	__SBR_DELAY_1MS
	CALL	__SBR_DELAY_1MS
	SDZ	    __R_TEMP0
	JMP	$1
	
	RET

__SYS_TM0_INT:
	CLR	TA0F	
	SET	__F_TIMER
	INC  __R_BUF
	INC 	__R_TIMER_GAIN
	INC	__R_TIMER_100US	
	MOV	A,__R_TIMER_100US
	SUB	A,200
	SNZ	C	
	JMP	CCRA_CTM_INT_EXIT
	SET	__F_TIMEUP
	CLR	__R_TIMER_100US
	INC	__R_TIMER_20MS
		
CCRA_CTM_INT_EXIT:
	JMP	__SYS_TM0_INT_BACK
	
	
;************* SUBROUTINE: GET REF VALUE *********************
;;STACK: 2 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: __F_SENSOR_58K
;;OUTPUT: __R_BIAS
;*************************************************************
__SBR_GET_BIAS:
	CLR	__R_TEMP0
	CLR	__R_TEMP1
	CLR	__R_TEMP2
	CLR	__R_TEMP3
	MOV	A,00111111b
	SET	ACC.6
	MOV	SCFCTL,A
	SZ	__F_SENSOR_58K
	SET	SCBWSL

	MOVF	ADCR0,00001000b
	CLR	ADCR1
	CLR	SUMSEL
	
	CALL	__INI_FIFO
	CLR	FIFO10F
$2:	SET	FSTART
	CLR	WDT
	SNZ	FIFO10F
	JMP	$-2
	CLR	FIFO10F
	CLR	FSTART
	MOVF	__R_TEMP3,10
$0:	
	MOV	a,FIFOOUT
	ADDM	a,__R_TEMP0
	SZ	C
	INC	__R_TEMP1
	SIZ	__R_TEMP2
	JMP	$3
	JMP	$1
$3:
	SDZ	__R_TEMP3
	JMP	$0
	jmp	$2
$1:
	MOV	A,FIFOOUT
	MOV	A,FIFOOUT
	MOV	A,FIFOOUT
	MOV	A,FIFOOUT
	
	CLR	FSTART
	MOVF	__R_BIAS,0;__R_TEMP1

	SUB	A,15
	SNZ	C
	JMP	L_GET_BIAS_EXIT
	MOV	A,5
	ADDM	A,__R_BIAS
L_GET_BIAS_EXIT:
	;MOVF	__R_BIAS,15	; // __SBR_GET_BIAS 不可靠，不使用；
	RET

;************* SUBROUTINE: GET DVCM VALUE ********************
;;STACK: 1 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: NONE
;;OUTPUT: DVCM
;*************************************************************
__SBR_GET_DVCM:
	MOVF	ADCR0,00001001b
	CLR	__R_TEMP0
	CLR	__R_TEMP1
	CLR	__R_TEMP2
	CLR	ADOFF
L_AD_START:
	CLR	WDT
	CLR	START
	NOP
	SET	START
	NOP
	CLR	START
L_EOCB_POLLING:
	SZ	EOCB
	JMP	L_EOCB_POLLING
	MOV	A,ADR
	
	ADDM	A,__R_TEMP1
	SZ	C
	INC	__R_TEMP0
	SDZ	__R_TEMP2
	JMP	L_AD_START

	MOVF	DVCM,__R_TEMP0
	RET



;************* SUBROUTINE: GENERATE ULTRASONIC*****************
;;STACK: 1 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: __F_SENSOR_58K
;;OUTPUT: NONE
;*************************************************************
__SBR_GENERATE_ULTRASONIC:
	CLR	EMI
	CLR	PBC.1
	
	SZ	__F_SENSOR_58K
	JMP	L_TX_58K	
L_TX_40K:
	MOVF	__R_TEMP0,__R_GENERATE_ULTRASONIC_NUM	
L_TX_40K_LOOP:
	SET	PB.1
	CLR	WDT
	MOV	A,15
	SDZ	ACC
	JMP	$-1
	
	SNZ	TA0F
	JMP	$+3
	CLR	TA0F
	INC	__R_TIMER_100US
;	NOP
;	NOP
;	NOP
	
	CLR	PB.1
	CLR	WDT
	MOV	A,15
	SDZ	ACC
	JMP	$-1
	
	SDZ	__R_TEMP0
	JMP	L_TX_40K_LOOP
	JMP	L__SBR_GENERATE_ULTRASONIC_EXIT
L_TX_58K:
	MOVF	__R_TEMP0,29
L_TX_58K_LOOP:
	SET	PB.1
	CLR	WDT
	MOV	A,10
	SDZ	ACC
	JMP	$-1
	NOP
	NOP
		
	CLR	PB.1
	CLR	WDT
	MOV	A,10
	SDZ	ACC
	JMP	$-1

	SDZ	__R_TEMP0
	JMP	L_TX_58K_LOOP
	JMP	L__SBR_GENERATE_ULTRASONIC_EXIT
L__SBR_GENERATE_ULTRASONIC_EXIT:
	CLR	PB.1
	SET	EMI
RET



;************* SUBROUTINE: GET AFTERSHOCK TIME*****************
;;STACK: 2 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: __F_SENSOR_58K, __R_GAIN[], __R_TIMER_100US, __R_BIAS,
;;       __R_AFTERSHOCK_TIME_ADJ, __R_ECHO_REFERENCE_ADJ,
;;       __R_ECHO_REFERENCE_ADJ_MAX
;;OUTPUT: __R_AFTERSHOCK_TIME
;*************************************************************
__SBR_GET_AFTER_SHOCK:
	MOVF	TBLP,OFFSET	CFG_ECHO_REFERENCE_ADJ_MAX
	TABRDL	__R_ECHO_REFERENCE_ADJ_MAX
	MOVF	TBLP,OFFSET	CFG_ECHO_REFERENCE_ADJ
	TABRDL	__R_ECHO_REFERENCE_ADJ
	
	
	MOVF	TBLP,OFFSET CFG_GAIN
	TABRDL	ACC
	SET	ACC.6
	MOV	SCFCTL,A
	SZ	__F_SENSOR_58K
	SET	SCBWSL

	MOVF	ADCR0,08h
	MOVF	ADCR1,00h

	CALL	__SBR_GENERATE_ULTRASONIC
	
	;MOVF	TM0AL,90h
	;MOVF	TM0AH,01h
	;MOVF	TM0C1,03h
	CLR	T0ON
	SET	T0ON
	CLR	__F_TIMEUP
	CLR	__R_TIMER_100US
	SET	TA0E
$0:
	CLR	WDT
	MOV	A,__R_TIMER_100US
	SUB	A,7
	SNZ	C
	JMP	$0
	

	MOVF	TBLP,OFFSET	CFG_MAX_AFTERSHOCK_TIME
	TABRDL	__R_TEMP0
	
	MOV	A,__R_BIAS
	ADD	A,__R_ECHO_REFERENCE_ADJ_MAX
	MOV	SUMCMP,A

$1:
	SET	ENVEDGE0
	CLR	ENVCMPF
	CLR	WDT
	MOV	A,__R_TIMER_100US
	SUB	A,20;__R_TEMP0
	SNZ	C
	JMP	$2
	MOVF	__R_AFTERSHOCK_TIME,__R_TIMER_100US;__R_TEMP0
	JMP	L_GET_AFTER_SHOCK_EXIT
$2:	
	SNZ	ENVCMPF
	JMP	$1
	
	CLR	ENVEDGE0
	CLR	ENVCMPF
	MOVF	__R_TEMP1,__R_TIMER_100US
	
	MOV	A,5
	ADDM	A,SUMCMP	

$3:
	CLR	WDT
	MOV	A,__R_TIMER_100US
	SUB	A,__R_TEMP1
	SUB	A,3
	SNZ	C
	JMP	$4
	MOVF	__R_AFTERSHOCK_TIME,__R_TEMP1
	JMP	L_GET_AFTER_SHOCK_EXIT
$4:	
	SNZ	ENVCMPF
	JMP	$3	

	MOV	A,__R_TEMP1
	ADD	A,10
	MOV	__R_AFTERSHOCK_TIME,A
	JMP	L_GET_AFTER_SHOCK_EXIT


;;降低门限，等待第二次下降
;	MOV	A,SUMCMP
;	SUB	A,5
;	MOV	SUMCMP,A
;	MOVF	__R_TEMP2,__R_TIMER_100US
;
;$5:
;	SET	ENVEDGE0
;	CLR	ENVCMPF
;	CLR	WDT
;	MOV	A,__R_TIMER_100US
;	SUB	A,__R_TEMP2
;	SUB	A,10
;	SNZ	C
;	JMP	$6
;	
;	MOV	A,__R_TEMP2
;	ADD	A,10
;	MOV	__R_AFTERSHOCK_TIME,A
;	JMP	L_GET_AFTER_SHOCK_EXIT
;$6:	
;	SNZ	ENVCMPF
;	JMP	$5
;	MOVF	__R_AFTERSHOCK_TIME,__R_TIMER_100US
	
L_GET_AFTER_SHOCK_EXIT:
	CLR	ENVEDGE0
	MOVF	TBLP,OFFSET	CFG_AFTERSHOCK_TIME_ADJ
	TABRDL	ACC
	ADDM	A,__R_AFTERSHOCK_TIME	

L_CHECK_AFTERSHOCK_TIME:
	RET
	

	
;************* SUBROUTINE: DISTANCE MEASURE********************
;;STACK: 2 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: __F_SENSOR_58K, __R_GAIN[], __R_TIMER_100US, __R_BIAS,
;;       __R_ECHO_REFERENCE_ADJ,__R_ECHO_REFERENCE_ADJ_MAX, AFTERSHOCK_REFERENCE
;;OUTPUT: __R_TIME_H, __R_TIME_M, __R_TIME_L, __F_GET_DISTANCE
;*************************************************************
__SBR_DISTANCE_MEASURE:
	;;SCFCTL 寄存器配置Fc=40KHz，SCFO 引脚功能SCFOUT，增益置1。（0~30）
	CLR	WDT
	MOVF	TBLP,OFFSET CFG_GAIN
	TABRDL	ACC
	SET	ACC.6
	MOV	SCFCTL,A
    
	MOVF	ADCR0,00001000b
	
	SZ	__F_SENSOR_58K
	SET	SCBWSL
	CLR	__F_GET_DISTANCE
	JMP	L_ULTRASONIC_DISTANCE_MEASURE
IF 0 ;;TEST	
	CLR	__F_CONTINUOUS_NOISE
	
L_NOISE_SAMPLE:	
	CALL	__INI_FIFO
	CLR	FIFO10E
	CLR	FIFO10F
	MOVF	__R_TEMP4,40
	CLR	__R_TEMP3
	CLR	__R_TEMP5
L_NOISE_SAMPLE_LOOP:
	SET	FSTART
	CLR	WDT
	SNZ	FIFO10F
	JMP	$-2
	CLR	FIFO10F
	
	MOVF	__R_DATA[0],FIFOOUT
	MOVF	__R_DATA[1],FIFOOUT
	MOVF	__R_DATA[2],FIFOOUT
	MOVF	__R_DATA[3],FIFOOUT
	MOVF	__R_DATA[4],FIFOOUT	
	MOVF	__R_DATA[5],FIFOOUT
	MOVF	__R_DATA[6],FIFOOUT
	MOVF	__R_DATA[7],FIFOOUT
	MOVF	__R_DATA[8],FIFOOUT
	MOVF	__R_DATA[9],FIFOOUT
	
	CLR	    FSTART
	
	MOVF	__R_TEMP2,10
	CLR	__R_TEMP0
	CLR	__R_TEMP1
	
	MOVF	MP0,OFFSET __R_DATA
	CLR	__F_NOISE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $0:
	; MOV	A,IAR0
	; SUB	A,__R_BIAS
	; SNZ	C
	; CLR	ACC
	; ADDM	A,__R_TEMP0
	; SZ	C
	; INC	__R_TEMP1
	; INC	MP0
	; SDZ	__R_TEMP2
	; JMP	$0
	
	; MOV	A,5
	; SUB	A,__R_TEMP0
	; MOV	A,0
	; SBC	A,__R_TEMP1
	; SNZ	C
	; SET	__F_CONTINUOUS_NOISE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
$0:
	MOV	A,__R_BIAS
	ADD	A,__R_ECHO_REFERENCE_ADJ
	SUB	A,IAR0
	SZ	C
	CLR	__R_TEMP3

	INC	MP0
	INC	__R_TEMP3
	
	MOV	A,__R_TEMP3
	SUB	A,4
	SZ	C
	SET	__F_NOISE
	
	SDZ	__R_TEMP2
	JMP	$0
	
	SNZ	__F_NOISE
	CLR	__R_TEMP5
	
	INC	__R_TEMP5
	MOV	A,__R_TEMP5
	SUB	A,5
	SZ	C
	SET	__F_CONTINUOUS_NOISE
	
	SDZ	__R_TEMP4
	JMP	L_NOISE_SAMPLE_LOOP
	
ENDIF ;;TEST+	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
L_ULTRASONIC_DISTANCE_MEASURE:	

	CLR		T0ON	
	;;CLR		__R_TIMER_50MS
	CLR		__R_TIMER_100US
	CLR		__F_TIMEUP
	CLR		__R_TIMER_GAIN
	CLR		__R_GAIN_CNT
 	CLR     __R_MAX_DATA		
    ;;CLR     __R_DET_CNT
    ;;CLR     __R_MAXDET_CNT		   
    ;;CLR     __R_DET_TIME		    
    CLR    __R_DET_TIME_H		
    CLR    __R_DET_TIME_M		
    CLR    __R_DET_TIME_L
    ;;CLR    __R_MIN_CNT 
    ;;CLR    __F_GET_DOW
    ;;CLR     __F_GET_UP
    ;;CLR     __R_DET_DATA
    ;;CLR	   __R_MAX_CNT
    CLR     __R_STOP_CNT         
    ;;CLR   __R_START_CNT         
	CLR   	__R_TIME_H 
	CLR   	__R_TIME_L
	CALL	__INI_FIFO
	CLR		FIFO10E
	CLR		FIFO10F
	
	CLR		ENVCMPF
	
	CLR		__F_TIMER
	CLR 	F_MY_TEST	
	
	CALL	__SBR_GENERATE_ULTRASONIC
	SET		T0ON ;;TEST+
	SET		TA0E
    CLR		PB2
	
	
AEP_ENVCMPINT: ;;退出此 AEP_ENVCMPINT 循环条件：1.超时20ms  2.ENVCMPF 自动包络比较器中断
	CLR 	WDT ;;TEST++
	SZ		__F_TIMEUP
	JMP		L_ULTRASONIC_DISTANCE_MEASURE_EXIT	
	CALL 	__SBR_GAIN_CTRL
	SZ		__F_TIMER
	CALL	__SBR_REF_CTRL	
	SNZ		ENVCMPF
	JMP		AEP_ENVCMPINT
	;;只能得到一个大约的时间,需要找到峰值，并初始配置FIFO开始存储FIFO值，
	;;FSTART=1时自动包络处理机制通过硬件自动开始向 FIFO 写入数据或从 FIFO 读取数据
    SET	    FSTART	
	SET 	FIFO10E	

;;40KHz的正弦波一个周期25us半个周期12.5us	
;;完成10笔FIFOOUT数据约125us，FIFOOUT的一笔数据是半个周期的数据取绝对值，
;;LOOP_DETECT_PEAK大约等待104us,说明LOOP_FIFOOUT处理数据较快，不影响后续FIFO中断数据的处理
;;所以FIFO有足够时间在LOOP_FIFOOUT执行完成后，FIFO还没完成10笔数据写入FIFOOUT,要原地等待104us.
;;注意:LOOP_FIFOOUT程序处理数据要尽量快，时间不能大于125us,即FIFOOUT被写入新数据的时间间隔.
LOOP_DETECT_PEAK:      
    CLR     __R_START_CNT 
	MOVF	__R_TEMP0,10
	MOVF	MP0,OFFSET __R_DATA	
	;;SET		PB2 ;;TEST
	;;等待10-level FIFO 中断请求完成保存时间和取FIFOOUT数据
	CLR	WDT
	SZ		__F_TIMEUP
	JMP		L_ULTRASONIC_DISTANCE_MEASURE_EXIT	
	SNZ		F_MY_TEST 
	JMP		$-4	
	CLR		F_MY_TEST
	;;CLR		PB2 ;;TEST
	IF 1 ;;
	;; 注意:在FIFO中断读取FIFOOUT数据时，不知为什么会导致测试距离不准确？而且测距误差没有线性，但稳定度不变，放在这里也稳定.
	MOVF	__R_DATA[0],FIFOOUT
	MOVF	__R_DATA[1],FIFOOUT
	MOVF	__R_DATA[2],FIFOOUT
	MOVF	__R_DATA[3],FIFOOUT
	MOVF	__R_DATA[4],FIFOOUT	
	MOVF	__R_DATA[5],FIFOOUT
	MOVF	__R_DATA[6],FIFOOUT
	MOVF	__R_DATA[7],FIFOOUT
	MOVF	__R_DATA[8],FIFOOUT
	MOVF	__R_DATA[9],FIFOOUT	
	;;读取完FIFOOUT后，应立即初始化FIFO并启动自动包络处理向FIFO写入数据
	CLR		FSTART
	CLR		FULL
	CLR		FRESET
	SET	    FSTART
	ENDIF
	
LOOP_FIFOOUT:		;;LOOP_FIFOOUT:第一次进来执行54us，后面执行与34us
    INC     __R_START_CNT      
    MOV     A,__R_MAX_DATA
    SUB     A,IAR0
    SZ      C 
    JMP     $0 	;__R_MAX_DATA >= IAR0
    ;__R_MAX_DATA < IAR0   更新最大值并保存更新时间,记录这笔数据是第几个半周期的
    MOVF    __R_MAX_DATA, IAR0
    MOV     A,1
	ADDM    A,__R_MAX_DATA
	SZ      C
	SET     __R_MAX_DATA
	MOVF   	__R_TIME_H,__R_DET_TIME_H 
	MOVF   	__R_TIME_L,__R_DET_TIME_L
	MOV 	A, 10
	SUB		A, __R_START_CNT
	MOV		__R_STOP_CNT, A	;;记录这笔数据是第几个半周期的,FIFO中断保存的时间减去x*12.5us,得到峰值的时间
	       
$0:    ;__R_MAX_DATA >= IAR0 不更新时间,直接进行下笔数据比较
	INC		MP0
	SDZ		__R_TEMP0
	JMP		LOOP_FIFOOUT
	
LOOP_DETECT_TIME:  
    SNZ    __F_GET_DISTANCE
	JMP    $0
	JMP    $1
$0:	
    SET	   __F_GET_DISTANCE
	CLR	   __F_DISTANCE_FAIL	
	MOVF   __R_BUF,0   
$1:	
	MOV   A,__R_BUF                       
	SUB   A,7 ;;20=2MS, 10=1MS
	SNZ   C
	JMP		LOOP_DETECT_PEAK

;;
;;最大值是在FIFO中断保存的时间减去 x*12.5us, 得到峰值的时间
;;计算回波达到的峰值时间和刚接收回波前沿时间(超声波经过这段距离的时间)
;;
TIME_OF_ARRIVAL: 
	CLR		PB2;;TEST+
    CLR	 	FSTART
  	CLR 	FIFO10E ;;关闭FIFO中断
  	CLR		T0PAU   ;;运行TM0计数器

	IF 1 ;;__EXTERN_2M__ 
	MOVF	__R_TEMP7,125  ;;半周期12.5us，扩大10倍
	MOVF	__R_TEMP6,0
	MOVF	__R_TEMP5,0
	MOVF	__R_TEMP8,0
	MOVF	__R_TEMP9,__R_STOP_CNT;__R_MAXDET_CNT  
	CALL    __SBR_MULTIi_3BY2
	MOVF	__R_TEMP5,__R_TEMP4          
	MOVF	__R_TEMP4,__R_TEMP3
	MOVF	__R_TEMP3,__R_TEMP2
	MOVF	__R_TEMP2,__R_TEMP1
	MOVF	__R_TEMP1,__R_TEMP0
	CLR	    __R_TEMP0
	MOVF	__R_TEMP6,00H            
	MOVF	__R_TEMP7,00H
	MOVF	__R_TEMP8,0AH
	CALL    __SBR_DIVIDE_6BY3
	MOVF 	__R_TIME_M,__R_TEMP5
	
;	MOV     A,__R_TIME_H
;	SUB     A,3
;	SNZ		 C
;	CLR		 __F_GET_DISTANCE       
	
	ELSE
	MOVF	__R_TEMP7,125  ;;半周期12.5us，扩大10倍
	MOVF	__R_TEMP6,0
	MOVF	__R_TEMP5,0
	MOVF	__R_TEMP8,0
	MOVF	__R_TEMP9,__R_STOP_CNT;__R_MAXDET_CNT  
	CALL    __SBR_MULTIi_3BY2
	MOVF	__R_TEMP5,__R_TEMP4          
	MOVF	__R_TEMP4,__R_TEMP3
	MOVF	__R_TEMP3,__R_TEMP2
	MOVF	__R_TEMP2,__R_TEMP1
	MOVF	__R_TEMP1,__R_TEMP0
	CLR	    __R_TEMP0
	MOVF	__R_TEMP6,00H            
	MOVF	__R_TEMP7,00H
	MOVF	__R_TEMP8,064H
	CALL    __SBR_DIVIDE_6BY3
	MOV     A,__R_TIME_H
	SUB     A,2
	SNZ		 C
	CLR		 __F_GET_DISTANCE                  
	MOV     __R_TIME_H,A
	MOV     A,20
	ADD    	A,__R_TIME_L           
    SUB    	A,__R_TEMP5      
    MOV    	__R_TIME_L,A
    ENDIF   
L_ULTRASONIC_DISTANCE_MEASURE_EXIT:

	CLR		FSTART
	CLR 	FIFO10E ;;TEST+
  	CLR		T0PAU   ;;TEST+	运行TM0计数器
  	
;;test+	
;;__F_TIMEUP延时20ms,这里延时20ms和Det_Loop循环也延时20ms，
;;所以每发射触发脉冲测量一次至少需要40ms为一个周期

	CLR	WDT
	SNZ	__F_TIMEUP
	JMP	$-2         
	CLR	__F_TIMEUP
;	CLR	__R_TIMER_100US
	
	SZ	__F_GET_DISTANCE
	JMP	L__DISTANCE_MEASURE_RET
	SET	__F_DISTANCE_FAIL
	MOVF	__R_TIME_H,0
	MOVF	__R_TIME_M,0
	MOVF	__R_TIME_L,0
	
	
L__DISTANCE_MEASURE_RET:

;;TEST+++++++++++++++++++++++++++
IF 0 ;;__UART_DEBUG__ 
	clr	EMI			

	MOVF	TM1C0,28H
	MOVF	TM1C1,03H
IF 0	
	MOVF	   MP0,OFFSET __R_DATA
	MOVF    __R_TEMP2 , 10
$0:
    CLR     WDT
	MOVF	RX_DATA,IAR0
	CALL	SBR_UART_SND			
	INC     MP0
	SDZ	    __R_TEMP2
	JMP     $0
ENDIF	
;	MOVF		RX_DATA, __R_DATA[0]
;	CALL	SBR_UART_SND
;
;	MOVF		RX_DATA, __R_DATA[1]
;	CALL	SBR_UART_SND
		
	MOVF	RX_DATA,__R_TIME_H
	CALL	SBR_UART_SND
	MOVF	RX_DATA,__R_TIME_L
	CALL	SBR_UART_SND
		
	MOVF	RX_DATA,__R_GAIN_CNT
	CALL	SBR_UART_SND	
	
	MOVF	RX_DATA,__R_ADCOMPARE_VALUE
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA,__R_MAX_DATA
	CALL	SBR_UART_SND
	
	MOVF	RX_DATA,__R_STOP_CNT
	CALL	SBR_UART_SND

	MOVF	TM1AL,255 ;255				;255
	MOVF	TM1AH,0
	MOVF	TM1C0,00110000B
	MOVF	TM1C1,11000001B		
	SET	EMI	
ENDIF 
;;TEST+++++++++++++++++++++++++++

	RET

;************* SUBROUTINE: CALCULATE DISTANCE**************
;;STACK: 2 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: __R_TIME_H, __R_TIME_M, __R_TIME_L, __F_GET_DISTANCE 
;;OUTPUT: __R_DISTANCE_H, __R_DISTANCE_L      
;*************************************************************
	
__SBR_CALC_DISTANCE:	
	CLR	WDT
	CLR	__R_DISTANCE_L
	CLR	__R_DISTANCE_H
	SNZ	__F_GET_DISTANCE
	JMP	__SBR_CALC_DISTANCE_EXIT

;=============================================================
;;TEST+
;;s = v*T/2
;;INPUT: __R_TIME_H,__R_TIME_L
;;		 __R_SOUND_SPEED_H,__R_SOUND_SPEED_L
;;	v(cm/s)
;;	T(时间__R_TIME_L的精度10us，__R_TIME_H的精度100us)
;;OUTPUT:
;;	s = v*T/20000 则距离的单位为mm
L_CALC_DISTANCE:
	CLR	__R_TEMP8
	
;	SZ	__F_TM0_EXTERNAL  ;;
	JMP	$0
;	JMP	$1
$0:
	MOV	A,10 ;10
	JMP	$2
$1:
	MOV	A,100
$2:
	CLR	__R_TEMP8	
	MOV	__R_TEMP9,A
	CLR	__R_TEMP5
	CLR	__R_TEMP6
	MOVF	__R_TEMP7,__R_TIME_H
	CALL	__SBR_MULTIi_3BY2
	MOV	A,__R_TIME_L
	ADDM	A,__R_TEMP4
	MOV	A,0
	ADCM	A,__R_TEMP3				
	MOVF	__R_TEMP7,__R_TEMP4
	MOVF	__R_TEMP6,__R_TEMP3
	MOVF	__R_TEMP5,__R_TEMP2
	MOVF	__R_TEMP8,__R_SOUND_SPEED_H
	MOVF	__R_TEMP9,__R_SOUND_SPEED_L
	CALL	__SBR_MULTIi_3BY2		
	MOVF	__R_TEMP5,__R_TEMP4
	MOVF	__R_TEMP4,__R_TEMP3
	MOVF	__R_TEMP3,__R_TEMP2
	MOVF	__R_TEMP2,__R_TEMP1
	MOVF	__R_TEMP1,__R_TEMP0
	CLR	__R_TEMP0
									
	
;	SZ	__F_TM0_EXTERNAL
	JMP	$3
;	JMP	$4
$3:	


;	MOVF	__R_TEMP6,00H		
;	MOVF	__R_TEMP7,07H			
;	MOVF	__R_TEMP8,0D0H
								
	MOVF	__R_TEMP6,00H         
	MOVF	__R_TEMP7,4EH	;;‭4E20H = 20000‬	
	MOVF	__R_TEMP8,20H       

;	MOVF	__R_TEMP6,03H
;	MOVF	__R_TEMP7,0DH
;	MOVF	__R_TEMP8,40H       
	JMP	$5
$4:
	MOVF	__R_TEMP6,1EH;7AH;1EH;98H;001h
	MOVF	__R_TEMP7,84H;12H;96H;038h
	MOVF	__R_TEMP8,80H;00H;80H;080h    
$5:									 
	CALL	__SBR_DIVIDE_6BY3
	
	MOVF	__R_DISTANCE_L,__R_TEMP5
	MOVF	__R_DISTANCE_H,__R_TEMP4 
__SBR_CALC_DISTANCE_EXIT:
	RET
	
;;
;;设置带通滤波器SCFCTL 增益，SUMCMP寄存器比较值
;;
__SBR_GAIN_CTRL:
	MOV	A,__R_GAIN_CNT
	SUB	A, 30
	SZ	C
	JMP	__SBR_GAINCTRL_EXIT

L_CHANGE_GAIN:

	MOV		A,OFFSET CFG_GAIN
	ADD		A,__R_GAIN_CNT
	MOV		TBLP,A
	TABRDL	ACC
	SET		ACC.6
	SZ		__F_SENSOR_58K
	SET		ACC.7
	MOV		SCFCTL,A
	
	MOV		A,OFFSET CFG_THRESHOLD_VALUE
	ADD		A,__R_GAIN_CNT
	MOV		TBLP,A
	TABRDL	ACC
;	ADD		A,_R__ADJ_THRESHOLD_VALUE_ADJUST
	MOV		__R_ADCOMPARE_VALUE,A
	MOVF	SUMCMP,__R_ADCOMPARE_VALUE
	
__SBR_GAINCTRL_EXIT:
	RET
	
;;
;;__R_TIMER_GAIN这是调整增益和比较值的计数变量，范围:0~30,每400us加1，作为调整参数
;;
__SBR_REF_CTRL:
	CLR		__F_TIMER		
CHANG_GAIN:	
	MOV	A,__R_TIMER_GAIN
	SUB	A,4
	SNZ	C
	JMP	L_REF_CTRL_EXIT
	CLR	__R_TIMER_GAIN
	INC 	__R_GAIN_CNT

L_REF_CTRL_EXIT:
	RET
	

;************* SUBROUTINE: INIT FIFO *************************
;;STACK: 1 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: NONE
;;OUTPUT: NONE
;;Bit 1 FRESET： 该 FRESET 位用于对齐 FIFO 读地址和写地址。当完成对齐，该位将自动清为 " 
;;		0 "。注意，该位只有在 FSTART 位设为“0”时才有效。
;;Bit 0 FSTART：自动包络功能模式选择
;;		1：自动包络处理机制通过硬件自动开始向 FIFO 写入数据或从 FIFO 读取数据
;;		0：自动包络处理机制停止向 FIFO 写入数据或从 FIFO 读取数据。通过应用程
;;		序可以手动对 FIFO 写入数据或从 FIFO 读取数据。
;*************************************************************
__INI_FIFO:
	CLR	FSTART
	CLR	FULL
	SET	FRESET
	CLR	FRESET
RET

;************* SUBROUTINE: DIVIDE 6 BY 3 *********************
;;STACK: 1 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;INPUT: NONE
;;OUTPUT: NONE
;;dividend: __R_TEMP0,__R_TEMP1, __R_TEMP2,__R_TEMP3,__R_TEMP4,__R_TEMP5
;;division: __R_TEMP6,__R_TEMP7,__R_TEMP8
;;effect:  __R_TEMP9,__R_TEMPA,__R_TEMPB
;;output:  __R_TEMP3,__R_TEMP4,__R_TEMP5
;;SubCounter:__R_TEMPC
;*************************************************************
__SBR_DIVIDE_6BY3:
	MOVF	__R_TEMPC,24
L_NEXTSHIFT:
	CLR	C
	RLC	__R_TEMP5
	RLC	__R_TEMP4
	RLC	__R_TEMP3
	RLC	__R_TEMP2
	RLC	__R_TEMP1
	RLC	__R_TEMP0

	SZ	C
	INC	__R_TEMP5

	MOV	A,__R_TEMP2
	SUB	A,__R_TEMP8
	MOV	__R_TEMP9,A
	MOV	A,__R_TEMP1
	SBC	A,__R_TEMP7
	MOV	__R_TEMPA,A
	MOV	A,__R_TEMP0
	SBC	A,__R_TEMP6
	MOV	__R_TEMPB,A
	
	SZ	__R_TEMP5.0
	JMP	$+4

	SNZ	C
	JMP	L_POSITIVERESULT
	INC	__R_TEMP5
	MOVF	__R_TEMP0,__R_TEMPB
	MOVF	__R_TEMP1,__R_TEMPA
	MOVF	__R_TEMP2,__R_TEMP9
L_POSITIVERESULT:
	DEC	__R_TEMPC
	SNZ	Z
	JMP	L_NEXTSHIFT

;	CLR	C
;	RLC	__R_TEMP2
;	RLC	__R_TEMP1
;	RLC	__R_TEMP0
;	MOV	A,__R_TEMP2
;	SUB	A,__R_TEMP8
;	MOV	A,__R_TEMP1
;	SBC	A,__R_TEMP7
;	MOV	A,__R_TEMP0
;	SBC	A,__R_TEMP6
	RET
	
;************* SUBROUTINE: MULTIi 3 BY 2***********************
;;STACK: 1 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;multiplicand:	__R_TEMP5,__R_TEMP6,__R_TEMP7
;;multiplicator:	__R_TEMP8,__R_TEMP9
;;effect:	__R_TEMPA,__R_TEMPB
;;output:	__R_TEMP0,__R_TEMP1,__R_TEMP2,__R_TEMP3,__R_TEMP4
;;SubCounter:	__R_TEMPC
;*************************************************************
__SBR_MULTIi_3BY2:

	CLR	__R_TEMP0
	CLR	__R_TEMP1
	CLR	__R_TEMP2
	CLR	__R_TEMP3
	CLR	__R_TEMP4
	CLR	__R_TEMPA
	CLR	__R_TEMPB
	MOVF	__R_TEMPC,16
	;....................
L_NeEXTADDB1:
	CLR	C
	RRC	__R_TEMP8  ;; 2位被乘数:__R_TEMP8(HIGH)__R_TEMP9(LOW) 
	RRC	__R_TEMP9
	SNZ	C
	JMP	L_EXITDIVIDEB1
	MOV	A,__R_TEMP7
	ADDM	A,__R_TEMP4 ;;累加乘法结果:__R_TEMP4...__R_TEMP0
	MOV	A,__R_TEMP6
	ADCM	A,__R_TEMP3
	MOV	A,__R_TEMP5
	ADCM	A,__R_TEMP2
	MOV	A,__R_TEMPB
	ADCM	A,__R_TEMP1
	MOV	A,__R_TEMPA
	ADCM	A,__R_TEMP0
L_EXITDIVIDEB1:
	CLR	C
	RLC	__R_TEMP7  ;;单次乘法结果：__R_TEMP7(L)...__R_TEMPA (H)
	RLC	__R_TEMP6  ;;3位乘数：__R_TEMP7(L)...__R_TEMP5 (H)
	RLC	__R_TEMP5
	RLC	__R_TEMPB
	RLC	__R_TEMPA
	DEC	__R_TEMPC
	SNZ	Z
	JMP	L_NeEXTADDB1
	;.................
	RET

	
;************* SUBROUTINE: CALCULATE SOUND SPEED****************
;;STACK: 2 
;;ROM:   
;;RAM:  
;;WDT: ENABLE 
;;TIMER: 0 
;;INTERRUPT:0  
;;PORT:   NONE  
;;MAXRUNTIME: 
;;input:ACC
;;output:__R_SOUND_SPEED_H, __R_SOUND_SPEED_L
;*************************************************************
__SBR_CALC_SOUND_SPEED:
	MOVF	__R_TEMP8,R_TEMPERATURE_H
	MOVF	__R_TEMP9,R_TEMPERATURE_L		;C=C0+0.607*T  C0  0度 速度 33145cm/s  											
IF 0 ;;TEST-------------
	CLR	__R_TEMP5
	CLR	__R_TEMP6
	MOVF	__R_TEMP7,61
	CALL	__SBR_MULTIi_3BY2	

	MOVF	__R_SOUND_SPEED_H,HIGH(31925)	;HIGH(33145)
	MOVF	__R_SOUND_SPEED_L,LOW(31925)	;LOW(33145)
	MOV		A,__R_TEMP4
	ADDM	A,__R_SOUND_SPEED_L
	MOV		A,	__R_TEMP3
	ADCM	A,__R_SOUND_SPEED_H	
	
ELSE
	;;提高精度
	;;C=C0+0.607*T  C0为环境温度0摄氏度时的超声波速度33145cm/s  
	CLR		__R_TEMP5
	MOVF	__R_TEMP6, HIGH(607)
	MOVF	__R_TEMP7, LOW(607)
	CALL	__SBR_MULTIi_3BY2
	
	MOVF	__R_TEMP5, __R_TEMP4
	MOVF	__R_TEMP4, __R_TEMP3
	MOVF	__R_TEMP3, __R_TEMP2
	CLR		__R_TEMP2
	CLR		__R_TEMP1
	CLR		__R_TEMP0
	
	CLR		__R_TEMP6
	CLR		__R_TEMP7
	IFDEF	__TEMPERATURE_ACCURACY__
	MOVF	__R_TEMP8, 64H	
	ELSE
	MOVF	__R_TEMP8, 0AH	
	ENDIF
	CALL	__SBR_DIVIDE_6BY3
	
	MOVF	__R_SOUND_SPEED_H,HIGH(31931)	;TEST+ 31925CM/S是温度为-20摄氏度的声速
	MOVF	__R_SOUND_SPEED_L,LOW(31931)	;TEST+
	MOV		A,__R_TEMP5
	ADDM	A,__R_SOUND_SPEED_L
	MOV		A,	__R_TEMP4
	ADCM	A,__R_SOUND_SPEED_H	
	
	IFDEF	__TEMPERATURE_ACCURACY__
	MOVF	__R_TEMP5, R_TEMPERATURE_L
	MOVF	__R_TEMP4, R_TEMPERATURE_H
	CLR		__R_TEMP3
	CLR		__R_TEMP2
	CLR		__R_TEMP1
	CLR		__R_TEMP0

	CLR		__R_TEMP6
	CLR		__R_TEMP7
	MOVF	__R_TEMP8, 0AH	

	CALL	__SBR_DIVIDE_6BY3
	CLR		R_TEMPERATURE_L
	CLR		R_TEMPERATURE_H
	MOV		A,__R_TEMP5
	ADDM	A,R_TEMPERATURE_L
	MOV		A,	__R_TEMP4
	ADCM	A,R_TEMPERATURE_H	
	ENDIF	
ENDIF ;;TEST++++++++++++++++++
		
	RET
;....................................................
;16bit binary to BCD
;input:__R_TEMP1(LSB),ACC(MSB)
;output:__R_TEMP0(个位),__R_TEMP1(十位),__R_TEMP2(百位),__R_TEMP3(千位),__R_TEMP4(万位)
;effect:__R_TEMP5
;....................................................
__SBR_Bin_to_BCD_16bit:
	;...............
	MOV	__R_TEMP5,A
	CLR	__R_TEMP0
;	CLR	__R_TEMP1
	CLR	__R_TEMP2
	MOVF	__R_TEMP3,16
	CLR	__R_TEMP4
	;.....
__s_sys_BCD_Loop:
	CLR	C
	RLC	__R_TEMP1
	RLC	__R_TEMP5
	MOV	A,__R_TEMP0
	ADC	A,__R_TEMP0
	DAA	__R_TEMP0
	MOV	A,__R_TEMP2
	ADC	A,__R_TEMP2
	DAA	__R_TEMP2
	MOV	A,__R_TEMP4
	ADC	A,__R_TEMP4
	DAA	__R_TEMP4
	SDZ	__R_TEMP3
	JMP	__s_sys_BCD_Loop
	
	SWAPA	__R_TEMP0
	AND	A,0FH
	MOV	__R_TEMP1,A
	SWAPA	__R_TEMP2
	AND	A,0FH
	MOV	__R_TEMP3,A
	MOV	A,0FH
	ANDM	A,__R_TEMP0
	ANDM	A,__R_TEMP2
	ANDM	A,__R_TEMP4
	RET  
	
IF 1 ;;TEST+++++++++++++++++
__MY_FIFO_INT:
	CLR FIFO10F
	;;中断保存时间和取FIFOOUT数据
	SET		T0PAU	;;	暂停TM0计数器,保存时间							
	MOVF	__R_DET_TIME_H, __R_TIMER_100US 
	MOVF	__R_DET_TIME_M, TM0DH
	MOVF	__R_DET_TIME_L, TM0DL
	CLR		T0PAU
	IF 0 ;;
	MOVF	__R_DATA[0],FIFOOUT
	MOVF	__R_DATA[1],FIFOOUT
	MOVF	__R_DATA[2],FIFOOUT
	MOVF	__R_DATA[3],FIFOOUT
	MOVF	__R_DATA[4],FIFOOUT	
	MOVF	__R_DATA[5],FIFOOUT
	MOVF	__R_DATA[6],FIFOOUT
	MOVF	__R_DATA[7],FIFOOUT
	MOVF	__R_DATA[8],FIFOOUT
	MOVF	__R_DATA[9],FIFOOUT	
	;;读取完FIFIOUT后，应立即初始化FIFO并启动自动包络处理向FIFO写入数据
	CLR	FSTART
	CLR	FULL
	SET	FRESET
	CLR	FRESET

	SET	    FSTART
	ENDIF
	SET F_MY_TEST
	
MY_FIFO_INT_EXIT:
	JMP	__MY_FIFO_INT_BACK
ENDIF ;;TEST++++++++++++++++	
	
	      
;-----------------------------------------------
;;**************************************************
;; delay_SUB
;;**************************************************
;;--------------------------------------------
__SBR_DELAY_1MS:
	SET	ACC
$0:
	CLR	WDT
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	SDZ	ACC
	JMP	$0
	
	MOV	A,0F0H
$1:
	CLR	WDT
	NOP
	SDZ	ACC
	JMP	$1
	RET

;ROMBANK 0 CONFIG

PUBLIC __SYS_TM0_INT
PUBLIC __SBR_GET_BIAS
PUBLIC __SBR_GET_DVCM
PUBLIC __SBR_GENERATE_ULTRASONIC
PUBLIC __SBR_GET_AFTER_SHOCK
PUBLIC __SBR_DISTANCE_MEASURE
PUBLIC __SBR_CALC_DISTANCE
PUBLIC __SBR_DIVIDE_6BY3
PUBLIC __SBR_MULTIi_3BY2
PUBLIC __SBR_DELAY_1MS
PUBLIC __SBR_CALC_SOUND_SPEED
PUBLIC __SBR_SYS_INIT
PUBLIC L_ULTRASONIC_DISTANCE_MEASURE_EXIT
PUBLIC __SBR_Bin_to_BCD_16bit

PUBLIC __R_DATA				
PUBLIC __R_TIMER_GAIN		
PUBLIC __R_GAIN_CNT		
PUBLIC __R_BIAS 	
PUBLIC __R_DISTANCE_L		
PUBLIC __R_DISTANCE_H					
PUBLIC __R_TIME_H		
PUBLIC __R_TIME_M		
PUBLIC __R_TIME_L		
PUBLIC __R_AFTERSHOCK_TIME	
PUBLIC __R_TEMP0		
PUBLIC __R_TEMP1		
PUBLIC __R_TEMP2		
PUBLIC __R_TEMP3		
PUBLIC __R_TEMP4		
PUBLIC __R_TEMP5		
PUBLIC __R_TEMP6		
PUBLIC __R_TEMP7		
PUBLIC __R_TEMP8		
PUBLIC __R_TEMP9		
PUBLIC __R_TEMPA		
PUBLIC __R_TEMPB		
PUBLIC __R_TEMPC		
PUBLIC __R_REF_CONTROL		
PUBLIC __R_TIMER_100US
PUBLIC __R_TIMER_50MS
PUBLIC __R_TIMER_20MS
PUBLIC __R_TIMER_5S

PUBLIC	__R_BUF

PUBLIC	__R_ADJ_MAX_SUMCMP
PUBLIC	__R_GENERATE_ULTRASONIC_NUM

PUBLIC __F_REF_CONTROL		
PUBLIC __F_TIMEUP		
PUBLIC __f_get_distance	
	
PUBLIC __F_SENSOR_58K		
PUBLIC __F_TIMER
PUBLIC __R_ECHO_REFERENCE_ADJ			
PUBLIC __R_ECHO_REFERENCE_ADJ_MAX	
PUBLIC __R_ADCOMPARE_VALUE	

PUBLIC __R_SOUND_SPEED_H
PUBLIC __R_SOUND_SPEED_L
PUBLIC __F_CONTINUOUS_NOISE
PUBLIC	__F_DISTANCE_FAIL

IF 1 ;;TEST+++++++++
PUBLIC __MY_FIFO_INT
PUBLIC __R_DET_TIME_M
ENDIF ;;TEST++++++++
;END	