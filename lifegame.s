/************************************/
/*各種レジスタ定義*/
/************************************/

/***************/
/*レジスタ群の先頭*/
/***************/
.equ REGBASE,  0xFFF000  /*DMAPを使用*/
.equ IOBASE,   0x00d00000

/********************/
/*割り込み関係のレジスタ*/
/********************/
.equ IVR,      REGBASE+0x300 /*割り込みベクタレジスタ*/
.equ IMR,      REGBASE+0x304 /*割り込みマスクレジスタ*/
.equ ISR,      REGBASE+0x30c /*割り込みステータスレジスタ*/
.equ IPR,      REGBASE+0x310 /*割り込みペンディングレジスタ*/

/*******************/
/*タイマ関連のレジスタ*/
/******************/
.equ TCTL1,    REGBASE+0x600 /*タイマ1コントロールレジスタ*/
.equ TPRER1,   REGBASE+0x602 /*タイマ1プリスケーラレジスタ*/
.equ TCMP1,    REGBASE+0x604 /*タイマ1コンペアレジスタ*/
.equ TCN1,     REGBASE+0x608 /*タイマ1カウンタレジスタ*/
.equ TSTAT1,   REGBASE+0x60a /*タイマ1ステータスレジスタ*/

/*************************/
/*UART1(送受信)関係のレジスタ*/
/*************************/
.equ USTCNT1,  REGBASE+0x900 /*UART1ステータス/コントロールレジスタ*/
.equ UBAUD1,   REGBASE+0x902 /*UART1ボーコントロールレジスタ*/
.equ URX1,     REGBASE+0x904 /*UART1受信レジスタ*/
.equ UTX1,     REGBASE+0x906 /*UART1送信レジスタ*/

/*******************/
/*LED*/
/*******************/
.equ LED7,     IOBASE+0x000002f /*ボード搭載のLED用レジスタ*/
.equ LED6,     IOBASE+0x000002d
.equ LED5,     IOBASE+0x000002b
.equ LED4,     IOBASE+0x0000029
.equ LED3,     IOBASE+0x000003f
.equ LED2,     IOBASE+0x000003d
.equ LED1,     IOBASE+0x000003b
.equ LED0,     IOBASE+0x0000039

/******************************************************************/
/*キュー関連の情報の格納場所*/
/******************************************************************/
.equ get_ptr0, qs0+SIZE  
.equ put_ptr0, get_ptr0+4
.equ s0, get_ptr0+8

.equ get_ptr1, qs1+SIZE
.equ put_ptr1, get_ptr1+4
.equ s1, get_ptr1+8

/******************************************************************/
/*システムコール番号*/
/******************************************************************/
.equ  SYSCALL_NUM_GETSTRING,    1
.equ  SYSCALL_NUM_PUTSTRING,    2
.equ  SYSCALL_NUM_RESET_TIMER,  3
.equ  SYSCALL_NUM_SET_TIMER,    4

/******************************************************************/
/*ゲーム関連*/
/******************************************************************/
.equ  AREASIZE,   256
.equ  WH,         16

/********************************************************************/
/*スタック領域の確保*/
/********************************************************************/
.section .bss
.even
SYS_STK:
	.ds.b  0x4000 /*システムスタック領域*/
	.even
SYS_STK_TOP:	/*システムスタック領域の最後尾*/

task_p:	.ds.l 1
/*********************************************************************/
/*初期化*/
/*内部デバイスレジスタには特定の値が設定されている。*/
/*その理由を知るには、付録Bの各レジスタの仕様を参照すること。*/
/**********************************************************************/
.section .text
.even
boot:
	/*スーパバイザ&各種設定を行っている最中の割り込み禁止*/
	move.w  #0x2700, %SR
	lea.l   SYS_STK_TOP, %SP /*set sp*/

	
	/*************************/
	/*割り込みコントローラの初期化*/
	/*************************/
	move.b  #0x40, IVR /*ユーザ割り込みベクタ番号を0x40+levelに設定*/
	move.l  #0x00ffffff, IMR /*全割り込みマスク*/


	/*****************************************************/
	/*送受信(UART1)関係の初期化(割り込みはレベル4に固定されている)*/
	/*****************************************************/
	move.w  #0x0000, USTCNT1 /*リセット*/
	move.w  #0xe100, USTCNT1 /*送受信可能、パリティなし、1stop, 8bit, 送受信割り込み禁止*/
	move.w  #0x0126, UBAUD1  /*baud rate = 38400bps*/
	move.w  #0206, TPRER1  /*0.1msec*/

	move.w  #0x0000, URX1


	/*****************/
	/*タイマ関係の初期化(割り込みレベルは6に設定されている)*/
	/*****************/
	move.w  #0x0004, TCTL1 /*restart, 割り込み不可、システムクロックの1/16を単位として計時、タイマ使用停止*/


