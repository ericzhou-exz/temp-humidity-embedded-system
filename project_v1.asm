;	This file is a basic code template for assembly code generation
;	on the PIC16F886. This file contains the basic code
;	building blocks to build upon. YOUR PROJECT MUST BE SET TO
;	RELOCATABLE. THIS IS CONTRARY TO WHAT SOME TUTORIALS TELL YOU
;	TO! YOU CAN EDIT THIS AT Project > Build Options... > Project
;	AND IN THE MPASM Suite TAB UNDER THE Single File Assembly
;	Projects, SELECT Generate relocatable code!!!!!

;	Learn how MPASM syntax such as directives work by opening the
;	MPASM User's Guide (Doc DS33014) at:
;	https://ww1.microchip.com/downloads/en/DeviceDoc/33014L.pdf
;	
;	Another useful resource can be found at:
;	https://documentation.help/Microchip-MPASM-Assembler/

;	Refer to the PIC16F886 datasheet to learn about the instructions
;	set and how to use all its peripherals and registers at:
;	http://ww1.microchip.com/downloads/en/devicedoc/41291d.pdf

;	Author:				Mr Bruh
;	Company:			UNSW
;	Creation Date:		dd/mm/yyyy
;	Modification Date:	dd/mm/yyyy
;	Version:			V1.0

;	Notes:	> 
;			> 
;			> 
;			> 
;			> 
;			> 

	TITLE		"Insert project name in under 60 characters."
	SUBTITLE	"Insert description in under 60 characters."
	LIST		b=4,	c=255,	st=OFF	; Set tab spaces, column width, and don't show symbols to format the listing file. Just for aesthetics.
	PROCESSOR	16f886			; Declare the processor we're using, which is the PIC16F886.
	RADIX		DEC				; Default numerics to decimal base. Otherwise your numbers will be treated like hexadecimal values.
	ERRORLEVEL	-302			; Suppress a dumb warning that complains whenever a non-Bank0 register is used.
	
	#include	<p16f886.inc>	; Include a header file with processor specific register names to easily reference and use.
	
	; '__CONFIG' directive is used to embed configuration data within .asm file.
	; When programming the microcontroller, these set how the microcontroller
	; behaves at runtime but are not instructions themselves. Basically, they're
	; settings that retain across power-ons. Check page 206 of the datasheet.
	__CONFIG	_CONFIG1, _LVP_OFF & _FCMEN_ON & _IESO_OFF & _BOR_OFF & _CPD_OFF & _CP_OFF & _MCLRE_ON & _PWRTE_OFF & _WDT_OFF & _INTRC_OSC_NOCLKOUT
	__CONFIG	_CONFIG2, _WRT_OFF & _BOR21V
	
    LCD_init_arr_L  EQU     D'12'
	
	
	PAGE	; Add page break to listing file. Just for aesthetics.
			; Define a section of data that must be bank selected. This is where your normal variables go.
vars		UDATA
; Declare your variables here.
counter1        RES     1
counter2        RES     1
counter3        RES     1
init_counter1   RES     1
init_counter2   RES     1
letter_counter  RES     1
DHT_counter     RES     1
DHT_data        RES     1
DHT_humidity    RES     1
DHT_temp        RES     1
DHT_checksum    RES     1
DHT_temp_dec    RES     1
DHT_hum_dec     RES     1
conversion      RES     1
humidity_bcd    RES     1
temp_bcd        RES     1


			; Define a section of data that can be accessed from any bank. For PIC16F886, only 8 bytes can do this.
global_vars	UDATA_SHR
WREG_CTX	RES		1		; Reserve a byte for the context saved Working Register for the interrupt routine.
STATUS_CTX	RES		1		; Reserve a byte for the context saved Status Register for the interrupt routine.
PCLATH_CTX	RES		1		; Reserve a byte for the context saved Program Counter Latch High Register for the interrupt routine.
FSR_CTX		RES		1		; Reserve a byte for the context saved File Select Register for the interrupt routine.



	PAGE	; Add page break to listing file. Just for aesthetics.
RES_VEC		CODE	0x0000	; POR and BOR vector (This is where the microcontroller starts when turned on.)
	goto	SETUP	; Jump the Program Counter to where the SETUP label is. This is to prevent running into the interrupt code section.

	
	
	; When any interrupt is raised, the last program counter location is pushed
	; onto the stack and the program counter is set to the this location. Global
	; interrupts are also disabled, because interrupting an interrupt doesn't
	; really make much logical sense.
