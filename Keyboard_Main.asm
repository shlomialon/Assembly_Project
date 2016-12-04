
;מגישים : 
; 311610547 שלומי אלון (מתרגל: גיל לוי) 
; מאור שבתאי (מתרגל: שמיל פלויט) 305036162
;------------------------------------------------------------------------------------------
;; התוכנית נבנתה ע"ב המטלה המקורית (הכוללת תפריט)
;; תצוגת המקלדת נעשתה ע"פ סדר הא"ב האנגלי ולא ע"פ תצוגת המקשים במקלדת ע"מ להשתמש בלולאה להזנת הנתונים ולא פיזית
;; המקלדת שמורה ב800:0 השינויים נשמרו 1000:0 ושמירת המקלדת במצב נתון נשמרה ב1600:0
;; 7c0hולכן השארנו אותו קבוע ב dsהחלטנו לעבוד עם אותו סגמנט נתונים ולכן לא השתמשנו ב
;------------------------------------------------------------------------------------------
xchg bx, bx                        ; Break point for BOCHS debugger                                   
mov ax, 7c0h                       ; Install data segment
mov ds, ax                                                  

main: 
call select_vga 
call Text_menu
call sectors 
call move
jmp $
;------------------------------------------------------------------------------------------
select_vga: ; VGA mode מצב
	push ax
	mov ah, 0
	mov al, 13h
	int 10h
	pop ax
	ret
	
sectors: ; סקטור שאחראי לאתחל את שאר הסקטורים
mov ax, 1300h
mov es, ax
mov bx, 0
mov ah, 2
mov al, 1
mov ch, 0
mov cl, 4
mov dh, 0
mov dl, 80h ; 	
int 13h
call 1300h:0000h
ret


Text_menu: ; הדפסת התפריט במיקום שלו
	mov ch, 17
	mov cl, 17
	mov si, 0
	mov di, 0
	looptest:
		call poinerMenu
		mov bx, [colormenu+di]
		call printmenu
		inc ch
		add di, 4
		cmp di, 32
		je sofTest
		jmp looptest
		sofTest:
		ret
printmenu: ; מדפיס שורה מהתפריט
	cmp byte[bx+si], 0
	je continue
	mov al, [bx+si]
	push bx
	add di ,2
	mov bl, byte[colormenu+di]
	sub di, 2
	mov ah,0eh
	int 10h
	pop bx
	inc si
	jmp printmenu
	continue:
	mov si, 0
	ret

poinerMenu: ; מיקום שורת התפריט במסך
	mov ah, 2
	mov bh, 0
	mov dh, ch 
	mov dl, cl 
	int 10h
ret

move: ; הזזה בתפריט ובחירת אופציה
	mov si, 2
	mov byte[colormenu+si], 6
	push si
	call Text_menu
	pop si
	loopchoice:
	mov byte[colormenu+si], 7
	mov ah,0 ;  AL קלט של תו -הערך האסקיי נכנס לתוך 
	int 16h
	cmp ah,  0x50 ; לחיצה למטה
	je go_down
	cmp ah, 0x48 ; לחיצה למעלה
	je go_up
	cmp al, 0dh ; בדיקה האם נלחץ אנטר - בחירת אופציה
	je choice
	jmp loopchoice
go_down: ; ירידה למטה גורמת למיקום שמעליו להיצבע באפור והמיקום החדש בכתום
	cmp si, 30
	je nomore
	add si, 4
	call chanecolor
	nomore:
	jmp loopchoice
ret	
go_up: ; לחיצה למעלה גורמת למקום שמתחת להיצבע באפור והמיקום החדש באפור
	cmp si, 2
	je nomoreup
	sub si, 4
	call chanecolor
	nomoreup:
	jmp loopchoice
chanecolor:
	mov byte[colormenu+si], 6
	push si
	call Text_menu
	pop si
	ret
choice: ; בחירת אפשרות תתממש בסקטור 5
mov byte[colormenu+si], 2
push si
push si
call Text_menu
pop si
inc si
mov al, byte[colormenu+si]
push si
call 1400h:0000h
pop si
dec si
pop si
mov byte[colormenu+si], 6
	push si
	call select_vga ; איפוס המסך והצגה מחדש של הלחצנים והמקלדת
	call Text_menu  ;^
	mov byte[sector2_choise], 1 ;^
	call 1100h:0000h ;^
	pop si