/********************************************/
/*ここに必要な初期化などを記入*/
/********************************************/
INIT:
	move.l  #SENDRECV_INTERFACE, 0x110
	move.l  #TIMER,              0x118
	move.l  #SYSTEM_INTERFACE,   0x080

	
	move.l  #0xff3ff9, IMR
	move.w  #0xe10c, USTCNT1
	jsr     INITQ
	bra     MAIN


/*************************************************************************/
/*メインプログラム*/
/**************************************************************************/
.section .text
.even
MAIN:
	
*******************************************************
*** プログラム領域
*******************************************************

**走行モードとレベルの設定
  move.w    #0x0000,                    %SR    |USER MODE, LEVEL0
  lea.l     USR_STK_TOP,                %SP    |user stack config

**システムコールによる RESET_TIMERの起動
  move.l    #SYSCALL_NUM_RESET_TIMER,   %d0
  trap      #0

  jsr GAME_START

**システムコールによる SET_TIMERの起動
  move.l    #SYSCALL_NUM_SET_TIMER,     %d0
  move.w    #10000,                     %d1
  move.l    #GAME,                      %d2
  trap      #0

**************************************
***ゲームすたーと
**************************************
LOOP:   
  bra       LOOP

GAME:
  movem.l   %d0-%d7/%a0-%a6,-(%sp)
  move.w   #0,     %d0 /* i の宣言  */
GAME_MAIN:
  jsr       STEP

  addq.w    #1,     %d0
  cmp       #AREASIZE ,%d0
  bcs GAME_MAIN
  lea.l    GAME_AREA,     %a0
  lea.l    GAME_AREA2,    %a1
  move.w    #0,     %d0
COPYAREA:
  move.b    (%a0)+, (%a1)+
  addq.w    #1,     %d0
  cmp       #AREASIZE ,%d0
  bcs COPYAREA
  movem.l   (%sp)+,%d0-%d7/%a0-%a6
  rts


***************************************
*** step k -> null
*** ライフゲームにおける、k番めのマスの更新
***************************************
STEP:
  movem.l   %d0-%d7/%a0-%a6,-(%sp)
  move.w    %d0,        %d7
  bra       i2xy
  move.w    %d0,        %d2
  move.w    %d1,        %d3
  move.w    #0,         %d1   /* set counter = 0 */
  move.w    %d7,        %d0   /* k の復活  */
***********  変数初期化終了
FOR_I:
  lea.l     LOOP_VALUE, %a2  /*ループの-1,0,1をとってくる  set i */
FOR_J:
    lea.l     LOOP_VALUE, %a3  /*ループの-1,0,1をとってくる  set j */
    move.w    %d2,        #NX
    move.w    %d3,        #NY
    add.b     (a3),       #NX /* nx = j + x */
    add.b     (a2),       #NY /* ny = i + y */
    move.w    %d0,        %d4
    move.w    %d1,        %d5
    move.w    #NX,        %d0
    move.w    #NY,        %d1
    bra       isvalue
    beq       #0,         FOR_J_FINISH
    move.w    %d4,        %d0
    move.w    %d5,        %d1
    bra       xy2i
    bra       acc
    beq       #'0',       FOR_J_FINISH
    add.w     #1,         %d1
    
*** j ループの終わり
FOR_J_FINISH:
    move.w    %d4,        %d0
    move.w    %d5,        %d1
    add.l     #1,         %a3
    cmp       #0xfe,      %a3
    bcs       FOR_J
*** i ループの終わり
  add.l     #1,         %a2
  cmp       #0xfe,      %a2
  bne       FOR_I

  jsr       acc  
  cmp       #'1',       %d0  /* k 番目のマスが生存しているかどうか*/
  bne       DEAD
  move.w    %d7,        %d0   /* AAAA k の復活  */