INT_VEC		CODE	0x0004	; Interrupt Vector Location
	; Since we're dealing with a microcontroller from the naughties (2006), it is
	; over a decade old. This means you have to manually code in the saving of
	; context of core registers from what was running before the interrupt routine
	; so your interrupt code can modify and use them. The values must then be
	; restored to what was originally before after the interrupt routine is
	; complete. This is to make sure the normal non-interrupt code runs without
	; issue as if nothing had happened (kind of, timers still remember). If you
	; were using a newer PIC, this context saving is done for you. But we use
	; PIC from 2006 :).
	movwf	WREG_CTX						; Context save Working Register.
	movf	STATUS,				w			; Copy Status Register into Working Register.
	movwf	STATUS_CTX						; Context save Status Register.
	movf	FSR,				w			; Copy File Select Register into Working Register.
	movwf	FSR_CTX							; Context save File Select Register.
	movf	PCLATH,				w			; Copy Program Counter Latch High Register into Working Register.
	movwf	PCLATH_CTX						; Context save Program Counter Latch High Register.
	
	; Interrupt code goes here.
	
	movf	PCLATH_CTX,			w			; Copy saved context of Program Counter Latch High Register into Working Register.
	movwf	PCLATH							; Context restore Program Counter Latch High Register.
	movf	FSR_CTX,			w			; Copy saved context of File Select Register into Working Register.
	movwf	FSR								; Context restore File Select Register.
	movf	STATUS_CTX,			w			; Copy saved context of Status Register into Working Register.
	movwf	STATUS							; Context restore Status Register.
	swapf	WREG_CTX,			f			; We cannot use movf as that will mess with the Status Register. So we can swapf
	swapf	WREG_CTX,			w			; twice and on the second, context restore the Working Register.
	retfie									; Finally, return from the interrupt service routine. This is done by popping the
											; stack to get the Program Counter location before the interrupt. Global interrupts
											; are also re-enabled.



	PAGE	; Add page break to listing file. Just for aesthetics.
; Your normal program is written below here.

    
fcall    macro subroutine_name
    local here
    lcall subroutine_name
    pagesel here
here:
    endm
    
delay_50us
    movlw   D'8'
    movwf   counter1
delay_50us_loop
    nop
    nop
    decfsz  counter1,f
    goto    delay_50us_loop
    nop
    return
    
delay_1ms
    movlw   D'199'
    movwf   counter1
delay_1ms_loop
    nop
    nop
    decfsz  counter1,f
    goto    delay_1ms_loop
    nop
    return

delay_20ms
    movlw   D'20'
    movwf   counter2
delay_20ms_loop
    call    delay_1ms
    decfsz  counter2,f
    goto    delay_20ms_loop
    return
    
delay_1200ms
    movlw   D'60'
    movwf   counter3 
delay_1200ms_loop
    call    delay_20ms
    decfsz  counter3,f
    goto    delay_1200ms_loop
    return
 

LCD_init_arr
    addwf PCL, 1
    retlw b'00110000' ; Set 8-Bit Mode
    retlw b'00110000' ; This is done 3 times to ensure if it
    retlw b'00110000' ; was in 4-Bit mode, no errors occur.
    
    retlw b'00100000' ; Set 4-Bit Mode
    
    retlw b'00100000' ; Set Display Mode
    retlw b'10000000' ;
    
    retlw b'00000000' ; Enable Display, disable Cursor and Blink
    retlw b'11000000' ;
    
    retlw b'00000000' ; Set Entry Mode
    retlw b'01100000' ;
    
    retlw b'00000000' ; Clear Display
    retlw b'00010000' ;
    
LCD_init
    banksel     PORTA
    movfw       init_counter2
    call        LCD_init_arr
    movwf       PORTA
    call        data_upload_wait
    incf        init_counter2,f
    decfsz      init_counter1
    goto        LCD_init
    return
    
data_upload_wait
    banksel     PORTB
    bsf         PORTB,2
    call        delay_1ms
    call        delay_1ms
    bcf         PORTB,2
    call        delay_1ms
    call        delay_1ms
    return
    
shift_cursor
    banksel     PORTB
    bcf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    movlw       B'00010000'
    movwf       PORTA
    call        data_upload_wait
    movlw       B'01000000'
    movwf       PORTA
    return
    
