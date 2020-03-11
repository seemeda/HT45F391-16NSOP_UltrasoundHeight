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
__BUFF_DISTANCE_L           	 DB	    24	DUP(0)
__BUFF_DISTANCE_H           	 DB	    24	DUP(0)
__BUFF_DISTANCE_ADDRH        	DB	    ?
__BUFF_DISTANCE_ADDRL       	 DB	    ?
__R_COURT                   	 DB	    ?
;__R_CHECKSUM_H			   DB		? 
;__R_CHECKSUM_L			   DB		?
__R_DISTANCE_TIME		   DB		?
__R_ZERO                   	DB		?

__R_TOM			           DB		?

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
	RETI
	ORG		008H
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
Det_Loop: 
	call	 SBR_INIT_TM1_T
	call	TM0_external_setting

    CLR	    T0ON
	SET	    T0ON
	CLR     __R_TIMER_20MS
$0:
	CLR		WDT	
	MOV     A, __R_TIMER_20MS
	SUB     A, 1 
	SNZ     C 
	JMP     $0
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
	CALL	__SBR_CALC_DISTANCE
;;;;;;;;;;;;;
   
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
    CALL    L_MANAGE_DATA
;	JMP	    L_TRANSMIT_DATA

;---------------------------------------------------	

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	 	
L_TRANSMIT_DATA:

	clr	EMI			

	call	SBR_INIT_TM1_UART	
	
	MOVF	   MP0,OFFSET __BUFF_DATA
	MOVF    __R_TEMP2 , 5;8;12
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
    sub	a,78
    mov		__R_TEMP1 ,A
    mov	__R_MAX_DISTANCE_L,a
    
    
    clr	__r_temp0
    
    MOV    A, __R_MAX_DISTANCE_H
	sbc	a,__r_temp0
	mov	__R_MAX_DISTANCE_H,a
;======================================================
    CALL   __SBR_Bin_to_BCD_16bit
    MOVF   __BUFF_DATA[0] , __R_TEMP3
    MOVF   __BUFF_DATA[1] , __R_TEMP2
    MOVF   __BUFF_DATA[2] , __R_TEMP1
    MOVF   __BUFF_DATA[3] , __R_TEMP0
    MOVF   __BUFF_DATA[4] , R_TEMPERATURE_L
    
    
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

SBR_INIT_TM1_T:
	MOVF	TM1AL,255 ;255				;255
	MOVF	TM1AH,0
	MOVF	TM1C0,00110000B
	MOVF	TM1C1,11000001B		
	RET
	
SBR_INIT_TM1_UART:

	MOVF	TM1C0,28H
	MOVF	TM1C1,03H
	RET
	
			
public __SYS_TM0_INT_BACK
END