*** 生存しているなら
  cmp       #2,         %d1
  beq       BIRTH
  cmp       #3,         %d1
  beq       BIRTH
  bra       DIE

*** 死んでいるなら
DEAD:
  move.w    %d7,        %d0   /* k の復活 こちらの場合、AAAAで復活していないため */
  cmp       #3,         %d1
  beq       BIRTH
  bra       DIE

BIRTH: /*i番目のマスは生きる*/
  lea.l     GAME_AREA2, %a1
  add.w     %d0,        %a1
  move.b    #'1',       (%a1)
  bra       STEP_FINISH

DIE: /*i番目のマスを殺す*/
  lea.l     GAME_AREA2, %a1
  add.w     %d0,        %a1
  move.b    #'0',       (%a1)
  bra       STEP_FINISH

STEP_FINISH:
  movem.l   (%sp)+,%d0-%d7/%a0-%a6
  rts

**************************************
*** mod x y  ->  x    % y OK!
*** d1.w, d0.w -> d0.w
**************************************
mod:
  movem.l   %d1-%d7/%a0-%a6,-(%sp)
  divs.w    %d0,    %d1  /* d0 / d1 */
  lsr.l     #16,     %d1
  move.w    %d1,    %d0
  movem.l   (%sp)+,%d1-%d7/%a0-%a6
  rts


**************************************
*** i2xy i -> i % WH,i / WH OK!
*** d0.w   -> d0.w,d1.w
**************************************
i2xy:
  movem.l   %d2-%d7/%a0-%a6,-(%sp)
  move.w    %d0,      %d2
  move.w    #WH,      %d0
  move.w    %d2,      %d1
  jsr mod
  divs.w    #WH,      %d2
  move.w    %d2,      %d1
  movem.l   (%sp)+,%d2-%d7/%a0-%a6
  rts

**************************************
*** xy2i x y  -> i
*** d0.w d1.w -> d0.w
**************************************
xy2i:
  movem.l   %d1-%d7/%a0-%a6,-(%sp)
  muls.w    #16,      %d1
  add.w     %d1,      %d0
  movem.l   (%sp)+,%d1-%d7/%a0-%a6
  rts

**************************************
*** isvalue x y -> return 0 <= x && x < WH && 0 <= y && y < WH OK!
*** d0.w, d1.w  -> d0.w (0 or 1)
**************************************
isvalue:
  movem.l   %d1-%d7/%a0-%a6,-(%sp)
  move.w    %d0,      %d3
  cmp.w     #0,       %d3
  bcs isvalue_failure 
  move.w    %d0,      %d3
  cmp.w     #WH,       %d3
  bcc isvalue_failure 
  move.w    %d1,      %d3
  cmp.w     #0,       %d3
  bcs isvalue_failure 
  move.w    %d1,      %d3
  cmp.w     #WH,       %d3
  bcc isvalue_failure 

isvalue_success:
  move.w   #1,       %d0
  bra isvalue_finish 
isvalue_failure:
  move.w   #0,       %d0
isvalue_finish:
  movem.l   (%sp)+,%d1-%d7/%a0-%a6
  rts

**************************************
*** acc i -> return area[i] OK!
*** d0.w  -> d0.w
**************************************
acc:
  movem.l   %d1-%d7/%a0-%a6,-(%sp)
  lea.l     GAME_AREA,     %a0
  add.l     %d0,           %a0
  move.b    (%a0),         %d0
  movem.l   (%sp)+,%d1-%d7/%a0-%a6
  rts
  

**************************************
***タイマのテスト
**************************************
TT:
  movem.l   %d0-%d7/%a0-%a6,-(%sp)
  cmpi.w    #5,                         TTC | TTCカウンタで5回実行したかどうか数える
  beq       TTKILL 

  move.l    #SYSCALL_NUM_PUTSTRING,     %d0
  move.l    #0,                         %d1 | ch = 0
  move.l    #TMSG,                      %d2 | p  = size 
  move.l    #8,                         %d3 | size = 8
  trap      #0

  addi.w    #1,                         TTC | TTCカウンタを1つ増やして
  bra       TTEND                           | そのままもどる