print_name_arr
    addwf       PCL, 1
    retlw       b'01000000'
    retlw       b'01010000' ; E
    
    retlw       b'01010000'
    retlw       b'00100000' ; R
    
    retlw       b'01000000'
    retlw       b'10010000' ; I
    
    retlw       b'01000000'
    retlw       b'00110000' ; C
    
    retlw       b'00100000'
    retlw       b'00000000' ; [space]
    
    retlw       b'01010000'
    retlw       b'10100000' ; Z
    
    retlw       b'01000000'
    retlw       b'10000000' ; H
    
    retlw       b'01000000'
    retlw       b'11110000' ; O
    
    retlw       b'01010000'
    retlw       b'01010000' ; U
    
    
LCD_DHT_setup_arr
    addwf       PCL, 1
    retlw       b'01010000'
    retlw       b'01000000' ; T
    
    retlw       b'00110000'
    retlw       b'10100000' ; [colon]
    
    ;retlw       b'00100000'
    ;retlw       b'00000000' ; [space]
    
    retlw       b'00110000'
    retlw       b'00000000' ; 0
    
    retlw       b'00110000'
    retlw       b'00000000' ; 0
    
    retlw       b'11010000'
    retlw       b'11110000' ; [degrees]
    
    retlw       b'01000000'
    retlw       b'00110000' ; C
    
    retlw       b'01000000'
    retlw       b'10000000' ; H
    
    retlw       b'00110000'
    retlw       b'10100000' ; [colon]
    
    ;retlw       b'00100000'
    ;retlw       b'00000000' ; [space]
    
    retlw       b'00110000'
    retlw       b'00000000' ; 0
    
    retlw       b'00110000'
    retlw       b'00000000' ; 0
    
    retlw       b'00100000'
    retlw       b'01010000' ; %
    
print_letter
    banksel     PORTB
    bsf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    movfw       letter_counter
    fcall       print_name_arr
    incf        letter_counter
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTA
    movfw       letter_counter
    fcall       print_name_arr
    incf        letter_counter
    movwf       PORTA
    fcall       data_upload_wait
    return
    
move_cursor_section
    banksel     PORTB
    bcf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    movlw       b'11000000'
    
    ; 1st line is from "00H" to "27H", and DDRAM address in the
    ; 2nd line is from "40H" to "67H"

    movwf       PORTA
    fcall       data_upload_wait
    banksel     PORTA
    movlw       b'00000000'
    movwf       PORTA
    fcall       data_upload_wait
    return
    
print_name
    movlw       0x00
    movwf       letter_counter
    fcall       print_letter ; E
    fcall       print_letter ; R
    fcall       print_letter ; I
    fcall       print_letter ; C
    fcall       print_letter ; SPACE
    fcall       print_letter ; Z
    fcall       print_letter ; H
    fcall       print_letter ; O
    fcall       move_cursor_section
    fcall       print_letter ; U
    return

clear_display
    banksel     PORTB
    bcf         PORTB, 0
    bcf         PORTB, 1
    
    movlw       b'00000000' ; Clear Display
    movwf       PORTA
    fcall       data_upload_wait
    
    movlw       b'00010000'
    movwf       PORTA
    fcall       data_upload_wait
    return
    
LCD_DHT_setup
    fcall       clear_display
    
    movlw       0x00
    movwf       letter_counter
    
    fcall       LCD_DHT_setup_print ; T
    fcall       LCD_DHT_setup_print ; :
    ;fcall       LCD_DHT_setup_print ; [space]
    fcall       LCD_DHT_setup_print ; 0
    fcall       LCD_DHT_setup_print ; 0
    fcall       LCD_DHT_setup_print ; [degrees]
    fcall       LCD_DHT_setup_print ; C
    
    fcall       move_cursor_section
    
    fcall       LCD_DHT_setup_print ; H
    fcall       LCD_DHT_setup_print ; :
    ;fcall       LCD_DHT_setup_print ; [space]
    fcall       LCD_DHT_setup_print ; 0
    fcall       LCD_DHT_setup_print ; 0
    fcall       LCD_DHT_setup_print ; %
    return
    
LCD_DHT_setup_print
    banksel     PORTB
    bsf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    movfw       letter_counter
    fcall       LCD_DHT_setup_arr
    incf        letter_counter
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTA
    movfw       letter_counter
    fcall       LCD_DHT_setup_arr
    incf        letter_counter
    movwf       PORTA
    fcall       data_upload_wait
    return
    