jmp loopchoice
jmp $

temp db 0 , 1
colors db 7 ; אחראי על צבע התווים בהדפסה
cxmisgeret db 6 , 17 ; על מנת לחסוך שורות קוד בהדפסת המסגרות
dxmisgeretl1 db 6 , 17 ; על מנת לחסוך שורות קוד בהדפסת המסגרות
sector2_choise db 0 ; בורר האופציות עבור פרוצדורות בסקטור 2
sector3_choise db 0 ; בורר האופציות עבור פרוצדורות בסקטור 3
keletC db 'E','n','t','e','r',' ','t','a','b',':',0,'c','h','a','n','g','e',' ','t','o',':',0
defaultsetting db 'd','e','f','a','u','l','t',' ','s','e','t','t','i','n','g',0
clearchange db 'c','l','e','a','r',' ','c','h','a','n','g','e',0
savesetting db 's','a','v','e',' ','s','e','t','t','i','n','g',0
changeabutton db 'c','h','a','n','g','e',' ','a' ,' ','b','u','t','t','o','n',0
creatkeyboardsetting db 'c','r','e','a','t','e',' ','k','e','y','b','o','a','r','d',' ','s','e','t','t','i','n','g',0
setmysetting db 's','e','t',' ','m','y',' ','s','e','t','t','i','n','g',0
print db 'p','r','i','n','t',0
exit db 'e','x','i','t',0
colormenu times 16 dw 0 ; אחראי על שינויי הצבע בתפריט הראשי
times 510 - ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h                          ; Define MAGIC number at byte 512
;;-------------------sector 2-----------------------------------

sector2:
mov al, [sector2_choise]
cmp al, 0
je coise_0
cmp al, 1
je coise_1
cmp al, 3
je coise_3

coise_0: ; בזכרון ומדפיס מקלדת  Hמזין נתונים למקום ה 800
call azana
jmp coise_1
retf
coise_1: ; Hמדפיס מקלדת עם הנתונים שקיימים ב800
call printre_kube
call printmikledet
retf
coise_3: ;ESC פונקציה שמדפיסה תווים עד
call printtab
retf
azana: ; הזנת האותיות לפי סדר לזכרון כך שבתא אחרי כל אות מופיע העמודה והשורה שהיא נמצאת
    mov si, 0
	mov bl, 1
	mov bh, 1
	mov ah, 110
	mov al, 'a'
	start_l1:
		cmp al, ah ;   
		je sof1
		mov cx, 800h
		mov es, cx
		mov byte[es:si], al
		inc si
		mov byte[es:si], bl
		inc si
		mov byte[es:si], bh
		inc si
		mov cx, 1100h
		mov es, cx
		add bh, 2
		inc al
		jmp start_l1
	sof1:
		cmp al, 123
		je sofkelet
		mov bl, 3
		mov bh, 1
		mov ah ,123
		jmp start_l1
		sofkelet:
    ret
	
printre_kube: ; הדפסת ריבועים עבור האותיות
	mov di, 0
	mov si, 1
	mov dx,0
	mov byte[dxmisgeretl1], 6
	mov byte[dxmisgeretl1+si] ,17
	mov byte[cxmisgeret], 6
	mov byte[cxmisgeret+si], 17
	pr:
	mov cx, 0
	cmp di, 13
	je sofprint
	mov ah, 0ch
	mov al, 7
	mov dl, byte[dxmisgeretl1]
	loopR:
		inc dx
		cmp dl,byte[dxmisgeretl1+si]
		je sof222
		mov cl, byte[cxmisgeret]
		loopC:
		inc cx
		cmp cl,byte[cxmisgeret+si]
		je loopR
		int 10h
		jmp loopC
	sof222:
		mov cl,  byte[cxmisgeret+si]
		add cl , 5
		mov byte[cxmisgeret], cl  
		add cl, 11
		mov byte[cxmisgeret+si], cl
	inc di
	jmp pr
	sofprint: ;הדפסת חצי האותיות השני בשורה שנייה
	mov dl, byte[dxmisgeretl1]
	cmp dl, 22
	je endprintribua
	mov di, 0
	mov si, 1
	mov dx,0
	mov byte[dxmisgeretl1], 22
	mov byte[dxmisgeretl1+si] ,33
	mov byte[cxmisgeret], 6
	mov byte[cxmisgeret+si], 17
	jmp pr
	endprintribua:
	ret