TTKILL:
  move.l    #SYSCALL_NUM_RESET_TIMER,   %d0
  trap      #0

TTEND:
  movem.l   (%sp)+,%d0-%d7/%a0-%a6
  rts

GAME_START:
  movem.l   %d0-%d7/%a0-%a6,-(%sp)
WAIT_START:
  move.l    #SYSCALL_NUM_GETSTRING,     %d0
  move.l    #0,                         %d1 | ch = 0
  move.l    #BUF,                       %d2 | p  = #BUF
  move.l    #1,                         %d3 | size = 256
  trap      #0
  move.l    #'s',                       %d0
  move.w    %d2,                        %a2
  cmp       (%a2),                        %d0
  bne       WAIT_START
  movem.l   (%sp)+,%d0-%d7/%a0-%a6
  rts
  

**************************************
***初期値のあるデータ領域
**************************************

.section  .data
.even
TMSG:
.ascii  "******\r\n"
.even
TTC:
.dc.w   0
.even
GAME_AREA:
  .ascii "0111000110000001000010011100000110100110100100000010000001101110000001000110101000010001100100000010000000111000000001101000010100010000011000000001010100000101010000000011010010011100101001100000100001000000100111101100011111100011010011001000100000011000"
  .even
GAME_AREA2:
  .ascii "0111000110000001000010011100000110100110100100000010000001101110000001000110101000010001100100000010000000111000000001101000010100010000011000000001010100000101010000000011010010011100101001100000100001000000100111101100011111100011010011001000100000011000"
  .even

LOOP_VALUE:
  .dc.b 0xff,0x00,0x01,0xfe


**************************************
***初期値のないデータ領域
**************************************
.section .bss
.even
BUF:
  .ds.b 256      |BUF[256]
  .even

USR_STK:
  .ds.b 0x4000      |user stack area
  .even
USR_STK_TOP:
NX:
  .dc.w
  .even
NY:
  .dc.w
  .even

/**************************************************************************/
/*システムコールインターフェース*/
/*************************************************************************/
.section .text
.even
	
SYSTEM_INTERFACE:
	movem.l %d1-%d7/%a0-%a6, -(%sp)
  move.w  %d0,  %a0
  cmp     #1,    %a0
  beq   SET_GETSTRING
  move.w  %d0,  %a0
  cmp     #2,    %a0
  beq   SET_PUTSTRING
  move.w  %d0,  %a0
  cmp     #3,    %a0
  beq   SET_RESET_TIMER
  move.w  %d0,  %a0
  cmp     #4,    %a0
  beq   SET_SET_TIMER
  bra   SYSTEM_END


SET_GETSTRING:
  jsr     GETSTRING
  bra     SYSTEM_END

SET_PUTSTRING:
  jsr     PUTSTRING
  bra     SYSTEM_END

SET_RESET_TIMER:
  jsr     RESET_TIMER
  bra     SYSTEM_END

SET_SET_TIMER:
  jsr     SET_TIMER
  bra     SYSTEM_END

SYSTEM_END:
	movem.l (%sp)+, %d1-%d7/%a0-%a6
  rte

/************************************************/
/*送受信インターフェース*/
/************************************************/
SENDRECV_INTERFACE:
	movem.l %d0-%d3, -(%sp)
	move.w  URX1,     %d3
	move.b  %d3,      %d2
	andi.w  #0x2000,  %d3   |13ビットめの確認
	beq      SEND
	move.l  #0,       %d1   | data???
	jsr     INTERGET
	bra     SEND_RECV_END

SEND:	
	move.w  UTX1,     %d0     |UTX１の退避
	andi.w  #0x8000,  %d0   |15ビットめの確認
	beq      SEND_RECV_END
	move.l  #0,       %d1
	jsr     INTERPUT

SEND_RECV_END:
	movem.l (%sp)+, %d0-%d3
	rte

/**************************************************/
/*INTERGET*/
/**************************************************/
INTERGET:
	move.w %sr, -(%sp)	/* レジスタ退避 */
	movem.l %d0-%d6, -(%sp)
	move.w #0x2700, %sr   /*割り込み禁止*/

	cmp.l #0, %d1        /*ch != 0ならば何もしない*/
	bne INTERGET_END

	move.l #0, %d0     /*INQの入力設定*/
	move.b %d2, %d1		/* INQの引数%d1にdataをコピー(有村) */
	jsr INQ

