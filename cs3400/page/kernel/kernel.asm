
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	91013103          	ld	sp,-1776(sp) # 80008910 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	92070713          	addi	a4,a4,-1760 # 80008970 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	fce78793          	addi	a5,a5,-50 # 80006030 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca1f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	92650513          	addi	a0,a0,-1754 # 80010ab0 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	91648493          	addi	s1,s1,-1770 # 80010ab0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	9a690913          	addi	s2,s2,-1626 # 80010b48 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	88a50513          	addi	a0,a0,-1910 # 80010ab0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	87450513          	addi	a0,a0,-1932 # 80010ab0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8cf72b23          	sw	a5,-1834(a4) # 80010b48 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7e450513          	addi	a0,a0,2020 # 80010ab0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	7b650513          	addi	a0,a0,1974 # 80010ab0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	79270713          	addi	a4,a4,1938 # 80010ab0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	76878793          	addi	a5,a5,1896 # 80010ab0 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7d27a783          	lw	a5,2002(a5) # 80010b48 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	72670713          	addi	a4,a4,1830 # 80010ab0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	71648493          	addi	s1,s1,1814 # 80010ab0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6da70713          	addi	a4,a4,1754 # 80010ab0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	76f72223          	sw	a5,1892(a4) # 80010b50 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	69e78793          	addi	a5,a5,1694 # 80010ab0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	70c7ab23          	sw	a2,1814(a5) # 80010b4c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	70a50513          	addi	a0,a0,1802 # 80010b48 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	65050513          	addi	a0,a0,1616 # 80010ab0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	7d078793          	addi	a5,a5,2000 # 80020c48 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6207a223          	sw	zero,1572(a5) # 80010b70 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	d5250513          	addi	a0,a0,-686 # 800082c0 <digits+0x280>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	3af72823          	sw	a5,944(a4) # 80008930 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	5b4dad83          	lw	s11,1460(s11) # 80010b70 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	55e50513          	addi	a0,a0,1374 # 80010b58 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	40050513          	addi	a0,a0,1024 # 80010b58 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	3e448493          	addi	s1,s1,996 # 80010b58 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	3a450513          	addi	a0,a0,932 # 80010b78 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1307a783          	lw	a5,304(a5) # 80008930 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1007b783          	ld	a5,256(a5) # 80008938 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	10073703          	ld	a4,256(a4) # 80008940 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	316a0a13          	addi	s4,s4,790 # 80010b78 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	0ce48493          	addi	s1,s1,206 # 80008938 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	0ce98993          	addi	s3,s3,206 # 80008940 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	2a850513          	addi	a0,a0,680 # 80010b78 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0507a783          	lw	a5,80(a5) # 80008930 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	05673703          	ld	a4,86(a4) # 80008940 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	0467b783          	ld	a5,70(a5) # 80008938 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	27a98993          	addi	s3,s3,634 # 80010b78 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	03248493          	addi	s1,s1,50 # 80008938 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	03290913          	addi	s2,s2,50 # 80008940 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	24448493          	addi	s1,s1,580 # 80010b78 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fee7bc23          	sd	a4,-8(a5) # 80008940 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	1be48493          	addi	s1,s1,446 # 80010b78 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	3e478793          	addi	a5,a5,996 # 80021de0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	19490913          	addi	s2,s2,404 # 80010bb0 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0f650513          	addi	a0,a0,246 # 80010bb0 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	31250513          	addi	a0,a0,786 # 80021de0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0c048493          	addi	s1,s1,192 # 80010bb0 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	0a850513          	addi	a0,a0,168 # 80010bb0 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	07c50513          	addi	a0,a0,124 # 80010bb0 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd221>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
int process_id = 1;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	ac070713          	addi	a4,a4,-1344 # 80008948 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	bd6080e7          	jalr	-1066(ra) # 80002a94 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	1aa080e7          	jalr	426(ra) # 80006070 <plicinithart>
  }

  //printf("I cant Dollar your Mom: %d\n", pages(21));
  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	3da50513          	addi	a0,a0,986 # 800082c0 <digits+0x280>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	3ba50513          	addi	a0,a0,954 # 800082c0 <digits+0x280>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	b36080e7          	jalr	-1226(ra) # 80002a6c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	b56080e7          	jalr	-1194(ra) # 80002a94 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	114080e7          	jalr	276(ra) # 8000605a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	122080e7          	jalr	290(ra) # 80006070 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2c4080e7          	jalr	708(ra) # 8000321a <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	964080e7          	jalr	-1692(ra) # 800038c2 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	90a080e7          	jalr	-1782(ra) # 80004870 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	20a080e7          	jalr	522(ra) # 80006178 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9cf72223          	sw	a5,-1596(a4) # 80008948 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9b87b783          	ld	a5,-1608(a5) # 80008950 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd217>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ea7be23          	sd	a0,1788(a5) # 80008950 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd220>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	7b448493          	addi	s1,s1,1972 # 80011000 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	19aa0a13          	addi	s4,s4,410 # 80016a00 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2e850513          	addi	a0,a0,744 # 80010bd0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2e850513          	addi	a0,a0,744 # 80010be8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6f048493          	addi	s1,s1,1776 # 80011000 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	0ce98993          	addi	s3,s3,206 # 80016a00 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	26450513          	addi	a0,a0,612 # 80010c00 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	20c70713          	addi	a4,a4,524 # 80010bd0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	ec87a783          	lw	a5,-312(a5) # 800088c4 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	0a6080e7          	jalr	166(ra) # 80002aac <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	ea07a723          	sw	zero,-338(a5) # 800088c4 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	e22080e7          	jalr	-478(ra) # 80003842 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	19a90913          	addi	s2,s2,410 # 80010bd0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e8078793          	addi	a5,a5,-384 # 800088c8 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	43e48493          	addi	s1,s1,1086 # 80011000 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	e3690913          	addi	s2,s2,-458 # 80016a00 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	cca7b023          	sd	a0,-832(a5) # 80008958 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	c2c58593          	addi	a1,a1,-980 # 800088d0 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	58a080e7          	jalr	1418(ra) # 8000426c <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00003097          	auipc	ra,0x3
    80001e16:	af0080e7          	jalr	-1296(ra) # 80004902 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	c5e080e7          	jalr	-930(ra) # 80003a82 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d9848493          	addi	s1,s1,-616 # 80010be8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	d1270713          	addi	a4,a4,-750 # 80010bd0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	d3c70713          	addi	a4,a4,-708 # 80010c08 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cf4a0a13          	addi	s4,s4,-780 # 80010bd0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	b1a90913          	addi	s2,s2,-1254 # 80016a00 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	10648493          	addi	s1,s1,262 # 80011000 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00001097          	auipc	ra,0x1
    80001f38:	ace080e7          	jalr	-1330(ra) # 80002a02 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c6670713          	addi	a4,a4,-922 # 80010bd0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c4090913          	addi	s2,s2,-960 # 80010bd0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c6058593          	addi	a1,a1,-928 # 80010c08 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00001097          	auipc	ra,0x1
    80001fba:	a4c080e7          	jalr	-1460(ra) # 80002a02 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	f3448493          	addi	s1,s1,-204 # 80011000 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	92890913          	addi	s2,s2,-1752 # 80016a00 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	ec048493          	addi	s1,s1,-320 # 80011000 <proc>
      pp->parent = initproc;
    80002148:	00007a17          	auipc	s4,0x7
    8000214c:	810a0a13          	addi	s4,s4,-2032 # 80008958 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002150:	00015997          	auipc	s3,0x15
    80002154:	8b098993          	addi	s3,s3,-1872 # 80016a00 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if(pp->parent == p){
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7b47b783          	ld	a5,1972(a5) # 80008958 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	78c080e7          	jalr	1932(ra) # 80004954 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	2ac080e7          	jalr	684(ra) # 8000448c <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00002097          	auipc	ra,0x2
    800021f0:	a8e080e7          	jalr	-1394(ra) # 80003c7a <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	316080e7          	jalr	790(ra) # 8000450a <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	9e848493          	addi	s1,s1,-1560 # 80010be8 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d9248493          	addi	s1,s1,-622 # 80011000 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	78a98993          	addi	s3,s3,1930 # 80016a00 <tickslock>
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void
setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int
killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	89650513          	addi	a0,a0,-1898 # 80010be8 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	69898993          	addi	s3,s3,1688 # 80016a00 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	878c0c13          	addi	s8,s8,-1928 # 80010be8 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c8648493          	addi	s1,s1,-890 # 80011000 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000f517          	auipc	a0,0xf
    800023bc:	83050513          	addi	a0,a0,-2000 # 80010be8 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000f517          	auipc	a0,0xf
    800023d8:	81450513          	addi	a0,a0,-2028 # 80010be8 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if(pp->parent == p){
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if(!havekids || killed(p)){
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	7c650513          	addi	a0,a0,1990 # 80010be8 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if(user_dst){
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if(user_src){
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	da250513          	addi	a0,a0,-606 # 800082c0 <digits+0x280>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	c2a48493          	addi	s1,s1,-982 # 80011158 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	62290913          	addi	s2,s2,1570 # 80016b58 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	d70a0a13          	addi	s4,s4,-656 # 800082c0 <digits+0x280>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	db8b8b93          	addi	s7,s7,-584 # 80008310 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if(p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <print_pages>:

static char digits[] = "0123456789abcdef";

void print_pages(pagetable_t pagetable, int pagedepth)
{
  if (pagedepth <= 2)
    800025b8:	4789                	li	a5,2
    800025ba:	38b7c463          	blt	a5,a1,80002942 <print_pages+0x38a>
{
    800025be:	7129                	addi	sp,sp,-320
    800025c0:	fe06                	sd	ra,312(sp)
    800025c2:	fa22                	sd	s0,304(sp)
    800025c4:	f626                	sd	s1,296(sp)
    800025c6:	f24a                	sd	s2,288(sp)
    800025c8:	ee4e                	sd	s3,280(sp)
    800025ca:	ea52                	sd	s4,272(sp)
    800025cc:	e656                	sd	s5,264(sp)
    800025ce:	e25a                	sd	s6,256(sp)
    800025d0:	fdde                	sd	s7,248(sp)
    800025d2:	f9e2                	sd	s8,240(sp)
    800025d4:	f5e6                	sd	s9,232(sp)
    800025d6:	f1ea                	sd	s10,224(sp)
    800025d8:	edee                	sd	s11,216(sp)
    800025da:	0280                	addi	s0,sp,320
    800025dc:	8bae                	mv	s7,a1
    800025de:	8aaa                	mv	s5,a0
    800025e0:	0005871b          	sext.w	a4,a1
      pte_t pte = pagetable[i];
      if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
      {
        char str[80];
        int d = 0;
        for (int j = 2 - pagedepth; j > 0; j--)
    800025e4:	4c89                	li	s9,2
    800025e6:	40bc8cbb          	subw	s9,s9,a1
    800025ea:	000c8d1b          	sext.w	s10,s9
    800025ee:	fffd4793          	not	a5,s10
    800025f2:	97fd                	srai	a5,a5,0x3f
    800025f4:	00fcfcb3          	and	s9,s9,a5
    800025f8:	000c8d9b          	sext.w	s11,s9
    800025fc:	001c879b          	addiw	a5,s9,1
    80002600:	ecf43c23          	sd	a5,-296(s0)
        {
          str[d++] = '\n';
        }
        for (int j = 0; j < pagedepth; j++)
        {
          str[d++] = '\t';
    80002604:	00bc87bb          	addw	a5,s9,a1
    80002608:	00b05363          	blez	a1,8000260e <print_pages+0x56>
    8000260c:	8cbe                	mv	s9,a5
    8000260e:	000c879b          	sext.w	a5,s9
    80002612:	ecf43823          	sd	a5,-304(s0)
    80002616:	ef040693          	addi	a3,s0,-272
    8000261a:	00f68c33          	add	s8,a3,a5
    8000261e:	8cbe                	mv	s9,a5
    for (int i = 0; i < 512; i++)
    80002620:	4a01                	li	s4,0
        uint x = i;
        int strlen = 0;
        do
        {
          strlen++;
          buf[ii++] = digits[x % 10];
    80002622:	00006997          	auipc	s3,0x6
    80002626:	cee98993          	addi	s3,s3,-786 # 80008310 <states.0>
        print_pages(child, pagedepth + 1);
    8000262a:	001b879b          	addiw	a5,s7,1
    8000262e:	ecf43423          	sd	a5,-312(s0)
    80002632:	00168b13          	addi	s6,a3,1
    80002636:	4785                	li	a5,1
    80002638:	9f99                	subw	a5,a5,a4
    8000263a:	1782                	slli	a5,a5,0x20
    8000263c:	9381                	srli	a5,a5,0x20
    8000263e:	9b3e                	add	s6,s6,a5
    80002640:	ac59                	j	800028d6 <print_pages+0x31e>
        for (int j = 2 - pagedepth; j > 0; j--)
    80002642:	01a05a63          	blez	s10,80002656 <print_pages+0x9e>
    80002646:	ef040793          	addi	a5,s0,-272
          str[d++] = '\n';
    8000264a:	4729                	li	a4,10
    8000264c:	00e78023          	sb	a4,0(a5)
        for (int j = 2 - pagedepth; j > 0; j--)
    80002650:	0785                	addi	a5,a5,1
    80002652:	ff679de3          	bne	a5,s6,8000264c <print_pages+0x94>
        for (int j = 0; j < pagedepth; j++)
    80002656:	03705263          	blez	s7,8000267a <print_pages+0xc2>
          str[d++] = '\t';
    8000265a:	4725                	li	a4,9
    8000265c:	f90d8793          	addi	a5,s11,-112
    80002660:	97a2                	add	a5,a5,s0
    80002662:	f6e78023          	sb	a4,-160(a5)
        for (int j = 0; j < pagedepth; j++)
    80002666:	4789                	li	a5,2
    80002668:	00fb9963          	bne	s7,a5,8000267a <print_pages+0xc2>
          str[d++] = '\t';
    8000266c:	ed843783          	ld	a5,-296(s0)
    80002670:	f9078793          	addi	a5,a5,-112
    80002674:	97a2                	add	a5,a5,s0
    80002676:	f6e78023          	sb	a4,-160(a5)
        uint x = i;
    8000267a:	000a071b          	sext.w	a4,s4
        int strlen = 0;
    8000267e:	f4040613          	addi	a2,s0,-192
    80002682:	4681                	li	a3,0
          buf[ii++] = digits[x % 10];
    80002684:	4529                	li	a0,10
        } while ((x /= 10) != 0);
    80002686:	4825                	li	a6,9
          strlen++;
    80002688:	85b6                	mv	a1,a3
    8000268a:	2685                	addiw	a3,a3,1
          buf[ii++] = digits[x % 10];
    8000268c:	02a777bb          	remuw	a5,a4,a0
    80002690:	1782                	slli	a5,a5,0x20
    80002692:	9381                	srli	a5,a5,0x20
    80002694:	97ce                	add	a5,a5,s3
    80002696:	0307c783          	lbu	a5,48(a5)
    8000269a:	00f60023          	sb	a5,0(a2) # 1000 <_entry-0x7ffff000>
        } while ((x /= 10) != 0);
    8000269e:	0007079b          	sext.w	a5,a4
    800026a2:	02a7573b          	divuw	a4,a4,a0
    800026a6:	0605                	addi	a2,a2,1
    800026a8:	fef860e3          	bltu	a6,a5,80002688 <print_pages+0xd0>
        for (int j = 0; j < (3 - strlen); j++)
    800026ac:	448d                	li	s1,3
    800026ae:	9c95                	subw	s1,s1,a3
    800026b0:	0004879b          	sext.w	a5,s1
    800026b4:	0af05b63          	blez	a5,8000276a <print_pages+0x1b2>
    800026b8:	001c0713          	addi	a4,s8,1
    800026bc:	4789                	li	a5,2
    800026be:	9f95                	subw	a5,a5,a3
    800026c0:	1782                	slli	a5,a5,0x20
    800026c2:	9381                	srli	a5,a5,0x20
    800026c4:	973e                	add	a4,a4,a5
    800026c6:	87e2                	mv	a5,s8
          str[d++] = '0';
    800026c8:	03000613          	li	a2,48
    800026cc:	00c78023          	sb	a2,0(a5)
        for (int j = 0; j < (3 - strlen); j++)
    800026d0:	0785                	addi	a5,a5,1
    800026d2:	fee79de3          	bne	a5,a4,800026cc <print_pages+0x114>
          str[d++] = '0';
    800026d6:	019484bb          	addw	s1,s1,s9
        for (int j = 1; j <= strlen; j++)
    800026da:	02d05b63          	blez	a3,80002710 <print_pages+0x158>
    800026de:	f4040793          	addi	a5,s0,-192
    800026e2:	96be                	add	a3,a3,a5
    800026e4:	4781                	li	a5,0
          str[d++] = buf[strlen - j];
    800026e6:	00f48733          	add	a4,s1,a5
    800026ea:	ef040613          	addi	a2,s0,-272
    800026ee:	9732                	add	a4,a4,a2
    800026f0:	fff6c603          	lbu	a2,-1(a3)
    800026f4:	00c70023          	sb	a2,0(a4)
        for (int j = 1; j <= strlen; j++)
    800026f8:	0785                	addi	a5,a5,1
    800026fa:	16fd                	addi	a3,a3,-1
    800026fc:	0007871b          	sext.w	a4,a5
    80002700:	fee5d3e3          	bge	a1,a4,800026e6 <print_pages+0x12e>
    80002704:	2485                	addiw	s1,s1,1
          str[d++] = buf[strlen - j];
    80002706:	fff5c793          	not	a5,a1
    8000270a:	97fd                	srai	a5,a5,0x3f
    8000270c:	8dfd                	and	a1,a1,a5
    8000270e:	9cad                	addw	s1,s1,a1
        safestrcpy(str + d, ": %p ", 6);
    80002710:	4619                	li	a2,6
    80002712:	00006597          	auipc	a1,0x6
    80002716:	b8658593          	addi	a1,a1,-1146 # 80008298 <digits+0x258>
    8000271a:	ef040793          	addi	a5,s0,-272
    8000271e:	00978533          	add	a0,a5,s1
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	6fa080e7          	jalr	1786(ra) # 80000e1c <safestrcpy>
        str[d++] = '\n';
    8000272a:	0054879b          	addiw	a5,s1,5
    8000272e:	f9078793          	addi	a5,a5,-112
    80002732:	97a2                	add	a5,a5,s0
    80002734:	4729                	li	a4,10
    80002736:	f6e78023          	sb	a4,-160(a5)
        str[d++] = '\0';
    8000273a:	0064879b          	addiw	a5,s1,6
    8000273e:	f9078793          	addi	a5,a5,-112
    80002742:	97a2                	add	a5,a5,s0
    80002744:	f6078023          	sb	zero,-160(a5)
        printf(str, pte);
    80002748:	85ca                	mv	a1,s2
    8000274a:	ef040513          	addi	a0,s0,-272
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e3c080e7          	jalr	-452(ra) # 8000058a <printf>
        pagetable_t child = (pagetable_t)PTE2PA(pte);
    80002756:	00a95513          	srli	a0,s2,0xa
        print_pages(child, pagedepth + 1);
    8000275a:	ec843583          	ld	a1,-312(s0)
    8000275e:	0532                	slli	a0,a0,0xc
    80002760:	00000097          	auipc	ra,0x0
    80002764:	e58080e7          	jalr	-424(ra) # 800025b8 <print_pages>
    80002768:	a28d                	j	800028ca <print_pages+0x312>
        for (int j = 0; j < (3 - strlen); j++)
    8000276a:	ed043483          	ld	s1,-304(s0)
    8000276e:	b7b5                	j	800026da <print_pages+0x122>
        uint x = i;
    80002770:	000a071b          	sext.w	a4,s4
        int strlen = 0;
    80002774:	ee040613          	addi	a2,s0,-288
    80002778:	4681                	li	a3,0
          buf[ii++] = digits[x % 10];
    8000277a:	4529                	li	a0,10
        } while ((x /= 10) != 0);
    8000277c:	4825                	li	a6,9
          strlen++;
    8000277e:	85b6                	mv	a1,a3
    80002780:	2685                	addiw	a3,a3,1
          buf[ii++] = digits[x % 10];
    80002782:	02a777bb          	remuw	a5,a4,a0
    80002786:	1782                	slli	a5,a5,0x20
    80002788:	9381                	srli	a5,a5,0x20
    8000278a:	97ce                	add	a5,a5,s3
    8000278c:	0307c783          	lbu	a5,48(a5)
    80002790:	00f60023          	sb	a5,0(a2)
        } while ((x /= 10) != 0);
    80002794:	0007079b          	sext.w	a5,a4
    80002798:	02a7573b          	divuw	a4,a4,a0
    8000279c:	0605                	addi	a2,a2,1
    8000279e:	fef860e3          	bltu	a6,a5,8000277e <print_pages+0x1c6>
        for (int j = 0; j < (3 - strlen); j++)
    800027a2:	450d                	li	a0,3
    800027a4:	9d15                	subw	a0,a0,a3
    800027a6:	0005079b          	sext.w	a5,a0
    800027aa:	02f05563          	blez	a5,800027d4 <print_pages+0x21c>
    800027ae:	f4040793          	addi	a5,s0,-192
    800027b2:	97a6                	add	a5,a5,s1
    800027b4:	f4140713          	addi	a4,s0,-191
    800027b8:	9726                	add	a4,a4,s1
    800027ba:	4609                	li	a2,2
    800027bc:	9e15                	subw	a2,a2,a3
    800027be:	1602                	slli	a2,a2,0x20
    800027c0:	9201                	srli	a2,a2,0x20
    800027c2:	9732                	add	a4,a4,a2
        {
          str[d++] = '0';
    800027c4:	03000613          	li	a2,48
    800027c8:	00c78023          	sb	a2,0(a5)
        for (int j = 0; j < (3 - strlen); j++)
    800027cc:	0785                	addi	a5,a5,1
    800027ce:	fee79de3          	bne	a5,a4,800027c8 <print_pages+0x210>
          str[d++] = '0';
    800027d2:	9ca9                	addw	s1,s1,a0
        }
        for (int j = 1; j <= strlen; j++)
    800027d4:	02d05b63          	blez	a3,8000280a <print_pages+0x252>
    800027d8:	ee040793          	addi	a5,s0,-288
    800027dc:	96be                	add	a3,a3,a5
    800027de:	4781                	li	a5,0
        {
          str[d++] = buf[strlen - j];
    800027e0:	00f48733          	add	a4,s1,a5
    800027e4:	f4040613          	addi	a2,s0,-192
    800027e8:	9732                	add	a4,a4,a2
    800027ea:	fff6c603          	lbu	a2,-1(a3)
    800027ee:	00c70023          	sb	a2,0(a4)
        for (int j = 1; j <= strlen; j++)
    800027f2:	0785                	addi	a5,a5,1
    800027f4:	16fd                	addi	a3,a3,-1
    800027f6:	0007871b          	sext.w	a4,a5
    800027fa:	fee5d3e3          	bge	a1,a4,800027e0 <print_pages+0x228>
    800027fe:	2485                	addiw	s1,s1,1
          str[d++] = buf[strlen - j];
    80002800:	fff5c793          	not	a5,a1
    80002804:	97fd                	srai	a5,a5,0x3f
    80002806:	8dfd                	and	a1,a1,a5
    80002808:	9cad                	addw	s1,s1,a1
        }

        safestrcpy(str + d, ": %p ", 6);
    8000280a:	4619                	li	a2,6
    8000280c:	00006597          	auipc	a1,0x6
    80002810:	a8c58593          	addi	a1,a1,-1396 # 80008298 <digits+0x258>
    80002814:	f4040793          	addi	a5,s0,-192
    80002818:	00978533          	add	a0,a5,s1
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	600080e7          	jalr	1536(ra) # 80000e1c <safestrcpy>
        d += 5;
        str[d++] = ' ';
    80002824:	0054879b          	addiw	a5,s1,5
    80002828:	f9078793          	addi	a5,a5,-112
    8000282c:	97a2                	add	a5,a5,s0
    8000282e:	02000693          	li	a3,32
    80002832:	fad78823          	sb	a3,-80(a5)
        str[d++] = ' ';
    80002836:	0074879b          	addiw	a5,s1,7
    8000283a:	0064871b          	addiw	a4,s1,6
    8000283e:	f9070713          	addi	a4,a4,-112
    80002842:	9722                	add	a4,a4,s0
    80002844:	fad70823          	sb	a3,-80(a4)
        str[d++] = (pte & PTE_R) ? 'r' : '-';
    80002848:	00297713          	andi	a4,s2,2
    8000284c:	07200693          	li	a3,114
    80002850:	e319                	bnez	a4,80002856 <print_pages+0x29e>
    80002852:	02d00693          	li	a3,45
    80002856:	0084871b          	addiw	a4,s1,8
    8000285a:	f9078793          	addi	a5,a5,-112
    8000285e:	97a2                	add	a5,a5,s0
    80002860:	fad78823          	sb	a3,-80(a5)
        str[d++] = (pte & PTE_W) ? 'w' : '-';
    80002864:	00497793          	andi	a5,s2,4
    80002868:	07700693          	li	a3,119
    8000286c:	e399                	bnez	a5,80002872 <print_pages+0x2ba>
    8000286e:	02d00693          	li	a3,45
    80002872:	0094879b          	addiw	a5,s1,9
    80002876:	f9070713          	addi	a4,a4,-112
    8000287a:	9722                	add	a4,a4,s0
    8000287c:	fad70823          	sb	a3,-80(a4)
        str[d++] = (pte & PTE_X) ? 'x' : '-';
    80002880:	00897713          	andi	a4,s2,8
    80002884:	07800693          	li	a3,120
    80002888:	e319                	bnez	a4,8000288e <print_pages+0x2d6>
    8000288a:	02d00693          	li	a3,45
    8000288e:	00a4851b          	addiw	a0,s1,10
    80002892:	f9078793          	addi	a5,a5,-112
    80002896:	97a2                	add	a5,a5,s0
    80002898:	fad78823          	sb	a3,-80(a5)
        if (!(pte & PTE_U))
    8000289c:	01097793          	andi	a5,s2,16
    800028a0:	c3bd                	beqz	a5,80002906 <print_pages+0x34e>
        {
          safestrcpy(str + d, "   (kernel)", 12);
          d += 11;
        }
        str[d++] = '\n';
    800028a2:	f9050793          	addi	a5,a0,-112
    800028a6:	97a2                	add	a5,a5,s0
    800028a8:	4729                	li	a4,10
    800028aa:	fae78823          	sb	a4,-80(a5)
        str[d++] = '\0';
    800028ae:	2505                	addiw	a0,a0,1
    800028b0:	f9050793          	addi	a5,a0,-112
    800028b4:	00878533          	add	a0,a5,s0
    800028b8:	fa050823          	sb	zero,-80(a0)

        printf(str, pte);
    800028bc:	85ca                	mv	a1,s2
    800028be:	f4040513          	addi	a0,s0,-192
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cc8080e7          	jalr	-824(ra) # 8000058a <printf>
    for (int i = 0; i < 512; i++)
    800028ca:	2a05                	addiw	s4,s4,1
    800028cc:	0aa1                	addi	s5,s5,8
    800028ce:	20000793          	li	a5,512
    800028d2:	04fa0963          	beq	s4,a5,80002924 <print_pages+0x36c>
      pte_t pte = pagetable[i];
    800028d6:	000ab903          	ld	s2,0(s5)
      if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800028da:	00f97713          	andi	a4,s2,15
    800028de:	4785                	li	a5,1
    800028e0:	d6f701e3          	beq	a4,a5,80002642 <print_pages+0x8a>
      else if ((pte & PTE_V))
    800028e4:	00197793          	andi	a5,s2,1
    800028e8:	d3ed                	beqz	a5,800028ca <print_pages+0x312>
        int d = 0;
    800028ea:	4481                	li	s1,0
        for (; d < pagedepth; d++)
    800028ec:	e97052e3          	blez	s7,80002770 <print_pages+0x1b8>
          str[d] = '\t';
    800028f0:	47a5                	li	a5,9
    800028f2:	f4f40023          	sb	a5,-192(s0)
        for (; d < pagedepth; d++)
    800028f6:	4789                	li	a5,2
    800028f8:	84de                	mv	s1,s7
    800028fa:	e6fb9be3          	bne	s7,a5,80002770 <print_pages+0x1b8>
          str[d] = '\t';
    800028fe:	47a5                	li	a5,9
    80002900:	f4f400a3          	sb	a5,-191(s0)
        for (; d < pagedepth; d++)
    80002904:	b5b5                	j	80002770 <print_pages+0x1b8>
          safestrcpy(str + d, "   (kernel)", 12);
    80002906:	4631                	li	a2,12
    80002908:	00006597          	auipc	a1,0x6
    8000290c:	99858593          	addi	a1,a1,-1640 # 800082a0 <digits+0x260>
    80002910:	f4040793          	addi	a5,s0,-192
    80002914:	953e                	add	a0,a0,a5
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	506080e7          	jalr	1286(ra) # 80000e1c <safestrcpy>
          d += 11;
    8000291e:	0154851b          	addiw	a0,s1,21
    80002922:	b741                	j	800028a2 <print_pages+0x2ea>
      }
    }
  }
}
    80002924:	70f2                	ld	ra,312(sp)
    80002926:	7452                	ld	s0,304(sp)
    80002928:	74b2                	ld	s1,296(sp)
    8000292a:	7912                	ld	s2,288(sp)
    8000292c:	69f2                	ld	s3,280(sp)
    8000292e:	6a52                	ld	s4,272(sp)
    80002930:	6ab2                	ld	s5,264(sp)
    80002932:	6b12                	ld	s6,256(sp)
    80002934:	7bee                	ld	s7,248(sp)
    80002936:	7c4e                	ld	s8,240(sp)
    80002938:	7cae                	ld	s9,232(sp)
    8000293a:	7d0e                	ld	s10,224(sp)
    8000293c:	6dee                	ld	s11,216(sp)
    8000293e:	6131                	addi	sp,sp,320
    80002940:	8082                	ret
    80002942:	8082                	ret

0000000080002944 <pagewalk>:

int pagewalk(int pid)
{
    80002944:	7179                	addi	sp,sp,-48
    80002946:	f406                	sd	ra,40(sp)
    80002948:	f022                	sd	s0,32(sp)
    8000294a:	ec26                	sd	s1,24(sp)
    8000294c:	e84a                	sd	s2,16(sp)
    8000294e:	e44e                	sd	s3,8(sp)
    80002950:	1800                	addi	s0,sp,48
    80002952:	892a                	mv	s2,a0
  {
    printf("invalid page: %d\n", pid);
    return -1;
  }
  
  for (p = proc; p < &proc[NPROC]; p++)
    80002954:	0000e497          	auipc	s1,0xe
    80002958:	6ac48493          	addi	s1,s1,1708 # 80011000 <proc>
    8000295c:	00014997          	auipc	s3,0x14
    80002960:	0a498993          	addi	s3,s3,164 # 80016a00 <tickslock>
  if (pid == 0)
    80002964:	cd0d                	beqz	a0,8000299e <pagewalk+0x5a>
  {
    acquire(&p->lock);
    80002966:	8526                	mv	a0,s1
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	26e080e7          	jalr	622(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002970:	589c                	lw	a5,48(s1)
    80002972:	05278163          	beq	a5,s2,800029b4 <pagewalk+0x70>
      pagetable_t pagetable = p->pagetable;
      print_pages(pagetable, 0);
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002976:	8526                	mv	a0,s1
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	312080e7          	jalr	786(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002980:	16848493          	addi	s1,s1,360
    80002984:	ff3491e3          	bne	s1,s3,80002966 <pagewalk+0x22>
  }
  printf("invalid page: %d\n", pid);
    80002988:	85ca                	mv	a1,s2
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	92650513          	addi	a0,a0,-1754 # 800082b0 <digits+0x270>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf8080e7          	jalr	-1032(ra) # 8000058a <printf>
  return -1;
    8000299a:	557d                	li	a0,-1
    8000299c:	a081                	j	800029dc <pagewalk+0x98>
    printf("invalid page: %d\n", pid);
    8000299e:	4581                	li	a1,0
    800029a0:	00006517          	auipc	a0,0x6
    800029a4:	91050513          	addi	a0,a0,-1776 # 800082b0 <digits+0x270>
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	be2080e7          	jalr	-1054(ra) # 8000058a <printf>
    return -1;
    800029b0:	557d                	li	a0,-1
    800029b2:	a02d                	j	800029dc <pagewalk+0x98>
      printf("I cant Dollar your Mom\n");
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	91450513          	addi	a0,a0,-1772 # 800082c8 <digits+0x288>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bce080e7          	jalr	-1074(ra) # 8000058a <printf>
      print_pages(pagetable, 0);
    800029c4:	4581                	li	a1,0
    800029c6:	68a8                	ld	a0,80(s1)
    800029c8:	00000097          	auipc	ra,0x0
    800029cc:	bf0080e7          	jalr	-1040(ra) # 800025b8 <print_pages>
      release(&p->lock);
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	2b8080e7          	jalr	696(ra) # 80000c8a <release>
      return 0;
    800029da:	4501                	li	a0,0
  
}
    800029dc:	70a2                	ld	ra,40(sp)
    800029de:	7402                	ld	s0,32(sp)
    800029e0:	64e2                	ld	s1,24(sp)
    800029e2:	6942                	ld	s2,16(sp)
    800029e4:	69a2                	ld	s3,8(sp)
    800029e6:	6145                	addi	sp,sp,48
    800029e8:	8082                	ret

00000000800029ea <pages>:

int pages(int pid)
{
    800029ea:	1141                	addi	sp,sp,-16
    800029ec:	e406                	sd	ra,8(sp)
    800029ee:	e022                	sd	s0,0(sp)
    800029f0:	0800                	addi	s0,sp,16
  return pagewalk(pid);
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	f52080e7          	jalr	-174(ra) # 80002944 <pagewalk>
    800029fa:	60a2                	ld	ra,8(sp)
    800029fc:	6402                	ld	s0,0(sp)
    800029fe:	0141                	addi	sp,sp,16
    80002a00:	8082                	ret

0000000080002a02 <swtch>:
    80002a02:	00153023          	sd	ra,0(a0)
    80002a06:	00253423          	sd	sp,8(a0)
    80002a0a:	e900                	sd	s0,16(a0)
    80002a0c:	ed04                	sd	s1,24(a0)
    80002a0e:	03253023          	sd	s2,32(a0)
    80002a12:	03353423          	sd	s3,40(a0)
    80002a16:	03453823          	sd	s4,48(a0)
    80002a1a:	03553c23          	sd	s5,56(a0)
    80002a1e:	05653023          	sd	s6,64(a0)
    80002a22:	05753423          	sd	s7,72(a0)
    80002a26:	05853823          	sd	s8,80(a0)
    80002a2a:	05953c23          	sd	s9,88(a0)
    80002a2e:	07a53023          	sd	s10,96(a0)
    80002a32:	07b53423          	sd	s11,104(a0)
    80002a36:	0005b083          	ld	ra,0(a1)
    80002a3a:	0085b103          	ld	sp,8(a1)
    80002a3e:	6980                	ld	s0,16(a1)
    80002a40:	6d84                	ld	s1,24(a1)
    80002a42:	0205b903          	ld	s2,32(a1)
    80002a46:	0285b983          	ld	s3,40(a1)
    80002a4a:	0305ba03          	ld	s4,48(a1)
    80002a4e:	0385ba83          	ld	s5,56(a1)
    80002a52:	0405bb03          	ld	s6,64(a1)
    80002a56:	0485bb83          	ld	s7,72(a1)
    80002a5a:	0505bc03          	ld	s8,80(a1)
    80002a5e:	0585bc83          	ld	s9,88(a1)
    80002a62:	0605bd03          	ld	s10,96(a1)
    80002a66:	0685bd83          	ld	s11,104(a1)
    80002a6a:	8082                	ret

0000000080002a6c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a6c:	1141                	addi	sp,sp,-16
    80002a6e:	e406                	sd	ra,8(sp)
    80002a70:	e022                	sd	s0,0(sp)
    80002a72:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a74:	00006597          	auipc	a1,0x6
    80002a78:	8e458593          	addi	a1,a1,-1820 # 80008358 <digits+0x18>
    80002a7c:	00014517          	auipc	a0,0x14
    80002a80:	f8450513          	addi	a0,a0,-124 # 80016a00 <tickslock>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	0c2080e7          	jalr	194(ra) # 80000b46 <initlock>
}
    80002a8c:	60a2                	ld	ra,8(sp)
    80002a8e:	6402                	ld	s0,0(sp)
    80002a90:	0141                	addi	sp,sp,16
    80002a92:	8082                	ret

0000000080002a94 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a94:	1141                	addi	sp,sp,-16
    80002a96:	e422                	sd	s0,8(sp)
    80002a98:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a9a:	00003797          	auipc	a5,0x3
    80002a9e:	50678793          	addi	a5,a5,1286 # 80005fa0 <kernelvec>
    80002aa2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002aa6:	6422                	ld	s0,8(sp)
    80002aa8:	0141                	addi	sp,sp,16
    80002aaa:	8082                	ret

0000000080002aac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002aac:	1141                	addi	sp,sp,-16
    80002aae:	e406                	sd	ra,8(sp)
    80002ab0:	e022                	sd	s0,0(sp)
    80002ab2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	ef8080e7          	jalr	-264(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002abc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ac0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002ac6:	00004697          	auipc	a3,0x4
    80002aca:	53a68693          	addi	a3,a3,1338 # 80007000 <_trampoline>
    80002ace:	00004717          	auipc	a4,0x4
    80002ad2:	53270713          	addi	a4,a4,1330 # 80007000 <_trampoline>
    80002ad6:	8f15                	sub	a4,a4,a3
    80002ad8:	040007b7          	lui	a5,0x4000
    80002adc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002ade:	07b2                	slli	a5,a5,0xc
    80002ae0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002ae6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ae8:	18002673          	csrr	a2,satp
    80002aec:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aee:	6d30                	ld	a2,88(a0)
    80002af0:	6138                	ld	a4,64(a0)
    80002af2:	6585                	lui	a1,0x1
    80002af4:	972e                	add	a4,a4,a1
    80002af6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002af8:	6d38                	ld	a4,88(a0)
    80002afa:	00000617          	auipc	a2,0x0
    80002afe:	13060613          	addi	a2,a2,304 # 80002c2a <usertrap>
    80002b02:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b04:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b06:	8612                	mv	a2,tp
    80002b08:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b0e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b12:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b16:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b1a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b1c:	6f18                	ld	a4,24(a4)
    80002b1e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b22:	6928                	ld	a0,80(a0)
    80002b24:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b26:	00004717          	auipc	a4,0x4
    80002b2a:	57670713          	addi	a4,a4,1398 # 8000709c <userret>
    80002b2e:	8f15                	sub	a4,a4,a3
    80002b30:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002b32:	577d                	li	a4,-1
    80002b34:	177e                	slli	a4,a4,0x3f
    80002b36:	8d59                	or	a0,a0,a4
    80002b38:	9782                	jalr	a5
}
    80002b3a:	60a2                	ld	ra,8(sp)
    80002b3c:	6402                	ld	s0,0(sp)
    80002b3e:	0141                	addi	sp,sp,16
    80002b40:	8082                	ret

0000000080002b42 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	e426                	sd	s1,8(sp)
    80002b4a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b4c:	00014497          	auipc	s1,0x14
    80002b50:	eb448493          	addi	s1,s1,-332 # 80016a00 <tickslock>
    80002b54:	8526                	mv	a0,s1
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	080080e7          	jalr	128(ra) # 80000bd6 <acquire>
  ticks++;
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	e0250513          	addi	a0,a0,-510 # 80008960 <ticks>
    80002b66:	411c                	lw	a5,0(a0)
    80002b68:	2785                	addiw	a5,a5,1
    80002b6a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b6c:	fffff097          	auipc	ra,0xfffff
    80002b70:	54c080e7          	jalr	1356(ra) # 800020b8 <wakeup>
  release(&tickslock);
    80002b74:	8526                	mv	a0,s1
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	114080e7          	jalr	276(ra) # 80000c8a <release>
}
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret

0000000080002b88 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b88:	1101                	addi	sp,sp,-32
    80002b8a:	ec06                	sd	ra,24(sp)
    80002b8c:	e822                	sd	s0,16(sp)
    80002b8e:	e426                	sd	s1,8(sp)
    80002b90:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b92:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b96:	00074d63          	bltz	a4,80002bb0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b9a:	57fd                	li	a5,-1
    80002b9c:	17fe                	slli	a5,a5,0x3f
    80002b9e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ba0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ba2:	06f70363          	beq	a4,a5,80002c08 <devintr+0x80>
  }
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret
     (scause & 0xff) == 9){
    80002bb0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002bb4:	46a5                	li	a3,9
    80002bb6:	fed792e3          	bne	a5,a3,80002b9a <devintr+0x12>
    int irq = plic_claim();
    80002bba:	00003097          	auipc	ra,0x3
    80002bbe:	4ee080e7          	jalr	1262(ra) # 800060a8 <plic_claim>
    80002bc2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bc4:	47a9                	li	a5,10
    80002bc6:	02f50763          	beq	a0,a5,80002bf4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bca:	4785                	li	a5,1
    80002bcc:	02f50963          	beq	a0,a5,80002bfe <devintr+0x76>
    return 1;
    80002bd0:	4505                	li	a0,1
    } else if(irq){
    80002bd2:	d8f1                	beqz	s1,80002ba6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bd4:	85a6                	mv	a1,s1
    80002bd6:	00005517          	auipc	a0,0x5
    80002bda:	78a50513          	addi	a0,a0,1930 # 80008360 <digits+0x20>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ac080e7          	jalr	-1620(ra) # 8000058a <printf>
      plic_complete(irq);
    80002be6:	8526                	mv	a0,s1
    80002be8:	00003097          	auipc	ra,0x3
    80002bec:	4e4080e7          	jalr	1252(ra) # 800060cc <plic_complete>
    return 1;
    80002bf0:	4505                	li	a0,1
    80002bf2:	bf55                	j	80002ba6 <devintr+0x1e>
      uartintr();
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	da4080e7          	jalr	-604(ra) # 80000998 <uartintr>
    80002bfc:	b7ed                	j	80002be6 <devintr+0x5e>
      virtio_disk_intr();
    80002bfe:	00004097          	auipc	ra,0x4
    80002c02:	996080e7          	jalr	-1642(ra) # 80006594 <virtio_disk_intr>
    80002c06:	b7c5                	j	80002be6 <devintr+0x5e>
    if(cpuid() == 0){
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	d78080e7          	jalr	-648(ra) # 80001980 <cpuid>
    80002c10:	c901                	beqz	a0,80002c20 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c12:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c18:	14479073          	csrw	sip,a5
    return 2;
    80002c1c:	4509                	li	a0,2
    80002c1e:	b761                	j	80002ba6 <devintr+0x1e>
      clockintr();
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	f22080e7          	jalr	-222(ra) # 80002b42 <clockintr>
    80002c28:	b7ed                	j	80002c12 <devintr+0x8a>

0000000080002c2a <usertrap>:
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	e04a                	sd	s2,0(sp)
    80002c34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c3a:	1007f793          	andi	a5,a5,256
    80002c3e:	e3b1                	bnez	a5,80002c82 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c40:	00003797          	auipc	a5,0x3
    80002c44:	36078793          	addi	a5,a5,864 # 80005fa0 <kernelvec>
    80002c48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d60080e7          	jalr	-672(ra) # 800019ac <myproc>
    80002c54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c56:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c58:	14102773          	csrr	a4,sepc
    80002c5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c62:	47a1                	li	a5,8
    80002c64:	02f70763          	beq	a4,a5,80002c92 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	f20080e7          	jalr	-224(ra) # 80002b88 <devintr>
    80002c70:	892a                	mv	s2,a0
    80002c72:	c151                	beqz	a0,80002cf6 <usertrap+0xcc>
  if(killed(p))
    80002c74:	8526                	mv	a0,s1
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	686080e7          	jalr	1670(ra) # 800022fc <killed>
    80002c7e:	c929                	beqz	a0,80002cd0 <usertrap+0xa6>
    80002c80:	a099                	j	80002cc6 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002c82:	00005517          	auipc	a0,0x5
    80002c86:	6fe50513          	addi	a0,a0,1790 # 80008380 <digits+0x40>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	8b6080e7          	jalr	-1866(ra) # 80000540 <panic>
    if(killed(p))
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	66a080e7          	jalr	1642(ra) # 800022fc <killed>
    80002c9a:	e921                	bnez	a0,80002cea <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002c9c:	6cb8                	ld	a4,88(s1)
    80002c9e:	6f1c                	ld	a5,24(a4)
    80002ca0:	0791                	addi	a5,a5,4
    80002ca2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ca8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cac:	10079073          	csrw	sstatus,a5
    syscall();
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	2d4080e7          	jalr	724(ra) # 80002f84 <syscall>
  if(killed(p))
    80002cb8:	8526                	mv	a0,s1
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	642080e7          	jalr	1602(ra) # 800022fc <killed>
    80002cc2:	c911                	beqz	a0,80002cd6 <usertrap+0xac>
    80002cc4:	4901                	li	s2,0
    exit(-1);
    80002cc6:	557d                	li	a0,-1
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	4c0080e7          	jalr	1216(ra) # 80002188 <exit>
  if(which_dev == 2)
    80002cd0:	4789                	li	a5,2
    80002cd2:	04f90f63          	beq	s2,a5,80002d30 <usertrap+0x106>
  usertrapret();
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	dd6080e7          	jalr	-554(ra) # 80002aac <usertrapret>
}
    80002cde:	60e2                	ld	ra,24(sp)
    80002ce0:	6442                	ld	s0,16(sp)
    80002ce2:	64a2                	ld	s1,8(sp)
    80002ce4:	6902                	ld	s2,0(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret
      exit(-1);
    80002cea:	557d                	li	a0,-1
    80002cec:	fffff097          	auipc	ra,0xfffff
    80002cf0:	49c080e7          	jalr	1180(ra) # 80002188 <exit>
    80002cf4:	b765                	j	80002c9c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cf6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cfa:	5890                	lw	a2,48(s1)
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	6a450513          	addi	a0,a0,1700 # 800083a0 <digits+0x60>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	886080e7          	jalr	-1914(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	6bc50513          	addi	a0,a0,1724 # 800083d0 <digits+0x90>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	86e080e7          	jalr	-1938(ra) # 8000058a <printf>
    setkilled(p);
    80002d24:	8526                	mv	a0,s1
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	5aa080e7          	jalr	1450(ra) # 800022d0 <setkilled>
    80002d2e:	b769                	j	80002cb8 <usertrap+0x8e>
    yield();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	2e8080e7          	jalr	744(ra) # 80002018 <yield>
    80002d38:	bf79                	j	80002cd6 <usertrap+0xac>

0000000080002d3a <kerneltrap>:
{
    80002d3a:	7179                	addi	sp,sp,-48
    80002d3c:	f406                	sd	ra,40(sp)
    80002d3e:	f022                	sd	s0,32(sp)
    80002d40:	ec26                	sd	s1,24(sp)
    80002d42:	e84a                	sd	s2,16(sp)
    80002d44:	e44e                	sd	s3,8(sp)
    80002d46:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d48:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d50:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d54:	1004f793          	andi	a5,s1,256
    80002d58:	cb85                	beqz	a5,80002d88 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d5e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d60:	ef85                	bnez	a5,80002d98 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	e26080e7          	jalr	-474(ra) # 80002b88 <devintr>
    80002d6a:	cd1d                	beqz	a0,80002da8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d6c:	4789                	li	a5,2
    80002d6e:	06f50a63          	beq	a0,a5,80002de2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d72:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d76:	10049073          	csrw	sstatus,s1
}
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6942                	ld	s2,16(sp)
    80002d82:	69a2                	ld	s3,8(sp)
    80002d84:	6145                	addi	sp,sp,48
    80002d86:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d88:	00005517          	auipc	a0,0x5
    80002d8c:	66850513          	addi	a0,a0,1640 # 800083f0 <digits+0xb0>
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7b0080e7          	jalr	1968(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002d98:	00005517          	auipc	a0,0x5
    80002d9c:	68050513          	addi	a0,a0,1664 # 80008418 <digits+0xd8>
    80002da0:	ffffd097          	auipc	ra,0xffffd
    80002da4:	7a0080e7          	jalr	1952(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002da8:	85ce                	mv	a1,s3
    80002daa:	00005517          	auipc	a0,0x5
    80002dae:	68e50513          	addi	a0,a0,1678 # 80008438 <digits+0xf8>
    80002db2:	ffffd097          	auipc	ra,0xffffd
    80002db6:	7d8080e7          	jalr	2008(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dbe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dc2:	00005517          	auipc	a0,0x5
    80002dc6:	68650513          	addi	a0,a0,1670 # 80008448 <digits+0x108>
    80002dca:	ffffd097          	auipc	ra,0xffffd
    80002dce:	7c0080e7          	jalr	1984(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	68e50513          	addi	a0,a0,1678 # 80008460 <digits+0x120>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	766080e7          	jalr	1894(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	bca080e7          	jalr	-1078(ra) # 800019ac <myproc>
    80002dea:	d541                	beqz	a0,80002d72 <kerneltrap+0x38>
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	bc0080e7          	jalr	-1088(ra) # 800019ac <myproc>
    80002df4:	4d18                	lw	a4,24(a0)
    80002df6:	4791                	li	a5,4
    80002df8:	f6f71de3          	bne	a4,a5,80002d72 <kerneltrap+0x38>
    yield();
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	21c080e7          	jalr	540(ra) # 80002018 <yield>
    80002e04:	b7bd                	j	80002d72 <kerneltrap+0x38>

0000000080002e06 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	b9a080e7          	jalr	-1126(ra) # 800019ac <myproc>
  switch (n) {
    80002e1a:	4795                	li	a5,5
    80002e1c:	0497e163          	bltu	a5,s1,80002e5e <argraw+0x58>
    80002e20:	048a                	slli	s1,s1,0x2
    80002e22:	00005717          	auipc	a4,0x5
    80002e26:	67670713          	addi	a4,a4,1654 # 80008498 <digits+0x158>
    80002e2a:	94ba                	add	s1,s1,a4
    80002e2c:	409c                	lw	a5,0(s1)
    80002e2e:	97ba                	add	a5,a5,a4
    80002e30:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e32:	6d3c                	ld	a5,88(a0)
    80002e34:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e36:	60e2                	ld	ra,24(sp)
    80002e38:	6442                	ld	s0,16(sp)
    80002e3a:	64a2                	ld	s1,8(sp)
    80002e3c:	6105                	addi	sp,sp,32
    80002e3e:	8082                	ret
    return p->trapframe->a1;
    80002e40:	6d3c                	ld	a5,88(a0)
    80002e42:	7fa8                	ld	a0,120(a5)
    80002e44:	bfcd                	j	80002e36 <argraw+0x30>
    return p->trapframe->a2;
    80002e46:	6d3c                	ld	a5,88(a0)
    80002e48:	63c8                	ld	a0,128(a5)
    80002e4a:	b7f5                	j	80002e36 <argraw+0x30>
    return p->trapframe->a3;
    80002e4c:	6d3c                	ld	a5,88(a0)
    80002e4e:	67c8                	ld	a0,136(a5)
    80002e50:	b7dd                	j	80002e36 <argraw+0x30>
    return p->trapframe->a4;
    80002e52:	6d3c                	ld	a5,88(a0)
    80002e54:	6bc8                	ld	a0,144(a5)
    80002e56:	b7c5                	j	80002e36 <argraw+0x30>
    return p->trapframe->a5;
    80002e58:	6d3c                	ld	a5,88(a0)
    80002e5a:	6fc8                	ld	a0,152(a5)
    80002e5c:	bfe9                	j	80002e36 <argraw+0x30>
  panic("argraw");
    80002e5e:	00005517          	auipc	a0,0x5
    80002e62:	61250513          	addi	a0,a0,1554 # 80008470 <digits+0x130>
    80002e66:	ffffd097          	auipc	ra,0xffffd
    80002e6a:	6da080e7          	jalr	1754(ra) # 80000540 <panic>

0000000080002e6e <fetchaddr>:
{
    80002e6e:	1101                	addi	sp,sp,-32
    80002e70:	ec06                	sd	ra,24(sp)
    80002e72:	e822                	sd	s0,16(sp)
    80002e74:	e426                	sd	s1,8(sp)
    80002e76:	e04a                	sd	s2,0(sp)
    80002e78:	1000                	addi	s0,sp,32
    80002e7a:	84aa                	mv	s1,a0
    80002e7c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	b2e080e7          	jalr	-1234(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002e86:	653c                	ld	a5,72(a0)
    80002e88:	02f4f863          	bgeu	s1,a5,80002eb8 <fetchaddr+0x4a>
    80002e8c:	00848713          	addi	a4,s1,8
    80002e90:	02e7e663          	bltu	a5,a4,80002ebc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e94:	46a1                	li	a3,8
    80002e96:	8626                	mv	a2,s1
    80002e98:	85ca                	mv	a1,s2
    80002e9a:	6928                	ld	a0,80(a0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	85c080e7          	jalr	-1956(ra) # 800016f8 <copyin>
    80002ea4:	00a03533          	snez	a0,a0
    80002ea8:	40a00533          	neg	a0,a0
}
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6902                	ld	s2,0(sp)
    80002eb4:	6105                	addi	sp,sp,32
    80002eb6:	8082                	ret
    return -1;
    80002eb8:	557d                	li	a0,-1
    80002eba:	bfcd                	j	80002eac <fetchaddr+0x3e>
    80002ebc:	557d                	li	a0,-1
    80002ebe:	b7fd                	j	80002eac <fetchaddr+0x3e>

0000000080002ec0 <fetchstr>:
{
    80002ec0:	7179                	addi	sp,sp,-48
    80002ec2:	f406                	sd	ra,40(sp)
    80002ec4:	f022                	sd	s0,32(sp)
    80002ec6:	ec26                	sd	s1,24(sp)
    80002ec8:	e84a                	sd	s2,16(sp)
    80002eca:	e44e                	sd	s3,8(sp)
    80002ecc:	1800                	addi	s0,sp,48
    80002ece:	892a                	mv	s2,a0
    80002ed0:	84ae                	mv	s1,a1
    80002ed2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	ad8080e7          	jalr	-1320(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002edc:	86ce                	mv	a3,s3
    80002ede:	864a                	mv	a2,s2
    80002ee0:	85a6                	mv	a1,s1
    80002ee2:	6928                	ld	a0,80(a0)
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	8a2080e7          	jalr	-1886(ra) # 80001786 <copyinstr>
    80002eec:	00054e63          	bltz	a0,80002f08 <fetchstr+0x48>
  return strlen(buf);
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	f5c080e7          	jalr	-164(ra) # 80000e4e <strlen>
}
    80002efa:	70a2                	ld	ra,40(sp)
    80002efc:	7402                	ld	s0,32(sp)
    80002efe:	64e2                	ld	s1,24(sp)
    80002f00:	6942                	ld	s2,16(sp)
    80002f02:	69a2                	ld	s3,8(sp)
    80002f04:	6145                	addi	sp,sp,48
    80002f06:	8082                	ret
    return -1;
    80002f08:	557d                	li	a0,-1
    80002f0a:	bfc5                	j	80002efa <fetchstr+0x3a>

0000000080002f0c <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	addi	s0,sp,32
    80002f16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	eee080e7          	jalr	-274(ra) # 80002e06 <argraw>
    80002f20:	c088                	sw	a0,0(s1)
}
    80002f22:	60e2                	ld	ra,24(sp)
    80002f24:	6442                	ld	s0,16(sp)
    80002f26:	64a2                	ld	s1,8(sp)
    80002f28:	6105                	addi	sp,sp,32
    80002f2a:	8082                	ret

0000000080002f2c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002f2c:	1101                	addi	sp,sp,-32
    80002f2e:	ec06                	sd	ra,24(sp)
    80002f30:	e822                	sd	s0,16(sp)
    80002f32:	e426                	sd	s1,8(sp)
    80002f34:	1000                	addi	s0,sp,32
    80002f36:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f38:	00000097          	auipc	ra,0x0
    80002f3c:	ece080e7          	jalr	-306(ra) # 80002e06 <argraw>
    80002f40:	e088                	sd	a0,0(s1)
}
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	64a2                	ld	s1,8(sp)
    80002f48:	6105                	addi	sp,sp,32
    80002f4a:	8082                	ret

0000000080002f4c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f4c:	7179                	addi	sp,sp,-48
    80002f4e:	f406                	sd	ra,40(sp)
    80002f50:	f022                	sd	s0,32(sp)
    80002f52:	ec26                	sd	s1,24(sp)
    80002f54:	e84a                	sd	s2,16(sp)
    80002f56:	1800                	addi	s0,sp,48
    80002f58:	84ae                	mv	s1,a1
    80002f5a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002f5c:	fd840593          	addi	a1,s0,-40
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	fcc080e7          	jalr	-52(ra) # 80002f2c <argaddr>
  return fetchstr(addr, buf, max);
    80002f68:	864a                	mv	a2,s2
    80002f6a:	85a6                	mv	a1,s1
    80002f6c:	fd843503          	ld	a0,-40(s0)
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	f50080e7          	jalr	-176(ra) # 80002ec0 <fetchstr>
}
    80002f78:	70a2                	ld	ra,40(sp)
    80002f7a:	7402                	ld	s0,32(sp)
    80002f7c:	64e2                	ld	s1,24(sp)
    80002f7e:	6942                	ld	s2,16(sp)
    80002f80:	6145                	addi	sp,sp,48
    80002f82:	8082                	ret

0000000080002f84 <syscall>:
[SYS_joke]    sys_joke,
};

void
syscall(void)
{
    80002f84:	1101                	addi	sp,sp,-32
    80002f86:	ec06                	sd	ra,24(sp)
    80002f88:	e822                	sd	s0,16(sp)
    80002f8a:	e426                	sd	s1,8(sp)
    80002f8c:	e04a                	sd	s2,0(sp)
    80002f8e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	a1c080e7          	jalr	-1508(ra) # 800019ac <myproc>
    80002f98:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f9a:	05853903          	ld	s2,88(a0)
    80002f9e:	0a893783          	ld	a5,168(s2)
    80002fa2:	0007869b          	sext.w	a3,a5
  //printf("total syscalls: %d\n", NELEM(syscalls));
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fa6:	37fd                	addiw	a5,a5,-1
    80002fa8:	4759                	li	a4,22
    80002faa:	00f76f63          	bltu	a4,a5,80002fc8 <syscall+0x44>
    80002fae:	00369713          	slli	a4,a3,0x3
    80002fb2:	00005797          	auipc	a5,0x5
    80002fb6:	4fe78793          	addi	a5,a5,1278 # 800084b0 <syscalls>
    80002fba:	97ba                	add	a5,a5,a4
    80002fbc:	639c                	ld	a5,0(a5)
    80002fbe:	c789                	beqz	a5,80002fc8 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002fc0:	9782                	jalr	a5
    80002fc2:	06a93823          	sd	a0,112(s2)
    80002fc6:	a839                	j	80002fe4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fc8:	15848613          	addi	a2,s1,344
    80002fcc:	588c                	lw	a1,48(s1)
    80002fce:	00005517          	auipc	a0,0x5
    80002fd2:	4aa50513          	addi	a0,a0,1194 # 80008478 <digits+0x138>
    80002fd6:	ffffd097          	auipc	ra,0xffffd
    80002fda:	5b4080e7          	jalr	1460(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fde:	6cbc                	ld	a5,88(s1)
    80002fe0:	577d                	li	a4,-1
    80002fe2:	fbb8                	sd	a4,112(a5)
  }
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6902                	ld	s2,0(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret

0000000080002ff0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ff8:	fec40593          	addi	a1,s0,-20
    80002ffc:	4501                	li	a0,0
    80002ffe:	00000097          	auipc	ra,0x0
    80003002:	f0e080e7          	jalr	-242(ra) # 80002f0c <argint>
  exit(n);
    80003006:	fec42503          	lw	a0,-20(s0)
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	17e080e7          	jalr	382(ra) # 80002188 <exit>
  return 0;  // not reached
}
    80003012:	4501                	li	a0,0
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret

000000008000301c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000301c:	1141                	addi	sp,sp,-16
    8000301e:	e406                	sd	ra,8(sp)
    80003020:	e022                	sd	s0,0(sp)
    80003022:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	988080e7          	jalr	-1656(ra) # 800019ac <myproc>
}
    8000302c:	5908                	lw	a0,48(a0)
    8000302e:	60a2                	ld	ra,8(sp)
    80003030:	6402                	ld	s0,0(sp)
    80003032:	0141                	addi	sp,sp,16
    80003034:	8082                	ret

0000000080003036 <sys_fork>:

uint64
sys_fork(void)
{
    80003036:	1141                	addi	sp,sp,-16
    80003038:	e406                	sd	ra,8(sp)
    8000303a:	e022                	sd	s0,0(sp)
    8000303c:	0800                	addi	s0,sp,16
  return fork();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	d24080e7          	jalr	-732(ra) # 80001d62 <fork>
}
    80003046:	60a2                	ld	ra,8(sp)
    80003048:	6402                	ld	s0,0(sp)
    8000304a:	0141                	addi	sp,sp,16
    8000304c:	8082                	ret

000000008000304e <sys_wait>:

uint64
sys_wait(void)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003056:	fe840593          	addi	a1,s0,-24
    8000305a:	4501                	li	a0,0
    8000305c:	00000097          	auipc	ra,0x0
    80003060:	ed0080e7          	jalr	-304(ra) # 80002f2c <argaddr>
  return wait(p);
    80003064:	fe843503          	ld	a0,-24(s0)
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	2c6080e7          	jalr	710(ra) # 8000232e <wait>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	6105                	addi	sp,sp,32
    80003076:	8082                	ret

0000000080003078 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003078:	7179                	addi	sp,sp,-48
    8000307a:	f406                	sd	ra,40(sp)
    8000307c:	f022                	sd	s0,32(sp)
    8000307e:	ec26                	sd	s1,24(sp)
    80003080:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003082:	fdc40593          	addi	a1,s0,-36
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	e84080e7          	jalr	-380(ra) # 80002f0c <argint>
  addr = myproc()->sz;
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	91c080e7          	jalr	-1764(ra) # 800019ac <myproc>
    80003098:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    8000309a:	fdc42503          	lw	a0,-36(s0)
    8000309e:	fffff097          	auipc	ra,0xfffff
    800030a2:	c68080e7          	jalr	-920(ra) # 80001d06 <growproc>
    800030a6:	00054863          	bltz	a0,800030b6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030aa:	8526                	mv	a0,s1
    800030ac:	70a2                	ld	ra,40(sp)
    800030ae:	7402                	ld	s0,32(sp)
    800030b0:	64e2                	ld	s1,24(sp)
    800030b2:	6145                	addi	sp,sp,48
    800030b4:	8082                	ret
    return -1;
    800030b6:	54fd                	li	s1,-1
    800030b8:	bfcd                	j	800030aa <sys_sbrk+0x32>

00000000800030ba <sys_sleep>:

uint64
sys_sleep(void)
{
    800030ba:	7139                	addi	sp,sp,-64
    800030bc:	fc06                	sd	ra,56(sp)
    800030be:	f822                	sd	s0,48(sp)
    800030c0:	f426                	sd	s1,40(sp)
    800030c2:	f04a                	sd	s2,32(sp)
    800030c4:	ec4e                	sd	s3,24(sp)
    800030c6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030c8:	fcc40593          	addi	a1,s0,-52
    800030cc:	4501                	li	a0,0
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	e3e080e7          	jalr	-450(ra) # 80002f0c <argint>
  acquire(&tickslock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	92a50513          	addi	a0,a0,-1750 # 80016a00 <tickslock>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	af8080e7          	jalr	-1288(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800030e6:	00006917          	auipc	s2,0x6
    800030ea:	87a92903          	lw	s2,-1926(s2) # 80008960 <ticks>
  while(ticks - ticks0 < n){
    800030ee:	fcc42783          	lw	a5,-52(s0)
    800030f2:	cf9d                	beqz	a5,80003130 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030f4:	00014997          	auipc	s3,0x14
    800030f8:	90c98993          	addi	s3,s3,-1780 # 80016a00 <tickslock>
    800030fc:	00006497          	auipc	s1,0x6
    80003100:	86448493          	addi	s1,s1,-1948 # 80008960 <ticks>
    if(killed(myproc())){
    80003104:	fffff097          	auipc	ra,0xfffff
    80003108:	8a8080e7          	jalr	-1880(ra) # 800019ac <myproc>
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	1f0080e7          	jalr	496(ra) # 800022fc <killed>
    80003114:	ed15                	bnez	a0,80003150 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003116:	85ce                	mv	a1,s3
    80003118:	8526                	mv	a0,s1
    8000311a:	fffff097          	auipc	ra,0xfffff
    8000311e:	f3a080e7          	jalr	-198(ra) # 80002054 <sleep>
  while(ticks - ticks0 < n){
    80003122:	409c                	lw	a5,0(s1)
    80003124:	412787bb          	subw	a5,a5,s2
    80003128:	fcc42703          	lw	a4,-52(s0)
    8000312c:	fce7ece3          	bltu	a5,a4,80003104 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003130:	00014517          	auipc	a0,0x14
    80003134:	8d050513          	addi	a0,a0,-1840 # 80016a00 <tickslock>
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
  return 0;
    80003140:	4501                	li	a0,0
}
    80003142:	70e2                	ld	ra,56(sp)
    80003144:	7442                	ld	s0,48(sp)
    80003146:	74a2                	ld	s1,40(sp)
    80003148:	7902                	ld	s2,32(sp)
    8000314a:	69e2                	ld	s3,24(sp)
    8000314c:	6121                	addi	sp,sp,64
    8000314e:	8082                	ret
      release(&tickslock);
    80003150:	00014517          	auipc	a0,0x14
    80003154:	8b050513          	addi	a0,a0,-1872 # 80016a00 <tickslock>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b32080e7          	jalr	-1230(ra) # 80000c8a <release>
      return -1;
    80003160:	557d                	li	a0,-1
    80003162:	b7c5                	j	80003142 <sys_sleep+0x88>

0000000080003164 <sys_kill>:

uint64
sys_kill(void)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000316c:	fec40593          	addi	a1,s0,-20
    80003170:	4501                	li	a0,0
    80003172:	00000097          	auipc	ra,0x0
    80003176:	d9a080e7          	jalr	-614(ra) # 80002f0c <argint>
  return kill(pid);
    8000317a:	fec42503          	lw	a0,-20(s0)
    8000317e:	fffff097          	auipc	ra,0xfffff
    80003182:	0e0080e7          	jalr	224(ra) # 8000225e <kill>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	6105                	addi	sp,sp,32
    8000318c:	8082                	ret

000000008000318e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000318e:	1101                	addi	sp,sp,-32
    80003190:	ec06                	sd	ra,24(sp)
    80003192:	e822                	sd	s0,16(sp)
    80003194:	e426                	sd	s1,8(sp)
    80003196:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003198:	00014517          	auipc	a0,0x14
    8000319c:	86850513          	addi	a0,a0,-1944 # 80016a00 <tickslock>
    800031a0:	ffffe097          	auipc	ra,0xffffe
    800031a4:	a36080e7          	jalr	-1482(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800031a8:	00005497          	auipc	s1,0x5
    800031ac:	7b84a483          	lw	s1,1976(s1) # 80008960 <ticks>
  release(&tickslock);
    800031b0:	00014517          	auipc	a0,0x14
    800031b4:	85050513          	addi	a0,a0,-1968 # 80016a00 <tickslock>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	ad2080e7          	jalr	-1326(ra) # 80000c8a <release>
  return xticks;
}
    800031c0:	02049513          	slli	a0,s1,0x20
    800031c4:	9101                	srli	a0,a0,0x20
    800031c6:	60e2                	ld	ra,24(sp)
    800031c8:	6442                	ld	s0,16(sp)
    800031ca:	64a2                	ld	s1,8(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret

00000000800031d0 <sys_pages>:

uint64
sys_pages(void)
{
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	1000                	addi	s0,sp,32
  printf("Fortnite\n");
    800031d8:	00005517          	auipc	a0,0x5
    800031dc:	39850513          	addi	a0,a0,920 # 80008570 <syscalls+0xc0>
    800031e0:	ffffd097          	auipc	ra,0xffffd
    800031e4:	3aa080e7          	jalr	938(ra) # 8000058a <printf>
  int pid;

  argint(0, &pid);
    800031e8:	fec40593          	addi	a1,s0,-20
    800031ec:	4501                	li	a0,0
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	d1e080e7          	jalr	-738(ra) # 80002f0c <argint>
  return pages(pid);
    800031f6:	fec42503          	lw	a0,-20(s0)
    800031fa:	fffff097          	auipc	ra,0xfffff
    800031fe:	7f0080e7          	jalr	2032(ra) # 800029ea <pages>
}
    80003202:	60e2                	ld	ra,24(sp)
    80003204:	6442                	ld	s0,16(sp)
    80003206:	6105                	addi	sp,sp,32
    80003208:	8082                	ret

000000008000320a <sys_joke>:

uint64
sys_joke(void)
{
    8000320a:	1141                	addi	sp,sp,-16
    8000320c:	e422                	sd	s0,8(sp)
    8000320e:	0800                	addi	s0,sp,16
  return 1975;
    80003210:	7b700513          	li	a0,1975
    80003214:	6422                	ld	s0,8(sp)
    80003216:	0141                	addi	sp,sp,16
    80003218:	8082                	ret

000000008000321a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000321a:	7179                	addi	sp,sp,-48
    8000321c:	f406                	sd	ra,40(sp)
    8000321e:	f022                	sd	s0,32(sp)
    80003220:	ec26                	sd	s1,24(sp)
    80003222:	e84a                	sd	s2,16(sp)
    80003224:	e44e                	sd	s3,8(sp)
    80003226:	e052                	sd	s4,0(sp)
    80003228:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000322a:	00005597          	auipc	a1,0x5
    8000322e:	35658593          	addi	a1,a1,854 # 80008580 <syscalls+0xd0>
    80003232:	00013517          	auipc	a0,0x13
    80003236:	7e650513          	addi	a0,a0,2022 # 80016a18 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	90c080e7          	jalr	-1780(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003242:	0001b797          	auipc	a5,0x1b
    80003246:	7d678793          	addi	a5,a5,2006 # 8001ea18 <bcache+0x8000>
    8000324a:	0001c717          	auipc	a4,0x1c
    8000324e:	a3670713          	addi	a4,a4,-1482 # 8001ec80 <bcache+0x8268>
    80003252:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003256:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000325a:	00013497          	auipc	s1,0x13
    8000325e:	7d648493          	addi	s1,s1,2006 # 80016a30 <bcache+0x18>
    b->next = bcache.head.next;
    80003262:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003264:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003266:	00005a17          	auipc	s4,0x5
    8000326a:	322a0a13          	addi	s4,s4,802 # 80008588 <syscalls+0xd8>
    b->next = bcache.head.next;
    8000326e:	2b893783          	ld	a5,696(s2)
    80003272:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003274:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003278:	85d2                	mv	a1,s4
    8000327a:	01048513          	addi	a0,s1,16
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	4c8080e7          	jalr	1224(ra) # 80004746 <initsleeplock>
    bcache.head.next->prev = b;
    80003286:	2b893783          	ld	a5,696(s2)
    8000328a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000328c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003290:	45848493          	addi	s1,s1,1112
    80003294:	fd349de3          	bne	s1,s3,8000326e <binit+0x54>
  }
}
    80003298:	70a2                	ld	ra,40(sp)
    8000329a:	7402                	ld	s0,32(sp)
    8000329c:	64e2                	ld	s1,24(sp)
    8000329e:	6942                	ld	s2,16(sp)
    800032a0:	69a2                	ld	s3,8(sp)
    800032a2:	6a02                	ld	s4,0(sp)
    800032a4:	6145                	addi	sp,sp,48
    800032a6:	8082                	ret

00000000800032a8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032a8:	7179                	addi	sp,sp,-48
    800032aa:	f406                	sd	ra,40(sp)
    800032ac:	f022                	sd	s0,32(sp)
    800032ae:	ec26                	sd	s1,24(sp)
    800032b0:	e84a                	sd	s2,16(sp)
    800032b2:	e44e                	sd	s3,8(sp)
    800032b4:	1800                	addi	s0,sp,48
    800032b6:	892a                	mv	s2,a0
    800032b8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032ba:	00013517          	auipc	a0,0x13
    800032be:	75e50513          	addi	a0,a0,1886 # 80016a18 <bcache>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	914080e7          	jalr	-1772(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032ca:	0001c497          	auipc	s1,0x1c
    800032ce:	a064b483          	ld	s1,-1530(s1) # 8001ecd0 <bcache+0x82b8>
    800032d2:	0001c797          	auipc	a5,0x1c
    800032d6:	9ae78793          	addi	a5,a5,-1618 # 8001ec80 <bcache+0x8268>
    800032da:	02f48f63          	beq	s1,a5,80003318 <bread+0x70>
    800032de:	873e                	mv	a4,a5
    800032e0:	a021                	j	800032e8 <bread+0x40>
    800032e2:	68a4                	ld	s1,80(s1)
    800032e4:	02e48a63          	beq	s1,a4,80003318 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032e8:	449c                	lw	a5,8(s1)
    800032ea:	ff279ce3          	bne	a5,s2,800032e2 <bread+0x3a>
    800032ee:	44dc                	lw	a5,12(s1)
    800032f0:	ff3799e3          	bne	a5,s3,800032e2 <bread+0x3a>
      b->refcnt++;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	2785                	addiw	a5,a5,1
    800032f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fa:	00013517          	auipc	a0,0x13
    800032fe:	71e50513          	addi	a0,a0,1822 # 80016a18 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000330a:	01048513          	addi	a0,s1,16
    8000330e:	00001097          	auipc	ra,0x1
    80003312:	472080e7          	jalr	1138(ra) # 80004780 <acquiresleep>
      return b;
    80003316:	a8b9                	j	80003374 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003318:	0001c497          	auipc	s1,0x1c
    8000331c:	9b04b483          	ld	s1,-1616(s1) # 8001ecc8 <bcache+0x82b0>
    80003320:	0001c797          	auipc	a5,0x1c
    80003324:	96078793          	addi	a5,a5,-1696 # 8001ec80 <bcache+0x8268>
    80003328:	00f48863          	beq	s1,a5,80003338 <bread+0x90>
    8000332c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000332e:	40bc                	lw	a5,64(s1)
    80003330:	cf81                	beqz	a5,80003348 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003332:	64a4                	ld	s1,72(s1)
    80003334:	fee49de3          	bne	s1,a4,8000332e <bread+0x86>
  panic("bget: no buffers");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	25850513          	addi	a0,a0,600 # 80008590 <syscalls+0xe0>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	200080e7          	jalr	512(ra) # 80000540 <panic>
      b->dev = dev;
    80003348:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000334c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003350:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003354:	4785                	li	a5,1
    80003356:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003358:	00013517          	auipc	a0,0x13
    8000335c:	6c050513          	addi	a0,a0,1728 # 80016a18 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	92a080e7          	jalr	-1750(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003368:	01048513          	addi	a0,s1,16
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	414080e7          	jalr	1044(ra) # 80004780 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003374:	409c                	lw	a5,0(s1)
    80003376:	cb89                	beqz	a5,80003388 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003378:	8526                	mv	a0,s1
    8000337a:	70a2                	ld	ra,40(sp)
    8000337c:	7402                	ld	s0,32(sp)
    8000337e:	64e2                	ld	s1,24(sp)
    80003380:	6942                	ld	s2,16(sp)
    80003382:	69a2                	ld	s3,8(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret
    virtio_disk_rw(b, 0);
    80003388:	4581                	li	a1,0
    8000338a:	8526                	mv	a0,s1
    8000338c:	00003097          	auipc	ra,0x3
    80003390:	fd6080e7          	jalr	-42(ra) # 80006362 <virtio_disk_rw>
    b->valid = 1;
    80003394:	4785                	li	a5,1
    80003396:	c09c                	sw	a5,0(s1)
  return b;
    80003398:	b7c5                	j	80003378 <bread+0xd0>

000000008000339a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	e426                	sd	s1,8(sp)
    800033a2:	1000                	addi	s0,sp,32
    800033a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033a6:	0541                	addi	a0,a0,16
    800033a8:	00001097          	auipc	ra,0x1
    800033ac:	472080e7          	jalr	1138(ra) # 8000481a <holdingsleep>
    800033b0:	cd01                	beqz	a0,800033c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033b2:	4585                	li	a1,1
    800033b4:	8526                	mv	a0,s1
    800033b6:	00003097          	auipc	ra,0x3
    800033ba:	fac080e7          	jalr	-84(ra) # 80006362 <virtio_disk_rw>
}
    800033be:	60e2                	ld	ra,24(sp)
    800033c0:	6442                	ld	s0,16(sp)
    800033c2:	64a2                	ld	s1,8(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret
    panic("bwrite");
    800033c8:	00005517          	auipc	a0,0x5
    800033cc:	1e050513          	addi	a0,a0,480 # 800085a8 <syscalls+0xf8>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	170080e7          	jalr	368(ra) # 80000540 <panic>

00000000800033d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	e04a                	sd	s2,0(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e6:	01050913          	addi	s2,a0,16
    800033ea:	854a                	mv	a0,s2
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	42e080e7          	jalr	1070(ra) # 8000481a <holdingsleep>
    800033f4:	c92d                	beqz	a0,80003466 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	3de080e7          	jalr	990(ra) # 800047d6 <releasesleep>

  acquire(&bcache.lock);
    80003400:	00013517          	auipc	a0,0x13
    80003404:	61850513          	addi	a0,a0,1560 # 80016a18 <bcache>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	7ce080e7          	jalr	1998(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	37fd                	addiw	a5,a5,-1
    80003414:	0007871b          	sext.w	a4,a5
    80003418:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000341a:	eb05                	bnez	a4,8000344a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000341c:	68bc                	ld	a5,80(s1)
    8000341e:	64b8                	ld	a4,72(s1)
    80003420:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003422:	64bc                	ld	a5,72(s1)
    80003424:	68b8                	ld	a4,80(s1)
    80003426:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003428:	0001b797          	auipc	a5,0x1b
    8000342c:	5f078793          	addi	a5,a5,1520 # 8001ea18 <bcache+0x8000>
    80003430:	2b87b703          	ld	a4,696(a5)
    80003434:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003436:	0001c717          	auipc	a4,0x1c
    8000343a:	84a70713          	addi	a4,a4,-1974 # 8001ec80 <bcache+0x8268>
    8000343e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003440:	2b87b703          	ld	a4,696(a5)
    80003444:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003446:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000344a:	00013517          	auipc	a0,0x13
    8000344e:	5ce50513          	addi	a0,a0,1486 # 80016a18 <bcache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	838080e7          	jalr	-1992(ra) # 80000c8a <release>
}
    8000345a:	60e2                	ld	ra,24(sp)
    8000345c:	6442                	ld	s0,16(sp)
    8000345e:	64a2                	ld	s1,8(sp)
    80003460:	6902                	ld	s2,0(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret
    panic("brelse");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	14a50513          	addi	a0,a0,330 # 800085b0 <syscalls+0x100>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0d2080e7          	jalr	210(ra) # 80000540 <panic>

0000000080003476 <bpin>:

void
bpin(struct buf *b) {
    80003476:	1101                	addi	sp,sp,-32
    80003478:	ec06                	sd	ra,24(sp)
    8000347a:	e822                	sd	s0,16(sp)
    8000347c:	e426                	sd	s1,8(sp)
    8000347e:	1000                	addi	s0,sp,32
    80003480:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003482:	00013517          	auipc	a0,0x13
    80003486:	59650513          	addi	a0,a0,1430 # 80016a18 <bcache>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	74c080e7          	jalr	1868(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003492:	40bc                	lw	a5,64(s1)
    80003494:	2785                	addiw	a5,a5,1
    80003496:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003498:	00013517          	auipc	a0,0x13
    8000349c:	58050513          	addi	a0,a0,1408 # 80016a18 <bcache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7ea080e7          	jalr	2026(ra) # 80000c8a <release>
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret

00000000800034b2 <bunpin>:

void
bunpin(struct buf *b) {
    800034b2:	1101                	addi	sp,sp,-32
    800034b4:	ec06                	sd	ra,24(sp)
    800034b6:	e822                	sd	s0,16(sp)
    800034b8:	e426                	sd	s1,8(sp)
    800034ba:	1000                	addi	s0,sp,32
    800034bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034be:	00013517          	auipc	a0,0x13
    800034c2:	55a50513          	addi	a0,a0,1370 # 80016a18 <bcache>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	710080e7          	jalr	1808(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034ce:	40bc                	lw	a5,64(s1)
    800034d0:	37fd                	addiw	a5,a5,-1
    800034d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d4:	00013517          	auipc	a0,0x13
    800034d8:	54450513          	addi	a0,a0,1348 # 80016a18 <bcache>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	7ae080e7          	jalr	1966(ra) # 80000c8a <release>
}
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret

00000000800034ee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034ee:	1101                	addi	sp,sp,-32
    800034f0:	ec06                	sd	ra,24(sp)
    800034f2:	e822                	sd	s0,16(sp)
    800034f4:	e426                	sd	s1,8(sp)
    800034f6:	e04a                	sd	s2,0(sp)
    800034f8:	1000                	addi	s0,sp,32
    800034fa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034fc:	00d5d59b          	srliw	a1,a1,0xd
    80003500:	0001c797          	auipc	a5,0x1c
    80003504:	bf47a783          	lw	a5,-1036(a5) # 8001f0f4 <sb+0x1c>
    80003508:	9dbd                	addw	a1,a1,a5
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	d9e080e7          	jalr	-610(ra) # 800032a8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003512:	0074f713          	andi	a4,s1,7
    80003516:	4785                	li	a5,1
    80003518:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000351c:	14ce                	slli	s1,s1,0x33
    8000351e:	90d9                	srli	s1,s1,0x36
    80003520:	00950733          	add	a4,a0,s1
    80003524:	05874703          	lbu	a4,88(a4)
    80003528:	00e7f6b3          	and	a3,a5,a4
    8000352c:	c69d                	beqz	a3,8000355a <bfree+0x6c>
    8000352e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003530:	94aa                	add	s1,s1,a0
    80003532:	fff7c793          	not	a5,a5
    80003536:	8f7d                	and	a4,a4,a5
    80003538:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000353c:	00001097          	auipc	ra,0x1
    80003540:	126080e7          	jalr	294(ra) # 80004662 <log_write>
  brelse(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e92080e7          	jalr	-366(ra) # 800033d8 <brelse>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6902                	ld	s2,0(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret
    panic("freeing free block");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	05e50513          	addi	a0,a0,94 # 800085b8 <syscalls+0x108>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fde080e7          	jalr	-34(ra) # 80000540 <panic>

000000008000356a <balloc>:
{
    8000356a:	711d                	addi	sp,sp,-96
    8000356c:	ec86                	sd	ra,88(sp)
    8000356e:	e8a2                	sd	s0,80(sp)
    80003570:	e4a6                	sd	s1,72(sp)
    80003572:	e0ca                	sd	s2,64(sp)
    80003574:	fc4e                	sd	s3,56(sp)
    80003576:	f852                	sd	s4,48(sp)
    80003578:	f456                	sd	s5,40(sp)
    8000357a:	f05a                	sd	s6,32(sp)
    8000357c:	ec5e                	sd	s7,24(sp)
    8000357e:	e862                	sd	s8,16(sp)
    80003580:	e466                	sd	s9,8(sp)
    80003582:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003584:	0001c797          	auipc	a5,0x1c
    80003588:	b587a783          	lw	a5,-1192(a5) # 8001f0dc <sb+0x4>
    8000358c:	cff5                	beqz	a5,80003688 <balloc+0x11e>
    8000358e:	8baa                	mv	s7,a0
    80003590:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003592:	0001cb17          	auipc	s6,0x1c
    80003596:	b46b0b13          	addi	s6,s6,-1210 # 8001f0d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000359c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035a0:	6c89                	lui	s9,0x2
    800035a2:	a061                	j	8000362a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035a4:	97ca                	add	a5,a5,s2
    800035a6:	8e55                	or	a2,a2,a3
    800035a8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035ac:	854a                	mv	a0,s2
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	0b4080e7          	jalr	180(ra) # 80004662 <log_write>
        brelse(bp);
    800035b6:	854a                	mv	a0,s2
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	e20080e7          	jalr	-480(ra) # 800033d8 <brelse>
  bp = bread(dev, bno);
    800035c0:	85a6                	mv	a1,s1
    800035c2:	855e                	mv	a0,s7
    800035c4:	00000097          	auipc	ra,0x0
    800035c8:	ce4080e7          	jalr	-796(ra) # 800032a8 <bread>
    800035cc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ce:	40000613          	li	a2,1024
    800035d2:	4581                	li	a1,0
    800035d4:	05850513          	addi	a0,a0,88
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	6fa080e7          	jalr	1786(ra) # 80000cd2 <memset>
  log_write(bp);
    800035e0:	854a                	mv	a0,s2
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	080080e7          	jalr	128(ra) # 80004662 <log_write>
  brelse(bp);
    800035ea:	854a                	mv	a0,s2
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	dec080e7          	jalr	-532(ra) # 800033d8 <brelse>
}
    800035f4:	8526                	mv	a0,s1
    800035f6:	60e6                	ld	ra,88(sp)
    800035f8:	6446                	ld	s0,80(sp)
    800035fa:	64a6                	ld	s1,72(sp)
    800035fc:	6906                	ld	s2,64(sp)
    800035fe:	79e2                	ld	s3,56(sp)
    80003600:	7a42                	ld	s4,48(sp)
    80003602:	7aa2                	ld	s5,40(sp)
    80003604:	7b02                	ld	s6,32(sp)
    80003606:	6be2                	ld	s7,24(sp)
    80003608:	6c42                	ld	s8,16(sp)
    8000360a:	6ca2                	ld	s9,8(sp)
    8000360c:	6125                	addi	sp,sp,96
    8000360e:	8082                	ret
    brelse(bp);
    80003610:	854a                	mv	a0,s2
    80003612:	00000097          	auipc	ra,0x0
    80003616:	dc6080e7          	jalr	-570(ra) # 800033d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000361a:	015c87bb          	addw	a5,s9,s5
    8000361e:	00078a9b          	sext.w	s5,a5
    80003622:	004b2703          	lw	a4,4(s6)
    80003626:	06eaf163          	bgeu	s5,a4,80003688 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000362a:	41fad79b          	sraiw	a5,s5,0x1f
    8000362e:	0137d79b          	srliw	a5,a5,0x13
    80003632:	015787bb          	addw	a5,a5,s5
    80003636:	40d7d79b          	sraiw	a5,a5,0xd
    8000363a:	01cb2583          	lw	a1,28(s6)
    8000363e:	9dbd                	addw	a1,a1,a5
    80003640:	855e                	mv	a0,s7
    80003642:	00000097          	auipc	ra,0x0
    80003646:	c66080e7          	jalr	-922(ra) # 800032a8 <bread>
    8000364a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000364c:	004b2503          	lw	a0,4(s6)
    80003650:	000a849b          	sext.w	s1,s5
    80003654:	8762                	mv	a4,s8
    80003656:	faa4fde3          	bgeu	s1,a0,80003610 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000365a:	00777693          	andi	a3,a4,7
    8000365e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003662:	41f7579b          	sraiw	a5,a4,0x1f
    80003666:	01d7d79b          	srliw	a5,a5,0x1d
    8000366a:	9fb9                	addw	a5,a5,a4
    8000366c:	4037d79b          	sraiw	a5,a5,0x3
    80003670:	00f90633          	add	a2,s2,a5
    80003674:	05864603          	lbu	a2,88(a2)
    80003678:	00c6f5b3          	and	a1,a3,a2
    8000367c:	d585                	beqz	a1,800035a4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000367e:	2705                	addiw	a4,a4,1
    80003680:	2485                	addiw	s1,s1,1
    80003682:	fd471ae3          	bne	a4,s4,80003656 <balloc+0xec>
    80003686:	b769                	j	80003610 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	f4850513          	addi	a0,a0,-184 # 800085d0 <syscalls+0x120>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	efa080e7          	jalr	-262(ra) # 8000058a <printf>
  return 0;
    80003698:	4481                	li	s1,0
    8000369a:	bfa9                	j	800035f4 <balloc+0x8a>

000000008000369c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	e052                	sd	s4,0(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ae:	47ad                	li	a5,11
    800036b0:	02b7e863          	bltu	a5,a1,800036e0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036b4:	02059793          	slli	a5,a1,0x20
    800036b8:	01e7d593          	srli	a1,a5,0x1e
    800036bc:	00b504b3          	add	s1,a0,a1
    800036c0:	0504a903          	lw	s2,80(s1)
    800036c4:	06091e63          	bnez	s2,80003740 <bmap+0xa4>
      addr = balloc(ip->dev);
    800036c8:	4108                	lw	a0,0(a0)
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	ea0080e7          	jalr	-352(ra) # 8000356a <balloc>
    800036d2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036d6:	06090563          	beqz	s2,80003740 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800036da:	0524a823          	sw	s2,80(s1)
    800036de:	a08d                	j	80003740 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036e0:	ff45849b          	addiw	s1,a1,-12
    800036e4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036e8:	0ff00793          	li	a5,255
    800036ec:	08e7e563          	bltu	a5,a4,80003776 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036f0:	08052903          	lw	s2,128(a0)
    800036f4:	00091d63          	bnez	s2,8000370e <bmap+0x72>
      addr = balloc(ip->dev);
    800036f8:	4108                	lw	a0,0(a0)
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	e70080e7          	jalr	-400(ra) # 8000356a <balloc>
    80003702:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003706:	02090d63          	beqz	s2,80003740 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000370a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000370e:	85ca                	mv	a1,s2
    80003710:	0009a503          	lw	a0,0(s3)
    80003714:	00000097          	auipc	ra,0x0
    80003718:	b94080e7          	jalr	-1132(ra) # 800032a8 <bread>
    8000371c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000371e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003722:	02049713          	slli	a4,s1,0x20
    80003726:	01e75593          	srli	a1,a4,0x1e
    8000372a:	00b784b3          	add	s1,a5,a1
    8000372e:	0004a903          	lw	s2,0(s1)
    80003732:	02090063          	beqz	s2,80003752 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003736:	8552                	mv	a0,s4
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	ca0080e7          	jalr	-864(ra) # 800033d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003740:	854a                	mv	a0,s2
    80003742:	70a2                	ld	ra,40(sp)
    80003744:	7402                	ld	s0,32(sp)
    80003746:	64e2                	ld	s1,24(sp)
    80003748:	6942                	ld	s2,16(sp)
    8000374a:	69a2                	ld	s3,8(sp)
    8000374c:	6a02                	ld	s4,0(sp)
    8000374e:	6145                	addi	sp,sp,48
    80003750:	8082                	ret
      addr = balloc(ip->dev);
    80003752:	0009a503          	lw	a0,0(s3)
    80003756:	00000097          	auipc	ra,0x0
    8000375a:	e14080e7          	jalr	-492(ra) # 8000356a <balloc>
    8000375e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003762:	fc090ae3          	beqz	s2,80003736 <bmap+0x9a>
        a[bn] = addr;
    80003766:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000376a:	8552                	mv	a0,s4
    8000376c:	00001097          	auipc	ra,0x1
    80003770:	ef6080e7          	jalr	-266(ra) # 80004662 <log_write>
    80003774:	b7c9                	j	80003736 <bmap+0x9a>
  panic("bmap: out of range");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	e7250513          	addi	a0,a0,-398 # 800085e8 <syscalls+0x138>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dc2080e7          	jalr	-574(ra) # 80000540 <panic>

0000000080003786 <iget>:
{
    80003786:	7179                	addi	sp,sp,-48
    80003788:	f406                	sd	ra,40(sp)
    8000378a:	f022                	sd	s0,32(sp)
    8000378c:	ec26                	sd	s1,24(sp)
    8000378e:	e84a                	sd	s2,16(sp)
    80003790:	e44e                	sd	s3,8(sp)
    80003792:	e052                	sd	s4,0(sp)
    80003794:	1800                	addi	s0,sp,48
    80003796:	89aa                	mv	s3,a0
    80003798:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000379a:	0001c517          	auipc	a0,0x1c
    8000379e:	95e50513          	addi	a0,a0,-1698 # 8001f0f8 <itable>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	434080e7          	jalr	1076(ra) # 80000bd6 <acquire>
  empty = 0;
    800037aa:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037ac:	0001c497          	auipc	s1,0x1c
    800037b0:	96448493          	addi	s1,s1,-1692 # 8001f110 <itable+0x18>
    800037b4:	0001d697          	auipc	a3,0x1d
    800037b8:	3ec68693          	addi	a3,a3,1004 # 80020ba0 <log>
    800037bc:	a039                	j	800037ca <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037be:	02090b63          	beqz	s2,800037f4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c2:	08848493          	addi	s1,s1,136
    800037c6:	02d48a63          	beq	s1,a3,800037fa <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	fef059e3          	blez	a5,800037be <iget+0x38>
    800037d0:	4098                	lw	a4,0(s1)
    800037d2:	ff3716e3          	bne	a4,s3,800037be <iget+0x38>
    800037d6:	40d8                	lw	a4,4(s1)
    800037d8:	ff4713e3          	bne	a4,s4,800037be <iget+0x38>
      ip->ref++;
    800037dc:	2785                	addiw	a5,a5,1
    800037de:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037e0:	0001c517          	auipc	a0,0x1c
    800037e4:	91850513          	addi	a0,a0,-1768 # 8001f0f8 <itable>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	4a2080e7          	jalr	1186(ra) # 80000c8a <release>
      return ip;
    800037f0:	8926                	mv	s2,s1
    800037f2:	a03d                	j	80003820 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f4:	f7f9                	bnez	a5,800037c2 <iget+0x3c>
    800037f6:	8926                	mv	s2,s1
    800037f8:	b7e9                	j	800037c2 <iget+0x3c>
  if(empty == 0)
    800037fa:	02090c63          	beqz	s2,80003832 <iget+0xac>
  ip->dev = dev;
    800037fe:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003802:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003806:	4785                	li	a5,1
    80003808:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000380c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003810:	0001c517          	auipc	a0,0x1c
    80003814:	8e850513          	addi	a0,a0,-1816 # 8001f0f8 <itable>
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	472080e7          	jalr	1138(ra) # 80000c8a <release>
}
    80003820:	854a                	mv	a0,s2
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    panic("iget: no inodes");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	dce50513          	addi	a0,a0,-562 # 80008600 <syscalls+0x150>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>

0000000080003842 <fsinit>:
fsinit(int dev) {
    80003842:	7179                	addi	sp,sp,-48
    80003844:	f406                	sd	ra,40(sp)
    80003846:	f022                	sd	s0,32(sp)
    80003848:	ec26                	sd	s1,24(sp)
    8000384a:	e84a                	sd	s2,16(sp)
    8000384c:	e44e                	sd	s3,8(sp)
    8000384e:	1800                	addi	s0,sp,48
    80003850:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003852:	4585                	li	a1,1
    80003854:	00000097          	auipc	ra,0x0
    80003858:	a54080e7          	jalr	-1452(ra) # 800032a8 <bread>
    8000385c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000385e:	0001c997          	auipc	s3,0x1c
    80003862:	87a98993          	addi	s3,s3,-1926 # 8001f0d8 <sb>
    80003866:	02000613          	li	a2,32
    8000386a:	05850593          	addi	a1,a0,88
    8000386e:	854e                	mv	a0,s3
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	4be080e7          	jalr	1214(ra) # 80000d2e <memmove>
  brelse(bp);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	b5e080e7          	jalr	-1186(ra) # 800033d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003882:	0009a703          	lw	a4,0(s3)
    80003886:	102037b7          	lui	a5,0x10203
    8000388a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000388e:	02f71263          	bne	a4,a5,800038b2 <fsinit+0x70>
  initlog(dev, &sb);
    80003892:	0001c597          	auipc	a1,0x1c
    80003896:	84658593          	addi	a1,a1,-1978 # 8001f0d8 <sb>
    8000389a:	854a                	mv	a0,s2
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	b4a080e7          	jalr	-1206(ra) # 800043e6 <initlog>
}
    800038a4:	70a2                	ld	ra,40(sp)
    800038a6:	7402                	ld	s0,32(sp)
    800038a8:	64e2                	ld	s1,24(sp)
    800038aa:	6942                	ld	s2,16(sp)
    800038ac:	69a2                	ld	s3,8(sp)
    800038ae:	6145                	addi	sp,sp,48
    800038b0:	8082                	ret
    panic("invalid file system");
    800038b2:	00005517          	auipc	a0,0x5
    800038b6:	d5e50513          	addi	a0,a0,-674 # 80008610 <syscalls+0x160>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	c86080e7          	jalr	-890(ra) # 80000540 <panic>

00000000800038c2 <iinit>:
{
    800038c2:	7179                	addi	sp,sp,-48
    800038c4:	f406                	sd	ra,40(sp)
    800038c6:	f022                	sd	s0,32(sp)
    800038c8:	ec26                	sd	s1,24(sp)
    800038ca:	e84a                	sd	s2,16(sp)
    800038cc:	e44e                	sd	s3,8(sp)
    800038ce:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038d0:	00005597          	auipc	a1,0x5
    800038d4:	d5858593          	addi	a1,a1,-680 # 80008628 <syscalls+0x178>
    800038d8:	0001c517          	auipc	a0,0x1c
    800038dc:	82050513          	addi	a0,a0,-2016 # 8001f0f8 <itable>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	266080e7          	jalr	614(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038e8:	0001c497          	auipc	s1,0x1c
    800038ec:	83848493          	addi	s1,s1,-1992 # 8001f120 <itable+0x28>
    800038f0:	0001d997          	auipc	s3,0x1d
    800038f4:	2c098993          	addi	s3,s3,704 # 80020bb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038f8:	00005917          	auipc	s2,0x5
    800038fc:	d3890913          	addi	s2,s2,-712 # 80008630 <syscalls+0x180>
    80003900:	85ca                	mv	a1,s2
    80003902:	8526                	mv	a0,s1
    80003904:	00001097          	auipc	ra,0x1
    80003908:	e42080e7          	jalr	-446(ra) # 80004746 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000390c:	08848493          	addi	s1,s1,136
    80003910:	ff3498e3          	bne	s1,s3,80003900 <iinit+0x3e>
}
    80003914:	70a2                	ld	ra,40(sp)
    80003916:	7402                	ld	s0,32(sp)
    80003918:	64e2                	ld	s1,24(sp)
    8000391a:	6942                	ld	s2,16(sp)
    8000391c:	69a2                	ld	s3,8(sp)
    8000391e:	6145                	addi	sp,sp,48
    80003920:	8082                	ret

0000000080003922 <ialloc>:
{
    80003922:	715d                	addi	sp,sp,-80
    80003924:	e486                	sd	ra,72(sp)
    80003926:	e0a2                	sd	s0,64(sp)
    80003928:	fc26                	sd	s1,56(sp)
    8000392a:	f84a                	sd	s2,48(sp)
    8000392c:	f44e                	sd	s3,40(sp)
    8000392e:	f052                	sd	s4,32(sp)
    80003930:	ec56                	sd	s5,24(sp)
    80003932:	e85a                	sd	s6,16(sp)
    80003934:	e45e                	sd	s7,8(sp)
    80003936:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003938:	0001b717          	auipc	a4,0x1b
    8000393c:	7ac72703          	lw	a4,1964(a4) # 8001f0e4 <sb+0xc>
    80003940:	4785                	li	a5,1
    80003942:	04e7fa63          	bgeu	a5,a4,80003996 <ialloc+0x74>
    80003946:	8aaa                	mv	s5,a0
    80003948:	8bae                	mv	s7,a1
    8000394a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000394c:	0001ba17          	auipc	s4,0x1b
    80003950:	78ca0a13          	addi	s4,s4,1932 # 8001f0d8 <sb>
    80003954:	00048b1b          	sext.w	s6,s1
    80003958:	0044d593          	srli	a1,s1,0x4
    8000395c:	018a2783          	lw	a5,24(s4)
    80003960:	9dbd                	addw	a1,a1,a5
    80003962:	8556                	mv	a0,s5
    80003964:	00000097          	auipc	ra,0x0
    80003968:	944080e7          	jalr	-1724(ra) # 800032a8 <bread>
    8000396c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000396e:	05850993          	addi	s3,a0,88
    80003972:	00f4f793          	andi	a5,s1,15
    80003976:	079a                	slli	a5,a5,0x6
    80003978:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000397a:	00099783          	lh	a5,0(s3)
    8000397e:	c3a1                	beqz	a5,800039be <ialloc+0x9c>
    brelse(bp);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	a58080e7          	jalr	-1448(ra) # 800033d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003988:	0485                	addi	s1,s1,1
    8000398a:	00ca2703          	lw	a4,12(s4)
    8000398e:	0004879b          	sext.w	a5,s1
    80003992:	fce7e1e3          	bltu	a5,a4,80003954 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	ca250513          	addi	a0,a0,-862 # 80008638 <syscalls+0x188>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	bec080e7          	jalr	-1044(ra) # 8000058a <printf>
  return 0;
    800039a6:	4501                	li	a0,0
}
    800039a8:	60a6                	ld	ra,72(sp)
    800039aa:	6406                	ld	s0,64(sp)
    800039ac:	74e2                	ld	s1,56(sp)
    800039ae:	7942                	ld	s2,48(sp)
    800039b0:	79a2                	ld	s3,40(sp)
    800039b2:	7a02                	ld	s4,32(sp)
    800039b4:	6ae2                	ld	s5,24(sp)
    800039b6:	6b42                	ld	s6,16(sp)
    800039b8:	6ba2                	ld	s7,8(sp)
    800039ba:	6161                	addi	sp,sp,80
    800039bc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039be:	04000613          	li	a2,64
    800039c2:	4581                	li	a1,0
    800039c4:	854e                	mv	a0,s3
    800039c6:	ffffd097          	auipc	ra,0xffffd
    800039ca:	30c080e7          	jalr	780(ra) # 80000cd2 <memset>
      dip->type = type;
    800039ce:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	c8e080e7          	jalr	-882(ra) # 80004662 <log_write>
      brelse(bp);
    800039dc:	854a                	mv	a0,s2
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	9fa080e7          	jalr	-1542(ra) # 800033d8 <brelse>
      return iget(dev, inum);
    800039e6:	85da                	mv	a1,s6
    800039e8:	8556                	mv	a0,s5
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	d9c080e7          	jalr	-612(ra) # 80003786 <iget>
    800039f2:	bf5d                	j	800039a8 <ialloc+0x86>

00000000800039f4 <iupdate>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	e04a                	sd	s2,0(sp)
    800039fe:	1000                	addi	s0,sp,32
    80003a00:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a02:	415c                	lw	a5,4(a0)
    80003a04:	0047d79b          	srliw	a5,a5,0x4
    80003a08:	0001b597          	auipc	a1,0x1b
    80003a0c:	6e85a583          	lw	a1,1768(a1) # 8001f0f0 <sb+0x18>
    80003a10:	9dbd                	addw	a1,a1,a5
    80003a12:	4108                	lw	a0,0(a0)
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	894080e7          	jalr	-1900(ra) # 800032a8 <bread>
    80003a1c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a1e:	05850793          	addi	a5,a0,88
    80003a22:	40d8                	lw	a4,4(s1)
    80003a24:	8b3d                	andi	a4,a4,15
    80003a26:	071a                	slli	a4,a4,0x6
    80003a28:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a2a:	04449703          	lh	a4,68(s1)
    80003a2e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a32:	04649703          	lh	a4,70(s1)
    80003a36:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a3a:	04849703          	lh	a4,72(s1)
    80003a3e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a42:	04a49703          	lh	a4,74(s1)
    80003a46:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a4a:	44f8                	lw	a4,76(s1)
    80003a4c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a4e:	03400613          	li	a2,52
    80003a52:	05048593          	addi	a1,s1,80
    80003a56:	00c78513          	addi	a0,a5,12
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	2d4080e7          	jalr	724(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	bfe080e7          	jalr	-1026(ra) # 80004662 <log_write>
  brelse(bp);
    80003a6c:	854a                	mv	a0,s2
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	96a080e7          	jalr	-1686(ra) # 800033d8 <brelse>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret

0000000080003a82 <idup>:
{
    80003a82:	1101                	addi	sp,sp,-32
    80003a84:	ec06                	sd	ra,24(sp)
    80003a86:	e822                	sd	s0,16(sp)
    80003a88:	e426                	sd	s1,8(sp)
    80003a8a:	1000                	addi	s0,sp,32
    80003a8c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a8e:	0001b517          	auipc	a0,0x1b
    80003a92:	66a50513          	addi	a0,a0,1642 # 8001f0f8 <itable>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	140080e7          	jalr	320(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a9e:	449c                	lw	a5,8(s1)
    80003aa0:	2785                	addiw	a5,a5,1
    80003aa2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa4:	0001b517          	auipc	a0,0x1b
    80003aa8:	65450513          	addi	a0,a0,1620 # 8001f0f8 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	1de080e7          	jalr	478(ra) # 80000c8a <release>
}
    80003ab4:	8526                	mv	a0,s1
    80003ab6:	60e2                	ld	ra,24(sp)
    80003ab8:	6442                	ld	s0,16(sp)
    80003aba:	64a2                	ld	s1,8(sp)
    80003abc:	6105                	addi	sp,sp,32
    80003abe:	8082                	ret

0000000080003ac0 <ilock>:
{
    80003ac0:	1101                	addi	sp,sp,-32
    80003ac2:	ec06                	sd	ra,24(sp)
    80003ac4:	e822                	sd	s0,16(sp)
    80003ac6:	e426                	sd	s1,8(sp)
    80003ac8:	e04a                	sd	s2,0(sp)
    80003aca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003acc:	c115                	beqz	a0,80003af0 <ilock+0x30>
    80003ace:	84aa                	mv	s1,a0
    80003ad0:	451c                	lw	a5,8(a0)
    80003ad2:	00f05f63          	blez	a5,80003af0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ad6:	0541                	addi	a0,a0,16
    80003ad8:	00001097          	auipc	ra,0x1
    80003adc:	ca8080e7          	jalr	-856(ra) # 80004780 <acquiresleep>
  if(ip->valid == 0){
    80003ae0:	40bc                	lw	a5,64(s1)
    80003ae2:	cf99                	beqz	a5,80003b00 <ilock+0x40>
}
    80003ae4:	60e2                	ld	ra,24(sp)
    80003ae6:	6442                	ld	s0,16(sp)
    80003ae8:	64a2                	ld	s1,8(sp)
    80003aea:	6902                	ld	s2,0(sp)
    80003aec:	6105                	addi	sp,sp,32
    80003aee:	8082                	ret
    panic("ilock");
    80003af0:	00005517          	auipc	a0,0x5
    80003af4:	b6050513          	addi	a0,a0,-1184 # 80008650 <syscalls+0x1a0>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	a48080e7          	jalr	-1464(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b00:	40dc                	lw	a5,4(s1)
    80003b02:	0047d79b          	srliw	a5,a5,0x4
    80003b06:	0001b597          	auipc	a1,0x1b
    80003b0a:	5ea5a583          	lw	a1,1514(a1) # 8001f0f0 <sb+0x18>
    80003b0e:	9dbd                	addw	a1,a1,a5
    80003b10:	4088                	lw	a0,0(s1)
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	796080e7          	jalr	1942(ra) # 800032a8 <bread>
    80003b1a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b1c:	05850593          	addi	a1,a0,88
    80003b20:	40dc                	lw	a5,4(s1)
    80003b22:	8bbd                	andi	a5,a5,15
    80003b24:	079a                	slli	a5,a5,0x6
    80003b26:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b28:	00059783          	lh	a5,0(a1)
    80003b2c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b30:	00259783          	lh	a5,2(a1)
    80003b34:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b38:	00459783          	lh	a5,4(a1)
    80003b3c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b40:	00659783          	lh	a5,6(a1)
    80003b44:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b48:	459c                	lw	a5,8(a1)
    80003b4a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b4c:	03400613          	li	a2,52
    80003b50:	05b1                	addi	a1,a1,12
    80003b52:	05048513          	addi	a0,s1,80
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	1d8080e7          	jalr	472(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	00000097          	auipc	ra,0x0
    80003b64:	878080e7          	jalr	-1928(ra) # 800033d8 <brelse>
    ip->valid = 1;
    80003b68:	4785                	li	a5,1
    80003b6a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b6c:	04449783          	lh	a5,68(s1)
    80003b70:	fbb5                	bnez	a5,80003ae4 <ilock+0x24>
      panic("ilock: no type");
    80003b72:	00005517          	auipc	a0,0x5
    80003b76:	ae650513          	addi	a0,a0,-1306 # 80008658 <syscalls+0x1a8>
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	9c6080e7          	jalr	-1594(ra) # 80000540 <panic>

0000000080003b82 <iunlock>:
{
    80003b82:	1101                	addi	sp,sp,-32
    80003b84:	ec06                	sd	ra,24(sp)
    80003b86:	e822                	sd	s0,16(sp)
    80003b88:	e426                	sd	s1,8(sp)
    80003b8a:	e04a                	sd	s2,0(sp)
    80003b8c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b8e:	c905                	beqz	a0,80003bbe <iunlock+0x3c>
    80003b90:	84aa                	mv	s1,a0
    80003b92:	01050913          	addi	s2,a0,16
    80003b96:	854a                	mv	a0,s2
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	c82080e7          	jalr	-894(ra) # 8000481a <holdingsleep>
    80003ba0:	cd19                	beqz	a0,80003bbe <iunlock+0x3c>
    80003ba2:	449c                	lw	a5,8(s1)
    80003ba4:	00f05d63          	blez	a5,80003bbe <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	c2c080e7          	jalr	-980(ra) # 800047d6 <releasesleep>
}
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6902                	ld	s2,0(sp)
    80003bba:	6105                	addi	sp,sp,32
    80003bbc:	8082                	ret
    panic("iunlock");
    80003bbe:	00005517          	auipc	a0,0x5
    80003bc2:	aaa50513          	addi	a0,a0,-1366 # 80008668 <syscalls+0x1b8>
    80003bc6:	ffffd097          	auipc	ra,0xffffd
    80003bca:	97a080e7          	jalr	-1670(ra) # 80000540 <panic>

0000000080003bce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bce:	7179                	addi	sp,sp,-48
    80003bd0:	f406                	sd	ra,40(sp)
    80003bd2:	f022                	sd	s0,32(sp)
    80003bd4:	ec26                	sd	s1,24(sp)
    80003bd6:	e84a                	sd	s2,16(sp)
    80003bd8:	e44e                	sd	s3,8(sp)
    80003bda:	e052                	sd	s4,0(sp)
    80003bdc:	1800                	addi	s0,sp,48
    80003bde:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003be0:	05050493          	addi	s1,a0,80
    80003be4:	08050913          	addi	s2,a0,128
    80003be8:	a021                	j	80003bf0 <itrunc+0x22>
    80003bea:	0491                	addi	s1,s1,4
    80003bec:	01248d63          	beq	s1,s2,80003c06 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bf0:	408c                	lw	a1,0(s1)
    80003bf2:	dde5                	beqz	a1,80003bea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bf4:	0009a503          	lw	a0,0(s3)
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	8f6080e7          	jalr	-1802(ra) # 800034ee <bfree>
      ip->addrs[i] = 0;
    80003c00:	0004a023          	sw	zero,0(s1)
    80003c04:	b7dd                	j	80003bea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c06:	0809a583          	lw	a1,128(s3)
    80003c0a:	e185                	bnez	a1,80003c2a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c0c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c10:	854e                	mv	a0,s3
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	de2080e7          	jalr	-542(ra) # 800039f4 <iupdate>
}
    80003c1a:	70a2                	ld	ra,40(sp)
    80003c1c:	7402                	ld	s0,32(sp)
    80003c1e:	64e2                	ld	s1,24(sp)
    80003c20:	6942                	ld	s2,16(sp)
    80003c22:	69a2                	ld	s3,8(sp)
    80003c24:	6a02                	ld	s4,0(sp)
    80003c26:	6145                	addi	sp,sp,48
    80003c28:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c2a:	0009a503          	lw	a0,0(s3)
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	67a080e7          	jalr	1658(ra) # 800032a8 <bread>
    80003c36:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c38:	05850493          	addi	s1,a0,88
    80003c3c:	45850913          	addi	s2,a0,1112
    80003c40:	a021                	j	80003c48 <itrunc+0x7a>
    80003c42:	0491                	addi	s1,s1,4
    80003c44:	01248b63          	beq	s1,s2,80003c5a <itrunc+0x8c>
      if(a[j])
    80003c48:	408c                	lw	a1,0(s1)
    80003c4a:	dde5                	beqz	a1,80003c42 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c4c:	0009a503          	lw	a0,0(s3)
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	89e080e7          	jalr	-1890(ra) # 800034ee <bfree>
    80003c58:	b7ed                	j	80003c42 <itrunc+0x74>
    brelse(bp);
    80003c5a:	8552                	mv	a0,s4
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	77c080e7          	jalr	1916(ra) # 800033d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c64:	0809a583          	lw	a1,128(s3)
    80003c68:	0009a503          	lw	a0,0(s3)
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	882080e7          	jalr	-1918(ra) # 800034ee <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c74:	0809a023          	sw	zero,128(s3)
    80003c78:	bf51                	j	80003c0c <itrunc+0x3e>

0000000080003c7a <iput>:
{
    80003c7a:	1101                	addi	sp,sp,-32
    80003c7c:	ec06                	sd	ra,24(sp)
    80003c7e:	e822                	sd	s0,16(sp)
    80003c80:	e426                	sd	s1,8(sp)
    80003c82:	e04a                	sd	s2,0(sp)
    80003c84:	1000                	addi	s0,sp,32
    80003c86:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c88:	0001b517          	auipc	a0,0x1b
    80003c8c:	47050513          	addi	a0,a0,1136 # 8001f0f8 <itable>
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	f46080e7          	jalr	-186(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c98:	4498                	lw	a4,8(s1)
    80003c9a:	4785                	li	a5,1
    80003c9c:	02f70363          	beq	a4,a5,80003cc2 <iput+0x48>
  ip->ref--;
    80003ca0:	449c                	lw	a5,8(s1)
    80003ca2:	37fd                	addiw	a5,a5,-1
    80003ca4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ca6:	0001b517          	auipc	a0,0x1b
    80003caa:	45250513          	addi	a0,a0,1106 # 8001f0f8 <itable>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	fdc080e7          	jalr	-36(ra) # 80000c8a <release>
}
    80003cb6:	60e2                	ld	ra,24(sp)
    80003cb8:	6442                	ld	s0,16(sp)
    80003cba:	64a2                	ld	s1,8(sp)
    80003cbc:	6902                	ld	s2,0(sp)
    80003cbe:	6105                	addi	sp,sp,32
    80003cc0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cc2:	40bc                	lw	a5,64(s1)
    80003cc4:	dff1                	beqz	a5,80003ca0 <iput+0x26>
    80003cc6:	04a49783          	lh	a5,74(s1)
    80003cca:	fbf9                	bnez	a5,80003ca0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ccc:	01048913          	addi	s2,s1,16
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00001097          	auipc	ra,0x1
    80003cd6:	aae080e7          	jalr	-1362(ra) # 80004780 <acquiresleep>
    release(&itable.lock);
    80003cda:	0001b517          	auipc	a0,0x1b
    80003cde:	41e50513          	addi	a0,a0,1054 # 8001f0f8 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	fa8080e7          	jalr	-88(ra) # 80000c8a <release>
    itrunc(ip);
    80003cea:	8526                	mv	a0,s1
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	ee2080e7          	jalr	-286(ra) # 80003bce <itrunc>
    ip->type = 0;
    80003cf4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cf8:	8526                	mv	a0,s1
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	cfa080e7          	jalr	-774(ra) # 800039f4 <iupdate>
    ip->valid = 0;
    80003d02:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d06:	854a                	mv	a0,s2
    80003d08:	00001097          	auipc	ra,0x1
    80003d0c:	ace080e7          	jalr	-1330(ra) # 800047d6 <releasesleep>
    acquire(&itable.lock);
    80003d10:	0001b517          	auipc	a0,0x1b
    80003d14:	3e850513          	addi	a0,a0,1000 # 8001f0f8 <itable>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	ebe080e7          	jalr	-322(ra) # 80000bd6 <acquire>
    80003d20:	b741                	j	80003ca0 <iput+0x26>

0000000080003d22 <iunlockput>:
{
    80003d22:	1101                	addi	sp,sp,-32
    80003d24:	ec06                	sd	ra,24(sp)
    80003d26:	e822                	sd	s0,16(sp)
    80003d28:	e426                	sd	s1,8(sp)
    80003d2a:	1000                	addi	s0,sp,32
    80003d2c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	e54080e7          	jalr	-428(ra) # 80003b82 <iunlock>
  iput(ip);
    80003d36:	8526                	mv	a0,s1
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	f42080e7          	jalr	-190(ra) # 80003c7a <iput>
}
    80003d40:	60e2                	ld	ra,24(sp)
    80003d42:	6442                	ld	s0,16(sp)
    80003d44:	64a2                	ld	s1,8(sp)
    80003d46:	6105                	addi	sp,sp,32
    80003d48:	8082                	ret

0000000080003d4a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d4a:	1141                	addi	sp,sp,-16
    80003d4c:	e422                	sd	s0,8(sp)
    80003d4e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d50:	411c                	lw	a5,0(a0)
    80003d52:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d54:	415c                	lw	a5,4(a0)
    80003d56:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d58:	04451783          	lh	a5,68(a0)
    80003d5c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d60:	04a51783          	lh	a5,74(a0)
    80003d64:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d68:	04c56783          	lwu	a5,76(a0)
    80003d6c:	e99c                	sd	a5,16(a1)
}
    80003d6e:	6422                	ld	s0,8(sp)
    80003d70:	0141                	addi	sp,sp,16
    80003d72:	8082                	ret

0000000080003d74 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d74:	457c                	lw	a5,76(a0)
    80003d76:	0ed7e963          	bltu	a5,a3,80003e68 <readi+0xf4>
{
    80003d7a:	7159                	addi	sp,sp,-112
    80003d7c:	f486                	sd	ra,104(sp)
    80003d7e:	f0a2                	sd	s0,96(sp)
    80003d80:	eca6                	sd	s1,88(sp)
    80003d82:	e8ca                	sd	s2,80(sp)
    80003d84:	e4ce                	sd	s3,72(sp)
    80003d86:	e0d2                	sd	s4,64(sp)
    80003d88:	fc56                	sd	s5,56(sp)
    80003d8a:	f85a                	sd	s6,48(sp)
    80003d8c:	f45e                	sd	s7,40(sp)
    80003d8e:	f062                	sd	s8,32(sp)
    80003d90:	ec66                	sd	s9,24(sp)
    80003d92:	e86a                	sd	s10,16(sp)
    80003d94:	e46e                	sd	s11,8(sp)
    80003d96:	1880                	addi	s0,sp,112
    80003d98:	8b2a                	mv	s6,a0
    80003d9a:	8bae                	mv	s7,a1
    80003d9c:	8a32                	mv	s4,a2
    80003d9e:	84b6                	mv	s1,a3
    80003da0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003da2:	9f35                	addw	a4,a4,a3
    return 0;
    80003da4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003da6:	0ad76063          	bltu	a4,a3,80003e46 <readi+0xd2>
  if(off + n > ip->size)
    80003daa:	00e7f463          	bgeu	a5,a4,80003db2 <readi+0x3e>
    n = ip->size - off;
    80003dae:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003db2:	0a0a8963          	beqz	s5,80003e64 <readi+0xf0>
    80003db6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dbc:	5c7d                	li	s8,-1
    80003dbe:	a82d                	j	80003df8 <readi+0x84>
    80003dc0:	020d1d93          	slli	s11,s10,0x20
    80003dc4:	020ddd93          	srli	s11,s11,0x20
    80003dc8:	05890613          	addi	a2,s2,88
    80003dcc:	86ee                	mv	a3,s11
    80003dce:	963a                	add	a2,a2,a4
    80003dd0:	85d2                	mv	a1,s4
    80003dd2:	855e                	mv	a0,s7
    80003dd4:	ffffe097          	auipc	ra,0xffffe
    80003dd8:	688080e7          	jalr	1672(ra) # 8000245c <either_copyout>
    80003ddc:	05850d63          	beq	a0,s8,80003e36 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003de0:	854a                	mv	a0,s2
    80003de2:	fffff097          	auipc	ra,0xfffff
    80003de6:	5f6080e7          	jalr	1526(ra) # 800033d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dea:	013d09bb          	addw	s3,s10,s3
    80003dee:	009d04bb          	addw	s1,s10,s1
    80003df2:	9a6e                	add	s4,s4,s11
    80003df4:	0559f763          	bgeu	s3,s5,80003e42 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003df8:	00a4d59b          	srliw	a1,s1,0xa
    80003dfc:	855a                	mv	a0,s6
    80003dfe:	00000097          	auipc	ra,0x0
    80003e02:	89e080e7          	jalr	-1890(ra) # 8000369c <bmap>
    80003e06:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e0a:	cd85                	beqz	a1,80003e42 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e0c:	000b2503          	lw	a0,0(s6)
    80003e10:	fffff097          	auipc	ra,0xfffff
    80003e14:	498080e7          	jalr	1176(ra) # 800032a8 <bread>
    80003e18:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e1a:	3ff4f713          	andi	a4,s1,1023
    80003e1e:	40ec87bb          	subw	a5,s9,a4
    80003e22:	413a86bb          	subw	a3,s5,s3
    80003e26:	8d3e                	mv	s10,a5
    80003e28:	2781                	sext.w	a5,a5
    80003e2a:	0006861b          	sext.w	a2,a3
    80003e2e:	f8f679e3          	bgeu	a2,a5,80003dc0 <readi+0x4c>
    80003e32:	8d36                	mv	s10,a3
    80003e34:	b771                	j	80003dc0 <readi+0x4c>
      brelse(bp);
    80003e36:	854a                	mv	a0,s2
    80003e38:	fffff097          	auipc	ra,0xfffff
    80003e3c:	5a0080e7          	jalr	1440(ra) # 800033d8 <brelse>
      tot = -1;
    80003e40:	59fd                	li	s3,-1
  }
  return tot;
    80003e42:	0009851b          	sext.w	a0,s3
}
    80003e46:	70a6                	ld	ra,104(sp)
    80003e48:	7406                	ld	s0,96(sp)
    80003e4a:	64e6                	ld	s1,88(sp)
    80003e4c:	6946                	ld	s2,80(sp)
    80003e4e:	69a6                	ld	s3,72(sp)
    80003e50:	6a06                	ld	s4,64(sp)
    80003e52:	7ae2                	ld	s5,56(sp)
    80003e54:	7b42                	ld	s6,48(sp)
    80003e56:	7ba2                	ld	s7,40(sp)
    80003e58:	7c02                	ld	s8,32(sp)
    80003e5a:	6ce2                	ld	s9,24(sp)
    80003e5c:	6d42                	ld	s10,16(sp)
    80003e5e:	6da2                	ld	s11,8(sp)
    80003e60:	6165                	addi	sp,sp,112
    80003e62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e64:	89d6                	mv	s3,s5
    80003e66:	bff1                	j	80003e42 <readi+0xce>
    return 0;
    80003e68:	4501                	li	a0,0
}
    80003e6a:	8082                	ret

0000000080003e6c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e6c:	457c                	lw	a5,76(a0)
    80003e6e:	10d7e863          	bltu	a5,a3,80003f7e <writei+0x112>
{
    80003e72:	7159                	addi	sp,sp,-112
    80003e74:	f486                	sd	ra,104(sp)
    80003e76:	f0a2                	sd	s0,96(sp)
    80003e78:	eca6                	sd	s1,88(sp)
    80003e7a:	e8ca                	sd	s2,80(sp)
    80003e7c:	e4ce                	sd	s3,72(sp)
    80003e7e:	e0d2                	sd	s4,64(sp)
    80003e80:	fc56                	sd	s5,56(sp)
    80003e82:	f85a                	sd	s6,48(sp)
    80003e84:	f45e                	sd	s7,40(sp)
    80003e86:	f062                	sd	s8,32(sp)
    80003e88:	ec66                	sd	s9,24(sp)
    80003e8a:	e86a                	sd	s10,16(sp)
    80003e8c:	e46e                	sd	s11,8(sp)
    80003e8e:	1880                	addi	s0,sp,112
    80003e90:	8aaa                	mv	s5,a0
    80003e92:	8bae                	mv	s7,a1
    80003e94:	8a32                	mv	s4,a2
    80003e96:	8936                	mv	s2,a3
    80003e98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e9a:	00e687bb          	addw	a5,a3,a4
    80003e9e:	0ed7e263          	bltu	a5,a3,80003f82 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ea2:	00043737          	lui	a4,0x43
    80003ea6:	0ef76063          	bltu	a4,a5,80003f86 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eaa:	0c0b0863          	beqz	s6,80003f7a <writei+0x10e>
    80003eae:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eb4:	5c7d                	li	s8,-1
    80003eb6:	a091                	j	80003efa <writei+0x8e>
    80003eb8:	020d1d93          	slli	s11,s10,0x20
    80003ebc:	020ddd93          	srli	s11,s11,0x20
    80003ec0:	05848513          	addi	a0,s1,88
    80003ec4:	86ee                	mv	a3,s11
    80003ec6:	8652                	mv	a2,s4
    80003ec8:	85de                	mv	a1,s7
    80003eca:	953a                	add	a0,a0,a4
    80003ecc:	ffffe097          	auipc	ra,0xffffe
    80003ed0:	5e6080e7          	jalr	1510(ra) # 800024b2 <either_copyin>
    80003ed4:	07850263          	beq	a0,s8,80003f38 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ed8:	8526                	mv	a0,s1
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	788080e7          	jalr	1928(ra) # 80004662 <log_write>
    brelse(bp);
    80003ee2:	8526                	mv	a0,s1
    80003ee4:	fffff097          	auipc	ra,0xfffff
    80003ee8:	4f4080e7          	jalr	1268(ra) # 800033d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003eec:	013d09bb          	addw	s3,s10,s3
    80003ef0:	012d093b          	addw	s2,s10,s2
    80003ef4:	9a6e                	add	s4,s4,s11
    80003ef6:	0569f663          	bgeu	s3,s6,80003f42 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003efa:	00a9559b          	srliw	a1,s2,0xa
    80003efe:	8556                	mv	a0,s5
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	79c080e7          	jalr	1948(ra) # 8000369c <bmap>
    80003f08:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f0c:	c99d                	beqz	a1,80003f42 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f0e:	000aa503          	lw	a0,0(s5)
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	396080e7          	jalr	918(ra) # 800032a8 <bread>
    80003f1a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f1c:	3ff97713          	andi	a4,s2,1023
    80003f20:	40ec87bb          	subw	a5,s9,a4
    80003f24:	413b06bb          	subw	a3,s6,s3
    80003f28:	8d3e                	mv	s10,a5
    80003f2a:	2781                	sext.w	a5,a5
    80003f2c:	0006861b          	sext.w	a2,a3
    80003f30:	f8f674e3          	bgeu	a2,a5,80003eb8 <writei+0x4c>
    80003f34:	8d36                	mv	s10,a3
    80003f36:	b749                	j	80003eb8 <writei+0x4c>
      brelse(bp);
    80003f38:	8526                	mv	a0,s1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	49e080e7          	jalr	1182(ra) # 800033d8 <brelse>
  }

  if(off > ip->size)
    80003f42:	04caa783          	lw	a5,76(s5)
    80003f46:	0127f463          	bgeu	a5,s2,80003f4e <writei+0xe2>
    ip->size = off;
    80003f4a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f4e:	8556                	mv	a0,s5
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	aa4080e7          	jalr	-1372(ra) # 800039f4 <iupdate>

  return tot;
    80003f58:	0009851b          	sext.w	a0,s3
}
    80003f5c:	70a6                	ld	ra,104(sp)
    80003f5e:	7406                	ld	s0,96(sp)
    80003f60:	64e6                	ld	s1,88(sp)
    80003f62:	6946                	ld	s2,80(sp)
    80003f64:	69a6                	ld	s3,72(sp)
    80003f66:	6a06                	ld	s4,64(sp)
    80003f68:	7ae2                	ld	s5,56(sp)
    80003f6a:	7b42                	ld	s6,48(sp)
    80003f6c:	7ba2                	ld	s7,40(sp)
    80003f6e:	7c02                	ld	s8,32(sp)
    80003f70:	6ce2                	ld	s9,24(sp)
    80003f72:	6d42                	ld	s10,16(sp)
    80003f74:	6da2                	ld	s11,8(sp)
    80003f76:	6165                	addi	sp,sp,112
    80003f78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7a:	89da                	mv	s3,s6
    80003f7c:	bfc9                	j	80003f4e <writei+0xe2>
    return -1;
    80003f7e:	557d                	li	a0,-1
}
    80003f80:	8082                	ret
    return -1;
    80003f82:	557d                	li	a0,-1
    80003f84:	bfe1                	j	80003f5c <writei+0xf0>
    return -1;
    80003f86:	557d                	li	a0,-1
    80003f88:	bfd1                	j	80003f5c <writei+0xf0>

0000000080003f8a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f8a:	1141                	addi	sp,sp,-16
    80003f8c:	e406                	sd	ra,8(sp)
    80003f8e:	e022                	sd	s0,0(sp)
    80003f90:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f92:	4639                	li	a2,14
    80003f94:	ffffd097          	auipc	ra,0xffffd
    80003f98:	e0e080e7          	jalr	-498(ra) # 80000da2 <strncmp>
}
    80003f9c:	60a2                	ld	ra,8(sp)
    80003f9e:	6402                	ld	s0,0(sp)
    80003fa0:	0141                	addi	sp,sp,16
    80003fa2:	8082                	ret

0000000080003fa4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fa4:	7139                	addi	sp,sp,-64
    80003fa6:	fc06                	sd	ra,56(sp)
    80003fa8:	f822                	sd	s0,48(sp)
    80003faa:	f426                	sd	s1,40(sp)
    80003fac:	f04a                	sd	s2,32(sp)
    80003fae:	ec4e                	sd	s3,24(sp)
    80003fb0:	e852                	sd	s4,16(sp)
    80003fb2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fb4:	04451703          	lh	a4,68(a0)
    80003fb8:	4785                	li	a5,1
    80003fba:	00f71a63          	bne	a4,a5,80003fce <dirlookup+0x2a>
    80003fbe:	892a                	mv	s2,a0
    80003fc0:	89ae                	mv	s3,a1
    80003fc2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc4:	457c                	lw	a5,76(a0)
    80003fc6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fc8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fca:	e79d                	bnez	a5,80003ff8 <dirlookup+0x54>
    80003fcc:	a8a5                	j	80004044 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fce:	00004517          	auipc	a0,0x4
    80003fd2:	6a250513          	addi	a0,a0,1698 # 80008670 <syscalls+0x1c0>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	56a080e7          	jalr	1386(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003fde:	00004517          	auipc	a0,0x4
    80003fe2:	6aa50513          	addi	a0,a0,1706 # 80008688 <syscalls+0x1d8>
    80003fe6:	ffffc097          	auipc	ra,0xffffc
    80003fea:	55a080e7          	jalr	1370(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fee:	24c1                	addiw	s1,s1,16
    80003ff0:	04c92783          	lw	a5,76(s2)
    80003ff4:	04f4f763          	bgeu	s1,a5,80004042 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff8:	4741                	li	a4,16
    80003ffa:	86a6                	mv	a3,s1
    80003ffc:	fc040613          	addi	a2,s0,-64
    80004000:	4581                	li	a1,0
    80004002:	854a                	mv	a0,s2
    80004004:	00000097          	auipc	ra,0x0
    80004008:	d70080e7          	jalr	-656(ra) # 80003d74 <readi>
    8000400c:	47c1                	li	a5,16
    8000400e:	fcf518e3          	bne	a0,a5,80003fde <dirlookup+0x3a>
    if(de.inum == 0)
    80004012:	fc045783          	lhu	a5,-64(s0)
    80004016:	dfe1                	beqz	a5,80003fee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004018:	fc240593          	addi	a1,s0,-62
    8000401c:	854e                	mv	a0,s3
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	f6c080e7          	jalr	-148(ra) # 80003f8a <namecmp>
    80004026:	f561                	bnez	a0,80003fee <dirlookup+0x4a>
      if(poff)
    80004028:	000a0463          	beqz	s4,80004030 <dirlookup+0x8c>
        *poff = off;
    8000402c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004030:	fc045583          	lhu	a1,-64(s0)
    80004034:	00092503          	lw	a0,0(s2)
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	74e080e7          	jalr	1870(ra) # 80003786 <iget>
    80004040:	a011                	j	80004044 <dirlookup+0xa0>
  return 0;
    80004042:	4501                	li	a0,0
}
    80004044:	70e2                	ld	ra,56(sp)
    80004046:	7442                	ld	s0,48(sp)
    80004048:	74a2                	ld	s1,40(sp)
    8000404a:	7902                	ld	s2,32(sp)
    8000404c:	69e2                	ld	s3,24(sp)
    8000404e:	6a42                	ld	s4,16(sp)
    80004050:	6121                	addi	sp,sp,64
    80004052:	8082                	ret

0000000080004054 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004054:	711d                	addi	sp,sp,-96
    80004056:	ec86                	sd	ra,88(sp)
    80004058:	e8a2                	sd	s0,80(sp)
    8000405a:	e4a6                	sd	s1,72(sp)
    8000405c:	e0ca                	sd	s2,64(sp)
    8000405e:	fc4e                	sd	s3,56(sp)
    80004060:	f852                	sd	s4,48(sp)
    80004062:	f456                	sd	s5,40(sp)
    80004064:	f05a                	sd	s6,32(sp)
    80004066:	ec5e                	sd	s7,24(sp)
    80004068:	e862                	sd	s8,16(sp)
    8000406a:	e466                	sd	s9,8(sp)
    8000406c:	e06a                	sd	s10,0(sp)
    8000406e:	1080                	addi	s0,sp,96
    80004070:	84aa                	mv	s1,a0
    80004072:	8b2e                	mv	s6,a1
    80004074:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004076:	00054703          	lbu	a4,0(a0)
    8000407a:	02f00793          	li	a5,47
    8000407e:	02f70363          	beq	a4,a5,800040a4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004082:	ffffe097          	auipc	ra,0xffffe
    80004086:	92a080e7          	jalr	-1750(ra) # 800019ac <myproc>
    8000408a:	15053503          	ld	a0,336(a0)
    8000408e:	00000097          	auipc	ra,0x0
    80004092:	9f4080e7          	jalr	-1548(ra) # 80003a82 <idup>
    80004096:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004098:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    8000409c:	4cb5                	li	s9,13
  len = path - s;
    8000409e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040a0:	4c05                	li	s8,1
    800040a2:	a87d                	j	80004160 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040a4:	4585                	li	a1,1
    800040a6:	4505                	li	a0,1
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	6de080e7          	jalr	1758(ra) # 80003786 <iget>
    800040b0:	8a2a                	mv	s4,a0
    800040b2:	b7dd                	j	80004098 <namex+0x44>
      iunlockput(ip);
    800040b4:	8552                	mv	a0,s4
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	c6c080e7          	jalr	-916(ra) # 80003d22 <iunlockput>
      return 0;
    800040be:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040c0:	8552                	mv	a0,s4
    800040c2:	60e6                	ld	ra,88(sp)
    800040c4:	6446                	ld	s0,80(sp)
    800040c6:	64a6                	ld	s1,72(sp)
    800040c8:	6906                	ld	s2,64(sp)
    800040ca:	79e2                	ld	s3,56(sp)
    800040cc:	7a42                	ld	s4,48(sp)
    800040ce:	7aa2                	ld	s5,40(sp)
    800040d0:	7b02                	ld	s6,32(sp)
    800040d2:	6be2                	ld	s7,24(sp)
    800040d4:	6c42                	ld	s8,16(sp)
    800040d6:	6ca2                	ld	s9,8(sp)
    800040d8:	6d02                	ld	s10,0(sp)
    800040da:	6125                	addi	sp,sp,96
    800040dc:	8082                	ret
      iunlock(ip);
    800040de:	8552                	mv	a0,s4
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	aa2080e7          	jalr	-1374(ra) # 80003b82 <iunlock>
      return ip;
    800040e8:	bfe1                	j	800040c0 <namex+0x6c>
      iunlockput(ip);
    800040ea:	8552                	mv	a0,s4
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	c36080e7          	jalr	-970(ra) # 80003d22 <iunlockput>
      return 0;
    800040f4:	8a4e                	mv	s4,s3
    800040f6:	b7e9                	j	800040c0 <namex+0x6c>
  len = path - s;
    800040f8:	40998633          	sub	a2,s3,s1
    800040fc:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004100:	09acd863          	bge	s9,s10,80004190 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004104:	4639                	li	a2,14
    80004106:	85a6                	mv	a1,s1
    80004108:	8556                	mv	a0,s5
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	c24080e7          	jalr	-988(ra) # 80000d2e <memmove>
    80004112:	84ce                	mv	s1,s3
  while(*path == '/')
    80004114:	0004c783          	lbu	a5,0(s1)
    80004118:	01279763          	bne	a5,s2,80004126 <namex+0xd2>
    path++;
    8000411c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000411e:	0004c783          	lbu	a5,0(s1)
    80004122:	ff278de3          	beq	a5,s2,8000411c <namex+0xc8>
    ilock(ip);
    80004126:	8552                	mv	a0,s4
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	998080e7          	jalr	-1640(ra) # 80003ac0 <ilock>
    if(ip->type != T_DIR){
    80004130:	044a1783          	lh	a5,68(s4)
    80004134:	f98790e3          	bne	a5,s8,800040b4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004138:	000b0563          	beqz	s6,80004142 <namex+0xee>
    8000413c:	0004c783          	lbu	a5,0(s1)
    80004140:	dfd9                	beqz	a5,800040de <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004142:	865e                	mv	a2,s7
    80004144:	85d6                	mv	a1,s5
    80004146:	8552                	mv	a0,s4
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	e5c080e7          	jalr	-420(ra) # 80003fa4 <dirlookup>
    80004150:	89aa                	mv	s3,a0
    80004152:	dd41                	beqz	a0,800040ea <namex+0x96>
    iunlockput(ip);
    80004154:	8552                	mv	a0,s4
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	bcc080e7          	jalr	-1076(ra) # 80003d22 <iunlockput>
    ip = next;
    8000415e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004160:	0004c783          	lbu	a5,0(s1)
    80004164:	01279763          	bne	a5,s2,80004172 <namex+0x11e>
    path++;
    80004168:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000416a:	0004c783          	lbu	a5,0(s1)
    8000416e:	ff278de3          	beq	a5,s2,80004168 <namex+0x114>
  if(*path == 0)
    80004172:	cb9d                	beqz	a5,800041a8 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004174:	0004c783          	lbu	a5,0(s1)
    80004178:	89a6                	mv	s3,s1
  len = path - s;
    8000417a:	8d5e                	mv	s10,s7
    8000417c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000417e:	01278963          	beq	a5,s2,80004190 <namex+0x13c>
    80004182:	dbbd                	beqz	a5,800040f8 <namex+0xa4>
    path++;
    80004184:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004186:	0009c783          	lbu	a5,0(s3)
    8000418a:	ff279ce3          	bne	a5,s2,80004182 <namex+0x12e>
    8000418e:	b7ad                	j	800040f8 <namex+0xa4>
    memmove(name, s, len);
    80004190:	2601                	sext.w	a2,a2
    80004192:	85a6                	mv	a1,s1
    80004194:	8556                	mv	a0,s5
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	b98080e7          	jalr	-1128(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000419e:	9d56                	add	s10,s10,s5
    800041a0:	000d0023          	sb	zero,0(s10)
    800041a4:	84ce                	mv	s1,s3
    800041a6:	b7bd                	j	80004114 <namex+0xc0>
  if(nameiparent){
    800041a8:	f00b0ce3          	beqz	s6,800040c0 <namex+0x6c>
    iput(ip);
    800041ac:	8552                	mv	a0,s4
    800041ae:	00000097          	auipc	ra,0x0
    800041b2:	acc080e7          	jalr	-1332(ra) # 80003c7a <iput>
    return 0;
    800041b6:	4a01                	li	s4,0
    800041b8:	b721                	j	800040c0 <namex+0x6c>

00000000800041ba <dirlink>:
{
    800041ba:	7139                	addi	sp,sp,-64
    800041bc:	fc06                	sd	ra,56(sp)
    800041be:	f822                	sd	s0,48(sp)
    800041c0:	f426                	sd	s1,40(sp)
    800041c2:	f04a                	sd	s2,32(sp)
    800041c4:	ec4e                	sd	s3,24(sp)
    800041c6:	e852                	sd	s4,16(sp)
    800041c8:	0080                	addi	s0,sp,64
    800041ca:	892a                	mv	s2,a0
    800041cc:	8a2e                	mv	s4,a1
    800041ce:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041d0:	4601                	li	a2,0
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	dd2080e7          	jalr	-558(ra) # 80003fa4 <dirlookup>
    800041da:	e93d                	bnez	a0,80004250 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041dc:	04c92483          	lw	s1,76(s2)
    800041e0:	c49d                	beqz	s1,8000420e <dirlink+0x54>
    800041e2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041e4:	4741                	li	a4,16
    800041e6:	86a6                	mv	a3,s1
    800041e8:	fc040613          	addi	a2,s0,-64
    800041ec:	4581                	li	a1,0
    800041ee:	854a                	mv	a0,s2
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	b84080e7          	jalr	-1148(ra) # 80003d74 <readi>
    800041f8:	47c1                	li	a5,16
    800041fa:	06f51163          	bne	a0,a5,8000425c <dirlink+0xa2>
    if(de.inum == 0)
    800041fe:	fc045783          	lhu	a5,-64(s0)
    80004202:	c791                	beqz	a5,8000420e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004204:	24c1                	addiw	s1,s1,16
    80004206:	04c92783          	lw	a5,76(s2)
    8000420a:	fcf4ede3          	bltu	s1,a5,800041e4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000420e:	4639                	li	a2,14
    80004210:	85d2                	mv	a1,s4
    80004212:	fc240513          	addi	a0,s0,-62
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	bc8080e7          	jalr	-1080(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000421e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004222:	4741                	li	a4,16
    80004224:	86a6                	mv	a3,s1
    80004226:	fc040613          	addi	a2,s0,-64
    8000422a:	4581                	li	a1,0
    8000422c:	854a                	mv	a0,s2
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	c3e080e7          	jalr	-962(ra) # 80003e6c <writei>
    80004236:	1541                	addi	a0,a0,-16
    80004238:	00a03533          	snez	a0,a0
    8000423c:	40a00533          	neg	a0,a0
}
    80004240:	70e2                	ld	ra,56(sp)
    80004242:	7442                	ld	s0,48(sp)
    80004244:	74a2                	ld	s1,40(sp)
    80004246:	7902                	ld	s2,32(sp)
    80004248:	69e2                	ld	s3,24(sp)
    8000424a:	6a42                	ld	s4,16(sp)
    8000424c:	6121                	addi	sp,sp,64
    8000424e:	8082                	ret
    iput(ip);
    80004250:	00000097          	auipc	ra,0x0
    80004254:	a2a080e7          	jalr	-1494(ra) # 80003c7a <iput>
    return -1;
    80004258:	557d                	li	a0,-1
    8000425a:	b7dd                	j	80004240 <dirlink+0x86>
      panic("dirlink read");
    8000425c:	00004517          	auipc	a0,0x4
    80004260:	43c50513          	addi	a0,a0,1084 # 80008698 <syscalls+0x1e8>
    80004264:	ffffc097          	auipc	ra,0xffffc
    80004268:	2dc080e7          	jalr	732(ra) # 80000540 <panic>

000000008000426c <namei>:

struct inode*
namei(char *path)
{
    8000426c:	1101                	addi	sp,sp,-32
    8000426e:	ec06                	sd	ra,24(sp)
    80004270:	e822                	sd	s0,16(sp)
    80004272:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004274:	fe040613          	addi	a2,s0,-32
    80004278:	4581                	li	a1,0
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	dda080e7          	jalr	-550(ra) # 80004054 <namex>
}
    80004282:	60e2                	ld	ra,24(sp)
    80004284:	6442                	ld	s0,16(sp)
    80004286:	6105                	addi	sp,sp,32
    80004288:	8082                	ret

000000008000428a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000428a:	1141                	addi	sp,sp,-16
    8000428c:	e406                	sd	ra,8(sp)
    8000428e:	e022                	sd	s0,0(sp)
    80004290:	0800                	addi	s0,sp,16
    80004292:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004294:	4585                	li	a1,1
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	dbe080e7          	jalr	-578(ra) # 80004054 <namex>
}
    8000429e:	60a2                	ld	ra,8(sp)
    800042a0:	6402                	ld	s0,0(sp)
    800042a2:	0141                	addi	sp,sp,16
    800042a4:	8082                	ret

00000000800042a6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042a6:	1101                	addi	sp,sp,-32
    800042a8:	ec06                	sd	ra,24(sp)
    800042aa:	e822                	sd	s0,16(sp)
    800042ac:	e426                	sd	s1,8(sp)
    800042ae:	e04a                	sd	s2,0(sp)
    800042b0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042b2:	0001d917          	auipc	s2,0x1d
    800042b6:	8ee90913          	addi	s2,s2,-1810 # 80020ba0 <log>
    800042ba:	01892583          	lw	a1,24(s2)
    800042be:	02892503          	lw	a0,40(s2)
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	fe6080e7          	jalr	-26(ra) # 800032a8 <bread>
    800042ca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042cc:	02c92683          	lw	a3,44(s2)
    800042d0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042d2:	02d05863          	blez	a3,80004302 <write_head+0x5c>
    800042d6:	0001d797          	auipc	a5,0x1d
    800042da:	8fa78793          	addi	a5,a5,-1798 # 80020bd0 <log+0x30>
    800042de:	05c50713          	addi	a4,a0,92
    800042e2:	36fd                	addiw	a3,a3,-1
    800042e4:	02069613          	slli	a2,a3,0x20
    800042e8:	01e65693          	srli	a3,a2,0x1e
    800042ec:	0001d617          	auipc	a2,0x1d
    800042f0:	8e860613          	addi	a2,a2,-1816 # 80020bd4 <log+0x34>
    800042f4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042f6:	4390                	lw	a2,0(a5)
    800042f8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	0791                	addi	a5,a5,4
    800042fc:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800042fe:	fed79ce3          	bne	a5,a3,800042f6 <write_head+0x50>
  }
  bwrite(buf);
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	096080e7          	jalr	150(ra) # 8000339a <bwrite>
  brelse(buf);
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	0ca080e7          	jalr	202(ra) # 800033d8 <brelse>
}
    80004316:	60e2                	ld	ra,24(sp)
    80004318:	6442                	ld	s0,16(sp)
    8000431a:	64a2                	ld	s1,8(sp)
    8000431c:	6902                	ld	s2,0(sp)
    8000431e:	6105                	addi	sp,sp,32
    80004320:	8082                	ret

0000000080004322 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004322:	0001d797          	auipc	a5,0x1d
    80004326:	8aa7a783          	lw	a5,-1878(a5) # 80020bcc <log+0x2c>
    8000432a:	0af05d63          	blez	a5,800043e4 <install_trans+0xc2>
{
    8000432e:	7139                	addi	sp,sp,-64
    80004330:	fc06                	sd	ra,56(sp)
    80004332:	f822                	sd	s0,48(sp)
    80004334:	f426                	sd	s1,40(sp)
    80004336:	f04a                	sd	s2,32(sp)
    80004338:	ec4e                	sd	s3,24(sp)
    8000433a:	e852                	sd	s4,16(sp)
    8000433c:	e456                	sd	s5,8(sp)
    8000433e:	e05a                	sd	s6,0(sp)
    80004340:	0080                	addi	s0,sp,64
    80004342:	8b2a                	mv	s6,a0
    80004344:	0001da97          	auipc	s5,0x1d
    80004348:	88ca8a93          	addi	s5,s5,-1908 # 80020bd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000434e:	0001d997          	auipc	s3,0x1d
    80004352:	85298993          	addi	s3,s3,-1966 # 80020ba0 <log>
    80004356:	a00d                	j	80004378 <install_trans+0x56>
    brelse(lbuf);
    80004358:	854a                	mv	a0,s2
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	07e080e7          	jalr	126(ra) # 800033d8 <brelse>
    brelse(dbuf);
    80004362:	8526                	mv	a0,s1
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	074080e7          	jalr	116(ra) # 800033d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000436c:	2a05                	addiw	s4,s4,1
    8000436e:	0a91                	addi	s5,s5,4
    80004370:	02c9a783          	lw	a5,44(s3)
    80004374:	04fa5e63          	bge	s4,a5,800043d0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004378:	0189a583          	lw	a1,24(s3)
    8000437c:	014585bb          	addw	a1,a1,s4
    80004380:	2585                	addiw	a1,a1,1
    80004382:	0289a503          	lw	a0,40(s3)
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	f22080e7          	jalr	-222(ra) # 800032a8 <bread>
    8000438e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004390:	000aa583          	lw	a1,0(s5)
    80004394:	0289a503          	lw	a0,40(s3)
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	f10080e7          	jalr	-240(ra) # 800032a8 <bread>
    800043a0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043a2:	40000613          	li	a2,1024
    800043a6:	05890593          	addi	a1,s2,88
    800043aa:	05850513          	addi	a0,a0,88
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	980080e7          	jalr	-1664(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043b6:	8526                	mv	a0,s1
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	fe2080e7          	jalr	-30(ra) # 8000339a <bwrite>
    if(recovering == 0)
    800043c0:	f80b1ce3          	bnez	s6,80004358 <install_trans+0x36>
      bunpin(dbuf);
    800043c4:	8526                	mv	a0,s1
    800043c6:	fffff097          	auipc	ra,0xfffff
    800043ca:	0ec080e7          	jalr	236(ra) # 800034b2 <bunpin>
    800043ce:	b769                	j	80004358 <install_trans+0x36>
}
    800043d0:	70e2                	ld	ra,56(sp)
    800043d2:	7442                	ld	s0,48(sp)
    800043d4:	74a2                	ld	s1,40(sp)
    800043d6:	7902                	ld	s2,32(sp)
    800043d8:	69e2                	ld	s3,24(sp)
    800043da:	6a42                	ld	s4,16(sp)
    800043dc:	6aa2                	ld	s5,8(sp)
    800043de:	6b02                	ld	s6,0(sp)
    800043e0:	6121                	addi	sp,sp,64
    800043e2:	8082                	ret
    800043e4:	8082                	ret

00000000800043e6 <initlog>:
{
    800043e6:	7179                	addi	sp,sp,-48
    800043e8:	f406                	sd	ra,40(sp)
    800043ea:	f022                	sd	s0,32(sp)
    800043ec:	ec26                	sd	s1,24(sp)
    800043ee:	e84a                	sd	s2,16(sp)
    800043f0:	e44e                	sd	s3,8(sp)
    800043f2:	1800                	addi	s0,sp,48
    800043f4:	892a                	mv	s2,a0
    800043f6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043f8:	0001c497          	auipc	s1,0x1c
    800043fc:	7a848493          	addi	s1,s1,1960 # 80020ba0 <log>
    80004400:	00004597          	auipc	a1,0x4
    80004404:	2a858593          	addi	a1,a1,680 # 800086a8 <syscalls+0x1f8>
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	73c080e7          	jalr	1852(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004412:	0149a583          	lw	a1,20(s3)
    80004416:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004418:	0109a783          	lw	a5,16(s3)
    8000441c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000441e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004422:	854a                	mv	a0,s2
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	e84080e7          	jalr	-380(ra) # 800032a8 <bread>
  log.lh.n = lh->n;
    8000442c:	4d34                	lw	a3,88(a0)
    8000442e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004430:	02d05663          	blez	a3,8000445c <initlog+0x76>
    80004434:	05c50793          	addi	a5,a0,92
    80004438:	0001c717          	auipc	a4,0x1c
    8000443c:	79870713          	addi	a4,a4,1944 # 80020bd0 <log+0x30>
    80004440:	36fd                	addiw	a3,a3,-1
    80004442:	02069613          	slli	a2,a3,0x20
    80004446:	01e65693          	srli	a3,a2,0x1e
    8000444a:	06050613          	addi	a2,a0,96
    8000444e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004450:	4390                	lw	a2,0(a5)
    80004452:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004454:	0791                	addi	a5,a5,4
    80004456:	0711                	addi	a4,a4,4
    80004458:	fed79ce3          	bne	a5,a3,80004450 <initlog+0x6a>
  brelse(buf);
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	f7c080e7          	jalr	-132(ra) # 800033d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004464:	4505                	li	a0,1
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	ebc080e7          	jalr	-324(ra) # 80004322 <install_trans>
  log.lh.n = 0;
    8000446e:	0001c797          	auipc	a5,0x1c
    80004472:	7407af23          	sw	zero,1886(a5) # 80020bcc <log+0x2c>
  write_head(); // clear the log
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	e30080e7          	jalr	-464(ra) # 800042a6 <write_head>
}
    8000447e:	70a2                	ld	ra,40(sp)
    80004480:	7402                	ld	s0,32(sp)
    80004482:	64e2                	ld	s1,24(sp)
    80004484:	6942                	ld	s2,16(sp)
    80004486:	69a2                	ld	s3,8(sp)
    80004488:	6145                	addi	sp,sp,48
    8000448a:	8082                	ret

000000008000448c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000448c:	1101                	addi	sp,sp,-32
    8000448e:	ec06                	sd	ra,24(sp)
    80004490:	e822                	sd	s0,16(sp)
    80004492:	e426                	sd	s1,8(sp)
    80004494:	e04a                	sd	s2,0(sp)
    80004496:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004498:	0001c517          	auipc	a0,0x1c
    8000449c:	70850513          	addi	a0,a0,1800 # 80020ba0 <log>
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	736080e7          	jalr	1846(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800044a8:	0001c497          	auipc	s1,0x1c
    800044ac:	6f848493          	addi	s1,s1,1784 # 80020ba0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044b0:	4979                	li	s2,30
    800044b2:	a039                	j	800044c0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044b4:	85a6                	mv	a1,s1
    800044b6:	8526                	mv	a0,s1
    800044b8:	ffffe097          	auipc	ra,0xffffe
    800044bc:	b9c080e7          	jalr	-1124(ra) # 80002054 <sleep>
    if(log.committing){
    800044c0:	50dc                	lw	a5,36(s1)
    800044c2:	fbed                	bnez	a5,800044b4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044c4:	5098                	lw	a4,32(s1)
    800044c6:	2705                	addiw	a4,a4,1
    800044c8:	0007069b          	sext.w	a3,a4
    800044cc:	0027179b          	slliw	a5,a4,0x2
    800044d0:	9fb9                	addw	a5,a5,a4
    800044d2:	0017979b          	slliw	a5,a5,0x1
    800044d6:	54d8                	lw	a4,44(s1)
    800044d8:	9fb9                	addw	a5,a5,a4
    800044da:	00f95963          	bge	s2,a5,800044ec <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044de:	85a6                	mv	a1,s1
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffe097          	auipc	ra,0xffffe
    800044e6:	b72080e7          	jalr	-1166(ra) # 80002054 <sleep>
    800044ea:	bfd9                	j	800044c0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044ec:	0001c517          	auipc	a0,0x1c
    800044f0:	6b450513          	addi	a0,a0,1716 # 80020ba0 <log>
    800044f4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	794080e7          	jalr	1940(ra) # 80000c8a <release>
      break;
    }
  }
}
    800044fe:	60e2                	ld	ra,24(sp)
    80004500:	6442                	ld	s0,16(sp)
    80004502:	64a2                	ld	s1,8(sp)
    80004504:	6902                	ld	s2,0(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000450a:	7139                	addi	sp,sp,-64
    8000450c:	fc06                	sd	ra,56(sp)
    8000450e:	f822                	sd	s0,48(sp)
    80004510:	f426                	sd	s1,40(sp)
    80004512:	f04a                	sd	s2,32(sp)
    80004514:	ec4e                	sd	s3,24(sp)
    80004516:	e852                	sd	s4,16(sp)
    80004518:	e456                	sd	s5,8(sp)
    8000451a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000451c:	0001c497          	auipc	s1,0x1c
    80004520:	68448493          	addi	s1,s1,1668 # 80020ba0 <log>
    80004524:	8526                	mv	a0,s1
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6b0080e7          	jalr	1712(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000452e:	509c                	lw	a5,32(s1)
    80004530:	37fd                	addiw	a5,a5,-1
    80004532:	0007891b          	sext.w	s2,a5
    80004536:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004538:	50dc                	lw	a5,36(s1)
    8000453a:	e7b9                	bnez	a5,80004588 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000453c:	04091e63          	bnez	s2,80004598 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004540:	0001c497          	auipc	s1,0x1c
    80004544:	66048493          	addi	s1,s1,1632 # 80020ba0 <log>
    80004548:	4785                	li	a5,1
    8000454a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000454c:	8526                	mv	a0,s1
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	73c080e7          	jalr	1852(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004556:	54dc                	lw	a5,44(s1)
    80004558:	06f04763          	bgtz	a5,800045c6 <end_op+0xbc>
    acquire(&log.lock);
    8000455c:	0001c497          	auipc	s1,0x1c
    80004560:	64448493          	addi	s1,s1,1604 # 80020ba0 <log>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	670080e7          	jalr	1648(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000456e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004572:	8526                	mv	a0,s1
    80004574:	ffffe097          	auipc	ra,0xffffe
    80004578:	b44080e7          	jalr	-1212(ra) # 800020b8 <wakeup>
    release(&log.lock);
    8000457c:	8526                	mv	a0,s1
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	70c080e7          	jalr	1804(ra) # 80000c8a <release>
}
    80004586:	a03d                	j	800045b4 <end_op+0xaa>
    panic("log.committing");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	12850513          	addi	a0,a0,296 # 800086b0 <syscalls+0x200>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fb0080e7          	jalr	-80(ra) # 80000540 <panic>
    wakeup(&log);
    80004598:	0001c497          	auipc	s1,0x1c
    8000459c:	60848493          	addi	s1,s1,1544 # 80020ba0 <log>
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffe097          	auipc	ra,0xffffe
    800045a6:	b16080e7          	jalr	-1258(ra) # 800020b8 <wakeup>
  release(&log.lock);
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	6de080e7          	jalr	1758(ra) # 80000c8a <release>
}
    800045b4:	70e2                	ld	ra,56(sp)
    800045b6:	7442                	ld	s0,48(sp)
    800045b8:	74a2                	ld	s1,40(sp)
    800045ba:	7902                	ld	s2,32(sp)
    800045bc:	69e2                	ld	s3,24(sp)
    800045be:	6a42                	ld	s4,16(sp)
    800045c0:	6aa2                	ld	s5,8(sp)
    800045c2:	6121                	addi	sp,sp,64
    800045c4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c6:	0001ca97          	auipc	s5,0x1c
    800045ca:	60aa8a93          	addi	s5,s5,1546 # 80020bd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ce:	0001ca17          	auipc	s4,0x1c
    800045d2:	5d2a0a13          	addi	s4,s4,1490 # 80020ba0 <log>
    800045d6:	018a2583          	lw	a1,24(s4)
    800045da:	012585bb          	addw	a1,a1,s2
    800045de:	2585                	addiw	a1,a1,1
    800045e0:	028a2503          	lw	a0,40(s4)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	cc4080e7          	jalr	-828(ra) # 800032a8 <bread>
    800045ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045ee:	000aa583          	lw	a1,0(s5)
    800045f2:	028a2503          	lw	a0,40(s4)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	cb2080e7          	jalr	-846(ra) # 800032a8 <bread>
    800045fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004600:	40000613          	li	a2,1024
    80004604:	05850593          	addi	a1,a0,88
    80004608:	05848513          	addi	a0,s1,88
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	722080e7          	jalr	1826(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	d84080e7          	jalr	-636(ra) # 8000339a <bwrite>
    brelse(from);
    8000461e:	854e                	mv	a0,s3
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	db8080e7          	jalr	-584(ra) # 800033d8 <brelse>
    brelse(to);
    80004628:	8526                	mv	a0,s1
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	dae080e7          	jalr	-594(ra) # 800033d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004632:	2905                	addiw	s2,s2,1
    80004634:	0a91                	addi	s5,s5,4
    80004636:	02ca2783          	lw	a5,44(s4)
    8000463a:	f8f94ee3          	blt	s2,a5,800045d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	c68080e7          	jalr	-920(ra) # 800042a6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004646:	4501                	li	a0,0
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	cda080e7          	jalr	-806(ra) # 80004322 <install_trans>
    log.lh.n = 0;
    80004650:	0001c797          	auipc	a5,0x1c
    80004654:	5607ae23          	sw	zero,1404(a5) # 80020bcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	c4e080e7          	jalr	-946(ra) # 800042a6 <write_head>
    80004660:	bdf5                	j	8000455c <end_op+0x52>

0000000080004662 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004662:	1101                	addi	sp,sp,-32
    80004664:	ec06                	sd	ra,24(sp)
    80004666:	e822                	sd	s0,16(sp)
    80004668:	e426                	sd	s1,8(sp)
    8000466a:	e04a                	sd	s2,0(sp)
    8000466c:	1000                	addi	s0,sp,32
    8000466e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004670:	0001c917          	auipc	s2,0x1c
    80004674:	53090913          	addi	s2,s2,1328 # 80020ba0 <log>
    80004678:	854a                	mv	a0,s2
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	55c080e7          	jalr	1372(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004682:	02c92603          	lw	a2,44(s2)
    80004686:	47f5                	li	a5,29
    80004688:	06c7c563          	blt	a5,a2,800046f2 <log_write+0x90>
    8000468c:	0001c797          	auipc	a5,0x1c
    80004690:	5307a783          	lw	a5,1328(a5) # 80020bbc <log+0x1c>
    80004694:	37fd                	addiw	a5,a5,-1
    80004696:	04f65e63          	bge	a2,a5,800046f2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000469a:	0001c797          	auipc	a5,0x1c
    8000469e:	5267a783          	lw	a5,1318(a5) # 80020bc0 <log+0x20>
    800046a2:	06f05063          	blez	a5,80004702 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046a6:	4781                	li	a5,0
    800046a8:	06c05563          	blez	a2,80004712 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ac:	44cc                	lw	a1,12(s1)
    800046ae:	0001c717          	auipc	a4,0x1c
    800046b2:	52270713          	addi	a4,a4,1314 # 80020bd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046b6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046b8:	4314                	lw	a3,0(a4)
    800046ba:	04b68c63          	beq	a3,a1,80004712 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046be:	2785                	addiw	a5,a5,1
    800046c0:	0711                	addi	a4,a4,4
    800046c2:	fef61be3          	bne	a2,a5,800046b8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046c6:	0621                	addi	a2,a2,8
    800046c8:	060a                	slli	a2,a2,0x2
    800046ca:	0001c797          	auipc	a5,0x1c
    800046ce:	4d678793          	addi	a5,a5,1238 # 80020ba0 <log>
    800046d2:	97b2                	add	a5,a5,a2
    800046d4:	44d8                	lw	a4,12(s1)
    800046d6:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	d9c080e7          	jalr	-612(ra) # 80003476 <bpin>
    log.lh.n++;
    800046e2:	0001c717          	auipc	a4,0x1c
    800046e6:	4be70713          	addi	a4,a4,1214 # 80020ba0 <log>
    800046ea:	575c                	lw	a5,44(a4)
    800046ec:	2785                	addiw	a5,a5,1
    800046ee:	d75c                	sw	a5,44(a4)
    800046f0:	a82d                	j	8000472a <log_write+0xc8>
    panic("too big a transaction");
    800046f2:	00004517          	auipc	a0,0x4
    800046f6:	fce50513          	addi	a0,a0,-50 # 800086c0 <syscalls+0x210>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	e46080e7          	jalr	-442(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004702:	00004517          	auipc	a0,0x4
    80004706:	fd650513          	addi	a0,a0,-42 # 800086d8 <syscalls+0x228>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	e36080e7          	jalr	-458(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004712:	00878693          	addi	a3,a5,8
    80004716:	068a                	slli	a3,a3,0x2
    80004718:	0001c717          	auipc	a4,0x1c
    8000471c:	48870713          	addi	a4,a4,1160 # 80020ba0 <log>
    80004720:	9736                	add	a4,a4,a3
    80004722:	44d4                	lw	a3,12(s1)
    80004724:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004726:	faf609e3          	beq	a2,a5,800046d8 <log_write+0x76>
  }
  release(&log.lock);
    8000472a:	0001c517          	auipc	a0,0x1c
    8000472e:	47650513          	addi	a0,a0,1142 # 80020ba0 <log>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	558080e7          	jalr	1368(ra) # 80000c8a <release>
}
    8000473a:	60e2                	ld	ra,24(sp)
    8000473c:	6442                	ld	s0,16(sp)
    8000473e:	64a2                	ld	s1,8(sp)
    80004740:	6902                	ld	s2,0(sp)
    80004742:	6105                	addi	sp,sp,32
    80004744:	8082                	ret

0000000080004746 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004746:	1101                	addi	sp,sp,-32
    80004748:	ec06                	sd	ra,24(sp)
    8000474a:	e822                	sd	s0,16(sp)
    8000474c:	e426                	sd	s1,8(sp)
    8000474e:	e04a                	sd	s2,0(sp)
    80004750:	1000                	addi	s0,sp,32
    80004752:	84aa                	mv	s1,a0
    80004754:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004756:	00004597          	auipc	a1,0x4
    8000475a:	fa258593          	addi	a1,a1,-94 # 800086f8 <syscalls+0x248>
    8000475e:	0521                	addi	a0,a0,8
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	3e6080e7          	jalr	998(ra) # 80000b46 <initlock>
  lk->name = name;
    80004768:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000476c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004770:	0204a423          	sw	zero,40(s1)
}
    80004774:	60e2                	ld	ra,24(sp)
    80004776:	6442                	ld	s0,16(sp)
    80004778:	64a2                	ld	s1,8(sp)
    8000477a:	6902                	ld	s2,0(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret

0000000080004780 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004780:	1101                	addi	sp,sp,-32
    80004782:	ec06                	sd	ra,24(sp)
    80004784:	e822                	sd	s0,16(sp)
    80004786:	e426                	sd	s1,8(sp)
    80004788:	e04a                	sd	s2,0(sp)
    8000478a:	1000                	addi	s0,sp,32
    8000478c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000478e:	00850913          	addi	s2,a0,8
    80004792:	854a                	mv	a0,s2
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	442080e7          	jalr	1090(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000479c:	409c                	lw	a5,0(s1)
    8000479e:	cb89                	beqz	a5,800047b0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047a0:	85ca                	mv	a1,s2
    800047a2:	8526                	mv	a0,s1
    800047a4:	ffffe097          	auipc	ra,0xffffe
    800047a8:	8b0080e7          	jalr	-1872(ra) # 80002054 <sleep>
  while (lk->locked) {
    800047ac:	409c                	lw	a5,0(s1)
    800047ae:	fbed                	bnez	a5,800047a0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047b0:	4785                	li	a5,1
    800047b2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047b4:	ffffd097          	auipc	ra,0xffffd
    800047b8:	1f8080e7          	jalr	504(ra) # 800019ac <myproc>
    800047bc:	591c                	lw	a5,48(a0)
    800047be:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047c0:	854a                	mv	a0,s2
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4c8080e7          	jalr	1224(ra) # 80000c8a <release>
}
    800047ca:	60e2                	ld	ra,24(sp)
    800047cc:	6442                	ld	s0,16(sp)
    800047ce:	64a2                	ld	s1,8(sp)
    800047d0:	6902                	ld	s2,0(sp)
    800047d2:	6105                	addi	sp,sp,32
    800047d4:	8082                	ret

00000000800047d6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047d6:	1101                	addi	sp,sp,-32
    800047d8:	ec06                	sd	ra,24(sp)
    800047da:	e822                	sd	s0,16(sp)
    800047dc:	e426                	sd	s1,8(sp)
    800047de:	e04a                	sd	s2,0(sp)
    800047e0:	1000                	addi	s0,sp,32
    800047e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047e4:	00850913          	addi	s2,a0,8
    800047e8:	854a                	mv	a0,s2
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	3ec080e7          	jalr	1004(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800047f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047f6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047fa:	8526                	mv	a0,s1
    800047fc:	ffffe097          	auipc	ra,0xffffe
    80004800:	8bc080e7          	jalr	-1860(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    80004804:	854a                	mv	a0,s2
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	484080e7          	jalr	1156(ra) # 80000c8a <release>
}
    8000480e:	60e2                	ld	ra,24(sp)
    80004810:	6442                	ld	s0,16(sp)
    80004812:	64a2                	ld	s1,8(sp)
    80004814:	6902                	ld	s2,0(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000481a:	7179                	addi	sp,sp,-48
    8000481c:	f406                	sd	ra,40(sp)
    8000481e:	f022                	sd	s0,32(sp)
    80004820:	ec26                	sd	s1,24(sp)
    80004822:	e84a                	sd	s2,16(sp)
    80004824:	e44e                	sd	s3,8(sp)
    80004826:	1800                	addi	s0,sp,48
    80004828:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000482a:	00850913          	addi	s2,a0,8
    8000482e:	854a                	mv	a0,s2
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	3a6080e7          	jalr	934(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004838:	409c                	lw	a5,0(s1)
    8000483a:	ef99                	bnez	a5,80004858 <holdingsleep+0x3e>
    8000483c:	4481                	li	s1,0
  release(&lk->lk);
    8000483e:	854a                	mv	a0,s2
    80004840:	ffffc097          	auipc	ra,0xffffc
    80004844:	44a080e7          	jalr	1098(ra) # 80000c8a <release>
  return r;
}
    80004848:	8526                	mv	a0,s1
    8000484a:	70a2                	ld	ra,40(sp)
    8000484c:	7402                	ld	s0,32(sp)
    8000484e:	64e2                	ld	s1,24(sp)
    80004850:	6942                	ld	s2,16(sp)
    80004852:	69a2                	ld	s3,8(sp)
    80004854:	6145                	addi	sp,sp,48
    80004856:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004858:	0284a983          	lw	s3,40(s1)
    8000485c:	ffffd097          	auipc	ra,0xffffd
    80004860:	150080e7          	jalr	336(ra) # 800019ac <myproc>
    80004864:	5904                	lw	s1,48(a0)
    80004866:	413484b3          	sub	s1,s1,s3
    8000486a:	0014b493          	seqz	s1,s1
    8000486e:	bfc1                	j	8000483e <holdingsleep+0x24>

0000000080004870 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004870:	1141                	addi	sp,sp,-16
    80004872:	e406                	sd	ra,8(sp)
    80004874:	e022                	sd	s0,0(sp)
    80004876:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004878:	00004597          	auipc	a1,0x4
    8000487c:	e9058593          	addi	a1,a1,-368 # 80008708 <syscalls+0x258>
    80004880:	0001c517          	auipc	a0,0x1c
    80004884:	46850513          	addi	a0,a0,1128 # 80020ce8 <ftable>
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	2be080e7          	jalr	702(ra) # 80000b46 <initlock>
}
    80004890:	60a2                	ld	ra,8(sp)
    80004892:	6402                	ld	s0,0(sp)
    80004894:	0141                	addi	sp,sp,16
    80004896:	8082                	ret

0000000080004898 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048a2:	0001c517          	auipc	a0,0x1c
    800048a6:	44650513          	addi	a0,a0,1094 # 80020ce8 <ftable>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	32c080e7          	jalr	812(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048b2:	0001c497          	auipc	s1,0x1c
    800048b6:	44e48493          	addi	s1,s1,1102 # 80020d00 <ftable+0x18>
    800048ba:	0001d717          	auipc	a4,0x1d
    800048be:	3e670713          	addi	a4,a4,998 # 80021ca0 <disk>
    if(f->ref == 0){
    800048c2:	40dc                	lw	a5,4(s1)
    800048c4:	cf99                	beqz	a5,800048e2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048c6:	02848493          	addi	s1,s1,40
    800048ca:	fee49ce3          	bne	s1,a4,800048c2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048ce:	0001c517          	auipc	a0,0x1c
    800048d2:	41a50513          	addi	a0,a0,1050 # 80020ce8 <ftable>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	3b4080e7          	jalr	948(ra) # 80000c8a <release>
  return 0;
    800048de:	4481                	li	s1,0
    800048e0:	a819                	j	800048f6 <filealloc+0x5e>
      f->ref = 1;
    800048e2:	4785                	li	a5,1
    800048e4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048e6:	0001c517          	auipc	a0,0x1c
    800048ea:	40250513          	addi	a0,a0,1026 # 80020ce8 <ftable>
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	39c080e7          	jalr	924(ra) # 80000c8a <release>
}
    800048f6:	8526                	mv	a0,s1
    800048f8:	60e2                	ld	ra,24(sp)
    800048fa:	6442                	ld	s0,16(sp)
    800048fc:	64a2                	ld	s1,8(sp)
    800048fe:	6105                	addi	sp,sp,32
    80004900:	8082                	ret

0000000080004902 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004902:	1101                	addi	sp,sp,-32
    80004904:	ec06                	sd	ra,24(sp)
    80004906:	e822                	sd	s0,16(sp)
    80004908:	e426                	sd	s1,8(sp)
    8000490a:	1000                	addi	s0,sp,32
    8000490c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000490e:	0001c517          	auipc	a0,0x1c
    80004912:	3da50513          	addi	a0,a0,986 # 80020ce8 <ftable>
    80004916:	ffffc097          	auipc	ra,0xffffc
    8000491a:	2c0080e7          	jalr	704(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000491e:	40dc                	lw	a5,4(s1)
    80004920:	02f05263          	blez	a5,80004944 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004924:	2785                	addiw	a5,a5,1
    80004926:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004928:	0001c517          	auipc	a0,0x1c
    8000492c:	3c050513          	addi	a0,a0,960 # 80020ce8 <ftable>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	35a080e7          	jalr	858(ra) # 80000c8a <release>
  return f;
}
    80004938:	8526                	mv	a0,s1
    8000493a:	60e2                	ld	ra,24(sp)
    8000493c:	6442                	ld	s0,16(sp)
    8000493e:	64a2                	ld	s1,8(sp)
    80004940:	6105                	addi	sp,sp,32
    80004942:	8082                	ret
    panic("filedup");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	dcc50513          	addi	a0,a0,-564 # 80008710 <syscalls+0x260>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bf4080e7          	jalr	-1036(ra) # 80000540 <panic>

0000000080004954 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004954:	7139                	addi	sp,sp,-64
    80004956:	fc06                	sd	ra,56(sp)
    80004958:	f822                	sd	s0,48(sp)
    8000495a:	f426                	sd	s1,40(sp)
    8000495c:	f04a                	sd	s2,32(sp)
    8000495e:	ec4e                	sd	s3,24(sp)
    80004960:	e852                	sd	s4,16(sp)
    80004962:	e456                	sd	s5,8(sp)
    80004964:	0080                	addi	s0,sp,64
    80004966:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004968:	0001c517          	auipc	a0,0x1c
    8000496c:	38050513          	addi	a0,a0,896 # 80020ce8 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	266080e7          	jalr	614(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004978:	40dc                	lw	a5,4(s1)
    8000497a:	06f05163          	blez	a5,800049dc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000497e:	37fd                	addiw	a5,a5,-1
    80004980:	0007871b          	sext.w	a4,a5
    80004984:	c0dc                	sw	a5,4(s1)
    80004986:	06e04363          	bgtz	a4,800049ec <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000498a:	0004a903          	lw	s2,0(s1)
    8000498e:	0094ca83          	lbu	s5,9(s1)
    80004992:	0104ba03          	ld	s4,16(s1)
    80004996:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000499a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000499e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049a2:	0001c517          	auipc	a0,0x1c
    800049a6:	34650513          	addi	a0,a0,838 # 80020ce8 <ftable>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	2e0080e7          	jalr	736(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049b2:	4785                	li	a5,1
    800049b4:	04f90d63          	beq	s2,a5,80004a0e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049b8:	3979                	addiw	s2,s2,-2
    800049ba:	4785                	li	a5,1
    800049bc:	0527e063          	bltu	a5,s2,800049fc <fileclose+0xa8>
    begin_op();
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	acc080e7          	jalr	-1332(ra) # 8000448c <begin_op>
    iput(ff.ip);
    800049c8:	854e                	mv	a0,s3
    800049ca:	fffff097          	auipc	ra,0xfffff
    800049ce:	2b0080e7          	jalr	688(ra) # 80003c7a <iput>
    end_op();
    800049d2:	00000097          	auipc	ra,0x0
    800049d6:	b38080e7          	jalr	-1224(ra) # 8000450a <end_op>
    800049da:	a00d                	j	800049fc <fileclose+0xa8>
    panic("fileclose");
    800049dc:	00004517          	auipc	a0,0x4
    800049e0:	d3c50513          	addi	a0,a0,-708 # 80008718 <syscalls+0x268>
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	b5c080e7          	jalr	-1188(ra) # 80000540 <panic>
    release(&ftable.lock);
    800049ec:	0001c517          	auipc	a0,0x1c
    800049f0:	2fc50513          	addi	a0,a0,764 # 80020ce8 <ftable>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	296080e7          	jalr	662(ra) # 80000c8a <release>
  }
}
    800049fc:	70e2                	ld	ra,56(sp)
    800049fe:	7442                	ld	s0,48(sp)
    80004a00:	74a2                	ld	s1,40(sp)
    80004a02:	7902                	ld	s2,32(sp)
    80004a04:	69e2                	ld	s3,24(sp)
    80004a06:	6a42                	ld	s4,16(sp)
    80004a08:	6aa2                	ld	s5,8(sp)
    80004a0a:	6121                	addi	sp,sp,64
    80004a0c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a0e:	85d6                	mv	a1,s5
    80004a10:	8552                	mv	a0,s4
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	34c080e7          	jalr	844(ra) # 80004d5e <pipeclose>
    80004a1a:	b7cd                	j	800049fc <fileclose+0xa8>

0000000080004a1c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a1c:	715d                	addi	sp,sp,-80
    80004a1e:	e486                	sd	ra,72(sp)
    80004a20:	e0a2                	sd	s0,64(sp)
    80004a22:	fc26                	sd	s1,56(sp)
    80004a24:	f84a                	sd	s2,48(sp)
    80004a26:	f44e                	sd	s3,40(sp)
    80004a28:	0880                	addi	s0,sp,80
    80004a2a:	84aa                	mv	s1,a0
    80004a2c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a2e:	ffffd097          	auipc	ra,0xffffd
    80004a32:	f7e080e7          	jalr	-130(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a36:	409c                	lw	a5,0(s1)
    80004a38:	37f9                	addiw	a5,a5,-2
    80004a3a:	4705                	li	a4,1
    80004a3c:	04f76763          	bltu	a4,a5,80004a8a <filestat+0x6e>
    80004a40:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a42:	6c88                	ld	a0,24(s1)
    80004a44:	fffff097          	auipc	ra,0xfffff
    80004a48:	07c080e7          	jalr	124(ra) # 80003ac0 <ilock>
    stati(f->ip, &st);
    80004a4c:	fb840593          	addi	a1,s0,-72
    80004a50:	6c88                	ld	a0,24(s1)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	2f8080e7          	jalr	760(ra) # 80003d4a <stati>
    iunlock(f->ip);
    80004a5a:	6c88                	ld	a0,24(s1)
    80004a5c:	fffff097          	auipc	ra,0xfffff
    80004a60:	126080e7          	jalr	294(ra) # 80003b82 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a64:	46e1                	li	a3,24
    80004a66:	fb840613          	addi	a2,s0,-72
    80004a6a:	85ce                	mv	a1,s3
    80004a6c:	05093503          	ld	a0,80(s2)
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	bfc080e7          	jalr	-1028(ra) # 8000166c <copyout>
    80004a78:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a7c:	60a6                	ld	ra,72(sp)
    80004a7e:	6406                	ld	s0,64(sp)
    80004a80:	74e2                	ld	s1,56(sp)
    80004a82:	7942                	ld	s2,48(sp)
    80004a84:	79a2                	ld	s3,40(sp)
    80004a86:	6161                	addi	sp,sp,80
    80004a88:	8082                	ret
  return -1;
    80004a8a:	557d                	li	a0,-1
    80004a8c:	bfc5                	j	80004a7c <filestat+0x60>

0000000080004a8e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a8e:	7179                	addi	sp,sp,-48
    80004a90:	f406                	sd	ra,40(sp)
    80004a92:	f022                	sd	s0,32(sp)
    80004a94:	ec26                	sd	s1,24(sp)
    80004a96:	e84a                	sd	s2,16(sp)
    80004a98:	e44e                	sd	s3,8(sp)
    80004a9a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a9c:	00854783          	lbu	a5,8(a0)
    80004aa0:	c3d5                	beqz	a5,80004b44 <fileread+0xb6>
    80004aa2:	84aa                	mv	s1,a0
    80004aa4:	89ae                	mv	s3,a1
    80004aa6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004aa8:	411c                	lw	a5,0(a0)
    80004aaa:	4705                	li	a4,1
    80004aac:	04e78963          	beq	a5,a4,80004afe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ab0:	470d                	li	a4,3
    80004ab2:	04e78d63          	beq	a5,a4,80004b0c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ab6:	4709                	li	a4,2
    80004ab8:	06e79e63          	bne	a5,a4,80004b34 <fileread+0xa6>
    ilock(f->ip);
    80004abc:	6d08                	ld	a0,24(a0)
    80004abe:	fffff097          	auipc	ra,0xfffff
    80004ac2:	002080e7          	jalr	2(ra) # 80003ac0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ac6:	874a                	mv	a4,s2
    80004ac8:	5094                	lw	a3,32(s1)
    80004aca:	864e                	mv	a2,s3
    80004acc:	4585                	li	a1,1
    80004ace:	6c88                	ld	a0,24(s1)
    80004ad0:	fffff097          	auipc	ra,0xfffff
    80004ad4:	2a4080e7          	jalr	676(ra) # 80003d74 <readi>
    80004ad8:	892a                	mv	s2,a0
    80004ada:	00a05563          	blez	a0,80004ae4 <fileread+0x56>
      f->off += r;
    80004ade:	509c                	lw	a5,32(s1)
    80004ae0:	9fa9                	addw	a5,a5,a0
    80004ae2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ae4:	6c88                	ld	a0,24(s1)
    80004ae6:	fffff097          	auipc	ra,0xfffff
    80004aea:	09c080e7          	jalr	156(ra) # 80003b82 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004aee:	854a                	mv	a0,s2
    80004af0:	70a2                	ld	ra,40(sp)
    80004af2:	7402                	ld	s0,32(sp)
    80004af4:	64e2                	ld	s1,24(sp)
    80004af6:	6942                	ld	s2,16(sp)
    80004af8:	69a2                	ld	s3,8(sp)
    80004afa:	6145                	addi	sp,sp,48
    80004afc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004afe:	6908                	ld	a0,16(a0)
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	3c6080e7          	jalr	966(ra) # 80004ec6 <piperead>
    80004b08:	892a                	mv	s2,a0
    80004b0a:	b7d5                	j	80004aee <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b0c:	02451783          	lh	a5,36(a0)
    80004b10:	03079693          	slli	a3,a5,0x30
    80004b14:	92c1                	srli	a3,a3,0x30
    80004b16:	4725                	li	a4,9
    80004b18:	02d76863          	bltu	a4,a3,80004b48 <fileread+0xba>
    80004b1c:	0792                	slli	a5,a5,0x4
    80004b1e:	0001c717          	auipc	a4,0x1c
    80004b22:	12a70713          	addi	a4,a4,298 # 80020c48 <devsw>
    80004b26:	97ba                	add	a5,a5,a4
    80004b28:	639c                	ld	a5,0(a5)
    80004b2a:	c38d                	beqz	a5,80004b4c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b2c:	4505                	li	a0,1
    80004b2e:	9782                	jalr	a5
    80004b30:	892a                	mv	s2,a0
    80004b32:	bf75                	j	80004aee <fileread+0x60>
    panic("fileread");
    80004b34:	00004517          	auipc	a0,0x4
    80004b38:	bf450513          	addi	a0,a0,-1036 # 80008728 <syscalls+0x278>
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	a04080e7          	jalr	-1532(ra) # 80000540 <panic>
    return -1;
    80004b44:	597d                	li	s2,-1
    80004b46:	b765                	j	80004aee <fileread+0x60>
      return -1;
    80004b48:	597d                	li	s2,-1
    80004b4a:	b755                	j	80004aee <fileread+0x60>
    80004b4c:	597d                	li	s2,-1
    80004b4e:	b745                	j	80004aee <fileread+0x60>

0000000080004b50 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b50:	715d                	addi	sp,sp,-80
    80004b52:	e486                	sd	ra,72(sp)
    80004b54:	e0a2                	sd	s0,64(sp)
    80004b56:	fc26                	sd	s1,56(sp)
    80004b58:	f84a                	sd	s2,48(sp)
    80004b5a:	f44e                	sd	s3,40(sp)
    80004b5c:	f052                	sd	s4,32(sp)
    80004b5e:	ec56                	sd	s5,24(sp)
    80004b60:	e85a                	sd	s6,16(sp)
    80004b62:	e45e                	sd	s7,8(sp)
    80004b64:	e062                	sd	s8,0(sp)
    80004b66:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b68:	00954783          	lbu	a5,9(a0)
    80004b6c:	10078663          	beqz	a5,80004c78 <filewrite+0x128>
    80004b70:	892a                	mv	s2,a0
    80004b72:	8b2e                	mv	s6,a1
    80004b74:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b76:	411c                	lw	a5,0(a0)
    80004b78:	4705                	li	a4,1
    80004b7a:	02e78263          	beq	a5,a4,80004b9e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b7e:	470d                	li	a4,3
    80004b80:	02e78663          	beq	a5,a4,80004bac <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b84:	4709                	li	a4,2
    80004b86:	0ee79163          	bne	a5,a4,80004c68 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b8a:	0ac05d63          	blez	a2,80004c44 <filewrite+0xf4>
    int i = 0;
    80004b8e:	4981                	li	s3,0
    80004b90:	6b85                	lui	s7,0x1
    80004b92:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b96:	6c05                	lui	s8,0x1
    80004b98:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b9c:	a861                	j	80004c34 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b9e:	6908                	ld	a0,16(a0)
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	22e080e7          	jalr	558(ra) # 80004dce <pipewrite>
    80004ba8:	8a2a                	mv	s4,a0
    80004baa:	a045                	j	80004c4a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bac:	02451783          	lh	a5,36(a0)
    80004bb0:	03079693          	slli	a3,a5,0x30
    80004bb4:	92c1                	srli	a3,a3,0x30
    80004bb6:	4725                	li	a4,9
    80004bb8:	0cd76263          	bltu	a4,a3,80004c7c <filewrite+0x12c>
    80004bbc:	0792                	slli	a5,a5,0x4
    80004bbe:	0001c717          	auipc	a4,0x1c
    80004bc2:	08a70713          	addi	a4,a4,138 # 80020c48 <devsw>
    80004bc6:	97ba                	add	a5,a5,a4
    80004bc8:	679c                	ld	a5,8(a5)
    80004bca:	cbdd                	beqz	a5,80004c80 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bcc:	4505                	li	a0,1
    80004bce:	9782                	jalr	a5
    80004bd0:	8a2a                	mv	s4,a0
    80004bd2:	a8a5                	j	80004c4a <filewrite+0xfa>
    80004bd4:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bd8:	00000097          	auipc	ra,0x0
    80004bdc:	8b4080e7          	jalr	-1868(ra) # 8000448c <begin_op>
      ilock(f->ip);
    80004be0:	01893503          	ld	a0,24(s2)
    80004be4:	fffff097          	auipc	ra,0xfffff
    80004be8:	edc080e7          	jalr	-292(ra) # 80003ac0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004bec:	8756                	mv	a4,s5
    80004bee:	02092683          	lw	a3,32(s2)
    80004bf2:	01698633          	add	a2,s3,s6
    80004bf6:	4585                	li	a1,1
    80004bf8:	01893503          	ld	a0,24(s2)
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	270080e7          	jalr	624(ra) # 80003e6c <writei>
    80004c04:	84aa                	mv	s1,a0
    80004c06:	00a05763          	blez	a0,80004c14 <filewrite+0xc4>
        f->off += r;
    80004c0a:	02092783          	lw	a5,32(s2)
    80004c0e:	9fa9                	addw	a5,a5,a0
    80004c10:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c14:	01893503          	ld	a0,24(s2)
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	f6a080e7          	jalr	-150(ra) # 80003b82 <iunlock>
      end_op();
    80004c20:	00000097          	auipc	ra,0x0
    80004c24:	8ea080e7          	jalr	-1814(ra) # 8000450a <end_op>

      if(r != n1){
    80004c28:	009a9f63          	bne	s5,s1,80004c46 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c2c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c30:	0149db63          	bge	s3,s4,80004c46 <filewrite+0xf6>
      int n1 = n - i;
    80004c34:	413a04bb          	subw	s1,s4,s3
    80004c38:	0004879b          	sext.w	a5,s1
    80004c3c:	f8fbdce3          	bge	s7,a5,80004bd4 <filewrite+0x84>
    80004c40:	84e2                	mv	s1,s8
    80004c42:	bf49                	j	80004bd4 <filewrite+0x84>
    int i = 0;
    80004c44:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c46:	013a1f63          	bne	s4,s3,80004c64 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c4a:	8552                	mv	a0,s4
    80004c4c:	60a6                	ld	ra,72(sp)
    80004c4e:	6406                	ld	s0,64(sp)
    80004c50:	74e2                	ld	s1,56(sp)
    80004c52:	7942                	ld	s2,48(sp)
    80004c54:	79a2                	ld	s3,40(sp)
    80004c56:	7a02                	ld	s4,32(sp)
    80004c58:	6ae2                	ld	s5,24(sp)
    80004c5a:	6b42                	ld	s6,16(sp)
    80004c5c:	6ba2                	ld	s7,8(sp)
    80004c5e:	6c02                	ld	s8,0(sp)
    80004c60:	6161                	addi	sp,sp,80
    80004c62:	8082                	ret
    ret = (i == n ? n : -1);
    80004c64:	5a7d                	li	s4,-1
    80004c66:	b7d5                	j	80004c4a <filewrite+0xfa>
    panic("filewrite");
    80004c68:	00004517          	auipc	a0,0x4
    80004c6c:	ad050513          	addi	a0,a0,-1328 # 80008738 <syscalls+0x288>
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	8d0080e7          	jalr	-1840(ra) # 80000540 <panic>
    return -1;
    80004c78:	5a7d                	li	s4,-1
    80004c7a:	bfc1                	j	80004c4a <filewrite+0xfa>
      return -1;
    80004c7c:	5a7d                	li	s4,-1
    80004c7e:	b7f1                	j	80004c4a <filewrite+0xfa>
    80004c80:	5a7d                	li	s4,-1
    80004c82:	b7e1                	j	80004c4a <filewrite+0xfa>

0000000080004c84 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c84:	7179                	addi	sp,sp,-48
    80004c86:	f406                	sd	ra,40(sp)
    80004c88:	f022                	sd	s0,32(sp)
    80004c8a:	ec26                	sd	s1,24(sp)
    80004c8c:	e84a                	sd	s2,16(sp)
    80004c8e:	e44e                	sd	s3,8(sp)
    80004c90:	e052                	sd	s4,0(sp)
    80004c92:	1800                	addi	s0,sp,48
    80004c94:	84aa                	mv	s1,a0
    80004c96:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c98:	0005b023          	sd	zero,0(a1)
    80004c9c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ca0:	00000097          	auipc	ra,0x0
    80004ca4:	bf8080e7          	jalr	-1032(ra) # 80004898 <filealloc>
    80004ca8:	e088                	sd	a0,0(s1)
    80004caa:	c551                	beqz	a0,80004d36 <pipealloc+0xb2>
    80004cac:	00000097          	auipc	ra,0x0
    80004cb0:	bec080e7          	jalr	-1044(ra) # 80004898 <filealloc>
    80004cb4:	00aa3023          	sd	a0,0(s4)
    80004cb8:	c92d                	beqz	a0,80004d2a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	e2c080e7          	jalr	-468(ra) # 80000ae6 <kalloc>
    80004cc2:	892a                	mv	s2,a0
    80004cc4:	c125                	beqz	a0,80004d24 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cc6:	4985                	li	s3,1
    80004cc8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ccc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cd0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cd4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cd8:	00004597          	auipc	a1,0x4
    80004cdc:	a7058593          	addi	a1,a1,-1424 # 80008748 <syscalls+0x298>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	e66080e7          	jalr	-410(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004ce8:	609c                	ld	a5,0(s1)
    80004cea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004cee:	609c                	ld	a5,0(s1)
    80004cf0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cf4:	609c                	ld	a5,0(s1)
    80004cf6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cfa:	609c                	ld	a5,0(s1)
    80004cfc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d00:	000a3783          	ld	a5,0(s4)
    80004d04:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d08:	000a3783          	ld	a5,0(s4)
    80004d0c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d10:	000a3783          	ld	a5,0(s4)
    80004d14:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d18:	000a3783          	ld	a5,0(s4)
    80004d1c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d20:	4501                	li	a0,0
    80004d22:	a025                	j	80004d4a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d24:	6088                	ld	a0,0(s1)
    80004d26:	e501                	bnez	a0,80004d2e <pipealloc+0xaa>
    80004d28:	a039                	j	80004d36 <pipealloc+0xb2>
    80004d2a:	6088                	ld	a0,0(s1)
    80004d2c:	c51d                	beqz	a0,80004d5a <pipealloc+0xd6>
    fileclose(*f0);
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	c26080e7          	jalr	-986(ra) # 80004954 <fileclose>
  if(*f1)
    80004d36:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d3a:	557d                	li	a0,-1
  if(*f1)
    80004d3c:	c799                	beqz	a5,80004d4a <pipealloc+0xc6>
    fileclose(*f1);
    80004d3e:	853e                	mv	a0,a5
    80004d40:	00000097          	auipc	ra,0x0
    80004d44:	c14080e7          	jalr	-1004(ra) # 80004954 <fileclose>
  return -1;
    80004d48:	557d                	li	a0,-1
}
    80004d4a:	70a2                	ld	ra,40(sp)
    80004d4c:	7402                	ld	s0,32(sp)
    80004d4e:	64e2                	ld	s1,24(sp)
    80004d50:	6942                	ld	s2,16(sp)
    80004d52:	69a2                	ld	s3,8(sp)
    80004d54:	6a02                	ld	s4,0(sp)
    80004d56:	6145                	addi	sp,sp,48
    80004d58:	8082                	ret
  return -1;
    80004d5a:	557d                	li	a0,-1
    80004d5c:	b7fd                	j	80004d4a <pipealloc+0xc6>

0000000080004d5e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d5e:	1101                	addi	sp,sp,-32
    80004d60:	ec06                	sd	ra,24(sp)
    80004d62:	e822                	sd	s0,16(sp)
    80004d64:	e426                	sd	s1,8(sp)
    80004d66:	e04a                	sd	s2,0(sp)
    80004d68:	1000                	addi	s0,sp,32
    80004d6a:	84aa                	mv	s1,a0
    80004d6c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	e68080e7          	jalr	-408(ra) # 80000bd6 <acquire>
  if(writable){
    80004d76:	02090d63          	beqz	s2,80004db0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d7a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d7e:	21848513          	addi	a0,s1,536
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	336080e7          	jalr	822(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d8a:	2204b783          	ld	a5,544(s1)
    80004d8e:	eb95                	bnez	a5,80004dc2 <pipeclose+0x64>
    release(&pi->lock);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	ef8080e7          	jalr	-264(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	c4c080e7          	jalr	-948(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004da4:	60e2                	ld	ra,24(sp)
    80004da6:	6442                	ld	s0,16(sp)
    80004da8:	64a2                	ld	s1,8(sp)
    80004daa:	6902                	ld	s2,0(sp)
    80004dac:	6105                	addi	sp,sp,32
    80004dae:	8082                	ret
    pi->readopen = 0;
    80004db0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004db4:	21c48513          	addi	a0,s1,540
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	300080e7          	jalr	768(ra) # 800020b8 <wakeup>
    80004dc0:	b7e9                	j	80004d8a <pipeclose+0x2c>
    release(&pi->lock);
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	ec6080e7          	jalr	-314(ra) # 80000c8a <release>
}
    80004dcc:	bfe1                	j	80004da4 <pipeclose+0x46>

0000000080004dce <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dce:	711d                	addi	sp,sp,-96
    80004dd0:	ec86                	sd	ra,88(sp)
    80004dd2:	e8a2                	sd	s0,80(sp)
    80004dd4:	e4a6                	sd	s1,72(sp)
    80004dd6:	e0ca                	sd	s2,64(sp)
    80004dd8:	fc4e                	sd	s3,56(sp)
    80004dda:	f852                	sd	s4,48(sp)
    80004ddc:	f456                	sd	s5,40(sp)
    80004dde:	f05a                	sd	s6,32(sp)
    80004de0:	ec5e                	sd	s7,24(sp)
    80004de2:	e862                	sd	s8,16(sp)
    80004de4:	1080                	addi	s0,sp,96
    80004de6:	84aa                	mv	s1,a0
    80004de8:	8aae                	mv	s5,a1
    80004dea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	bc0080e7          	jalr	-1088(ra) # 800019ac <myproc>
    80004df4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004df6:	8526                	mv	a0,s1
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	dde080e7          	jalr	-546(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e00:	0b405663          	blez	s4,80004eac <pipewrite+0xde>
  int i = 0;
    80004e04:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e06:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e08:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e0c:	21c48b93          	addi	s7,s1,540
    80004e10:	a089                	j	80004e52 <pipewrite+0x84>
      release(&pi->lock);
    80004e12:	8526                	mv	a0,s1
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	e76080e7          	jalr	-394(ra) # 80000c8a <release>
      return -1;
    80004e1c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e1e:	854a                	mv	a0,s2
    80004e20:	60e6                	ld	ra,88(sp)
    80004e22:	6446                	ld	s0,80(sp)
    80004e24:	64a6                	ld	s1,72(sp)
    80004e26:	6906                	ld	s2,64(sp)
    80004e28:	79e2                	ld	s3,56(sp)
    80004e2a:	7a42                	ld	s4,48(sp)
    80004e2c:	7aa2                	ld	s5,40(sp)
    80004e2e:	7b02                	ld	s6,32(sp)
    80004e30:	6be2                	ld	s7,24(sp)
    80004e32:	6c42                	ld	s8,16(sp)
    80004e34:	6125                	addi	sp,sp,96
    80004e36:	8082                	ret
      wakeup(&pi->nread);
    80004e38:	8562                	mv	a0,s8
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	27e080e7          	jalr	638(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e42:	85a6                	mv	a1,s1
    80004e44:	855e                	mv	a0,s7
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	20e080e7          	jalr	526(ra) # 80002054 <sleep>
  while(i < n){
    80004e4e:	07495063          	bge	s2,s4,80004eae <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e52:	2204a783          	lw	a5,544(s1)
    80004e56:	dfd5                	beqz	a5,80004e12 <pipewrite+0x44>
    80004e58:	854e                	mv	a0,s3
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	4a2080e7          	jalr	1186(ra) # 800022fc <killed>
    80004e62:	f945                	bnez	a0,80004e12 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e64:	2184a783          	lw	a5,536(s1)
    80004e68:	21c4a703          	lw	a4,540(s1)
    80004e6c:	2007879b          	addiw	a5,a5,512
    80004e70:	fcf704e3          	beq	a4,a5,80004e38 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e74:	4685                	li	a3,1
    80004e76:	01590633          	add	a2,s2,s5
    80004e7a:	faf40593          	addi	a1,s0,-81
    80004e7e:	0509b503          	ld	a0,80(s3)
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	876080e7          	jalr	-1930(ra) # 800016f8 <copyin>
    80004e8a:	03650263          	beq	a0,s6,80004eae <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e8e:	21c4a783          	lw	a5,540(s1)
    80004e92:	0017871b          	addiw	a4,a5,1
    80004e96:	20e4ae23          	sw	a4,540(s1)
    80004e9a:	1ff7f793          	andi	a5,a5,511
    80004e9e:	97a6                	add	a5,a5,s1
    80004ea0:	faf44703          	lbu	a4,-81(s0)
    80004ea4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ea8:	2905                	addiw	s2,s2,1
    80004eaa:	b755                	j	80004e4e <pipewrite+0x80>
  int i = 0;
    80004eac:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004eae:	21848513          	addi	a0,s1,536
    80004eb2:	ffffd097          	auipc	ra,0xffffd
    80004eb6:	206080e7          	jalr	518(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	dce080e7          	jalr	-562(ra) # 80000c8a <release>
  return i;
    80004ec4:	bfa9                	j	80004e1e <pipewrite+0x50>

0000000080004ec6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ec6:	715d                	addi	sp,sp,-80
    80004ec8:	e486                	sd	ra,72(sp)
    80004eca:	e0a2                	sd	s0,64(sp)
    80004ecc:	fc26                	sd	s1,56(sp)
    80004ece:	f84a                	sd	s2,48(sp)
    80004ed0:	f44e                	sd	s3,40(sp)
    80004ed2:	f052                	sd	s4,32(sp)
    80004ed4:	ec56                	sd	s5,24(sp)
    80004ed6:	e85a                	sd	s6,16(sp)
    80004ed8:	0880                	addi	s0,sp,80
    80004eda:	84aa                	mv	s1,a0
    80004edc:	892e                	mv	s2,a1
    80004ede:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	acc080e7          	jalr	-1332(ra) # 800019ac <myproc>
    80004ee8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004eea:	8526                	mv	a0,s1
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	cea080e7          	jalr	-790(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef4:	2184a703          	lw	a4,536(s1)
    80004ef8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004efc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f00:	02f71763          	bne	a4,a5,80004f2e <piperead+0x68>
    80004f04:	2244a783          	lw	a5,548(s1)
    80004f08:	c39d                	beqz	a5,80004f2e <piperead+0x68>
    if(killed(pr)){
    80004f0a:	8552                	mv	a0,s4
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	3f0080e7          	jalr	1008(ra) # 800022fc <killed>
    80004f14:	e949                	bnez	a0,80004fa6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f16:	85a6                	mv	a1,s1
    80004f18:	854e                	mv	a0,s3
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	13a080e7          	jalr	314(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f22:	2184a703          	lw	a4,536(s1)
    80004f26:	21c4a783          	lw	a5,540(s1)
    80004f2a:	fcf70de3          	beq	a4,a5,80004f04 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f2e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f30:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f32:	05505463          	blez	s5,80004f7a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f36:	2184a783          	lw	a5,536(s1)
    80004f3a:	21c4a703          	lw	a4,540(s1)
    80004f3e:	02f70e63          	beq	a4,a5,80004f7a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f42:	0017871b          	addiw	a4,a5,1
    80004f46:	20e4ac23          	sw	a4,536(s1)
    80004f4a:	1ff7f793          	andi	a5,a5,511
    80004f4e:	97a6                	add	a5,a5,s1
    80004f50:	0187c783          	lbu	a5,24(a5)
    80004f54:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f58:	4685                	li	a3,1
    80004f5a:	fbf40613          	addi	a2,s0,-65
    80004f5e:	85ca                	mv	a1,s2
    80004f60:	050a3503          	ld	a0,80(s4)
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	708080e7          	jalr	1800(ra) # 8000166c <copyout>
    80004f6c:	01650763          	beq	a0,s6,80004f7a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f70:	2985                	addiw	s3,s3,1
    80004f72:	0905                	addi	s2,s2,1
    80004f74:	fd3a91e3          	bne	s5,s3,80004f36 <piperead+0x70>
    80004f78:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f7a:	21c48513          	addi	a0,s1,540
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	13a080e7          	jalr	314(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	d02080e7          	jalr	-766(ra) # 80000c8a <release>
  return i;
}
    80004f90:	854e                	mv	a0,s3
    80004f92:	60a6                	ld	ra,72(sp)
    80004f94:	6406                	ld	s0,64(sp)
    80004f96:	74e2                	ld	s1,56(sp)
    80004f98:	7942                	ld	s2,48(sp)
    80004f9a:	79a2                	ld	s3,40(sp)
    80004f9c:	7a02                	ld	s4,32(sp)
    80004f9e:	6ae2                	ld	s5,24(sp)
    80004fa0:	6b42                	ld	s6,16(sp)
    80004fa2:	6161                	addi	sp,sp,80
    80004fa4:	8082                	ret
      release(&pi->lock);
    80004fa6:	8526                	mv	a0,s1
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	ce2080e7          	jalr	-798(ra) # 80000c8a <release>
      return -1;
    80004fb0:	59fd                	li	s3,-1
    80004fb2:	bff9                	j	80004f90 <piperead+0xca>

0000000080004fb4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fb4:	1141                	addi	sp,sp,-16
    80004fb6:	e422                	sd	s0,8(sp)
    80004fb8:	0800                	addi	s0,sp,16
    80004fba:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004fbc:	8905                	andi	a0,a0,1
    80004fbe:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004fc0:	8b89                	andi	a5,a5,2
    80004fc2:	c399                	beqz	a5,80004fc8 <flags2perm+0x14>
      perm |= PTE_W;
    80004fc4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004fc8:	6422                	ld	s0,8(sp)
    80004fca:	0141                	addi	sp,sp,16
    80004fcc:	8082                	ret

0000000080004fce <exec>:

int
exec(char *path, char **argv)
{
    80004fce:	de010113          	addi	sp,sp,-544
    80004fd2:	20113c23          	sd	ra,536(sp)
    80004fd6:	20813823          	sd	s0,528(sp)
    80004fda:	20913423          	sd	s1,520(sp)
    80004fde:	21213023          	sd	s2,512(sp)
    80004fe2:	ffce                	sd	s3,504(sp)
    80004fe4:	fbd2                	sd	s4,496(sp)
    80004fe6:	f7d6                	sd	s5,488(sp)
    80004fe8:	f3da                	sd	s6,480(sp)
    80004fea:	efde                	sd	s7,472(sp)
    80004fec:	ebe2                	sd	s8,464(sp)
    80004fee:	e7e6                	sd	s9,456(sp)
    80004ff0:	e3ea                	sd	s10,448(sp)
    80004ff2:	ff6e                	sd	s11,440(sp)
    80004ff4:	1400                	addi	s0,sp,544
    80004ff6:	892a                	mv	s2,a0
    80004ff8:	dea43423          	sd	a0,-536(s0)
    80004ffc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	9ac080e7          	jalr	-1620(ra) # 800019ac <myproc>
    80005008:	84aa                	mv	s1,a0

  begin_op();
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	482080e7          	jalr	1154(ra) # 8000448c <begin_op>

  if((ip = namei(path)) == 0){
    80005012:	854a                	mv	a0,s2
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	258080e7          	jalr	600(ra) # 8000426c <namei>
    8000501c:	c93d                	beqz	a0,80005092 <exec+0xc4>
    8000501e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	aa0080e7          	jalr	-1376(ra) # 80003ac0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005028:	04000713          	li	a4,64
    8000502c:	4681                	li	a3,0
    8000502e:	e5040613          	addi	a2,s0,-432
    80005032:	4581                	li	a1,0
    80005034:	8556                	mv	a0,s5
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	d3e080e7          	jalr	-706(ra) # 80003d74 <readi>
    8000503e:	04000793          	li	a5,64
    80005042:	00f51a63          	bne	a0,a5,80005056 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005046:	e5042703          	lw	a4,-432(s0)
    8000504a:	464c47b7          	lui	a5,0x464c4
    8000504e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005052:	04f70663          	beq	a4,a5,8000509e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005056:	8556                	mv	a0,s5
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	cca080e7          	jalr	-822(ra) # 80003d22 <iunlockput>
    end_op();
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	4aa080e7          	jalr	1194(ra) # 8000450a <end_op>
  }
  return -1;
    80005068:	557d                	li	a0,-1
}
    8000506a:	21813083          	ld	ra,536(sp)
    8000506e:	21013403          	ld	s0,528(sp)
    80005072:	20813483          	ld	s1,520(sp)
    80005076:	20013903          	ld	s2,512(sp)
    8000507a:	79fe                	ld	s3,504(sp)
    8000507c:	7a5e                	ld	s4,496(sp)
    8000507e:	7abe                	ld	s5,488(sp)
    80005080:	7b1e                	ld	s6,480(sp)
    80005082:	6bfe                	ld	s7,472(sp)
    80005084:	6c5e                	ld	s8,464(sp)
    80005086:	6cbe                	ld	s9,456(sp)
    80005088:	6d1e                	ld	s10,448(sp)
    8000508a:	7dfa                	ld	s11,440(sp)
    8000508c:	22010113          	addi	sp,sp,544
    80005090:	8082                	ret
    end_op();
    80005092:	fffff097          	auipc	ra,0xfffff
    80005096:	478080e7          	jalr	1144(ra) # 8000450a <end_op>
    return -1;
    8000509a:	557d                	li	a0,-1
    8000509c:	b7f9                	j	8000506a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000509e:	8526                	mv	a0,s1
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	9d0080e7          	jalr	-1584(ra) # 80001a70 <proc_pagetable>
    800050a8:	8b2a                	mv	s6,a0
    800050aa:	d555                	beqz	a0,80005056 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ac:	e7042783          	lw	a5,-400(s0)
    800050b0:	e8845703          	lhu	a4,-376(s0)
    800050b4:	c735                	beqz	a4,80005120 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050b6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050bc:	6a05                	lui	s4,0x1
    800050be:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050c2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050c6:	6d85                	lui	s11,0x1
    800050c8:	7d7d                	lui	s10,0xfffff
    800050ca:	ac3d                	j	80005308 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050cc:	00003517          	auipc	a0,0x3
    800050d0:	68450513          	addi	a0,a0,1668 # 80008750 <syscalls+0x2a0>
    800050d4:	ffffb097          	auipc	ra,0xffffb
    800050d8:	46c080e7          	jalr	1132(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050dc:	874a                	mv	a4,s2
    800050de:	009c86bb          	addw	a3,s9,s1
    800050e2:	4581                	li	a1,0
    800050e4:	8556                	mv	a0,s5
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	c8e080e7          	jalr	-882(ra) # 80003d74 <readi>
    800050ee:	2501                	sext.w	a0,a0
    800050f0:	1aa91963          	bne	s2,a0,800052a2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800050f4:	009d84bb          	addw	s1,s11,s1
    800050f8:	013d09bb          	addw	s3,s10,s3
    800050fc:	1f74f663          	bgeu	s1,s7,800052e8 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005100:	02049593          	slli	a1,s1,0x20
    80005104:	9181                	srli	a1,a1,0x20
    80005106:	95e2                	add	a1,a1,s8
    80005108:	855a                	mv	a0,s6
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	f52080e7          	jalr	-174(ra) # 8000105c <walkaddr>
    80005112:	862a                	mv	a2,a0
    if(pa == 0)
    80005114:	dd45                	beqz	a0,800050cc <exec+0xfe>
      n = PGSIZE;
    80005116:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005118:	fd49f2e3          	bgeu	s3,s4,800050dc <exec+0x10e>
      n = sz - i;
    8000511c:	894e                	mv	s2,s3
    8000511e:	bf7d                	j	800050dc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005120:	4901                	li	s2,0
  iunlockput(ip);
    80005122:	8556                	mv	a0,s5
    80005124:	fffff097          	auipc	ra,0xfffff
    80005128:	bfe080e7          	jalr	-1026(ra) # 80003d22 <iunlockput>
  end_op();
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	3de080e7          	jalr	990(ra) # 8000450a <end_op>
  p = myproc();
    80005134:	ffffd097          	auipc	ra,0xffffd
    80005138:	878080e7          	jalr	-1928(ra) # 800019ac <myproc>
    8000513c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000513e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005142:	6785                	lui	a5,0x1
    80005144:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005146:	97ca                	add	a5,a5,s2
    80005148:	777d                	lui	a4,0xfffff
    8000514a:	8ff9                	and	a5,a5,a4
    8000514c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005150:	4691                	li	a3,4
    80005152:	6609                	lui	a2,0x2
    80005154:	963e                	add	a2,a2,a5
    80005156:	85be                	mv	a1,a5
    80005158:	855a                	mv	a0,s6
    8000515a:	ffffc097          	auipc	ra,0xffffc
    8000515e:	2b6080e7          	jalr	694(ra) # 80001410 <uvmalloc>
    80005162:	8c2a                	mv	s8,a0
  ip = 0;
    80005164:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005166:	12050e63          	beqz	a0,800052a2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000516a:	75f9                	lui	a1,0xffffe
    8000516c:	95aa                	add	a1,a1,a0
    8000516e:	855a                	mv	a0,s6
    80005170:	ffffc097          	auipc	ra,0xffffc
    80005174:	4ca080e7          	jalr	1226(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005178:	7afd                	lui	s5,0xfffff
    8000517a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000517c:	df043783          	ld	a5,-528(s0)
    80005180:	6388                	ld	a0,0(a5)
    80005182:	c925                	beqz	a0,800051f2 <exec+0x224>
    80005184:	e9040993          	addi	s3,s0,-368
    80005188:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000518c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000518e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	cbe080e7          	jalr	-834(ra) # 80000e4e <strlen>
    80005198:	0015079b          	addiw	a5,a0,1
    8000519c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051a0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051a4:	13596663          	bltu	s2,s5,800052d0 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a8:	df043d83          	ld	s11,-528(s0)
    800051ac:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051b0:	8552                	mv	a0,s4
    800051b2:	ffffc097          	auipc	ra,0xffffc
    800051b6:	c9c080e7          	jalr	-868(ra) # 80000e4e <strlen>
    800051ba:	0015069b          	addiw	a3,a0,1
    800051be:	8652                	mv	a2,s4
    800051c0:	85ca                	mv	a1,s2
    800051c2:	855a                	mv	a0,s6
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	4a8080e7          	jalr	1192(ra) # 8000166c <copyout>
    800051cc:	10054663          	bltz	a0,800052d8 <exec+0x30a>
    ustack[argc] = sp;
    800051d0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051d4:	0485                	addi	s1,s1,1
    800051d6:	008d8793          	addi	a5,s11,8
    800051da:	def43823          	sd	a5,-528(s0)
    800051de:	008db503          	ld	a0,8(s11)
    800051e2:	c911                	beqz	a0,800051f6 <exec+0x228>
    if(argc >= MAXARG)
    800051e4:	09a1                	addi	s3,s3,8
    800051e6:	fb3c95e3          	bne	s9,s3,80005190 <exec+0x1c2>
  sz = sz1;
    800051ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ee:	4a81                	li	s5,0
    800051f0:	a84d                	j	800052a2 <exec+0x2d4>
  sp = sz;
    800051f2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051f4:	4481                	li	s1,0
  ustack[argc] = 0;
    800051f6:	00349793          	slli	a5,s1,0x3
    800051fa:	f9078793          	addi	a5,a5,-112
    800051fe:	97a2                	add	a5,a5,s0
    80005200:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005204:	00148693          	addi	a3,s1,1
    80005208:	068e                	slli	a3,a3,0x3
    8000520a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000520e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005212:	01597663          	bgeu	s2,s5,8000521e <exec+0x250>
  sz = sz1;
    80005216:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000521a:	4a81                	li	s5,0
    8000521c:	a059                	j	800052a2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000521e:	e9040613          	addi	a2,s0,-368
    80005222:	85ca                	mv	a1,s2
    80005224:	855a                	mv	a0,s6
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	446080e7          	jalr	1094(ra) # 8000166c <copyout>
    8000522e:	0a054963          	bltz	a0,800052e0 <exec+0x312>
  p->trapframe->a1 = sp;
    80005232:	058bb783          	ld	a5,88(s7)
    80005236:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000523a:	de843783          	ld	a5,-536(s0)
    8000523e:	0007c703          	lbu	a4,0(a5)
    80005242:	cf11                	beqz	a4,8000525e <exec+0x290>
    80005244:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005246:	02f00693          	li	a3,47
    8000524a:	a039                	j	80005258 <exec+0x28a>
      last = s+1;
    8000524c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005250:	0785                	addi	a5,a5,1
    80005252:	fff7c703          	lbu	a4,-1(a5)
    80005256:	c701                	beqz	a4,8000525e <exec+0x290>
    if(*s == '/')
    80005258:	fed71ce3          	bne	a4,a3,80005250 <exec+0x282>
    8000525c:	bfc5                	j	8000524c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000525e:	4641                	li	a2,16
    80005260:	de843583          	ld	a1,-536(s0)
    80005264:	158b8513          	addi	a0,s7,344
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	bb4080e7          	jalr	-1100(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005270:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005274:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005278:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000527c:	058bb783          	ld	a5,88(s7)
    80005280:	e6843703          	ld	a4,-408(s0)
    80005284:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005286:	058bb783          	ld	a5,88(s7)
    8000528a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000528e:	85ea                	mv	a1,s10
    80005290:	ffffd097          	auipc	ra,0xffffd
    80005294:	87c080e7          	jalr	-1924(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005298:	0004851b          	sext.w	a0,s1
    8000529c:	b3f9                	j	8000506a <exec+0x9c>
    8000529e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052a2:	df843583          	ld	a1,-520(s0)
    800052a6:	855a                	mv	a0,s6
    800052a8:	ffffd097          	auipc	ra,0xffffd
    800052ac:	864080e7          	jalr	-1948(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800052b0:	da0a93e3          	bnez	s5,80005056 <exec+0x88>
  return -1;
    800052b4:	557d                	li	a0,-1
    800052b6:	bb55                	j	8000506a <exec+0x9c>
    800052b8:	df243c23          	sd	s2,-520(s0)
    800052bc:	b7dd                	j	800052a2 <exec+0x2d4>
    800052be:	df243c23          	sd	s2,-520(s0)
    800052c2:	b7c5                	j	800052a2 <exec+0x2d4>
    800052c4:	df243c23          	sd	s2,-520(s0)
    800052c8:	bfe9                	j	800052a2 <exec+0x2d4>
    800052ca:	df243c23          	sd	s2,-520(s0)
    800052ce:	bfd1                	j	800052a2 <exec+0x2d4>
  sz = sz1;
    800052d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052d4:	4a81                	li	s5,0
    800052d6:	b7f1                	j	800052a2 <exec+0x2d4>
  sz = sz1;
    800052d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052dc:	4a81                	li	s5,0
    800052de:	b7d1                	j	800052a2 <exec+0x2d4>
  sz = sz1;
    800052e0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e4:	4a81                	li	s5,0
    800052e6:	bf75                	j	800052a2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ec:	e0843783          	ld	a5,-504(s0)
    800052f0:	0017869b          	addiw	a3,a5,1
    800052f4:	e0d43423          	sd	a3,-504(s0)
    800052f8:	e0043783          	ld	a5,-512(s0)
    800052fc:	0387879b          	addiw	a5,a5,56
    80005300:	e8845703          	lhu	a4,-376(s0)
    80005304:	e0e6dfe3          	bge	a3,a4,80005122 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005308:	2781                	sext.w	a5,a5
    8000530a:	e0f43023          	sd	a5,-512(s0)
    8000530e:	03800713          	li	a4,56
    80005312:	86be                	mv	a3,a5
    80005314:	e1840613          	addi	a2,s0,-488
    80005318:	4581                	li	a1,0
    8000531a:	8556                	mv	a0,s5
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	a58080e7          	jalr	-1448(ra) # 80003d74 <readi>
    80005324:	03800793          	li	a5,56
    80005328:	f6f51be3          	bne	a0,a5,8000529e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000532c:	e1842783          	lw	a5,-488(s0)
    80005330:	4705                	li	a4,1
    80005332:	fae79de3          	bne	a5,a4,800052ec <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005336:	e4043483          	ld	s1,-448(s0)
    8000533a:	e3843783          	ld	a5,-456(s0)
    8000533e:	f6f4ede3          	bltu	s1,a5,800052b8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005342:	e2843783          	ld	a5,-472(s0)
    80005346:	94be                	add	s1,s1,a5
    80005348:	f6f4ebe3          	bltu	s1,a5,800052be <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000534c:	de043703          	ld	a4,-544(s0)
    80005350:	8ff9                	and	a5,a5,a4
    80005352:	fbad                	bnez	a5,800052c4 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005354:	e1c42503          	lw	a0,-484(s0)
    80005358:	00000097          	auipc	ra,0x0
    8000535c:	c5c080e7          	jalr	-932(ra) # 80004fb4 <flags2perm>
    80005360:	86aa                	mv	a3,a0
    80005362:	8626                	mv	a2,s1
    80005364:	85ca                	mv	a1,s2
    80005366:	855a                	mv	a0,s6
    80005368:	ffffc097          	auipc	ra,0xffffc
    8000536c:	0a8080e7          	jalr	168(ra) # 80001410 <uvmalloc>
    80005370:	dea43c23          	sd	a0,-520(s0)
    80005374:	d939                	beqz	a0,800052ca <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005376:	e2843c03          	ld	s8,-472(s0)
    8000537a:	e2042c83          	lw	s9,-480(s0)
    8000537e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005382:	f60b83e3          	beqz	s7,800052e8 <exec+0x31a>
    80005386:	89de                	mv	s3,s7
    80005388:	4481                	li	s1,0
    8000538a:	bb9d                	j	80005100 <exec+0x132>

000000008000538c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000538c:	7179                	addi	sp,sp,-48
    8000538e:	f406                	sd	ra,40(sp)
    80005390:	f022                	sd	s0,32(sp)
    80005392:	ec26                	sd	s1,24(sp)
    80005394:	e84a                	sd	s2,16(sp)
    80005396:	1800                	addi	s0,sp,48
    80005398:	892e                	mv	s2,a1
    8000539a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000539c:	fdc40593          	addi	a1,s0,-36
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	b6c080e7          	jalr	-1172(ra) # 80002f0c <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053a8:	fdc42703          	lw	a4,-36(s0)
    800053ac:	47bd                	li	a5,15
    800053ae:	02e7eb63          	bltu	a5,a4,800053e4 <argfd+0x58>
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	5fa080e7          	jalr	1530(ra) # 800019ac <myproc>
    800053ba:	fdc42703          	lw	a4,-36(s0)
    800053be:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd23a>
    800053c2:	078e                	slli	a5,a5,0x3
    800053c4:	953e                	add	a0,a0,a5
    800053c6:	611c                	ld	a5,0(a0)
    800053c8:	c385                	beqz	a5,800053e8 <argfd+0x5c>
    return -1;
  if(pfd)
    800053ca:	00090463          	beqz	s2,800053d2 <argfd+0x46>
    *pfd = fd;
    800053ce:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053d2:	4501                	li	a0,0
  if(pf)
    800053d4:	c091                	beqz	s1,800053d8 <argfd+0x4c>
    *pf = f;
    800053d6:	e09c                	sd	a5,0(s1)
}
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	64e2                	ld	s1,24(sp)
    800053de:	6942                	ld	s2,16(sp)
    800053e0:	6145                	addi	sp,sp,48
    800053e2:	8082                	ret
    return -1;
    800053e4:	557d                	li	a0,-1
    800053e6:	bfcd                	j	800053d8 <argfd+0x4c>
    800053e8:	557d                	li	a0,-1
    800053ea:	b7fd                	j	800053d8 <argfd+0x4c>

00000000800053ec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053ec:	1101                	addi	sp,sp,-32
    800053ee:	ec06                	sd	ra,24(sp)
    800053f0:	e822                	sd	s0,16(sp)
    800053f2:	e426                	sd	s1,8(sp)
    800053f4:	1000                	addi	s0,sp,32
    800053f6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053f8:	ffffc097          	auipc	ra,0xffffc
    800053fc:	5b4080e7          	jalr	1460(ra) # 800019ac <myproc>
    80005400:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005402:	0d050793          	addi	a5,a0,208
    80005406:	4501                	li	a0,0
    80005408:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000540a:	6398                	ld	a4,0(a5)
    8000540c:	cb19                	beqz	a4,80005422 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000540e:	2505                	addiw	a0,a0,1
    80005410:	07a1                	addi	a5,a5,8
    80005412:	fed51ce3          	bne	a0,a3,8000540a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005416:	557d                	li	a0,-1
}
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	64a2                	ld	s1,8(sp)
    8000541e:	6105                	addi	sp,sp,32
    80005420:	8082                	ret
      p->ofile[fd] = f;
    80005422:	01a50793          	addi	a5,a0,26
    80005426:	078e                	slli	a5,a5,0x3
    80005428:	963e                	add	a2,a2,a5
    8000542a:	e204                	sd	s1,0(a2)
      return fd;
    8000542c:	b7f5                	j	80005418 <fdalloc+0x2c>

000000008000542e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000542e:	715d                	addi	sp,sp,-80
    80005430:	e486                	sd	ra,72(sp)
    80005432:	e0a2                	sd	s0,64(sp)
    80005434:	fc26                	sd	s1,56(sp)
    80005436:	f84a                	sd	s2,48(sp)
    80005438:	f44e                	sd	s3,40(sp)
    8000543a:	f052                	sd	s4,32(sp)
    8000543c:	ec56                	sd	s5,24(sp)
    8000543e:	e85a                	sd	s6,16(sp)
    80005440:	0880                	addi	s0,sp,80
    80005442:	8b2e                	mv	s6,a1
    80005444:	89b2                	mv	s3,a2
    80005446:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005448:	fb040593          	addi	a1,s0,-80
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	e3e080e7          	jalr	-450(ra) # 8000428a <nameiparent>
    80005454:	84aa                	mv	s1,a0
    80005456:	14050f63          	beqz	a0,800055b4 <create+0x186>
    return 0;

  ilock(dp);
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	666080e7          	jalr	1638(ra) # 80003ac0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005462:	4601                	li	a2,0
    80005464:	fb040593          	addi	a1,s0,-80
    80005468:	8526                	mv	a0,s1
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	b3a080e7          	jalr	-1222(ra) # 80003fa4 <dirlookup>
    80005472:	8aaa                	mv	s5,a0
    80005474:	c931                	beqz	a0,800054c8 <create+0x9a>
    iunlockput(dp);
    80005476:	8526                	mv	a0,s1
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	8aa080e7          	jalr	-1878(ra) # 80003d22 <iunlockput>
    ilock(ip);
    80005480:	8556                	mv	a0,s5
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	63e080e7          	jalr	1598(ra) # 80003ac0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000548a:	000b059b          	sext.w	a1,s6
    8000548e:	4789                	li	a5,2
    80005490:	02f59563          	bne	a1,a5,800054ba <create+0x8c>
    80005494:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd264>
    80005498:	37f9                	addiw	a5,a5,-2
    8000549a:	17c2                	slli	a5,a5,0x30
    8000549c:	93c1                	srli	a5,a5,0x30
    8000549e:	4705                	li	a4,1
    800054a0:	00f76d63          	bltu	a4,a5,800054ba <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054a4:	8556                	mv	a0,s5
    800054a6:	60a6                	ld	ra,72(sp)
    800054a8:	6406                	ld	s0,64(sp)
    800054aa:	74e2                	ld	s1,56(sp)
    800054ac:	7942                	ld	s2,48(sp)
    800054ae:	79a2                	ld	s3,40(sp)
    800054b0:	7a02                	ld	s4,32(sp)
    800054b2:	6ae2                	ld	s5,24(sp)
    800054b4:	6b42                	ld	s6,16(sp)
    800054b6:	6161                	addi	sp,sp,80
    800054b8:	8082                	ret
    iunlockput(ip);
    800054ba:	8556                	mv	a0,s5
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	866080e7          	jalr	-1946(ra) # 80003d22 <iunlockput>
    return 0;
    800054c4:	4a81                	li	s5,0
    800054c6:	bff9                	j	800054a4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054c8:	85da                	mv	a1,s6
    800054ca:	4088                	lw	a0,0(s1)
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	456080e7          	jalr	1110(ra) # 80003922 <ialloc>
    800054d4:	8a2a                	mv	s4,a0
    800054d6:	c539                	beqz	a0,80005524 <create+0xf6>
  ilock(ip);
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	5e8080e7          	jalr	1512(ra) # 80003ac0 <ilock>
  ip->major = major;
    800054e0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800054e4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800054e8:	4905                	li	s2,1
    800054ea:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800054ee:	8552                	mv	a0,s4
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	504080e7          	jalr	1284(ra) # 800039f4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054f8:	000b059b          	sext.w	a1,s6
    800054fc:	03258b63          	beq	a1,s2,80005532 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005500:	004a2603          	lw	a2,4(s4)
    80005504:	fb040593          	addi	a1,s0,-80
    80005508:	8526                	mv	a0,s1
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	cb0080e7          	jalr	-848(ra) # 800041ba <dirlink>
    80005512:	06054f63          	bltz	a0,80005590 <create+0x162>
  iunlockput(dp);
    80005516:	8526                	mv	a0,s1
    80005518:	fffff097          	auipc	ra,0xfffff
    8000551c:	80a080e7          	jalr	-2038(ra) # 80003d22 <iunlockput>
  return ip;
    80005520:	8ad2                	mv	s5,s4
    80005522:	b749                	j	800054a4 <create+0x76>
    iunlockput(dp);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	7fc080e7          	jalr	2044(ra) # 80003d22 <iunlockput>
    return 0;
    8000552e:	8ad2                	mv	s5,s4
    80005530:	bf95                	j	800054a4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005532:	004a2603          	lw	a2,4(s4)
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	23a58593          	addi	a1,a1,570 # 80008770 <syscalls+0x2c0>
    8000553e:	8552                	mv	a0,s4
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	c7a080e7          	jalr	-902(ra) # 800041ba <dirlink>
    80005548:	04054463          	bltz	a0,80005590 <create+0x162>
    8000554c:	40d0                	lw	a2,4(s1)
    8000554e:	00003597          	auipc	a1,0x3
    80005552:	22a58593          	addi	a1,a1,554 # 80008778 <syscalls+0x2c8>
    80005556:	8552                	mv	a0,s4
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	c62080e7          	jalr	-926(ra) # 800041ba <dirlink>
    80005560:	02054863          	bltz	a0,80005590 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005564:	004a2603          	lw	a2,4(s4)
    80005568:	fb040593          	addi	a1,s0,-80
    8000556c:	8526                	mv	a0,s1
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c4c080e7          	jalr	-948(ra) # 800041ba <dirlink>
    80005576:	00054d63          	bltz	a0,80005590 <create+0x162>
    dp->nlink++;  // for ".."
    8000557a:	04a4d783          	lhu	a5,74(s1)
    8000557e:	2785                	addiw	a5,a5,1
    80005580:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	46e080e7          	jalr	1134(ra) # 800039f4 <iupdate>
    8000558e:	b761                	j	80005516 <create+0xe8>
  ip->nlink = 0;
    80005590:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005594:	8552                	mv	a0,s4
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	45e080e7          	jalr	1118(ra) # 800039f4 <iupdate>
  iunlockput(ip);
    8000559e:	8552                	mv	a0,s4
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	782080e7          	jalr	1922(ra) # 80003d22 <iunlockput>
  iunlockput(dp);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	778080e7          	jalr	1912(ra) # 80003d22 <iunlockput>
  return 0;
    800055b2:	bdcd                	j	800054a4 <create+0x76>
    return 0;
    800055b4:	8aaa                	mv	s5,a0
    800055b6:	b5fd                	j	800054a4 <create+0x76>

00000000800055b8 <sys_dup>:
{
    800055b8:	7179                	addi	sp,sp,-48
    800055ba:	f406                	sd	ra,40(sp)
    800055bc:	f022                	sd	s0,32(sp)
    800055be:	ec26                	sd	s1,24(sp)
    800055c0:	e84a                	sd	s2,16(sp)
    800055c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055c4:	fd840613          	addi	a2,s0,-40
    800055c8:	4581                	li	a1,0
    800055ca:	4501                	li	a0,0
    800055cc:	00000097          	auipc	ra,0x0
    800055d0:	dc0080e7          	jalr	-576(ra) # 8000538c <argfd>
    return -1;
    800055d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055d6:	02054363          	bltz	a0,800055fc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800055da:	fd843903          	ld	s2,-40(s0)
    800055de:	854a                	mv	a0,s2
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	e0c080e7          	jalr	-500(ra) # 800053ec <fdalloc>
    800055e8:	84aa                	mv	s1,a0
    return -1;
    800055ea:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055ec:	00054863          	bltz	a0,800055fc <sys_dup+0x44>
  filedup(f);
    800055f0:	854a                	mv	a0,s2
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	310080e7          	jalr	784(ra) # 80004902 <filedup>
  return fd;
    800055fa:	87a6                	mv	a5,s1
}
    800055fc:	853e                	mv	a0,a5
    800055fe:	70a2                	ld	ra,40(sp)
    80005600:	7402                	ld	s0,32(sp)
    80005602:	64e2                	ld	s1,24(sp)
    80005604:	6942                	ld	s2,16(sp)
    80005606:	6145                	addi	sp,sp,48
    80005608:	8082                	ret

000000008000560a <sys_read>:
{
    8000560a:	7179                	addi	sp,sp,-48
    8000560c:	f406                	sd	ra,40(sp)
    8000560e:	f022                	sd	s0,32(sp)
    80005610:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005612:	fd840593          	addi	a1,s0,-40
    80005616:	4505                	li	a0,1
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	914080e7          	jalr	-1772(ra) # 80002f2c <argaddr>
  argint(2, &n);
    80005620:	fe440593          	addi	a1,s0,-28
    80005624:	4509                	li	a0,2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	8e6080e7          	jalr	-1818(ra) # 80002f0c <argint>
  if(argfd(0, 0, &f) < 0)
    8000562e:	fe840613          	addi	a2,s0,-24
    80005632:	4581                	li	a1,0
    80005634:	4501                	li	a0,0
    80005636:	00000097          	auipc	ra,0x0
    8000563a:	d56080e7          	jalr	-682(ra) # 8000538c <argfd>
    8000563e:	87aa                	mv	a5,a0
    return -1;
    80005640:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005642:	0007cc63          	bltz	a5,8000565a <sys_read+0x50>
  return fileread(f, p, n);
    80005646:	fe442603          	lw	a2,-28(s0)
    8000564a:	fd843583          	ld	a1,-40(s0)
    8000564e:	fe843503          	ld	a0,-24(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	43c080e7          	jalr	1084(ra) # 80004a8e <fileread>
}
    8000565a:	70a2                	ld	ra,40(sp)
    8000565c:	7402                	ld	s0,32(sp)
    8000565e:	6145                	addi	sp,sp,48
    80005660:	8082                	ret

0000000080005662 <sys_write>:
{
    80005662:	7179                	addi	sp,sp,-48
    80005664:	f406                	sd	ra,40(sp)
    80005666:	f022                	sd	s0,32(sp)
    80005668:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000566a:	fd840593          	addi	a1,s0,-40
    8000566e:	4505                	li	a0,1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	8bc080e7          	jalr	-1860(ra) # 80002f2c <argaddr>
  argint(2, &n);
    80005678:	fe440593          	addi	a1,s0,-28
    8000567c:	4509                	li	a0,2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	88e080e7          	jalr	-1906(ra) # 80002f0c <argint>
  if(argfd(0, 0, &f) < 0)
    80005686:	fe840613          	addi	a2,s0,-24
    8000568a:	4581                	li	a1,0
    8000568c:	4501                	li	a0,0
    8000568e:	00000097          	auipc	ra,0x0
    80005692:	cfe080e7          	jalr	-770(ra) # 8000538c <argfd>
    80005696:	87aa                	mv	a5,a0
    return -1;
    80005698:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000569a:	0007cc63          	bltz	a5,800056b2 <sys_write+0x50>
  return filewrite(f, p, n);
    8000569e:	fe442603          	lw	a2,-28(s0)
    800056a2:	fd843583          	ld	a1,-40(s0)
    800056a6:	fe843503          	ld	a0,-24(s0)
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	4a6080e7          	jalr	1190(ra) # 80004b50 <filewrite>
}
    800056b2:	70a2                	ld	ra,40(sp)
    800056b4:	7402                	ld	s0,32(sp)
    800056b6:	6145                	addi	sp,sp,48
    800056b8:	8082                	ret

00000000800056ba <sys_close>:
{
    800056ba:	1101                	addi	sp,sp,-32
    800056bc:	ec06                	sd	ra,24(sp)
    800056be:	e822                	sd	s0,16(sp)
    800056c0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056c2:	fe040613          	addi	a2,s0,-32
    800056c6:	fec40593          	addi	a1,s0,-20
    800056ca:	4501                	li	a0,0
    800056cc:	00000097          	auipc	ra,0x0
    800056d0:	cc0080e7          	jalr	-832(ra) # 8000538c <argfd>
    return -1;
    800056d4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056d6:	02054463          	bltz	a0,800056fe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056da:	ffffc097          	auipc	ra,0xffffc
    800056de:	2d2080e7          	jalr	722(ra) # 800019ac <myproc>
    800056e2:	fec42783          	lw	a5,-20(s0)
    800056e6:	07e9                	addi	a5,a5,26
    800056e8:	078e                	slli	a5,a5,0x3
    800056ea:	953e                	add	a0,a0,a5
    800056ec:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800056f0:	fe043503          	ld	a0,-32(s0)
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	260080e7          	jalr	608(ra) # 80004954 <fileclose>
  return 0;
    800056fc:	4781                	li	a5,0
}
    800056fe:	853e                	mv	a0,a5
    80005700:	60e2                	ld	ra,24(sp)
    80005702:	6442                	ld	s0,16(sp)
    80005704:	6105                	addi	sp,sp,32
    80005706:	8082                	ret

0000000080005708 <sys_fstat>:
{
    80005708:	1101                	addi	sp,sp,-32
    8000570a:	ec06                	sd	ra,24(sp)
    8000570c:	e822                	sd	s0,16(sp)
    8000570e:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005710:	fe040593          	addi	a1,s0,-32
    80005714:	4505                	li	a0,1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	816080e7          	jalr	-2026(ra) # 80002f2c <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000571e:	fe840613          	addi	a2,s0,-24
    80005722:	4581                	li	a1,0
    80005724:	4501                	li	a0,0
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	c66080e7          	jalr	-922(ra) # 8000538c <argfd>
    8000572e:	87aa                	mv	a5,a0
    return -1;
    80005730:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005732:	0007ca63          	bltz	a5,80005746 <sys_fstat+0x3e>
  return filestat(f, st);
    80005736:	fe043583          	ld	a1,-32(s0)
    8000573a:	fe843503          	ld	a0,-24(s0)
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	2de080e7          	jalr	734(ra) # 80004a1c <filestat>
}
    80005746:	60e2                	ld	ra,24(sp)
    80005748:	6442                	ld	s0,16(sp)
    8000574a:	6105                	addi	sp,sp,32
    8000574c:	8082                	ret

000000008000574e <sys_link>:
{
    8000574e:	7169                	addi	sp,sp,-304
    80005750:	f606                	sd	ra,296(sp)
    80005752:	f222                	sd	s0,288(sp)
    80005754:	ee26                	sd	s1,280(sp)
    80005756:	ea4a                	sd	s2,272(sp)
    80005758:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000575a:	08000613          	li	a2,128
    8000575e:	ed040593          	addi	a1,s0,-304
    80005762:	4501                	li	a0,0
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	7e8080e7          	jalr	2024(ra) # 80002f4c <argstr>
    return -1;
    8000576c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000576e:	10054e63          	bltz	a0,8000588a <sys_link+0x13c>
    80005772:	08000613          	li	a2,128
    80005776:	f5040593          	addi	a1,s0,-176
    8000577a:	4505                	li	a0,1
    8000577c:	ffffd097          	auipc	ra,0xffffd
    80005780:	7d0080e7          	jalr	2000(ra) # 80002f4c <argstr>
    return -1;
    80005784:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005786:	10054263          	bltz	a0,8000588a <sys_link+0x13c>
  begin_op();
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	d02080e7          	jalr	-766(ra) # 8000448c <begin_op>
  if((ip = namei(old)) == 0){
    80005792:	ed040513          	addi	a0,s0,-304
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	ad6080e7          	jalr	-1322(ra) # 8000426c <namei>
    8000579e:	84aa                	mv	s1,a0
    800057a0:	c551                	beqz	a0,8000582c <sys_link+0xde>
  ilock(ip);
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	31e080e7          	jalr	798(ra) # 80003ac0 <ilock>
  if(ip->type == T_DIR){
    800057aa:	04449703          	lh	a4,68(s1)
    800057ae:	4785                	li	a5,1
    800057b0:	08f70463          	beq	a4,a5,80005838 <sys_link+0xea>
  ip->nlink++;
    800057b4:	04a4d783          	lhu	a5,74(s1)
    800057b8:	2785                	addiw	a5,a5,1
    800057ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	234080e7          	jalr	564(ra) # 800039f4 <iupdate>
  iunlock(ip);
    800057c8:	8526                	mv	a0,s1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	3b8080e7          	jalr	952(ra) # 80003b82 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057d2:	fd040593          	addi	a1,s0,-48
    800057d6:	f5040513          	addi	a0,s0,-176
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	ab0080e7          	jalr	-1360(ra) # 8000428a <nameiparent>
    800057e2:	892a                	mv	s2,a0
    800057e4:	c935                	beqz	a0,80005858 <sys_link+0x10a>
  ilock(dp);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	2da080e7          	jalr	730(ra) # 80003ac0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057ee:	00092703          	lw	a4,0(s2)
    800057f2:	409c                	lw	a5,0(s1)
    800057f4:	04f71d63          	bne	a4,a5,8000584e <sys_link+0x100>
    800057f8:	40d0                	lw	a2,4(s1)
    800057fa:	fd040593          	addi	a1,s0,-48
    800057fe:	854a                	mv	a0,s2
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	9ba080e7          	jalr	-1606(ra) # 800041ba <dirlink>
    80005808:	04054363          	bltz	a0,8000584e <sys_link+0x100>
  iunlockput(dp);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	514080e7          	jalr	1300(ra) # 80003d22 <iunlockput>
  iput(ip);
    80005816:	8526                	mv	a0,s1
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	462080e7          	jalr	1122(ra) # 80003c7a <iput>
  end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	cea080e7          	jalr	-790(ra) # 8000450a <end_op>
  return 0;
    80005828:	4781                	li	a5,0
    8000582a:	a085                	j	8000588a <sys_link+0x13c>
    end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	cde080e7          	jalr	-802(ra) # 8000450a <end_op>
    return -1;
    80005834:	57fd                	li	a5,-1
    80005836:	a891                	j	8000588a <sys_link+0x13c>
    iunlockput(ip);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	4e8080e7          	jalr	1256(ra) # 80003d22 <iunlockput>
    end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	cc8080e7          	jalr	-824(ra) # 8000450a <end_op>
    return -1;
    8000584a:	57fd                	li	a5,-1
    8000584c:	a83d                	j	8000588a <sys_link+0x13c>
    iunlockput(dp);
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	4d2080e7          	jalr	1234(ra) # 80003d22 <iunlockput>
  ilock(ip);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	266080e7          	jalr	614(ra) # 80003ac0 <ilock>
  ip->nlink--;
    80005862:	04a4d783          	lhu	a5,74(s1)
    80005866:	37fd                	addiw	a5,a5,-1
    80005868:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	186080e7          	jalr	390(ra) # 800039f4 <iupdate>
  iunlockput(ip);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	4aa080e7          	jalr	1194(ra) # 80003d22 <iunlockput>
  end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	c8a080e7          	jalr	-886(ra) # 8000450a <end_op>
  return -1;
    80005888:	57fd                	li	a5,-1
}
    8000588a:	853e                	mv	a0,a5
    8000588c:	70b2                	ld	ra,296(sp)
    8000588e:	7412                	ld	s0,288(sp)
    80005890:	64f2                	ld	s1,280(sp)
    80005892:	6952                	ld	s2,272(sp)
    80005894:	6155                	addi	sp,sp,304
    80005896:	8082                	ret

0000000080005898 <sys_unlink>:
{
    80005898:	7151                	addi	sp,sp,-240
    8000589a:	f586                	sd	ra,232(sp)
    8000589c:	f1a2                	sd	s0,224(sp)
    8000589e:	eda6                	sd	s1,216(sp)
    800058a0:	e9ca                	sd	s2,208(sp)
    800058a2:	e5ce                	sd	s3,200(sp)
    800058a4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058a6:	08000613          	li	a2,128
    800058aa:	f3040593          	addi	a1,s0,-208
    800058ae:	4501                	li	a0,0
    800058b0:	ffffd097          	auipc	ra,0xffffd
    800058b4:	69c080e7          	jalr	1692(ra) # 80002f4c <argstr>
    800058b8:	18054163          	bltz	a0,80005a3a <sys_unlink+0x1a2>
  begin_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	bd0080e7          	jalr	-1072(ra) # 8000448c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058c4:	fb040593          	addi	a1,s0,-80
    800058c8:	f3040513          	addi	a0,s0,-208
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	9be080e7          	jalr	-1602(ra) # 8000428a <nameiparent>
    800058d4:	84aa                	mv	s1,a0
    800058d6:	c979                	beqz	a0,800059ac <sys_unlink+0x114>
  ilock(dp);
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	1e8080e7          	jalr	488(ra) # 80003ac0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058e0:	00003597          	auipc	a1,0x3
    800058e4:	e9058593          	addi	a1,a1,-368 # 80008770 <syscalls+0x2c0>
    800058e8:	fb040513          	addi	a0,s0,-80
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	69e080e7          	jalr	1694(ra) # 80003f8a <namecmp>
    800058f4:	14050a63          	beqz	a0,80005a48 <sys_unlink+0x1b0>
    800058f8:	00003597          	auipc	a1,0x3
    800058fc:	e8058593          	addi	a1,a1,-384 # 80008778 <syscalls+0x2c8>
    80005900:	fb040513          	addi	a0,s0,-80
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	686080e7          	jalr	1670(ra) # 80003f8a <namecmp>
    8000590c:	12050e63          	beqz	a0,80005a48 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005910:	f2c40613          	addi	a2,s0,-212
    80005914:	fb040593          	addi	a1,s0,-80
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	68a080e7          	jalr	1674(ra) # 80003fa4 <dirlookup>
    80005922:	892a                	mv	s2,a0
    80005924:	12050263          	beqz	a0,80005a48 <sys_unlink+0x1b0>
  ilock(ip);
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	198080e7          	jalr	408(ra) # 80003ac0 <ilock>
  if(ip->nlink < 1)
    80005930:	04a91783          	lh	a5,74(s2)
    80005934:	08f05263          	blez	a5,800059b8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005938:	04491703          	lh	a4,68(s2)
    8000593c:	4785                	li	a5,1
    8000593e:	08f70563          	beq	a4,a5,800059c8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005942:	4641                	li	a2,16
    80005944:	4581                	li	a1,0
    80005946:	fc040513          	addi	a0,s0,-64
    8000594a:	ffffb097          	auipc	ra,0xffffb
    8000594e:	388080e7          	jalr	904(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005952:	4741                	li	a4,16
    80005954:	f2c42683          	lw	a3,-212(s0)
    80005958:	fc040613          	addi	a2,s0,-64
    8000595c:	4581                	li	a1,0
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	50c080e7          	jalr	1292(ra) # 80003e6c <writei>
    80005968:	47c1                	li	a5,16
    8000596a:	0af51563          	bne	a0,a5,80005a14 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000596e:	04491703          	lh	a4,68(s2)
    80005972:	4785                	li	a5,1
    80005974:	0af70863          	beq	a4,a5,80005a24 <sys_unlink+0x18c>
  iunlockput(dp);
    80005978:	8526                	mv	a0,s1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	3a8080e7          	jalr	936(ra) # 80003d22 <iunlockput>
  ip->nlink--;
    80005982:	04a95783          	lhu	a5,74(s2)
    80005986:	37fd                	addiw	a5,a5,-1
    80005988:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000598c:	854a                	mv	a0,s2
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	066080e7          	jalr	102(ra) # 800039f4 <iupdate>
  iunlockput(ip);
    80005996:	854a                	mv	a0,s2
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	38a080e7          	jalr	906(ra) # 80003d22 <iunlockput>
  end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	b6a080e7          	jalr	-1174(ra) # 8000450a <end_op>
  return 0;
    800059a8:	4501                	li	a0,0
    800059aa:	a84d                	j	80005a5c <sys_unlink+0x1c4>
    end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	b5e080e7          	jalr	-1186(ra) # 8000450a <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	a05d                	j	80005a5c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059b8:	00003517          	auipc	a0,0x3
    800059bc:	dc850513          	addi	a0,a0,-568 # 80008780 <syscalls+0x2d0>
    800059c0:	ffffb097          	auipc	ra,0xffffb
    800059c4:	b80080e7          	jalr	-1152(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059c8:	04c92703          	lw	a4,76(s2)
    800059cc:	02000793          	li	a5,32
    800059d0:	f6e7f9e3          	bgeu	a5,a4,80005942 <sys_unlink+0xaa>
    800059d4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d8:	4741                	li	a4,16
    800059da:	86ce                	mv	a3,s3
    800059dc:	f1840613          	addi	a2,s0,-232
    800059e0:	4581                	li	a1,0
    800059e2:	854a                	mv	a0,s2
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	390080e7          	jalr	912(ra) # 80003d74 <readi>
    800059ec:	47c1                	li	a5,16
    800059ee:	00f51b63          	bne	a0,a5,80005a04 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059f2:	f1845783          	lhu	a5,-232(s0)
    800059f6:	e7a1                	bnez	a5,80005a3e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059f8:	29c1                	addiw	s3,s3,16
    800059fa:	04c92783          	lw	a5,76(s2)
    800059fe:	fcf9ede3          	bltu	s3,a5,800059d8 <sys_unlink+0x140>
    80005a02:	b781                	j	80005942 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a04:	00003517          	auipc	a0,0x3
    80005a08:	d9450513          	addi	a0,a0,-620 # 80008798 <syscalls+0x2e8>
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	b34080e7          	jalr	-1228(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a14:	00003517          	auipc	a0,0x3
    80005a18:	d9c50513          	addi	a0,a0,-612 # 800087b0 <syscalls+0x300>
    80005a1c:	ffffb097          	auipc	ra,0xffffb
    80005a20:	b24080e7          	jalr	-1244(ra) # 80000540 <panic>
    dp->nlink--;
    80005a24:	04a4d783          	lhu	a5,74(s1)
    80005a28:	37fd                	addiw	a5,a5,-1
    80005a2a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	fc4080e7          	jalr	-60(ra) # 800039f4 <iupdate>
    80005a38:	b781                	j	80005978 <sys_unlink+0xe0>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	a005                	j	80005a5c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a3e:	854a                	mv	a0,s2
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	2e2080e7          	jalr	738(ra) # 80003d22 <iunlockput>
  iunlockput(dp);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	2d8080e7          	jalr	728(ra) # 80003d22 <iunlockput>
  end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	ab8080e7          	jalr	-1352(ra) # 8000450a <end_op>
  return -1;
    80005a5a:	557d                	li	a0,-1
}
    80005a5c:	70ae                	ld	ra,232(sp)
    80005a5e:	740e                	ld	s0,224(sp)
    80005a60:	64ee                	ld	s1,216(sp)
    80005a62:	694e                	ld	s2,208(sp)
    80005a64:	69ae                	ld	s3,200(sp)
    80005a66:	616d                	addi	sp,sp,240
    80005a68:	8082                	ret

0000000080005a6a <sys_open>:

uint64
sys_open(void)
{
    80005a6a:	7131                	addi	sp,sp,-192
    80005a6c:	fd06                	sd	ra,184(sp)
    80005a6e:	f922                	sd	s0,176(sp)
    80005a70:	f526                	sd	s1,168(sp)
    80005a72:	f14a                	sd	s2,160(sp)
    80005a74:	ed4e                	sd	s3,152(sp)
    80005a76:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a78:	f4c40593          	addi	a1,s0,-180
    80005a7c:	4505                	li	a0,1
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	48e080e7          	jalr	1166(ra) # 80002f0c <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a86:	08000613          	li	a2,128
    80005a8a:	f5040593          	addi	a1,s0,-176
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	4bc080e7          	jalr	1212(ra) # 80002f4c <argstr>
    80005a98:	87aa                	mv	a5,a0
    return -1;
    80005a9a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a9c:	0a07c963          	bltz	a5,80005b4e <sys_open+0xe4>

  begin_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	9ec080e7          	jalr	-1556(ra) # 8000448c <begin_op>

  if(omode & O_CREATE){
    80005aa8:	f4c42783          	lw	a5,-180(s0)
    80005aac:	2007f793          	andi	a5,a5,512
    80005ab0:	cfc5                	beqz	a5,80005b68 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ab2:	4681                	li	a3,0
    80005ab4:	4601                	li	a2,0
    80005ab6:	4589                	li	a1,2
    80005ab8:	f5040513          	addi	a0,s0,-176
    80005abc:	00000097          	auipc	ra,0x0
    80005ac0:	972080e7          	jalr	-1678(ra) # 8000542e <create>
    80005ac4:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ac6:	c959                	beqz	a0,80005b5c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ac8:	04449703          	lh	a4,68(s1)
    80005acc:	478d                	li	a5,3
    80005ace:	00f71763          	bne	a4,a5,80005adc <sys_open+0x72>
    80005ad2:	0464d703          	lhu	a4,70(s1)
    80005ad6:	47a5                	li	a5,9
    80005ad8:	0ce7ed63          	bltu	a5,a4,80005bb2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	dbc080e7          	jalr	-580(ra) # 80004898 <filealloc>
    80005ae4:	89aa                	mv	s3,a0
    80005ae6:	10050363          	beqz	a0,80005bec <sys_open+0x182>
    80005aea:	00000097          	auipc	ra,0x0
    80005aee:	902080e7          	jalr	-1790(ra) # 800053ec <fdalloc>
    80005af2:	892a                	mv	s2,a0
    80005af4:	0e054763          	bltz	a0,80005be2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005af8:	04449703          	lh	a4,68(s1)
    80005afc:	478d                	li	a5,3
    80005afe:	0cf70563          	beq	a4,a5,80005bc8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b02:	4789                	li	a5,2
    80005b04:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b08:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b0c:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b10:	f4c42783          	lw	a5,-180(s0)
    80005b14:	0017c713          	xori	a4,a5,1
    80005b18:	8b05                	andi	a4,a4,1
    80005b1a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b1e:	0037f713          	andi	a4,a5,3
    80005b22:	00e03733          	snez	a4,a4
    80005b26:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b2a:	4007f793          	andi	a5,a5,1024
    80005b2e:	c791                	beqz	a5,80005b3a <sys_open+0xd0>
    80005b30:	04449703          	lh	a4,68(s1)
    80005b34:	4789                	li	a5,2
    80005b36:	0af70063          	beq	a4,a5,80005bd6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	046080e7          	jalr	70(ra) # 80003b82 <iunlock>
  end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	9c6080e7          	jalr	-1594(ra) # 8000450a <end_op>

  return fd;
    80005b4c:	854a                	mv	a0,s2
}
    80005b4e:	70ea                	ld	ra,184(sp)
    80005b50:	744a                	ld	s0,176(sp)
    80005b52:	74aa                	ld	s1,168(sp)
    80005b54:	790a                	ld	s2,160(sp)
    80005b56:	69ea                	ld	s3,152(sp)
    80005b58:	6129                	addi	sp,sp,192
    80005b5a:	8082                	ret
      end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	9ae080e7          	jalr	-1618(ra) # 8000450a <end_op>
      return -1;
    80005b64:	557d                	li	a0,-1
    80005b66:	b7e5                	j	80005b4e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b68:	f5040513          	addi	a0,s0,-176
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	700080e7          	jalr	1792(ra) # 8000426c <namei>
    80005b74:	84aa                	mv	s1,a0
    80005b76:	c905                	beqz	a0,80005ba6 <sys_open+0x13c>
    ilock(ip);
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	f48080e7          	jalr	-184(ra) # 80003ac0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b80:	04449703          	lh	a4,68(s1)
    80005b84:	4785                	li	a5,1
    80005b86:	f4f711e3          	bne	a4,a5,80005ac8 <sys_open+0x5e>
    80005b8a:	f4c42783          	lw	a5,-180(s0)
    80005b8e:	d7b9                	beqz	a5,80005adc <sys_open+0x72>
      iunlockput(ip);
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	190080e7          	jalr	400(ra) # 80003d22 <iunlockput>
      end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	970080e7          	jalr	-1680(ra) # 8000450a <end_op>
      return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	b76d                	j	80005b4e <sys_open+0xe4>
      end_op();
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	964080e7          	jalr	-1692(ra) # 8000450a <end_op>
      return -1;
    80005bae:	557d                	li	a0,-1
    80005bb0:	bf79                	j	80005b4e <sys_open+0xe4>
    iunlockput(ip);
    80005bb2:	8526                	mv	a0,s1
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	16e080e7          	jalr	366(ra) # 80003d22 <iunlockput>
    end_op();
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	94e080e7          	jalr	-1714(ra) # 8000450a <end_op>
    return -1;
    80005bc4:	557d                	li	a0,-1
    80005bc6:	b761                	j	80005b4e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bc8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bcc:	04649783          	lh	a5,70(s1)
    80005bd0:	02f99223          	sh	a5,36(s3)
    80005bd4:	bf25                	j	80005b0c <sys_open+0xa2>
    itrunc(ip);
    80005bd6:	8526                	mv	a0,s1
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	ff6080e7          	jalr	-10(ra) # 80003bce <itrunc>
    80005be0:	bfa9                	j	80005b3a <sys_open+0xd0>
      fileclose(f);
    80005be2:	854e                	mv	a0,s3
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	d70080e7          	jalr	-656(ra) # 80004954 <fileclose>
    iunlockput(ip);
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	134080e7          	jalr	308(ra) # 80003d22 <iunlockput>
    end_op();
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	914080e7          	jalr	-1772(ra) # 8000450a <end_op>
    return -1;
    80005bfe:	557d                	li	a0,-1
    80005c00:	b7b9                	j	80005b4e <sys_open+0xe4>

0000000080005c02 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c02:	7175                	addi	sp,sp,-144
    80005c04:	e506                	sd	ra,136(sp)
    80005c06:	e122                	sd	s0,128(sp)
    80005c08:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	882080e7          	jalr	-1918(ra) # 8000448c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c12:	08000613          	li	a2,128
    80005c16:	f7040593          	addi	a1,s0,-144
    80005c1a:	4501                	li	a0,0
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	330080e7          	jalr	816(ra) # 80002f4c <argstr>
    80005c24:	02054963          	bltz	a0,80005c56 <sys_mkdir+0x54>
    80005c28:	4681                	li	a3,0
    80005c2a:	4601                	li	a2,0
    80005c2c:	4585                	li	a1,1
    80005c2e:	f7040513          	addi	a0,s0,-144
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	7fc080e7          	jalr	2044(ra) # 8000542e <create>
    80005c3a:	cd11                	beqz	a0,80005c56 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	0e6080e7          	jalr	230(ra) # 80003d22 <iunlockput>
  end_op();
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	8c6080e7          	jalr	-1850(ra) # 8000450a <end_op>
  return 0;
    80005c4c:	4501                	li	a0,0
}
    80005c4e:	60aa                	ld	ra,136(sp)
    80005c50:	640a                	ld	s0,128(sp)
    80005c52:	6149                	addi	sp,sp,144
    80005c54:	8082                	ret
    end_op();
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	8b4080e7          	jalr	-1868(ra) # 8000450a <end_op>
    return -1;
    80005c5e:	557d                	li	a0,-1
    80005c60:	b7fd                	j	80005c4e <sys_mkdir+0x4c>

0000000080005c62 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c62:	7135                	addi	sp,sp,-160
    80005c64:	ed06                	sd	ra,152(sp)
    80005c66:	e922                	sd	s0,144(sp)
    80005c68:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	822080e7          	jalr	-2014(ra) # 8000448c <begin_op>
  argint(1, &major);
    80005c72:	f6c40593          	addi	a1,s0,-148
    80005c76:	4505                	li	a0,1
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	294080e7          	jalr	660(ra) # 80002f0c <argint>
  argint(2, &minor);
    80005c80:	f6840593          	addi	a1,s0,-152
    80005c84:	4509                	li	a0,2
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	286080e7          	jalr	646(ra) # 80002f0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c8e:	08000613          	li	a2,128
    80005c92:	f7040593          	addi	a1,s0,-144
    80005c96:	4501                	li	a0,0
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	2b4080e7          	jalr	692(ra) # 80002f4c <argstr>
    80005ca0:	02054b63          	bltz	a0,80005cd6 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ca4:	f6841683          	lh	a3,-152(s0)
    80005ca8:	f6c41603          	lh	a2,-148(s0)
    80005cac:	458d                	li	a1,3
    80005cae:	f7040513          	addi	a0,s0,-144
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	77c080e7          	jalr	1916(ra) # 8000542e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cba:	cd11                	beqz	a0,80005cd6 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	066080e7          	jalr	102(ra) # 80003d22 <iunlockput>
  end_op();
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	846080e7          	jalr	-1978(ra) # 8000450a <end_op>
  return 0;
    80005ccc:	4501                	li	a0,0
}
    80005cce:	60ea                	ld	ra,152(sp)
    80005cd0:	644a                	ld	s0,144(sp)
    80005cd2:	610d                	addi	sp,sp,160
    80005cd4:	8082                	ret
    end_op();
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	834080e7          	jalr	-1996(ra) # 8000450a <end_op>
    return -1;
    80005cde:	557d                	li	a0,-1
    80005ce0:	b7fd                	j	80005cce <sys_mknod+0x6c>

0000000080005ce2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ce2:	7135                	addi	sp,sp,-160
    80005ce4:	ed06                	sd	ra,152(sp)
    80005ce6:	e922                	sd	s0,144(sp)
    80005ce8:	e526                	sd	s1,136(sp)
    80005cea:	e14a                	sd	s2,128(sp)
    80005cec:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cee:	ffffc097          	auipc	ra,0xffffc
    80005cf2:	cbe080e7          	jalr	-834(ra) # 800019ac <myproc>
    80005cf6:	892a                	mv	s2,a0
  
  begin_op();
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	794080e7          	jalr	1940(ra) # 8000448c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d00:	08000613          	li	a2,128
    80005d04:	f6040593          	addi	a1,s0,-160
    80005d08:	4501                	li	a0,0
    80005d0a:	ffffd097          	auipc	ra,0xffffd
    80005d0e:	242080e7          	jalr	578(ra) # 80002f4c <argstr>
    80005d12:	04054b63          	bltz	a0,80005d68 <sys_chdir+0x86>
    80005d16:	f6040513          	addi	a0,s0,-160
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	552080e7          	jalr	1362(ra) # 8000426c <namei>
    80005d22:	84aa                	mv	s1,a0
    80005d24:	c131                	beqz	a0,80005d68 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	d9a080e7          	jalr	-614(ra) # 80003ac0 <ilock>
  if(ip->type != T_DIR){
    80005d2e:	04449703          	lh	a4,68(s1)
    80005d32:	4785                	li	a5,1
    80005d34:	04f71063          	bne	a4,a5,80005d74 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d38:	8526                	mv	a0,s1
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	e48080e7          	jalr	-440(ra) # 80003b82 <iunlock>
  iput(p->cwd);
    80005d42:	15093503          	ld	a0,336(s2)
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	f34080e7          	jalr	-204(ra) # 80003c7a <iput>
  end_op();
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	7bc080e7          	jalr	1980(ra) # 8000450a <end_op>
  p->cwd = ip;
    80005d56:	14993823          	sd	s1,336(s2)
  return 0;
    80005d5a:	4501                	li	a0,0
}
    80005d5c:	60ea                	ld	ra,152(sp)
    80005d5e:	644a                	ld	s0,144(sp)
    80005d60:	64aa                	ld	s1,136(sp)
    80005d62:	690a                	ld	s2,128(sp)
    80005d64:	610d                	addi	sp,sp,160
    80005d66:	8082                	ret
    end_op();
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	7a2080e7          	jalr	1954(ra) # 8000450a <end_op>
    return -1;
    80005d70:	557d                	li	a0,-1
    80005d72:	b7ed                	j	80005d5c <sys_chdir+0x7a>
    iunlockput(ip);
    80005d74:	8526                	mv	a0,s1
    80005d76:	ffffe097          	auipc	ra,0xffffe
    80005d7a:	fac080e7          	jalr	-84(ra) # 80003d22 <iunlockput>
    end_op();
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	78c080e7          	jalr	1932(ra) # 8000450a <end_op>
    return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	bfd1                	j	80005d5c <sys_chdir+0x7a>

0000000080005d8a <sys_exec>:

uint64
sys_exec(void)
{
    80005d8a:	7145                	addi	sp,sp,-464
    80005d8c:	e786                	sd	ra,456(sp)
    80005d8e:	e3a2                	sd	s0,448(sp)
    80005d90:	ff26                	sd	s1,440(sp)
    80005d92:	fb4a                	sd	s2,432(sp)
    80005d94:	f74e                	sd	s3,424(sp)
    80005d96:	f352                	sd	s4,416(sp)
    80005d98:	ef56                	sd	s5,408(sp)
    80005d9a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d9c:	e3840593          	addi	a1,s0,-456
    80005da0:	4505                	li	a0,1
    80005da2:	ffffd097          	auipc	ra,0xffffd
    80005da6:	18a080e7          	jalr	394(ra) # 80002f2c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005daa:	08000613          	li	a2,128
    80005dae:	f4040593          	addi	a1,s0,-192
    80005db2:	4501                	li	a0,0
    80005db4:	ffffd097          	auipc	ra,0xffffd
    80005db8:	198080e7          	jalr	408(ra) # 80002f4c <argstr>
    80005dbc:	87aa                	mv	a5,a0
    return -1;
    80005dbe:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005dc0:	0c07c363          	bltz	a5,80005e86 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005dc4:	10000613          	li	a2,256
    80005dc8:	4581                	li	a1,0
    80005dca:	e4040513          	addi	a0,s0,-448
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	f04080e7          	jalr	-252(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dd6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dda:	89a6                	mv	s3,s1
    80005ddc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dde:	02000a13          	li	s4,32
    80005de2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005de6:	00391513          	slli	a0,s2,0x3
    80005dea:	e3040593          	addi	a1,s0,-464
    80005dee:	e3843783          	ld	a5,-456(s0)
    80005df2:	953e                	add	a0,a0,a5
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	07a080e7          	jalr	122(ra) # 80002e6e <fetchaddr>
    80005dfc:	02054a63          	bltz	a0,80005e30 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e00:	e3043783          	ld	a5,-464(s0)
    80005e04:	c3b9                	beqz	a5,80005e4a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e06:	ffffb097          	auipc	ra,0xffffb
    80005e0a:	ce0080e7          	jalr	-800(ra) # 80000ae6 <kalloc>
    80005e0e:	85aa                	mv	a1,a0
    80005e10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e14:	cd11                	beqz	a0,80005e30 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e16:	6605                	lui	a2,0x1
    80005e18:	e3043503          	ld	a0,-464(s0)
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	0a4080e7          	jalr	164(ra) # 80002ec0 <fetchstr>
    80005e24:	00054663          	bltz	a0,80005e30 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e28:	0905                	addi	s2,s2,1
    80005e2a:	09a1                	addi	s3,s3,8
    80005e2c:	fb491be3          	bne	s2,s4,80005de2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e30:	f4040913          	addi	s2,s0,-192
    80005e34:	6088                	ld	a0,0(s1)
    80005e36:	c539                	beqz	a0,80005e84 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e38:	ffffb097          	auipc	ra,0xffffb
    80005e3c:	bb0080e7          	jalr	-1104(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e40:	04a1                	addi	s1,s1,8
    80005e42:	ff2499e3          	bne	s1,s2,80005e34 <sys_exec+0xaa>
  return -1;
    80005e46:	557d                	li	a0,-1
    80005e48:	a83d                	j	80005e86 <sys_exec+0xfc>
      argv[i] = 0;
    80005e4a:	0a8e                	slli	s5,s5,0x3
    80005e4c:	fc0a8793          	addi	a5,s5,-64
    80005e50:	00878ab3          	add	s5,a5,s0
    80005e54:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e58:	e4040593          	addi	a1,s0,-448
    80005e5c:	f4040513          	addi	a0,s0,-192
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	16e080e7          	jalr	366(ra) # 80004fce <exec>
    80005e68:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e6a:	f4040993          	addi	s3,s0,-192
    80005e6e:	6088                	ld	a0,0(s1)
    80005e70:	c901                	beqz	a0,80005e80 <sys_exec+0xf6>
    kfree(argv[i]);
    80005e72:	ffffb097          	auipc	ra,0xffffb
    80005e76:	b76080e7          	jalr	-1162(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e7a:	04a1                	addi	s1,s1,8
    80005e7c:	ff3499e3          	bne	s1,s3,80005e6e <sys_exec+0xe4>
  return ret;
    80005e80:	854a                	mv	a0,s2
    80005e82:	a011                	j	80005e86 <sys_exec+0xfc>
  return -1;
    80005e84:	557d                	li	a0,-1
}
    80005e86:	60be                	ld	ra,456(sp)
    80005e88:	641e                	ld	s0,448(sp)
    80005e8a:	74fa                	ld	s1,440(sp)
    80005e8c:	795a                	ld	s2,432(sp)
    80005e8e:	79ba                	ld	s3,424(sp)
    80005e90:	7a1a                	ld	s4,416(sp)
    80005e92:	6afa                	ld	s5,408(sp)
    80005e94:	6179                	addi	sp,sp,464
    80005e96:	8082                	ret

0000000080005e98 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e98:	7139                	addi	sp,sp,-64
    80005e9a:	fc06                	sd	ra,56(sp)
    80005e9c:	f822                	sd	s0,48(sp)
    80005e9e:	f426                	sd	s1,40(sp)
    80005ea0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ea2:	ffffc097          	auipc	ra,0xffffc
    80005ea6:	b0a080e7          	jalr	-1270(ra) # 800019ac <myproc>
    80005eaa:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005eac:	fd840593          	addi	a1,s0,-40
    80005eb0:	4501                	li	a0,0
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	07a080e7          	jalr	122(ra) # 80002f2c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005eba:	fc840593          	addi	a1,s0,-56
    80005ebe:	fd040513          	addi	a0,s0,-48
    80005ec2:	fffff097          	auipc	ra,0xfffff
    80005ec6:	dc2080e7          	jalr	-574(ra) # 80004c84 <pipealloc>
    return -1;
    80005eca:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ecc:	0c054463          	bltz	a0,80005f94 <sys_pipe+0xfc>
  fd0 = -1;
    80005ed0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ed4:	fd043503          	ld	a0,-48(s0)
    80005ed8:	fffff097          	auipc	ra,0xfffff
    80005edc:	514080e7          	jalr	1300(ra) # 800053ec <fdalloc>
    80005ee0:	fca42223          	sw	a0,-60(s0)
    80005ee4:	08054b63          	bltz	a0,80005f7a <sys_pipe+0xe2>
    80005ee8:	fc843503          	ld	a0,-56(s0)
    80005eec:	fffff097          	auipc	ra,0xfffff
    80005ef0:	500080e7          	jalr	1280(ra) # 800053ec <fdalloc>
    80005ef4:	fca42023          	sw	a0,-64(s0)
    80005ef8:	06054863          	bltz	a0,80005f68 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005efc:	4691                	li	a3,4
    80005efe:	fc440613          	addi	a2,s0,-60
    80005f02:	fd843583          	ld	a1,-40(s0)
    80005f06:	68a8                	ld	a0,80(s1)
    80005f08:	ffffb097          	auipc	ra,0xffffb
    80005f0c:	764080e7          	jalr	1892(ra) # 8000166c <copyout>
    80005f10:	02054063          	bltz	a0,80005f30 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f14:	4691                	li	a3,4
    80005f16:	fc040613          	addi	a2,s0,-64
    80005f1a:	fd843583          	ld	a1,-40(s0)
    80005f1e:	0591                	addi	a1,a1,4
    80005f20:	68a8                	ld	a0,80(s1)
    80005f22:	ffffb097          	auipc	ra,0xffffb
    80005f26:	74a080e7          	jalr	1866(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f2a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f2c:	06055463          	bgez	a0,80005f94 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f30:	fc442783          	lw	a5,-60(s0)
    80005f34:	07e9                	addi	a5,a5,26
    80005f36:	078e                	slli	a5,a5,0x3
    80005f38:	97a6                	add	a5,a5,s1
    80005f3a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f3e:	fc042783          	lw	a5,-64(s0)
    80005f42:	07e9                	addi	a5,a5,26
    80005f44:	078e                	slli	a5,a5,0x3
    80005f46:	94be                	add	s1,s1,a5
    80005f48:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f4c:	fd043503          	ld	a0,-48(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	a04080e7          	jalr	-1532(ra) # 80004954 <fileclose>
    fileclose(wf);
    80005f58:	fc843503          	ld	a0,-56(s0)
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	9f8080e7          	jalr	-1544(ra) # 80004954 <fileclose>
    return -1;
    80005f64:	57fd                	li	a5,-1
    80005f66:	a03d                	j	80005f94 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f68:	fc442783          	lw	a5,-60(s0)
    80005f6c:	0007c763          	bltz	a5,80005f7a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f70:	07e9                	addi	a5,a5,26
    80005f72:	078e                	slli	a5,a5,0x3
    80005f74:	97a6                	add	a5,a5,s1
    80005f76:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005f7a:	fd043503          	ld	a0,-48(s0)
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	9d6080e7          	jalr	-1578(ra) # 80004954 <fileclose>
    fileclose(wf);
    80005f86:	fc843503          	ld	a0,-56(s0)
    80005f8a:	fffff097          	auipc	ra,0xfffff
    80005f8e:	9ca080e7          	jalr	-1590(ra) # 80004954 <fileclose>
    return -1;
    80005f92:	57fd                	li	a5,-1
}
    80005f94:	853e                	mv	a0,a5
    80005f96:	70e2                	ld	ra,56(sp)
    80005f98:	7442                	ld	s0,48(sp)
    80005f9a:	74a2                	ld	s1,40(sp)
    80005f9c:	6121                	addi	sp,sp,64
    80005f9e:	8082                	ret

0000000080005fa0 <kernelvec>:
    80005fa0:	7111                	addi	sp,sp,-256
    80005fa2:	e006                	sd	ra,0(sp)
    80005fa4:	e40a                	sd	sp,8(sp)
    80005fa6:	e80e                	sd	gp,16(sp)
    80005fa8:	ec12                	sd	tp,24(sp)
    80005faa:	f016                	sd	t0,32(sp)
    80005fac:	f41a                	sd	t1,40(sp)
    80005fae:	f81e                	sd	t2,48(sp)
    80005fb0:	fc22                	sd	s0,56(sp)
    80005fb2:	e0a6                	sd	s1,64(sp)
    80005fb4:	e4aa                	sd	a0,72(sp)
    80005fb6:	e8ae                	sd	a1,80(sp)
    80005fb8:	ecb2                	sd	a2,88(sp)
    80005fba:	f0b6                	sd	a3,96(sp)
    80005fbc:	f4ba                	sd	a4,104(sp)
    80005fbe:	f8be                	sd	a5,112(sp)
    80005fc0:	fcc2                	sd	a6,120(sp)
    80005fc2:	e146                	sd	a7,128(sp)
    80005fc4:	e54a                	sd	s2,136(sp)
    80005fc6:	e94e                	sd	s3,144(sp)
    80005fc8:	ed52                	sd	s4,152(sp)
    80005fca:	f156                	sd	s5,160(sp)
    80005fcc:	f55a                	sd	s6,168(sp)
    80005fce:	f95e                	sd	s7,176(sp)
    80005fd0:	fd62                	sd	s8,184(sp)
    80005fd2:	e1e6                	sd	s9,192(sp)
    80005fd4:	e5ea                	sd	s10,200(sp)
    80005fd6:	e9ee                	sd	s11,208(sp)
    80005fd8:	edf2                	sd	t3,216(sp)
    80005fda:	f1f6                	sd	t4,224(sp)
    80005fdc:	f5fa                	sd	t5,232(sp)
    80005fde:	f9fe                	sd	t6,240(sp)
    80005fe0:	d5bfc0ef          	jal	ra,80002d3a <kerneltrap>
    80005fe4:	6082                	ld	ra,0(sp)
    80005fe6:	6122                	ld	sp,8(sp)
    80005fe8:	61c2                	ld	gp,16(sp)
    80005fea:	7282                	ld	t0,32(sp)
    80005fec:	7322                	ld	t1,40(sp)
    80005fee:	73c2                	ld	t2,48(sp)
    80005ff0:	7462                	ld	s0,56(sp)
    80005ff2:	6486                	ld	s1,64(sp)
    80005ff4:	6526                	ld	a0,72(sp)
    80005ff6:	65c6                	ld	a1,80(sp)
    80005ff8:	6666                	ld	a2,88(sp)
    80005ffa:	7686                	ld	a3,96(sp)
    80005ffc:	7726                	ld	a4,104(sp)
    80005ffe:	77c6                	ld	a5,112(sp)
    80006000:	7866                	ld	a6,120(sp)
    80006002:	688a                	ld	a7,128(sp)
    80006004:	692a                	ld	s2,136(sp)
    80006006:	69ca                	ld	s3,144(sp)
    80006008:	6a6a                	ld	s4,152(sp)
    8000600a:	7a8a                	ld	s5,160(sp)
    8000600c:	7b2a                	ld	s6,168(sp)
    8000600e:	7bca                	ld	s7,176(sp)
    80006010:	7c6a                	ld	s8,184(sp)
    80006012:	6c8e                	ld	s9,192(sp)
    80006014:	6d2e                	ld	s10,200(sp)
    80006016:	6dce                	ld	s11,208(sp)
    80006018:	6e6e                	ld	t3,216(sp)
    8000601a:	7e8e                	ld	t4,224(sp)
    8000601c:	7f2e                	ld	t5,232(sp)
    8000601e:	7fce                	ld	t6,240(sp)
    80006020:	6111                	addi	sp,sp,256
    80006022:	10200073          	sret
    80006026:	00000013          	nop
    8000602a:	00000013          	nop
    8000602e:	0001                	nop

0000000080006030 <timervec>:
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	e10c                	sd	a1,0(a0)
    80006036:	e510                	sd	a2,8(a0)
    80006038:	e914                	sd	a3,16(a0)
    8000603a:	6d0c                	ld	a1,24(a0)
    8000603c:	7110                	ld	a2,32(a0)
    8000603e:	6194                	ld	a3,0(a1)
    80006040:	96b2                	add	a3,a3,a2
    80006042:	e194                	sd	a3,0(a1)
    80006044:	4589                	li	a1,2
    80006046:	14459073          	csrw	sip,a1
    8000604a:	6914                	ld	a3,16(a0)
    8000604c:	6510                	ld	a2,8(a0)
    8000604e:	610c                	ld	a1,0(a0)
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	30200073          	mret
	...

000000008000605a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000605a:	1141                	addi	sp,sp,-16
    8000605c:	e422                	sd	s0,8(sp)
    8000605e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006060:	0c0007b7          	lui	a5,0xc000
    80006064:	4705                	li	a4,1
    80006066:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006068:	c3d8                	sw	a4,4(a5)
}
    8000606a:	6422                	ld	s0,8(sp)
    8000606c:	0141                	addi	sp,sp,16
    8000606e:	8082                	ret

0000000080006070 <plicinithart>:

void
plicinithart(void)
{
    80006070:	1141                	addi	sp,sp,-16
    80006072:	e406                	sd	ra,8(sp)
    80006074:	e022                	sd	s0,0(sp)
    80006076:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	908080e7          	jalr	-1784(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006080:	0085171b          	slliw	a4,a0,0x8
    80006084:	0c0027b7          	lui	a5,0xc002
    80006088:	97ba                	add	a5,a5,a4
    8000608a:	40200713          	li	a4,1026
    8000608e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006092:	00d5151b          	slliw	a0,a0,0xd
    80006096:	0c2017b7          	lui	a5,0xc201
    8000609a:	97aa                	add	a5,a5,a0
    8000609c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060a0:	60a2                	ld	ra,8(sp)
    800060a2:	6402                	ld	s0,0(sp)
    800060a4:	0141                	addi	sp,sp,16
    800060a6:	8082                	ret

00000000800060a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060a8:	1141                	addi	sp,sp,-16
    800060aa:	e406                	sd	ra,8(sp)
    800060ac:	e022                	sd	s0,0(sp)
    800060ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	8d0080e7          	jalr	-1840(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060b8:	00d5151b          	slliw	a0,a0,0xd
    800060bc:	0c2017b7          	lui	a5,0xc201
    800060c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060c2:	43c8                	lw	a0,4(a5)
    800060c4:	60a2                	ld	ra,8(sp)
    800060c6:	6402                	ld	s0,0(sp)
    800060c8:	0141                	addi	sp,sp,16
    800060ca:	8082                	ret

00000000800060cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060cc:	1101                	addi	sp,sp,-32
    800060ce:	ec06                	sd	ra,24(sp)
    800060d0:	e822                	sd	s0,16(sp)
    800060d2:	e426                	sd	s1,8(sp)
    800060d4:	1000                	addi	s0,sp,32
    800060d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	8a8080e7          	jalr	-1880(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060e0:	00d5151b          	slliw	a0,a0,0xd
    800060e4:	0c2017b7          	lui	a5,0xc201
    800060e8:	97aa                	add	a5,a5,a0
    800060ea:	c3c4                	sw	s1,4(a5)
}
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	64a2                	ld	s1,8(sp)
    800060f2:	6105                	addi	sp,sp,32
    800060f4:	8082                	ret

00000000800060f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060f6:	1141                	addi	sp,sp,-16
    800060f8:	e406                	sd	ra,8(sp)
    800060fa:	e022                	sd	s0,0(sp)
    800060fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060fe:	479d                	li	a5,7
    80006100:	04a7cc63          	blt	a5,a0,80006158 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006104:	0001c797          	auipc	a5,0x1c
    80006108:	b9c78793          	addi	a5,a5,-1124 # 80021ca0 <disk>
    8000610c:	97aa                	add	a5,a5,a0
    8000610e:	0187c783          	lbu	a5,24(a5)
    80006112:	ebb9                	bnez	a5,80006168 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006114:	00451693          	slli	a3,a0,0x4
    80006118:	0001c797          	auipc	a5,0x1c
    8000611c:	b8878793          	addi	a5,a5,-1144 # 80021ca0 <disk>
    80006120:	6398                	ld	a4,0(a5)
    80006122:	9736                	add	a4,a4,a3
    80006124:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006128:	6398                	ld	a4,0(a5)
    8000612a:	9736                	add	a4,a4,a3
    8000612c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006130:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006134:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006138:	97aa                	add	a5,a5,a0
    8000613a:	4705                	li	a4,1
    8000613c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006140:	0001c517          	auipc	a0,0x1c
    80006144:	b7850513          	addi	a0,a0,-1160 # 80021cb8 <disk+0x18>
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	f70080e7          	jalr	-144(ra) # 800020b8 <wakeup>
}
    80006150:	60a2                	ld	ra,8(sp)
    80006152:	6402                	ld	s0,0(sp)
    80006154:	0141                	addi	sp,sp,16
    80006156:	8082                	ret
    panic("free_desc 1");
    80006158:	00002517          	auipc	a0,0x2
    8000615c:	66850513          	addi	a0,a0,1640 # 800087c0 <syscalls+0x310>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	3e0080e7          	jalr	992(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006168:	00002517          	auipc	a0,0x2
    8000616c:	66850513          	addi	a0,a0,1640 # 800087d0 <syscalls+0x320>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	3d0080e7          	jalr	976(ra) # 80000540 <panic>

0000000080006178 <virtio_disk_init>:
{
    80006178:	1101                	addi	sp,sp,-32
    8000617a:	ec06                	sd	ra,24(sp)
    8000617c:	e822                	sd	s0,16(sp)
    8000617e:	e426                	sd	s1,8(sp)
    80006180:	e04a                	sd	s2,0(sp)
    80006182:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006184:	00002597          	auipc	a1,0x2
    80006188:	65c58593          	addi	a1,a1,1628 # 800087e0 <syscalls+0x330>
    8000618c:	0001c517          	auipc	a0,0x1c
    80006190:	c3c50513          	addi	a0,a0,-964 # 80021dc8 <disk+0x128>
    80006194:	ffffb097          	auipc	ra,0xffffb
    80006198:	9b2080e7          	jalr	-1614(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	4398                	lw	a4,0(a5)
    800061a2:	2701                	sext.w	a4,a4
    800061a4:	747277b7          	lui	a5,0x74727
    800061a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ac:	14f71b63          	bne	a4,a5,80006302 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061b0:	100017b7          	lui	a5,0x10001
    800061b4:	43dc                	lw	a5,4(a5)
    800061b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b8:	4709                	li	a4,2
    800061ba:	14e79463          	bne	a5,a4,80006302 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061be:	100017b7          	lui	a5,0x10001
    800061c2:	479c                	lw	a5,8(a5)
    800061c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061c6:	12e79e63          	bne	a5,a4,80006302 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061ca:	100017b7          	lui	a5,0x10001
    800061ce:	47d8                	lw	a4,12(a5)
    800061d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061d2:	554d47b7          	lui	a5,0x554d4
    800061d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061da:	12f71463          	bne	a4,a5,80006302 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061de:	100017b7          	lui	a5,0x10001
    800061e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e6:	4705                	li	a4,1
    800061e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ea:	470d                	li	a4,3
    800061ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061ee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061f0:	c7ffe6b7          	lui	a3,0xc7ffe
    800061f4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc97f>
    800061f8:	8f75                	and	a4,a4,a3
    800061fa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061fc:	472d                	li	a4,11
    800061fe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006200:	5bbc                	lw	a5,112(a5)
    80006202:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006206:	8ba1                	andi	a5,a5,8
    80006208:	10078563          	beqz	a5,80006312 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000620c:	100017b7          	lui	a5,0x10001
    80006210:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006214:	43fc                	lw	a5,68(a5)
    80006216:	2781                	sext.w	a5,a5
    80006218:	10079563          	bnez	a5,80006322 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000621c:	100017b7          	lui	a5,0x10001
    80006220:	5bdc                	lw	a5,52(a5)
    80006222:	2781                	sext.w	a5,a5
  if(max == 0)
    80006224:	10078763          	beqz	a5,80006332 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006228:	471d                	li	a4,7
    8000622a:	10f77c63          	bgeu	a4,a5,80006342 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	8b8080e7          	jalr	-1864(ra) # 80000ae6 <kalloc>
    80006236:	0001c497          	auipc	s1,0x1c
    8000623a:	a6a48493          	addi	s1,s1,-1430 # 80021ca0 <disk>
    8000623e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	8a6080e7          	jalr	-1882(ra) # 80000ae6 <kalloc>
    80006248:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	89c080e7          	jalr	-1892(ra) # 80000ae6 <kalloc>
    80006252:	87aa                	mv	a5,a0
    80006254:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006256:	6088                	ld	a0,0(s1)
    80006258:	cd6d                	beqz	a0,80006352 <virtio_disk_init+0x1da>
    8000625a:	0001c717          	auipc	a4,0x1c
    8000625e:	a4e73703          	ld	a4,-1458(a4) # 80021ca8 <disk+0x8>
    80006262:	cb65                	beqz	a4,80006352 <virtio_disk_init+0x1da>
    80006264:	c7fd                	beqz	a5,80006352 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006266:	6605                	lui	a2,0x1
    80006268:	4581                	li	a1,0
    8000626a:	ffffb097          	auipc	ra,0xffffb
    8000626e:	a68080e7          	jalr	-1432(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006272:	0001c497          	auipc	s1,0x1c
    80006276:	a2e48493          	addi	s1,s1,-1490 # 80021ca0 <disk>
    8000627a:	6605                	lui	a2,0x1
    8000627c:	4581                	li	a1,0
    8000627e:	6488                	ld	a0,8(s1)
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	a52080e7          	jalr	-1454(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006288:	6605                	lui	a2,0x1
    8000628a:	4581                	li	a1,0
    8000628c:	6888                	ld	a0,16(s1)
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	a44080e7          	jalr	-1468(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006296:	100017b7          	lui	a5,0x10001
    8000629a:	4721                	li	a4,8
    8000629c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000629e:	4098                	lw	a4,0(s1)
    800062a0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062a4:	40d8                	lw	a4,4(s1)
    800062a6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062aa:	6498                	ld	a4,8(s1)
    800062ac:	0007069b          	sext.w	a3,a4
    800062b0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062b4:	9701                	srai	a4,a4,0x20
    800062b6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062ba:	6898                	ld	a4,16(s1)
    800062bc:	0007069b          	sext.w	a3,a4
    800062c0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800062c4:	9701                	srai	a4,a4,0x20
    800062c6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800062ca:	4705                	li	a4,1
    800062cc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800062ce:	00e48c23          	sb	a4,24(s1)
    800062d2:	00e48ca3          	sb	a4,25(s1)
    800062d6:	00e48d23          	sb	a4,26(s1)
    800062da:	00e48da3          	sb	a4,27(s1)
    800062de:	00e48e23          	sb	a4,28(s1)
    800062e2:	00e48ea3          	sb	a4,29(s1)
    800062e6:	00e48f23          	sb	a4,30(s1)
    800062ea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800062ee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f2:	0727a823          	sw	s2,112(a5)
}
    800062f6:	60e2                	ld	ra,24(sp)
    800062f8:	6442                	ld	s0,16(sp)
    800062fa:	64a2                	ld	s1,8(sp)
    800062fc:	6902                	ld	s2,0(sp)
    800062fe:	6105                	addi	sp,sp,32
    80006300:	8082                	ret
    panic("could not find virtio disk");
    80006302:	00002517          	auipc	a0,0x2
    80006306:	4ee50513          	addi	a0,a0,1262 # 800087f0 <syscalls+0x340>
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	236080e7          	jalr	566(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006312:	00002517          	auipc	a0,0x2
    80006316:	4fe50513          	addi	a0,a0,1278 # 80008810 <syscalls+0x360>
    8000631a:	ffffa097          	auipc	ra,0xffffa
    8000631e:	226080e7          	jalr	550(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	50e50513          	addi	a0,a0,1294 # 80008830 <syscalls+0x380>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	216080e7          	jalr	534(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	51e50513          	addi	a0,a0,1310 # 80008850 <syscalls+0x3a0>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	206080e7          	jalr	518(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	52e50513          	addi	a0,a0,1326 # 80008870 <syscalls+0x3c0>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	53e50513          	addi	a0,a0,1342 # 80008890 <syscalls+0x3e0>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>

0000000080006362 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006362:	7119                	addi	sp,sp,-128
    80006364:	fc86                	sd	ra,120(sp)
    80006366:	f8a2                	sd	s0,112(sp)
    80006368:	f4a6                	sd	s1,104(sp)
    8000636a:	f0ca                	sd	s2,96(sp)
    8000636c:	ecce                	sd	s3,88(sp)
    8000636e:	e8d2                	sd	s4,80(sp)
    80006370:	e4d6                	sd	s5,72(sp)
    80006372:	e0da                	sd	s6,64(sp)
    80006374:	fc5e                	sd	s7,56(sp)
    80006376:	f862                	sd	s8,48(sp)
    80006378:	f466                	sd	s9,40(sp)
    8000637a:	f06a                	sd	s10,32(sp)
    8000637c:	ec6e                	sd	s11,24(sp)
    8000637e:	0100                	addi	s0,sp,128
    80006380:	8aaa                	mv	s5,a0
    80006382:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006384:	00c52d03          	lw	s10,12(a0)
    80006388:	001d1d1b          	slliw	s10,s10,0x1
    8000638c:	1d02                	slli	s10,s10,0x20
    8000638e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006392:	0001c517          	auipc	a0,0x1c
    80006396:	a3650513          	addi	a0,a0,-1482 # 80021dc8 <disk+0x128>
    8000639a:	ffffb097          	auipc	ra,0xffffb
    8000639e:	83c080e7          	jalr	-1988(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800063a2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063a6:	0001cb97          	auipc	s7,0x1c
    800063aa:	8fab8b93          	addi	s7,s7,-1798 # 80021ca0 <disk>
  for(int i = 0; i < 3; i++){
    800063ae:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063b0:	0001cc97          	auipc	s9,0x1c
    800063b4:	a18c8c93          	addi	s9,s9,-1512 # 80021dc8 <disk+0x128>
    800063b8:	a08d                	j	8000641a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063ba:	00fb8733          	add	a4,s7,a5
    800063be:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063c2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063c4:	0207c563          	bltz	a5,800063ee <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800063c8:	2905                	addiw	s2,s2,1
    800063ca:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800063cc:	05690c63          	beq	s2,s6,80006424 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800063d0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063d2:	0001c717          	auipc	a4,0x1c
    800063d6:	8ce70713          	addi	a4,a4,-1842 # 80021ca0 <disk>
    800063da:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063dc:	01874683          	lbu	a3,24(a4)
    800063e0:	fee9                	bnez	a3,800063ba <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800063e2:	2785                	addiw	a5,a5,1
    800063e4:	0705                	addi	a4,a4,1
    800063e6:	fe979be3          	bne	a5,s1,800063dc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800063ea:	57fd                	li	a5,-1
    800063ec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063ee:	01205d63          	blez	s2,80006408 <virtio_disk_rw+0xa6>
    800063f2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063f4:	000a2503          	lw	a0,0(s4)
    800063f8:	00000097          	auipc	ra,0x0
    800063fc:	cfe080e7          	jalr	-770(ra) # 800060f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006400:	2d85                	addiw	s11,s11,1
    80006402:	0a11                	addi	s4,s4,4
    80006404:	ff2d98e3          	bne	s11,s2,800063f4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006408:	85e6                	mv	a1,s9
    8000640a:	0001c517          	auipc	a0,0x1c
    8000640e:	8ae50513          	addi	a0,a0,-1874 # 80021cb8 <disk+0x18>
    80006412:	ffffc097          	auipc	ra,0xffffc
    80006416:	c42080e7          	jalr	-958(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000641a:	f8040a13          	addi	s4,s0,-128
{
    8000641e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006420:	894e                	mv	s2,s3
    80006422:	b77d                	j	800063d0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006424:	f8042503          	lw	a0,-128(s0)
    80006428:	00a50713          	addi	a4,a0,10
    8000642c:	0712                	slli	a4,a4,0x4

  if(write)
    8000642e:	0001c797          	auipc	a5,0x1c
    80006432:	87278793          	addi	a5,a5,-1934 # 80021ca0 <disk>
    80006436:	00e786b3          	add	a3,a5,a4
    8000643a:	01803633          	snez	a2,s8
    8000643e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006440:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006444:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006448:	f6070613          	addi	a2,a4,-160
    8000644c:	6394                	ld	a3,0(a5)
    8000644e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006450:	00870593          	addi	a1,a4,8
    80006454:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006456:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006458:	0007b803          	ld	a6,0(a5)
    8000645c:	9642                	add	a2,a2,a6
    8000645e:	46c1                	li	a3,16
    80006460:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006462:	4585                	li	a1,1
    80006464:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006468:	f8442683          	lw	a3,-124(s0)
    8000646c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006470:	0692                	slli	a3,a3,0x4
    80006472:	9836                	add	a6,a6,a3
    80006474:	058a8613          	addi	a2,s5,88
    80006478:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000647c:	0007b803          	ld	a6,0(a5)
    80006480:	96c2                	add	a3,a3,a6
    80006482:	40000613          	li	a2,1024
    80006486:	c690                	sw	a2,8(a3)
  if(write)
    80006488:	001c3613          	seqz	a2,s8
    8000648c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006490:	00166613          	ori	a2,a2,1
    80006494:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006498:	f8842603          	lw	a2,-120(s0)
    8000649c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064a0:	00250693          	addi	a3,a0,2
    800064a4:	0692                	slli	a3,a3,0x4
    800064a6:	96be                	add	a3,a3,a5
    800064a8:	58fd                	li	a7,-1
    800064aa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064ae:	0612                	slli	a2,a2,0x4
    800064b0:	9832                	add	a6,a6,a2
    800064b2:	f9070713          	addi	a4,a4,-112
    800064b6:	973e                	add	a4,a4,a5
    800064b8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800064bc:	6398                	ld	a4,0(a5)
    800064be:	9732                	add	a4,a4,a2
    800064c0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064c2:	4609                	li	a2,2
    800064c4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800064c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064cc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800064d0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d4:	6794                	ld	a3,8(a5)
    800064d6:	0026d703          	lhu	a4,2(a3)
    800064da:	8b1d                	andi	a4,a4,7
    800064dc:	0706                	slli	a4,a4,0x1
    800064de:	96ba                	add	a3,a3,a4
    800064e0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800064e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064e8:	6798                	ld	a4,8(a5)
    800064ea:	00275783          	lhu	a5,2(a4)
    800064ee:	2785                	addiw	a5,a5,1
    800064f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064f8:	100017b7          	lui	a5,0x10001
    800064fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006500:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006504:	0001c917          	auipc	s2,0x1c
    80006508:	8c490913          	addi	s2,s2,-1852 # 80021dc8 <disk+0x128>
  while(b->disk == 1) {
    8000650c:	4485                	li	s1,1
    8000650e:	00b79c63          	bne	a5,a1,80006526 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006512:	85ca                	mv	a1,s2
    80006514:	8556                	mv	a0,s5
    80006516:	ffffc097          	auipc	ra,0xffffc
    8000651a:	b3e080e7          	jalr	-1218(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000651e:	004aa783          	lw	a5,4(s5)
    80006522:	fe9788e3          	beq	a5,s1,80006512 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006526:	f8042903          	lw	s2,-128(s0)
    8000652a:	00290713          	addi	a4,s2,2
    8000652e:	0712                	slli	a4,a4,0x4
    80006530:	0001b797          	auipc	a5,0x1b
    80006534:	77078793          	addi	a5,a5,1904 # 80021ca0 <disk>
    80006538:	97ba                	add	a5,a5,a4
    8000653a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000653e:	0001b997          	auipc	s3,0x1b
    80006542:	76298993          	addi	s3,s3,1890 # 80021ca0 <disk>
    80006546:	00491713          	slli	a4,s2,0x4
    8000654a:	0009b783          	ld	a5,0(s3)
    8000654e:	97ba                	add	a5,a5,a4
    80006550:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006554:	854a                	mv	a0,s2
    80006556:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000655a:	00000097          	auipc	ra,0x0
    8000655e:	b9c080e7          	jalr	-1124(ra) # 800060f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006562:	8885                	andi	s1,s1,1
    80006564:	f0ed                	bnez	s1,80006546 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006566:	0001c517          	auipc	a0,0x1c
    8000656a:	86250513          	addi	a0,a0,-1950 # 80021dc8 <disk+0x128>
    8000656e:	ffffa097          	auipc	ra,0xffffa
    80006572:	71c080e7          	jalr	1820(ra) # 80000c8a <release>
}
    80006576:	70e6                	ld	ra,120(sp)
    80006578:	7446                	ld	s0,112(sp)
    8000657a:	74a6                	ld	s1,104(sp)
    8000657c:	7906                	ld	s2,96(sp)
    8000657e:	69e6                	ld	s3,88(sp)
    80006580:	6a46                	ld	s4,80(sp)
    80006582:	6aa6                	ld	s5,72(sp)
    80006584:	6b06                	ld	s6,64(sp)
    80006586:	7be2                	ld	s7,56(sp)
    80006588:	7c42                	ld	s8,48(sp)
    8000658a:	7ca2                	ld	s9,40(sp)
    8000658c:	7d02                	ld	s10,32(sp)
    8000658e:	6de2                	ld	s11,24(sp)
    80006590:	6109                	addi	sp,sp,128
    80006592:	8082                	ret

0000000080006594 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006594:	1101                	addi	sp,sp,-32
    80006596:	ec06                	sd	ra,24(sp)
    80006598:	e822                	sd	s0,16(sp)
    8000659a:	e426                	sd	s1,8(sp)
    8000659c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000659e:	0001b497          	auipc	s1,0x1b
    800065a2:	70248493          	addi	s1,s1,1794 # 80021ca0 <disk>
    800065a6:	0001c517          	auipc	a0,0x1c
    800065aa:	82250513          	addi	a0,a0,-2014 # 80021dc8 <disk+0x128>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	628080e7          	jalr	1576(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065b6:	10001737          	lui	a4,0x10001
    800065ba:	533c                	lw	a5,96(a4)
    800065bc:	8b8d                	andi	a5,a5,3
    800065be:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065c0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065c4:	689c                	ld	a5,16(s1)
    800065c6:	0204d703          	lhu	a4,32(s1)
    800065ca:	0027d783          	lhu	a5,2(a5)
    800065ce:	04f70863          	beq	a4,a5,8000661e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800065d2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065d6:	6898                	ld	a4,16(s1)
    800065d8:	0204d783          	lhu	a5,32(s1)
    800065dc:	8b9d                	andi	a5,a5,7
    800065de:	078e                	slli	a5,a5,0x3
    800065e0:	97ba                	add	a5,a5,a4
    800065e2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065e4:	00278713          	addi	a4,a5,2
    800065e8:	0712                	slli	a4,a4,0x4
    800065ea:	9726                	add	a4,a4,s1
    800065ec:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800065f0:	e721                	bnez	a4,80006638 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065f2:	0789                	addi	a5,a5,2
    800065f4:	0792                	slli	a5,a5,0x4
    800065f6:	97a6                	add	a5,a5,s1
    800065f8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800065fa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065fe:	ffffc097          	auipc	ra,0xffffc
    80006602:	aba080e7          	jalr	-1350(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006606:	0204d783          	lhu	a5,32(s1)
    8000660a:	2785                	addiw	a5,a5,1
    8000660c:	17c2                	slli	a5,a5,0x30
    8000660e:	93c1                	srli	a5,a5,0x30
    80006610:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006614:	6898                	ld	a4,16(s1)
    80006616:	00275703          	lhu	a4,2(a4)
    8000661a:	faf71ce3          	bne	a4,a5,800065d2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000661e:	0001b517          	auipc	a0,0x1b
    80006622:	7aa50513          	addi	a0,a0,1962 # 80021dc8 <disk+0x128>
    80006626:	ffffa097          	auipc	ra,0xffffa
    8000662a:	664080e7          	jalr	1636(ra) # 80000c8a <release>
}
    8000662e:	60e2                	ld	ra,24(sp)
    80006630:	6442                	ld	s0,16(sp)
    80006632:	64a2                	ld	s1,8(sp)
    80006634:	6105                	addi	sp,sp,32
    80006636:	8082                	ret
      panic("virtio_disk_intr status");
    80006638:	00002517          	auipc	a0,0x2
    8000663c:	27050513          	addi	a0,a0,624 # 800088a8 <syscalls+0x3f8>
    80006640:	ffffa097          	auipc	ra,0xffffa
    80006644:	f00080e7          	jalr	-256(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