read_DHT
    banksel     TRISA
    bcf         TRISA, 0
    ;start signal
    banksel     PORTA
    bsf         PORTA, 0
    fcall       delay_1200ms
    banksel     PORTA
    bcf         PORTA, 0
    
    banksel     PORTA
    bcf         PORTA, 0
    fcall       delay_20ms
    banksel     PORTA
    bsf         PORTA, 0
    fcall       delay_50us
    ; response signal
    banksel     TRISA
    bsf         TRISA, 0
    banksel     PORTA
    
wait_for_lo_1
    btfsc       PORTA, 0
    goto        wait_for_lo_1
wait_for_hi
    btfss       PORTA, 0
    goto        wait_for_hi
wait_for_lo_2
    btfsc       PORTA, 0
    goto        wait_for_lo_2 
    
    fcall       read_DHT_loop ; humidity integer
    movfw       DHT_data
    movwf       DHT_humidity
    
    fcall       read_DHT_loop ; humidity decimal
    movfw       DHT_data
    movwf       DHT_hum_dec
    
    fcall       read_DHT_loop ; temp integer
    movfw       DHT_data
    movwf       DHT_temp
    
    fcall       read_DHT_loop ; temp decimal
    movfw       DHT_data
    movwf       DHT_temp_dec
    
    fcall       read_DHT_loop ; checksum
    movfw       DHT_data
    movwf       DHT_checksum
validate_checksum
    movlw       0x00
    banksel     DHT_humidity
    addwf       DHT_humidity, w
    addwf       DHT_hum_dec, w
    addwf       DHT_temp, w
    addwf       DHT_temp_dec, w
    ;addlw       d'12'
    subwf       DHT_checksum, w
    
    btfss       STATUS, Z
    goto        read_DHT
    return

read_DHT_loop
    movlw       d'8'
    movwf       DHT_counter
    clrf        DHT_data
DHT_bits
    banksel     PORTA
    btfss       PORTA, 0
    goto        DHT_bits
    fcall       delay_50us
    btfss       PORTA, 0
    goto        received_lo
    bsf         STATUS, C
    rlf         DHT_data, f
    goto        wait_for_next_bit
received_lo
    bcf         STATUS, C
    rlf         DHT_data, f
    bsf         STATUS, C
wait_for_next_bit
    btfsc       PORTA, 0
    goto        wait_for_next_bit
    decfsz      DHT_counter, f
    goto        DHT_bits    
    return
    
hex_to_decimal        
    ; credit to Dabbot from EEVblog
    ; https://www.eevblog.com/forum/microcontrollers/pic-binary-to-bcd-assembly-code/
    banksel     conversion
    clrf        conversion

    addlw       d'56'			
    rlf         conversion, f   
    btfss       conversion, 0	
    addlw       d'200'			

    addlw       d'156'			
    rlf         conversion, f   
    btfss       conversion, 0	
    addlw       d'100'			

    addlw       d'176'			
    rlf         conversion, f	
    btfss       conversion, 0	
    addlw       d'80'			

    addlw       d'216'			
    rlf         conversion, f	
    btfss       conversion, 0	
    addlw       d'40'			

    addlw       d'236'			
    rlf         conversion, f	
    btfss       conversion, 0	
    addlw       d'20'			

    addlw       d'246'			
    rlf         conversion, f	
    btfss       conversion, 0	
    addlw       d'10'			
    
    swapf       conversion, f
    iorwf       conversion, w
    return                 
    
update_LCD
    ; all LCD nums start with 0011
    ; lower 4 bits are just binary representation of that number
    banksel     PORTB
    bcf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    
    movlw       b'10000000' ; changing ddram address
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTA
    movlw       b'00100000' ; ddram address 02
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTB
    bsf         PORTB, 0
    bcf         PORTB, 1
    
update_temperature
    banksel     PORTA
    movlw       b'00110000'
    movwf       PORTA
    fcall       data_upload_wait
    
    ;using the stored DHT_temp
    banksel     PORTA
    movfw       DHT_temp
    ;movlw       0x1b
    fcall       hex_to_decimal
    movwf       temp_bcd
    banksel     PORTA
    movwf       PORTA
    fcall       data_upload_wait
    
    ;change value of T_hi
    banksel     PORTA
    movlw       b'00110000'
    movwf       PORTA
    fcall       data_upload_wait
    
    ;using the stored DHT_temp
    banksel     PORTA
    swapf       temp_bcd, f
    movfw       temp_bcd
    movwf       PORTA
    fcall       data_upload_wait    