INTERGET_END:
	movem.l (%sp)+, %d0-%d6	/* レジスタ回復 */
	move.w (%sp)+, %sr
	rts
	

/***************************************************************/
/*INTERPUT*/
/***************************************************************/
INTERPUT:
	move.w  %sr, -(%sp)
	movem.l %d0-%d1, -(%sp)
	move.w  #0x2700, %SR /*割り込み禁止*/
	cmp.l   #0, %d1
	bne     INTERPUT_FINISH /*ch 0 でなければ終了    */
	move.w  #1, %d0
	jsr     OUTQ
	cmp.l   #0, %d0
	bne     INTERPUT_SUCCESS
	move.w  #0xe108, USTCNT1 /*OUTQ失敗ならば送信割り込みをマスク */
	bra     INTERPUT_FINISH

INTERPUT_SUCCESS:
	add.l   #0x800, %d1
	move.w  %d1, UTX1 /* 送信レジスタに値を代入 */
	
INTERPUT_FINISH:
	movem.l (%sp)+, %d0-%d1	/* 旧走行レベルの回復 */
	move.w (%sp)+, %sr
	rts
	
/***********************************************************************/
/* PUTSTRING v-2*/
/***********************************************************************/
*入力:	d1チャネル
*	d2:データ読み込み先の先頭アドレス
*	d3:送信するデータ数
*出力:	d0:送信したデータ数
****************************
**%a1:i　レビュー者：波多江
**%d4:sz
**
****************************
PUTSTRING:
	move.w %sr, -(%sp)
	movem.l	%d1-%d4/%a1, -(%sp)		/* レジスタ退避 */
	cmp.l	#0, %d1
	bne	PUTSTRING_FINISH	/* ch != 0なら復帰 */

	move.l	#0, %d4			/* sz = 0 */
	move.l	%d2, %a1		/* i(INQの引数のアドレス) = p */

	cmp.l	#0, %d3			/* size = 0なら分岐 */
	beq 	PUTSTRING3

PUTSTRING1:
	cmp.l	%d3, %d4		/* sz = sizeなら分岐 */
	beq	PUTSTRING2

	move.l	#1, %d0			/* キュー番号(INQの引数)を1に */
	move.b	(%a1), %d1		/* iの指すアドレスの値を取得 */
	jsr 	INQ			/* INQ(1, i)を実行 */
	cmp.l	#0 ,%d0			/* INQ失敗(%d0 = 0)なら分岐 */
	beq 	PUTSTRING2 
	
	add.l	#1 ,%d4			/* sz++ */
	add.l	#1, %a1			/* i++ */
	bra	PUTSTRING1              /*無条件のループ　(波多江)*/

PUTSTRING2:
	move.w	#0xe10c, USTCNT1	/* 送信割り込み許可 */

PUTSTRING3:
	move.l	%d4, %d0		/* %d0 = sz */
	
PUTSTRING_FINISH:
	movem.l	(%sp)+, %d1-%d4/%a1		/* レジスタ回復 */
	rte

/***************************************************************/
/*GETSTRING*/
/***************************************************************/
GETSTRING:                  /*sz:%d4, i:%a1*/
	move.w %sr, -(%sp)
	movem.l %d1-%d6/%a1, -(%sp)  /*退避*/
	cmp.l #0, %d1      
	bne GETS_END          /*ch != 0ならば何もしない*/

	move.l #0, %d4        /*sz <- 0*/
	move.l %d2, %a1         /*i <- p*/
GETS_LOOP:
	cmp.l %d4, %d3    /*sz = sizeならループを抜ける*/
	beq GETS_LAST

	move.l #0, %d0  /*OUTQの入力設定*/
	jsr OUTQ
	
	cmp.l #0, %d0    /*OUTQの出力が0(失敗)ならば終了*/
	beq GETS_LAST

	move.b %d1, (%a1)  /*i番地にdataをコピー*/

	addq.l #1, %d4    /*sz++*/
	addq.l #1, %a1     /*i++*/

	bra GETS_LOOP
	
