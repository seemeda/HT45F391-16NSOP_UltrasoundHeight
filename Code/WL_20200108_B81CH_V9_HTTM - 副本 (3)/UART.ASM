INCLUDE HT45F391.INC
INCLUDE MACRO.INC
INCLUDE USER.INC
INCLUDE MEASURE.INC

#define	RX	PA6     ;主机的TX
#define	P_RX	PA6
#define	TX	PA4     ;主机的RX
#define	P_TX	PA4

RAMBANK	0	RAMBANK0
RAMBANK0	.SECTION	'data'

RX_DATA	    DB	?
;TX_DATA	DB	?
R_DELAY_TIME	DB	?
R_RX_CNT	DB	?
;;__BUFF_DATA	DB	    5	DUP(0) ;;TEST-
__BUFF_DATA	DB	    7	DUP(0) ;;TEST+
R_BUFF_CNT      	DB	?
R_TM1DL_BUF	DB	?
R_TM1DH_BUF	DB	?
F_FULL         DBIT    
bus	.SECTION	at 2E0h 'CODE'	;190h


;SBR_UART_READ:
;;	SET	EMI
;;	SET	T0ON 
;;	CLR F_FULL
;	MOVF	MP0,OFFSET __BUFF_DATA
;	MOVF    R_BUFF_CNT , 1;4
;_OVER_CHECK:	
;	; //30s没有操作则进入睡眠
;	; // WAIT TO SLEEP
;	;MOVF	__R_TIMER_20MS,65H
;	
;;	MOV	A,__R_TIMER_20MS
;;	SUB	A,64h ; SLEEP AFTER 2S
;;	SNZ	C 
;;	JMP	_KEEP_GOING
;;	
;;	;TEST
;;	;JMP	_KEEP_GOING
;;	
;;	; // WDT = 8.2s
;;	; //休眠状态
;;	
;;	; 中断
;;	CLR	EMI
;;	CLR	T0ON 
;;	
;;	MOVF	__R_TEMP0,PAC
;;	MOVF	__R_TEMP1,PA 
;;	MOVF	__R_TEMP2,PAPU 
;;	MOVF	__R_TEMP3,PBC
;;	MOVF	__R_TEMP4,PB 
;;	MOVF	__R_TEMP5,PBPU 
;;	
;;	;======
;;	; io
;;	;======
;;	CLR	PAWK
;;	
;;	CLR	PAC
;;	CLR	PA
;;	CLR	PAPU
;;	
;;	CLR	PBC
;;	CLR	PB
;;	CLR	PBPU
;;	; empty mcu is 1.9ua
;;	
;;	;SET	PAC3
;;	
;;	SET	PAC6
;;	;SET	PAPU6
;;	SET	PAWK6
;;	CLR	 F_FULL
;;	; a1 a7
;;	;SET	PAC1
;;	;SET	PAC7
;;	
;;	;CLR	PBC0
;;	
;;	;=========
;;	; SCF ADC fifo
;;	;=========
;;	CLR	FSTART  ; FIFO 
;;	CLR	ACERL   ;ADC 
;;	set	ADOFF   ; ADC 
;;	clr	SAVP    ; SCF 
;;	CLR	SCFOUT
;;	
;;	NOP
;;	NOP
;;	
;;	HALT
;;	
;;	NOP
;;	NOP
;;	MOVF	PAC,__R_TEMP0
;;	MOVF	PA,__R_TEMP1
;;	MOVF	PAPU,__R_TEMP2 
;;	MOVF	PBC,__R_TEMP3
;;	MOVF	PB,__R_TEMP4 
;;	MOVF	PBPU,__R_TEMP5
;;	SET	T0ON ;T0M 
;;	CLR	ADOFF
;;	SET	SCFOUT
;;	SET	SAVP
;;	SET	EMI
;;	NOP
;;	
;	; //恢复cpu状态
;_KEEP_GOING:
;    CLR	EMI
;	CLR	WDT
;	SZ	RX
;	;JMP	$-2
;;	JMP	_OVER_CHECK
;    JMP _KEEP_GOING 
;	
;	CLR	__R_TIMER_20MS
;	;CLR	__R_TIMER_5S
;	
;;延时104us  16M  每个周期 = 3 * 1 / 16 = 0.1875 us 
;;104us	/  0.1875 us =  554.666  取555
;;	CLR	EMI
;	MOVF	R_DELAY_TIME,105
;	CLR	    WDT	;1
;	SDZ	    R_DELAY_TIME	;1
;	JMP	    $-2	;2      555 / 5 = 111
;	
;	MOVF	R_RX_CNT,8
;	CLR	RX_DATA
;	MOVF	R_DELAY_TIME,50
;	CLR	    WDT	;1
;	SDZ	    R_DELAY_TIME	;1
;	JMP	    $-2	;2      555 / 5 = 111
;L_START_UART_RX:
;	SZ	RX
;	SET	RX_DATA.7
;	SDZ	R_RX_CNT
;	JMP	L_GET_DATA
;	SDZ     R_BUFF_CNT
;	JMP     $0
;	MOVF	IAR0 , RX_DATA
;	SET	    F_FULL
;	JMP	SBR_UART_READ_EXIT
;$0:
;   	MOVF	IAR0 , RX_DATA
;	INC     MP0	
;	MOVF	R_DELAY_TIME,105
;	CLR	    WDT	;1
;	SDZ	    R_DELAY_TIME	;1
;	JMP	    $-2	
;	JMP     _KEEP_GOING	
;L_GET_DATA:
;	RR	RX_DATA
;	MOVF	R_DELAY_TIME,105
;	CLR	WDT	
;	SDZ	R_DELAY_TIME	
;	JMP	$-2	
;	JMP	L_START_UART_RX	
;	
;SBR_UART_READ_EXIT:
;	SET	EMI
;	RET	
;
;
;
;SBR_UART_SND:
;;	MOVF	RX_DATA,55H
;	CLR	EMI
;	MOVF	R_RX_CNT,8
;	CLR	TX
;L_START_SND:	
;	MOVF	R_DELAY_TIME,105
;	CLR	WDT	
;	SDZ	R_DELAY_TIME	
;	JMP	$-2
;	
;	SNZ	RX_DATA.0
;	CLR	TX
;	SZ	RX_DATA.0
;	SET	TX	
;	
;	RR	RX_DATA
;	SDZ	R_RX_CNT
;	JMP	L_START_SND
;	
;	MOVF	R_DELAY_TIME,105
;	CLR	WDT	
;	SDZ	R_DELAY_TIME	
;	JMP	$-2
;	SET	TX
;	MOVF	R_DELAY_TIME,105
;	CLR	WDT	
;	SDZ	R_DELAY_TIME	
;	JMP	$-2
;	SET	EMI
;	RET
;read 
SBR_UART_READ:

SBR_BUS_RECIVE_DATA:
	SZ	P_RX
	JMP	SBR_BUS_RECIVE_DATA_EXIT
	
	clr	__R_TIMER_100US
;	SET	T0ON
;-------------------------------------;	
; GET CLK
$0:
	over_time	12		;超時1.2ms
	JMP	SBR_BUS_RECIVE_DATA_EXIT
	
	SNZ	P_RX			;等待起始位结束			
	JMP	$0

	CLR	T1ON
	MOVF	TM1AL,250		;学习1010 所有的时间	104*4=416 /255 =1 --153
	MOVF	TM1AH,2			;760us  > 150*4  够用
	SET	T1ON
	
	
	clr	__R_TIMER_100US

$1:					;等待1 结束
	over_time	12		;超時1.2ms
	JMP	SBR_BUS_RECIVE_DATA_EXIT
	SZ	P_RX
	JMP	$1
	
	clr	__R_TIMER_100US
	
$2:					;等待0 结束
	over_time	12		;超時1.2ms
	JMP	SBR_BUS_RECIVE_DATA_EXIT
	SNZ	P_RX
	JMP	$2	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;得到2bit持续时间，运算后保存
	CLR	T1ON
	MOVF	R_TM1DH_BUF,TM1DH
	MOVF	R_TM1DL_BUF,TM1DL
	
	CLR	C
	RRC	R_TM1DH_BUF
	RRC	R_TM1DL_BUF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;得到时钟之后保存，本次测量和返回数据均以改时钟为准
	MOVF	TM1AL,R_TM1DL_BUF
	MOVF	TM1AH,R_TM1DH_BUF		;得到波特率时钟后，开始接收数据
	
	clr	C
	RRC	R_TM1DH_BUF
	RRC	R_TM1DL_BUF	
	
	
	SET	T1ON
	CLR	TA1F
	
	MOVF	R_RX_CNT,6
	
	CLR	RX_DATA

$4:	



	SZ	P_RX
	SET	RX_DATA.7
	
	SNZ	TA1F
	JMP	$-1
	
	CLR	TA1F




	SDZ	R_RX_CNT
	JMP	$+2
	JMP	$5
	
	CLR	C
	RRC	RX_DATA
$6:	
	mov	a,TM1DH
	mov	a,TM1DL
	sub	a,R_TM1DL_BUF
	sz	C
	jmp	$4	
	
	JMP	$6
$5:
	
	SNZ	TA1F
	JMP	$-1
	CLR	TA1F	
	
	INC	RX_DATA
	MOVF	R_TM1DH_BUF,TM1AH	;保存時間設置
	MOVF	R_TM1DL_BUF,TM1AL

	
;--------------------------------------;
SBR_BUS_RECIVE_DATA_EXIT:
	RET



SBR_UART_SND:
	
	IF __UART_DEBUG__
	;;串口波特率9600bps
	MOVF	TM1AL,103;;test+
	MOVF	TM1AH,0;;test+
	ELSE
	MOVF	TM1AL,R_TM1DL_BUF
	MOVF	TM1AH,R_TM1DH_BUF
	ENDIF	

	MOVF	R_RX_CNT,8
	
	CLR	T1ON
	SET	T1ON
	CLR	TA1F
	CLR	P_TX
	
	SNZ	TA1F
	JMP	$-1
	CLR	TA1F
;	SET		R_TX
$0:	
	SZ	RX_DATA.0
	SET	P_TX
	SNZ	RX_DATA.0
	CLR	P_TX
	
$1:
	SNZ	TA1F
	JMP	$-1
	CLR	TA1F

	RR	RX_DATA
	SDZ	R_RX_CNT
	JMP	$0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;发送校验位
	
	
	SET	P_TX			;发送停止位
	SNZ	TA1F
	JMP	$-1
	clr	TA1F
	RET











PUBLIC	SBR_UART_READ
PUBLIC	SBR_UART_SND

PUBLIC	RX_DATA
PUBLIC      F_FULL 
PUBLIC      __BUFF_DATA	       
END