printmikledet: ;   hהמקלדת ע"פ הנתונים בזכרון מ1000
	mov di, 0
	mov si,0
	printM:
	mov cx, 0
	mov dx, 0
	cmp di, 26
	je sofloop
	mov ax, 1000h
	mov es , ax
	mov ax, di
	mov bl, 2
	mul bl
	mov di, ax
	inc di
	mov al, byte[es:di]	
	push ax
	mov dx, 0
	dec di
	mov ax, di
	div bl
	mov di, ax
	call mikum
	push ax
	push dx
	mov bx, 1100h
	mov es, bx
	mov bx,0
	call printchar
	inc di
	jmp printM
	sofloop:
    ret
mikum:
	inc si
	mov bx, 800h
	mov es , bx
	mov dl, byte[es:si] ;שורה	
	inc si
	mov al, byte[es:si]	; עמודה
	inc si
	ret
printchar: ; הדפסת תו בצבע
	pop cx
	pop bx ; שורה
	pop dx ; עמודה
	pop ax
	push cx
	mov ah,2
	mov dh, bl
	int 10h
	mov bl, byte[colors]
	mov ah, 9
	mov cx, 1
	mov bh, 0
	int 10h
	ret
	
printtab: ; הדפסת תווים כאשר התו המבוקש מקבל צבע אדום וחוזר להיות אפור כאשר תו אחר נקלט
	mov dl,1
	mov dh,5
	push dx
	show:
	mov dx, 0
	mov si, 1
	mov bl, 7
	mov ah , 0
	int 16h
	cmp al, 01bh
	je esc2
	cmp al, 60
	jna show
	cmp al, 123
	ja show
	push ax
	call printmikledet 
	pop ax
	call kelet
	mov si, 1
	mov byte[temp] ,al
	mov ah, 2
	mov bh, 0
	mov dl, byte[temp+si]
	pop cx
	mov dh, ch
	int 10h
	inc dl
	cmp dl, 35
	je newline
	backprint:
	push dx
	mov byte[temp+si],dl
	mov bx, 7
	mov al, byte[temp]
	mov ah, 0eh
	int 10h
	jmp show
	esc2:
	mov byte[temp+si],1
	pop cx
	ret	

	newline: ;כאשר הוקלדו יותר מידי תווים בשורה יעבור שורה חדשה וכאשר יחרוג ממספר השורות יצא לתפריט הראשי
	add ch, 1
	mov dx, cx
	mov dl, 1
	cmp dh, 17
	jne backprint
	push dx
	jmp esc2
	
kelet: ; מדפיס את המספר הנקלט בצבע אדום ומציג אותו על המסך
	mov byte [colors], 4
	call colortab
	mov ah, 0eh
	int 10h
	esc1:
	ret

colortab: ; צביעה חוזרת של כל האותיות באפור
	mov bl, 'a'
	sub al, bl
	mov ah, 0
	push ax
	mov bl, 3
	mov dx, 0
	mul bl
	mov si, ax
	call mikum
	pop bx
	push ax
	push dx
	mov ax, bx
	mov bl, 2	
	mul bl
	inc ax
	mov di, ax
	mov cx, 1000h
	mov es, cx
	mov al, [es:di]
	mov cx, 1100h
	mov es, cx
	pop bx
	pop dx
	push ax
	push dx
	push bx
	mov bx, 7
	call printchar
	mov byte [colors], 7
	ret

times 1022- ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h 
                         ; Define MAGIC number at byte 512
;;---------------------sector 3--------------------------------
sector3:
mov al , byte[sector3_choise]
cmp al, 0 ;  איתחול : הזנת מערך באורך 26*2 כל אות מוזנת כפול (על מנת השינויים שיהיו בהמשך) 
je coise_S3_1
cmp al, 1
je coise_S3_1 
cmp al, 2
je coise_S3_2
cmp al, 3
je coise_S3_3
cmp al, 4
je coise_S3_4

call newtavla
call kelettoChange
call pelettoChange
call changeOt
call print_idcun
call changeAll

coise_S3_1: ; איתחול הזכרון של השינויים במקלדת
call newtavla
retf

coise_S3_2: ; החלפת תו בתו אחר
call kelettoChange
call pelettoChange
call changeOt
call print_idcun

retf
coise_S3_3: ; החלפת כל האותיות לפי הסדר
call changeAll
retf