GETS_LAST:
	move.l %d4, %d0 /* d0 <- sz(平理) */

GETS_END:
	movem.l (%sp)+, %d1-%d6/%a1
	rte


	
/***************************************************************/
/*TIMERインターフェース*/
/***************************************************************/
TIMER:
  move.l %d0, -(%sp)   
  move.w  TSTAT1,   %d0
  and     #1,       %d0
  cmp     #0x000,   %d0
  beq     TIMER_END
  move.w  #0,      TSTAT1
  move.l  (%sp)+, %d0
  jsr     CALL_RP


TIMER_END:
  rte

/**************************************************************/
/*RESET_TIMER    レビュー平健*/
/**************************************************************/
RESET_TIMER:
	move.w  #0x0004, TCTL1  /* タイマ割り込みを不可にし、タイマを停止。システムクロックの1/16を単位として計時する*/
	rts


/**************************************************/
/*SET_TIMER      レビュー平健*/
/**************************************************/
/*
入力:	%d1.w → タイマ割り込み発生周期
	%d2.l → 割り込み時に起動するルーチンの先頭アドレス
出力:	なし
*/
SET_TIMER:
	movem.l %d1-%d2, -(%sp)
	move.l  %d2,  task_p /*大域変数に割り込みルーチンをセット*/
	move.w  #206, TPRER1 /* 0.1ms毎に1カウンタが増える*/
	move.w  %d1,  TCMP1  /*タイマ発生割り込み周期の設定*/
	move.w  #0x0015, TCTL1  /* タイマ割り込みを許可し、タイマを作動。システムクロックの1/16を単位として計時する*/
	movem.l (%sp)+, %d1-%d2
	rts


/***********************/
/*	CALL_RP
	入出力なし*/
/***********************/
CALL_RP:
	movem.l %d0-%d7/%a0-%a6, -(%SP) /*レジスタ退避*/
	move.l  task_p, %a1
	jsr     (%a1) /*a1,つまりtask_pの指すアドレスにjmp*/
	movem.l (%SP)+, %d0-%d7/%a0-%a6 /*レジスタ回復*/
	rts
	
/***************************************************************/
/*キューの初期化*/
/***************************************************************/
INITQ:
	movem.l	%a4, -(%sp)
	lea.l qs0, %a4
	move.l %a4, get_ptr0   /*受信キューの初期化*/
	move.l %a4, put_ptr0
	move.w #0, s0
	lea.l qs1, %a4
	move.l %a4, get_ptr1   /*送信キューの初期化*/
	move.l %a4, put_ptr1
	move.w #0, s1
	movem.l	(%sp)+, %a4
	rts
	
/* 入力　d0 キュー番号
	d1 挿入するデータ
　　出力　d0 挿入の成否*/
INQ:
	move.w %sr, -(%sp) /* 走行レベルの退避 */
	movem.l %a1-%a6/%d2-%d6, -(%sp)	/*レジスタ退避*/
	move.w #0x2700, %sr	 /*走行レベルを7に*/
	move.l %d0, %d5 /* d5 = キュー番号 */

	cmp.l #0, %d5
	beq I_no0           /*受信キュー、送信キューの分岐*/
	lea.l qs1, %a5     /*送信キューのアドレス設定*/
	move.l %a5, top
	add.l  #SIZE, %a5
	subq.l #1, %a5
	move.l %a5, bottom
	move.l get_ptr1, out
	move.l put_ptr1, in
	move.w s1, s
	bra I_three
	
I_no0:
	lea.l qs0, %a5   /*受信キューのアドレス設定*/
	move.l %a5, top
	add.l  #SIZE, %a5
	subq.l #1, %a5
	move.l %a5, bottom
	move.l get_ptr0, out
	move.l put_ptr0, in
	move.w s0, s
	
I_three:	
	move.w s, %d3  /*sを%d3へ*/
	cmp.w #SIZE, %d3 /* s == 256 なら例外処理 */
	bne  I_four
	move.l #0, %d0 /* d0 = 0 として処理中断 */
	bra I_seven

I_four:
	move.l in, %a4 /* a4 = in */
	move.b %d1, (%a4) /* inの指すアドレスに = d1*/
	move.l bottom, %a6
	cmp.l %a6, %a4 /*in == bottomなら*/
	bls I_else

	move.l top, %a5
	move.l %a5, in /*inをリセット*/
	bra I_six

