;
;;=====================================================================================
;;User define
;;=====================================================================================
;
;;-------------------------------------------------------------------------------------
;;LIN BUS
;;-------------------------------------------------------------------------------------
;;#define				RXC		PAC.7
;;#define				RX		PA.7
;;#define				TXC		PAC.7
;;#define				TX		PA.7
;
;
;include	MACRO.INC
;;;;HT45F39  IAP 操作
;
;;address:	__R_TEMP0(L),__R_PAGE(H)
;
;SBR_WRITE_flash:
;
;L_ENABLE_IAP:
;		
;		MOVF	FC0,	11100000B	;FMOD2`FMOD0 = 110  FWEN模式-Flash存储器写功能使能模式
;		SET		FWPEN				;写步骤使能控制
;
;		MOVF	FD1L,	00H
;		MOVF	FD1H,	04H
;		MOVF	FD2L,	0DH
;		MOVF	FD2H,	09H
;		MOVF	FD3L,	0C3H
;		MOVF	FD3H,	40H
;
;		
;		MOV	A,255
;	$1:	
;		CLR	WDT
;		SNZ	FWPEN
;		JMP	L_WRITE_flash00
;	
;		SDZ	ACC
;		JMP	$1
;		JMP	SBR_WRITE_flash;enable failed	;超时 写失败 重写
;
;L_WRITE_flash00:
;;;;擦除页程序
;		MOVF	FC0,	10010000B	;FMOD2`FMOD0 = 001   擦除页模式
;		SET	FWT			;激活一个写周期
;
;		CLR	WDT
;		SZ	FWT
;		JMP	$-2			;等待写周期完成
;
;;;;写程序
;SBR_WRITE_flash01:
;		MOVF	FC0,	10000000B	;FMOD2`FMOD0 = 000  写存储器模式    		
;		
;		MOVF	FARL,	ADDRESS_L
;		MOVF	FARH,	ADDRESS_H
;		MOVF	FD0L,	__R_TEML
;		MOVF	FD0H,	__R_TEMH
;
;		SET	FWT
;
;		MOV	A,255				;实际是300us的时间
;	$00:
;		CLR	WDT
;		SNZ	FWT
;		JMP	$02
;		SDZ	ACC
;		JMP	$00
;		JMP	SBR_WRITE_flash01		;超时重写
;		
;	$02:	
;		CLR	CFWEN				;写成功后CFWEN 软件置0
;		RET
;
;;;;读程序
;SBR_READ_flash02：
;;第一种方法
;		MOVF	FC0,	10110000B	;FMOD2`FMOD0 = 011  读存储器模式    
;		MOVF	FARL,	ADDRESS_L
;		MOVF	FARH,	ADDRESS_H
;		
;		SET	FRDEN
;		MOV	A,255
;	$03:	
;		SET	FRD
;		SNZ	FRD
;		JMP	$04
;		SDZ	ACC
;		JMP	$03
;		JMP	SBR_READ_flash02
;	$04:	
;		MOVF	__R_TEMPL,FD0L
;		MOVF	__R_TEMPH,FD0H
;		CLR	FWEN
;
;		
;
;;第二种方法
;		MOVF	TBLP,__R_TEMP0		;偏移量
;		MOVF	TBLH,R_PAGE
;
;		TABRDC	_R_TEMPH
;		MOVF	_R_TEMPH,TBLH
;		RET
;
;
;