coise_S3_4: ; הדפסת המקלדת עם השינויים
call print_idcun
retf

newtavla: ;בזכרון את האותיות כפול, תא ראשון לא ניגע ותא אחריו נשמור את השינויים Hהכנסה למקום ה1000
	mov si, 0
	mov al, 'a'
	mov cx, 1000h
	mov es, cx
	loop_otiyut:
		mov byte[es:si], al
		inc si
		mov byte[es:si], al
		inc si
		cmp al , 'z'
		je sof3
		inc al
		jmp loop_otiyut
	sof3:
	mov cx, 1200h
	mov es, cx
	ret

kelettoChange: ; קליטה מהמשתמש את התו אותו נרצה לשנות
	call again_mikledet
	pop cx
	call pointer
	mov si,0
	call ask
	mov ah , 0
	int 16h
	mov ah,0
	push ax
	mov ah, 0eh
	int 10h
	mov ah, 0Eh       ;ירידת שורה - שורה חדשה
    mov al, 0Dh
    int 10h
	mov al, 0Ah  
	int 10h 
	push cx
	ret
pelettoChange: ; קליטה מהמשתמש את התו אליו ירצה שישתנה
	pop cx
	mov si,11
	call ask
	mov ah , 0
	int 16h
	mov ah,0
	push ax
	mov bx, 7
	mov ah, 0eh
	int 10h
	push cx
	ret
ask: ; הדפסת הבקשות להכנסת קלט לשינוי והכנסת קלט אליו ישתנה
	mov bx, 7
	cmp byte[keletC+si], 0
	je code1
	mov al, [keletC+si]
	mov ah,0eh
	int 10h
	inc si
	jmp ask
	code1:
	ret
	
changeOt: ; שינוי תו, הפרוצדורה מקבלת דרך המחסנית את 2 התווים שבחר המשתמש
	pop cx
	pop bx
	pop ax
	push cx
	sub ax, 'a'
	mov si, 2
	mul si
	inc ax
	mov si, ax
	mov cx, 1000h
	mov es, cx
	mov byte[es:si], bl
	mov cx, 1200h
	mov es, cx
	ret

print_idcun: ; ככך שכל אות ששינינו מחליפה את המקורית Hהעתקת השינויים מהזכרון במקום ה1000 אל המקומות המתאימים ב800 
	mov si, 1
	mov di, 0
	loopIdcun:
	mov ax, 1000h
	mov es, ax
	mov dl , byte[es:si]
	mov ax, 800h
	mov es, ax
	mov byte[es:di], dl
	add si , 2
	add di, 3
	cmp si, 53
	je sof5
	jmp loopIdcun
	sof5:
	call again_mikledet
	ret
again_mikledet: ; הדפסת המקלדת שוב (לאחר השינויים שביצענו)
	mov byte[sector2_choise], 1
	call 1100h:0000h
	mov byte[sector2_choise], 0
	ret
pointer: ; מיקום התחלה למצביע בעת הדפספת תווים
	mov ah, 2
	mov bh, 0
	mov dh, 7
	mov dl, 0
	int 10h
	ret

changeAll: ; החלפת כל האותיות במקלדת
	call again_mikledet 
	mov di, 0
	loopChange:
		call pointer
		mov si ,11	
		mov cx, 1000h
		mov es, cx
		mov al, byte[es:di]
		mov ah,0
		push ax
		mov bx, 7
		mov ah, 0eh
		int 10h
		mov cx, 1200h
		mov es, cx	
		mov ah, 0Eh       ;ירידת שורה - שורה חדשה
		mov al, 0Dh
		int 10h
		mov al, 0Ah  
		int 10h
		pop ax
		push si
		push di
		push ax
		call pelettoChange
		call changeOt
		call print_idcun
		pop di
		pop si
		add di, 2
		cmp di, 52
		jne loopChange
	ret	
	
times 1534- ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h                          ; Define MAGIC number at byte 512	


;;----------------Sector 4-------------------------------	

; Hסקטור 4 אחראי על פתיחת שאר הסקטורים ובכך גם איתחול הנתונים בזכרון ה800 וה1000

ONsector3:
mov ax, 1200h
mov es, ax
mov bx, 0
mov ah, 2
mov al, 1
mov ch, 0
mov cl, 3
mov dh, 0
mov dl, 80h ; 	
int 13h