I_else:
	addq.l #1, in

I_six:
	addq.w #1, s
	move.l #1, %d0 /* 処理完了　d0 = 1 */ 
	
I_seven:
	/* 値を返す */
	cmp.l #0, %d5
	beq I_no0rtn           /*受信キュー、送信キューの分岐*/
	/*送信キューのアドレス設定*/
	move.l out, get_ptr1
	move.l in, put_ptr1
	move.w s, s1
	bra I_end
	
I_no0rtn:
	/*受信キューのアドレス設定*/
	move.l out, get_ptr0
	move.l in, put_ptr0
	move.w s, s0

I_end:	
	movem.l (%sp)+, %a1-%a6/%d2-%d6
	move.w (%sp)+, %sr 		/* 旧走行レベルの回復 */
	rts
	
/* 入力　d0 キュー番号
   出力 d0 挿入の成否
	d1 読み出したデータ*/

OUTQ:
	move.w %sr, -(%sp) /* 走行レベルの退避 */
	movem.l %a1-%a6/%d2-%d6, -(%sp)	/*レジスタ退避*/
	move.w #0x2700, %sr	 /*走行レベルを7に*/
	move.l %d0, %d5 /* d5 = キュー番号 */

	cmp.l #0, %d5
	beq O_no0	/*受信キュー、送信キューの分岐*/
	lea.l qs1, %a5
	move.l %a5, top
	add.l  #SIZE, %a5
	subq.l #1, %a5
	move.l %a5, bottom	 /*送信キューのアドレス設定*/
	move.l get_ptr1, out
	move.l put_ptr1, in
	move.w s1, s
	bra O_three
	
O_no0:
	lea.l qs0, %a5
	move.l %a5, top
	add.l  #SIZE, %a5
	subq.l #1, %a5
	move.l %a5, bottom	/*受信キューのアドレス設定*/
	move.l get_ptr0, out
	move.l put_ptr0, in
	move.w s0, s
	
O_three:	
	move.w s, %d3  /*sを%d3へ*/
	cmp.w #0, %d3	/* s == 0 なら例外処理 */
	bne  O_four
	move.l #0, %d0	/* d0 = 0 として処理中断 */
	bra O_seven

O_four:
	move.l out, %a4	/* a4 = out */
	move.b (%a4), %d1	/* outが指すアドレスの値を d1 に */
	move.b #0, (%a4) /* 取り出した値をキューから消去 */
	move.l bottom, %a6
	cmp.l %a6, %a4	 /*out == bottomならinをリセット*/
	bls O_else

	move.l top, %a5
	move.l %a5, out		 /*outをリセット*/
	bra O_six

O_else:
	addq.l #1, out

O_six:
	subq.w #1, s
	move.l #1, %d0	/* 処理完了　d0 = 1 */
	
O_seven:
	/* 値を返す */
	cmp.l #0, %d5
	beq O_no0rtn           /*受信キュー、送信キューの分岐*/
	/*送信キューのアドレス設定*/
	move.l out, get_ptr1
	move.l in, put_ptr1
	move.w s, s1
	bra O_end
	
O_no0rtn:
	/*受信キューのアドレス設定*/
	move.l out, get_ptr0
	move.l in, put_ptr0
	move.w s, s0

O_end:
	movem.l (%sp)+, %a1-%a6/%d2-%d6
	move.w (%sp)+, %sr 		/* 旧走行レベルの回復 */
	rts

/********************************************************************/
.section .data
	.equ SIZE, 256
Data_to_Que:	.ds.b 256
In_Flag:	.ds.b 256
Data_from_Que:	.ds.b 256
Out_Flag:	.ds.b 256

	
	
.section .bss	
top:	.ds.l 1
bottom:	.ds.l 1
out:	.ds.l 1
in:	.ds.l 1
s:	.ds.w 1
	/* キュー領域をSIZE分確保 +10の内訳は以下のとおり
　　	get_ptr  longword 
	put_ptr  longword 
	s	 word    */
qs0:	.ds.b SIZE+10
qs1:	.ds.b SIZE+10
	

	
	.end


	
