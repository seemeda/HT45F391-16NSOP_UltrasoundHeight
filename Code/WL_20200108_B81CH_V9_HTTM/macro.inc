
;-----------------------------MACRO
MOVF	MACRO	F1,F2
	MOV	A,F2
	MOV	F1,A
	ENDM
	
;-----------------------------MACRO
MOVT	MACRO	F1,F2
	MOV	A,F2
	MOV	TBLP,A
	TABRDL	F1
	ENDM
	
;........................
PUSH	MACRO
	MOV	__R_BACKUP_ACC,A
	MOV	A,Status
	MOV	__R_BACKUP_STATUS,A
	ENDM
	
;........................
POP	MACRO
	MOV	A,__R_BACKUP_STATUS
	MOV	Status,A
	MOV	A,__R_BACKUP_ACC
	ENDM
	
;........................
SZJ	MACRO	Data,Address	;
	XOR	A,Data
	SZ	Z
	JMP	Address
	XOR	A,Data
	ENDM
;........................
SUBC	MACRO	C_data,dataH,dataL
	MOV	A,LOW(C_data)
	SUB	A,dataL
	MOV	A,HIGH(C_data)
	SBC	A,dataH
	ENDM


over_time	macro	timer_counter

	mov	a,__R_TIMER_100US
	sub	a,timer_counter
	sz	c
	
	endm