ONsector2:
mov ax, 1100h
mov es, ax
mov bx, 0
mov ah, 2
mov al, 1
mov ch, 0
mov cl, 2
mov dh, 0
mov dl, 80h ; 	
int 13h


ONsector5:
mov ax, 1400h
mov es, ax
mov bx, 0
mov ah, 2
mov al, 1
mov ch, 0
mov cl, 5
mov dh, 0
mov dl, 80h ; 	
int 13h

azana_Menu: ; מזין את המחרוזות של התפריט, צבע אפור, מספר הפעולה שעליה הוא אחראי
mov si, 0
mov cl, 1 
mov ax, defaultsetting
call loopazana
mov ax, clearchange
call loopazana
mov ax, savesetting
call loopazana
mov ax, changeabutton
call loopazana
mov ax, creatkeyboardsetting
call loopazana
mov ax, setmysetting
call loopazana
mov ax, print
call loopazana
mov ax, exit
call loopazana
	
call 1100h:0000h
call 1200h:0000h
mov byte[sector2_choise], 1
call 1100h:0000h

retf

loopazana:
	mov [colormenu+si], ax
	add si, 2
	mov byte[colormenu+si], 7
	inc si
	mov byte[colormenu+si], cl
	inc cl
	inc si
	ret

	
times 2046- ($-$$) db 0            ; Fill empty bytes to binary file
dw 0aa55h 
;;----------------Sector 5-------------------------------

; סקטור 5 אחראי על ביצוע פעולות התפריט, כאשר הפעולות נקלחות ממה שנכתב בסקטור 2 ובסקטור 3
cmp al, 0
je backchoise
cmp al, 1
je default_option
cmp al, 2
je clear_option
cmp al, 3
je save_option
cmp al, 4
je changeB_option
cmp al, 5
je creat_option
cmp al, 6
je set_option
cmp al, 7
je print_option
cmp al, 8
je exit_option

default_option: ; מציג את ברירת מחדל של המקלדת
	mov byte[sector3_choise],0
	call 1200h:0000h
	mov byte[sector2_choise], 0
	call 1100h:0000h
	jmp backchoise
clear_option: ; ניקוי הזכרון משינויים ששמרנו
	mov si, 0
	loopdelet:
	mov ax, 1600h
	mov es, ax
	mov byte[es:si], 0
	inc si
	cmp si, 52
	je continue2
	jmp loopdelet
	continue2:
	mov byte[sector3_choise], 1
	call 1200h:0000h
	mov byte[sector3_choise], 0
	mov byte[sector2_choise], 0
	call 1100h:0000h
	jmp backchoise
save_option: ; Hשמירת שינויים שביצענו החל מהכתובת 1600
	mov si, 0
	loopsave:
	mov ax, 1000h
	mov es, ax
	mov dl, byte[es:si]
	mov ax, 1600h
	mov es, ax
	mov byte[es:si], dl
	inc si
	cmp si, 52
	je back3
	jmp loopsave
	back3:
	jmp backchoise
changeB_option: ; החלפת תו
	mov byte[sector3_choise], 2
	call 1200h:0000h
	mov byte[sector3_choise], 0	
	jmp backchoise
creat_option: ; החלפת כל האותיות
	mov byte[sector3_choise], 3
	call 1200h:0000h
	mov byte[sector3_choise], 0	
	jmp backchoise
set_option: ; טעינת השינויים שנשמרו
	mov si, 0
	loopset:
	mov ax, 1600h
	mov es, ax
	mov dl, byte[es:si]
	cmp dl , 0
	je back4
	mov ax, 1000h
	mov es, ax
	mov byte[es:si], dl
	inc si
	cmp si, 52
	je back4
	jmp loopset
	back4:
	mov byte[sector3_choise], 4
	call 1200h:0000h
	mov byte[sector3_choise], 0
	jmp backchoise
print_option:	; הדפסת תווים
	mov byte[sector2_choise], 3
	call 1100h:0000h
	mov byte[sector2_choise], 0	
	mov byte[sector2_choise], 1
	call 1100h:0000h
	mov byte[sector2_choise], 0
	jmp backchoise
exit_option: ; יציאה מהתוכנית
	push ax
	mov ah, 0
	mov al, 13h
	int 10h
	pop ax
	jmp $
	
backchoise:
	retf

times 2*8*63*512 - ($-$$) db 0