update_humidity
    banksel     PORTB
    bcf         PORTB, 0
    bcf         PORTB, 1
    banksel     PORTA
    
    movlw       b'11000000' ; changing ddram address
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTA
    movlw       b'00100000' ; ddram address 0x42
    movwf       PORTA
    fcall       data_upload_wait
    
    banksel     PORTB
    bsf         PORTB, 0
    bcf         PORTB, 1
    
    ;change value of H_hi
    banksel     PORTA
    movlw       b'00110000'
    movwf       PORTA
    fcall       data_upload_wait
    
    ;using the stored DHT_humidity
    movfw       DHT_humidity
    fcall       hex_to_decimal
    movwf       humidity_bcd
    banksel     PORTA
    movwf       PORTA
    fcall       data_upload_wait
    
    ;change value of H_lo
    banksel     PORTA
    movlw       b'00110000'
    movwf       PORTA
    fcall       data_upload_wait
    
    ;using the stored DHT_humidity
    banksel     PORTA
    swapf       humidity_bcd, f
    movfw       humidity_bcd
    movwf       PORTA
    fcall       data_upload_wait    
    return
    
update_PWM
    banksel     CCP1CON
    movlw       b'00001100'
    movwf       CCP1CON
    
    banksel     T2CON
    movlw       b'00000111'
    movwf       T2CON
    
    banksel     PR2
    movlw       d'252'
    movwf       PR2
    
    movlw       d'20'       ;T1 = 20
    banksel     DHT_temp
    subwf       DHT_temp, f    
    btfsc       DHT_temp, 7
    goto        PWM_off
    
    movlw       d'4'        ;T2 = 24
    banksel     DHT_temp
    subwf       DHT_temp, f    
    btfsc       DHT_temp, 7
    goto        PWM_1
    
    movlw       d'4'        ;T3 = 28
    banksel     DHT_temp
    subwf       DHT_temp, f    
    btfsc       DHT_temp, 7
    goto        PWM_2
    
    goto        PWM_3
    
PWM_off
    banksel     CCPR1L
    movlw       d'0'
    movwf       CCPR1L
    
    banksel     PORTC
    clrf        PORTC
    return
    
PWM_1
    banksel     CCPR1L
    movlw       d'63'
    movwf       CCPR1L
    
    banksel     PORTC
    bsf         PORTC, 7
    bcf         PORTC, 6
    bcf         PORTC, 5
    return

PWM_2
    banksel     CCPR1L
    movlw       d'126'
    movwf       CCPR1L
    
    banksel     PORTB
    bsf         PORTC, 7
    bsf         PORTC, 6
    bcf         PORTC, 5
    return
    
PWM_3
    banksel     CCPR1L
    movlw       d'189'
    movwf       CCPR1L
    
    banksel     PORTC
    bsf         PORTC, 7
    bsf         PORTC, 6
    bsf         PORTC, 5
    return
    
SETUP
	; Insert setup code here.
    nop
    fcall       delay_1200ms
    ;fcall       delay_50us
    ;fcall       delay_20ms
    
    ; top 4 bits for lcd, bottom 1 for DHT11
    banksel     ANSEL
    clrf        ANSEL
    banksel     TRISA
    movlw       b'00001110'     
    movwf       TRISA       
    banksel     PORTA
    clrf        PORTA
    
    ; RC2 is CCP1, set to output, LEDs are top 3 bits
    banksel     ANSELH
    clrf        ANSELH
    banksel     TRISB
    movlw       0xF0
    movwf       TRISB
    banksel     PORTB
    clrf        PORTB
    
    banksel     TRISC
    movlw       b'00011011'   
    movwf       TRISC   
    
    banksel     PORTC
    clrf        PORTC
    
    banksel     init_counter1
    movlw       D'12'
    movwf       init_counter1
    
    movlw       0x00
    movwf       init_counter2
    
    fcall       LCD_init
    fcall       print_name
    fcall       delay_1200ms
    fcall       LCD_DHT_setup
    
LOOP
	; Insert code that repeats here.
    fcall       read_DHT
    ;movlw       d'15'
    ;movwf       DHT_temp
    fcall       update_LCD
    fcall       update_PWM
    
	goto        LOOP		; Jump the Program Counter to where the LOOP label is. This creates an infinite loop!
	
	END		; Directive to signify end of code. This is required.