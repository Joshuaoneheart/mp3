
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0ec78793          	addi	a5,a5,236 # 80006150 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff977ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e0278793          	addi	a5,a5,-510 # 80000eb0 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	af2080e7          	jalr	-1294(ra) # 80000c06 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	44a080e7          	jalr	1098(ra) # 80002578 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	796080e7          	jalr	1942(ra) # 800008d4 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	b64080e7          	jalr	-1180(ra) # 80000cba <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7159                	addi	sp,sp,-112
    80000178:	f486                	sd	ra,104(sp)
    8000017a:	f0a2                	sd	s0,96(sp)
    8000017c:	eca6                	sd	s1,88(sp)
    8000017e:	e8ca                	sd	s2,80(sp)
    80000180:	e4ce                	sd	s3,72(sp)
    80000182:	e0d2                	sd	s4,64(sp)
    80000184:	fc56                	sd	s5,56(sp)
    80000186:	f85a                	sd	s6,48(sp)
    80000188:	f45e                	sd	s7,40(sp)
    8000018a:	f062                	sd	s8,32(sp)
    8000018c:	ec66                	sd	s9,24(sp)
    8000018e:	e86a                	sd	s10,16(sp)
    80000190:	1880                	addi	s0,sp,112
    80000192:	8aaa                	mv	s5,a0
    80000194:	8a2e                	mv	s4,a1
    80000196:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000198:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	fd450513          	addi	a0,a0,-44 # 80011170 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	a62080e7          	jalr	-1438(ra) # 80000c06 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ac:	00011497          	auipc	s1,0x11
    800001b0:	fc448493          	addi	s1,s1,-60 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	00011917          	auipc	s2,0x11
    800001b8:	05490913          	addi	s2,s2,84 # 80011208 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001bc:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001be:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c0:	4ca9                	li	s9,10
  while(n > 0){
    800001c2:	07305863          	blez	s3,80000232 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001c6:	0984a783          	lw	a5,152(s1)
    800001ca:	09c4a703          	lw	a4,156(s1)
    800001ce:	02f71463          	bne	a4,a5,800001f6 <consoleread+0x80>
      if(myproc()->killed){
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	83c080e7          	jalr	-1988(ra) # 80001a0e <myproc>
    800001da:	591c                	lw	a5,48(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	0ce080e7          	jalr	206(ra) # 800022b0 <sleep>
    while(cons.r == cons.w){
    800001ea:	0984a783          	lw	a5,152(s1)
    800001ee:	09c4a703          	lw	a4,156(s1)
    800001f2:	fef700e3          	beq	a4,a5,800001d2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f6:	0017871b          	addiw	a4,a5,1
    800001fa:	08e4ac23          	sw	a4,152(s1)
    800001fe:	07f7f713          	andi	a4,a5,127
    80000202:	9726                	add	a4,a4,s1
    80000204:	01874703          	lbu	a4,24(a4)
    80000208:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    8000020c:	077d0563          	beq	s10,s7,80000276 <consoleread+0x100>
    cbuf = c;
    80000210:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000214:	4685                	li	a3,1
    80000216:	f9f40613          	addi	a2,s0,-97
    8000021a:	85d2                	mv	a1,s4
    8000021c:	8556                	mv	a0,s5
    8000021e:	00002097          	auipc	ra,0x2
    80000222:	300080e7          	jalr	768(ra) # 8000251e <either_copyout>
    80000226:	01850663          	beq	a0,s8,80000232 <consoleread+0xbc>
    dst++;
    8000022a:	0a05                	addi	s4,s4,1
    --n;
    8000022c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000022e:	f99d1ae3          	bne	s10,s9,800001c2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000232:	00011517          	auipc	a0,0x11
    80000236:	f3e50513          	addi	a0,a0,-194 # 80011170 <cons>
    8000023a:	00001097          	auipc	ra,0x1
    8000023e:	a80080e7          	jalr	-1408(ra) # 80000cba <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	a6a080e7          	jalr	-1430(ra) # 80000cba <release>
        return -1;
    80000258:	557d                	li	a0,-1
}
    8000025a:	70a6                	ld	ra,104(sp)
    8000025c:	7406                	ld	s0,96(sp)
    8000025e:	64e6                	ld	s1,88(sp)
    80000260:	6946                	ld	s2,80(sp)
    80000262:	69a6                	ld	s3,72(sp)
    80000264:	6a06                	ld	s4,64(sp)
    80000266:	7ae2                	ld	s5,56(sp)
    80000268:	7b42                	ld	s6,48(sp)
    8000026a:	7ba2                	ld	s7,40(sp)
    8000026c:	7c02                	ld	s8,32(sp)
    8000026e:	6ce2                	ld	s9,24(sp)
    80000270:	6d42                	ld	s10,16(sp)
    80000272:	6165                	addi	sp,sp,112
    80000274:	8082                	ret
      if(n < target){
    80000276:	0009871b          	sext.w	a4,s3
    8000027a:	fb677ce3          	bgeu	a4,s6,80000232 <consoleread+0xbc>
        cons.r--;
    8000027e:	00011717          	auipc	a4,0x11
    80000282:	f8f72523          	sw	a5,-118(a4) # 80011208 <cons+0x98>
    80000286:	b775                	j	80000232 <consoleread+0xbc>

0000000080000288 <consputc>:
{
    80000288:	1141                	addi	sp,sp,-16
    8000028a:	e406                	sd	ra,8(sp)
    8000028c:	e022                	sd	s0,0(sp)
    8000028e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000290:	10000793          	li	a5,256
    80000294:	00f50a63          	beq	a0,a5,800002a8 <consputc+0x20>
    uartputc_sync(c);
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	55e080e7          	jalr	1374(ra) # 800007f6 <uartputc_sync>
}
    800002a0:	60a2                	ld	ra,8(sp)
    800002a2:	6402                	ld	s0,0(sp)
    800002a4:	0141                	addi	sp,sp,16
    800002a6:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a8:	4521                	li	a0,8
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	54c080e7          	jalr	1356(ra) # 800007f6 <uartputc_sync>
    800002b2:	02000513          	li	a0,32
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	540080e7          	jalr	1344(ra) # 800007f6 <uartputc_sync>
    800002be:	4521                	li	a0,8
    800002c0:	00000097          	auipc	ra,0x0
    800002c4:	536080e7          	jalr	1334(ra) # 800007f6 <uartputc_sync>
    800002c8:	bfe1                	j	800002a0 <consputc+0x18>

00000000800002ca <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ca:	1101                	addi	sp,sp,-32
    800002cc:	ec06                	sd	ra,24(sp)
    800002ce:	e822                	sd	s0,16(sp)
    800002d0:	e426                	sd	s1,8(sp)
    800002d2:	e04a                	sd	s2,0(sp)
    800002d4:	1000                	addi	s0,sp,32
    800002d6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d8:	00011517          	auipc	a0,0x11
    800002dc:	e9850513          	addi	a0,a0,-360 # 80011170 <cons>
    800002e0:	00001097          	auipc	ra,0x1
    800002e4:	926080e7          	jalr	-1754(ra) # 80000c06 <acquire>

  switch(c){
    800002e8:	47d5                	li	a5,21
    800002ea:	0af48663          	beq	s1,a5,80000396 <consoleintr+0xcc>
    800002ee:	0297ca63          	blt	a5,s1,80000322 <consoleintr+0x58>
    800002f2:	47a1                	li	a5,8
    800002f4:	0ef48763          	beq	s1,a5,800003e2 <consoleintr+0x118>
    800002f8:	47c1                	li	a5,16
    800002fa:	10f49a63          	bne	s1,a5,8000040e <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fe:	00002097          	auipc	ra,0x2
    80000302:	2d4080e7          	jalr	724(ra) # 800025d2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	9ac080e7          	jalr	-1620(ra) # 80000cba <release>
}
    80000316:	60e2                	ld	ra,24(sp)
    80000318:	6442                	ld	s0,16(sp)
    8000031a:	64a2                	ld	s1,8(sp)
    8000031c:	6902                	ld	s2,0(sp)
    8000031e:	6105                	addi	sp,sp,32
    80000320:	8082                	ret
  switch(c){
    80000322:	07f00793          	li	a5,127
    80000326:	0af48e63          	beq	s1,a5,800003e2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000032a:	00011717          	auipc	a4,0x11
    8000032e:	e4670713          	addi	a4,a4,-442 # 80011170 <cons>
    80000332:	0a072783          	lw	a5,160(a4)
    80000336:	09872703          	lw	a4,152(a4)
    8000033a:	9f99                	subw	a5,a5,a4
    8000033c:	07f00713          	li	a4,127
    80000340:	fcf763e3          	bltu	a4,a5,80000306 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000344:	47b5                	li	a5,13
    80000346:	0cf48763          	beq	s1,a5,80000414 <consoleintr+0x14a>
      consputc(c);
    8000034a:	8526                	mv	a0,s1
    8000034c:	00000097          	auipc	ra,0x0
    80000350:	f3c080e7          	jalr	-196(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000354:	00011797          	auipc	a5,0x11
    80000358:	e1c78793          	addi	a5,a5,-484 # 80011170 <cons>
    8000035c:	0a07a703          	lw	a4,160(a5)
    80000360:	0017069b          	addiw	a3,a4,1
    80000364:	0006861b          	sext.w	a2,a3
    80000368:	0ad7a023          	sw	a3,160(a5)
    8000036c:	07f77713          	andi	a4,a4,127
    80000370:	97ba                	add	a5,a5,a4
    80000372:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000376:	47a9                	li	a5,10
    80000378:	0cf48563          	beq	s1,a5,80000442 <consoleintr+0x178>
    8000037c:	4791                	li	a5,4
    8000037e:	0cf48263          	beq	s1,a5,80000442 <consoleintr+0x178>
    80000382:	00011797          	auipc	a5,0x11
    80000386:	e867a783          	lw	a5,-378(a5) # 80011208 <cons+0x98>
    8000038a:	0807879b          	addiw	a5,a5,128
    8000038e:	f6f61ce3          	bne	a2,a5,80000306 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000392:	863e                	mv	a2,a5
    80000394:	a07d                	j	80000442 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000396:	00011717          	auipc	a4,0x11
    8000039a:	dda70713          	addi	a4,a4,-550 # 80011170 <cons>
    8000039e:	0a072783          	lw	a5,160(a4)
    800003a2:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a6:	00011497          	auipc	s1,0x11
    800003aa:	dca48493          	addi	s1,s1,-566 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003ae:	4929                	li	s2,10
    800003b0:	f4f70be3          	beq	a4,a5,80000306 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b4:	37fd                	addiw	a5,a5,-1
    800003b6:	07f7f713          	andi	a4,a5,127
    800003ba:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003bc:	01874703          	lbu	a4,24(a4)
    800003c0:	f52703e3          	beq	a4,s2,80000306 <consoleintr+0x3c>
      cons.e--;
    800003c4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c8:	10000513          	li	a0,256
    800003cc:	00000097          	auipc	ra,0x0
    800003d0:	ebc080e7          	jalr	-324(ra) # 80000288 <consputc>
    while(cons.e != cons.w &&
    800003d4:	0a04a783          	lw	a5,160(s1)
    800003d8:	09c4a703          	lw	a4,156(s1)
    800003dc:	fcf71ce3          	bne	a4,a5,800003b4 <consoleintr+0xea>
    800003e0:	b71d                	j	80000306 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e2:	00011717          	auipc	a4,0x11
    800003e6:	d8e70713          	addi	a4,a4,-626 # 80011170 <cons>
    800003ea:	0a072783          	lw	a5,160(a4)
    800003ee:	09c72703          	lw	a4,156(a4)
    800003f2:	f0f70ae3          	beq	a4,a5,80000306 <consoleintr+0x3c>
      cons.e--;
    800003f6:	37fd                	addiw	a5,a5,-1
    800003f8:	00011717          	auipc	a4,0x11
    800003fc:	e0f72c23          	sw	a5,-488(a4) # 80011210 <cons+0xa0>
      consputc(BACKSPACE);
    80000400:	10000513          	li	a0,256
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e84080e7          	jalr	-380(ra) # 80000288 <consputc>
    8000040c:	bded                	j	80000306 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040e:	ee048ce3          	beqz	s1,80000306 <consoleintr+0x3c>
    80000412:	bf21                	j	8000032a <consoleintr+0x60>
      consputc(c);
    80000414:	4529                	li	a0,10
    80000416:	00000097          	auipc	ra,0x0
    8000041a:	e72080e7          	jalr	-398(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041e:	00011797          	auipc	a5,0x11
    80000422:	d5278793          	addi	a5,a5,-686 # 80011170 <cons>
    80000426:	0a07a703          	lw	a4,160(a5)
    8000042a:	0017069b          	addiw	a3,a4,1
    8000042e:	0006861b          	sext.w	a2,a3
    80000432:	0ad7a023          	sw	a3,160(a5)
    80000436:	07f77713          	andi	a4,a4,127
    8000043a:	97ba                	add	a5,a5,a4
    8000043c:	4729                	li	a4,10
    8000043e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000442:	00011797          	auipc	a5,0x11
    80000446:	dcc7a523          	sw	a2,-566(a5) # 8001120c <cons+0x9c>
        wakeup(&cons.r);
    8000044a:	00011517          	auipc	a0,0x11
    8000044e:	dbe50513          	addi	a0,a0,-578 # 80011208 <cons+0x98>
    80000452:	00002097          	auipc	ra,0x2
    80000456:	fe2080e7          	jalr	-30(ra) # 80002434 <wakeup>
    8000045a:	b575                	j	80000306 <consoleintr+0x3c>

000000008000045c <consoleinit>:

void
consoleinit(void)
{
    8000045c:	1141                	addi	sp,sp,-16
    8000045e:	e406                	sd	ra,8(sp)
    80000460:	e022                	sd	s0,0(sp)
    80000462:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000464:	00008597          	auipc	a1,0x8
    80000468:	bac58593          	addi	a1,a1,-1108 # 80008010 <etext+0x10>
    8000046c:	00011517          	auipc	a0,0x11
    80000470:	d0450513          	addi	a0,a0,-764 # 80011170 <cons>
    80000474:	00000097          	auipc	ra,0x0
    80000478:	702080e7          	jalr	1794(ra) # 80000b76 <initlock>

  uartinit();
    8000047c:	00000097          	auipc	ra,0x0
    80000480:	32a080e7          	jalr	810(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000484:	00062797          	auipc	a5,0x62
    80000488:	26c78793          	addi	a5,a5,620 # 800626f0 <devsw>
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	cea70713          	addi	a4,a4,-790 # 80000176 <consoleread>
    80000494:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000496:	00000717          	auipc	a4,0x0
    8000049a:	c5e70713          	addi	a4,a4,-930 # 800000f4 <consolewrite>
    8000049e:	ef98                	sd	a4,24(a5)
}
    800004a0:	60a2                	ld	ra,8(sp)
    800004a2:	6402                	ld	s0,0(sp)
    800004a4:	0141                	addi	sp,sp,16
    800004a6:	8082                	ret

00000000800004a8 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a8:	7179                	addi	sp,sp,-48
    800004aa:	f406                	sd	ra,40(sp)
    800004ac:	f022                	sd	s0,32(sp)
    800004ae:	ec26                	sd	s1,24(sp)
    800004b0:	e84a                	sd	s2,16(sp)
    800004b2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b4:	c219                	beqz	a2,800004ba <printint+0x12>
    800004b6:	08054663          	bltz	a0,80000542 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ba:	2501                	sext.w	a0,a0
    800004bc:	4881                	li	a7,0
    800004be:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c4:	2581                	sext.w	a1,a1
    800004c6:	00008617          	auipc	a2,0x8
    800004ca:	b7a60613          	addi	a2,a2,-1158 # 80008040 <digits>
    800004ce:	883a                	mv	a6,a4
    800004d0:	2705                	addiw	a4,a4,1
    800004d2:	02b577bb          	remuw	a5,a0,a1
    800004d6:	1782                	slli	a5,a5,0x20
    800004d8:	9381                	srli	a5,a5,0x20
    800004da:	97b2                	add	a5,a5,a2
    800004dc:	0007c783          	lbu	a5,0(a5)
    800004e0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e4:	0005079b          	sext.w	a5,a0
    800004e8:	02b5553b          	divuw	a0,a0,a1
    800004ec:	0685                	addi	a3,a3,1
    800004ee:	feb7f0e3          	bgeu	a5,a1,800004ce <printint+0x26>

  if(sign)
    800004f2:	00088b63          	beqz	a7,80000508 <printint+0x60>
    buf[i++] = '-';
    800004f6:	fe040793          	addi	a5,s0,-32
    800004fa:	973e                	add	a4,a4,a5
    800004fc:	02d00793          	li	a5,45
    80000500:	fef70823          	sb	a5,-16(a4)
    80000504:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000508:	02e05763          	blez	a4,80000536 <printint+0x8e>
    8000050c:	fd040793          	addi	a5,s0,-48
    80000510:	00e784b3          	add	s1,a5,a4
    80000514:	fff78913          	addi	s2,a5,-1
    80000518:	993a                	add	s2,s2,a4
    8000051a:	377d                	addiw	a4,a4,-1
    8000051c:	1702                	slli	a4,a4,0x20
    8000051e:	9301                	srli	a4,a4,0x20
    80000520:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000524:	fff4c503          	lbu	a0,-1(s1)
    80000528:	00000097          	auipc	ra,0x0
    8000052c:	d60080e7          	jalr	-672(ra) # 80000288 <consputc>
  while(--i >= 0)
    80000530:	14fd                	addi	s1,s1,-1
    80000532:	ff2499e3          	bne	s1,s2,80000524 <printint+0x7c>
}
    80000536:	70a2                	ld	ra,40(sp)
    80000538:	7402                	ld	s0,32(sp)
    8000053a:	64e2                	ld	s1,24(sp)
    8000053c:	6942                	ld	s2,16(sp)
    8000053e:	6145                	addi	sp,sp,48
    80000540:	8082                	ret
    x = -xx;
    80000542:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000546:	4885                	li	a7,1
    x = -xx;
    80000548:	bf9d                	j	800004be <printint+0x16>

000000008000054a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000054a:	1101                	addi	sp,sp,-32
    8000054c:	ec06                	sd	ra,24(sp)
    8000054e:	e822                	sd	s0,16(sp)
    80000550:	e426                	sd	s1,8(sp)
    80000552:	1000                	addi	s0,sp,32
    80000554:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000556:	00011797          	auipc	a5,0x11
    8000055a:	cc07ad23          	sw	zero,-806(a5) # 80011230 <pr+0x18>
  printf("panic: ");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	aba50513          	addi	a0,a0,-1350 # 80008018 <etext+0x18>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	02e080e7          	jalr	46(ra) # 80000594 <printf>
  printf(s);
    8000056e:	8526                	mv	a0,s1
    80000570:	00000097          	auipc	ra,0x0
    80000574:	024080e7          	jalr	36(ra) # 80000594 <printf>
  printf("\n");
    80000578:	00008517          	auipc	a0,0x8
    8000057c:	b5050513          	addi	a0,a0,-1200 # 800080c8 <digits+0x88>
    80000580:	00000097          	auipc	ra,0x0
    80000584:	014080e7          	jalr	20(ra) # 80000594 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000588:	4785                	li	a5,1
    8000058a:	00009717          	auipc	a4,0x9
    8000058e:	a6f72b23          	sw	a5,-1418(a4) # 80009000 <panicked>
  for(;;)
    80000592:	a001                	j	80000592 <panic+0x48>

0000000080000594 <printf>:
{
    80000594:	7131                	addi	sp,sp,-192
    80000596:	fc86                	sd	ra,120(sp)
    80000598:	f8a2                	sd	s0,112(sp)
    8000059a:	f4a6                	sd	s1,104(sp)
    8000059c:	f0ca                	sd	s2,96(sp)
    8000059e:	ecce                	sd	s3,88(sp)
    800005a0:	e8d2                	sd	s4,80(sp)
    800005a2:	e4d6                	sd	s5,72(sp)
    800005a4:	e0da                	sd	s6,64(sp)
    800005a6:	fc5e                	sd	s7,56(sp)
    800005a8:	f862                	sd	s8,48(sp)
    800005aa:	f466                	sd	s9,40(sp)
    800005ac:	f06a                	sd	s10,32(sp)
    800005ae:	ec6e                	sd	s11,24(sp)
    800005b0:	0100                	addi	s0,sp,128
    800005b2:	8a2a                	mv	s4,a0
    800005b4:	e40c                	sd	a1,8(s0)
    800005b6:	e810                	sd	a2,16(s0)
    800005b8:	ec14                	sd	a3,24(s0)
    800005ba:	f018                	sd	a4,32(s0)
    800005bc:	f41c                	sd	a5,40(s0)
    800005be:	03043823          	sd	a6,48(s0)
    800005c2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c6:	00011d97          	auipc	s11,0x11
    800005ca:	c6adad83          	lw	s11,-918(s11) # 80011230 <pr+0x18>
  if(locking)
    800005ce:	020d9b63          	bnez	s11,80000604 <printf+0x70>
  if (fmt == 0)
    800005d2:	040a0263          	beqz	s4,80000616 <printf+0x82>
  va_start(ap, fmt);
    800005d6:	00840793          	addi	a5,s0,8
    800005da:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005de:	000a4503          	lbu	a0,0(s4)
    800005e2:	14050f63          	beqz	a0,80000740 <printf+0x1ac>
    800005e6:	4981                	li	s3,0
    if(c != '%'){
    800005e8:	02500a93          	li	s5,37
    switch(c){
    800005ec:	07000b93          	li	s7,112
  consputc('x');
    800005f0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f2:	00008b17          	auipc	s6,0x8
    800005f6:	a4eb0b13          	addi	s6,s6,-1458 # 80008040 <digits>
    switch(c){
    800005fa:	07300c93          	li	s9,115
    800005fe:	06400c13          	li	s8,100
    80000602:	a82d                	j	8000063c <printf+0xa8>
    acquire(&pr.lock);
    80000604:	00011517          	auipc	a0,0x11
    80000608:	c1450513          	addi	a0,a0,-1004 # 80011218 <pr>
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	5fa080e7          	jalr	1530(ra) # 80000c06 <acquire>
    80000614:	bf7d                	j	800005d2 <printf+0x3e>
    panic("null fmt");
    80000616:	00008517          	auipc	a0,0x8
    8000061a:	a1250513          	addi	a0,a0,-1518 # 80008028 <etext+0x28>
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	f2c080e7          	jalr	-212(ra) # 8000054a <panic>
      consputc(c);
    80000626:	00000097          	auipc	ra,0x0
    8000062a:	c62080e7          	jalr	-926(ra) # 80000288 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062e:	2985                	addiw	s3,s3,1
    80000630:	013a07b3          	add	a5,s4,s3
    80000634:	0007c503          	lbu	a0,0(a5)
    80000638:	10050463          	beqz	a0,80000740 <printf+0x1ac>
    if(c != '%'){
    8000063c:	ff5515e3          	bne	a0,s5,80000626 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000640:	2985                	addiw	s3,s3,1
    80000642:	013a07b3          	add	a5,s4,s3
    80000646:	0007c783          	lbu	a5,0(a5)
    8000064a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064e:	cbed                	beqz	a5,80000740 <printf+0x1ac>
    switch(c){
    80000650:	05778a63          	beq	a5,s7,800006a4 <printf+0x110>
    80000654:	02fbf663          	bgeu	s7,a5,80000680 <printf+0xec>
    80000658:	09978863          	beq	a5,s9,800006e8 <printf+0x154>
    8000065c:	07800713          	li	a4,120
    80000660:	0ce79563          	bne	a5,a4,8000072a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000664:	f8843783          	ld	a5,-120(s0)
    80000668:	00878713          	addi	a4,a5,8
    8000066c:	f8e43423          	sd	a4,-120(s0)
    80000670:	4605                	li	a2,1
    80000672:	85ea                	mv	a1,s10
    80000674:	4388                	lw	a0,0(a5)
    80000676:	00000097          	auipc	ra,0x0
    8000067a:	e32080e7          	jalr	-462(ra) # 800004a8 <printint>
      break;
    8000067e:	bf45                	j	8000062e <printf+0x9a>
    switch(c){
    80000680:	09578f63          	beq	a5,s5,8000071e <printf+0x18a>
    80000684:	0b879363          	bne	a5,s8,8000072a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000688:	f8843783          	ld	a5,-120(s0)
    8000068c:	00878713          	addi	a4,a5,8
    80000690:	f8e43423          	sd	a4,-120(s0)
    80000694:	4605                	li	a2,1
    80000696:	45a9                	li	a1,10
    80000698:	4388                	lw	a0,0(a5)
    8000069a:	00000097          	auipc	ra,0x0
    8000069e:	e0e080e7          	jalr	-498(ra) # 800004a8 <printint>
      break;
    800006a2:	b771                	j	8000062e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a4:	f8843783          	ld	a5,-120(s0)
    800006a8:	00878713          	addi	a4,a5,8
    800006ac:	f8e43423          	sd	a4,-120(s0)
    800006b0:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b4:	03000513          	li	a0,48
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bd0080e7          	jalr	-1072(ra) # 80000288 <consputc>
  consputc('x');
    800006c0:	07800513          	li	a0,120
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bc4080e7          	jalr	-1084(ra) # 80000288 <consputc>
    800006cc:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ce:	03c95793          	srli	a5,s2,0x3c
    800006d2:	97da                	add	a5,a5,s6
    800006d4:	0007c503          	lbu	a0,0(a5)
    800006d8:	00000097          	auipc	ra,0x0
    800006dc:	bb0080e7          	jalr	-1104(ra) # 80000288 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e0:	0912                	slli	s2,s2,0x4
    800006e2:	34fd                	addiw	s1,s1,-1
    800006e4:	f4ed                	bnez	s1,800006ce <printf+0x13a>
    800006e6:	b7a1                	j	8000062e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	6384                	ld	s1,0(a5)
    800006f6:	cc89                	beqz	s1,80000710 <printf+0x17c>
      for(; *s; s++)
    800006f8:	0004c503          	lbu	a0,0(s1)
    800006fc:	d90d                	beqz	a0,8000062e <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b8a080e7          	jalr	-1142(ra) # 80000288 <consputc>
      for(; *s; s++)
    80000706:	0485                	addi	s1,s1,1
    80000708:	0004c503          	lbu	a0,0(s1)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x16a>
    8000070e:	b705                	j	8000062e <printf+0x9a>
        s = "(null)";
    80000710:	00008497          	auipc	s1,0x8
    80000714:	91048493          	addi	s1,s1,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x16a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b68080e7          	jalr	-1176(ra) # 80000288 <consputc>
      break;
    80000728:	b719                	j	8000062e <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b5c080e7          	jalr	-1188(ra) # 80000288 <consputc>
      consputc(c);
    80000734:	8526                	mv	a0,s1
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b52080e7          	jalr	-1198(ra) # 80000288 <consputc>
      break;
    8000073e:	bdc5                	j	8000062e <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1ce>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00011517          	auipc	a0,0x11
    80000766:	ab650513          	addi	a0,a0,-1354 # 80011218 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	550080e7          	jalr	1360(ra) # 80000cba <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b0>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00011497          	auipc	s1,0x11
    80000782:	a9a48493          	addi	s1,s1,-1382 # 80011218 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3e6080e7          	jalr	998(ra) # 80000b76 <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00011517          	auipc	a0,0x11
    800007e2:	a5a50513          	addi	a0,a0,-1446 # 80011238 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	390080e7          	jalr	912(ra) # 80000b76 <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	3b8080e7          	jalr	952(ra) # 80000bba <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	7f67a783          	lw	a5,2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0207f793          	andi	a5,a5,32
    80000822:	dfe5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000824:	0ff4f513          	andi	a0,s1,255
    80000828:	100007b7          	lui	a5,0x10000
    8000082c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000830:	00000097          	auipc	ra,0x0
    80000834:	42a080e7          	jalr	1066(ra) # 80000c5a <pop_off>
}
    80000838:	60e2                	ld	ra,24(sp)
    8000083a:	6442                	ld	s0,16(sp)
    8000083c:	64a2                	ld	s1,8(sp)
    8000083e:	6105                	addi	sp,sp,32
    80000840:	8082                	ret

0000000080000842 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000842:	00008797          	auipc	a5,0x8
    80000846:	7c27a783          	lw	a5,1986(a5) # 80009004 <uart_tx_r>
    8000084a:	00008717          	auipc	a4,0x8
    8000084e:	7be72703          	lw	a4,1982(a4) # 80009008 <uart_tx_w>
    80000852:	08f70063          	beq	a4,a5,800008d2 <uartstart+0x90>
{
    80000856:	7139                	addi	sp,sp,-64
    80000858:	fc06                	sd	ra,56(sp)
    8000085a:	f822                	sd	s0,48(sp)
    8000085c:	f426                	sd	s1,40(sp)
    8000085e:	f04a                	sd	s2,32(sp)
    80000860:	ec4e                	sd	s3,24(sp)
    80000862:	e852                	sd	s4,16(sp)
    80000864:	e456                	sd	s5,8(sp)
    80000866:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000868:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000086c:	00011a97          	auipc	s5,0x11
    80000870:	9cca8a93          	addi	s5,s5,-1588 # 80011238 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000874:	00008497          	auipc	s1,0x8
    80000878:	79048493          	addi	s1,s1,1936 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087c:	00008a17          	auipc	s4,0x8
    80000880:	78ca0a13          	addi	s4,s4,1932 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000884:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000888:	02077713          	andi	a4,a4,32
    8000088c:	cb15                	beqz	a4,800008c0 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    8000088e:	00fa8733          	add	a4,s5,a5
    80000892:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000896:	2785                	addiw	a5,a5,1
    80000898:	41f7d71b          	sraiw	a4,a5,0x1f
    8000089c:	01b7571b          	srliw	a4,a4,0x1b
    800008a0:	9fb9                	addw	a5,a5,a4
    800008a2:	8bfd                	andi	a5,a5,31
    800008a4:	9f99                	subw	a5,a5,a4
    800008a6:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a8:	8526                	mv	a0,s1
    800008aa:	00002097          	auipc	ra,0x2
    800008ae:	b8a080e7          	jalr	-1142(ra) # 80002434 <wakeup>
    
    WriteReg(THR, c);
    800008b2:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b6:	409c                	lw	a5,0(s1)
    800008b8:	000a2703          	lw	a4,0(s4)
    800008bc:	fcf714e3          	bne	a4,a5,80000884 <uartstart+0x42>
  }
}
    800008c0:	70e2                	ld	ra,56(sp)
    800008c2:	7442                	ld	s0,48(sp)
    800008c4:	74a2                	ld	s1,40(sp)
    800008c6:	7902                	ld	s2,32(sp)
    800008c8:	69e2                	ld	s3,24(sp)
    800008ca:	6a42                	ld	s4,16(sp)
    800008cc:	6aa2                	ld	s5,8(sp)
    800008ce:	6121                	addi	sp,sp,64
    800008d0:	8082                	ret
    800008d2:	8082                	ret

00000000800008d4 <uartputc>:
{
    800008d4:	7179                	addi	sp,sp,-48
    800008d6:	f406                	sd	ra,40(sp)
    800008d8:	f022                	sd	s0,32(sp)
    800008da:	ec26                	sd	s1,24(sp)
    800008dc:	e84a                	sd	s2,16(sp)
    800008de:	e44e                	sd	s3,8(sp)
    800008e0:	e052                	sd	s4,0(sp)
    800008e2:	1800                	addi	s0,sp,48
    800008e4:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008e6:	00011517          	auipc	a0,0x11
    800008ea:	95250513          	addi	a0,a0,-1710 # 80011238 <uart_tx_lock>
    800008ee:	00000097          	auipc	ra,0x0
    800008f2:	318080e7          	jalr	792(ra) # 80000c06 <acquire>
  if(panicked){
    800008f6:	00008797          	auipc	a5,0x8
    800008fa:	70a7a783          	lw	a5,1802(a5) # 80009000 <panicked>
    800008fe:	c391                	beqz	a5,80000902 <uartputc+0x2e>
    for(;;)
    80000900:	a001                	j	80000900 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000902:	00008697          	auipc	a3,0x8
    80000906:	7066a683          	lw	a3,1798(a3) # 80009008 <uart_tx_w>
    8000090a:	0016879b          	addiw	a5,a3,1
    8000090e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000912:	01b7571b          	srliw	a4,a4,0x1b
    80000916:	9fb9                	addw	a5,a5,a4
    80000918:	8bfd                	andi	a5,a5,31
    8000091a:	9f99                	subw	a5,a5,a4
    8000091c:	00008717          	auipc	a4,0x8
    80000920:	6e872703          	lw	a4,1768(a4) # 80009004 <uart_tx_r>
    80000924:	04f71363          	bne	a4,a5,8000096a <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	00011a17          	auipc	s4,0x11
    8000092c:	910a0a13          	addi	s4,s4,-1776 # 80011238 <uart_tx_lock>
    80000930:	00008917          	auipc	s2,0x8
    80000934:	6d490913          	addi	s2,s2,1748 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000938:	00008997          	auipc	s3,0x8
    8000093c:	6d098993          	addi	s3,s3,1744 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000940:	85d2                	mv	a1,s4
    80000942:	854a                	mv	a0,s2
    80000944:	00002097          	auipc	ra,0x2
    80000948:	96c080e7          	jalr	-1684(ra) # 800022b0 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	0009a683          	lw	a3,0(s3)
    80000950:	0016879b          	addiw	a5,a3,1
    80000954:	41f7d71b          	sraiw	a4,a5,0x1f
    80000958:	01b7571b          	srliw	a4,a4,0x1b
    8000095c:	9fb9                	addw	a5,a5,a4
    8000095e:	8bfd                	andi	a5,a5,31
    80000960:	9f99                	subw	a5,a5,a4
    80000962:	00092703          	lw	a4,0(s2)
    80000966:	fcf70de3          	beq	a4,a5,80000940 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000096a:	00011917          	auipc	s2,0x11
    8000096e:	8ce90913          	addi	s2,s2,-1842 # 80011238 <uart_tx_lock>
    80000972:	96ca                	add	a3,a3,s2
    80000974:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000978:	00008717          	auipc	a4,0x8
    8000097c:	68f72823          	sw	a5,1680(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000980:	00000097          	auipc	ra,0x0
    80000984:	ec2080e7          	jalr	-318(ra) # 80000842 <uartstart>
      release(&uart_tx_lock);
    80000988:	854a                	mv	a0,s2
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	330080e7          	jalr	816(ra) # 80000cba <release>
}
    80000992:	70a2                	ld	ra,40(sp)
    80000994:	7402                	ld	s0,32(sp)
    80000996:	64e2                	ld	s1,24(sp)
    80000998:	6942                	ld	s2,16(sp)
    8000099a:	69a2                	ld	s3,8(sp)
    8000099c:	6a02                	ld	s4,0(sp)
    8000099e:	6145                	addi	sp,sp,48
    800009a0:	8082                	ret

00000000800009a2 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009a2:	1141                	addi	sp,sp,-16
    800009a4:	e422                	sd	s0,8(sp)
    800009a6:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a8:	100007b7          	lui	a5,0x10000
    800009ac:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009b0:	8b85                	andi	a5,a5,1
    800009b2:	cb91                	beqz	a5,800009c6 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009b4:	100007b7          	lui	a5,0x10000
    800009b8:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009bc:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009c0:	6422                	ld	s0,8(sp)
    800009c2:	0141                	addi	sp,sp,16
    800009c4:	8082                	ret
    return -1;
    800009c6:	557d                	li	a0,-1
    800009c8:	bfe5                	j	800009c0 <uartgetc+0x1e>

00000000800009ca <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009ca:	1101                	addi	sp,sp,-32
    800009cc:	ec06                	sd	ra,24(sp)
    800009ce:	e822                	sd	s0,16(sp)
    800009d0:	e426                	sd	s1,8(sp)
    800009d2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009d4:	54fd                	li	s1,-1
    800009d6:	a029                	j	800009e0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	8f2080e7          	jalr	-1806(ra) # 800002ca <consoleintr>
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fc2080e7          	jalr	-62(ra) # 800009a2 <uartgetc>
    if(c == -1)
    800009e8:	fe9518e3          	bne	a0,s1,800009d8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ec:	00011497          	auipc	s1,0x11
    800009f0:	84c48493          	addi	s1,s1,-1972 # 80011238 <uart_tx_lock>
    800009f4:	8526                	mv	a0,s1
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	210080e7          	jalr	528(ra) # 80000c06 <acquire>
  uartstart();
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	e44080e7          	jalr	-444(ra) # 80000842 <uartstart>
  release(&uart_tx_lock);
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	2b2080e7          	jalr	690(ra) # 80000cba <release>
}
    80000a10:	60e2                	ld	ra,24(sp)
    80000a12:	6442                	ld	s0,16(sp)
    80000a14:	64a2                	ld	s1,8(sp)
    80000a16:	6105                	addi	sp,sp,32
    80000a18:	8082                	ret

0000000080000a1a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1a:	1101                	addi	sp,sp,-32
    80000a1c:	ec06                	sd	ra,24(sp)
    80000a1e:	e822                	sd	s0,16(sp)
    80000a20:	e426                	sd	s1,8(sp)
    80000a22:	e04a                	sd	s2,0(sp)
    80000a24:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a26:	03451793          	slli	a5,a0,0x34
    80000a2a:	ebb9                	bnez	a5,80000a80 <kfree+0x66>
    80000a2c:	84aa                	mv	s1,a0
    80000a2e:	00066797          	auipc	a5,0x66
    80000a32:	5d278793          	addi	a5,a5,1490 # 80067000 <end>
    80000a36:	04f56563          	bltu	a0,a5,80000a80 <kfree+0x66>
    80000a3a:	47c5                	li	a5,17
    80000a3c:	07ee                	slli	a5,a5,0x1b
    80000a3e:	04f57163          	bgeu	a0,a5,80000a80 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a42:	6605                	lui	a2,0x1
    80000a44:	4585                	li	a1,1
    80000a46:	00000097          	auipc	ra,0x0
    80000a4a:	2bc080e7          	jalr	700(ra) # 80000d02 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4e:	00011917          	auipc	s2,0x11
    80000a52:	82290913          	addi	s2,s2,-2014 # 80011270 <kmem>
    80000a56:	854a                	mv	a0,s2
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	1ae080e7          	jalr	430(ra) # 80000c06 <acquire>
  r->next = kmem.freelist;
    80000a60:	01893783          	ld	a5,24(s2)
    80000a64:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a66:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a6a:	854a                	mv	a0,s2
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	24e080e7          	jalr	590(ra) # 80000cba <release>
}
    80000a74:	60e2                	ld	ra,24(sp)
    80000a76:	6442                	ld	s0,16(sp)
    80000a78:	64a2                	ld	s1,8(sp)
    80000a7a:	6902                	ld	s2,0(sp)
    80000a7c:	6105                	addi	sp,sp,32
    80000a7e:	8082                	ret
    panic("kfree");
    80000a80:	00007517          	auipc	a0,0x7
    80000a84:	5e050513          	addi	a0,a0,1504 # 80008060 <digits+0x20>
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	ac2080e7          	jalr	-1342(ra) # 8000054a <panic>

0000000080000a90 <freerange>:
{
    80000a90:	7179                	addi	sp,sp,-48
    80000a92:	f406                	sd	ra,40(sp)
    80000a94:	f022                	sd	s0,32(sp)
    80000a96:	ec26                	sd	s1,24(sp)
    80000a98:	e84a                	sd	s2,16(sp)
    80000a9a:	e44e                	sd	s3,8(sp)
    80000a9c:	e052                	sd	s4,0(sp)
    80000a9e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aa0:	6785                	lui	a5,0x1
    80000aa2:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000aa6:	94aa                	add	s1,s1,a0
    80000aa8:	757d                	lui	a0,0xfffff
    80000aaa:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	94be                	add	s1,s1,a5
    80000aae:	0095ee63          	bltu	a1,s1,80000aca <freerange+0x3a>
    80000ab2:	892e                	mv	s2,a1
    kfree(p);
    80000ab4:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	6985                	lui	s3,0x1
    kfree(p);
    80000ab8:	01448533          	add	a0,s1,s4
    80000abc:	00000097          	auipc	ra,0x0
    80000ac0:	f5e080e7          	jalr	-162(ra) # 80000a1a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac4:	94ce                	add	s1,s1,s3
    80000ac6:	fe9979e3          	bgeu	s2,s1,80000ab8 <freerange+0x28>
}
    80000aca:	70a2                	ld	ra,40(sp)
    80000acc:	7402                	ld	s0,32(sp)
    80000ace:	64e2                	ld	s1,24(sp)
    80000ad0:	6942                	ld	s2,16(sp)
    80000ad2:	69a2                	ld	s3,8(sp)
    80000ad4:	6a02                	ld	s4,0(sp)
    80000ad6:	6145                	addi	sp,sp,48
    80000ad8:	8082                	ret

0000000080000ada <kinit>:
{
    80000ada:	1141                	addi	sp,sp,-16
    80000adc:	e406                	sd	ra,8(sp)
    80000ade:	e022                	sd	s0,0(sp)
    80000ae0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ae2:	00007597          	auipc	a1,0x7
    80000ae6:	58658593          	addi	a1,a1,1414 # 80008068 <digits+0x28>
    80000aea:	00010517          	auipc	a0,0x10
    80000aee:	78650513          	addi	a0,a0,1926 # 80011270 <kmem>
    80000af2:	00000097          	auipc	ra,0x0
    80000af6:	084080e7          	jalr	132(ra) # 80000b76 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000afa:	45c5                	li	a1,17
    80000afc:	05ee                	slli	a1,a1,0x1b
    80000afe:	00066517          	auipc	a0,0x66
    80000b02:	50250513          	addi	a0,a0,1282 # 80067000 <end>
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	f8a080e7          	jalr	-118(ra) # 80000a90 <freerange>
}
    80000b0e:	60a2                	ld	ra,8(sp)
    80000b10:	6402                	ld	s0,0(sp)
    80000b12:	0141                	addi	sp,sp,16
    80000b14:	8082                	ret

0000000080000b16 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b16:	1101                	addi	sp,sp,-32
    80000b18:	ec06                	sd	ra,24(sp)
    80000b1a:	e822                	sd	s0,16(sp)
    80000b1c:	e426                	sd	s1,8(sp)
    80000b1e:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b20:	00010497          	auipc	s1,0x10
    80000b24:	75048493          	addi	s1,s1,1872 # 80011270 <kmem>
    80000b28:	8526                	mv	a0,s1
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	0dc080e7          	jalr	220(ra) # 80000c06 <acquire>
  r = kmem.freelist;
    80000b32:	6c84                	ld	s1,24(s1)
  if(r)
    80000b34:	c885                	beqz	s1,80000b64 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b36:	609c                	ld	a5,0(s1)
    80000b38:	00010517          	auipc	a0,0x10
    80000b3c:	73850513          	addi	a0,a0,1848 # 80011270 <kmem>
    80000b40:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	178080e7          	jalr	376(ra) # 80000cba <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b4a:	6605                	lui	a2,0x1
    80000b4c:	4595                	li	a1,5
    80000b4e:	8526                	mv	a0,s1
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	1b2080e7          	jalr	434(ra) # 80000d02 <memset>
  return (void*)r;
}
    80000b58:	8526                	mv	a0,s1
    80000b5a:	60e2                	ld	ra,24(sp)
    80000b5c:	6442                	ld	s0,16(sp)
    80000b5e:	64a2                	ld	s1,8(sp)
    80000b60:	6105                	addi	sp,sp,32
    80000b62:	8082                	ret
  release(&kmem.lock);
    80000b64:	00010517          	auipc	a0,0x10
    80000b68:	70c50513          	addi	a0,a0,1804 # 80011270 <kmem>
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	14e080e7          	jalr	334(ra) # 80000cba <release>
  if(r)
    80000b74:	b7d5                	j	80000b58 <kalloc+0x42>

0000000080000b76 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b76:	1141                	addi	sp,sp,-16
    80000b78:	e422                	sd	s0,8(sp)
    80000b7a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b7c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b7e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b82:	00053823          	sd	zero,16(a0)
}
    80000b86:	6422                	ld	s0,8(sp)
    80000b88:	0141                	addi	sp,sp,16
    80000b8a:	8082                	ret

0000000080000b8c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b8c:	411c                	lw	a5,0(a0)
    80000b8e:	e399                	bnez	a5,80000b94 <holding+0x8>
    80000b90:	4501                	li	a0,0
  return r;
}
    80000b92:	8082                	ret
{
    80000b94:	1101                	addi	sp,sp,-32
    80000b96:	ec06                	sd	ra,24(sp)
    80000b98:	e822                	sd	s0,16(sp)
    80000b9a:	e426                	sd	s1,8(sp)
    80000b9c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b9e:	6904                	ld	s1,16(a0)
    80000ba0:	00001097          	auipc	ra,0x1
    80000ba4:	e52080e7          	jalr	-430(ra) # 800019f2 <mycpu>
    80000ba8:	40a48533          	sub	a0,s1,a0
    80000bac:	00153513          	seqz	a0,a0
}
    80000bb0:	60e2                	ld	ra,24(sp)
    80000bb2:	6442                	ld	s0,16(sp)
    80000bb4:	64a2                	ld	s1,8(sp)
    80000bb6:	6105                	addi	sp,sp,32
    80000bb8:	8082                	ret

0000000080000bba <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bba:	1101                	addi	sp,sp,-32
    80000bbc:	ec06                	sd	ra,24(sp)
    80000bbe:	e822                	sd	s0,16(sp)
    80000bc0:	e426                	sd	s1,8(sp)
    80000bc2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bc4:	100024f3          	csrr	s1,sstatus
    80000bc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bcc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bce:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	e20080e7          	jalr	-480(ra) # 800019f2 <mycpu>
    80000bda:	5d3c                	lw	a5,120(a0)
    80000bdc:	cf89                	beqz	a5,80000bf6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bde:	00001097          	auipc	ra,0x1
    80000be2:	e14080e7          	jalr	-492(ra) # 800019f2 <mycpu>
    80000be6:	5d3c                	lw	a5,120(a0)
    80000be8:	2785                	addiw	a5,a5,1
    80000bea:	dd3c                	sw	a5,120(a0)
}
    80000bec:	60e2                	ld	ra,24(sp)
    80000bee:	6442                	ld	s0,16(sp)
    80000bf0:	64a2                	ld	s1,8(sp)
    80000bf2:	6105                	addi	sp,sp,32
    80000bf4:	8082                	ret
    mycpu()->intena = old;
    80000bf6:	00001097          	auipc	ra,0x1
    80000bfa:	dfc080e7          	jalr	-516(ra) # 800019f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bfe:	8085                	srli	s1,s1,0x1
    80000c00:	8885                	andi	s1,s1,1
    80000c02:	dd64                	sw	s1,124(a0)
    80000c04:	bfe9                	j	80000bde <push_off+0x24>

0000000080000c06 <acquire>:
{
    80000c06:	1101                	addi	sp,sp,-32
    80000c08:	ec06                	sd	ra,24(sp)
    80000c0a:	e822                	sd	s0,16(sp)
    80000c0c:	e426                	sd	s1,8(sp)
    80000c0e:	1000                	addi	s0,sp,32
    80000c10:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	fa8080e7          	jalr	-88(ra) # 80000bba <push_off>
  if(holding(lk))
    80000c1a:	8526                	mv	a0,s1
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	f70080e7          	jalr	-144(ra) # 80000b8c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c24:	4705                	li	a4,1
  if(holding(lk))
    80000c26:	e115                	bnez	a0,80000c4a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c28:	87ba                	mv	a5,a4
    80000c2a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c2e:	2781                	sext.w	a5,a5
    80000c30:	ffe5                	bnez	a5,80000c28 <acquire+0x22>
  __sync_synchronize();
    80000c32:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c36:	00001097          	auipc	ra,0x1
    80000c3a:	dbc080e7          	jalr	-580(ra) # 800019f2 <mycpu>
    80000c3e:	e888                	sd	a0,16(s1)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    panic("acquire");
    80000c4a:	00007517          	auipc	a0,0x7
    80000c4e:	42650513          	addi	a0,a0,1062 # 80008070 <digits+0x30>
    80000c52:	00000097          	auipc	ra,0x0
    80000c56:	8f8080e7          	jalr	-1800(ra) # 8000054a <panic>

0000000080000c5a <pop_off>:

void
pop_off(void)
{
    80000c5a:	1141                	addi	sp,sp,-16
    80000c5c:	e406                	sd	ra,8(sp)
    80000c5e:	e022                	sd	s0,0(sp)
    80000c60:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	d90080e7          	jalr	-624(ra) # 800019f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c6e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c70:	e78d                	bnez	a5,80000c9a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c72:	5d3c                	lw	a5,120(a0)
    80000c74:	02f05b63          	blez	a5,80000caa <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c78:	37fd                	addiw	a5,a5,-1
    80000c7a:	0007871b          	sext.w	a4,a5
    80000c7e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c80:	eb09                	bnez	a4,80000c92 <pop_off+0x38>
    80000c82:	5d7c                	lw	a5,124(a0)
    80000c84:	c799                	beqz	a5,80000c92 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c8e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c92:	60a2                	ld	ra,8(sp)
    80000c94:	6402                	ld	s0,0(sp)
    80000c96:	0141                	addi	sp,sp,16
    80000c98:	8082                	ret
    panic("pop_off - interruptible");
    80000c9a:	00007517          	auipc	a0,0x7
    80000c9e:	3de50513          	addi	a0,a0,990 # 80008078 <digits+0x38>
    80000ca2:	00000097          	auipc	ra,0x0
    80000ca6:	8a8080e7          	jalr	-1880(ra) # 8000054a <panic>
    panic("pop_off");
    80000caa:	00007517          	auipc	a0,0x7
    80000cae:	3e650513          	addi	a0,a0,998 # 80008090 <digits+0x50>
    80000cb2:	00000097          	auipc	ra,0x0
    80000cb6:	898080e7          	jalr	-1896(ra) # 8000054a <panic>

0000000080000cba <release>:
{
    80000cba:	1101                	addi	sp,sp,-32
    80000cbc:	ec06                	sd	ra,24(sp)
    80000cbe:	e822                	sd	s0,16(sp)
    80000cc0:	e426                	sd	s1,8(sp)
    80000cc2:	1000                	addi	s0,sp,32
    80000cc4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	ec6080e7          	jalr	-314(ra) # 80000b8c <holding>
    80000cce:	c115                	beqz	a0,80000cf2 <release+0x38>
  lk->cpu = 0;
    80000cd0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cd4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd8:	0f50000f          	fence	iorw,ow
    80000cdc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	f7a080e7          	jalr	-134(ra) # 80000c5a <pop_off>
}
    80000ce8:	60e2                	ld	ra,24(sp)
    80000cea:	6442                	ld	s0,16(sp)
    80000cec:	64a2                	ld	s1,8(sp)
    80000cee:	6105                	addi	sp,sp,32
    80000cf0:	8082                	ret
    panic("release");
    80000cf2:	00007517          	auipc	a0,0x7
    80000cf6:	3a650513          	addi	a0,a0,934 # 80008098 <digits+0x58>
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	850080e7          	jalr	-1968(ra) # 8000054a <panic>

0000000080000d02 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d02:	1141                	addi	sp,sp,-16
    80000d04:	e422                	sd	s0,8(sp)
    80000d06:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d08:	ca19                	beqz	a2,80000d1e <memset+0x1c>
    80000d0a:	87aa                	mv	a5,a0
    80000d0c:	1602                	slli	a2,a2,0x20
    80000d0e:	9201                	srli	a2,a2,0x20
    80000d10:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d14:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d18:	0785                	addi	a5,a5,1
    80000d1a:	fee79de3          	bne	a5,a4,80000d14 <memset+0x12>
  }
  return dst;
}
    80000d1e:	6422                	ld	s0,8(sp)
    80000d20:	0141                	addi	sp,sp,16
    80000d22:	8082                	ret

0000000080000d24 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d24:	1141                	addi	sp,sp,-16
    80000d26:	e422                	sd	s0,8(sp)
    80000d28:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d2a:	ca05                	beqz	a2,80000d5a <memcmp+0x36>
    80000d2c:	fff6069b          	addiw	a3,a2,-1
    80000d30:	1682                	slli	a3,a3,0x20
    80000d32:	9281                	srli	a3,a3,0x20
    80000d34:	0685                	addi	a3,a3,1
    80000d36:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d38:	00054783          	lbu	a5,0(a0)
    80000d3c:	0005c703          	lbu	a4,0(a1)
    80000d40:	00e79863          	bne	a5,a4,80000d50 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d44:	0505                	addi	a0,a0,1
    80000d46:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d48:	fed518e3          	bne	a0,a3,80000d38 <memcmp+0x14>
  }

  return 0;
    80000d4c:	4501                	li	a0,0
    80000d4e:	a019                	j	80000d54 <memcmp+0x30>
      return *s1 - *s2;
    80000d50:	40e7853b          	subw	a0,a5,a4
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	bfe5                	j	80000d54 <memcmp+0x30>

0000000080000d5e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d5e:	1141                	addi	sp,sp,-16
    80000d60:	e422                	sd	s0,8(sp)
    80000d62:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d64:	02a5e563          	bltu	a1,a0,80000d8e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d68:	fff6069b          	addiw	a3,a2,-1
    80000d6c:	ce11                	beqz	a2,80000d88 <memmove+0x2a>
    80000d6e:	1682                	slli	a3,a3,0x20
    80000d70:	9281                	srli	a3,a3,0x20
    80000d72:	0685                	addi	a3,a3,1
    80000d74:	96ae                	add	a3,a3,a1
    80000d76:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d78:	0585                	addi	a1,a1,1
    80000d7a:	0785                	addi	a5,a5,1
    80000d7c:	fff5c703          	lbu	a4,-1(a1)
    80000d80:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d84:	fed59ae3          	bne	a1,a3,80000d78 <memmove+0x1a>

  return dst;
}
    80000d88:	6422                	ld	s0,8(sp)
    80000d8a:	0141                	addi	sp,sp,16
    80000d8c:	8082                	ret
  if(s < d && s + n > d){
    80000d8e:	02061713          	slli	a4,a2,0x20
    80000d92:	9301                	srli	a4,a4,0x20
    80000d94:	00e587b3          	add	a5,a1,a4
    80000d98:	fcf578e3          	bgeu	a0,a5,80000d68 <memmove+0xa>
    d += n;
    80000d9c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d9e:	fff6069b          	addiw	a3,a2,-1
    80000da2:	d27d                	beqz	a2,80000d88 <memmove+0x2a>
    80000da4:	02069613          	slli	a2,a3,0x20
    80000da8:	9201                	srli	a2,a2,0x20
    80000daa:	fff64613          	not	a2,a2
    80000dae:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000db0:	17fd                	addi	a5,a5,-1
    80000db2:	177d                	addi	a4,a4,-1
    80000db4:	0007c683          	lbu	a3,0(a5)
    80000db8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dbc:	fef61ae3          	bne	a2,a5,80000db0 <memmove+0x52>
    80000dc0:	b7e1                	j	80000d88 <memmove+0x2a>

0000000080000dc2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dc2:	1141                	addi	sp,sp,-16
    80000dc4:	e406                	sd	ra,8(sp)
    80000dc6:	e022                	sd	s0,0(sp)
    80000dc8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dca:	00000097          	auipc	ra,0x0
    80000dce:	f94080e7          	jalr	-108(ra) # 80000d5e <memmove>
}
    80000dd2:	60a2                	ld	ra,8(sp)
    80000dd4:	6402                	ld	s0,0(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret

0000000080000dda <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dda:	1141                	addi	sp,sp,-16
    80000ddc:	e422                	sd	s0,8(sp)
    80000dde:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000de0:	ce11                	beqz	a2,80000dfc <strncmp+0x22>
    80000de2:	00054783          	lbu	a5,0(a0)
    80000de6:	cf89                	beqz	a5,80000e00 <strncmp+0x26>
    80000de8:	0005c703          	lbu	a4,0(a1)
    80000dec:	00f71a63          	bne	a4,a5,80000e00 <strncmp+0x26>
    n--, p++, q++;
    80000df0:	367d                	addiw	a2,a2,-1
    80000df2:	0505                	addi	a0,a0,1
    80000df4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df6:	f675                	bnez	a2,80000de2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df8:	4501                	li	a0,0
    80000dfa:	a809                	j	80000e0c <strncmp+0x32>
    80000dfc:	4501                	li	a0,0
    80000dfe:	a039                	j	80000e0c <strncmp+0x32>
  if(n == 0)
    80000e00:	ca09                	beqz	a2,80000e12 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e02:	00054503          	lbu	a0,0(a0)
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	9d1d                	subw	a0,a0,a5
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret
    return 0;
    80000e12:	4501                	li	a0,0
    80000e14:	bfe5                	j	80000e0c <strncmp+0x32>

0000000080000e16 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e422                	sd	s0,8(sp)
    80000e1a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e1c:	872a                	mv	a4,a0
    80000e1e:	8832                	mv	a6,a2
    80000e20:	367d                	addiw	a2,a2,-1
    80000e22:	01005963          	blez	a6,80000e34 <strncpy+0x1e>
    80000e26:	0705                	addi	a4,a4,1
    80000e28:	0005c783          	lbu	a5,0(a1)
    80000e2c:	fef70fa3          	sb	a5,-1(a4)
    80000e30:	0585                	addi	a1,a1,1
    80000e32:	f7f5                	bnez	a5,80000e1e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e34:	86ba                	mv	a3,a4
    80000e36:	00c05c63          	blez	a2,80000e4e <strncpy+0x38>
    *s++ = 0;
    80000e3a:	0685                	addi	a3,a3,1
    80000e3c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e40:	fff6c793          	not	a5,a3
    80000e44:	9fb9                	addw	a5,a5,a4
    80000e46:	010787bb          	addw	a5,a5,a6
    80000e4a:	fef048e3          	bgtz	a5,80000e3a <strncpy+0x24>
  return os;
}
    80000e4e:	6422                	ld	s0,8(sp)
    80000e50:	0141                	addi	sp,sp,16
    80000e52:	8082                	ret

0000000080000e54 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e54:	1141                	addi	sp,sp,-16
    80000e56:	e422                	sd	s0,8(sp)
    80000e58:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e5a:	02c05363          	blez	a2,80000e80 <safestrcpy+0x2c>
    80000e5e:	fff6069b          	addiw	a3,a2,-1
    80000e62:	1682                	slli	a3,a3,0x20
    80000e64:	9281                	srli	a3,a3,0x20
    80000e66:	96ae                	add	a3,a3,a1
    80000e68:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e6a:	00d58963          	beq	a1,a3,80000e7c <safestrcpy+0x28>
    80000e6e:	0585                	addi	a1,a1,1
    80000e70:	0785                	addi	a5,a5,1
    80000e72:	fff5c703          	lbu	a4,-1(a1)
    80000e76:	fee78fa3          	sb	a4,-1(a5)
    80000e7a:	fb65                	bnez	a4,80000e6a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e7c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e80:	6422                	ld	s0,8(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret

0000000080000e86 <strlen>:

int
strlen(const char *s)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e8c:	00054783          	lbu	a5,0(a0)
    80000e90:	cf91                	beqz	a5,80000eac <strlen+0x26>
    80000e92:	0505                	addi	a0,a0,1
    80000e94:	87aa                	mv	a5,a0
    80000e96:	4685                	li	a3,1
    80000e98:	9e89                	subw	a3,a3,a0
    80000e9a:	00f6853b          	addw	a0,a3,a5
    80000e9e:	0785                	addi	a5,a5,1
    80000ea0:	fff7c703          	lbu	a4,-1(a5)
    80000ea4:	fb7d                	bnez	a4,80000e9a <strlen+0x14>
    ;
  return n;
}
    80000ea6:	6422                	ld	s0,8(sp)
    80000ea8:	0141                	addi	sp,sp,16
    80000eaa:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eac:	4501                	li	a0,0
    80000eae:	bfe5                	j	80000ea6 <strlen+0x20>

0000000080000eb0 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eb0:	1141                	addi	sp,sp,-16
    80000eb2:	e406                	sd	ra,8(sp)
    80000eb4:	e022                	sd	s0,0(sp)
    80000eb6:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	b2a080e7          	jalr	-1238(ra) # 800019e2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ec0:	00008717          	auipc	a4,0x8
    80000ec4:	14c70713          	addi	a4,a4,332 # 8000900c <started>
  if(cpuid() == 0){
    80000ec8:	c139                	beqz	a0,80000f0e <main+0x5e>
    while(started == 0)
    80000eca:	431c                	lw	a5,0(a4)
    80000ecc:	2781                	sext.w	a5,a5
    80000ece:	dff5                	beqz	a5,80000eca <main+0x1a>
      ;
    __sync_synchronize();
    80000ed0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	b0e080e7          	jalr	-1266(ra) # 800019e2 <cpuid>
    80000edc:	85aa                	mv	a1,a0
    80000ede:	00007517          	auipc	a0,0x7
    80000ee2:	1da50513          	addi	a0,a0,474 # 800080b8 <digits+0x78>
    80000ee6:	fffff097          	auipc	ra,0xfffff
    80000eea:	6ae080e7          	jalr	1710(ra) # 80000594 <printf>
    kvminithart();    // turn on paging
    80000eee:	00000097          	auipc	ra,0x0
    80000ef2:	0d8080e7          	jalr	216(ra) # 80000fc6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef6:	00002097          	auipc	ra,0x2
    80000efa:	824080e7          	jalr	-2012(ra) # 8000271a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000efe:	00005097          	auipc	ra,0x5
    80000f02:	292080e7          	jalr	658(ra) # 80006190 <plicinithart>
  }

  scheduler();        
    80000f06:	00001097          	auipc	ra,0x1
    80000f0a:	0d6080e7          	jalr	214(ra) # 80001fdc <scheduler>
    consoleinit();
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	54e080e7          	jalr	1358(ra) # 8000045c <consoleinit>
    printfinit();
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	85e080e7          	jalr	-1954(ra) # 80000774 <printfinit>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	1aa50513          	addi	a0,a0,426 # 800080c8 <digits+0x88>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	66e080e7          	jalr	1646(ra) # 80000594 <printf>
    printf("xv6 kernel is booting\n");
    80000f2e:	00007517          	auipc	a0,0x7
    80000f32:	17250513          	addi	a0,a0,370 # 800080a0 <digits+0x60>
    80000f36:	fffff097          	auipc	ra,0xfffff
    80000f3a:	65e080e7          	jalr	1630(ra) # 80000594 <printf>
    printf("\n");
    80000f3e:	00007517          	auipc	a0,0x7
    80000f42:	18a50513          	addi	a0,a0,394 # 800080c8 <digits+0x88>
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	64e080e7          	jalr	1614(ra) # 80000594 <printf>
    kinit();         // physical page allocator
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	b8c080e7          	jalr	-1140(ra) # 80000ada <kinit>
    kvminit();       // create kernel page table
    80000f56:	00000097          	auipc	ra,0x0
    80000f5a:	310080e7          	jalr	784(ra) # 80001266 <kvminit>
    kvminithart();   // turn on paging
    80000f5e:	00000097          	auipc	ra,0x0
    80000f62:	068080e7          	jalr	104(ra) # 80000fc6 <kvminithart>
    procinit();      // process table
    80000f66:	00001097          	auipc	ra,0x1
    80000f6a:	9d0080e7          	jalr	-1584(ra) # 80001936 <procinit>
    trapinit();      // trap vectors
    80000f6e:	00001097          	auipc	ra,0x1
    80000f72:	784080e7          	jalr	1924(ra) # 800026f2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	7a4080e7          	jalr	1956(ra) # 8000271a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f7e:	00005097          	auipc	ra,0x5
    80000f82:	1fc080e7          	jalr	508(ra) # 8000617a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	20a080e7          	jalr	522(ra) # 80006190 <plicinithart>
    binit();         // buffer cache
    80000f8e:	00002097          	auipc	ra,0x2
    80000f92:	362080e7          	jalr	866(ra) # 800032f0 <binit>
    iinit();         // inode cache
    80000f96:	00003097          	auipc	ra,0x3
    80000f9a:	9f2080e7          	jalr	-1550(ra) # 80003988 <iinit>
    fileinit();      // file table
    80000f9e:	00004097          	auipc	ra,0x4
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80004944 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa6:	00005097          	auipc	ra,0x5
    80000faa:	30c080e7          	jalr	780(ra) # 800062b2 <virtio_disk_init>
    userinit();      // first user process
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	d78080e7          	jalr	-648(ra) # 80001d26 <userinit>
    __sync_synchronize();
    80000fb6:	0ff0000f          	fence
    started = 1;
    80000fba:	4785                	li	a5,1
    80000fbc:	00008717          	auipc	a4,0x8
    80000fc0:	04f72823          	sw	a5,80(a4) # 8000900c <started>
    80000fc4:	b789                	j	80000f06 <main+0x56>

0000000080000fc6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc6:	1141                	addi	sp,sp,-16
    80000fc8:	e422                	sd	s0,8(sp)
    80000fca:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fcc:	00008797          	auipc	a5,0x8
    80000fd0:	0447b783          	ld	a5,68(a5) # 80009010 <kernel_pagetable>
    80000fd4:	83b1                	srli	a5,a5,0xc
    80000fd6:	577d                	li	a4,-1
    80000fd8:	177e                	slli	a4,a4,0x3f
    80000fda:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fdc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe4:	6422                	ld	s0,8(sp)
    80000fe6:	0141                	addi	sp,sp,16
    80000fe8:	8082                	ret

0000000080000fea <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fea:	7139                	addi	sp,sp,-64
    80000fec:	fc06                	sd	ra,56(sp)
    80000fee:	f822                	sd	s0,48(sp)
    80000ff0:	f426                	sd	s1,40(sp)
    80000ff2:	f04a                	sd	s2,32(sp)
    80000ff4:	ec4e                	sd	s3,24(sp)
    80000ff6:	e852                	sd	s4,16(sp)
    80000ff8:	e456                	sd	s5,8(sp)
    80000ffa:	e05a                	sd	s6,0(sp)
    80000ffc:	0080                	addi	s0,sp,64
    80000ffe:	84aa                	mv	s1,a0
    80001000:	89ae                	mv	s3,a1
    80001002:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001004:	57fd                	li	a5,-1
    80001006:	83e9                	srli	a5,a5,0x1a
    80001008:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100a:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100c:	04b7f263          	bgeu	a5,a1,80001050 <walk+0x66>
    panic("walk");
    80001010:	00007517          	auipc	a0,0x7
    80001014:	0c050513          	addi	a0,a0,192 # 800080d0 <digits+0x90>
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	532080e7          	jalr	1330(ra) # 8000054a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001020:	060a8663          	beqz	s5,8000108c <walk+0xa2>
    80001024:	00000097          	auipc	ra,0x0
    80001028:	af2080e7          	jalr	-1294(ra) # 80000b16 <kalloc>
    8000102c:	84aa                	mv	s1,a0
    8000102e:	c529                	beqz	a0,80001078 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001030:	6605                	lui	a2,0x1
    80001032:	4581                	li	a1,0
    80001034:	00000097          	auipc	ra,0x0
    80001038:	cce080e7          	jalr	-818(ra) # 80000d02 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103c:	00c4d793          	srli	a5,s1,0xc
    80001040:	07aa                	slli	a5,a5,0xa
    80001042:	0017e793          	ori	a5,a5,1
    80001046:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104a:	3a5d                	addiw	s4,s4,-9
    8000104c:	036a0063          	beq	s4,s6,8000106c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001050:	0149d933          	srl	s2,s3,s4
    80001054:	1ff97913          	andi	s2,s2,511
    80001058:	090e                	slli	s2,s2,0x3
    8000105a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105c:	00093483          	ld	s1,0(s2)
    80001060:	0014f793          	andi	a5,s1,1
    80001064:	dfd5                	beqz	a5,80001020 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001066:	80a9                	srli	s1,s1,0xa
    80001068:	04b2                	slli	s1,s1,0xc
    8000106a:	b7c5                	j	8000104a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106c:	00c9d513          	srli	a0,s3,0xc
    80001070:	1ff57513          	andi	a0,a0,511
    80001074:	050e                	slli	a0,a0,0x3
    80001076:	9526                	add	a0,a0,s1
}
    80001078:	70e2                	ld	ra,56(sp)
    8000107a:	7442                	ld	s0,48(sp)
    8000107c:	74a2                	ld	s1,40(sp)
    8000107e:	7902                	ld	s2,32(sp)
    80001080:	69e2                	ld	s3,24(sp)
    80001082:	6a42                	ld	s4,16(sp)
    80001084:	6aa2                	ld	s5,8(sp)
    80001086:	6b02                	ld	s6,0(sp)
    80001088:	6121                	addi	sp,sp,64
    8000108a:	8082                	ret
        return 0;
    8000108c:	4501                	li	a0,0
    8000108e:	b7ed                	j	80001078 <walk+0x8e>

0000000080001090 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001090:	57fd                	li	a5,-1
    80001092:	83e9                	srli	a5,a5,0x1a
    80001094:	00b7f463          	bgeu	a5,a1,8000109c <walkaddr+0xc>
    return 0;
    80001098:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109a:	8082                	ret
{
    8000109c:	1141                	addi	sp,sp,-16
    8000109e:	e406                	sd	ra,8(sp)
    800010a0:	e022                	sd	s0,0(sp)
    800010a2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a4:	4601                	li	a2,0
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	f44080e7          	jalr	-188(ra) # 80000fea <walk>
  if(pte == 0)
    800010ae:	c105                	beqz	a0,800010ce <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b2:	0117f693          	andi	a3,a5,17
    800010b6:	4745                	li	a4,17
    return 0;
    800010b8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ba:	00e68663          	beq	a3,a4,800010c6 <walkaddr+0x36>
}
    800010be:	60a2                	ld	ra,8(sp)
    800010c0:	6402                	ld	s0,0(sp)
    800010c2:	0141                	addi	sp,sp,16
    800010c4:	8082                	ret
  pa = PTE2PA(*pte);
    800010c6:	00a7d513          	srli	a0,a5,0xa
    800010ca:	0532                	slli	a0,a0,0xc
  return pa;
    800010cc:	bfcd                	j	800010be <walkaddr+0x2e>
    return 0;
    800010ce:	4501                	li	a0,0
    800010d0:	b7fd                	j	800010be <walkaddr+0x2e>

00000000800010d2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010d2:	715d                	addi	sp,sp,-80
    800010d4:	e486                	sd	ra,72(sp)
    800010d6:	e0a2                	sd	s0,64(sp)
    800010d8:	fc26                	sd	s1,56(sp)
    800010da:	f84a                	sd	s2,48(sp)
    800010dc:	f44e                	sd	s3,40(sp)
    800010de:	f052                	sd	s4,32(sp)
    800010e0:	ec56                	sd	s5,24(sp)
    800010e2:	e85a                	sd	s6,16(sp)
    800010e4:	e45e                	sd	s7,8(sp)
    800010e6:	0880                	addi	s0,sp,80
    800010e8:	8aaa                	mv	s5,a0
    800010ea:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010ec:	777d                	lui	a4,0xfffff
    800010ee:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010f2:	167d                	addi	a2,a2,-1
    800010f4:	00b609b3          	add	s3,a2,a1
    800010f8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010fc:	893e                	mv	s2,a5
    800010fe:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001102:	6b85                	lui	s7,0x1
    80001104:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001108:	4605                	li	a2,1
    8000110a:	85ca                	mv	a1,s2
    8000110c:	8556                	mv	a0,s5
    8000110e:	00000097          	auipc	ra,0x0
    80001112:	edc080e7          	jalr	-292(ra) # 80000fea <walk>
    80001116:	c51d                	beqz	a0,80001144 <mappages+0x72>
    if(*pte & PTE_V)
    80001118:	611c                	ld	a5,0(a0)
    8000111a:	8b85                	andi	a5,a5,1
    8000111c:	ef81                	bnez	a5,80001134 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000111e:	80b1                	srli	s1,s1,0xc
    80001120:	04aa                	slli	s1,s1,0xa
    80001122:	0164e4b3          	or	s1,s1,s6
    80001126:	0014e493          	ori	s1,s1,1
    8000112a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000112c:	03390863          	beq	s2,s3,8000115c <mappages+0x8a>
    a += PGSIZE;
    80001130:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001132:	bfc9                	j	80001104 <mappages+0x32>
      panic("remap");
    80001134:	00007517          	auipc	a0,0x7
    80001138:	fa450513          	addi	a0,a0,-92 # 800080d8 <digits+0x98>
    8000113c:	fffff097          	auipc	ra,0xfffff
    80001140:	40e080e7          	jalr	1038(ra) # 8000054a <panic>
      return -1;
    80001144:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001146:	60a6                	ld	ra,72(sp)
    80001148:	6406                	ld	s0,64(sp)
    8000114a:	74e2                	ld	s1,56(sp)
    8000114c:	7942                	ld	s2,48(sp)
    8000114e:	79a2                	ld	s3,40(sp)
    80001150:	7a02                	ld	s4,32(sp)
    80001152:	6ae2                	ld	s5,24(sp)
    80001154:	6b42                	ld	s6,16(sp)
    80001156:	6ba2                	ld	s7,8(sp)
    80001158:	6161                	addi	sp,sp,80
    8000115a:	8082                	ret
  return 0;
    8000115c:	4501                	li	a0,0
    8000115e:	b7e5                	j	80001146 <mappages+0x74>

0000000080001160 <kvmmap>:
{
    80001160:	1141                	addi	sp,sp,-16
    80001162:	e406                	sd	ra,8(sp)
    80001164:	e022                	sd	s0,0(sp)
    80001166:	0800                	addi	s0,sp,16
    80001168:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000116a:	86b2                	mv	a3,a2
    8000116c:	863e                	mv	a2,a5
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	f64080e7          	jalr	-156(ra) # 800010d2 <mappages>
    80001176:	e509                	bnez	a0,80001180 <kvmmap+0x20>
}
    80001178:	60a2                	ld	ra,8(sp)
    8000117a:	6402                	ld	s0,0(sp)
    8000117c:	0141                	addi	sp,sp,16
    8000117e:	8082                	ret
    panic("kvmmap");
    80001180:	00007517          	auipc	a0,0x7
    80001184:	f6050513          	addi	a0,a0,-160 # 800080e0 <digits+0xa0>
    80001188:	fffff097          	auipc	ra,0xfffff
    8000118c:	3c2080e7          	jalr	962(ra) # 8000054a <panic>

0000000080001190 <kvmmake>:
{
    80001190:	1101                	addi	sp,sp,-32
    80001192:	ec06                	sd	ra,24(sp)
    80001194:	e822                	sd	s0,16(sp)
    80001196:	e426                	sd	s1,8(sp)
    80001198:	e04a                	sd	s2,0(sp)
    8000119a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	97a080e7          	jalr	-1670(ra) # 80000b16 <kalloc>
    800011a4:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	b58080e7          	jalr	-1192(ra) # 80000d02 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	6685                	lui	a3,0x1
    800011b6:	10000637          	lui	a2,0x10000
    800011ba:	100005b7          	lui	a1,0x10000
    800011be:	8526                	mv	a0,s1
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	fa0080e7          	jalr	-96(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c8:	4719                	li	a4,6
    800011ca:	6685                	lui	a3,0x1
    800011cc:	10001637          	lui	a2,0x10001
    800011d0:	100015b7          	lui	a1,0x10001
    800011d4:	8526                	mv	a0,s1
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f8a080e7          	jalr	-118(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011de:	4719                	li	a4,6
    800011e0:	004006b7          	lui	a3,0x400
    800011e4:	0c000637          	lui	a2,0xc000
    800011e8:	0c0005b7          	lui	a1,0xc000
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f72080e7          	jalr	-142(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f6:	00007917          	auipc	s2,0x7
    800011fa:	e0a90913          	addi	s2,s2,-502 # 80008000 <etext>
    800011fe:	4729                	li	a4,10
    80001200:	80007697          	auipc	a3,0x80007
    80001204:	e0068693          	addi	a3,a3,-512 # 8000 <_entry-0x7fff8000>
    80001208:	4605                	li	a2,1
    8000120a:	067e                	slli	a2,a2,0x1f
    8000120c:	85b2                	mv	a1,a2
    8000120e:	8526                	mv	a0,s1
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f50080e7          	jalr	-176(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001218:	4719                	li	a4,6
    8000121a:	46c5                	li	a3,17
    8000121c:	06ee                	slli	a3,a3,0x1b
    8000121e:	412686b3          	sub	a3,a3,s2
    80001222:	864a                	mv	a2,s2
    80001224:	85ca                	mv	a1,s2
    80001226:	8526                	mv	a0,s1
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f38080e7          	jalr	-200(ra) # 80001160 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001230:	4729                	li	a4,10
    80001232:	6685                	lui	a3,0x1
    80001234:	00006617          	auipc	a2,0x6
    80001238:	dcc60613          	addi	a2,a2,-564 # 80007000 <_trampoline>
    8000123c:	040005b7          	lui	a1,0x4000
    80001240:	15fd                	addi	a1,a1,-1
    80001242:	05b2                	slli	a1,a1,0xc
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f1a080e7          	jalr	-230(ra) # 80001160 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	644080e7          	jalr	1604(ra) # 80001894 <proc_mapstacks>
}
    80001258:	8526                	mv	a0,s1
    8000125a:	60e2                	ld	ra,24(sp)
    8000125c:	6442                	ld	s0,16(sp)
    8000125e:	64a2                	ld	s1,8(sp)
    80001260:	6902                	ld	s2,0(sp)
    80001262:	6105                	addi	sp,sp,32
    80001264:	8082                	ret

0000000080001266 <kvminit>:
{
    80001266:	1141                	addi	sp,sp,-16
    80001268:	e406                	sd	ra,8(sp)
    8000126a:	e022                	sd	s0,0(sp)
    8000126c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f22080e7          	jalr	-222(ra) # 80001190 <kvmmake>
    80001276:	00008797          	auipc	a5,0x8
    8000127a:	d8a7bd23          	sd	a0,-614(a5) # 80009010 <kernel_pagetable>
}
    8000127e:	60a2                	ld	ra,8(sp)
    80001280:	6402                	ld	s0,0(sp)
    80001282:	0141                	addi	sp,sp,16
    80001284:	8082                	ret

0000000080001286 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001286:	715d                	addi	sp,sp,-80
    80001288:	e486                	sd	ra,72(sp)
    8000128a:	e0a2                	sd	s0,64(sp)
    8000128c:	fc26                	sd	s1,56(sp)
    8000128e:	f84a                	sd	s2,48(sp)
    80001290:	f44e                	sd	s3,40(sp)
    80001292:	f052                	sd	s4,32(sp)
    80001294:	ec56                	sd	s5,24(sp)
    80001296:	e85a                	sd	s6,16(sp)
    80001298:	e45e                	sd	s7,8(sp)
    8000129a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000129c:	03459793          	slli	a5,a1,0x34
    800012a0:	e795                	bnez	a5,800012cc <uvmunmap+0x46>
    800012a2:	8a2a                	mv	s4,a0
    800012a4:	892e                	mv	s2,a1
    800012a6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	0632                	slli	a2,a2,0xc
    800012aa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ae:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012b0:	6b05                	lui	s6,0x1
    800012b2:	0735e263          	bltu	a1,s3,80001316 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b6:	60a6                	ld	ra,72(sp)
    800012b8:	6406                	ld	s0,64(sp)
    800012ba:	74e2                	ld	s1,56(sp)
    800012bc:	7942                	ld	s2,48(sp)
    800012be:	79a2                	ld	s3,40(sp)
    800012c0:	7a02                	ld	s4,32(sp)
    800012c2:	6ae2                	ld	s5,24(sp)
    800012c4:	6b42                	ld	s6,16(sp)
    800012c6:	6ba2                	ld	s7,8(sp)
    800012c8:	6161                	addi	sp,sp,80
    800012ca:	8082                	ret
    panic("uvmunmap: not aligned");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e1c50513          	addi	a0,a0,-484 # 800080e8 <digits+0xa8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	276080e7          	jalr	630(ra) # 8000054a <panic>
      panic("uvmunmap: walk");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e2450513          	addi	a0,a0,-476 # 80008100 <digits+0xc0>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	266080e7          	jalr	614(ra) # 8000054a <panic>
      panic("uvmunmap: not mapped");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e2450513          	addi	a0,a0,-476 # 80008110 <digits+0xd0>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	256080e7          	jalr	598(ra) # 8000054a <panic>
      panic("uvmunmap: not a leaf");
    800012fc:	00007517          	auipc	a0,0x7
    80001300:	e2c50513          	addi	a0,a0,-468 # 80008128 <digits+0xe8>
    80001304:	fffff097          	auipc	ra,0xfffff
    80001308:	246080e7          	jalr	582(ra) # 8000054a <panic>
    *pte = 0;
    8000130c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001310:	995a                	add	s2,s2,s6
    80001312:	fb3972e3          	bgeu	s2,s3,800012b6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001316:	4601                	li	a2,0
    80001318:	85ca                	mv	a1,s2
    8000131a:	8552                	mv	a0,s4
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	cce080e7          	jalr	-818(ra) # 80000fea <walk>
    80001324:	84aa                	mv	s1,a0
    80001326:	d95d                	beqz	a0,800012dc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001328:	6108                	ld	a0,0(a0)
    8000132a:	00157793          	andi	a5,a0,1
    8000132e:	dfdd                	beqz	a5,800012ec <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001330:	3ff57793          	andi	a5,a0,1023
    80001334:	fd7784e3          	beq	a5,s7,800012fc <uvmunmap+0x76>
    if(do_free){
    80001338:	fc0a8ae3          	beqz	s5,8000130c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000133c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000133e:	0532                	slli	a0,a0,0xc
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	6da080e7          	jalr	1754(ra) # 80000a1a <kfree>
    80001348:	b7d1                	j	8000130c <uvmunmap+0x86>

000000008000134a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000134a:	1101                	addi	sp,sp,-32
    8000134c:	ec06                	sd	ra,24(sp)
    8000134e:	e822                	sd	s0,16(sp)
    80001350:	e426                	sd	s1,8(sp)
    80001352:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	7c2080e7          	jalr	1986(ra) # 80000b16 <kalloc>
    8000135c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000135e:	c519                	beqz	a0,8000136c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001360:	6605                	lui	a2,0x1
    80001362:	4581                	li	a1,0
    80001364:	00000097          	auipc	ra,0x0
    80001368:	99e080e7          	jalr	-1634(ra) # 80000d02 <memset>
  return pagetable;
}
    8000136c:	8526                	mv	a0,s1
    8000136e:	60e2                	ld	ra,24(sp)
    80001370:	6442                	ld	s0,16(sp)
    80001372:	64a2                	ld	s1,8(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001378:	7179                	addi	sp,sp,-48
    8000137a:	f406                	sd	ra,40(sp)
    8000137c:	f022                	sd	s0,32(sp)
    8000137e:	ec26                	sd	s1,24(sp)
    80001380:	e84a                	sd	s2,16(sp)
    80001382:	e44e                	sd	s3,8(sp)
    80001384:	e052                	sd	s4,0(sp)
    80001386:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001388:	6785                	lui	a5,0x1
    8000138a:	04f67863          	bgeu	a2,a5,800013da <uvminit+0x62>
    8000138e:	8a2a                	mv	s4,a0
    80001390:	89ae                	mv	s3,a1
    80001392:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	782080e7          	jalr	1922(ra) # 80000b16 <kalloc>
    8000139c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	00000097          	auipc	ra,0x0
    800013a6:	960080e7          	jalr	-1696(ra) # 80000d02 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013aa:	4779                	li	a4,30
    800013ac:	86ca                	mv	a3,s2
    800013ae:	6605                	lui	a2,0x1
    800013b0:	4581                	li	a1,0
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	d1e080e7          	jalr	-738(ra) # 800010d2 <mappages>
  memmove(mem, src, sz);
    800013bc:	8626                	mv	a2,s1
    800013be:	85ce                	mv	a1,s3
    800013c0:	854a                	mv	a0,s2
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	99c080e7          	jalr	-1636(ra) # 80000d5e <memmove>
}
    800013ca:	70a2                	ld	ra,40(sp)
    800013cc:	7402                	ld	s0,32(sp)
    800013ce:	64e2                	ld	s1,24(sp)
    800013d0:	6942                	ld	s2,16(sp)
    800013d2:	69a2                	ld	s3,8(sp)
    800013d4:	6a02                	ld	s4,0(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret
    panic("inituvm: more than a page");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d6650513          	addi	a0,a0,-666 # 80008140 <digits+0x100>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	168080e7          	jalr	360(ra) # 8000054a <panic>

00000000800013ea <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013f4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f6:	00b67d63          	bgeu	a2,a1,80001410 <uvmdealloc+0x26>
    800013fa:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013fc:	6785                	lui	a5,0x1
    800013fe:	17fd                	addi	a5,a5,-1
    80001400:	00f60733          	add	a4,a2,a5
    80001404:	767d                	lui	a2,0xfffff
    80001406:	8f71                	and	a4,a4,a2
    80001408:	97ae                	add	a5,a5,a1
    8000140a:	8ff1                	and	a5,a5,a2
    8000140c:	00f76863          	bltu	a4,a5,8000141c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001410:	8526                	mv	a0,s1
    80001412:	60e2                	ld	ra,24(sp)
    80001414:	6442                	ld	s0,16(sp)
    80001416:	64a2                	ld	s1,8(sp)
    80001418:	6105                	addi	sp,sp,32
    8000141a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000141c:	8f99                	sub	a5,a5,a4
    8000141e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001420:	4685                	li	a3,1
    80001422:	0007861b          	sext.w	a2,a5
    80001426:	85ba                	mv	a1,a4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	e5e080e7          	jalr	-418(ra) # 80001286 <uvmunmap>
    80001430:	b7c5                	j	80001410 <uvmdealloc+0x26>

0000000080001432 <uvmalloc>:
  if(newsz < oldsz)
    80001432:	0ab66163          	bltu	a2,a1,800014d4 <uvmalloc+0xa2>
{
    80001436:	7139                	addi	sp,sp,-64
    80001438:	fc06                	sd	ra,56(sp)
    8000143a:	f822                	sd	s0,48(sp)
    8000143c:	f426                	sd	s1,40(sp)
    8000143e:	f04a                	sd	s2,32(sp)
    80001440:	ec4e                	sd	s3,24(sp)
    80001442:	e852                	sd	s4,16(sp)
    80001444:	e456                	sd	s5,8(sp)
    80001446:	0080                	addi	s0,sp,64
    80001448:	8aaa                	mv	s5,a0
    8000144a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000144c:	6985                	lui	s3,0x1
    8000144e:	19fd                	addi	s3,s3,-1
    80001450:	95ce                	add	a1,a1,s3
    80001452:	79fd                	lui	s3,0xfffff
    80001454:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001458:	08c9f063          	bgeu	s3,a2,800014d8 <uvmalloc+0xa6>
    8000145c:	894e                	mv	s2,s3
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	6b8080e7          	jalr	1720(ra) # 80000b16 <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	894080e7          	jalr	-1900(ra) # 80000d02 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001476:	4779                	li	a4,30
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c52080e7          	jalr	-942(ra) # 800010d2 <mappages>
    80001488:	e905                	bnez	a0,800014b8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x2c>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f4e080e7          	jalr	-178(ra) # 800013ea <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6121                	addi	sp,sp,64
    800014b6:	8082                	ret
      kfree(mem);
    800014b8:	8526                	mv	a0,s1
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	560080e7          	jalr	1376(ra) # 80000a1a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c2:	864e                	mv	a2,s3
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	f22080e7          	jalr	-222(ra) # 800013ea <uvmdealloc>
      return 0;
    800014d0:	4501                	li	a0,0
    800014d2:	bfd1                	j	800014a6 <uvmalloc+0x74>
    return oldsz;
    800014d4:	852e                	mv	a0,a1
}
    800014d6:	8082                	ret
  return newsz;
    800014d8:	8532                	mv	a0,a2
    800014da:	b7f1                	j	800014a6 <uvmalloc+0x74>

00000000800014dc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014dc:	7179                	addi	sp,sp,-48
    800014de:	f406                	sd	ra,40(sp)
    800014e0:	f022                	sd	s0,32(sp)
    800014e2:	ec26                	sd	s1,24(sp)
    800014e4:	e84a                	sd	s2,16(sp)
    800014e6:	e44e                	sd	s3,8(sp)
    800014e8:	e052                	sd	s4,0(sp)
    800014ea:	1800                	addi	s0,sp,48
    800014ec:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ee:	84aa                	mv	s1,a0
    800014f0:	6905                	lui	s2,0x1
    800014f2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f4:	4985                	li	s3,1
    800014f6:	a821                	j	8000150e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fa:	0532                	slli	a0,a0,0xc
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	fe0080e7          	jalr	-32(ra) # 800014dc <freewalk>
      pagetable[i] = 0;
    80001504:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001508:	04a1                	addi	s1,s1,8
    8000150a:	03248163          	beq	s1,s2,8000152c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000150e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001510:	00f57793          	andi	a5,a0,15
    80001514:	ff3782e3          	beq	a5,s3,800014f8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001518:	8905                	andi	a0,a0,1
    8000151a:	d57d                	beqz	a0,80001508 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151c:	00007517          	auipc	a0,0x7
    80001520:	c4450513          	addi	a0,a0,-956 # 80008160 <digits+0x120>
    80001524:	fffff097          	auipc	ra,0xfffff
    80001528:	026080e7          	jalr	38(ra) # 8000054a <panic>
    }
  }
  kfree((void*)pagetable);
    8000152c:	8552                	mv	a0,s4
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	4ec080e7          	jalr	1260(ra) # 80000a1a <kfree>
}
    80001536:	70a2                	ld	ra,40(sp)
    80001538:	7402                	ld	s0,32(sp)
    8000153a:	64e2                	ld	s1,24(sp)
    8000153c:	6942                	ld	s2,16(sp)
    8000153e:	69a2                	ld	s3,8(sp)
    80001540:	6a02                	ld	s4,0(sp)
    80001542:	6145                	addi	sp,sp,48
    80001544:	8082                	ret

0000000080001546 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001546:	1101                	addi	sp,sp,-32
    80001548:	ec06                	sd	ra,24(sp)
    8000154a:	e822                	sd	s0,16(sp)
    8000154c:	e426                	sd	s1,8(sp)
    8000154e:	1000                	addi	s0,sp,32
    80001550:	84aa                	mv	s1,a0
  if(sz > 0)
    80001552:	e999                	bnez	a1,80001568 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001554:	8526                	mv	a0,s1
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	f86080e7          	jalr	-122(ra) # 800014dc <freewalk>
}
    8000155e:	60e2                	ld	ra,24(sp)
    80001560:	6442                	ld	s0,16(sp)
    80001562:	64a2                	ld	s1,8(sp)
    80001564:	6105                	addi	sp,sp,32
    80001566:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001568:	6605                	lui	a2,0x1
    8000156a:	167d                	addi	a2,a2,-1
    8000156c:	962e                	add	a2,a2,a1
    8000156e:	4685                	li	a3,1
    80001570:	8231                	srli	a2,a2,0xc
    80001572:	4581                	li	a1,0
    80001574:	00000097          	auipc	ra,0x0
    80001578:	d12080e7          	jalr	-750(ra) # 80001286 <uvmunmap>
    8000157c:	bfe1                	j	80001554 <uvmfree+0xe>

000000008000157e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000157e:	c679                	beqz	a2,8000164c <uvmcopy+0xce>
{
    80001580:	715d                	addi	sp,sp,-80
    80001582:	e486                	sd	ra,72(sp)
    80001584:	e0a2                	sd	s0,64(sp)
    80001586:	fc26                	sd	s1,56(sp)
    80001588:	f84a                	sd	s2,48(sp)
    8000158a:	f44e                	sd	s3,40(sp)
    8000158c:	f052                	sd	s4,32(sp)
    8000158e:	ec56                	sd	s5,24(sp)
    80001590:	e85a                	sd	s6,16(sp)
    80001592:	e45e                	sd	s7,8(sp)
    80001594:	0880                	addi	s0,sp,80
    80001596:	8b2a                	mv	s6,a0
    80001598:	8aae                	mv	s5,a1
    8000159a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000159e:	4601                	li	a2,0
    800015a0:	85ce                	mv	a1,s3
    800015a2:	855a                	mv	a0,s6
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	a46080e7          	jalr	-1466(ra) # 80000fea <walk>
    800015ac:	c531                	beqz	a0,800015f8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ae:	6118                	ld	a4,0(a0)
    800015b0:	00177793          	andi	a5,a4,1
    800015b4:	cbb1                	beqz	a5,80001608 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b6:	00a75593          	srli	a1,a4,0xa
    800015ba:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015be:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	554080e7          	jalr	1364(ra) # 80000b16 <kalloc>
    800015ca:	892a                	mv	s2,a0
    800015cc:	c939                	beqz	a0,80001622 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85de                	mv	a1,s7
    800015d2:	fffff097          	auipc	ra,0xfffff
    800015d6:	78c080e7          	jalr	1932(ra) # 80000d5e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015da:	8726                	mv	a4,s1
    800015dc:	86ca                	mv	a3,s2
    800015de:	6605                	lui	a2,0x1
    800015e0:	85ce                	mv	a1,s3
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	aee080e7          	jalr	-1298(ra) # 800010d2 <mappages>
    800015ec:	e515                	bnez	a0,80001618 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ee:	6785                	lui	a5,0x1
    800015f0:	99be                	add	s3,s3,a5
    800015f2:	fb49e6e3          	bltu	s3,s4,8000159e <uvmcopy+0x20>
    800015f6:	a081                	j	80001636 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	b7850513          	addi	a0,a0,-1160 # 80008170 <digits+0x130>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f4a080e7          	jalr	-182(ra) # 8000054a <panic>
      panic("uvmcopy: page not present");
    80001608:	00007517          	auipc	a0,0x7
    8000160c:	b8850513          	addi	a0,a0,-1144 # 80008190 <digits+0x150>
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	f3a080e7          	jalr	-198(ra) # 8000054a <panic>
      kfree(mem);
    80001618:	854a                	mv	a0,s2
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	400080e7          	jalr	1024(ra) # 80000a1a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001622:	4685                	li	a3,1
    80001624:	00c9d613          	srli	a2,s3,0xc
    80001628:	4581                	li	a1,0
    8000162a:	8556                	mv	a0,s5
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	c5a080e7          	jalr	-934(ra) # 80001286 <uvmunmap>
  return -1;
    80001634:	557d                	li	a0,-1
}
    80001636:	60a6                	ld	ra,72(sp)
    80001638:	6406                	ld	s0,64(sp)
    8000163a:	74e2                	ld	s1,56(sp)
    8000163c:	7942                	ld	s2,48(sp)
    8000163e:	79a2                	ld	s3,40(sp)
    80001640:	7a02                	ld	s4,32(sp)
    80001642:	6ae2                	ld	s5,24(sp)
    80001644:	6b42                	ld	s6,16(sp)
    80001646:	6ba2                	ld	s7,8(sp)
    80001648:	6161                	addi	sp,sp,80
    8000164a:	8082                	ret
  return 0;
    8000164c:	4501                	li	a0,0
}
    8000164e:	8082                	ret

0000000080001650 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001650:	1141                	addi	sp,sp,-16
    80001652:	e406                	sd	ra,8(sp)
    80001654:	e022                	sd	s0,0(sp)
    80001656:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001658:	4601                	li	a2,0
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	990080e7          	jalr	-1648(ra) # 80000fea <walk>
  if(pte == 0)
    80001662:	c901                	beqz	a0,80001672 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001664:	611c                	ld	a5,0(a0)
    80001666:	9bbd                	andi	a5,a5,-17
    80001668:	e11c                	sd	a5,0(a0)
}
    8000166a:	60a2                	ld	ra,8(sp)
    8000166c:	6402                	ld	s0,0(sp)
    8000166e:	0141                	addi	sp,sp,16
    80001670:	8082                	ret
    panic("uvmclear");
    80001672:	00007517          	auipc	a0,0x7
    80001676:	b3e50513          	addi	a0,a0,-1218 # 800081b0 <digits+0x170>
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	ed0080e7          	jalr	-304(ra) # 8000054a <panic>

0000000080001682 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001682:	c6bd                	beqz	a3,800016f0 <copyout+0x6e>
{
    80001684:	715d                	addi	sp,sp,-80
    80001686:	e486                	sd	ra,72(sp)
    80001688:	e0a2                	sd	s0,64(sp)
    8000168a:	fc26                	sd	s1,56(sp)
    8000168c:	f84a                	sd	s2,48(sp)
    8000168e:	f44e                	sd	s3,40(sp)
    80001690:	f052                	sd	s4,32(sp)
    80001692:	ec56                	sd	s5,24(sp)
    80001694:	e85a                	sd	s6,16(sp)
    80001696:	e45e                	sd	s7,8(sp)
    80001698:	e062                	sd	s8,0(sp)
    8000169a:	0880                	addi	s0,sp,80
    8000169c:	8b2a                	mv	s6,a0
    8000169e:	8c2e                	mv	s8,a1
    800016a0:	8a32                	mv	s4,a2
    800016a2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a6:	6a85                	lui	s5,0x1
    800016a8:	a015                	j	800016cc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016aa:	9562                	add	a0,a0,s8
    800016ac:	0004861b          	sext.w	a2,s1
    800016b0:	85d2                	mv	a1,s4
    800016b2:	41250533          	sub	a0,a0,s2
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	6a8080e7          	jalr	1704(ra) # 80000d5e <memmove>

    len -= n;
    800016be:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c8:	02098263          	beqz	s3,800016ec <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016cc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d0:	85ca                	mv	a1,s2
    800016d2:	855a                	mv	a0,s6
    800016d4:	00000097          	auipc	ra,0x0
    800016d8:	9bc080e7          	jalr	-1604(ra) # 80001090 <walkaddr>
    if(pa0 == 0)
    800016dc:	cd01                	beqz	a0,800016f4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016de:	418904b3          	sub	s1,s2,s8
    800016e2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e4:	fc99f3e3          	bgeu	s3,s1,800016aa <copyout+0x28>
    800016e8:	84ce                	mv	s1,s3
    800016ea:	b7c1                	j	800016aa <copyout+0x28>
  }
  return 0;
    800016ec:	4501                	li	a0,0
    800016ee:	a021                	j	800016f6 <copyout+0x74>
    800016f0:	4501                	li	a0,0
}
    800016f2:	8082                	ret
      return -1;
    800016f4:	557d                	li	a0,-1
}
    800016f6:	60a6                	ld	ra,72(sp)
    800016f8:	6406                	ld	s0,64(sp)
    800016fa:	74e2                	ld	s1,56(sp)
    800016fc:	7942                	ld	s2,48(sp)
    800016fe:	79a2                	ld	s3,40(sp)
    80001700:	7a02                	ld	s4,32(sp)
    80001702:	6ae2                	ld	s5,24(sp)
    80001704:	6b42                	ld	s6,16(sp)
    80001706:	6ba2                	ld	s7,8(sp)
    80001708:	6c02                	ld	s8,0(sp)
    8000170a:	6161                	addi	sp,sp,80
    8000170c:	8082                	ret

000000008000170e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000170e:	caa5                	beqz	a3,8000177e <copyin+0x70>
{
    80001710:	715d                	addi	sp,sp,-80
    80001712:	e486                	sd	ra,72(sp)
    80001714:	e0a2                	sd	s0,64(sp)
    80001716:	fc26                	sd	s1,56(sp)
    80001718:	f84a                	sd	s2,48(sp)
    8000171a:	f44e                	sd	s3,40(sp)
    8000171c:	f052                	sd	s4,32(sp)
    8000171e:	ec56                	sd	s5,24(sp)
    80001720:	e85a                	sd	s6,16(sp)
    80001722:	e45e                	sd	s7,8(sp)
    80001724:	e062                	sd	s8,0(sp)
    80001726:	0880                	addi	s0,sp,80
    80001728:	8b2a                	mv	s6,a0
    8000172a:	8a2e                	mv	s4,a1
    8000172c:	8c32                	mv	s8,a2
    8000172e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001730:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001732:	6a85                	lui	s5,0x1
    80001734:	a01d                	j	8000175a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001736:	018505b3          	add	a1,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412585b3          	sub	a1,a1,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	61a080e7          	jalr	1562(ra) # 80000d5e <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	92e080e7          	jalr	-1746(ra) # 80001090 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f2e3          	bgeu	s3,s1,80001736 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	bf7d                	j	80001736 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x76>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	89c080e7          	jalr	-1892(ra) # 80001090 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ff98000>
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001850:	1101                	addi	sp,sp,-32
    80001852:	ec06                	sd	ra,24(sp)
    80001854:	e822                	sd	s0,16(sp)
    80001856:	e426                	sd	s1,8(sp)
    80001858:	1000                	addi	s0,sp,32
    8000185a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000185c:	fffff097          	auipc	ra,0xfffff
    80001860:	330080e7          	jalr	816(ra) # 80000b8c <holding>
    80001864:	c909                	beqz	a0,80001876 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001866:	749c                	ld	a5,40(s1)
    80001868:	00978f63          	beq	a5,s1,80001886 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000186c:	60e2                	ld	ra,24(sp)
    8000186e:	6442                	ld	s0,16(sp)
    80001870:	64a2                	ld	s1,8(sp)
    80001872:	6105                	addi	sp,sp,32
    80001874:	8082                	ret
    panic("wakeup1");
    80001876:	00007517          	auipc	a0,0x7
    8000187a:	94a50513          	addi	a0,a0,-1718 # 800081c0 <digits+0x180>
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	ccc080e7          	jalr	-820(ra) # 8000054a <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001886:	4c98                	lw	a4,24(s1)
    80001888:	4785                	li	a5,1
    8000188a:	fef711e3          	bne	a4,a5,8000186c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000188e:	4789                	li	a5,2
    80001890:	cc9c                	sw	a5,24(s1)
}
    80001892:	bfe9                	j	8000186c <wakeup1+0x1c>

0000000080001894 <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    80001894:	715d                	addi	sp,sp,-80
    80001896:	e486                	sd	ra,72(sp)
    80001898:	e0a2                	sd	s0,64(sp)
    8000189a:	fc26                	sd	s1,56(sp)
    8000189c:	f84a                	sd	s2,48(sp)
    8000189e:	f44e                	sd	s3,40(sp)
    800018a0:	f052                	sd	s4,32(sp)
    800018a2:	ec56                	sd	s5,24(sp)
    800018a4:	e85a                	sd	s6,16(sp)
    800018a6:	e45e                	sd	s7,8(sp)
    800018a8:	e062                	sd	s8,0(sp)
    800018aa:	0880                	addi	s0,sp,80
    800018ac:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ae:	00010497          	auipc	s1,0x10
    800018b2:	dfa48493          	addi	s1,s1,-518 # 800116a8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800018b6:	8c26                	mv	s8,s1
    800018b8:	00006b97          	auipc	s7,0x6
    800018bc:	748b8b93          	addi	s7,s7,1864 # 80008000 <etext>
    800018c0:	04000937          	lui	s2,0x4000
    800018c4:	197d                	addi	s2,s2,-1
    800018c6:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018c8:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ca:	1b8a0b13          	addi	s6,s4,440 # 11b8 <_entry-0x7fffee48>
    800018ce:	00057a97          	auipc	s5,0x57
    800018d2:	bdaa8a93          	addi	s5,s5,-1062 # 800584a8 <tickslock>
    char *pa = kalloc();
    800018d6:	fffff097          	auipc	ra,0xfffff
    800018da:	240080e7          	jalr	576(ra) # 80000b16 <kalloc>
    800018de:	862a                	mv	a2,a0
    if(pa == 0)
    800018e0:	c139                	beqz	a0,80001926 <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    800018e2:	418485b3          	sub	a1,s1,s8
    800018e6:	858d                	srai	a1,a1,0x3
    800018e8:	000bb783          	ld	a5,0(s7)
    800018ec:	02f585b3          	mul	a1,a1,a5
    800018f0:	2585                	addiw	a1,a1,1
    800018f2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018f6:	4719                	li	a4,6
    800018f8:	86d2                	mv	a3,s4
    800018fa:	40b905b3          	sub	a1,s2,a1
    800018fe:	854e                	mv	a0,s3
    80001900:	00000097          	auipc	ra,0x0
    80001904:	860080e7          	jalr	-1952(ra) # 80001160 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001908:	94da                	add	s1,s1,s6
    8000190a:	fd5496e3          	bne	s1,s5,800018d6 <proc_mapstacks+0x42>
}
    8000190e:	60a6                	ld	ra,72(sp)
    80001910:	6406                	ld	s0,64(sp)
    80001912:	74e2                	ld	s1,56(sp)
    80001914:	7942                	ld	s2,48(sp)
    80001916:	79a2                	ld	s3,40(sp)
    80001918:	7a02                	ld	s4,32(sp)
    8000191a:	6ae2                	ld	s5,24(sp)
    8000191c:	6b42                	ld	s6,16(sp)
    8000191e:	6ba2                	ld	s7,8(sp)
    80001920:	6c02                	ld	s8,0(sp)
    80001922:	6161                	addi	sp,sp,80
    80001924:	8082                	ret
      panic("kalloc");
    80001926:	00007517          	auipc	a0,0x7
    8000192a:	8a250513          	addi	a0,a0,-1886 # 800081c8 <digits+0x188>
    8000192e:	fffff097          	auipc	ra,0xfffff
    80001932:	c1c080e7          	jalr	-996(ra) # 8000054a <panic>

0000000080001936 <procinit>:
{
    80001936:	715d                	addi	sp,sp,-80
    80001938:	e486                	sd	ra,72(sp)
    8000193a:	e0a2                	sd	s0,64(sp)
    8000193c:	fc26                	sd	s1,56(sp)
    8000193e:	f84a                	sd	s2,48(sp)
    80001940:	f44e                	sd	s3,40(sp)
    80001942:	f052                	sd	s4,32(sp)
    80001944:	ec56                	sd	s5,24(sp)
    80001946:	e85a                	sd	s6,16(sp)
    80001948:	e45e                	sd	s7,8(sp)
    8000194a:	e062                	sd	s8,0(sp)
    8000194c:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000194e:	00007597          	auipc	a1,0x7
    80001952:	88258593          	addi	a1,a1,-1918 # 800081d0 <digits+0x190>
    80001956:	00010517          	auipc	a0,0x10
    8000195a:	93a50513          	addi	a0,a0,-1734 # 80011290 <pid_lock>
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	218080e7          	jalr	536(ra) # 80000b76 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001966:	00010497          	auipc	s1,0x10
    8000196a:	d4248493          	addi	s1,s1,-702 # 800116a8 <proc>
      initlock(&p->lock, "proc");
    8000196e:	00007c17          	auipc	s8,0x7
    80001972:	86ac0c13          	addi	s8,s8,-1942 # 800081d8 <digits+0x198>
      p->kstack = KSTACK((int) (p - proc));
    80001976:	6985                	lui	s3,0x1
    80001978:	09098b93          	addi	s7,s3,144 # 1090 <_entry-0x7fffef70>
    8000197c:	8b26                	mv	s6,s1
    8000197e:	00006a97          	auipc	s5,0x6
    80001982:	682a8a93          	addi	s5,s5,1666 # 80008000 <etext>
    80001986:	04000937          	lui	s2,0x4000
    8000198a:	197d                	addi	s2,s2,-1
    8000198c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	1b898993          	addi	s3,s3,440
    80001992:	00057a17          	auipc	s4,0x57
    80001996:	b16a0a13          	addi	s4,s4,-1258 # 800584a8 <tickslock>
      initlock(&p->lock, "proc");
    8000199a:	85e2                	mv	a1,s8
    8000199c:	8526                	mv	a0,s1
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	1d8080e7          	jalr	472(ra) # 80000b76 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019a6:	01748733          	add	a4,s1,s7
    800019aa:	416487b3          	sub	a5,s1,s6
    800019ae:	878d                	srai	a5,a5,0x3
    800019b0:	000ab683          	ld	a3,0(s5)
    800019b4:	02d787b3          	mul	a5,a5,a3
    800019b8:	2785                	addiw	a5,a5,1
    800019ba:	00d7979b          	slliw	a5,a5,0xd
    800019be:	40f907b3          	sub	a5,s2,a5
    800019c2:	e31c                	sd	a5,0(a4)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	94ce                	add	s1,s1,s3
    800019c6:	fd449ae3          	bne	s1,s4,8000199a <procinit+0x64>
}
    800019ca:	60a6                	ld	ra,72(sp)
    800019cc:	6406                	ld	s0,64(sp)
    800019ce:	74e2                	ld	s1,56(sp)
    800019d0:	7942                	ld	s2,48(sp)
    800019d2:	79a2                	ld	s3,40(sp)
    800019d4:	7a02                	ld	s4,32(sp)
    800019d6:	6ae2                	ld	s5,24(sp)
    800019d8:	6b42                	ld	s6,16(sp)
    800019da:	6ba2                	ld	s7,8(sp)
    800019dc:	6c02                	ld	s8,0(sp)
    800019de:	6161                	addi	sp,sp,80
    800019e0:	8082                	ret

00000000800019e2 <cpuid>:
{
    800019e2:	1141                	addi	sp,sp,-16
    800019e4:	e422                	sd	s0,8(sp)
    800019e6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e8:	8512                	mv	a0,tp
}
    800019ea:	2501                	sext.w	a0,a0
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <mycpu>:
mycpu(void) {
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e422                	sd	s0,8(sp)
    800019f6:	0800                	addi	s0,sp,16
    800019f8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019fa:	2781                	sext.w	a5,a5
    800019fc:	079e                	slli	a5,a5,0x7
}
    800019fe:	00010517          	auipc	a0,0x10
    80001a02:	8aa50513          	addi	a0,a0,-1878 # 800112a8 <cpus>
    80001a06:	953e                	add	a0,a0,a5
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <myproc>:
myproc(void) {
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
  push_off();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	1a2080e7          	jalr	418(ra) # 80000bba <push_off>
    80001a20:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
    80001a26:	00010717          	auipc	a4,0x10
    80001a2a:	86a70713          	addi	a4,a4,-1942 # 80011290 <pid_lock>
    80001a2e:	97ba                	add	a5,a5,a4
    80001a30:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	228080e7          	jalr	552(ra) # 80000c5a <pop_off>
}
    80001a3a:	8526                	mv	a0,s1
    80001a3c:	60e2                	ld	ra,24(sp)
    80001a3e:	6442                	ld	s0,16(sp)
    80001a40:	64a2                	ld	s1,8(sp)
    80001a42:	6105                	addi	sp,sp,32
    80001a44:	8082                	ret

0000000080001a46 <forkret>:
{
    80001a46:	1141                	addi	sp,sp,-16
    80001a48:	e406                	sd	ra,8(sp)
    80001a4a:	e022                	sd	s0,0(sp)
    80001a4c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	fc0080e7          	jalr	-64(ra) # 80001a0e <myproc>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	264080e7          	jalr	612(ra) # 80000cba <release>
  if (first) {
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	db27a783          	lw	a5,-590(a5) # 80008810 <first.1>
    80001a66:	eb89                	bnez	a5,80001a78 <forkret+0x32>
  usertrapret();
    80001a68:	00001097          	auipc	ra,0x1
    80001a6c:	cca080e7          	jalr	-822(ra) # 80002732 <usertrapret>
}
    80001a70:	60a2                	ld	ra,8(sp)
    80001a72:	6402                	ld	s0,0(sp)
    80001a74:	0141                	addi	sp,sp,16
    80001a76:	8082                	ret
    first = 0;
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	d807ac23          	sw	zero,-616(a5) # 80008810 <first.1>
    fsinit(ROOTDEV);
    80001a80:	4505                	li	a0,1
    80001a82:	00002097          	auipc	ra,0x2
    80001a86:	e86080e7          	jalr	-378(ra) # 80003908 <fsinit>
    80001a8a:	bff9                	j	80001a68 <forkret+0x22>

0000000080001a8c <allocpid>:
allocpid() {
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a98:	0000f917          	auipc	s2,0xf
    80001a9c:	7f890913          	addi	s2,s2,2040 # 80011290 <pid_lock>
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	164080e7          	jalr	356(ra) # 80000c06 <acquire>
  pid = nextpid;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	d6a78793          	addi	a5,a5,-662 # 80008814 <nextpid>
    80001ab2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ab4:	0014871b          	addiw	a4,s1,1
    80001ab8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	1fe080e7          	jalr	510(ra) # 80000cba <release>
}
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	60e2                	ld	ra,24(sp)
    80001ac8:	6442                	ld	s0,16(sp)
    80001aca:	64a2                	ld	s1,8(sp)
    80001acc:	6902                	ld	s2,0(sp)
    80001ace:	6105                	addi	sp,sp,32
    80001ad0:	8082                	ret

0000000080001ad2 <proc_pagetable>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	e04a                	sd	s2,0(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	86a080e7          	jalr	-1942(ra) # 8000134a <uvmcreate>
    80001ae8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aea:	c129                	beqz	a0,80001b2c <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aec:	4729                	li	a4,10
    80001aee:	00005697          	auipc	a3,0x5
    80001af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80001af6:	6605                	lui	a2,0x1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	5d2080e7          	jalr	1490(ra) # 800010d2 <mappages>
    80001b08:	02054963          	bltz	a0,80001b3a <proc_pagetable+0x68>
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    80001b0c:	6505                	lui	a0,0x1
    80001b0e:	954a                	add	a0,a0,s2
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b10:	4719                	li	a4,6
    80001b12:	7554                	ld	a3,168(a0)
    80001b14:	6605                	lui	a2,0x1
    80001b16:	020005b7          	lui	a1,0x2000
    80001b1a:	15fd                	addi	a1,a1,-1
    80001b1c:	05b6                	slli	a1,a1,0xd
    80001b1e:	8526                	mv	a0,s1
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	5b2080e7          	jalr	1458(ra) # 800010d2 <mappages>
    80001b28:	02054163          	bltz	a0,80001b4a <proc_pagetable+0x78>
}
    80001b2c:	8526                	mv	a0,s1
    80001b2e:	60e2                	ld	ra,24(sp)
    80001b30:	6442                	ld	s0,16(sp)
    80001b32:	64a2                	ld	s1,8(sp)
    80001b34:	6902                	ld	s2,0(sp)
    80001b36:	6105                	addi	sp,sp,32
    80001b38:	8082                	ret
    uvmfree(pagetable, 0);
    80001b3a:	4581                	li	a1,0
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	00000097          	auipc	ra,0x0
    80001b42:	a08080e7          	jalr	-1528(ra) # 80001546 <uvmfree>
    return 0;
    80001b46:	4481                	li	s1,0
    80001b48:	b7d5                	j	80001b2c <proc_pagetable+0x5a>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	040005b7          	lui	a1,0x4000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b2                	slli	a1,a1,0xc
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	72e080e7          	jalr	1838(ra) # 80001286 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b60:	4581                	li	a1,0
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e2080e7          	jalr	-1566(ra) # 80001546 <uvmfree>
    return 0;
    80001b6c:	4481                	li	s1,0
    80001b6e:	bf7d                	j	80001b2c <proc_pagetable+0x5a>

0000000080001b70 <proc_freepagetable>:
{
    80001b70:	1101                	addi	sp,sp,-32
    80001b72:	ec06                	sd	ra,24(sp)
    80001b74:	e822                	sd	s0,16(sp)
    80001b76:	e426                	sd	s1,8(sp)
    80001b78:	e04a                	sd	s2,0(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
    80001b7e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b80:	4681                	li	a3,0
    80001b82:	4605                	li	a2,1
    80001b84:	040005b7          	lui	a1,0x4000
    80001b88:	15fd                	addi	a1,a1,-1
    80001b8a:	05b2                	slli	a1,a1,0xc
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	6fa080e7          	jalr	1786(ra) # 80001286 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	020005b7          	lui	a1,0x2000
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05b6                	slli	a1,a1,0xd
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	6e4080e7          	jalr	1764(ra) # 80001286 <uvmunmap>
  uvmfree(pagetable, sz);
    80001baa:	85ca                	mv	a1,s2
    80001bac:	8526                	mv	a0,s1
    80001bae:	00000097          	auipc	ra,0x0
    80001bb2:	998080e7          	jalr	-1640(ra) # 80001546 <uvmfree>
}
    80001bb6:	60e2                	ld	ra,24(sp)
    80001bb8:	6442                	ld	s0,16(sp)
    80001bba:	64a2                	ld	s1,8(sp)
    80001bbc:	6902                	ld	s2,0(sp)
    80001bbe:	6105                	addi	sp,sp,32
    80001bc0:	8082                	ret

0000000080001bc2 <freeproc>:
{
    80001bc2:	1101                	addi	sp,sp,-32
    80001bc4:	ec06                	sd	ra,24(sp)
    80001bc6:	e822                	sd	s0,16(sp)
    80001bc8:	e426                	sd	s1,8(sp)
    80001bca:	1000                	addi	s0,sp,32
    80001bcc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bce:	6785                	lui	a5,0x1
    80001bd0:	97aa                	add	a5,a5,a0
    80001bd2:	77c8                	ld	a0,168(a5)
    80001bd4:	c509                	beqz	a0,80001bde <freeproc+0x1c>
    kfree((void*)p->trapframe);
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	e44080e7          	jalr	-444(ra) # 80000a1a <kfree>
  p->trapframe = 0;
    80001bde:	6785                	lui	a5,0x1
    80001be0:	97a6                	add	a5,a5,s1
    80001be2:	0a07b423          	sd	zero,168(a5) # 10a8 <_entry-0x7fffef58>
  if(p->pagetable)
    80001be6:	73c8                	ld	a0,160(a5)
    80001be8:	c901                	beqz	a0,80001bf8 <freeproc+0x36>
    proc_freepagetable(p->pagetable, p->sz);
    80001bea:	6785                	lui	a5,0x1
    80001bec:	97a6                	add	a5,a5,s1
    80001bee:	6fcc                	ld	a1,152(a5)
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	f80080e7          	jalr	-128(ra) # 80001b70 <proc_freepagetable>
  p->pagetable = 0;
    80001bf8:	6785                	lui	a5,0x1
    80001bfa:	97a6                	add	a5,a5,s1
    80001bfc:	0a07b023          	sd	zero,160(a5) # 10a0 <_entry-0x7fffef60>
  p->sz = 0;
    80001c00:	0807bc23          	sd	zero,152(a5)
  p->pid = 0;
    80001c04:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c08:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c0c:	1a078423          	sb	zero,424(a5)
  p->chan = 0;
    80001c10:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c14:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c18:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c1c:	0004ac23          	sw	zero,24(s1)
}
    80001c20:	60e2                	ld	ra,24(sp)
    80001c22:	6442                	ld	s0,16(sp)
    80001c24:	64a2                	ld	s1,8(sp)
    80001c26:	6105                	addi	sp,sp,32
    80001c28:	8082                	ret

0000000080001c2a <allocproc>:
{
    80001c2a:	7179                	addi	sp,sp,-48
    80001c2c:	f406                	sd	ra,40(sp)
    80001c2e:	f022                	sd	s0,32(sp)
    80001c30:	ec26                	sd	s1,24(sp)
    80001c32:	e84a                	sd	s2,16(sp)
    80001c34:	e44e                	sd	s3,8(sp)
    80001c36:	e052                	sd	s4,0(sp)
    80001c38:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3a:	00010497          	auipc	s1,0x10
    80001c3e:	a6e48493          	addi	s1,s1,-1426 # 800116a8 <proc>
    80001c42:	6985                	lui	s3,0x1
    80001c44:	1b898993          	addi	s3,s3,440 # 11b8 <_entry-0x7fffee48>
    80001c48:	00057a17          	auipc	s4,0x57
    80001c4c:	860a0a13          	addi	s4,s4,-1952 # 800584a8 <tickslock>
    acquire(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	fb4080e7          	jalr	-76(ra) # 80000c06 <acquire>
    if(p->state == UNUSED) {
    80001c5a:	4c9c                	lw	a5,24(s1)
    80001c5c:	cb99                	beqz	a5,80001c72 <allocproc+0x48>
      release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	05a080e7          	jalr	90(ra) # 80000cba <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	94ce                	add	s1,s1,s3
    80001c6a:	ff4493e3          	bne	s1,s4,80001c50 <allocproc+0x26>
  return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	a8bd                	j	80001cee <allocproc+0xc4>
  p->pid = allocpid();
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e1a080e7          	jalr	-486(ra) # 80001a8c <allocpid>
    80001c7a:	dc88                	sw	a0,56(s1)
  p->thrdstop_ticks = 0;
    80001c7c:	0204ae23          	sw	zero,60(s1)
  p->thrdstop_interval = -1;
    80001c80:	57fd                	li	a5,-1
    80001c82:	c0bc                	sw	a5,64(s1)
  for (i = 0; i < MAX_THRD_NUM; i++)
    80001c84:	6705                	lui	a4,0x1
    80001c86:	05070793          	addi	a5,a4,80 # 1050 <_entry-0x7fffefb0>
    80001c8a:	97a6                	add	a5,a5,s1
    80001c8c:	09070713          	addi	a4,a4,144
    80001c90:	00e48933          	add	s2,s1,a4
    p->thrdstop_context_used[i] = 0;
    80001c94:	0007a023          	sw	zero,0(a5)
  for (i = 0; i < MAX_THRD_NUM; i++)
    80001c98:	0791                	addi	a5,a5,4
    80001c9a:	ff279de3          	bne	a5,s2,80001c94 <allocproc+0x6a>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	e78080e7          	jalr	-392(ra) # 80000b16 <kalloc>
    80001ca6:	892a                	mv	s2,a0
    80001ca8:	6785                	lui	a5,0x1
    80001caa:	97a6                	add	a5,a5,s1
    80001cac:	f7c8                	sd	a0,168(a5)
    80001cae:	c929                	beqz	a0,80001d00 <allocproc+0xd6>
  p->pagetable = proc_pagetable(p);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	e20080e7          	jalr	-480(ra) # 80001ad2 <proc_pagetable>
    80001cba:	892a                	mv	s2,a0
    80001cbc:	6785                	lui	a5,0x1
    80001cbe:	97a6                	add	a5,a5,s1
    80001cc0:	f3c8                	sd	a0,160(a5)
  if(p->pagetable == 0){
    80001cc2:	c531                	beqz	a0,80001d0e <allocproc+0xe4>
  memset(&p->context, 0, sizeof(p->context));
    80001cc4:	6905                	lui	s2,0x1
    80001cc6:	0b090513          	addi	a0,s2,176 # 10b0 <_entry-0x7fffef50>
    80001cca:	07000613          	li	a2,112
    80001cce:	4581                	li	a1,0
    80001cd0:	9526                	add	a0,a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	030080e7          	jalr	48(ra) # 80000d02 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	012487b3          	add	a5,s1,s2
    80001cde:	00000717          	auipc	a4,0x0
    80001ce2:	d6870713          	addi	a4,a4,-664 # 80001a46 <forkret>
    80001ce6:	fbd8                	sd	a4,176(a5)
  p->context.sp = p->kstack + PGSIZE;
    80001ce8:	6bd8                	ld	a4,144(a5)
    80001cea:	974a                	add	a4,a4,s2
    80001cec:	ffd8                	sd	a4,184(a5)
}
    80001cee:	8526                	mv	a0,s1
    80001cf0:	70a2                	ld	ra,40(sp)
    80001cf2:	7402                	ld	s0,32(sp)
    80001cf4:	64e2                	ld	s1,24(sp)
    80001cf6:	6942                	ld	s2,16(sp)
    80001cf8:	69a2                	ld	s3,8(sp)
    80001cfa:	6a02                	ld	s4,0(sp)
    80001cfc:	6145                	addi	sp,sp,48
    80001cfe:	8082                	ret
    release(&p->lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	fb8080e7          	jalr	-72(ra) # 80000cba <release>
    return 0;
    80001d0a:	84ca                	mv	s1,s2
    80001d0c:	b7cd                	j	80001cee <allocproc+0xc4>
    freeproc(p);
    80001d0e:	8526                	mv	a0,s1
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	eb2080e7          	jalr	-334(ra) # 80001bc2 <freeproc>
    release(&p->lock);
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	fa0080e7          	jalr	-96(ra) # 80000cba <release>
    return 0;
    80001d22:	84ca                	mv	s1,s2
    80001d24:	b7e9                	j	80001cee <allocproc+0xc4>

0000000080001d26 <userinit>:
{
    80001d26:	7179                	addi	sp,sp,-48
    80001d28:	f406                	sd	ra,40(sp)
    80001d2a:	f022                	sd	s0,32(sp)
    80001d2c:	ec26                	sd	s1,24(sp)
    80001d2e:	e84a                	sd	s2,16(sp)
    80001d30:	e44e                	sd	s3,8(sp)
    80001d32:	1800                	addi	s0,sp,48
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	ef6080e7          	jalr	-266(ra) # 80001c2a <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	2ca7bd23          	sd	a0,730(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d46:	6905                	lui	s2,0x1
    80001d48:	012509b3          	add	s3,a0,s2
    80001d4c:	03400613          	li	a2,52
    80001d50:	00007597          	auipc	a1,0x7
    80001d54:	ad058593          	addi	a1,a1,-1328 # 80008820 <initcode>
    80001d58:	0a09b503          	ld	a0,160(s3)
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	61c080e7          	jalr	1564(ra) # 80001378 <uvminit>
  p->sz = PGSIZE;
    80001d64:	0929bc23          	sd	s2,152(s3)
  p->trapframe->epc = 0;      // user program counter
    80001d68:	0a89b783          	ld	a5,168(s3)
    80001d6c:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d70:	0a89b783          	ld	a5,168(s3)
    80001d74:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d78:	1a890513          	addi	a0,s2,424 # 11a8 <_entry-0x7fffee58>
    80001d7c:	4641                	li	a2,16
    80001d7e:	00006597          	auipc	a1,0x6
    80001d82:	46258593          	addi	a1,a1,1122 # 800081e0 <digits+0x1a0>
    80001d86:	9526                	add	a0,a0,s1
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	0cc080e7          	jalr	204(ra) # 80000e54 <safestrcpy>
  p->cwd = namei("/");
    80001d90:	00006517          	auipc	a0,0x6
    80001d94:	46050513          	addi	a0,a0,1120 # 800081f0 <digits+0x1b0>
    80001d98:	00002097          	auipc	ra,0x2
    80001d9c:	5a0080e7          	jalr	1440(ra) # 80004338 <namei>
    80001da0:	1aa9b023          	sd	a0,416(s3)
  p->state = RUNNABLE;
    80001da4:	4789                	li	a5,2
    80001da6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da8:	8526                	mv	a0,s1
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	f10080e7          	jalr	-240(ra) # 80000cba <release>
}
    80001db2:	70a2                	ld	ra,40(sp)
    80001db4:	7402                	ld	s0,32(sp)
    80001db6:	64e2                	ld	s1,24(sp)
    80001db8:	6942                	ld	s2,16(sp)
    80001dba:	69a2                	ld	s3,8(sp)
    80001dbc:	6145                	addi	sp,sp,48
    80001dbe:	8082                	ret

0000000080001dc0 <growproc>:
{
    80001dc0:	1101                	addi	sp,sp,-32
    80001dc2:	ec06                	sd	ra,24(sp)
    80001dc4:	e822                	sd	s0,16(sp)
    80001dc6:	e426                	sd	s1,8(sp)
    80001dc8:	e04a                	sd	s2,0(sp)
    80001dca:	1000                	addi	s0,sp,32
    80001dcc:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	c40080e7          	jalr	-960(ra) # 80001a0e <myproc>
    80001dd6:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dd8:	6785                	lui	a5,0x1
    80001dda:	97aa                	add	a5,a5,a0
    80001ddc:	6fcc                	ld	a1,152(a5)
    80001dde:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001de2:	03204063          	bgtz	s2,80001e02 <growproc+0x42>
  } else if(n < 0){
    80001de6:	04094063          	bltz	s2,80001e26 <growproc+0x66>
  p->sz = sz;
    80001dea:	6505                	lui	a0,0x1
    80001dec:	94aa                	add	s1,s1,a0
    80001dee:	1602                	slli	a2,a2,0x20
    80001df0:	9201                	srli	a2,a2,0x20
    80001df2:	ecd0                	sd	a2,152(s1)
  return 0;
    80001df4:	4501                	li	a0,0
}
    80001df6:	60e2                	ld	ra,24(sp)
    80001df8:	6442                	ld	s0,16(sp)
    80001dfa:	64a2                	ld	s1,8(sp)
    80001dfc:	6902                	ld	s2,0(sp)
    80001dfe:	6105                	addi	sp,sp,32
    80001e00:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e02:	00c9063b          	addw	a2,s2,a2
    80001e06:	6785                	lui	a5,0x1
    80001e08:	97aa                	add	a5,a5,a0
    80001e0a:	1602                	slli	a2,a2,0x20
    80001e0c:	9201                	srli	a2,a2,0x20
    80001e0e:	1582                	slli	a1,a1,0x20
    80001e10:	9181                	srli	a1,a1,0x20
    80001e12:	73c8                	ld	a0,160(a5)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	61e080e7          	jalr	1566(ra) # 80001432 <uvmalloc>
    80001e1c:	0005061b          	sext.w	a2,a0
    80001e20:	f669                	bnez	a2,80001dea <growproc+0x2a>
      return -1;
    80001e22:	557d                	li	a0,-1
    80001e24:	bfc9                	j	80001df6 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e26:	00c9063b          	addw	a2,s2,a2
    80001e2a:	6785                	lui	a5,0x1
    80001e2c:	97aa                	add	a5,a5,a0
    80001e2e:	1602                	slli	a2,a2,0x20
    80001e30:	9201                	srli	a2,a2,0x20
    80001e32:	1582                	slli	a1,a1,0x20
    80001e34:	9181                	srli	a1,a1,0x20
    80001e36:	73c8                	ld	a0,160(a5)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	5b2080e7          	jalr	1458(ra) # 800013ea <uvmdealloc>
    80001e40:	0005061b          	sext.w	a2,a0
    80001e44:	b75d                	j	80001dea <growproc+0x2a>

0000000080001e46 <fork>:
{
    80001e46:	7139                	addi	sp,sp,-64
    80001e48:	fc06                	sd	ra,56(sp)
    80001e4a:	f822                	sd	s0,48(sp)
    80001e4c:	f426                	sd	s1,40(sp)
    80001e4e:	f04a                	sd	s2,32(sp)
    80001e50:	ec4e                	sd	s3,24(sp)
    80001e52:	e852                	sd	s4,16(sp)
    80001e54:	e456                	sd	s5,8(sp)
    80001e56:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	bb6080e7          	jalr	-1098(ra) # 80001a0e <myproc>
    80001e60:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	dc8080e7          	jalr	-568(ra) # 80001c2a <allocproc>
    80001e6a:	10050063          	beqz	a0,80001f6a <fork+0x124>
    80001e6e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e70:	6785                	lui	a5,0x1
    80001e72:	00fa8733          	add	a4,s5,a5
    80001e76:	97aa                	add	a5,a5,a0
    80001e78:	6f50                	ld	a2,152(a4)
    80001e7a:	73cc                	ld	a1,160(a5)
    80001e7c:	7348                	ld	a0,160(a4)
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	700080e7          	jalr	1792(ra) # 8000157e <uvmcopy>
    80001e86:	04054e63          	bltz	a0,80001ee2 <fork+0x9c>
  np->sz = p->sz;
    80001e8a:	6705                	lui	a4,0x1
    80001e8c:	00ea87b3          	add	a5,s5,a4
    80001e90:	6fd4                	ld	a3,152(a5)
    80001e92:	9752                	add	a4,a4,s4
    80001e94:	ef54                	sd	a3,152(a4)
  np->parent = p;
    80001e96:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e9a:	77d4                	ld	a3,168(a5)
    80001e9c:	87b6                	mv	a5,a3
    80001e9e:	7758                	ld	a4,168(a4)
    80001ea0:	12068693          	addi	a3,a3,288
    80001ea4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ea8:	6788                	ld	a0,8(a5)
    80001eaa:	6b8c                	ld	a1,16(a5)
    80001eac:	6f90                	ld	a2,24(a5)
    80001eae:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001eb2:	e708                	sd	a0,8(a4)
    80001eb4:	eb0c                	sd	a1,16(a4)
    80001eb6:	ef10                	sd	a2,24(a4)
    80001eb8:	02078793          	addi	a5,a5,32
    80001ebc:	02070713          	addi	a4,a4,32
    80001ec0:	fed792e3          	bne	a5,a3,80001ea4 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001ec4:	6985                	lui	s3,0x1
    80001ec6:	013a07b3          	add	a5,s4,s3
    80001eca:	77dc                	ld	a5,168(a5)
    80001ecc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed0:	12098913          	addi	s2,s3,288 # 1120 <_entry-0x7fffeee0>
    80001ed4:	012a84b3          	add	s1,s5,s2
    80001ed8:	9952                	add	s2,s2,s4
    80001eda:	1a098993          	addi	s3,s3,416
    80001ede:	99d6                	add	s3,s3,s5
    80001ee0:	a00d                	j	80001f02 <fork+0xbc>
    freeproc(np);
    80001ee2:	8552                	mv	a0,s4
    80001ee4:	00000097          	auipc	ra,0x0
    80001ee8:	cde080e7          	jalr	-802(ra) # 80001bc2 <freeproc>
    release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	dcc080e7          	jalr	-564(ra) # 80000cba <release>
    return -1;
    80001ef6:	54fd                	li	s1,-1
    80001ef8:	a8b9                	j	80001f56 <fork+0x110>
  for(i = 0; i < NOFILE; i++)
    80001efa:	04a1                	addi	s1,s1,8
    80001efc:	0921                	addi	s2,s2,8
    80001efe:	01348b63          	beq	s1,s3,80001f14 <fork+0xce>
    if(p->ofile[i])
    80001f02:	6088                	ld	a0,0(s1)
    80001f04:	d97d                	beqz	a0,80001efa <fork+0xb4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f06:	00003097          	auipc	ra,0x3
    80001f0a:	ad0080e7          	jalr	-1328(ra) # 800049d6 <filedup>
    80001f0e:	00a93023          	sd	a0,0(s2)
    80001f12:	b7e5                	j	80001efa <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001f14:	6485                	lui	s1,0x1
    80001f16:	009a87b3          	add	a5,s5,s1
    80001f1a:	1a07b503          	ld	a0,416(a5)
    80001f1e:	00002097          	auipc	ra,0x2
    80001f22:	c24080e7          	jalr	-988(ra) # 80003b42 <idup>
    80001f26:	009a07b3          	add	a5,s4,s1
    80001f2a:	1aa7b023          	sd	a0,416(a5)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f2e:	1a848513          	addi	a0,s1,424 # 11a8 <_entry-0x7fffee58>
    80001f32:	4641                	li	a2,16
    80001f34:	00aa85b3          	add	a1,s5,a0
    80001f38:	9552                	add	a0,a0,s4
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	f1a080e7          	jalr	-230(ra) # 80000e54 <safestrcpy>
  pid = np->pid;
    80001f42:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001f46:	4789                	li	a5,2
    80001f48:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f4c:	8552                	mv	a0,s4
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	d6c080e7          	jalr	-660(ra) # 80000cba <release>
}
    80001f56:	8526                	mv	a0,s1
    80001f58:	70e2                	ld	ra,56(sp)
    80001f5a:	7442                	ld	s0,48(sp)
    80001f5c:	74a2                	ld	s1,40(sp)
    80001f5e:	7902                	ld	s2,32(sp)
    80001f60:	69e2                	ld	s3,24(sp)
    80001f62:	6a42                	ld	s4,16(sp)
    80001f64:	6aa2                	ld	s5,8(sp)
    80001f66:	6121                	addi	sp,sp,64
    80001f68:	8082                	ret
    return -1;
    80001f6a:	54fd                	li	s1,-1
    80001f6c:	b7ed                	j	80001f56 <fork+0x110>

0000000080001f6e <reparent>:
{
    80001f6e:	7139                	addi	sp,sp,-64
    80001f70:	fc06                	sd	ra,56(sp)
    80001f72:	f822                	sd	s0,48(sp)
    80001f74:	f426                	sd	s1,40(sp)
    80001f76:	f04a                	sd	s2,32(sp)
    80001f78:	ec4e                	sd	s3,24(sp)
    80001f7a:	e852                	sd	s4,16(sp)
    80001f7c:	e456                	sd	s5,8(sp)
    80001f7e:	0080                	addi	s0,sp,64
    80001f80:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f82:	0000f497          	auipc	s1,0xf
    80001f86:	72648493          	addi	s1,s1,1830 # 800116a8 <proc>
      pp->parent = initproc;
    80001f8a:	00007a97          	auipc	s5,0x7
    80001f8e:	08ea8a93          	addi	s5,s5,142 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f92:	6905                	lui	s2,0x1
    80001f94:	1b890913          	addi	s2,s2,440 # 11b8 <_entry-0x7fffee48>
    80001f98:	00056a17          	auipc	s4,0x56
    80001f9c:	510a0a13          	addi	s4,s4,1296 # 800584a8 <tickslock>
    80001fa0:	a021                	j	80001fa8 <reparent+0x3a>
    80001fa2:	94ca                	add	s1,s1,s2
    80001fa4:	03448363          	beq	s1,s4,80001fca <reparent+0x5c>
    if(pp->parent == p){
    80001fa8:	709c                	ld	a5,32(s1)
    80001faa:	ff379ce3          	bne	a5,s3,80001fa2 <reparent+0x34>
      acquire(&pp->lock);
    80001fae:	8526                	mv	a0,s1
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	c56080e7          	jalr	-938(ra) # 80000c06 <acquire>
      pp->parent = initproc;
    80001fb8:	000ab783          	ld	a5,0(s5)
    80001fbc:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cfa080e7          	jalr	-774(ra) # 80000cba <release>
    80001fc8:	bfe9                	j	80001fa2 <reparent+0x34>
}
    80001fca:	70e2                	ld	ra,56(sp)
    80001fcc:	7442                	ld	s0,48(sp)
    80001fce:	74a2                	ld	s1,40(sp)
    80001fd0:	7902                	ld	s2,32(sp)
    80001fd2:	69e2                	ld	s3,24(sp)
    80001fd4:	6a42                	ld	s4,16(sp)
    80001fd6:	6aa2                	ld	s5,8(sp)
    80001fd8:	6121                	addi	sp,sp,64
    80001fda:	8082                	ret

0000000080001fdc <scheduler>:
{
    80001fdc:	715d                	addi	sp,sp,-80
    80001fde:	e486                	sd	ra,72(sp)
    80001fe0:	e0a2                	sd	s0,64(sp)
    80001fe2:	fc26                	sd	s1,56(sp)
    80001fe4:	f84a                	sd	s2,48(sp)
    80001fe6:	f44e                	sd	s3,40(sp)
    80001fe8:	f052                	sd	s4,32(sp)
    80001fea:	ec56                	sd	s5,24(sp)
    80001fec:	e85a                	sd	s6,16(sp)
    80001fee:	e45e                	sd	s7,8(sp)
    80001ff0:	0880                	addi	s0,sp,80
    80001ff2:	8792                	mv	a5,tp
  int id = r_tp();
    80001ff4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ff6:	00779b13          	slli	s6,a5,0x7
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	29670713          	addi	a4,a4,662 # 80011290 <pid_lock>
    80002002:	975a                	add	a4,a4,s6
    80002004:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002008:	0000f717          	auipc	a4,0xf
    8000200c:	2a870713          	addi	a4,a4,680 # 800112b0 <cpus+0x8>
    80002010:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002012:	079e                	slli	a5,a5,0x7
    80002014:	0000fa97          	auipc	s5,0xf
    80002018:	27ca8a93          	addi	s5,s5,636 # 80011290 <pid_lock>
    8000201c:	9abe                	add	s5,s5,a5
        swtch(&c->context, &p->context);
    8000201e:	6a05                	lui	s4,0x1
    80002020:	0b0a0b93          	addi	s7,s4,176 # 10b0 <_entry-0x7fffef50>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002024:	1b8a0a13          	addi	s4,s4,440
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002028:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002030:	10079073          	csrw	sstatus,a5
    80002034:	0000f497          	auipc	s1,0xf
    80002038:	67448493          	addi	s1,s1,1652 # 800116a8 <proc>
      if(p->state == RUNNABLE) {
    8000203c:	4989                	li	s3,2
    for(p = proc; p < &proc[NPROC]; p++) {
    8000203e:	00056917          	auipc	s2,0x56
    80002042:	46a90913          	addi	s2,s2,1130 # 800584a8 <tickslock>
    80002046:	a809                	j	80002058 <scheduler+0x7c>
      release(&p->lock);
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	c70080e7          	jalr	-912(ra) # 80000cba <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002052:	94d2                	add	s1,s1,s4
    80002054:	fd248ae3          	beq	s1,s2,80002028 <scheduler+0x4c>
      acquire(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	bac080e7          	jalr	-1108(ra) # 80000c06 <acquire>
      if(p->state == RUNNABLE) {
    80002062:	4c9c                	lw	a5,24(s1)
    80002064:	ff3792e3          	bne	a5,s3,80002048 <scheduler+0x6c>
        p->state = RUNNING;
    80002068:	478d                	li	a5,3
    8000206a:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    8000206c:	009abc23          	sd	s1,24(s5)
        swtch(&c->context, &p->context);
    80002070:	017485b3          	add	a1,s1,s7
    80002074:	855a                	mv	a0,s6
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	612080e7          	jalr	1554(ra) # 80002688 <swtch>
        c->proc = 0;
    8000207e:	000abc23          	sd	zero,24(s5)
    80002082:	b7d9                	j	80002048 <scheduler+0x6c>

0000000080002084 <sched>:
{
    80002084:	7179                	addi	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	97c080e7          	jalr	-1668(ra) # 80001a0e <myproc>
    8000209a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	af0080e7          	jalr	-1296(ra) # 80000b8c <holding>
    800020a4:	cd2d                	beqz	a0,8000211e <sched+0x9a>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	0000f717          	auipc	a4,0xf
    800020b0:	1e470713          	addi	a4,a4,484 # 80011290 <pid_lock>
    800020b4:	97ba                	add	a5,a5,a4
    800020b6:	0907a703          	lw	a4,144(a5)
    800020ba:	4785                	li	a5,1
    800020bc:	06f71963          	bne	a4,a5,8000212e <sched+0xaa>
  if(p->state == RUNNING)
    800020c0:	4c98                	lw	a4,24(s1)
    800020c2:	478d                	li	a5,3
    800020c4:	06f70d63          	beq	a4,a5,8000213e <sched+0xba>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020cc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020ce:	e3c1                	bnez	a5,8000214e <sched+0xca>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020d2:	0000f917          	auipc	s2,0xf
    800020d6:	1be90913          	addi	s2,s2,446 # 80011290 <pid_lock>
    800020da:	2781                	sext.w	a5,a5
    800020dc:	079e                	slli	a5,a5,0x7
    800020de:	97ca                	add	a5,a5,s2
    800020e0:	0947a983          	lw	s3,148(a5)
    800020e4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020e6:	2781                	sext.w	a5,a5
    800020e8:	079e                	slli	a5,a5,0x7
    800020ea:	0000f597          	auipc	a1,0xf
    800020ee:	1c658593          	addi	a1,a1,454 # 800112b0 <cpus+0x8>
    800020f2:	95be                	add	a1,a1,a5
    800020f4:	6505                	lui	a0,0x1
    800020f6:	0b050513          	addi	a0,a0,176 # 10b0 <_entry-0x7fffef50>
    800020fa:	9526                	add	a0,a0,s1
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	58c080e7          	jalr	1420(ra) # 80002688 <swtch>
    80002104:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002106:	2781                	sext.w	a5,a5
    80002108:	079e                	slli	a5,a5,0x7
    8000210a:	97ca                	add	a5,a5,s2
    8000210c:	0937aa23          	sw	s3,148(a5)
}
    80002110:	70a2                	ld	ra,40(sp)
    80002112:	7402                	ld	s0,32(sp)
    80002114:	64e2                	ld	s1,24(sp)
    80002116:	6942                	ld	s2,16(sp)
    80002118:	69a2                	ld	s3,8(sp)
    8000211a:	6145                	addi	sp,sp,48
    8000211c:	8082                	ret
    panic("sched p->lock");
    8000211e:	00006517          	auipc	a0,0x6
    80002122:	0da50513          	addi	a0,a0,218 # 800081f8 <digits+0x1b8>
    80002126:	ffffe097          	auipc	ra,0xffffe
    8000212a:	424080e7          	jalr	1060(ra) # 8000054a <panic>
    panic("sched locks");
    8000212e:	00006517          	auipc	a0,0x6
    80002132:	0da50513          	addi	a0,a0,218 # 80008208 <digits+0x1c8>
    80002136:	ffffe097          	auipc	ra,0xffffe
    8000213a:	414080e7          	jalr	1044(ra) # 8000054a <panic>
    panic("sched running");
    8000213e:	00006517          	auipc	a0,0x6
    80002142:	0da50513          	addi	a0,a0,218 # 80008218 <digits+0x1d8>
    80002146:	ffffe097          	auipc	ra,0xffffe
    8000214a:	404080e7          	jalr	1028(ra) # 8000054a <panic>
    panic("sched interruptible");
    8000214e:	00006517          	auipc	a0,0x6
    80002152:	0da50513          	addi	a0,a0,218 # 80008228 <digits+0x1e8>
    80002156:	ffffe097          	auipc	ra,0xffffe
    8000215a:	3f4080e7          	jalr	1012(ra) # 8000054a <panic>

000000008000215e <exit>:
{
    8000215e:	7179                	addi	sp,sp,-48
    80002160:	f406                	sd	ra,40(sp)
    80002162:	f022                	sd	s0,32(sp)
    80002164:	ec26                	sd	s1,24(sp)
    80002166:	e84a                	sd	s2,16(sp)
    80002168:	e44e                	sd	s3,8(sp)
    8000216a:	e052                	sd	s4,0(sp)
    8000216c:	1800                	addi	s0,sp,48
    8000216e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002170:	00000097          	auipc	ra,0x0
    80002174:	89e080e7          	jalr	-1890(ra) # 80001a0e <myproc>
  if(p == initproc)
    80002178:	00007797          	auipc	a5,0x7
    8000217c:	ea07b783          	ld	a5,-352(a5) # 80009018 <initproc>
    80002180:	00a78b63          	beq	a5,a0,80002196 <exit+0x38>
    80002184:	89aa                	mv	s3,a0
    80002186:	6905                	lui	s2,0x1
    80002188:	12090493          	addi	s1,s2,288 # 1120 <_entry-0x7fffeee0>
    8000218c:	94aa                	add	s1,s1,a0
    8000218e:	1a090913          	addi	s2,s2,416
    80002192:	992a                	add	s2,s2,a0
    80002194:	a015                	j	800021b8 <exit+0x5a>
    panic("init exiting");
    80002196:	00006517          	auipc	a0,0x6
    8000219a:	0aa50513          	addi	a0,a0,170 # 80008240 <digits+0x200>
    8000219e:	ffffe097          	auipc	ra,0xffffe
    800021a2:	3ac080e7          	jalr	940(ra) # 8000054a <panic>
      fileclose(f);
    800021a6:	00003097          	auipc	ra,0x3
    800021aa:	882080e7          	jalr	-1918(ra) # 80004a28 <fileclose>
      p->ofile[fd] = 0;
    800021ae:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021b2:	04a1                	addi	s1,s1,8
    800021b4:	01248563          	beq	s1,s2,800021be <exit+0x60>
    if(p->ofile[fd]){
    800021b8:	6088                	ld	a0,0(s1)
    800021ba:	f575                	bnez	a0,800021a6 <exit+0x48>
    800021bc:	bfdd                	j	800021b2 <exit+0x54>
  begin_op();
    800021be:	00002097          	auipc	ra,0x2
    800021c2:	396080e7          	jalr	918(ra) # 80004554 <begin_op>
  iput(p->cwd);
    800021c6:	6485                	lui	s1,0x1
    800021c8:	94ce                	add	s1,s1,s3
    800021ca:	1a04b503          	ld	a0,416(s1) # 11a0 <_entry-0x7fffee60>
    800021ce:	00002097          	auipc	ra,0x2
    800021d2:	b6c080e7          	jalr	-1172(ra) # 80003d3a <iput>
  end_op();
    800021d6:	00002097          	auipc	ra,0x2
    800021da:	3fe080e7          	jalr	1022(ra) # 800045d4 <end_op>
  p->cwd = 0;
    800021de:	1a04b023          	sd	zero,416(s1)
  acquire(&initproc->lock);
    800021e2:	00007497          	auipc	s1,0x7
    800021e6:	e3648493          	addi	s1,s1,-458 # 80009018 <initproc>
    800021ea:	6088                	ld	a0,0(s1)
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	a1a080e7          	jalr	-1510(ra) # 80000c06 <acquire>
  wakeup1(initproc);
    800021f4:	6088                	ld	a0,0(s1)
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	65a080e7          	jalr	1626(ra) # 80001850 <wakeup1>
  release(&initproc->lock);
    800021fe:	6088                	ld	a0,0(s1)
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	aba080e7          	jalr	-1350(ra) # 80000cba <release>
  acquire(&p->lock);
    80002208:	854e                	mv	a0,s3
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9fc080e7          	jalr	-1540(ra) # 80000c06 <acquire>
  struct proc *original_parent = p->parent;
    80002212:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002216:	854e                	mv	a0,s3
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	aa2080e7          	jalr	-1374(ra) # 80000cba <release>
  acquire(&original_parent->lock);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9e4080e7          	jalr	-1564(ra) # 80000c06 <acquire>
  acquire(&p->lock);
    8000222a:	854e                	mv	a0,s3
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	9da080e7          	jalr	-1574(ra) # 80000c06 <acquire>
  reparent(p);
    80002234:	854e                	mv	a0,s3
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	d38080e7          	jalr	-712(ra) # 80001f6e <reparent>
  wakeup1(original_parent);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	610080e7          	jalr	1552(ra) # 80001850 <wakeup1>
  p->xstate = status;
    80002248:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000224c:	4791                	li	a5,4
    8000224e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a66080e7          	jalr	-1434(ra) # 80000cba <release>
  sched();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	e28080e7          	jalr	-472(ra) # 80002084 <sched>
  panic("zombie exit");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	fec50513          	addi	a0,a0,-20 # 80008250 <digits+0x210>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2de080e7          	jalr	734(ra) # 8000054a <panic>

0000000080002274 <yield>:
{
    80002274:	1101                	addi	sp,sp,-32
    80002276:	ec06                	sd	ra,24(sp)
    80002278:	e822                	sd	s0,16(sp)
    8000227a:	e426                	sd	s1,8(sp)
    8000227c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	790080e7          	jalr	1936(ra) # 80001a0e <myproc>
    80002286:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	97e080e7          	jalr	-1666(ra) # 80000c06 <acquire>
  p->state = RUNNABLE;
    80002290:	4789                	li	a5,2
    80002292:	cc9c                	sw	a5,24(s1)
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	df0080e7          	jalr	-528(ra) # 80002084 <sched>
  release(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	a1c080e7          	jalr	-1508(ra) # 80000cba <release>
}
    800022a6:	60e2                	ld	ra,24(sp)
    800022a8:	6442                	ld	s0,16(sp)
    800022aa:	64a2                	ld	s1,8(sp)
    800022ac:	6105                	addi	sp,sp,32
    800022ae:	8082                	ret

00000000800022b0 <sleep>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	89aa                	mv	s3,a0
    800022c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	74c080e7          	jalr	1868(ra) # 80001a0e <myproc>
    800022ca:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022cc:	05250663          	beq	a0,s2,80002318 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	936080e7          	jalr	-1738(ra) # 80000c06 <acquire>
    release(lk);
    800022d8:	854a                	mv	a0,s2
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9e0080e7          	jalr	-1568(ra) # 80000cba <release>
  p->chan = chan;
    800022e2:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022e6:	4785                	li	a5,1
    800022e8:	cc9c                	sw	a5,24(s1)
  sched();
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	d9a080e7          	jalr	-614(ra) # 80002084 <sched>
  p->chan = 0;
    800022f2:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9c2080e7          	jalr	-1598(ra) # 80000cba <release>
    acquire(lk);
    80002300:	854a                	mv	a0,s2
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	904080e7          	jalr	-1788(ra) # 80000c06 <acquire>
}
    8000230a:	70a2                	ld	ra,40(sp)
    8000230c:	7402                	ld	s0,32(sp)
    8000230e:	64e2                	ld	s1,24(sp)
    80002310:	6942                	ld	s2,16(sp)
    80002312:	69a2                	ld	s3,8(sp)
    80002314:	6145                	addi	sp,sp,48
    80002316:	8082                	ret
  p->chan = chan;
    80002318:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000231c:	4785                	li	a5,1
    8000231e:	cd1c                	sw	a5,24(a0)
  sched();
    80002320:	00000097          	auipc	ra,0x0
    80002324:	d64080e7          	jalr	-668(ra) # 80002084 <sched>
  p->chan = 0;
    80002328:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000232c:	bff9                	j	8000230a <sleep+0x5a>

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
    80002342:	0880                	addi	s0,sp,80
    80002344:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	6c8080e7          	jalr	1736(ra) # 80001a0e <myproc>
    8000234e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	8b6080e7          	jalr	-1866(ra) # 80000c06 <acquire>
        if(np->state == ZOMBIE){
    80002358:	4a91                	li	s5,4
        havekids = 1;
    8000235a:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000235c:	6985                	lui	s3,0x1
    8000235e:	1b898993          	addi	s3,s3,440 # 11b8 <_entry-0x7fffee48>
    80002362:	00056a17          	auipc	s4,0x56
    80002366:	146a0a13          	addi	s4,s4,326 # 800584a8 <tickslock>
    havekids = 0;
    8000236a:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    8000236c:	0000f497          	auipc	s1,0xf
    80002370:	33c48493          	addi	s1,s1,828 # 800116a8 <proc>
    80002374:	a08d                	j	800023d6 <wait+0xa8>
          pid = np->pid;
    80002376:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000237a:	000b8f63          	beqz	s7,80002398 <wait+0x6a>
    8000237e:	6785                	lui	a5,0x1
    80002380:	97ca                	add	a5,a5,s2
    80002382:	4691                	li	a3,4
    80002384:	03448613          	addi	a2,s1,52
    80002388:	85de                	mv	a1,s7
    8000238a:	73c8                	ld	a0,160(a5)
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	2f6080e7          	jalr	758(ra) # 80001682 <copyout>
    80002394:	02054263          	bltz	a0,800023b8 <wait+0x8a>
          freeproc(np);
    80002398:	8526                	mv	a0,s1
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	828080e7          	jalr	-2008(ra) # 80001bc2 <freeproc>
          release(&np->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	916080e7          	jalr	-1770(ra) # 80000cba <release>
          release(&p->lock);
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	90c080e7          	jalr	-1780(ra) # 80000cba <release>
          return pid;
    800023b6:	a8a1                	j	8000240e <wait+0xe0>
            release(&np->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	900080e7          	jalr	-1792(ra) # 80000cba <release>
            release(&p->lock);
    800023c2:	854a                	mv	a0,s2
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8f6080e7          	jalr	-1802(ra) # 80000cba <release>
            return -1;
    800023cc:	59fd                	li	s3,-1
    800023ce:	a081                	j	8000240e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023d0:	94ce                	add	s1,s1,s3
    800023d2:	03448463          	beq	s1,s4,800023fa <wait+0xcc>
      if(np->parent == p){
    800023d6:	709c                	ld	a5,32(s1)
    800023d8:	ff279ce3          	bne	a5,s2,800023d0 <wait+0xa2>
        acquire(&np->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	828080e7          	jalr	-2008(ra) # 80000c06 <acquire>
        if(np->state == ZOMBIE){
    800023e6:	4c9c                	lw	a5,24(s1)
    800023e8:	f95787e3          	beq	a5,s5,80002376 <wait+0x48>
        release(&np->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8cc080e7          	jalr	-1844(ra) # 80000cba <release>
        havekids = 1;
    800023f6:	875a                	mv	a4,s6
    800023f8:	bfe1                	j	800023d0 <wait+0xa2>
    if(!havekids || p->killed){
    800023fa:	c701                	beqz	a4,80002402 <wait+0xd4>
    800023fc:	03092783          	lw	a5,48(s2)
    80002400:	c39d                	beqz	a5,80002426 <wait+0xf8>
      release(&p->lock);
    80002402:	854a                	mv	a0,s2
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	8b6080e7          	jalr	-1866(ra) # 80000cba <release>
      return -1;
    8000240c:	59fd                	li	s3,-1
}
    8000240e:	854e                	mv	a0,s3
    80002410:	60a6                	ld	ra,72(sp)
    80002412:	6406                	ld	s0,64(sp)
    80002414:	74e2                	ld	s1,56(sp)
    80002416:	7942                	ld	s2,48(sp)
    80002418:	79a2                	ld	s3,40(sp)
    8000241a:	7a02                	ld	s4,32(sp)
    8000241c:	6ae2                	ld	s5,24(sp)
    8000241e:	6b42                	ld	s6,16(sp)
    80002420:	6ba2                	ld	s7,8(sp)
    80002422:	6161                	addi	sp,sp,80
    80002424:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002426:	85ca                	mv	a1,s2
    80002428:	854a                	mv	a0,s2
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	e86080e7          	jalr	-378(ra) # 800022b0 <sleep>
    havekids = 0;
    80002432:	bf25                	j	8000236a <wait+0x3c>

0000000080002434 <wakeup>:
{
    80002434:	7139                	addi	sp,sp,-64
    80002436:	fc06                	sd	ra,56(sp)
    80002438:	f822                	sd	s0,48(sp)
    8000243a:	f426                	sd	s1,40(sp)
    8000243c:	f04a                	sd	s2,32(sp)
    8000243e:	ec4e                	sd	s3,24(sp)
    80002440:	e852                	sd	s4,16(sp)
    80002442:	e456                	sd	s5,8(sp)
    80002444:	e05a                	sd	s6,0(sp)
    80002446:	0080                	addi	s0,sp,64
    80002448:	8aaa                	mv	s5,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000244a:	0000f497          	auipc	s1,0xf
    8000244e:	25e48493          	addi	s1,s1,606 # 800116a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002452:	4a05                	li	s4,1
      p->state = RUNNABLE;
    80002454:	4b09                	li	s6,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002456:	6905                	lui	s2,0x1
    80002458:	1b890913          	addi	s2,s2,440 # 11b8 <_entry-0x7fffee48>
    8000245c:	00056997          	auipc	s3,0x56
    80002460:	04c98993          	addi	s3,s3,76 # 800584a8 <tickslock>
    80002464:	a809                	j	80002476 <wakeup+0x42>
    release(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	852080e7          	jalr	-1966(ra) # 80000cba <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002470:	94ca                	add	s1,s1,s2
    80002472:	03348063          	beq	s1,s3,80002492 <wakeup+0x5e>
    acquire(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	78e080e7          	jalr	1934(ra) # 80000c06 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	ff4792e3          	bne	a5,s4,80002466 <wakeup+0x32>
    80002486:	749c                	ld	a5,40(s1)
    80002488:	fd579fe3          	bne	a5,s5,80002466 <wakeup+0x32>
      p->state = RUNNABLE;
    8000248c:	0164ac23          	sw	s6,24(s1)
    80002490:	bfd9                	j	80002466 <wakeup+0x32>
}
    80002492:	70e2                	ld	ra,56(sp)
    80002494:	7442                	ld	s0,48(sp)
    80002496:	74a2                	ld	s1,40(sp)
    80002498:	7902                	ld	s2,32(sp)
    8000249a:	69e2                	ld	s3,24(sp)
    8000249c:	6a42                	ld	s4,16(sp)
    8000249e:	6aa2                	ld	s5,8(sp)
    800024a0:	6b02                	ld	s6,0(sp)
    800024a2:	6121                	addi	sp,sp,64
    800024a4:	8082                	ret

00000000800024a6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024a6:	7179                	addi	sp,sp,-48
    800024a8:	f406                	sd	ra,40(sp)
    800024aa:	f022                	sd	s0,32(sp)
    800024ac:	ec26                	sd	s1,24(sp)
    800024ae:	e84a                	sd	s2,16(sp)
    800024b0:	e44e                	sd	s3,8(sp)
    800024b2:	e052                	sd	s4,0(sp)
    800024b4:	1800                	addi	s0,sp,48
    800024b6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024b8:	0000f497          	auipc	s1,0xf
    800024bc:	1f048493          	addi	s1,s1,496 # 800116a8 <proc>
    800024c0:	6985                	lui	s3,0x1
    800024c2:	1b898993          	addi	s3,s3,440 # 11b8 <_entry-0x7fffee48>
    800024c6:	00056a17          	auipc	s4,0x56
    800024ca:	fe2a0a13          	addi	s4,s4,-30 # 800584a8 <tickslock>
    acquire(&p->lock);
    800024ce:	8526                	mv	a0,s1
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	736080e7          	jalr	1846(ra) # 80000c06 <acquire>
    if(p->pid == pid){
    800024d8:	5c9c                	lw	a5,56(s1)
    800024da:	01278c63          	beq	a5,s2,800024f2 <kill+0x4c>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7da080e7          	jalr	2010(ra) # 80000cba <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024e8:	94ce                	add	s1,s1,s3
    800024ea:	ff4492e3          	bne	s1,s4,800024ce <kill+0x28>
  }
  return -1;
    800024ee:	557d                	li	a0,-1
    800024f0:	a821                	j	80002508 <kill+0x62>
      p->killed = 1;
    800024f2:	4785                	li	a5,1
    800024f4:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024f6:	4c98                	lw	a4,24(s1)
    800024f8:	02f70063          	beq	a4,a5,80002518 <kill+0x72>
      release(&p->lock);
    800024fc:	8526                	mv	a0,s1
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	7bc080e7          	jalr	1980(ra) # 80000cba <release>
      return 0;
    80002506:	4501                	li	a0,0
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6a02                	ld	s4,0(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret
        p->state = RUNNABLE;
    80002518:	4789                	li	a5,2
    8000251a:	cc9c                	sw	a5,24(s1)
    8000251c:	b7c5                	j	800024fc <kill+0x56>

000000008000251e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000251e:	7179                	addi	sp,sp,-48
    80002520:	f406                	sd	ra,40(sp)
    80002522:	f022                	sd	s0,32(sp)
    80002524:	ec26                	sd	s1,24(sp)
    80002526:	e84a                	sd	s2,16(sp)
    80002528:	e44e                	sd	s3,8(sp)
    8000252a:	e052                	sd	s4,0(sp)
    8000252c:	1800                	addi	s0,sp,48
    8000252e:	84aa                	mv	s1,a0
    80002530:	892e                	mv	s2,a1
    80002532:	89b2                	mv	s3,a2
    80002534:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	4d8080e7          	jalr	1240(ra) # 80001a0e <myproc>
  if(user_dst){
    8000253e:	c09d                	beqz	s1,80002564 <either_copyout+0x46>
    return copyout(p->pagetable, dst, src, len);
    80002540:	6785                	lui	a5,0x1
    80002542:	953e                	add	a0,a0,a5
    80002544:	86d2                	mv	a3,s4
    80002546:	864e                	mv	a2,s3
    80002548:	85ca                	mv	a1,s2
    8000254a:	7148                	ld	a0,160(a0)
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	136080e7          	jalr	310(ra) # 80001682 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6a02                	ld	s4,0(sp)
    80002560:	6145                	addi	sp,sp,48
    80002562:	8082                	ret
    memmove((char *)dst, src, len);
    80002564:	000a061b          	sext.w	a2,s4
    80002568:	85ce                	mv	a1,s3
    8000256a:	854a                	mv	a0,s2
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	7f2080e7          	jalr	2034(ra) # 80000d5e <memmove>
    return 0;
    80002574:	8526                	mv	a0,s1
    80002576:	bff9                	j	80002554 <either_copyout+0x36>

0000000080002578 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	e052                	sd	s4,0(sp)
    80002586:	1800                	addi	s0,sp,48
    80002588:	892a                	mv	s2,a0
    8000258a:	84ae                	mv	s1,a1
    8000258c:	89b2                	mv	s3,a2
    8000258e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	47e080e7          	jalr	1150(ra) # 80001a0e <myproc>
  if(user_src){
    80002598:	c09d                	beqz	s1,800025be <either_copyin+0x46>
    return copyin(p->pagetable, dst, src, len);
    8000259a:	6785                	lui	a5,0x1
    8000259c:	97aa                	add	a5,a5,a0
    8000259e:	86d2                	mv	a3,s4
    800025a0:	864e                	mv	a2,s3
    800025a2:	85ca                	mv	a1,s2
    800025a4:	73c8                	ld	a0,160(a5)
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	168080e7          	jalr	360(ra) # 8000170e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ae:	70a2                	ld	ra,40(sp)
    800025b0:	7402                	ld	s0,32(sp)
    800025b2:	64e2                	ld	s1,24(sp)
    800025b4:	6942                	ld	s2,16(sp)
    800025b6:	69a2                	ld	s3,8(sp)
    800025b8:	6a02                	ld	s4,0(sp)
    800025ba:	6145                	addi	sp,sp,48
    800025bc:	8082                	ret
    memmove(dst, (char*)src, len);
    800025be:	000a061b          	sext.w	a2,s4
    800025c2:	85ce                	mv	a1,s3
    800025c4:	854a                	mv	a0,s2
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	798080e7          	jalr	1944(ra) # 80000d5e <memmove>
    return 0;
    800025ce:	8526                	mv	a0,s1
    800025d0:	bff9                	j	800025ae <either_copyin+0x36>

00000000800025d2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d2:	715d                	addi	sp,sp,-80
    800025d4:	e486                	sd	ra,72(sp)
    800025d6:	e0a2                	sd	s0,64(sp)
    800025d8:	fc26                	sd	s1,56(sp)
    800025da:	f84a                	sd	s2,48(sp)
    800025dc:	f44e                	sd	s3,40(sp)
    800025de:	f052                	sd	s4,32(sp)
    800025e0:	ec56                	sd	s5,24(sp)
    800025e2:	e85a                	sd	s6,16(sp)
    800025e4:	e45e                	sd	s7,8(sp)
    800025e6:	e062                	sd	s8,0(sp)
    800025e8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ea:	00006517          	auipc	a0,0x6
    800025ee:	ade50513          	addi	a0,a0,-1314 # 800080c8 <digits+0x88>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	fa2080e7          	jalr	-94(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	0ae48493          	addi	s1,s1,174 # 800116a8 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002602:	4b91                	li	s7,4
      state = states[p->state];
    else
      state = "???";
    80002604:	00006a17          	auipc	s4,0x6
    80002608:	c5ca0a13          	addi	s4,s4,-932 # 80008260 <digits+0x220>
    printf("%d %s %s", p->pid, state, p->name);
    8000260c:	6905                	lui	s2,0x1
    8000260e:	1a890b13          	addi	s6,s2,424 # 11a8 <_entry-0x7fffee58>
    80002612:	00006a97          	auipc	s5,0x6
    80002616:	c56a8a93          	addi	s5,s5,-938 # 80008268 <digits+0x228>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261a:	00006c17          	auipc	s8,0x6
    8000261e:	c86c0c13          	addi	s8,s8,-890 # 800082a0 <states.0>
  for(p = proc; p < &proc[NPROC]; p++){
    80002622:	1b890913          	addi	s2,s2,440
    80002626:	00056997          	auipc	s3,0x56
    8000262a:	e8298993          	addi	s3,s3,-382 # 800584a8 <tickslock>
    8000262e:	a025                	j	80002656 <procdump+0x84>
    printf("%d %s %s", p->pid, state, p->name);
    80002630:	016486b3          	add	a3,s1,s6
    80002634:	5c8c                	lw	a1,56(s1)
    80002636:	8556                	mv	a0,s5
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	f5c080e7          	jalr	-164(ra) # 80000594 <printf>
    printf("\n");
    80002640:	00006517          	auipc	a0,0x6
    80002644:	a8850513          	addi	a0,a0,-1400 # 800080c8 <digits+0x88>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	f4c080e7          	jalr	-180(ra) # 80000594 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002650:	94ca                	add	s1,s1,s2
    80002652:	01348f63          	beq	s1,s3,80002670 <procdump+0x9e>
    if(p->state == UNUSED)
    80002656:	4c9c                	lw	a5,24(s1)
    80002658:	dfe5                	beqz	a5,80002650 <procdump+0x7e>
      state = "???";
    8000265a:	8652                	mv	a2,s4
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265c:	fcfbeae3          	bltu	s7,a5,80002630 <procdump+0x5e>
    80002660:	1782                	slli	a5,a5,0x20
    80002662:	9381                	srli	a5,a5,0x20
    80002664:	078e                	slli	a5,a5,0x3
    80002666:	97e2                	add	a5,a5,s8
    80002668:	6390                	ld	a2,0(a5)
    8000266a:	f279                	bnez	a2,80002630 <procdump+0x5e>
      state = "???";
    8000266c:	8652                	mv	a2,s4
    8000266e:	b7c9                	j	80002630 <procdump+0x5e>
  }
}
    80002670:	60a6                	ld	ra,72(sp)
    80002672:	6406                	ld	s0,64(sp)
    80002674:	74e2                	ld	s1,56(sp)
    80002676:	7942                	ld	s2,48(sp)
    80002678:	79a2                	ld	s3,40(sp)
    8000267a:	7a02                	ld	s4,32(sp)
    8000267c:	6ae2                	ld	s5,24(sp)
    8000267e:	6b42                	ld	s6,16(sp)
    80002680:	6ba2                	ld	s7,8(sp)
    80002682:	6c02                	ld	s8,0(sp)
    80002684:	6161                	addi	sp,sp,80
    80002686:	8082                	ret

0000000080002688 <swtch>:
    80002688:	00153023          	sd	ra,0(a0)
    8000268c:	00253423          	sd	sp,8(a0)
    80002690:	e900                	sd	s0,16(a0)
    80002692:	ed04                	sd	s1,24(a0)
    80002694:	03253023          	sd	s2,32(a0)
    80002698:	03353423          	sd	s3,40(a0)
    8000269c:	03453823          	sd	s4,48(a0)
    800026a0:	03553c23          	sd	s5,56(a0)
    800026a4:	05653023          	sd	s6,64(a0)
    800026a8:	05753423          	sd	s7,72(a0)
    800026ac:	05853823          	sd	s8,80(a0)
    800026b0:	05953c23          	sd	s9,88(a0)
    800026b4:	07a53023          	sd	s10,96(a0)
    800026b8:	07b53423          	sd	s11,104(a0)
    800026bc:	0005b083          	ld	ra,0(a1)
    800026c0:	0085b103          	ld	sp,8(a1)
    800026c4:	6980                	ld	s0,16(a1)
    800026c6:	6d84                	ld	s1,24(a1)
    800026c8:	0205b903          	ld	s2,32(a1)
    800026cc:	0285b983          	ld	s3,40(a1)
    800026d0:	0305ba03          	ld	s4,48(a1)
    800026d4:	0385ba83          	ld	s5,56(a1)
    800026d8:	0405bb03          	ld	s6,64(a1)
    800026dc:	0485bb83          	ld	s7,72(a1)
    800026e0:	0505bc03          	ld	s8,80(a1)
    800026e4:	0585bc83          	ld	s9,88(a1)
    800026e8:	0605bd03          	ld	s10,96(a1)
    800026ec:	0685bd83          	ld	s11,104(a1)
    800026f0:	8082                	ret

00000000800026f2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f2:	1141                	addi	sp,sp,-16
    800026f4:	e406                	sd	ra,8(sp)
    800026f6:	e022                	sd	s0,0(sp)
    800026f8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fa:	00006597          	auipc	a1,0x6
    800026fe:	bce58593          	addi	a1,a1,-1074 # 800082c8 <states.0+0x28>
    80002702:	00056517          	auipc	a0,0x56
    80002706:	da650513          	addi	a0,a0,-602 # 800584a8 <tickslock>
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	46c080e7          	jalr	1132(ra) # 80000b76 <initlock>
}
    80002712:	60a2                	ld	ra,8(sp)
    80002714:	6402                	ld	s0,0(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e422                	sd	s0,8(sp)
    8000271e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002720:	00004797          	auipc	a5,0x4
    80002724:	9a078793          	addi	a5,a5,-1632 # 800060c0 <kernelvec>
    80002728:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272c:	6422                	ld	s0,8(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002732:	1141                	addi	sp,sp,-16
    80002734:	e406                	sd	ra,8(sp)
    80002736:	e022                	sd	s0,0(sp)
    80002738:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273a:	fffff097          	auipc	ra,0xfffff
    8000273e:	2d4080e7          	jalr	724(ra) # 80001a0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002742:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002746:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002748:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274c:	00005617          	auipc	a2,0x5
    80002750:	8b460613          	addi	a2,a2,-1868 # 80007000 <_trampoline>
    80002754:	00005697          	auipc	a3,0x5
    80002758:	8ac68693          	addi	a3,a3,-1876 # 80007000 <_trampoline>
    8000275c:	8e91                	sub	a3,a3,a2
    8000275e:	040007b7          	lui	a5,0x4000
    80002762:	17fd                	addi	a5,a5,-1
    80002764:	07b2                	slli	a5,a5,0xc
    80002766:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002768:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276c:	6705                	lui	a4,0x1
    8000276e:	953a                	add	a0,a0,a4
    80002770:	7554                	ld	a3,168(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002772:	180025f3          	csrr	a1,satp
    80002776:	e28c                	sd	a1,0(a3)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002778:	754c                	ld	a1,168(a0)
    8000277a:	6954                	ld	a3,144(a0)
    8000277c:	96ba                	add	a3,a3,a4
    8000277e:	e594                	sd	a3,8(a1)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002780:	7558                	ld	a4,168(a0)
    80002782:	00000697          	auipc	a3,0x0
    80002786:	13868693          	addi	a3,a3,312 # 800028ba <usertrap>
    8000278a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278c:	7558                	ld	a4,168(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278e:	8692                	mv	a3,tp
    80002790:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002796:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a2:	7558                	ld	a4,168(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a4:	6f18                	ld	a4,24(a4)
    800027a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027aa:	714c                	ld	a1,160(a0)
    800027ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ae:	00005717          	auipc	a4,0x5
    800027b2:	8e270713          	addi	a4,a4,-1822 # 80007090 <userret>
    800027b6:	8f11                	sub	a4,a4,a2
    800027b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ba:	577d                	li	a4,-1
    800027bc:	177e                	slli	a4,a4,0x3f
    800027be:	8dd9                	or	a1,a1,a4
    800027c0:	02000537          	lui	a0,0x2000
    800027c4:	157d                	addi	a0,a0,-1
    800027c6:	0536                	slli	a0,a0,0xd
    800027c8:	9782                	jalr	a5
}
    800027ca:	60a2                	ld	ra,8(sp)
    800027cc:	6402                	ld	s0,0(sp)
    800027ce:	0141                	addi	sp,sp,16
    800027d0:	8082                	ret

00000000800027d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027dc:	00056497          	auipc	s1,0x56
    800027e0:	ccc48493          	addi	s1,s1,-820 # 800584a8 <tickslock>
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	420080e7          	jalr	1056(ra) # 80000c06 <acquire>
  ticks++;
    800027ee:	00007517          	auipc	a0,0x7
    800027f2:	83250513          	addi	a0,a0,-1998 # 80009020 <ticks>
    800027f6:	411c                	lw	a5,0(a0)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	c38080e7          	jalr	-968(ra) # 80002434 <wakeup>
  release(&tickslock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	4b4080e7          	jalr	1204(ra) # 80000cba <release>
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret

0000000080002818 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002822:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002826:	00074d63          	bltz	a4,80002840 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282a:	57fd                	li	a5,-1
    8000282c:	17fe                	slli	a5,a5,0x3f
    8000282e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002830:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002832:	06f70363          	beq	a4,a5,80002898 <devintr+0x80>
  }
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret
     (scause & 0xff) == 9){
    80002840:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002844:	46a5                	li	a3,9
    80002846:	fed792e3          	bne	a5,a3,8000282a <devintr+0x12>
    int irq = plic_claim();
    8000284a:	00004097          	auipc	ra,0x4
    8000284e:	97e080e7          	jalr	-1666(ra) # 800061c8 <plic_claim>
    80002852:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002854:	47a9                	li	a5,10
    80002856:	02f50763          	beq	a0,a5,80002884 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285a:	4785                	li	a5,1
    8000285c:	02f50963          	beq	a0,a5,8000288e <devintr+0x76>
    return 1;
    80002860:	4505                	li	a0,1
    } else if(irq){
    80002862:	d8f1                	beqz	s1,80002836 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002864:	85a6                	mv	a1,s1
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	a6a50513          	addi	a0,a0,-1430 # 800082d0 <states.0+0x30>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d26080e7          	jalr	-730(ra) # 80000594 <printf>
      plic_complete(irq);
    80002876:	8526                	mv	a0,s1
    80002878:	00004097          	auipc	ra,0x4
    8000287c:	974080e7          	jalr	-1676(ra) # 800061ec <plic_complete>
    return 1;
    80002880:	4505                	li	a0,1
    80002882:	bf55                	j	80002836 <devintr+0x1e>
      uartintr();
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	146080e7          	jalr	326(ra) # 800009ca <uartintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x5e>
      virtio_disk_intr();
    8000288e:	00004097          	auipc	ra,0x4
    80002892:	df0080e7          	jalr	-528(ra) # 8000667e <virtio_disk_intr>
    80002896:	b7c5                	j	80002876 <devintr+0x5e>
    if(cpuid() == 0){
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	14a080e7          	jalr	330(ra) # 800019e2 <cpuid>
    800028a0:	c901                	beqz	a0,800028b0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a8:	14479073          	csrw	sip,a5
    return 2;
    800028ac:	4509                	li	a0,2
    800028ae:	b761                	j	80002836 <devintr+0x1e>
      clockintr();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	f22080e7          	jalr	-222(ra) # 800027d2 <clockintr>
    800028b8:	b7ed                	j	800028a2 <devintr+0x8a>

00000000800028ba <usertrap>:
{
    800028ba:	1101                	addi	sp,sp,-32
    800028bc:	ec06                	sd	ra,24(sp)
    800028be:	e822                	sd	s0,16(sp)
    800028c0:	e426                	sd	s1,8(sp)
    800028c2:	e04a                	sd	s2,0(sp)
    800028c4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ca:	1007f793          	andi	a5,a5,256
    800028ce:	e7ad                	bnez	a5,80002938 <usertrap+0x7e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d0:	00003797          	auipc	a5,0x3
    800028d4:	7f078793          	addi	a5,a5,2032 # 800060c0 <kernelvec>
    800028d8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	132080e7          	jalr	306(ra) # 80001a0e <myproc>
    800028e4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e6:	6785                	lui	a5,0x1
    800028e8:	97aa                	add	a5,a5,a0
    800028ea:	77dc                	ld	a5,168(a5)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	14102773          	csrr	a4,sepc
    800028f0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f6:	47a1                	li	a5,8
    800028f8:	04f71e63          	bne	a4,a5,80002954 <usertrap+0x9a>
    if(p->killed)
    800028fc:	591c                	lw	a5,48(a0)
    800028fe:	e7a9                	bnez	a5,80002948 <usertrap+0x8e>
    p->trapframe->epc += 4;
    80002900:	6785                	lui	a5,0x1
    80002902:	97a6                	add	a5,a5,s1
    80002904:	77d8                	ld	a4,168(a5)
    80002906:	6f1c                	ld	a5,24(a4)
    80002908:	0791                	addi	a5,a5,4
    8000290a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002910:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002914:	10079073          	csrw	sstatus,a5
    syscall();
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	4ac080e7          	jalr	1196(ra) # 80002dc4 <syscall>
  if(p->killed)
    80002920:	589c                	lw	a5,48(s1)
    80002922:	e3c5                	bnez	a5,800029c2 <usertrap+0x108>
  usertrapret();
    80002924:	00000097          	auipc	ra,0x0
    80002928:	e0e080e7          	jalr	-498(ra) # 80002732 <usertrapret>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6902                	ld	s2,0(sp)
    80002934:	6105                	addi	sp,sp,32
    80002936:	8082                	ret
    panic("usertrap: not from user mode");
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	9b850513          	addi	a0,a0,-1608 # 800082f0 <states.0+0x50>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c0a080e7          	jalr	-1014(ra) # 8000054a <panic>
      exit(-1);
    80002948:	557d                	li	a0,-1
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	814080e7          	jalr	-2028(ra) # 8000215e <exit>
    80002952:	b77d                	j	80002900 <usertrap+0x46>
  } else if((which_dev = devintr()) != 0){
    80002954:	00000097          	auipc	ra,0x0
    80002958:	ec4080e7          	jalr	-316(ra) # 80002818 <devintr>
    8000295c:	892a                	mv	s2,a0
    8000295e:	c501                	beqz	a0,80002966 <usertrap+0xac>
  if(p->killed)
    80002960:	589c                	lw	a5,48(s1)
    80002962:	c3a1                	beqz	a5,800029a2 <usertrap+0xe8>
    80002964:	a815                	j	80002998 <usertrap+0xde>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002966:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000296a:	5c90                	lw	a2,56(s1)
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	9a450513          	addi	a0,a0,-1628 # 80008310 <states.0+0x70>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	c20080e7          	jalr	-992(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002980:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9bc50513          	addi	a0,a0,-1604 # 80008340 <states.0+0xa0>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	c08080e7          	jalr	-1016(ra) # 80000594 <printf>
    p->killed = 1;
    80002994:	4785                	li	a5,1
    80002996:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002998:	557d                	li	a0,-1
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	7c4080e7          	jalr	1988(ra) # 8000215e <exit>
  if(which_dev == 2)
    800029a2:	4789                	li	a5,2
    800029a4:	f8f910e3          	bne	s2,a5,80002924 <usertrap+0x6a>
    if(p->thrdstop_ticks < p->thrdstop_interval - 1) p->thrdstop_ticks++;
    800029a8:	5cdc                	lw	a5,60(s1)
    800029aa:	40b8                	lw	a4,64(s1)
    800029ac:	fff7069b          	addiw	a3,a4,-1
    800029b0:	00d7db63          	bge	a5,a3,800029c6 <usertrap+0x10c>
    800029b4:	2785                	addiw	a5,a5,1
    800029b6:	dcdc                	sw	a5,60(s1)
    yield();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	8bc080e7          	jalr	-1860(ra) # 80002274 <yield>
    800029c0:	b795                	j	80002924 <usertrap+0x6a>
  int which_dev = 0;
    800029c2:	4901                	li	s2,0
    800029c4:	bfd1                	j	80002998 <usertrap+0xde>
    else if (p->thrdstop_interval > 0) {
    800029c6:	fee059e3          	blez	a4,800029b8 <usertrap+0xfe>
    	struct thrd_context_data *thcd = &(p->thrdstop_context[p->thrdstop_context_id]);
    800029ca:	40f4                	lw	a3,68(s1)
	struct trapframe *tf = p->trapframe;
    800029cc:	6785                	lui	a5,0x1
    800029ce:	97a6                	add	a5,a5,s1
    800029d0:	77dc                	ld	a5,168(a5)
	thcd->s_regs[0] = tf->s0;
    800029d2:	73b0                	ld	a2,96(a5)
    800029d4:	00869713          	slli	a4,a3,0x8
    800029d8:	9726                	add	a4,a4,s1
    800029da:	eb30                	sd	a2,80(a4)
	thcd->s_regs[1] = tf->s1;
    800029dc:	77b0                	ld	a2,104(a5)
    800029de:	ef30                	sd	a2,88(a4)
	thcd->s_regs[2] = tf->s2;
    800029e0:	7bd0                	ld	a2,176(a5)
    800029e2:	f330                	sd	a2,96(a4)
	thcd->s_regs[3] = tf->s3;
    800029e4:	7fd0                	ld	a2,184(a5)
    800029e6:	f730                	sd	a2,104(a4)
	thcd->s_regs[4] = tf->s4;
    800029e8:	63f0                	ld	a2,192(a5)
    800029ea:	fb30                	sd	a2,112(a4)
	thcd->s_regs[5] = tf->s5;
    800029ec:	67f0                	ld	a2,200(a5)
    800029ee:	ff30                	sd	a2,120(a4)
	thcd->s_regs[6] = tf->s6;
    800029f0:	6bf0                	ld	a2,208(a5)
    800029f2:	e350                	sd	a2,128(a4)
	thcd->s_regs[7] = tf->s7;
    800029f4:	6ff0                	ld	a2,216(a5)
    800029f6:	e750                	sd	a2,136(a4)
	thcd->s_regs[8] = tf->s8;
    800029f8:	73f0                	ld	a2,224(a5)
    800029fa:	eb50                	sd	a2,144(a4)
	thcd->s_regs[9] = tf->s9;
    800029fc:	77f0                	ld	a2,232(a5)
    800029fe:	ef50                	sd	a2,152(a4)
	thcd->s_regs[10] = tf->s10;
    80002a00:	7bf0                	ld	a2,240(a5)
    80002a02:	f350                	sd	a2,160(a4)
	thcd->s_regs[11] = tf->s11;
    80002a04:	7ff0                	ld	a2,248(a5)
    80002a06:	f750                	sd	a2,168(a4)
	thcd->ra = tf->ra;
    80002a08:	7790                	ld	a2,40(a5)
    80002a0a:	fb50                	sd	a2,176(a4)
	thcd->sp = tf->sp;
    80002a0c:	7b90                	ld	a2,48(a5)
    80002a0e:	ff50                	sd	a2,184(a4)
	thcd->t_regs[0] = tf->t0;
    80002a10:	67b0                	ld	a2,72(a5)
    80002a12:	e370                	sd	a2,192(a4)
	thcd->t_regs[1] = tf->t1;
    80002a14:	6bb0                	ld	a2,80(a5)
    80002a16:	e770                	sd	a2,200(a4)
	thcd->t_regs[2] = tf->t2;
    80002a18:	6fb0                	ld	a2,88(a5)
    80002a1a:	eb70                	sd	a2,208(a4)
	thcd->t_regs[3] = tf->t3;
    80002a1c:	1007b603          	ld	a2,256(a5) # 1100 <_entry-0x7fffef00>
    80002a20:	ef70                	sd	a2,216(a4)
	thcd->t_regs[4] = tf->t4;
    80002a22:	1087b603          	ld	a2,264(a5)
    80002a26:	f370                	sd	a2,224(a4)
	thcd->t_regs[5] = tf->t5;
    80002a28:	1107b603          	ld	a2,272(a5)
    80002a2c:	f770                	sd	a2,232(a4)
	thcd->t_regs[6] = tf->t6;
    80002a2e:	1187b603          	ld	a2,280(a5)
    80002a32:	fb70                	sd	a2,240(a4)
	thcd->a_regs[0] = tf->a0;
    80002a34:	7bb0                	ld	a2,112(a5)
    80002a36:	ff70                	sd	a2,248(a4)
	thcd->a_regs[1] = tf->a1;
    80002a38:	7fb0                	ld	a2,120(a5)
    80002a3a:	10c73023          	sd	a2,256(a4)
	thcd->a_regs[2] = tf->a2;
    80002a3e:	63d0                	ld	a2,128(a5)
    80002a40:	0685                	addi	a3,a3,1
    80002a42:	06a2                	slli	a3,a3,0x8
    80002a44:	96a6                	add	a3,a3,s1
    80002a46:	e690                	sd	a2,8(a3)
	thcd->a_regs[3] = tf->a3;
    80002a48:	67d4                	ld	a3,136(a5)
    80002a4a:	10d73823          	sd	a3,272(a4)
	thcd->a_regs[4] = tf->a4;
    80002a4e:	6bd4                	ld	a3,144(a5)
    80002a50:	10d73c23          	sd	a3,280(a4)
	thcd->a_regs[5] = tf->a5;
    80002a54:	6fd4                	ld	a3,152(a5)
    80002a56:	12d73023          	sd	a3,288(a4)
	thcd->a_regs[6] = tf->a6;
    80002a5a:	73d4                	ld	a3,160(a5)
    80002a5c:	12d73423          	sd	a3,296(a4)
	thcd->a_regs[7] = tf->a7;
    80002a60:	77d4                	ld	a3,168(a5)
    80002a62:	12d73823          	sd	a3,304(a4)
	thcd->gp = tf->gp;
    80002a66:	7f94                	ld	a3,56(a5)
    80002a68:	12d73c23          	sd	a3,312(a4)
	thcd->tp = tf->tp;
    80002a6c:	63b4                	ld	a3,64(a5)
    80002a6e:	14d73023          	sd	a3,320(a4)
	thcd->epc = tf->epc;
    80002a72:	6f94                	ld	a3,24(a5)
    80002a74:	14d73423          	sd	a3,328(a4)
    	p->thrdstop_interval = -1;
    80002a78:	577d                	li	a4,-1
    80002a7a:	c0b8                	sw	a4,64(s1)
	p->thrdstop_ticks = 0;
    80002a7c:	0204ae23          	sw	zero,60(s1)
	p->trapframe->epc = p->thrdstop_handler_pointer;
    80002a80:	64b8                	ld	a4,72(s1)
    80002a82:	ef98                	sd	a4,24(a5)
    80002a84:	bf15                	j	800029b8 <usertrap+0xfe>

0000000080002a86 <kerneltrap>:
{
    80002a86:	7179                	addi	sp,sp,-48
    80002a88:	f406                	sd	ra,40(sp)
    80002a8a:	f022                	sd	s0,32(sp)
    80002a8c:	ec26                	sd	s1,24(sp)
    80002a8e:	e84a                	sd	s2,16(sp)
    80002a90:	e44e                	sd	s3,8(sp)
    80002a92:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a94:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a98:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aa0:	1004f793          	andi	a5,s1,256
    80002aa4:	cb85                	beqz	a5,80002ad4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aaa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aac:	ef85                	bnez	a5,80002ae4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002aae:	00000097          	auipc	ra,0x0
    80002ab2:	d6a080e7          	jalr	-662(ra) # 80002818 <devintr>
    80002ab6:	cd1d                	beqz	a0,80002af4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab8:	4789                	li	a5,2
    80002aba:	06f50a63          	beq	a0,a5,80002b2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002abe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac2:	10049073          	csrw	sstatus,s1
}
    80002ac6:	70a2                	ld	ra,40(sp)
    80002ac8:	7402                	ld	s0,32(sp)
    80002aca:	64e2                	ld	s1,24(sp)
    80002acc:	6942                	ld	s2,16(sp)
    80002ace:	69a2                	ld	s3,8(sp)
    80002ad0:	6145                	addi	sp,sp,48
    80002ad2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	88c50513          	addi	a0,a0,-1908 # 80008360 <states.0+0xc0>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a6e080e7          	jalr	-1426(ra) # 8000054a <panic>
    panic("kerneltrap: interrupts enabled");
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	8a450513          	addi	a0,a0,-1884 # 80008388 <states.0+0xe8>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	a5e080e7          	jalr	-1442(ra) # 8000054a <panic>
    printf("scause %p\n", scause);
    80002af4:	85ce                	mv	a1,s3
    80002af6:	00006517          	auipc	a0,0x6
    80002afa:	8b250513          	addi	a0,a0,-1870 # 800083a8 <states.0+0x108>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a96080e7          	jalr	-1386(ra) # 80000594 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	8aa50513          	addi	a0,a0,-1878 # 800083b8 <states.0+0x118>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a7e080e7          	jalr	-1410(ra) # 80000594 <printf>
    panic("kerneltrap");
    80002b1e:	00006517          	auipc	a0,0x6
    80002b22:	8b250513          	addi	a0,a0,-1870 # 800083d0 <states.0+0x130>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a24080e7          	jalr	-1500(ra) # 8000054a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	ee0080e7          	jalr	-288(ra) # 80001a0e <myproc>
    80002b36:	d541                	beqz	a0,80002abe <kerneltrap+0x38>
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	ed6080e7          	jalr	-298(ra) # 80001a0e <myproc>
    80002b40:	4d18                	lw	a4,24(a0)
    80002b42:	478d                	li	a5,3
    80002b44:	f6f71de3          	bne	a4,a5,80002abe <kerneltrap+0x38>
    struct proc* p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	ec6080e7          	jalr	-314(ra) # 80001a0e <myproc>
    if(p->thrdstop_ticks < p->thrdstop_interval - 1) p->thrdstop_ticks++;
    80002b50:	5d5c                	lw	a5,60(a0)
    80002b52:	4138                	lw	a4,64(a0)
    80002b54:	fff7069b          	addiw	a3,a4,-1
    80002b58:	00d7d963          	bge	a5,a3,80002b6a <kerneltrap+0xe4>
    80002b5c:	2785                	addiw	a5,a5,1
    80002b5e:	dd5c                	sw	a5,60(a0)
    yield();
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	714080e7          	jalr	1812(ra) # 80002274 <yield>
    80002b68:	bf99                	j	80002abe <kerneltrap+0x38>
    else if (p->thrdstop_interval > 0) {
    80002b6a:	fee05be3          	blez	a4,80002b60 <kerneltrap+0xda>
    	struct thrd_context_data *thcd = &(p->thrdstop_context[p->thrdstop_context_id]);
    80002b6e:	4174                	lw	a3,68(a0)
	struct trapframe *tf = p->trapframe;
    80002b70:	6785                	lui	a5,0x1
    80002b72:	97aa                	add	a5,a5,a0
    80002b74:	77dc                	ld	a5,168(a5)
	thcd->s_regs[0] = tf->s0;
    80002b76:	73b0                	ld	a2,96(a5)
    80002b78:	00869713          	slli	a4,a3,0x8
    80002b7c:	972a                	add	a4,a4,a0
    80002b7e:	eb30                	sd	a2,80(a4)
	thcd->s_regs[1] = tf->s1;
    80002b80:	77b0                	ld	a2,104(a5)
    80002b82:	ef30                	sd	a2,88(a4)
	thcd->s_regs[2] = tf->s2;
    80002b84:	7bd0                	ld	a2,176(a5)
    80002b86:	f330                	sd	a2,96(a4)
	thcd->s_regs[3] = tf->s3;
    80002b88:	7fd0                	ld	a2,184(a5)
    80002b8a:	f730                	sd	a2,104(a4)
	thcd->s_regs[4] = tf->s4;
    80002b8c:	63f0                	ld	a2,192(a5)
    80002b8e:	fb30                	sd	a2,112(a4)
	thcd->s_regs[5] = tf->s5;
    80002b90:	67f0                	ld	a2,200(a5)
    80002b92:	ff30                	sd	a2,120(a4)
	thcd->s_regs[6] = tf->s6;
    80002b94:	6bf0                	ld	a2,208(a5)
    80002b96:	e350                	sd	a2,128(a4)
	thcd->s_regs[7] = tf->s7;
    80002b98:	6ff0                	ld	a2,216(a5)
    80002b9a:	e750                	sd	a2,136(a4)
	thcd->s_regs[8] = tf->s8;
    80002b9c:	73f0                	ld	a2,224(a5)
    80002b9e:	eb50                	sd	a2,144(a4)
	thcd->s_regs[9] = tf->s9;
    80002ba0:	77f0                	ld	a2,232(a5)
    80002ba2:	ef50                	sd	a2,152(a4)
	thcd->s_regs[10] = tf->s10;
    80002ba4:	7bf0                	ld	a2,240(a5)
    80002ba6:	f350                	sd	a2,160(a4)
	thcd->s_regs[11] = tf->s11;
    80002ba8:	7ff0                	ld	a2,248(a5)
    80002baa:	f750                	sd	a2,168(a4)
	thcd->ra = tf->ra;
    80002bac:	7790                	ld	a2,40(a5)
    80002bae:	fb50                	sd	a2,176(a4)
	thcd->sp = tf->sp;
    80002bb0:	7b90                	ld	a2,48(a5)
    80002bb2:	ff50                	sd	a2,184(a4)
	thcd->t_regs[0] = tf->t0;
    80002bb4:	67b0                	ld	a2,72(a5)
    80002bb6:	e370                	sd	a2,192(a4)
	thcd->t_regs[1] = tf->t1;
    80002bb8:	6bb0                	ld	a2,80(a5)
    80002bba:	e770                	sd	a2,200(a4)
	thcd->t_regs[2] = tf->t2;
    80002bbc:	6fb0                	ld	a2,88(a5)
    80002bbe:	eb70                	sd	a2,208(a4)
	thcd->t_regs[3] = tf->t3;
    80002bc0:	1007b603          	ld	a2,256(a5) # 1100 <_entry-0x7fffef00>
    80002bc4:	ef70                	sd	a2,216(a4)
	thcd->t_regs[4] = tf->t4;
    80002bc6:	1087b603          	ld	a2,264(a5)
    80002bca:	f370                	sd	a2,224(a4)
	thcd->t_regs[5] = tf->t5;
    80002bcc:	1107b603          	ld	a2,272(a5)
    80002bd0:	f770                	sd	a2,232(a4)
	thcd->t_regs[6] = tf->t6;
    80002bd2:	1187b603          	ld	a2,280(a5)
    80002bd6:	fb70                	sd	a2,240(a4)
	thcd->a_regs[0] = tf->a0;
    80002bd8:	7bb0                	ld	a2,112(a5)
    80002bda:	ff70                	sd	a2,248(a4)
	thcd->a_regs[1] = tf->a1;
    80002bdc:	7fb0                	ld	a2,120(a5)
    80002bde:	10c73023          	sd	a2,256(a4)
	thcd->a_regs[2] = tf->a2;
    80002be2:	63d0                	ld	a2,128(a5)
    80002be4:	0685                	addi	a3,a3,1
    80002be6:	06a2                	slli	a3,a3,0x8
    80002be8:	96aa                	add	a3,a3,a0
    80002bea:	e690                	sd	a2,8(a3)
	thcd->a_regs[3] = tf->a3;
    80002bec:	67d4                	ld	a3,136(a5)
    80002bee:	10d73823          	sd	a3,272(a4)
	thcd->a_regs[4] = tf->a4;
    80002bf2:	6bd4                	ld	a3,144(a5)
    80002bf4:	10d73c23          	sd	a3,280(a4)
	thcd->a_regs[5] = tf->a5;
    80002bf8:	6fd4                	ld	a3,152(a5)
    80002bfa:	12d73023          	sd	a3,288(a4)
	thcd->a_regs[6] = tf->a6;
    80002bfe:	73d4                	ld	a3,160(a5)
    80002c00:	12d73423          	sd	a3,296(a4)
	thcd->a_regs[7] = tf->a7;
    80002c04:	77d4                	ld	a3,168(a5)
    80002c06:	12d73823          	sd	a3,304(a4)
	thcd->gp = tf->gp;
    80002c0a:	7f94                	ld	a3,56(a5)
    80002c0c:	12d73c23          	sd	a3,312(a4)
	thcd->tp = tf->tp;
    80002c10:	63b4                	ld	a3,64(a5)
    80002c12:	14d73023          	sd	a3,320(a4)
	thcd->epc = tf->epc;
    80002c16:	6f94                	ld	a3,24(a5)
    80002c18:	14d73423          	sd	a3,328(a4)
    	p->thrdstop_interval = -1;
    80002c1c:	577d                	li	a4,-1
    80002c1e:	c138                	sw	a4,64(a0)
	p->thrdstop_ticks = 0;
    80002c20:	02052e23          	sw	zero,60(a0)
	p->trapframe->epc = p->thrdstop_handler_pointer;
    80002c24:	6538                	ld	a4,72(a0)
    80002c26:	ef98                	sd	a4,24(a5)
    80002c28:	bf25                	j	80002b60 <kerneltrap+0xda>

0000000080002c2a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	1000                	addi	s0,sp,32
    80002c34:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	dd8080e7          	jalr	-552(ra) # 80001a0e <myproc>
  switch (n) {
    80002c3e:	4795                	li	a5,5
    80002c40:	0497ed63          	bltu	a5,s1,80002c9a <argraw+0x70>
    80002c44:	048a                	slli	s1,s1,0x2
    80002c46:	00005717          	auipc	a4,0x5
    80002c4a:	7c270713          	addi	a4,a4,1986 # 80008408 <states.0+0x168>
    80002c4e:	94ba                	add	s1,s1,a4
    80002c50:	409c                	lw	a5,0(s1)
    80002c52:	97ba                	add	a5,a5,a4
    80002c54:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c56:	6785                	lui	a5,0x1
    80002c58:	953e                	add	a0,a0,a5
    80002c5a:	755c                	ld	a5,168(a0)
    80002c5c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c5e:	60e2                	ld	ra,24(sp)
    80002c60:	6442                	ld	s0,16(sp)
    80002c62:	64a2                	ld	s1,8(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    return p->trapframe->a1;
    80002c68:	6785                	lui	a5,0x1
    80002c6a:	953e                	add	a0,a0,a5
    80002c6c:	755c                	ld	a5,168(a0)
    80002c6e:	7fa8                	ld	a0,120(a5)
    80002c70:	b7fd                	j	80002c5e <argraw+0x34>
    return p->trapframe->a2;
    80002c72:	6785                	lui	a5,0x1
    80002c74:	953e                	add	a0,a0,a5
    80002c76:	755c                	ld	a5,168(a0)
    80002c78:	63c8                	ld	a0,128(a5)
    80002c7a:	b7d5                	j	80002c5e <argraw+0x34>
    return p->trapframe->a3;
    80002c7c:	6785                	lui	a5,0x1
    80002c7e:	953e                	add	a0,a0,a5
    80002c80:	755c                	ld	a5,168(a0)
    80002c82:	67c8                	ld	a0,136(a5)
    80002c84:	bfe9                	j	80002c5e <argraw+0x34>
    return p->trapframe->a4;
    80002c86:	6785                	lui	a5,0x1
    80002c88:	953e                	add	a0,a0,a5
    80002c8a:	755c                	ld	a5,168(a0)
    80002c8c:	6bc8                	ld	a0,144(a5)
    80002c8e:	bfc1                	j	80002c5e <argraw+0x34>
    return p->trapframe->a5;
    80002c90:	6785                	lui	a5,0x1
    80002c92:	953e                	add	a0,a0,a5
    80002c94:	755c                	ld	a5,168(a0)
    80002c96:	6fc8                	ld	a0,152(a5)
    80002c98:	b7d9                	j	80002c5e <argraw+0x34>
  panic("argraw");
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	74650513          	addi	a0,a0,1862 # 800083e0 <states.0+0x140>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	8a8080e7          	jalr	-1880(ra) # 8000054a <panic>

0000000080002caa <fetchaddr>:
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	e04a                	sd	s2,0(sp)
    80002cb4:	1000                	addi	s0,sp,32
    80002cb6:	84aa                	mv	s1,a0
    80002cb8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	d54080e7          	jalr	-684(ra) # 80001a0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cc2:	6785                	lui	a5,0x1
    80002cc4:	97aa                	add	a5,a5,a0
    80002cc6:	6fdc                	ld	a5,152(a5)
    80002cc8:	02f4fa63          	bgeu	s1,a5,80002cfc <fetchaddr+0x52>
    80002ccc:	00848713          	addi	a4,s1,8
    80002cd0:	02e7e863          	bltu	a5,a4,80002d00 <fetchaddr+0x56>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cd4:	6785                	lui	a5,0x1
    80002cd6:	97aa                	add	a5,a5,a0
    80002cd8:	46a1                	li	a3,8
    80002cda:	8626                	mv	a2,s1
    80002cdc:	85ca                	mv	a1,s2
    80002cde:	73c8                	ld	a0,160(a5)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	a2e080e7          	jalr	-1490(ra) # 8000170e <copyin>
    80002ce8:	00a03533          	snez	a0,a0
    80002cec:	40a00533          	neg	a0,a0
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6902                	ld	s2,0(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret
    return -1;
    80002cfc:	557d                	li	a0,-1
    80002cfe:	bfcd                	j	80002cf0 <fetchaddr+0x46>
    80002d00:	557d                	li	a0,-1
    80002d02:	b7fd                	j	80002cf0 <fetchaddr+0x46>

0000000080002d04 <fetchstr>:
{
    80002d04:	7179                	addi	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	e84a                	sd	s2,16(sp)
    80002d0e:	e44e                	sd	s3,8(sp)
    80002d10:	1800                	addi	s0,sp,48
    80002d12:	892a                	mv	s2,a0
    80002d14:	84ae                	mv	s1,a1
    80002d16:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	cf6080e7          	jalr	-778(ra) # 80001a0e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d20:	6785                	lui	a5,0x1
    80002d22:	97aa                	add	a5,a5,a0
    80002d24:	86ce                	mv	a3,s3
    80002d26:	864a                	mv	a2,s2
    80002d28:	85a6                	mv	a1,s1
    80002d2a:	73c8                	ld	a0,160(a5)
    80002d2c:	fffff097          	auipc	ra,0xfffff
    80002d30:	a70080e7          	jalr	-1424(ra) # 8000179c <copyinstr>
  if(err < 0)
    80002d34:	00054763          	bltz	a0,80002d42 <fetchstr+0x3e>
  return strlen(buf);
    80002d38:	8526                	mv	a0,s1
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	14c080e7          	jalr	332(ra) # 80000e86 <strlen>
}
    80002d42:	70a2                	ld	ra,40(sp)
    80002d44:	7402                	ld	s0,32(sp)
    80002d46:	64e2                	ld	s1,24(sp)
    80002d48:	6942                	ld	s2,16(sp)
    80002d4a:	69a2                	ld	s3,8(sp)
    80002d4c:	6145                	addi	sp,sp,48
    80002d4e:	8082                	ret

0000000080002d50 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	1000                	addi	s0,sp,32
    80002d5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	ece080e7          	jalr	-306(ra) # 80002c2a <argraw>
    80002d64:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d66:	4501                	li	a0,0
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	64a2                	ld	s1,8(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	1000                	addi	s0,sp,32
    80002d7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	eac080e7          	jalr	-340(ra) # 80002c2a <argraw>
    80002d86:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d88:	4501                	li	a0,0
    80002d8a:	60e2                	ld	ra,24(sp)
    80002d8c:	6442                	ld	s0,16(sp)
    80002d8e:	64a2                	ld	s1,8(sp)
    80002d90:	6105                	addi	sp,sp,32
    80002d92:	8082                	ret

0000000080002d94 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	e04a                	sd	s2,0(sp)
    80002d9e:	1000                	addi	s0,sp,32
    80002da0:	84ae                	mv	s1,a1
    80002da2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	e86080e7          	jalr	-378(ra) # 80002c2a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dac:	864a                	mv	a2,s2
    80002dae:	85a6                	mv	a1,s1
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	f54080e7          	jalr	-172(ra) # 80002d04 <fetchstr>
}
    80002db8:	60e2                	ld	ra,24(sp)
    80002dba:	6442                	ld	s0,16(sp)
    80002dbc:	64a2                	ld	s1,8(sp)
    80002dbe:	6902                	ld	s2,0(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <syscall>:
[SYS_cancelthrdstop]   sys_cancelthrdstop,
};

void
syscall(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	e04a                	sd	s2,0(sp)
    80002dce:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	c3e080e7          	jalr	-962(ra) # 80001a0e <myproc>
    80002dd8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dda:	6785                	lui	a5,0x1
    80002ddc:	97aa                	add	a5,a5,a0
    80002dde:	0a87b903          	ld	s2,168(a5) # 10a8 <_entry-0x7fffef58>
    80002de2:	0a893783          	ld	a5,168(s2)
    80002de6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dea:	37fd                	addiw	a5,a5,-1
    80002dec:	475d                	li	a4,23
    80002dee:	00f76f63          	bltu	a4,a5,80002e0c <syscall+0x48>
    80002df2:	00369713          	slli	a4,a3,0x3
    80002df6:	00005797          	auipc	a5,0x5
    80002dfa:	62a78793          	addi	a5,a5,1578 # 80008420 <syscalls>
    80002dfe:	97ba                	add	a5,a5,a4
    80002e00:	639c                	ld	a5,0(a5)
    80002e02:	c789                	beqz	a5,80002e0c <syscall+0x48>
    p->trapframe->a0 = syscalls[num]();
    80002e04:	9782                	jalr	a5
    80002e06:	06a93823          	sd	a0,112(s2)
    80002e0a:	a015                	j	80002e2e <syscall+0x6a>
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    80002e0c:	6905                	lui	s2,0x1
    80002e0e:	1a890613          	addi	a2,s2,424 # 11a8 <_entry-0x7fffee58>
    printf("%d %s: unknown sys call %d\n",
    80002e12:	9626                	add	a2,a2,s1
    80002e14:	5c8c                	lw	a1,56(s1)
    80002e16:	00005517          	auipc	a0,0x5
    80002e1a:	5d250513          	addi	a0,a0,1490 # 800083e8 <states.0+0x148>
    80002e1e:	ffffd097          	auipc	ra,0xffffd
    80002e22:	776080e7          	jalr	1910(ra) # 80000594 <printf>
    p->trapframe->a0 = -1;
    80002e26:	94ca                	add	s1,s1,s2
    80002e28:	74dc                	ld	a5,168(s1)
    80002e2a:	577d                	li	a4,-1
    80002e2c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	64a2                	ld	s1,8(sp)
    80002e34:	6902                	ld	s2,0(sp)
    80002e36:	6105                	addi	sp,sp,32
    80002e38:	8082                	ret

0000000080002e3a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e3a:	1101                	addi	sp,sp,-32
    80002e3c:	ec06                	sd	ra,24(sp)
    80002e3e:	e822                	sd	s0,16(sp)
    80002e40:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e42:	fec40593          	addi	a1,s0,-20
    80002e46:	4501                	li	a0,0
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	f08080e7          	jalr	-248(ra) # 80002d50 <argint>
    return -1;
    80002e50:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e52:	00054963          	bltz	a0,80002e64 <sys_exit+0x2a>
  exit(n);
    80002e56:	fec42503          	lw	a0,-20(s0)
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	304080e7          	jalr	772(ra) # 8000215e <exit>
  return 0;  // not reached
    80002e62:	4781                	li	a5,0
}
    80002e64:	853e                	mv	a0,a5
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e6e:	1141                	addi	sp,sp,-16
    80002e70:	e406                	sd	ra,8(sp)
    80002e72:	e022                	sd	s0,0(sp)
    80002e74:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e76:	fffff097          	auipc	ra,0xfffff
    80002e7a:	b98080e7          	jalr	-1128(ra) # 80001a0e <myproc>
}
    80002e7e:	5d08                	lw	a0,56(a0)
    80002e80:	60a2                	ld	ra,8(sp)
    80002e82:	6402                	ld	s0,0(sp)
    80002e84:	0141                	addi	sp,sp,16
    80002e86:	8082                	ret

0000000080002e88 <sys_fork>:

uint64
sys_fork(void)
{
    80002e88:	1141                	addi	sp,sp,-16
    80002e8a:	e406                	sd	ra,8(sp)
    80002e8c:	e022                	sd	s0,0(sp)
    80002e8e:	0800                	addi	s0,sp,16
  return fork();
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	fb6080e7          	jalr	-74(ra) # 80001e46 <fork>
}
    80002e98:	60a2                	ld	ra,8(sp)
    80002e9a:	6402                	ld	s0,0(sp)
    80002e9c:	0141                	addi	sp,sp,16
    80002e9e:	8082                	ret

0000000080002ea0 <sys_wait>:

uint64
sys_wait(void)
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ea8:	fe840593          	addi	a1,s0,-24
    80002eac:	4501                	li	a0,0
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	ec4080e7          	jalr	-316(ra) # 80002d72 <argaddr>
    80002eb6:	87aa                	mv	a5,a0
    return -1;
    80002eb8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002eba:	0007c863          	bltz	a5,80002eca <sys_wait+0x2a>
  return wait(p);
    80002ebe:	fe843503          	ld	a0,-24(s0)
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	46c080e7          	jalr	1132(ra) # 8000232e <wait>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	6105                	addi	sp,sp,32
    80002ed0:	8082                	ret

0000000080002ed2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ed2:	7179                	addi	sp,sp,-48
    80002ed4:	f406                	sd	ra,40(sp)
    80002ed6:	f022                	sd	s0,32(sp)
    80002ed8:	ec26                	sd	s1,24(sp)
    80002eda:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002edc:	fdc40593          	addi	a1,s0,-36
    80002ee0:	4501                	li	a0,0
    80002ee2:	00000097          	auipc	ra,0x0
    80002ee6:	e6e080e7          	jalr	-402(ra) # 80002d50 <argint>
    return -1;
    80002eea:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002eec:	02054263          	bltz	a0,80002f10 <sys_sbrk+0x3e>
  addr = myproc()->sz;
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	b1e080e7          	jalr	-1250(ra) # 80001a0e <myproc>
    80002ef8:	6785                	lui	a5,0x1
    80002efa:	953e                	add	a0,a0,a5
    80002efc:	09852483          	lw	s1,152(a0)
  if(growproc(n) < 0)
    80002f00:	fdc42503          	lw	a0,-36(s0)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	ebc080e7          	jalr	-324(ra) # 80001dc0 <growproc>
    80002f0c:	00054863          	bltz	a0,80002f1c <sys_sbrk+0x4a>
    return -1;
  return addr;
}
    80002f10:	8526                	mv	a0,s1
    80002f12:	70a2                	ld	ra,40(sp)
    80002f14:	7402                	ld	s0,32(sp)
    80002f16:	64e2                	ld	s1,24(sp)
    80002f18:	6145                	addi	sp,sp,48
    80002f1a:	8082                	ret
    return -1;
    80002f1c:	54fd                	li	s1,-1
    80002f1e:	bfcd                	j	80002f10 <sys_sbrk+0x3e>

0000000080002f20 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f20:	7139                	addi	sp,sp,-64
    80002f22:	fc06                	sd	ra,56(sp)
    80002f24:	f822                	sd	s0,48(sp)
    80002f26:	f426                	sd	s1,40(sp)
    80002f28:	f04a                	sd	s2,32(sp)
    80002f2a:	ec4e                	sd	s3,24(sp)
    80002f2c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f2e:	fcc40593          	addi	a1,s0,-52
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	e1c080e7          	jalr	-484(ra) # 80002d50 <argint>
    return -1;
    80002f3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f3e:	06054563          	bltz	a0,80002fa8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002f42:	00055517          	auipc	a0,0x55
    80002f46:	56650513          	addi	a0,a0,1382 # 800584a8 <tickslock>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	cbc080e7          	jalr	-836(ra) # 80000c06 <acquire>
  ticks0 = ticks;
    80002f52:	00006917          	auipc	s2,0x6
    80002f56:	0ce92903          	lw	s2,206(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f5a:	fcc42783          	lw	a5,-52(s0)
    80002f5e:	cf85                	beqz	a5,80002f96 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f60:	00055997          	auipc	s3,0x55
    80002f64:	54898993          	addi	s3,s3,1352 # 800584a8 <tickslock>
    80002f68:	00006497          	auipc	s1,0x6
    80002f6c:	0b848493          	addi	s1,s1,184 # 80009020 <ticks>
    if(myproc()->killed){
    80002f70:	fffff097          	auipc	ra,0xfffff
    80002f74:	a9e080e7          	jalr	-1378(ra) # 80001a0e <myproc>
    80002f78:	591c                	lw	a5,48(a0)
    80002f7a:	ef9d                	bnez	a5,80002fb8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f7c:	85ce                	mv	a1,s3
    80002f7e:	8526                	mv	a0,s1
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	330080e7          	jalr	816(ra) # 800022b0 <sleep>
  while(ticks - ticks0 < n){
    80002f88:	409c                	lw	a5,0(s1)
    80002f8a:	412787bb          	subw	a5,a5,s2
    80002f8e:	fcc42703          	lw	a4,-52(s0)
    80002f92:	fce7efe3          	bltu	a5,a4,80002f70 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f96:	00055517          	auipc	a0,0x55
    80002f9a:	51250513          	addi	a0,a0,1298 # 800584a8 <tickslock>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	d1c080e7          	jalr	-740(ra) # 80000cba <release>
  return 0;
    80002fa6:	4781                	li	a5,0
}
    80002fa8:	853e                	mv	a0,a5
    80002faa:	70e2                	ld	ra,56(sp)
    80002fac:	7442                	ld	s0,48(sp)
    80002fae:	74a2                	ld	s1,40(sp)
    80002fb0:	7902                	ld	s2,32(sp)
    80002fb2:	69e2                	ld	s3,24(sp)
    80002fb4:	6121                	addi	sp,sp,64
    80002fb6:	8082                	ret
      release(&tickslock);
    80002fb8:	00055517          	auipc	a0,0x55
    80002fbc:	4f050513          	addi	a0,a0,1264 # 800584a8 <tickslock>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	cfa080e7          	jalr	-774(ra) # 80000cba <release>
      return -1;
    80002fc8:	57fd                	li	a5,-1
    80002fca:	bff9                	j	80002fa8 <sys_sleep+0x88>

0000000080002fcc <sys_kill>:

uint64
sys_kill(void)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fd4:	fec40593          	addi	a1,s0,-20
    80002fd8:	4501                	li	a0,0
    80002fda:	00000097          	auipc	ra,0x0
    80002fde:	d76080e7          	jalr	-650(ra) # 80002d50 <argint>
    80002fe2:	87aa                	mv	a5,a0
    return -1;
    80002fe4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002fe6:	0007c863          	bltz	a5,80002ff6 <sys_kill+0x2a>
  return kill(pid);
    80002fea:	fec42503          	lw	a0,-20(s0)
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	4b8080e7          	jalr	1208(ra) # 800024a6 <kill>
}
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	6105                	addi	sp,sp,32
    80002ffc:	8082                	ret

0000000080002ffe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003008:	00055517          	auipc	a0,0x55
    8000300c:	4a050513          	addi	a0,a0,1184 # 800584a8 <tickslock>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	bf6080e7          	jalr	-1034(ra) # 80000c06 <acquire>
  xticks = ticks;
    80003018:	00006497          	auipc	s1,0x6
    8000301c:	0084a483          	lw	s1,8(s1) # 80009020 <ticks>
  release(&tickslock);
    80003020:	00055517          	auipc	a0,0x55
    80003024:	48850513          	addi	a0,a0,1160 # 800584a8 <tickslock>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	c92080e7          	jalr	-878(ra) # 80000cba <release>
  return xticks;
}
    80003030:	02049513          	slli	a0,s1,0x20
    80003034:	9101                	srli	a0,a0,0x20
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <sys_thrdstop>:


// for mp3
uint64
sys_thrdstop(void)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	1000                	addi	s0,sp,32
  int interval, thrdstop_context_id;
  uint64 handler;
  if (argint(0, &interval) < 0)
    80003048:	fec40593          	addi	a1,s0,-20
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	d02080e7          	jalr	-766(ra) # 80002d50 <argint>
    return -1;
    80003056:	57fd                	li	a5,-1
  if (argint(0, &interval) < 0)
    80003058:	04054e63          	bltz	a0,800030b4 <sys_thrdstop+0x74>
  if (argint(1, &thrdstop_context_id) < 0)
    8000305c:	fe840593          	addi	a1,s0,-24
    80003060:	4505                	li	a0,1
    80003062:	00000097          	auipc	ra,0x0
    80003066:	cee080e7          	jalr	-786(ra) # 80002d50 <argint>
    return -1;
    8000306a:	57fd                	li	a5,-1
  if (argint(1, &thrdstop_context_id) < 0)
    8000306c:	04054463          	bltz	a0,800030b4 <sys_thrdstop+0x74>
  if (argaddr(2, &handler) < 0)
    80003070:	fe040593          	addi	a1,s0,-32
    80003074:	4509                	li	a0,2
    80003076:	00000097          	auipc	ra,0x0
    8000307a:	cfc080e7          	jalr	-772(ra) # 80002d72 <argaddr>
    return -1;
    8000307e:	57fd                	li	a5,-1
  if (argaddr(2, &handler) < 0)
    80003080:	02054a63          	bltz	a0,800030b4 <sys_thrdstop+0x74>

  struct proc *p = myproc();
    80003084:	fffff097          	auipc	ra,0xfffff
    80003088:	98a080e7          	jalr	-1654(ra) # 80001a0e <myproc>
  p->thrdstop_ticks = 0;
    8000308c:	02052e23          	sw	zero,60(a0)
  p->thrdstop_interval = interval;
    80003090:	fec42783          	lw	a5,-20(s0)
    80003094:	c13c                	sw	a5,64(a0)
  p->thrdstop_handler_pointer = handler;
    80003096:	fe043783          	ld	a5,-32(s0)
    8000309a:	e53c                	sd	a5,72(a0)
  
  if(thrdstop_context_id == -1){
    8000309c:	fe842783          	lw	a5,-24(s0)
    800030a0:	577d                	li	a4,-1
    800030a2:	00e78e63          	beq	a5,a4,800030be <sys_thrdstop+0x7e>
	  }
      }
      return -1;
  }

  p->thrdstop_context_used[thrdstop_context_id] = 1;
    800030a6:	41478713          	addi	a4,a5,1044 # 1414 <_entry-0x7fffebec>
    800030aa:	070a                	slli	a4,a4,0x2
    800030ac:	972a                	add	a4,a4,a0
    800030ae:	4685                	li	a3,1
    800030b0:	c314                	sw	a3,0(a4)
  p->thrdstop_context_id = thrdstop_context_id;
    800030b2:	c17c                	sw	a5,68(a0)
  return thrdstop_context_id;
}
    800030b4:	853e                	mv	a0,a5
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	6105                	addi	sp,sp,32
    800030bc:	8082                	ret
    800030be:	6705                	lui	a4,0x1
    800030c0:	05070713          	addi	a4,a4,80 # 1050 <_entry-0x7fffefb0>
    800030c4:	972a                	add	a4,a4,a0
      for(int i = 0;i < MAX_THRD_NUM;i++){
    800030c6:	4781                	li	a5,0
    800030c8:	4641                	li	a2,16
	  if(!p->thrdstop_context_used[i]) {
    800030ca:	4314                	lw	a3,0(a4)
    800030cc:	c699                	beqz	a3,800030da <sys_thrdstop+0x9a>
      for(int i = 0;i < MAX_THRD_NUM;i++){
    800030ce:	2785                	addiw	a5,a5,1
    800030d0:	0711                	addi	a4,a4,4
    800030d2:	fec79ce3          	bne	a5,a2,800030ca <sys_thrdstop+0x8a>
      return -1;
    800030d6:	57fd                	li	a5,-1
    800030d8:	bff1                	j	800030b4 <sys_thrdstop+0x74>
	      p->thrdstop_context_id = i;
    800030da:	c17c                	sw	a5,68(a0)
	      p->thrdstop_context_used[i] = 1;
    800030dc:	41478713          	addi	a4,a5,1044
    800030e0:	070a                	slli	a4,a4,0x2
    800030e2:	953a                	add	a0,a0,a4
    800030e4:	4705                	li	a4,1
    800030e6:	c118                	sw	a4,0(a0)
	      return i;
    800030e8:	b7f1                	j	800030b4 <sys_thrdstop+0x74>

00000000800030ea <sys_cancelthrdstop>:

// for mp3
uint64
sys_cancelthrdstop(void)
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	1000                	addi	s0,sp,32
  int thrdstop_context_id;
  if (argint(0, &thrdstop_context_id) < 0)
    800030f2:	fec40593          	addi	a1,s0,-20
    800030f6:	4501                	li	a0,0
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	c58080e7          	jalr	-936(ra) # 80002d50 <argint>
    return -1;
    80003100:	567d                	li	a2,-1
  if (argint(0, &thrdstop_context_id) < 0)
    80003102:	0c054a63          	bltz	a0,800031d6 <sys_cancelthrdstop+0xec>
  struct proc *p = myproc();
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	908080e7          	jalr	-1784(ra) # 80001a0e <myproc>
  p->thrdstop_interval = -1;
    8000310e:	57fd                	li	a5,-1
    80003110:	c13c                	sw	a5,64(a0)
  int res = p->thrdstop_ticks;
    80003112:	5d50                	lw	a2,60(a0)
  int i = thrdstop_context_id;
    80003114:	fec42783          	lw	a5,-20(s0)
  if (i >= 0 && p->thrdstop_context_used[i]){
    80003118:	0a07cf63          	bltz	a5,800031d6 <sys_cancelthrdstop+0xec>
    8000311c:	41478793          	addi	a5,a5,1044
    80003120:	078a                	slli	a5,a5,0x2
    80003122:	97aa                	add	a5,a5,a0
    80003124:	439c                	lw	a5,0(a5)
    80003126:	cbc5                	beqz	a5,800031d6 <sys_cancelthrdstop+0xec>
    struct thrd_context_data *thcd = &(p->thrdstop_context[p->thrdstop_context_id]);
    80003128:	4174                	lw	a3,68(a0)
    struct trapframe *tf = p->trapframe;
    8000312a:	6785                	lui	a5,0x1
    8000312c:	97aa                	add	a5,a5,a0
    8000312e:	77d8                	ld	a4,168(a5)
    thcd->s_regs[0] = tf->s0;
    80003130:	732c                	ld	a1,96(a4)
    80003132:	00869793          	slli	a5,a3,0x8
    80003136:	97aa                	add	a5,a5,a0
    80003138:	ebac                	sd	a1,80(a5)
    thcd->s_regs[1] = tf->s1;
    8000313a:	772c                	ld	a1,104(a4)
    8000313c:	efac                	sd	a1,88(a5)
    thcd->s_regs[2] = tf->s2;
    8000313e:	7b4c                	ld	a1,176(a4)
    80003140:	f3ac                	sd	a1,96(a5)
    thcd->s_regs[3] = tf->s3;
    80003142:	7f4c                	ld	a1,184(a4)
    80003144:	f7ac                	sd	a1,104(a5)
    thcd->s_regs[4] = tf->s4;
    80003146:	636c                	ld	a1,192(a4)
    80003148:	fbac                	sd	a1,112(a5)
    thcd->s_regs[5] = tf->s5;
    8000314a:	676c                	ld	a1,200(a4)
    8000314c:	ffac                	sd	a1,120(a5)
    thcd->s_regs[6] = tf->s6;
    8000314e:	6b6c                	ld	a1,208(a4)
    80003150:	e3cc                	sd	a1,128(a5)
    thcd->s_regs[7] = tf->s7;
    80003152:	6f6c                	ld	a1,216(a4)
    80003154:	e7cc                	sd	a1,136(a5)
    thcd->s_regs[8] = tf->s8;
    80003156:	736c                	ld	a1,224(a4)
    80003158:	ebcc                	sd	a1,144(a5)
    thcd->s_regs[9] = tf->s9;
    8000315a:	776c                	ld	a1,232(a4)
    8000315c:	efcc                	sd	a1,152(a5)
    thcd->s_regs[10] = tf->s10;
    8000315e:	7b6c                	ld	a1,240(a4)
    80003160:	f3cc                	sd	a1,160(a5)
    thcd->s_regs[11] = tf->s11;
    80003162:	7f6c                	ld	a1,248(a4)
    80003164:	f7cc                	sd	a1,168(a5)
    thcd->ra = tf->ra;
    80003166:	770c                	ld	a1,40(a4)
    80003168:	fbcc                	sd	a1,176(a5)
    thcd->sp = tf->sp;
    8000316a:	7b0c                	ld	a1,48(a4)
    8000316c:	ffcc                	sd	a1,184(a5)
    thcd->t_regs[0] = tf->t0;
    8000316e:	672c                	ld	a1,72(a4)
    80003170:	e3ec                	sd	a1,192(a5)
    thcd->t_regs[1] = tf->t1;
    80003172:	6b2c                	ld	a1,80(a4)
    80003174:	e7ec                	sd	a1,200(a5)
    thcd->t_regs[2] = tf->t2;
    80003176:	6f2c                	ld	a1,88(a4)
    80003178:	ebec                	sd	a1,208(a5)
    thcd->t_regs[3] = tf->t3;
    8000317a:	10073583          	ld	a1,256(a4)
    8000317e:	efec                	sd	a1,216(a5)
    thcd->t_regs[4] = tf->t4;
    80003180:	10873583          	ld	a1,264(a4)
    80003184:	f3ec                	sd	a1,224(a5)
    thcd->t_regs[5] = tf->t5;
    80003186:	11073583          	ld	a1,272(a4)
    8000318a:	f7ec                	sd	a1,232(a5)
    thcd->t_regs[6] = tf->t6;
    8000318c:	11873583          	ld	a1,280(a4)
    80003190:	fbec                	sd	a1,240(a5)
    thcd->a_regs[0] = tf->a0;
    80003192:	7b2c                	ld	a1,112(a4)
    80003194:	ffec                	sd	a1,248(a5)
    thcd->a_regs[1] = tf->a1;
    80003196:	7f2c                	ld	a1,120(a4)
    80003198:	10b7b023          	sd	a1,256(a5) # 1100 <_entry-0x7fffef00>
    thcd->a_regs[2] = tf->a2;
    8000319c:	634c                	ld	a1,128(a4)
    8000319e:	0685                	addi	a3,a3,1
    800031a0:	06a2                	slli	a3,a3,0x8
    800031a2:	9536                	add	a0,a0,a3
    800031a4:	e50c                	sd	a1,8(a0)
    thcd->a_regs[3] = tf->a3;
    800031a6:	6754                	ld	a3,136(a4)
    800031a8:	10d7b823          	sd	a3,272(a5)
    thcd->a_regs[4] = tf->a4;
    800031ac:	6b54                	ld	a3,144(a4)
    800031ae:	10d7bc23          	sd	a3,280(a5)
    thcd->a_regs[5] = tf->a5;
    800031b2:	6f54                	ld	a3,152(a4)
    800031b4:	12d7b023          	sd	a3,288(a5)
    thcd->a_regs[6] = tf->a6;
    800031b8:	7354                	ld	a3,160(a4)
    800031ba:	12d7b423          	sd	a3,296(a5)
    thcd->a_regs[7] = tf->a7;
    800031be:	7754                	ld	a3,168(a4)
    800031c0:	12d7b823          	sd	a3,304(a5)
    thcd->gp = tf->gp;
    800031c4:	7f14                	ld	a3,56(a4)
    800031c6:	12d7bc23          	sd	a3,312(a5)
    thcd->tp = tf->tp;
    800031ca:	6334                	ld	a3,64(a4)
    800031cc:	14d7b023          	sd	a3,320(a5)
    thcd->epc = tf->epc;
    800031d0:	6f18                	ld	a4,24(a4)
    800031d2:	14e7b423          	sd	a4,328(a5)
  }
  return res;
}
    800031d6:	8532                	mv	a0,a2
    800031d8:	60e2                	ld	ra,24(sp)
    800031da:	6442                	ld	s0,16(sp)
    800031dc:	6105                	addi	sp,sp,32
    800031de:	8082                	ret

00000000800031e0 <sys_thrdresume>:

// for mp3
uint64
sys_thrdresume(void)
{
    800031e0:	1101                	addi	sp,sp,-32
    800031e2:	ec06                	sd	ra,24(sp)
    800031e4:	e822                	sd	s0,16(sp)
    800031e6:	1000                	addi	s0,sp,32
  int  thrdstop_context_id, is_exit;
  if (argint(0, &thrdstop_context_id) < 0)
    800031e8:	fec40593          	addi	a1,s0,-20
    800031ec:	4501                	li	a0,0
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	b62080e7          	jalr	-1182(ra) # 80002d50 <argint>
    return -1;
    800031f6:	57fd                	li	a5,-1
  if (argint(0, &thrdstop_context_id) < 0)
    800031f8:	02054e63          	bltz	a0,80003234 <sys_thrdresume+0x54>
  if (argint(1, &is_exit) < 0)
    800031fc:	fe840593          	addi	a1,s0,-24
    80003200:	4505                	li	a0,1
    80003202:	00000097          	auipc	ra,0x0
    80003206:	b4e080e7          	jalr	-1202(ra) # 80002d50 <argint>
    return -1;
    8000320a:	57fd                	li	a5,-1
  if (argint(1, &is_exit) < 0)
    8000320c:	02054463          	bltz	a0,80003234 <sys_thrdresume+0x54>
  struct proc * p = myproc();
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	7fe080e7          	jalr	2046(ra) # 80001a0e <myproc>
  if(is_exit) {
    80003218:	fe842783          	lw	a5,-24(s0)
    8000321c:	c38d                	beqz	a5,8000323e <sys_thrdresume+0x5e>
      p->thrdstop_context_used[thrdstop_context_id] = 0;
    8000321e:	fec42783          	lw	a5,-20(s0)
    80003222:	41478793          	addi	a5,a5,1044
    80003226:	078a                	slli	a5,a5,0x2
    80003228:	97aa                	add	a5,a5,a0
    8000322a:	0007a023          	sw	zero,0(a5)
      p->thrdstop_interval = -1;
    8000322e:	57fd                	li	a5,-1
    80003230:	c13c                	sw	a5,64(a0)
    tf->a7 = thcd->a_regs[7];
    tf->gp = thcd->gp;
    tf->tp = thcd->tp;
    tf->epc = thcd->epc;
  }
  return 0;
    80003232:	4781                	li	a5,0
}
    80003234:	853e                	mv	a0,a5
    80003236:	60e2                	ld	ra,24(sp)
    80003238:	6442                	ld	s0,16(sp)
    8000323a:	6105                	addi	sp,sp,32
    8000323c:	8082                	ret
    struct thrd_context_data *thcd = &(p->thrdstop_context[p->thrdstop_context_id]);
    8000323e:	4174                	lw	a3,68(a0)
    struct trapframe *tf = p->trapframe;
    80003240:	6785                	lui	a5,0x1
    80003242:	97aa                	add	a5,a5,a0
    80003244:	77d8                	ld	a4,168(a5)
    tf->s0 = thcd->s_regs[0];
    80003246:	00869793          	slli	a5,a3,0x8
    8000324a:	97aa                	add	a5,a5,a0
    8000324c:	6bb0                	ld	a2,80(a5)
    8000324e:	f330                	sd	a2,96(a4)
    tf->s1 = thcd->s_regs[1];
    80003250:	6fb0                	ld	a2,88(a5)
    80003252:	f730                	sd	a2,104(a4)
    tf->s2 = thcd->s_regs[2];
    80003254:	73b0                	ld	a2,96(a5)
    80003256:	fb50                	sd	a2,176(a4)
    tf->s3 = thcd->s_regs[3];
    80003258:	77b0                	ld	a2,104(a5)
    8000325a:	ff50                	sd	a2,184(a4)
    tf->s4 = thcd->s_regs[4];
    8000325c:	7bb0                	ld	a2,112(a5)
    8000325e:	e370                	sd	a2,192(a4)
    tf->s5 = thcd->s_regs[5];
    80003260:	7fb0                	ld	a2,120(a5)
    80003262:	e770                	sd	a2,200(a4)
    tf->s6 = thcd->s_regs[6];
    80003264:	63d0                	ld	a2,128(a5)
    80003266:	eb70                	sd	a2,208(a4)
    tf->s7 = thcd->s_regs[7];
    80003268:	67d0                	ld	a2,136(a5)
    8000326a:	ef70                	sd	a2,216(a4)
    tf->s8 = thcd->s_regs[8];
    8000326c:	6bd0                	ld	a2,144(a5)
    8000326e:	f370                	sd	a2,224(a4)
    tf->s9 = thcd->s_regs[9];
    80003270:	6fd0                	ld	a2,152(a5)
    80003272:	f770                	sd	a2,232(a4)
    tf->s10 = thcd->s_regs[10];
    80003274:	73d0                	ld	a2,160(a5)
    80003276:	fb70                	sd	a2,240(a4)
    tf->s11 = thcd->s_regs[11];
    80003278:	77d0                	ld	a2,168(a5)
    8000327a:	ff70                	sd	a2,248(a4)
    tf->ra = thcd->ra;
    8000327c:	7bd0                	ld	a2,176(a5)
    8000327e:	f710                	sd	a2,40(a4)
    tf->sp = thcd->sp;
    80003280:	7fd0                	ld	a2,184(a5)
    80003282:	fb10                	sd	a2,48(a4)
    tf->t0 = thcd->t_regs[0];
    80003284:	63f0                	ld	a2,192(a5)
    80003286:	e730                	sd	a2,72(a4)
    tf->t1 = thcd->t_regs[1];
    80003288:	67f0                	ld	a2,200(a5)
    8000328a:	eb30                	sd	a2,80(a4)
    tf->t2 = thcd->t_regs[2];
    8000328c:	6bf0                	ld	a2,208(a5)
    8000328e:	ef30                	sd	a2,88(a4)
    tf->t3 = thcd->t_regs[3];
    80003290:	6ff0                	ld	a2,216(a5)
    80003292:	10c73023          	sd	a2,256(a4)
    tf->t4 = thcd->t_regs[4];
    80003296:	73f0                	ld	a2,224(a5)
    80003298:	10c73423          	sd	a2,264(a4)
    tf->t5 = thcd->t_regs[5];
    8000329c:	77f0                	ld	a2,232(a5)
    8000329e:	10c73823          	sd	a2,272(a4)
    tf->t6 = thcd->t_regs[6];
    800032a2:	7bf0                	ld	a2,240(a5)
    800032a4:	10c73c23          	sd	a2,280(a4)
    tf->a0 = thcd->a_regs[0];
    800032a8:	7ff0                	ld	a2,248(a5)
    800032aa:	fb30                	sd	a2,112(a4)
    tf->a1 = thcd->a_regs[1];
    800032ac:	1007b603          	ld	a2,256(a5) # 1100 <_entry-0x7fffef00>
    800032b0:	ff30                	sd	a2,120(a4)
    tf->a2 = thcd->a_regs[2];
    800032b2:	0685                	addi	a3,a3,1
    800032b4:	06a2                	slli	a3,a3,0x8
    800032b6:	9536                	add	a0,a0,a3
    800032b8:	6514                	ld	a3,8(a0)
    800032ba:	e354                	sd	a3,128(a4)
    tf->a3 = thcd->a_regs[3];
    800032bc:	1107b683          	ld	a3,272(a5)
    800032c0:	e754                	sd	a3,136(a4)
    tf->a4 = thcd->a_regs[4];
    800032c2:	1187b683          	ld	a3,280(a5)
    800032c6:	eb54                	sd	a3,144(a4)
    tf->a5 = thcd->a_regs[5];
    800032c8:	1207b683          	ld	a3,288(a5)
    800032cc:	ef54                	sd	a3,152(a4)
    tf->a6 = thcd->a_regs[6];
    800032ce:	1287b683          	ld	a3,296(a5)
    800032d2:	f354                	sd	a3,160(a4)
    tf->a7 = thcd->a_regs[7];
    800032d4:	1307b683          	ld	a3,304(a5)
    800032d8:	f754                	sd	a3,168(a4)
    tf->gp = thcd->gp;
    800032da:	1387b683          	ld	a3,312(a5)
    800032de:	ff14                	sd	a3,56(a4)
    tf->tp = thcd->tp;
    800032e0:	1407b683          	ld	a3,320(a5)
    800032e4:	e334                	sd	a3,64(a4)
    tf->epc = thcd->epc;
    800032e6:	1487b783          	ld	a5,328(a5)
    800032ea:	ef1c                	sd	a5,24(a4)
  return 0;
    800032ec:	4781                	li	a5,0
    800032ee:	b799                	j	80003234 <sys_thrdresume+0x54>

00000000800032f0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032f0:	7179                	addi	sp,sp,-48
    800032f2:	f406                	sd	ra,40(sp)
    800032f4:	f022                	sd	s0,32(sp)
    800032f6:	ec26                	sd	s1,24(sp)
    800032f8:	e84a                	sd	s2,16(sp)
    800032fa:	e44e                	sd	s3,8(sp)
    800032fc:	e052                	sd	s4,0(sp)
    800032fe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003300:	00005597          	auipc	a1,0x5
    80003304:	1e858593          	addi	a1,a1,488 # 800084e8 <syscalls+0xc8>
    80003308:	00055517          	auipc	a0,0x55
    8000330c:	1b850513          	addi	a0,a0,440 # 800584c0 <bcache>
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	866080e7          	jalr	-1946(ra) # 80000b76 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003318:	0005d797          	auipc	a5,0x5d
    8000331c:	1a878793          	addi	a5,a5,424 # 800604c0 <bcache+0x8000>
    80003320:	0005d717          	auipc	a4,0x5d
    80003324:	40870713          	addi	a4,a4,1032 # 80060728 <bcache+0x8268>
    80003328:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000332c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003330:	00055497          	auipc	s1,0x55
    80003334:	1a848493          	addi	s1,s1,424 # 800584d8 <bcache+0x18>
    b->next = bcache.head.next;
    80003338:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000333a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000333c:	00005a17          	auipc	s4,0x5
    80003340:	1b4a0a13          	addi	s4,s4,436 # 800084f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003344:	2b893783          	ld	a5,696(s2)
    80003348:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000334a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000334e:	85d2                	mv	a1,s4
    80003350:	01048513          	addi	a0,s1,16
    80003354:	00001097          	auipc	ra,0x1
    80003358:	4c6080e7          	jalr	1222(ra) # 8000481a <initsleeplock>
    bcache.head.next->prev = b;
    8000335c:	2b893783          	ld	a5,696(s2)
    80003360:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003362:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003366:	45848493          	addi	s1,s1,1112
    8000336a:	fd349de3          	bne	s1,s3,80003344 <binit+0x54>
  }
}
    8000336e:	70a2                	ld	ra,40(sp)
    80003370:	7402                	ld	s0,32(sp)
    80003372:	64e2                	ld	s1,24(sp)
    80003374:	6942                	ld	s2,16(sp)
    80003376:	69a2                	ld	s3,8(sp)
    80003378:	6a02                	ld	s4,0(sp)
    8000337a:	6145                	addi	sp,sp,48
    8000337c:	8082                	ret

000000008000337e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000337e:	7179                	addi	sp,sp,-48
    80003380:	f406                	sd	ra,40(sp)
    80003382:	f022                	sd	s0,32(sp)
    80003384:	ec26                	sd	s1,24(sp)
    80003386:	e84a                	sd	s2,16(sp)
    80003388:	e44e                	sd	s3,8(sp)
    8000338a:	1800                	addi	s0,sp,48
    8000338c:	892a                	mv	s2,a0
    8000338e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003390:	00055517          	auipc	a0,0x55
    80003394:	13050513          	addi	a0,a0,304 # 800584c0 <bcache>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	86e080e7          	jalr	-1938(ra) # 80000c06 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033a0:	0005d497          	auipc	s1,0x5d
    800033a4:	3d84b483          	ld	s1,984(s1) # 80060778 <bcache+0x82b8>
    800033a8:	0005d797          	auipc	a5,0x5d
    800033ac:	38078793          	addi	a5,a5,896 # 80060728 <bcache+0x8268>
    800033b0:	02f48f63          	beq	s1,a5,800033ee <bread+0x70>
    800033b4:	873e                	mv	a4,a5
    800033b6:	a021                	j	800033be <bread+0x40>
    800033b8:	68a4                	ld	s1,80(s1)
    800033ba:	02e48a63          	beq	s1,a4,800033ee <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800033be:	449c                	lw	a5,8(s1)
    800033c0:	ff279ce3          	bne	a5,s2,800033b8 <bread+0x3a>
    800033c4:	44dc                	lw	a5,12(s1)
    800033c6:	ff3799e3          	bne	a5,s3,800033b8 <bread+0x3a>
      b->refcnt++;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033d0:	00055517          	auipc	a0,0x55
    800033d4:	0f050513          	addi	a0,a0,240 # 800584c0 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8e2080e7          	jalr	-1822(ra) # 80000cba <release>
      acquiresleep(&b->lock);
    800033e0:	01048513          	addi	a0,s1,16
    800033e4:	00001097          	auipc	ra,0x1
    800033e8:	470080e7          	jalr	1136(ra) # 80004854 <acquiresleep>
      return b;
    800033ec:	a8b9                	j	8000344a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033ee:	0005d497          	auipc	s1,0x5d
    800033f2:	3824b483          	ld	s1,898(s1) # 80060770 <bcache+0x82b0>
    800033f6:	0005d797          	auipc	a5,0x5d
    800033fa:	33278793          	addi	a5,a5,818 # 80060728 <bcache+0x8268>
    800033fe:	00f48863          	beq	s1,a5,8000340e <bread+0x90>
    80003402:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003404:	40bc                	lw	a5,64(s1)
    80003406:	cf81                	beqz	a5,8000341e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003408:	64a4                	ld	s1,72(s1)
    8000340a:	fee49de3          	bne	s1,a4,80003404 <bread+0x86>
  panic("bget: no buffers");
    8000340e:	00005517          	auipc	a0,0x5
    80003412:	0ea50513          	addi	a0,a0,234 # 800084f8 <syscalls+0xd8>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	134080e7          	jalr	308(ra) # 8000054a <panic>
      b->dev = dev;
    8000341e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003422:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003426:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000342a:	4785                	li	a5,1
    8000342c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000342e:	00055517          	auipc	a0,0x55
    80003432:	09250513          	addi	a0,a0,146 # 800584c0 <bcache>
    80003436:	ffffe097          	auipc	ra,0xffffe
    8000343a:	884080e7          	jalr	-1916(ra) # 80000cba <release>
      acquiresleep(&b->lock);
    8000343e:	01048513          	addi	a0,s1,16
    80003442:	00001097          	auipc	ra,0x1
    80003446:	412080e7          	jalr	1042(ra) # 80004854 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000344a:	409c                	lw	a5,0(s1)
    8000344c:	cb89                	beqz	a5,8000345e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000344e:	8526                	mv	a0,s1
    80003450:	70a2                	ld	ra,40(sp)
    80003452:	7402                	ld	s0,32(sp)
    80003454:	64e2                	ld	s1,24(sp)
    80003456:	6942                	ld	s2,16(sp)
    80003458:	69a2                	ld	s3,8(sp)
    8000345a:	6145                	addi	sp,sp,48
    8000345c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000345e:	4581                	li	a1,0
    80003460:	8526                	mv	a0,s1
    80003462:	00003097          	auipc	ra,0x3
    80003466:	f94080e7          	jalr	-108(ra) # 800063f6 <virtio_disk_rw>
    b->valid = 1;
    8000346a:	4785                	li	a5,1
    8000346c:	c09c                	sw	a5,0(s1)
  return b;
    8000346e:	b7c5                	j	8000344e <bread+0xd0>

0000000080003470 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	1000                	addi	s0,sp,32
    8000347a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000347c:	0541                	addi	a0,a0,16
    8000347e:	00001097          	auipc	ra,0x1
    80003482:	470080e7          	jalr	1136(ra) # 800048ee <holdingsleep>
    80003486:	cd01                	beqz	a0,8000349e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003488:	4585                	li	a1,1
    8000348a:	8526                	mv	a0,s1
    8000348c:	00003097          	auipc	ra,0x3
    80003490:	f6a080e7          	jalr	-150(ra) # 800063f6 <virtio_disk_rw>
}
    80003494:	60e2                	ld	ra,24(sp)
    80003496:	6442                	ld	s0,16(sp)
    80003498:	64a2                	ld	s1,8(sp)
    8000349a:	6105                	addi	sp,sp,32
    8000349c:	8082                	ret
    panic("bwrite");
    8000349e:	00005517          	auipc	a0,0x5
    800034a2:	07250513          	addi	a0,a0,114 # 80008510 <syscalls+0xf0>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	0a4080e7          	jalr	164(ra) # 8000054a <panic>

00000000800034ae <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034ae:	1101                	addi	sp,sp,-32
    800034b0:	ec06                	sd	ra,24(sp)
    800034b2:	e822                	sd	s0,16(sp)
    800034b4:	e426                	sd	s1,8(sp)
    800034b6:	e04a                	sd	s2,0(sp)
    800034b8:	1000                	addi	s0,sp,32
    800034ba:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034bc:	01050913          	addi	s2,a0,16
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	42c080e7          	jalr	1068(ra) # 800048ee <holdingsleep>
    800034ca:	c92d                	beqz	a0,8000353c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800034cc:	854a                	mv	a0,s2
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	3dc080e7          	jalr	988(ra) # 800048aa <releasesleep>

  acquire(&bcache.lock);
    800034d6:	00055517          	auipc	a0,0x55
    800034da:	fea50513          	addi	a0,a0,-22 # 800584c0 <bcache>
    800034de:	ffffd097          	auipc	ra,0xffffd
    800034e2:	728080e7          	jalr	1832(ra) # 80000c06 <acquire>
  b->refcnt--;
    800034e6:	40bc                	lw	a5,64(s1)
    800034e8:	37fd                	addiw	a5,a5,-1
    800034ea:	0007871b          	sext.w	a4,a5
    800034ee:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034f0:	eb05                	bnez	a4,80003520 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034f2:	68bc                	ld	a5,80(s1)
    800034f4:	64b8                	ld	a4,72(s1)
    800034f6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034f8:	64bc                	ld	a5,72(s1)
    800034fa:	68b8                	ld	a4,80(s1)
    800034fc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034fe:	0005d797          	auipc	a5,0x5d
    80003502:	fc278793          	addi	a5,a5,-62 # 800604c0 <bcache+0x8000>
    80003506:	2b87b703          	ld	a4,696(a5)
    8000350a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000350c:	0005d717          	auipc	a4,0x5d
    80003510:	21c70713          	addi	a4,a4,540 # 80060728 <bcache+0x8268>
    80003514:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003516:	2b87b703          	ld	a4,696(a5)
    8000351a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000351c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003520:	00055517          	auipc	a0,0x55
    80003524:	fa050513          	addi	a0,a0,-96 # 800584c0 <bcache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	792080e7          	jalr	1938(ra) # 80000cba <release>
}
    80003530:	60e2                	ld	ra,24(sp)
    80003532:	6442                	ld	s0,16(sp)
    80003534:	64a2                	ld	s1,8(sp)
    80003536:	6902                	ld	s2,0(sp)
    80003538:	6105                	addi	sp,sp,32
    8000353a:	8082                	ret
    panic("brelse");
    8000353c:	00005517          	auipc	a0,0x5
    80003540:	fdc50513          	addi	a0,a0,-36 # 80008518 <syscalls+0xf8>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	006080e7          	jalr	6(ra) # 8000054a <panic>

000000008000354c <bpin>:

void
bpin(struct buf *b) {
    8000354c:	1101                	addi	sp,sp,-32
    8000354e:	ec06                	sd	ra,24(sp)
    80003550:	e822                	sd	s0,16(sp)
    80003552:	e426                	sd	s1,8(sp)
    80003554:	1000                	addi	s0,sp,32
    80003556:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003558:	00055517          	auipc	a0,0x55
    8000355c:	f6850513          	addi	a0,a0,-152 # 800584c0 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	6a6080e7          	jalr	1702(ra) # 80000c06 <acquire>
  b->refcnt++;
    80003568:	40bc                	lw	a5,64(s1)
    8000356a:	2785                	addiw	a5,a5,1
    8000356c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000356e:	00055517          	auipc	a0,0x55
    80003572:	f5250513          	addi	a0,a0,-174 # 800584c0 <bcache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	744080e7          	jalr	1860(ra) # 80000cba <release>
}
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6105                	addi	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <bunpin>:

void
bunpin(struct buf *b) {
    80003588:	1101                	addi	sp,sp,-32
    8000358a:	ec06                	sd	ra,24(sp)
    8000358c:	e822                	sd	s0,16(sp)
    8000358e:	e426                	sd	s1,8(sp)
    80003590:	1000                	addi	s0,sp,32
    80003592:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003594:	00055517          	auipc	a0,0x55
    80003598:	f2c50513          	addi	a0,a0,-212 # 800584c0 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	66a080e7          	jalr	1642(ra) # 80000c06 <acquire>
  b->refcnt--;
    800035a4:	40bc                	lw	a5,64(s1)
    800035a6:	37fd                	addiw	a5,a5,-1
    800035a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035aa:	00055517          	auipc	a0,0x55
    800035ae:	f1650513          	addi	a0,a0,-234 # 800584c0 <bcache>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	708080e7          	jalr	1800(ra) # 80000cba <release>
}
    800035ba:	60e2                	ld	ra,24(sp)
    800035bc:	6442                	ld	s0,16(sp)
    800035be:	64a2                	ld	s1,8(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035c4:	1101                	addi	sp,sp,-32
    800035c6:	ec06                	sd	ra,24(sp)
    800035c8:	e822                	sd	s0,16(sp)
    800035ca:	e426                	sd	s1,8(sp)
    800035cc:	e04a                	sd	s2,0(sp)
    800035ce:	1000                	addi	s0,sp,32
    800035d0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035d2:	00d5d59b          	srliw	a1,a1,0xd
    800035d6:	0005d797          	auipc	a5,0x5d
    800035da:	5c67a783          	lw	a5,1478(a5) # 80060b9c <sb+0x1c>
    800035de:	9dbd                	addw	a1,a1,a5
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	d9e080e7          	jalr	-610(ra) # 8000337e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035e8:	0074f713          	andi	a4,s1,7
    800035ec:	4785                	li	a5,1
    800035ee:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035f2:	14ce                	slli	s1,s1,0x33
    800035f4:	90d9                	srli	s1,s1,0x36
    800035f6:	00950733          	add	a4,a0,s1
    800035fa:	05874703          	lbu	a4,88(a4)
    800035fe:	00e7f6b3          	and	a3,a5,a4
    80003602:	c69d                	beqz	a3,80003630 <bfree+0x6c>
    80003604:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003606:	94aa                	add	s1,s1,a0
    80003608:	fff7c793          	not	a5,a5
    8000360c:	8ff9                	and	a5,a5,a4
    8000360e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003612:	00001097          	auipc	ra,0x1
    80003616:	11a080e7          	jalr	282(ra) # 8000472c <log_write>
  brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	e92080e7          	jalr	-366(ra) # 800034ae <brelse>
}
    80003624:	60e2                	ld	ra,24(sp)
    80003626:	6442                	ld	s0,16(sp)
    80003628:	64a2                	ld	s1,8(sp)
    8000362a:	6902                	ld	s2,0(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret
    panic("freeing free block");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	ef050513          	addi	a0,a0,-272 # 80008520 <syscalls+0x100>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	f12080e7          	jalr	-238(ra) # 8000054a <panic>

0000000080003640 <balloc>:
{
    80003640:	711d                	addi	sp,sp,-96
    80003642:	ec86                	sd	ra,88(sp)
    80003644:	e8a2                	sd	s0,80(sp)
    80003646:	e4a6                	sd	s1,72(sp)
    80003648:	e0ca                	sd	s2,64(sp)
    8000364a:	fc4e                	sd	s3,56(sp)
    8000364c:	f852                	sd	s4,48(sp)
    8000364e:	f456                	sd	s5,40(sp)
    80003650:	f05a                	sd	s6,32(sp)
    80003652:	ec5e                	sd	s7,24(sp)
    80003654:	e862                	sd	s8,16(sp)
    80003656:	e466                	sd	s9,8(sp)
    80003658:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000365a:	0005d797          	auipc	a5,0x5d
    8000365e:	52a7a783          	lw	a5,1322(a5) # 80060b84 <sb+0x4>
    80003662:	cbd1                	beqz	a5,800036f6 <balloc+0xb6>
    80003664:	8baa                	mv	s7,a0
    80003666:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003668:	0005db17          	auipc	s6,0x5d
    8000366c:	518b0b13          	addi	s6,s6,1304 # 80060b80 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003670:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003672:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003674:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003676:	6c89                	lui	s9,0x2
    80003678:	a831                	j	80003694 <balloc+0x54>
    brelse(bp);
    8000367a:	854a                	mv	a0,s2
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	e32080e7          	jalr	-462(ra) # 800034ae <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003684:	015c87bb          	addw	a5,s9,s5
    80003688:	00078a9b          	sext.w	s5,a5
    8000368c:	004b2703          	lw	a4,4(s6)
    80003690:	06eaf363          	bgeu	s5,a4,800036f6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003694:	41fad79b          	sraiw	a5,s5,0x1f
    80003698:	0137d79b          	srliw	a5,a5,0x13
    8000369c:	015787bb          	addw	a5,a5,s5
    800036a0:	40d7d79b          	sraiw	a5,a5,0xd
    800036a4:	01cb2583          	lw	a1,28(s6)
    800036a8:	9dbd                	addw	a1,a1,a5
    800036aa:	855e                	mv	a0,s7
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	cd2080e7          	jalr	-814(ra) # 8000337e <bread>
    800036b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b6:	004b2503          	lw	a0,4(s6)
    800036ba:	000a849b          	sext.w	s1,s5
    800036be:	8662                	mv	a2,s8
    800036c0:	faa4fde3          	bgeu	s1,a0,8000367a <balloc+0x3a>
      m = 1 << (bi % 8);
    800036c4:	41f6579b          	sraiw	a5,a2,0x1f
    800036c8:	01d7d69b          	srliw	a3,a5,0x1d
    800036cc:	00c6873b          	addw	a4,a3,a2
    800036d0:	00777793          	andi	a5,a4,7
    800036d4:	9f95                	subw	a5,a5,a3
    800036d6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036da:	4037571b          	sraiw	a4,a4,0x3
    800036de:	00e906b3          	add	a3,s2,a4
    800036e2:	0586c683          	lbu	a3,88(a3)
    800036e6:	00d7f5b3          	and	a1,a5,a3
    800036ea:	cd91                	beqz	a1,80003706 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ec:	2605                	addiw	a2,a2,1
    800036ee:	2485                	addiw	s1,s1,1
    800036f0:	fd4618e3          	bne	a2,s4,800036c0 <balloc+0x80>
    800036f4:	b759                	j	8000367a <balloc+0x3a>
  panic("balloc: out of blocks");
    800036f6:	00005517          	auipc	a0,0x5
    800036fa:	e4250513          	addi	a0,a0,-446 # 80008538 <syscalls+0x118>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	e4c080e7          	jalr	-436(ra) # 8000054a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003706:	974a                	add	a4,a4,s2
    80003708:	8fd5                	or	a5,a5,a3
    8000370a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00001097          	auipc	ra,0x1
    80003714:	01c080e7          	jalr	28(ra) # 8000472c <log_write>
        brelse(bp);
    80003718:	854a                	mv	a0,s2
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	d94080e7          	jalr	-620(ra) # 800034ae <brelse>
  bp = bread(dev, bno);
    80003722:	85a6                	mv	a1,s1
    80003724:	855e                	mv	a0,s7
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	c58080e7          	jalr	-936(ra) # 8000337e <bread>
    8000372e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003730:	40000613          	li	a2,1024
    80003734:	4581                	li	a1,0
    80003736:	05850513          	addi	a0,a0,88
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	5c8080e7          	jalr	1480(ra) # 80000d02 <memset>
  log_write(bp);
    80003742:	854a                	mv	a0,s2
    80003744:	00001097          	auipc	ra,0x1
    80003748:	fe8080e7          	jalr	-24(ra) # 8000472c <log_write>
  brelse(bp);
    8000374c:	854a                	mv	a0,s2
    8000374e:	00000097          	auipc	ra,0x0
    80003752:	d60080e7          	jalr	-672(ra) # 800034ae <brelse>
}
    80003756:	8526                	mv	a0,s1
    80003758:	60e6                	ld	ra,88(sp)
    8000375a:	6446                	ld	s0,80(sp)
    8000375c:	64a6                	ld	s1,72(sp)
    8000375e:	6906                	ld	s2,64(sp)
    80003760:	79e2                	ld	s3,56(sp)
    80003762:	7a42                	ld	s4,48(sp)
    80003764:	7aa2                	ld	s5,40(sp)
    80003766:	7b02                	ld	s6,32(sp)
    80003768:	6be2                	ld	s7,24(sp)
    8000376a:	6c42                	ld	s8,16(sp)
    8000376c:	6ca2                	ld	s9,8(sp)
    8000376e:	6125                	addi	sp,sp,96
    80003770:	8082                	ret

0000000080003772 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003772:	7179                	addi	sp,sp,-48
    80003774:	f406                	sd	ra,40(sp)
    80003776:	f022                	sd	s0,32(sp)
    80003778:	ec26                	sd	s1,24(sp)
    8000377a:	e84a                	sd	s2,16(sp)
    8000377c:	e44e                	sd	s3,8(sp)
    8000377e:	e052                	sd	s4,0(sp)
    80003780:	1800                	addi	s0,sp,48
    80003782:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003784:	47ad                	li	a5,11
    80003786:	04b7fe63          	bgeu	a5,a1,800037e2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000378a:	ff45849b          	addiw	s1,a1,-12
    8000378e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003792:	0ff00793          	li	a5,255
    80003796:	0ae7e363          	bltu	a5,a4,8000383c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000379a:	08052583          	lw	a1,128(a0)
    8000379e:	c5ad                	beqz	a1,80003808 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037a0:	00092503          	lw	a0,0(s2)
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	bda080e7          	jalr	-1062(ra) # 8000337e <bread>
    800037ac:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037ae:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037b2:	02049593          	slli	a1,s1,0x20
    800037b6:	9181                	srli	a1,a1,0x20
    800037b8:	058a                	slli	a1,a1,0x2
    800037ba:	00b784b3          	add	s1,a5,a1
    800037be:	0004a983          	lw	s3,0(s1)
    800037c2:	04098d63          	beqz	s3,8000381c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037c6:	8552                	mv	a0,s4
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	ce6080e7          	jalr	-794(ra) # 800034ae <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037d0:	854e                	mv	a0,s3
    800037d2:	70a2                	ld	ra,40(sp)
    800037d4:	7402                	ld	s0,32(sp)
    800037d6:	64e2                	ld	s1,24(sp)
    800037d8:	6942                	ld	s2,16(sp)
    800037da:	69a2                	ld	s3,8(sp)
    800037dc:	6a02                	ld	s4,0(sp)
    800037de:	6145                	addi	sp,sp,48
    800037e0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037e2:	02059493          	slli	s1,a1,0x20
    800037e6:	9081                	srli	s1,s1,0x20
    800037e8:	048a                	slli	s1,s1,0x2
    800037ea:	94aa                	add	s1,s1,a0
    800037ec:	0504a983          	lw	s3,80(s1)
    800037f0:	fe0990e3          	bnez	s3,800037d0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037f4:	4108                	lw	a0,0(a0)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	e4a080e7          	jalr	-438(ra) # 80003640 <balloc>
    800037fe:	0005099b          	sext.w	s3,a0
    80003802:	0534a823          	sw	s3,80(s1)
    80003806:	b7e9                	j	800037d0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003808:	4108                	lw	a0,0(a0)
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	e36080e7          	jalr	-458(ra) # 80003640 <balloc>
    80003812:	0005059b          	sext.w	a1,a0
    80003816:	08b92023          	sw	a1,128(s2)
    8000381a:	b759                	j	800037a0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000381c:	00092503          	lw	a0,0(s2)
    80003820:	00000097          	auipc	ra,0x0
    80003824:	e20080e7          	jalr	-480(ra) # 80003640 <balloc>
    80003828:	0005099b          	sext.w	s3,a0
    8000382c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003830:	8552                	mv	a0,s4
    80003832:	00001097          	auipc	ra,0x1
    80003836:	efa080e7          	jalr	-262(ra) # 8000472c <log_write>
    8000383a:	b771                	j	800037c6 <bmap+0x54>
  panic("bmap: out of range");
    8000383c:	00005517          	auipc	a0,0x5
    80003840:	d1450513          	addi	a0,a0,-748 # 80008550 <syscalls+0x130>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	d06080e7          	jalr	-762(ra) # 8000054a <panic>

000000008000384c <iget>:
{
    8000384c:	7179                	addi	sp,sp,-48
    8000384e:	f406                	sd	ra,40(sp)
    80003850:	f022                	sd	s0,32(sp)
    80003852:	ec26                	sd	s1,24(sp)
    80003854:	e84a                	sd	s2,16(sp)
    80003856:	e44e                	sd	s3,8(sp)
    80003858:	e052                	sd	s4,0(sp)
    8000385a:	1800                	addi	s0,sp,48
    8000385c:	89aa                	mv	s3,a0
    8000385e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003860:	0005d517          	auipc	a0,0x5d
    80003864:	34050513          	addi	a0,a0,832 # 80060ba0 <icache>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	39e080e7          	jalr	926(ra) # 80000c06 <acquire>
  empty = 0;
    80003870:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003872:	0005d497          	auipc	s1,0x5d
    80003876:	34648493          	addi	s1,s1,838 # 80060bb8 <icache+0x18>
    8000387a:	0005f697          	auipc	a3,0x5f
    8000387e:	dce68693          	addi	a3,a3,-562 # 80062648 <log>
    80003882:	a039                	j	80003890 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003884:	02090b63          	beqz	s2,800038ba <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003888:	08848493          	addi	s1,s1,136
    8000388c:	02d48a63          	beq	s1,a3,800038c0 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003890:	449c                	lw	a5,8(s1)
    80003892:	fef059e3          	blez	a5,80003884 <iget+0x38>
    80003896:	4098                	lw	a4,0(s1)
    80003898:	ff3716e3          	bne	a4,s3,80003884 <iget+0x38>
    8000389c:	40d8                	lw	a4,4(s1)
    8000389e:	ff4713e3          	bne	a4,s4,80003884 <iget+0x38>
      ip->ref++;
    800038a2:	2785                	addiw	a5,a5,1
    800038a4:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800038a6:	0005d517          	auipc	a0,0x5d
    800038aa:	2fa50513          	addi	a0,a0,762 # 80060ba0 <icache>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	40c080e7          	jalr	1036(ra) # 80000cba <release>
      return ip;
    800038b6:	8926                	mv	s2,s1
    800038b8:	a03d                	j	800038e6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038ba:	f7f9                	bnez	a5,80003888 <iget+0x3c>
    800038bc:	8926                	mv	s2,s1
    800038be:	b7e9                	j	80003888 <iget+0x3c>
  if(empty == 0)
    800038c0:	02090c63          	beqz	s2,800038f8 <iget+0xac>
  ip->dev = dev;
    800038c4:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038c8:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038cc:	4785                	li	a5,1
    800038ce:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038d2:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800038d6:	0005d517          	auipc	a0,0x5d
    800038da:	2ca50513          	addi	a0,a0,714 # 80060ba0 <icache>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3dc080e7          	jalr	988(ra) # 80000cba <release>
}
    800038e6:	854a                	mv	a0,s2
    800038e8:	70a2                	ld	ra,40(sp)
    800038ea:	7402                	ld	s0,32(sp)
    800038ec:	64e2                	ld	s1,24(sp)
    800038ee:	6942                	ld	s2,16(sp)
    800038f0:	69a2                	ld	s3,8(sp)
    800038f2:	6a02                	ld	s4,0(sp)
    800038f4:	6145                	addi	sp,sp,48
    800038f6:	8082                	ret
    panic("iget: no inodes");
    800038f8:	00005517          	auipc	a0,0x5
    800038fc:	c7050513          	addi	a0,a0,-912 # 80008568 <syscalls+0x148>
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	c4a080e7          	jalr	-950(ra) # 8000054a <panic>

0000000080003908 <fsinit>:
fsinit(int dev) {
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	1800                	addi	s0,sp,48
    80003916:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003918:	4585                	li	a1,1
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	a64080e7          	jalr	-1436(ra) # 8000337e <bread>
    80003922:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003924:	0005d997          	auipc	s3,0x5d
    80003928:	25c98993          	addi	s3,s3,604 # 80060b80 <sb>
    8000392c:	02000613          	li	a2,32
    80003930:	05850593          	addi	a1,a0,88
    80003934:	854e                	mv	a0,s3
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	428080e7          	jalr	1064(ra) # 80000d5e <memmove>
  brelse(bp);
    8000393e:	8526                	mv	a0,s1
    80003940:	00000097          	auipc	ra,0x0
    80003944:	b6e080e7          	jalr	-1170(ra) # 800034ae <brelse>
  if(sb.magic != FSMAGIC)
    80003948:	0009a703          	lw	a4,0(s3)
    8000394c:	102037b7          	lui	a5,0x10203
    80003950:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003954:	02f71263          	bne	a4,a5,80003978 <fsinit+0x70>
  initlog(dev, &sb);
    80003958:	0005d597          	auipc	a1,0x5d
    8000395c:	22858593          	addi	a1,a1,552 # 80060b80 <sb>
    80003960:	854a                	mv	a0,s2
    80003962:	00001097          	auipc	ra,0x1
    80003966:	b4e080e7          	jalr	-1202(ra) # 800044b0 <initlog>
}
    8000396a:	70a2                	ld	ra,40(sp)
    8000396c:	7402                	ld	s0,32(sp)
    8000396e:	64e2                	ld	s1,24(sp)
    80003970:	6942                	ld	s2,16(sp)
    80003972:	69a2                	ld	s3,8(sp)
    80003974:	6145                	addi	sp,sp,48
    80003976:	8082                	ret
    panic("invalid file system");
    80003978:	00005517          	auipc	a0,0x5
    8000397c:	c0050513          	addi	a0,a0,-1024 # 80008578 <syscalls+0x158>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	bca080e7          	jalr	-1078(ra) # 8000054a <panic>

0000000080003988 <iinit>:
{
    80003988:	7179                	addi	sp,sp,-48
    8000398a:	f406                	sd	ra,40(sp)
    8000398c:	f022                	sd	s0,32(sp)
    8000398e:	ec26                	sd	s1,24(sp)
    80003990:	e84a                	sd	s2,16(sp)
    80003992:	e44e                	sd	s3,8(sp)
    80003994:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003996:	00005597          	auipc	a1,0x5
    8000399a:	bfa58593          	addi	a1,a1,-1030 # 80008590 <syscalls+0x170>
    8000399e:	0005d517          	auipc	a0,0x5d
    800039a2:	20250513          	addi	a0,a0,514 # 80060ba0 <icache>
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	1d0080e7          	jalr	464(ra) # 80000b76 <initlock>
  for(i = 0; i < NINODE; i++) {
    800039ae:	0005d497          	auipc	s1,0x5d
    800039b2:	21a48493          	addi	s1,s1,538 # 80060bc8 <icache+0x28>
    800039b6:	0005f997          	auipc	s3,0x5f
    800039ba:	ca298993          	addi	s3,s3,-862 # 80062658 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800039be:	00005917          	auipc	s2,0x5
    800039c2:	bda90913          	addi	s2,s2,-1062 # 80008598 <syscalls+0x178>
    800039c6:	85ca                	mv	a1,s2
    800039c8:	8526                	mv	a0,s1
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	e50080e7          	jalr	-432(ra) # 8000481a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039d2:	08848493          	addi	s1,s1,136
    800039d6:	ff3498e3          	bne	s1,s3,800039c6 <iinit+0x3e>
}
    800039da:	70a2                	ld	ra,40(sp)
    800039dc:	7402                	ld	s0,32(sp)
    800039de:	64e2                	ld	s1,24(sp)
    800039e0:	6942                	ld	s2,16(sp)
    800039e2:	69a2                	ld	s3,8(sp)
    800039e4:	6145                	addi	sp,sp,48
    800039e6:	8082                	ret

00000000800039e8 <ialloc>:
{
    800039e8:	715d                	addi	sp,sp,-80
    800039ea:	e486                	sd	ra,72(sp)
    800039ec:	e0a2                	sd	s0,64(sp)
    800039ee:	fc26                	sd	s1,56(sp)
    800039f0:	f84a                	sd	s2,48(sp)
    800039f2:	f44e                	sd	s3,40(sp)
    800039f4:	f052                	sd	s4,32(sp)
    800039f6:	ec56                	sd	s5,24(sp)
    800039f8:	e85a                	sd	s6,16(sp)
    800039fa:	e45e                	sd	s7,8(sp)
    800039fc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039fe:	0005d717          	auipc	a4,0x5d
    80003a02:	18e72703          	lw	a4,398(a4) # 80060b8c <sb+0xc>
    80003a06:	4785                	li	a5,1
    80003a08:	04e7fa63          	bgeu	a5,a4,80003a5c <ialloc+0x74>
    80003a0c:	8aaa                	mv	s5,a0
    80003a0e:	8bae                	mv	s7,a1
    80003a10:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a12:	0005da17          	auipc	s4,0x5d
    80003a16:	16ea0a13          	addi	s4,s4,366 # 80060b80 <sb>
    80003a1a:	00048b1b          	sext.w	s6,s1
    80003a1e:	0044d793          	srli	a5,s1,0x4
    80003a22:	018a2583          	lw	a1,24(s4)
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	8556                	mv	a0,s5
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	954080e7          	jalr	-1708(ra) # 8000337e <bread>
    80003a32:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a34:	05850993          	addi	s3,a0,88
    80003a38:	00f4f793          	andi	a5,s1,15
    80003a3c:	079a                	slli	a5,a5,0x6
    80003a3e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a40:	00099783          	lh	a5,0(s3)
    80003a44:	c785                	beqz	a5,80003a6c <ialloc+0x84>
    brelse(bp);
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	a68080e7          	jalr	-1432(ra) # 800034ae <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a4e:	0485                	addi	s1,s1,1
    80003a50:	00ca2703          	lw	a4,12(s4)
    80003a54:	0004879b          	sext.w	a5,s1
    80003a58:	fce7e1e3          	bltu	a5,a4,80003a1a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a5c:	00005517          	auipc	a0,0x5
    80003a60:	b4450513          	addi	a0,a0,-1212 # 800085a0 <syscalls+0x180>
    80003a64:	ffffd097          	auipc	ra,0xffffd
    80003a68:	ae6080e7          	jalr	-1306(ra) # 8000054a <panic>
      memset(dip, 0, sizeof(*dip));
    80003a6c:	04000613          	li	a2,64
    80003a70:	4581                	li	a1,0
    80003a72:	854e                	mv	a0,s3
    80003a74:	ffffd097          	auipc	ra,0xffffd
    80003a78:	28e080e7          	jalr	654(ra) # 80000d02 <memset>
      dip->type = type;
    80003a7c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a80:	854a                	mv	a0,s2
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	caa080e7          	jalr	-854(ra) # 8000472c <log_write>
      brelse(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	a22080e7          	jalr	-1502(ra) # 800034ae <brelse>
      return iget(dev, inum);
    80003a94:	85da                	mv	a1,s6
    80003a96:	8556                	mv	a0,s5
    80003a98:	00000097          	auipc	ra,0x0
    80003a9c:	db4080e7          	jalr	-588(ra) # 8000384c <iget>
}
    80003aa0:	60a6                	ld	ra,72(sp)
    80003aa2:	6406                	ld	s0,64(sp)
    80003aa4:	74e2                	ld	s1,56(sp)
    80003aa6:	7942                	ld	s2,48(sp)
    80003aa8:	79a2                	ld	s3,40(sp)
    80003aaa:	7a02                	ld	s4,32(sp)
    80003aac:	6ae2                	ld	s5,24(sp)
    80003aae:	6b42                	ld	s6,16(sp)
    80003ab0:	6ba2                	ld	s7,8(sp)
    80003ab2:	6161                	addi	sp,sp,80
    80003ab4:	8082                	ret

0000000080003ab6 <iupdate>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	e04a                	sd	s2,0(sp)
    80003ac0:	1000                	addi	s0,sp,32
    80003ac2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ac4:	415c                	lw	a5,4(a0)
    80003ac6:	0047d79b          	srliw	a5,a5,0x4
    80003aca:	0005d597          	auipc	a1,0x5d
    80003ace:	0ce5a583          	lw	a1,206(a1) # 80060b98 <sb+0x18>
    80003ad2:	9dbd                	addw	a1,a1,a5
    80003ad4:	4108                	lw	a0,0(a0)
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	8a8080e7          	jalr	-1880(ra) # 8000337e <bread>
    80003ade:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ae0:	05850793          	addi	a5,a0,88
    80003ae4:	40c8                	lw	a0,4(s1)
    80003ae6:	893d                	andi	a0,a0,15
    80003ae8:	051a                	slli	a0,a0,0x6
    80003aea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003aec:	04449703          	lh	a4,68(s1)
    80003af0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003af4:	04649703          	lh	a4,70(s1)
    80003af8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003afc:	04849703          	lh	a4,72(s1)
    80003b00:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b04:	04a49703          	lh	a4,74(s1)
    80003b08:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b0c:	44f8                	lw	a4,76(s1)
    80003b0e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b10:	03400613          	li	a2,52
    80003b14:	05048593          	addi	a1,s1,80
    80003b18:	0531                	addi	a0,a0,12
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	244080e7          	jalr	580(ra) # 80000d5e <memmove>
  log_write(bp);
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	c08080e7          	jalr	-1016(ra) # 8000472c <log_write>
  brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	980080e7          	jalr	-1664(ra) # 800034ae <brelse>
}
    80003b36:	60e2                	ld	ra,24(sp)
    80003b38:	6442                	ld	s0,16(sp)
    80003b3a:	64a2                	ld	s1,8(sp)
    80003b3c:	6902                	ld	s2,0(sp)
    80003b3e:	6105                	addi	sp,sp,32
    80003b40:	8082                	ret

0000000080003b42 <idup>:
{
    80003b42:	1101                	addi	sp,sp,-32
    80003b44:	ec06                	sd	ra,24(sp)
    80003b46:	e822                	sd	s0,16(sp)
    80003b48:	e426                	sd	s1,8(sp)
    80003b4a:	1000                	addi	s0,sp,32
    80003b4c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b4e:	0005d517          	auipc	a0,0x5d
    80003b52:	05250513          	addi	a0,a0,82 # 80060ba0 <icache>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	0b0080e7          	jalr	176(ra) # 80000c06 <acquire>
  ip->ref++;
    80003b5e:	449c                	lw	a5,8(s1)
    80003b60:	2785                	addiw	a5,a5,1
    80003b62:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b64:	0005d517          	auipc	a0,0x5d
    80003b68:	03c50513          	addi	a0,a0,60 # 80060ba0 <icache>
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	14e080e7          	jalr	334(ra) # 80000cba <release>
}
    80003b74:	8526                	mv	a0,s1
    80003b76:	60e2                	ld	ra,24(sp)
    80003b78:	6442                	ld	s0,16(sp)
    80003b7a:	64a2                	ld	s1,8(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret

0000000080003b80 <ilock>:
{
    80003b80:	1101                	addi	sp,sp,-32
    80003b82:	ec06                	sd	ra,24(sp)
    80003b84:	e822                	sd	s0,16(sp)
    80003b86:	e426                	sd	s1,8(sp)
    80003b88:	e04a                	sd	s2,0(sp)
    80003b8a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b8c:	c115                	beqz	a0,80003bb0 <ilock+0x30>
    80003b8e:	84aa                	mv	s1,a0
    80003b90:	451c                	lw	a5,8(a0)
    80003b92:	00f05f63          	blez	a5,80003bb0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b96:	0541                	addi	a0,a0,16
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	cbc080e7          	jalr	-836(ra) # 80004854 <acquiresleep>
  if(ip->valid == 0){
    80003ba0:	40bc                	lw	a5,64(s1)
    80003ba2:	cf99                	beqz	a5,80003bc0 <ilock+0x40>
}
    80003ba4:	60e2                	ld	ra,24(sp)
    80003ba6:	6442                	ld	s0,16(sp)
    80003ba8:	64a2                	ld	s1,8(sp)
    80003baa:	6902                	ld	s2,0(sp)
    80003bac:	6105                	addi	sp,sp,32
    80003bae:	8082                	ret
    panic("ilock");
    80003bb0:	00005517          	auipc	a0,0x5
    80003bb4:	a0850513          	addi	a0,a0,-1528 # 800085b8 <syscalls+0x198>
    80003bb8:	ffffd097          	auipc	ra,0xffffd
    80003bbc:	992080e7          	jalr	-1646(ra) # 8000054a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bc0:	40dc                	lw	a5,4(s1)
    80003bc2:	0047d79b          	srliw	a5,a5,0x4
    80003bc6:	0005d597          	auipc	a1,0x5d
    80003bca:	fd25a583          	lw	a1,-46(a1) # 80060b98 <sb+0x18>
    80003bce:	9dbd                	addw	a1,a1,a5
    80003bd0:	4088                	lw	a0,0(s1)
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	7ac080e7          	jalr	1964(ra) # 8000337e <bread>
    80003bda:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bdc:	05850593          	addi	a1,a0,88
    80003be0:	40dc                	lw	a5,4(s1)
    80003be2:	8bbd                	andi	a5,a5,15
    80003be4:	079a                	slli	a5,a5,0x6
    80003be6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003be8:	00059783          	lh	a5,0(a1)
    80003bec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bf0:	00259783          	lh	a5,2(a1)
    80003bf4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bf8:	00459783          	lh	a5,4(a1)
    80003bfc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c00:	00659783          	lh	a5,6(a1)
    80003c04:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c08:	459c                	lw	a5,8(a1)
    80003c0a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c0c:	03400613          	li	a2,52
    80003c10:	05b1                	addi	a1,a1,12
    80003c12:	05048513          	addi	a0,s1,80
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	148080e7          	jalr	328(ra) # 80000d5e <memmove>
    brelse(bp);
    80003c1e:	854a                	mv	a0,s2
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	88e080e7          	jalr	-1906(ra) # 800034ae <brelse>
    ip->valid = 1;
    80003c28:	4785                	li	a5,1
    80003c2a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c2c:	04449783          	lh	a5,68(s1)
    80003c30:	fbb5                	bnez	a5,80003ba4 <ilock+0x24>
      panic("ilock: no type");
    80003c32:	00005517          	auipc	a0,0x5
    80003c36:	98e50513          	addi	a0,a0,-1650 # 800085c0 <syscalls+0x1a0>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	910080e7          	jalr	-1776(ra) # 8000054a <panic>

0000000080003c42 <iunlock>:
{
    80003c42:	1101                	addi	sp,sp,-32
    80003c44:	ec06                	sd	ra,24(sp)
    80003c46:	e822                	sd	s0,16(sp)
    80003c48:	e426                	sd	s1,8(sp)
    80003c4a:	e04a                	sd	s2,0(sp)
    80003c4c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c4e:	c905                	beqz	a0,80003c7e <iunlock+0x3c>
    80003c50:	84aa                	mv	s1,a0
    80003c52:	01050913          	addi	s2,a0,16
    80003c56:	854a                	mv	a0,s2
    80003c58:	00001097          	auipc	ra,0x1
    80003c5c:	c96080e7          	jalr	-874(ra) # 800048ee <holdingsleep>
    80003c60:	cd19                	beqz	a0,80003c7e <iunlock+0x3c>
    80003c62:	449c                	lw	a5,8(s1)
    80003c64:	00f05d63          	blez	a5,80003c7e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	c40080e7          	jalr	-960(ra) # 800048aa <releasesleep>
}
    80003c72:	60e2                	ld	ra,24(sp)
    80003c74:	6442                	ld	s0,16(sp)
    80003c76:	64a2                	ld	s1,8(sp)
    80003c78:	6902                	ld	s2,0(sp)
    80003c7a:	6105                	addi	sp,sp,32
    80003c7c:	8082                	ret
    panic("iunlock");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	95250513          	addi	a0,a0,-1710 # 800085d0 <syscalls+0x1b0>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8c4080e7          	jalr	-1852(ra) # 8000054a <panic>

0000000080003c8e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c8e:	7179                	addi	sp,sp,-48
    80003c90:	f406                	sd	ra,40(sp)
    80003c92:	f022                	sd	s0,32(sp)
    80003c94:	ec26                	sd	s1,24(sp)
    80003c96:	e84a                	sd	s2,16(sp)
    80003c98:	e44e                	sd	s3,8(sp)
    80003c9a:	e052                	sd	s4,0(sp)
    80003c9c:	1800                	addi	s0,sp,48
    80003c9e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ca0:	05050493          	addi	s1,a0,80
    80003ca4:	08050913          	addi	s2,a0,128
    80003ca8:	a021                	j	80003cb0 <itrunc+0x22>
    80003caa:	0491                	addi	s1,s1,4
    80003cac:	01248d63          	beq	s1,s2,80003cc6 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cb0:	408c                	lw	a1,0(s1)
    80003cb2:	dde5                	beqz	a1,80003caa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cb4:	0009a503          	lw	a0,0(s3)
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	90c080e7          	jalr	-1780(ra) # 800035c4 <bfree>
      ip->addrs[i] = 0;
    80003cc0:	0004a023          	sw	zero,0(s1)
    80003cc4:	b7dd                	j	80003caa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cc6:	0809a583          	lw	a1,128(s3)
    80003cca:	e185                	bnez	a1,80003cea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ccc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	de4080e7          	jalr	-540(ra) # 80003ab6 <iupdate>
}
    80003cda:	70a2                	ld	ra,40(sp)
    80003cdc:	7402                	ld	s0,32(sp)
    80003cde:	64e2                	ld	s1,24(sp)
    80003ce0:	6942                	ld	s2,16(sp)
    80003ce2:	69a2                	ld	s3,8(sp)
    80003ce4:	6a02                	ld	s4,0(sp)
    80003ce6:	6145                	addi	sp,sp,48
    80003ce8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cea:	0009a503          	lw	a0,0(s3)
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	690080e7          	jalr	1680(ra) # 8000337e <bread>
    80003cf6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cf8:	05850493          	addi	s1,a0,88
    80003cfc:	45850913          	addi	s2,a0,1112
    80003d00:	a021                	j	80003d08 <itrunc+0x7a>
    80003d02:	0491                	addi	s1,s1,4
    80003d04:	01248b63          	beq	s1,s2,80003d1a <itrunc+0x8c>
      if(a[j])
    80003d08:	408c                	lw	a1,0(s1)
    80003d0a:	dde5                	beqz	a1,80003d02 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d0c:	0009a503          	lw	a0,0(s3)
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	8b4080e7          	jalr	-1868(ra) # 800035c4 <bfree>
    80003d18:	b7ed                	j	80003d02 <itrunc+0x74>
    brelse(bp);
    80003d1a:	8552                	mv	a0,s4
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	792080e7          	jalr	1938(ra) # 800034ae <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d24:	0809a583          	lw	a1,128(s3)
    80003d28:	0009a503          	lw	a0,0(s3)
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	898080e7          	jalr	-1896(ra) # 800035c4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d34:	0809a023          	sw	zero,128(s3)
    80003d38:	bf51                	j	80003ccc <itrunc+0x3e>

0000000080003d3a <iput>:
{
    80003d3a:	1101                	addi	sp,sp,-32
    80003d3c:	ec06                	sd	ra,24(sp)
    80003d3e:	e822                	sd	s0,16(sp)
    80003d40:	e426                	sd	s1,8(sp)
    80003d42:	e04a                	sd	s2,0(sp)
    80003d44:	1000                	addi	s0,sp,32
    80003d46:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003d48:	0005d517          	auipc	a0,0x5d
    80003d4c:	e5850513          	addi	a0,a0,-424 # 80060ba0 <icache>
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	eb6080e7          	jalr	-330(ra) # 80000c06 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d58:	4498                	lw	a4,8(s1)
    80003d5a:	4785                	li	a5,1
    80003d5c:	02f70363          	beq	a4,a5,80003d82 <iput+0x48>
  ip->ref--;
    80003d60:	449c                	lw	a5,8(s1)
    80003d62:	37fd                	addiw	a5,a5,-1
    80003d64:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003d66:	0005d517          	auipc	a0,0x5d
    80003d6a:	e3a50513          	addi	a0,a0,-454 # 80060ba0 <icache>
    80003d6e:	ffffd097          	auipc	ra,0xffffd
    80003d72:	f4c080e7          	jalr	-180(ra) # 80000cba <release>
}
    80003d76:	60e2                	ld	ra,24(sp)
    80003d78:	6442                	ld	s0,16(sp)
    80003d7a:	64a2                	ld	s1,8(sp)
    80003d7c:	6902                	ld	s2,0(sp)
    80003d7e:	6105                	addi	sp,sp,32
    80003d80:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d82:	40bc                	lw	a5,64(s1)
    80003d84:	dff1                	beqz	a5,80003d60 <iput+0x26>
    80003d86:	04a49783          	lh	a5,74(s1)
    80003d8a:	fbf9                	bnez	a5,80003d60 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d8c:	01048913          	addi	s2,s1,16
    80003d90:	854a                	mv	a0,s2
    80003d92:	00001097          	auipc	ra,0x1
    80003d96:	ac2080e7          	jalr	-1342(ra) # 80004854 <acquiresleep>
    release(&icache.lock);
    80003d9a:	0005d517          	auipc	a0,0x5d
    80003d9e:	e0650513          	addi	a0,a0,-506 # 80060ba0 <icache>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	f18080e7          	jalr	-232(ra) # 80000cba <release>
    itrunc(ip);
    80003daa:	8526                	mv	a0,s1
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	ee2080e7          	jalr	-286(ra) # 80003c8e <itrunc>
    ip->type = 0;
    80003db4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003db8:	8526                	mv	a0,s1
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	cfc080e7          	jalr	-772(ra) # 80003ab6 <iupdate>
    ip->valid = 0;
    80003dc2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003dc6:	854a                	mv	a0,s2
    80003dc8:	00001097          	auipc	ra,0x1
    80003dcc:	ae2080e7          	jalr	-1310(ra) # 800048aa <releasesleep>
    acquire(&icache.lock);
    80003dd0:	0005d517          	auipc	a0,0x5d
    80003dd4:	dd050513          	addi	a0,a0,-560 # 80060ba0 <icache>
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	e2e080e7          	jalr	-466(ra) # 80000c06 <acquire>
    80003de0:	b741                	j	80003d60 <iput+0x26>

0000000080003de2 <iunlockput>:
{
    80003de2:	1101                	addi	sp,sp,-32
    80003de4:	ec06                	sd	ra,24(sp)
    80003de6:	e822                	sd	s0,16(sp)
    80003de8:	e426                	sd	s1,8(sp)
    80003dea:	1000                	addi	s0,sp,32
    80003dec:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	e54080e7          	jalr	-428(ra) # 80003c42 <iunlock>
  iput(ip);
    80003df6:	8526                	mv	a0,s1
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	f42080e7          	jalr	-190(ra) # 80003d3a <iput>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret

0000000080003e0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e0a:	1141                	addi	sp,sp,-16
    80003e0c:	e422                	sd	s0,8(sp)
    80003e0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e10:	411c                	lw	a5,0(a0)
    80003e12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e14:	415c                	lw	a5,4(a0)
    80003e16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e18:	04451783          	lh	a5,68(a0)
    80003e1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e20:	04a51783          	lh	a5,74(a0)
    80003e24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e28:	04c56783          	lwu	a5,76(a0)
    80003e2c:	e99c                	sd	a5,16(a1)
}
    80003e2e:	6422                	ld	s0,8(sp)
    80003e30:	0141                	addi	sp,sp,16
    80003e32:	8082                	ret

0000000080003e34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e34:	457c                	lw	a5,76(a0)
    80003e36:	0ed7e963          	bltu	a5,a3,80003f28 <readi+0xf4>
{
    80003e3a:	7159                	addi	sp,sp,-112
    80003e3c:	f486                	sd	ra,104(sp)
    80003e3e:	f0a2                	sd	s0,96(sp)
    80003e40:	eca6                	sd	s1,88(sp)
    80003e42:	e8ca                	sd	s2,80(sp)
    80003e44:	e4ce                	sd	s3,72(sp)
    80003e46:	e0d2                	sd	s4,64(sp)
    80003e48:	fc56                	sd	s5,56(sp)
    80003e4a:	f85a                	sd	s6,48(sp)
    80003e4c:	f45e                	sd	s7,40(sp)
    80003e4e:	f062                	sd	s8,32(sp)
    80003e50:	ec66                	sd	s9,24(sp)
    80003e52:	e86a                	sd	s10,16(sp)
    80003e54:	e46e                	sd	s11,8(sp)
    80003e56:	1880                	addi	s0,sp,112
    80003e58:	8baa                	mv	s7,a0
    80003e5a:	8c2e                	mv	s8,a1
    80003e5c:	8ab2                	mv	s5,a2
    80003e5e:	84b6                	mv	s1,a3
    80003e60:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e62:	9f35                	addw	a4,a4,a3
    return 0;
    80003e64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e66:	0ad76063          	bltu	a4,a3,80003f06 <readi+0xd2>
  if(off + n > ip->size)
    80003e6a:	00e7f463          	bgeu	a5,a4,80003e72 <readi+0x3e>
    n = ip->size - off;
    80003e6e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e72:	0a0b0963          	beqz	s6,80003f24 <readi+0xf0>
    80003e76:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e78:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e7c:	5cfd                	li	s9,-1
    80003e7e:	a82d                	j	80003eb8 <readi+0x84>
    80003e80:	020a1d93          	slli	s11,s4,0x20
    80003e84:	020ddd93          	srli	s11,s11,0x20
    80003e88:	05890793          	addi	a5,s2,88
    80003e8c:	86ee                	mv	a3,s11
    80003e8e:	963e                	add	a2,a2,a5
    80003e90:	85d6                	mv	a1,s5
    80003e92:	8562                	mv	a0,s8
    80003e94:	ffffe097          	auipc	ra,0xffffe
    80003e98:	68a080e7          	jalr	1674(ra) # 8000251e <either_copyout>
    80003e9c:	05950d63          	beq	a0,s9,80003ef6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ea0:	854a                	mv	a0,s2
    80003ea2:	fffff097          	auipc	ra,0xfffff
    80003ea6:	60c080e7          	jalr	1548(ra) # 800034ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eaa:	013a09bb          	addw	s3,s4,s3
    80003eae:	009a04bb          	addw	s1,s4,s1
    80003eb2:	9aee                	add	s5,s5,s11
    80003eb4:	0569f763          	bgeu	s3,s6,80003f02 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eb8:	000ba903          	lw	s2,0(s7)
    80003ebc:	00a4d59b          	srliw	a1,s1,0xa
    80003ec0:	855e                	mv	a0,s7
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	8b0080e7          	jalr	-1872(ra) # 80003772 <bmap>
    80003eca:	0005059b          	sext.w	a1,a0
    80003ece:	854a                	mv	a0,s2
    80003ed0:	fffff097          	auipc	ra,0xfffff
    80003ed4:	4ae080e7          	jalr	1198(ra) # 8000337e <bread>
    80003ed8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eda:	3ff4f613          	andi	a2,s1,1023
    80003ede:	40cd07bb          	subw	a5,s10,a2
    80003ee2:	413b073b          	subw	a4,s6,s3
    80003ee6:	8a3e                	mv	s4,a5
    80003ee8:	2781                	sext.w	a5,a5
    80003eea:	0007069b          	sext.w	a3,a4
    80003eee:	f8f6f9e3          	bgeu	a3,a5,80003e80 <readi+0x4c>
    80003ef2:	8a3a                	mv	s4,a4
    80003ef4:	b771                	j	80003e80 <readi+0x4c>
      brelse(bp);
    80003ef6:	854a                	mv	a0,s2
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	5b6080e7          	jalr	1462(ra) # 800034ae <brelse>
      tot = -1;
    80003f00:	59fd                	li	s3,-1
  }
  return tot;
    80003f02:	0009851b          	sext.w	a0,s3
}
    80003f06:	70a6                	ld	ra,104(sp)
    80003f08:	7406                	ld	s0,96(sp)
    80003f0a:	64e6                	ld	s1,88(sp)
    80003f0c:	6946                	ld	s2,80(sp)
    80003f0e:	69a6                	ld	s3,72(sp)
    80003f10:	6a06                	ld	s4,64(sp)
    80003f12:	7ae2                	ld	s5,56(sp)
    80003f14:	7b42                	ld	s6,48(sp)
    80003f16:	7ba2                	ld	s7,40(sp)
    80003f18:	7c02                	ld	s8,32(sp)
    80003f1a:	6ce2                	ld	s9,24(sp)
    80003f1c:	6d42                	ld	s10,16(sp)
    80003f1e:	6da2                	ld	s11,8(sp)
    80003f20:	6165                	addi	sp,sp,112
    80003f22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f24:	89da                	mv	s3,s6
    80003f26:	bff1                	j	80003f02 <readi+0xce>
    return 0;
    80003f28:	4501                	li	a0,0
}
    80003f2a:	8082                	ret

0000000080003f2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f2c:	457c                	lw	a5,76(a0)
    80003f2e:	10d7e763          	bltu	a5,a3,8000403c <writei+0x110>
{
    80003f32:	7159                	addi	sp,sp,-112
    80003f34:	f486                	sd	ra,104(sp)
    80003f36:	f0a2                	sd	s0,96(sp)
    80003f38:	eca6                	sd	s1,88(sp)
    80003f3a:	e8ca                	sd	s2,80(sp)
    80003f3c:	e4ce                	sd	s3,72(sp)
    80003f3e:	e0d2                	sd	s4,64(sp)
    80003f40:	fc56                	sd	s5,56(sp)
    80003f42:	f85a                	sd	s6,48(sp)
    80003f44:	f45e                	sd	s7,40(sp)
    80003f46:	f062                	sd	s8,32(sp)
    80003f48:	ec66                	sd	s9,24(sp)
    80003f4a:	e86a                	sd	s10,16(sp)
    80003f4c:	e46e                	sd	s11,8(sp)
    80003f4e:	1880                	addi	s0,sp,112
    80003f50:	8baa                	mv	s7,a0
    80003f52:	8c2e                	mv	s8,a1
    80003f54:	8ab2                	mv	s5,a2
    80003f56:	8936                	mv	s2,a3
    80003f58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f5a:	00e687bb          	addw	a5,a3,a4
    80003f5e:	0ed7e163          	bltu	a5,a3,80004040 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f62:	00043737          	lui	a4,0x43
    80003f66:	0cf76f63          	bltu	a4,a5,80004044 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f6a:	0a0b0863          	beqz	s6,8000401a <writei+0xee>
    80003f6e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f70:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f74:	5cfd                	li	s9,-1
    80003f76:	a091                	j	80003fba <writei+0x8e>
    80003f78:	02099d93          	slli	s11,s3,0x20
    80003f7c:	020ddd93          	srli	s11,s11,0x20
    80003f80:	05848793          	addi	a5,s1,88
    80003f84:	86ee                	mv	a3,s11
    80003f86:	8656                	mv	a2,s5
    80003f88:	85e2                	mv	a1,s8
    80003f8a:	953e                	add	a0,a0,a5
    80003f8c:	ffffe097          	auipc	ra,0xffffe
    80003f90:	5ec080e7          	jalr	1516(ra) # 80002578 <either_copyin>
    80003f94:	07950263          	beq	a0,s9,80003ff8 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003f98:	8526                	mv	a0,s1
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	792080e7          	jalr	1938(ra) # 8000472c <log_write>
    brelse(bp);
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	50a080e7          	jalr	1290(ra) # 800034ae <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fac:	01498a3b          	addw	s4,s3,s4
    80003fb0:	0129893b          	addw	s2,s3,s2
    80003fb4:	9aee                	add	s5,s5,s11
    80003fb6:	056a7763          	bgeu	s4,s6,80004004 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fba:	000ba483          	lw	s1,0(s7)
    80003fbe:	00a9559b          	srliw	a1,s2,0xa
    80003fc2:	855e                	mv	a0,s7
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	7ae080e7          	jalr	1966(ra) # 80003772 <bmap>
    80003fcc:	0005059b          	sext.w	a1,a0
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	3ac080e7          	jalr	940(ra) # 8000337e <bread>
    80003fda:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fdc:	3ff97513          	andi	a0,s2,1023
    80003fe0:	40ad07bb          	subw	a5,s10,a0
    80003fe4:	414b073b          	subw	a4,s6,s4
    80003fe8:	89be                	mv	s3,a5
    80003fea:	2781                	sext.w	a5,a5
    80003fec:	0007069b          	sext.w	a3,a4
    80003ff0:	f8f6f4e3          	bgeu	a3,a5,80003f78 <writei+0x4c>
    80003ff4:	89ba                	mv	s3,a4
    80003ff6:	b749                	j	80003f78 <writei+0x4c>
      brelse(bp);
    80003ff8:	8526                	mv	a0,s1
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	4b4080e7          	jalr	1204(ra) # 800034ae <brelse>
      n = -1;
    80004002:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80004004:	04cba783          	lw	a5,76(s7)
    80004008:	0127f463          	bgeu	a5,s2,80004010 <writei+0xe4>
      ip->size = off;
    8000400c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80004010:	855e                	mv	a0,s7
    80004012:	00000097          	auipc	ra,0x0
    80004016:	aa4080e7          	jalr	-1372(ra) # 80003ab6 <iupdate>
  }

  return n;
    8000401a:	000b051b          	sext.w	a0,s6
}
    8000401e:	70a6                	ld	ra,104(sp)
    80004020:	7406                	ld	s0,96(sp)
    80004022:	64e6                	ld	s1,88(sp)
    80004024:	6946                	ld	s2,80(sp)
    80004026:	69a6                	ld	s3,72(sp)
    80004028:	6a06                	ld	s4,64(sp)
    8000402a:	7ae2                	ld	s5,56(sp)
    8000402c:	7b42                	ld	s6,48(sp)
    8000402e:	7ba2                	ld	s7,40(sp)
    80004030:	7c02                	ld	s8,32(sp)
    80004032:	6ce2                	ld	s9,24(sp)
    80004034:	6d42                	ld	s10,16(sp)
    80004036:	6da2                	ld	s11,8(sp)
    80004038:	6165                	addi	sp,sp,112
    8000403a:	8082                	ret
    return -1;
    8000403c:	557d                	li	a0,-1
}
    8000403e:	8082                	ret
    return -1;
    80004040:	557d                	li	a0,-1
    80004042:	bff1                	j	8000401e <writei+0xf2>
    return -1;
    80004044:	557d                	li	a0,-1
    80004046:	bfe1                	j	8000401e <writei+0xf2>

0000000080004048 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004048:	1141                	addi	sp,sp,-16
    8000404a:	e406                	sd	ra,8(sp)
    8000404c:	e022                	sd	s0,0(sp)
    8000404e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004050:	4639                	li	a2,14
    80004052:	ffffd097          	auipc	ra,0xffffd
    80004056:	d88080e7          	jalr	-632(ra) # 80000dda <strncmp>
}
    8000405a:	60a2                	ld	ra,8(sp)
    8000405c:	6402                	ld	s0,0(sp)
    8000405e:	0141                	addi	sp,sp,16
    80004060:	8082                	ret

0000000080004062 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	e852                	sd	s4,16(sp)
    80004070:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004072:	04451703          	lh	a4,68(a0)
    80004076:	4785                	li	a5,1
    80004078:	00f71a63          	bne	a4,a5,8000408c <dirlookup+0x2a>
    8000407c:	892a                	mv	s2,a0
    8000407e:	89ae                	mv	s3,a1
    80004080:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004082:	457c                	lw	a5,76(a0)
    80004084:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004086:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004088:	e79d                	bnez	a5,800040b6 <dirlookup+0x54>
    8000408a:	a8a5                	j	80004102 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000408c:	00004517          	auipc	a0,0x4
    80004090:	54c50513          	addi	a0,a0,1356 # 800085d8 <syscalls+0x1b8>
    80004094:	ffffc097          	auipc	ra,0xffffc
    80004098:	4b6080e7          	jalr	1206(ra) # 8000054a <panic>
      panic("dirlookup read");
    8000409c:	00004517          	auipc	a0,0x4
    800040a0:	55450513          	addi	a0,a0,1364 # 800085f0 <syscalls+0x1d0>
    800040a4:	ffffc097          	auipc	ra,0xffffc
    800040a8:	4a6080e7          	jalr	1190(ra) # 8000054a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ac:	24c1                	addiw	s1,s1,16
    800040ae:	04c92783          	lw	a5,76(s2)
    800040b2:	04f4f763          	bgeu	s1,a5,80004100 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b6:	4741                	li	a4,16
    800040b8:	86a6                	mv	a3,s1
    800040ba:	fc040613          	addi	a2,s0,-64
    800040be:	4581                	li	a1,0
    800040c0:	854a                	mv	a0,s2
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	d72080e7          	jalr	-654(ra) # 80003e34 <readi>
    800040ca:	47c1                	li	a5,16
    800040cc:	fcf518e3          	bne	a0,a5,8000409c <dirlookup+0x3a>
    if(de.inum == 0)
    800040d0:	fc045783          	lhu	a5,-64(s0)
    800040d4:	dfe1                	beqz	a5,800040ac <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040d6:	fc240593          	addi	a1,s0,-62
    800040da:	854e                	mv	a0,s3
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	f6c080e7          	jalr	-148(ra) # 80004048 <namecmp>
    800040e4:	f561                	bnez	a0,800040ac <dirlookup+0x4a>
      if(poff)
    800040e6:	000a0463          	beqz	s4,800040ee <dirlookup+0x8c>
        *poff = off;
    800040ea:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040ee:	fc045583          	lhu	a1,-64(s0)
    800040f2:	00092503          	lw	a0,0(s2)
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	756080e7          	jalr	1878(ra) # 8000384c <iget>
    800040fe:	a011                	j	80004102 <dirlookup+0xa0>
  return 0;
    80004100:	4501                	li	a0,0
}
    80004102:	70e2                	ld	ra,56(sp)
    80004104:	7442                	ld	s0,48(sp)
    80004106:	74a2                	ld	s1,40(sp)
    80004108:	7902                	ld	s2,32(sp)
    8000410a:	69e2                	ld	s3,24(sp)
    8000410c:	6a42                	ld	s4,16(sp)
    8000410e:	6121                	addi	sp,sp,64
    80004110:	8082                	ret

0000000080004112 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004112:	711d                	addi	sp,sp,-96
    80004114:	ec86                	sd	ra,88(sp)
    80004116:	e8a2                	sd	s0,80(sp)
    80004118:	e4a6                	sd	s1,72(sp)
    8000411a:	e0ca                	sd	s2,64(sp)
    8000411c:	fc4e                	sd	s3,56(sp)
    8000411e:	f852                	sd	s4,48(sp)
    80004120:	f456                	sd	s5,40(sp)
    80004122:	f05a                	sd	s6,32(sp)
    80004124:	ec5e                	sd	s7,24(sp)
    80004126:	e862                	sd	s8,16(sp)
    80004128:	e466                	sd	s9,8(sp)
    8000412a:	1080                	addi	s0,sp,96
    8000412c:	84aa                	mv	s1,a0
    8000412e:	8aae                	mv	s5,a1
    80004130:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004132:	00054703          	lbu	a4,0(a0)
    80004136:	02f00793          	li	a5,47
    8000413a:	02f70563          	beq	a4,a5,80004164 <namex+0x52>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000413e:	ffffe097          	auipc	ra,0xffffe
    80004142:	8d0080e7          	jalr	-1840(ra) # 80001a0e <myproc>
    80004146:	6785                	lui	a5,0x1
    80004148:	97aa                	add	a5,a5,a0
    8000414a:	1a07b503          	ld	a0,416(a5) # 11a0 <_entry-0x7fffee60>
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	9f4080e7          	jalr	-1548(ra) # 80003b42 <idup>
    80004156:	89aa                	mv	s3,a0
  while(*path == '/')
    80004158:	02f00913          	li	s2,47
  len = path - s;
    8000415c:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000415e:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004160:	4b85                	li	s7,1
    80004162:	a865                	j	8000421a <namex+0x108>
    ip = iget(ROOTDEV, ROOTINO);
    80004164:	4585                	li	a1,1
    80004166:	4505                	li	a0,1
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	6e4080e7          	jalr	1764(ra) # 8000384c <iget>
    80004170:	89aa                	mv	s3,a0
    80004172:	b7dd                	j	80004158 <namex+0x46>
      iunlockput(ip);
    80004174:	854e                	mv	a0,s3
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	c6c080e7          	jalr	-916(ra) # 80003de2 <iunlockput>
      return 0;
    8000417e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004180:	854e                	mv	a0,s3
    80004182:	60e6                	ld	ra,88(sp)
    80004184:	6446                	ld	s0,80(sp)
    80004186:	64a6                	ld	s1,72(sp)
    80004188:	6906                	ld	s2,64(sp)
    8000418a:	79e2                	ld	s3,56(sp)
    8000418c:	7a42                	ld	s4,48(sp)
    8000418e:	7aa2                	ld	s5,40(sp)
    80004190:	7b02                	ld	s6,32(sp)
    80004192:	6be2                	ld	s7,24(sp)
    80004194:	6c42                	ld	s8,16(sp)
    80004196:	6ca2                	ld	s9,8(sp)
    80004198:	6125                	addi	sp,sp,96
    8000419a:	8082                	ret
      iunlock(ip);
    8000419c:	854e                	mv	a0,s3
    8000419e:	00000097          	auipc	ra,0x0
    800041a2:	aa4080e7          	jalr	-1372(ra) # 80003c42 <iunlock>
      return ip;
    800041a6:	bfe9                	j	80004180 <namex+0x6e>
      iunlockput(ip);
    800041a8:	854e                	mv	a0,s3
    800041aa:	00000097          	auipc	ra,0x0
    800041ae:	c38080e7          	jalr	-968(ra) # 80003de2 <iunlockput>
      return 0;
    800041b2:	89e6                	mv	s3,s9
    800041b4:	b7f1                	j	80004180 <namex+0x6e>
  len = path - s;
    800041b6:	40b48633          	sub	a2,s1,a1
    800041ba:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800041be:	099c5463          	bge	s8,s9,80004246 <namex+0x134>
    memmove(name, s, DIRSIZ);
    800041c2:	4639                	li	a2,14
    800041c4:	8552                	mv	a0,s4
    800041c6:	ffffd097          	auipc	ra,0xffffd
    800041ca:	b98080e7          	jalr	-1128(ra) # 80000d5e <memmove>
  while(*path == '/')
    800041ce:	0004c783          	lbu	a5,0(s1)
    800041d2:	01279763          	bne	a5,s2,800041e0 <namex+0xce>
    path++;
    800041d6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041d8:	0004c783          	lbu	a5,0(s1)
    800041dc:	ff278de3          	beq	a5,s2,800041d6 <namex+0xc4>
    ilock(ip);
    800041e0:	854e                	mv	a0,s3
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	99e080e7          	jalr	-1634(ra) # 80003b80 <ilock>
    if(ip->type != T_DIR){
    800041ea:	04499783          	lh	a5,68(s3)
    800041ee:	f97793e3          	bne	a5,s7,80004174 <namex+0x62>
    if(nameiparent && *path == '\0'){
    800041f2:	000a8563          	beqz	s5,800041fc <namex+0xea>
    800041f6:	0004c783          	lbu	a5,0(s1)
    800041fa:	d3cd                	beqz	a5,8000419c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041fc:	865a                	mv	a2,s6
    800041fe:	85d2                	mv	a1,s4
    80004200:	854e                	mv	a0,s3
    80004202:	00000097          	auipc	ra,0x0
    80004206:	e60080e7          	jalr	-416(ra) # 80004062 <dirlookup>
    8000420a:	8caa                	mv	s9,a0
    8000420c:	dd51                	beqz	a0,800041a8 <namex+0x96>
    iunlockput(ip);
    8000420e:	854e                	mv	a0,s3
    80004210:	00000097          	auipc	ra,0x0
    80004214:	bd2080e7          	jalr	-1070(ra) # 80003de2 <iunlockput>
    ip = next;
    80004218:	89e6                	mv	s3,s9
  while(*path == '/')
    8000421a:	0004c783          	lbu	a5,0(s1)
    8000421e:	05279763          	bne	a5,s2,8000426c <namex+0x15a>
    path++;
    80004222:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004224:	0004c783          	lbu	a5,0(s1)
    80004228:	ff278de3          	beq	a5,s2,80004222 <namex+0x110>
  if(*path == 0)
    8000422c:	c79d                	beqz	a5,8000425a <namex+0x148>
    path++;
    8000422e:	85a6                	mv	a1,s1
  len = path - s;
    80004230:	8cda                	mv	s9,s6
    80004232:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004234:	01278963          	beq	a5,s2,80004246 <namex+0x134>
    80004238:	dfbd                	beqz	a5,800041b6 <namex+0xa4>
    path++;
    8000423a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000423c:	0004c783          	lbu	a5,0(s1)
    80004240:	ff279ce3          	bne	a5,s2,80004238 <namex+0x126>
    80004244:	bf8d                	j	800041b6 <namex+0xa4>
    memmove(name, s, len);
    80004246:	2601                	sext.w	a2,a2
    80004248:	8552                	mv	a0,s4
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	b14080e7          	jalr	-1260(ra) # 80000d5e <memmove>
    name[len] = 0;
    80004252:	9cd2                	add	s9,s9,s4
    80004254:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004258:	bf9d                	j	800041ce <namex+0xbc>
  if(nameiparent){
    8000425a:	f20a83e3          	beqz	s5,80004180 <namex+0x6e>
    iput(ip);
    8000425e:	854e                	mv	a0,s3
    80004260:	00000097          	auipc	ra,0x0
    80004264:	ada080e7          	jalr	-1318(ra) # 80003d3a <iput>
    return 0;
    80004268:	4981                	li	s3,0
    8000426a:	bf19                	j	80004180 <namex+0x6e>
  if(*path == 0)
    8000426c:	d7fd                	beqz	a5,8000425a <namex+0x148>
  while(*path != '/' && *path != 0)
    8000426e:	0004c783          	lbu	a5,0(s1)
    80004272:	85a6                	mv	a1,s1
    80004274:	b7d1                	j	80004238 <namex+0x126>

0000000080004276 <dirlink>:
{
    80004276:	7139                	addi	sp,sp,-64
    80004278:	fc06                	sd	ra,56(sp)
    8000427a:	f822                	sd	s0,48(sp)
    8000427c:	f426                	sd	s1,40(sp)
    8000427e:	f04a                	sd	s2,32(sp)
    80004280:	ec4e                	sd	s3,24(sp)
    80004282:	e852                	sd	s4,16(sp)
    80004284:	0080                	addi	s0,sp,64
    80004286:	892a                	mv	s2,a0
    80004288:	8a2e                	mv	s4,a1
    8000428a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000428c:	4601                	li	a2,0
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	dd4080e7          	jalr	-556(ra) # 80004062 <dirlookup>
    80004296:	e93d                	bnez	a0,8000430c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004298:	04c92483          	lw	s1,76(s2)
    8000429c:	c49d                	beqz	s1,800042ca <dirlink+0x54>
    8000429e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042a0:	4741                	li	a4,16
    800042a2:	86a6                	mv	a3,s1
    800042a4:	fc040613          	addi	a2,s0,-64
    800042a8:	4581                	li	a1,0
    800042aa:	854a                	mv	a0,s2
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	b88080e7          	jalr	-1144(ra) # 80003e34 <readi>
    800042b4:	47c1                	li	a5,16
    800042b6:	06f51163          	bne	a0,a5,80004318 <dirlink+0xa2>
    if(de.inum == 0)
    800042ba:	fc045783          	lhu	a5,-64(s0)
    800042be:	c791                	beqz	a5,800042ca <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c0:	24c1                	addiw	s1,s1,16
    800042c2:	04c92783          	lw	a5,76(s2)
    800042c6:	fcf4ede3          	bltu	s1,a5,800042a0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042ca:	4639                	li	a2,14
    800042cc:	85d2                	mv	a1,s4
    800042ce:	fc240513          	addi	a0,s0,-62
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	b44080e7          	jalr	-1212(ra) # 80000e16 <strncpy>
  de.inum = inum;
    800042da:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042de:	4741                	li	a4,16
    800042e0:	86a6                	mv	a3,s1
    800042e2:	fc040613          	addi	a2,s0,-64
    800042e6:	4581                	li	a1,0
    800042e8:	854a                	mv	a0,s2
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	c42080e7          	jalr	-958(ra) # 80003f2c <writei>
    800042f2:	872a                	mv	a4,a0
    800042f4:	47c1                	li	a5,16
  return 0;
    800042f6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f8:	02f71863          	bne	a4,a5,80004328 <dirlink+0xb2>
}
    800042fc:	70e2                	ld	ra,56(sp)
    800042fe:	7442                	ld	s0,48(sp)
    80004300:	74a2                	ld	s1,40(sp)
    80004302:	7902                	ld	s2,32(sp)
    80004304:	69e2                	ld	s3,24(sp)
    80004306:	6a42                	ld	s4,16(sp)
    80004308:	6121                	addi	sp,sp,64
    8000430a:	8082                	ret
    iput(ip);
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	a2e080e7          	jalr	-1490(ra) # 80003d3a <iput>
    return -1;
    80004314:	557d                	li	a0,-1
    80004316:	b7dd                	j	800042fc <dirlink+0x86>
      panic("dirlink read");
    80004318:	00004517          	auipc	a0,0x4
    8000431c:	2e850513          	addi	a0,a0,744 # 80008600 <syscalls+0x1e0>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	22a080e7          	jalr	554(ra) # 8000054a <panic>
    panic("dirlink");
    80004328:	00004517          	auipc	a0,0x4
    8000432c:	3f850513          	addi	a0,a0,1016 # 80008720 <syscalls+0x300>
    80004330:	ffffc097          	auipc	ra,0xffffc
    80004334:	21a080e7          	jalr	538(ra) # 8000054a <panic>

0000000080004338 <namei>:

struct inode*
namei(char *path)
{
    80004338:	1101                	addi	sp,sp,-32
    8000433a:	ec06                	sd	ra,24(sp)
    8000433c:	e822                	sd	s0,16(sp)
    8000433e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004340:	fe040613          	addi	a2,s0,-32
    80004344:	4581                	li	a1,0
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	dcc080e7          	jalr	-564(ra) # 80004112 <namex>
}
    8000434e:	60e2                	ld	ra,24(sp)
    80004350:	6442                	ld	s0,16(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004356:	1141                	addi	sp,sp,-16
    80004358:	e406                	sd	ra,8(sp)
    8000435a:	e022                	sd	s0,0(sp)
    8000435c:	0800                	addi	s0,sp,16
    8000435e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004360:	4585                	li	a1,1
    80004362:	00000097          	auipc	ra,0x0
    80004366:	db0080e7          	jalr	-592(ra) # 80004112 <namex>
}
    8000436a:	60a2                	ld	ra,8(sp)
    8000436c:	6402                	ld	s0,0(sp)
    8000436e:	0141                	addi	sp,sp,16
    80004370:	8082                	ret

0000000080004372 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000437e:	0005e917          	auipc	s2,0x5e
    80004382:	2ca90913          	addi	s2,s2,714 # 80062648 <log>
    80004386:	01892583          	lw	a1,24(s2)
    8000438a:	02892503          	lw	a0,40(s2)
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	ff0080e7          	jalr	-16(ra) # 8000337e <bread>
    80004396:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004398:	02c92683          	lw	a3,44(s2)
    8000439c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000439e:	02d05763          	blez	a3,800043cc <write_head+0x5a>
    800043a2:	0005e797          	auipc	a5,0x5e
    800043a6:	2d678793          	addi	a5,a5,726 # 80062678 <log+0x30>
    800043aa:	05c50713          	addi	a4,a0,92
    800043ae:	36fd                	addiw	a3,a3,-1
    800043b0:	1682                	slli	a3,a3,0x20
    800043b2:	9281                	srli	a3,a3,0x20
    800043b4:	068a                	slli	a3,a3,0x2
    800043b6:	0005e617          	auipc	a2,0x5e
    800043ba:	2c660613          	addi	a2,a2,710 # 8006267c <log+0x34>
    800043be:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043c0:	4390                	lw	a2,0(a5)
    800043c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	0791                	addi	a5,a5,4
    800043c6:	0711                	addi	a4,a4,4
    800043c8:	fed79ce3          	bne	a5,a3,800043c0 <write_head+0x4e>
  }
  bwrite(buf);
    800043cc:	8526                	mv	a0,s1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	0a2080e7          	jalr	162(ra) # 80003470 <bwrite>
  brelse(buf);
    800043d6:	8526                	mv	a0,s1
    800043d8:	fffff097          	auipc	ra,0xfffff
    800043dc:	0d6080e7          	jalr	214(ra) # 800034ae <brelse>
}
    800043e0:	60e2                	ld	ra,24(sp)
    800043e2:	6442                	ld	s0,16(sp)
    800043e4:	64a2                	ld	s1,8(sp)
    800043e6:	6902                	ld	s2,0(sp)
    800043e8:	6105                	addi	sp,sp,32
    800043ea:	8082                	ret

00000000800043ec <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ec:	0005e797          	auipc	a5,0x5e
    800043f0:	2887a783          	lw	a5,648(a5) # 80062674 <log+0x2c>
    800043f4:	0af05d63          	blez	a5,800044ae <install_trans+0xc2>
{
    800043f8:	7139                	addi	sp,sp,-64
    800043fa:	fc06                	sd	ra,56(sp)
    800043fc:	f822                	sd	s0,48(sp)
    800043fe:	f426                	sd	s1,40(sp)
    80004400:	f04a                	sd	s2,32(sp)
    80004402:	ec4e                	sd	s3,24(sp)
    80004404:	e852                	sd	s4,16(sp)
    80004406:	e456                	sd	s5,8(sp)
    80004408:	e05a                	sd	s6,0(sp)
    8000440a:	0080                	addi	s0,sp,64
    8000440c:	8b2a                	mv	s6,a0
    8000440e:	0005ea97          	auipc	s5,0x5e
    80004412:	26aa8a93          	addi	s5,s5,618 # 80062678 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004416:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004418:	0005e997          	auipc	s3,0x5e
    8000441c:	23098993          	addi	s3,s3,560 # 80062648 <log>
    80004420:	a00d                	j	80004442 <install_trans+0x56>
    brelse(lbuf);
    80004422:	854a                	mv	a0,s2
    80004424:	fffff097          	auipc	ra,0xfffff
    80004428:	08a080e7          	jalr	138(ra) # 800034ae <brelse>
    brelse(dbuf);
    8000442c:	8526                	mv	a0,s1
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	080080e7          	jalr	128(ra) # 800034ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004436:	2a05                	addiw	s4,s4,1
    80004438:	0a91                	addi	s5,s5,4
    8000443a:	02c9a783          	lw	a5,44(s3)
    8000443e:	04fa5e63          	bge	s4,a5,8000449a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004442:	0189a583          	lw	a1,24(s3)
    80004446:	014585bb          	addw	a1,a1,s4
    8000444a:	2585                	addiw	a1,a1,1
    8000444c:	0289a503          	lw	a0,40(s3)
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	f2e080e7          	jalr	-210(ra) # 8000337e <bread>
    80004458:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000445a:	000aa583          	lw	a1,0(s5)
    8000445e:	0289a503          	lw	a0,40(s3)
    80004462:	fffff097          	auipc	ra,0xfffff
    80004466:	f1c080e7          	jalr	-228(ra) # 8000337e <bread>
    8000446a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000446c:	40000613          	li	a2,1024
    80004470:	05890593          	addi	a1,s2,88
    80004474:	05850513          	addi	a0,a0,88
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	8e6080e7          	jalr	-1818(ra) # 80000d5e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004480:	8526                	mv	a0,s1
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	fee080e7          	jalr	-18(ra) # 80003470 <bwrite>
    if(recovering == 0)
    8000448a:	f80b1ce3          	bnez	s6,80004422 <install_trans+0x36>
      bunpin(dbuf);
    8000448e:	8526                	mv	a0,s1
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	0f8080e7          	jalr	248(ra) # 80003588 <bunpin>
    80004498:	b769                	j	80004422 <install_trans+0x36>
}
    8000449a:	70e2                	ld	ra,56(sp)
    8000449c:	7442                	ld	s0,48(sp)
    8000449e:	74a2                	ld	s1,40(sp)
    800044a0:	7902                	ld	s2,32(sp)
    800044a2:	69e2                	ld	s3,24(sp)
    800044a4:	6a42                	ld	s4,16(sp)
    800044a6:	6aa2                	ld	s5,8(sp)
    800044a8:	6b02                	ld	s6,0(sp)
    800044aa:	6121                	addi	sp,sp,64
    800044ac:	8082                	ret
    800044ae:	8082                	ret

00000000800044b0 <initlog>:
{
    800044b0:	7179                	addi	sp,sp,-48
    800044b2:	f406                	sd	ra,40(sp)
    800044b4:	f022                	sd	s0,32(sp)
    800044b6:	ec26                	sd	s1,24(sp)
    800044b8:	e84a                	sd	s2,16(sp)
    800044ba:	e44e                	sd	s3,8(sp)
    800044bc:	1800                	addi	s0,sp,48
    800044be:	892a                	mv	s2,a0
    800044c0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044c2:	0005e497          	auipc	s1,0x5e
    800044c6:	18648493          	addi	s1,s1,390 # 80062648 <log>
    800044ca:	00004597          	auipc	a1,0x4
    800044ce:	14658593          	addi	a1,a1,326 # 80008610 <syscalls+0x1f0>
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	6a2080e7          	jalr	1698(ra) # 80000b76 <initlock>
  log.start = sb->logstart;
    800044dc:	0149a583          	lw	a1,20(s3)
    800044e0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044e2:	0109a783          	lw	a5,16(s3)
    800044e6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044e8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044ec:	854a                	mv	a0,s2
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	e90080e7          	jalr	-368(ra) # 8000337e <bread>
  log.lh.n = lh->n;
    800044f6:	4d34                	lw	a3,88(a0)
    800044f8:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044fa:	02d05563          	blez	a3,80004524 <initlog+0x74>
    800044fe:	05c50793          	addi	a5,a0,92
    80004502:	0005e717          	auipc	a4,0x5e
    80004506:	17670713          	addi	a4,a4,374 # 80062678 <log+0x30>
    8000450a:	36fd                	addiw	a3,a3,-1
    8000450c:	1682                	slli	a3,a3,0x20
    8000450e:	9281                	srli	a3,a3,0x20
    80004510:	068a                	slli	a3,a3,0x2
    80004512:	06050613          	addi	a2,a0,96
    80004516:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004518:	4390                	lw	a2,0(a5)
    8000451a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000451c:	0791                	addi	a5,a5,4
    8000451e:	0711                	addi	a4,a4,4
    80004520:	fed79ce3          	bne	a5,a3,80004518 <initlog+0x68>
  brelse(buf);
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	f8a080e7          	jalr	-118(ra) # 800034ae <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000452c:	4505                	li	a0,1
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	ebe080e7          	jalr	-322(ra) # 800043ec <install_trans>
  log.lh.n = 0;
    80004536:	0005e797          	auipc	a5,0x5e
    8000453a:	1207af23          	sw	zero,318(a5) # 80062674 <log+0x2c>
  write_head(); // clear the log
    8000453e:	00000097          	auipc	ra,0x0
    80004542:	e34080e7          	jalr	-460(ra) # 80004372 <write_head>
}
    80004546:	70a2                	ld	ra,40(sp)
    80004548:	7402                	ld	s0,32(sp)
    8000454a:	64e2                	ld	s1,24(sp)
    8000454c:	6942                	ld	s2,16(sp)
    8000454e:	69a2                	ld	s3,8(sp)
    80004550:	6145                	addi	sp,sp,48
    80004552:	8082                	ret

0000000080004554 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	e426                	sd	s1,8(sp)
    8000455c:	e04a                	sd	s2,0(sp)
    8000455e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004560:	0005e517          	auipc	a0,0x5e
    80004564:	0e850513          	addi	a0,a0,232 # 80062648 <log>
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	69e080e7          	jalr	1694(ra) # 80000c06 <acquire>
  while(1){
    if(log.committing){
    80004570:	0005e497          	auipc	s1,0x5e
    80004574:	0d848493          	addi	s1,s1,216 # 80062648 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004578:	4979                	li	s2,30
    8000457a:	a039                	j	80004588 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000457c:	85a6                	mv	a1,s1
    8000457e:	8526                	mv	a0,s1
    80004580:	ffffe097          	auipc	ra,0xffffe
    80004584:	d30080e7          	jalr	-720(ra) # 800022b0 <sleep>
    if(log.committing){
    80004588:	50dc                	lw	a5,36(s1)
    8000458a:	fbed                	bnez	a5,8000457c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000458c:	509c                	lw	a5,32(s1)
    8000458e:	0017871b          	addiw	a4,a5,1
    80004592:	0007069b          	sext.w	a3,a4
    80004596:	0027179b          	slliw	a5,a4,0x2
    8000459a:	9fb9                	addw	a5,a5,a4
    8000459c:	0017979b          	slliw	a5,a5,0x1
    800045a0:	54d8                	lw	a4,44(s1)
    800045a2:	9fb9                	addw	a5,a5,a4
    800045a4:	00f95963          	bge	s2,a5,800045b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045a8:	85a6                	mv	a1,s1
    800045aa:	8526                	mv	a0,s1
    800045ac:	ffffe097          	auipc	ra,0xffffe
    800045b0:	d04080e7          	jalr	-764(ra) # 800022b0 <sleep>
    800045b4:	bfd1                	j	80004588 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045b6:	0005e517          	auipc	a0,0x5e
    800045ba:	09250513          	addi	a0,a0,146 # 80062648 <log>
    800045be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6fa080e7          	jalr	1786(ra) # 80000cba <release>
      break;
    }
  }
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045d4:	7139                	addi	sp,sp,-64
    800045d6:	fc06                	sd	ra,56(sp)
    800045d8:	f822                	sd	s0,48(sp)
    800045da:	f426                	sd	s1,40(sp)
    800045dc:	f04a                	sd	s2,32(sp)
    800045de:	ec4e                	sd	s3,24(sp)
    800045e0:	e852                	sd	s4,16(sp)
    800045e2:	e456                	sd	s5,8(sp)
    800045e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045e6:	0005e497          	auipc	s1,0x5e
    800045ea:	06248493          	addi	s1,s1,98 # 80062648 <log>
    800045ee:	8526                	mv	a0,s1
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	616080e7          	jalr	1558(ra) # 80000c06 <acquire>
  log.outstanding -= 1;
    800045f8:	509c                	lw	a5,32(s1)
    800045fa:	37fd                	addiw	a5,a5,-1
    800045fc:	0007891b          	sext.w	s2,a5
    80004600:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004602:	50dc                	lw	a5,36(s1)
    80004604:	e7b9                	bnez	a5,80004652 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004606:	04091e63          	bnez	s2,80004662 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000460a:	0005e497          	auipc	s1,0x5e
    8000460e:	03e48493          	addi	s1,s1,62 # 80062648 <log>
    80004612:	4785                	li	a5,1
    80004614:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004616:	8526                	mv	a0,s1
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	6a2080e7          	jalr	1698(ra) # 80000cba <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004620:	54dc                	lw	a5,44(s1)
    80004622:	06f04763          	bgtz	a5,80004690 <end_op+0xbc>
    acquire(&log.lock);
    80004626:	0005e497          	auipc	s1,0x5e
    8000462a:	02248493          	addi	s1,s1,34 # 80062648 <log>
    8000462e:	8526                	mv	a0,s1
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	5d6080e7          	jalr	1494(ra) # 80000c06 <acquire>
    log.committing = 0;
    80004638:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffe097          	auipc	ra,0xffffe
    80004642:	df6080e7          	jalr	-522(ra) # 80002434 <wakeup>
    release(&log.lock);
    80004646:	8526                	mv	a0,s1
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	672080e7          	jalr	1650(ra) # 80000cba <release>
}
    80004650:	a03d                	j	8000467e <end_op+0xaa>
    panic("log.committing");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	fc650513          	addi	a0,a0,-58 # 80008618 <syscalls+0x1f8>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	ef0080e7          	jalr	-272(ra) # 8000054a <panic>
    wakeup(&log);
    80004662:	0005e497          	auipc	s1,0x5e
    80004666:	fe648493          	addi	s1,s1,-26 # 80062648 <log>
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	dc8080e7          	jalr	-568(ra) # 80002434 <wakeup>
  release(&log.lock);
    80004674:	8526                	mv	a0,s1
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	644080e7          	jalr	1604(ra) # 80000cba <release>
}
    8000467e:	70e2                	ld	ra,56(sp)
    80004680:	7442                	ld	s0,48(sp)
    80004682:	74a2                	ld	s1,40(sp)
    80004684:	7902                	ld	s2,32(sp)
    80004686:	69e2                	ld	s3,24(sp)
    80004688:	6a42                	ld	s4,16(sp)
    8000468a:	6aa2                	ld	s5,8(sp)
    8000468c:	6121                	addi	sp,sp,64
    8000468e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004690:	0005ea97          	auipc	s5,0x5e
    80004694:	fe8a8a93          	addi	s5,s5,-24 # 80062678 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004698:	0005ea17          	auipc	s4,0x5e
    8000469c:	fb0a0a13          	addi	s4,s4,-80 # 80062648 <log>
    800046a0:	018a2583          	lw	a1,24(s4)
    800046a4:	012585bb          	addw	a1,a1,s2
    800046a8:	2585                	addiw	a1,a1,1
    800046aa:	028a2503          	lw	a0,40(s4)
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	cd0080e7          	jalr	-816(ra) # 8000337e <bread>
    800046b6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046b8:	000aa583          	lw	a1,0(s5)
    800046bc:	028a2503          	lw	a0,40(s4)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	cbe080e7          	jalr	-834(ra) # 8000337e <bread>
    800046c8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046ca:	40000613          	li	a2,1024
    800046ce:	05850593          	addi	a1,a0,88
    800046d2:	05848513          	addi	a0,s1,88
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	688080e7          	jalr	1672(ra) # 80000d5e <memmove>
    bwrite(to);  // write the log
    800046de:	8526                	mv	a0,s1
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	d90080e7          	jalr	-624(ra) # 80003470 <bwrite>
    brelse(from);
    800046e8:	854e                	mv	a0,s3
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	dc4080e7          	jalr	-572(ra) # 800034ae <brelse>
    brelse(to);
    800046f2:	8526                	mv	a0,s1
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	dba080e7          	jalr	-582(ra) # 800034ae <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046fc:	2905                	addiw	s2,s2,1
    800046fe:	0a91                	addi	s5,s5,4
    80004700:	02ca2783          	lw	a5,44(s4)
    80004704:	f8f94ee3          	blt	s2,a5,800046a0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	c6a080e7          	jalr	-918(ra) # 80004372 <write_head>
    install_trans(0); // Now install writes to home locations
    80004710:	4501                	li	a0,0
    80004712:	00000097          	auipc	ra,0x0
    80004716:	cda080e7          	jalr	-806(ra) # 800043ec <install_trans>
    log.lh.n = 0;
    8000471a:	0005e797          	auipc	a5,0x5e
    8000471e:	f407ad23          	sw	zero,-166(a5) # 80062674 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004722:	00000097          	auipc	ra,0x0
    80004726:	c50080e7          	jalr	-944(ra) # 80004372 <write_head>
    8000472a:	bdf5                	j	80004626 <end_op+0x52>

000000008000472c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000472c:	1101                	addi	sp,sp,-32
    8000472e:	ec06                	sd	ra,24(sp)
    80004730:	e822                	sd	s0,16(sp)
    80004732:	e426                	sd	s1,8(sp)
    80004734:	e04a                	sd	s2,0(sp)
    80004736:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004738:	0005e717          	auipc	a4,0x5e
    8000473c:	f3c72703          	lw	a4,-196(a4) # 80062674 <log+0x2c>
    80004740:	47f5                	li	a5,29
    80004742:	08e7c063          	blt	a5,a4,800047c2 <log_write+0x96>
    80004746:	84aa                	mv	s1,a0
    80004748:	0005e797          	auipc	a5,0x5e
    8000474c:	f1c7a783          	lw	a5,-228(a5) # 80062664 <log+0x1c>
    80004750:	37fd                	addiw	a5,a5,-1
    80004752:	06f75863          	bge	a4,a5,800047c2 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004756:	0005e797          	auipc	a5,0x5e
    8000475a:	f127a783          	lw	a5,-238(a5) # 80062668 <log+0x20>
    8000475e:	06f05a63          	blez	a5,800047d2 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004762:	0005e917          	auipc	s2,0x5e
    80004766:	ee690913          	addi	s2,s2,-282 # 80062648 <log>
    8000476a:	854a                	mv	a0,s2
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	49a080e7          	jalr	1178(ra) # 80000c06 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004774:	02c92603          	lw	a2,44(s2)
    80004778:	06c05563          	blez	a2,800047e2 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000477c:	44cc                	lw	a1,12(s1)
    8000477e:	0005e717          	auipc	a4,0x5e
    80004782:	efa70713          	addi	a4,a4,-262 # 80062678 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004786:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004788:	4314                	lw	a3,0(a4)
    8000478a:	04b68d63          	beq	a3,a1,800047e4 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000478e:	2785                	addiw	a5,a5,1
    80004790:	0711                	addi	a4,a4,4
    80004792:	fec79be3          	bne	a5,a2,80004788 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004796:	0621                	addi	a2,a2,8
    80004798:	060a                	slli	a2,a2,0x2
    8000479a:	0005e797          	auipc	a5,0x5e
    8000479e:	eae78793          	addi	a5,a5,-338 # 80062648 <log>
    800047a2:	963e                	add	a2,a2,a5
    800047a4:	44dc                	lw	a5,12(s1)
    800047a6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047a8:	8526                	mv	a0,s1
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	da2080e7          	jalr	-606(ra) # 8000354c <bpin>
    log.lh.n++;
    800047b2:	0005e717          	auipc	a4,0x5e
    800047b6:	e9670713          	addi	a4,a4,-362 # 80062648 <log>
    800047ba:	575c                	lw	a5,44(a4)
    800047bc:	2785                	addiw	a5,a5,1
    800047be:	d75c                	sw	a5,44(a4)
    800047c0:	a83d                	j	800047fe <log_write+0xd2>
    panic("too big a transaction");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	e6650513          	addi	a0,a0,-410 # 80008628 <syscalls+0x208>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d80080e7          	jalr	-640(ra) # 8000054a <panic>
    panic("log_write outside of trans");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	e6e50513          	addi	a0,a0,-402 # 80008640 <syscalls+0x220>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d70080e7          	jalr	-656(ra) # 8000054a <panic>
  for (i = 0; i < log.lh.n; i++) {
    800047e2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800047e4:	00878713          	addi	a4,a5,8
    800047e8:	00271693          	slli	a3,a4,0x2
    800047ec:	0005e717          	auipc	a4,0x5e
    800047f0:	e5c70713          	addi	a4,a4,-420 # 80062648 <log>
    800047f4:	9736                	add	a4,a4,a3
    800047f6:	44d4                	lw	a3,12(s1)
    800047f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047fa:	faf607e3          	beq	a2,a5,800047a8 <log_write+0x7c>
  }
  release(&log.lock);
    800047fe:	0005e517          	auipc	a0,0x5e
    80004802:	e4a50513          	addi	a0,a0,-438 # 80062648 <log>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	4b4080e7          	jalr	1204(ra) # 80000cba <release>
}
    8000480e:	60e2                	ld	ra,24(sp)
    80004810:	6442                	ld	s0,16(sp)
    80004812:	64a2                	ld	s1,8(sp)
    80004814:	6902                	ld	s2,0(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000481a:	1101                	addi	sp,sp,-32
    8000481c:	ec06                	sd	ra,24(sp)
    8000481e:	e822                	sd	s0,16(sp)
    80004820:	e426                	sd	s1,8(sp)
    80004822:	e04a                	sd	s2,0(sp)
    80004824:	1000                	addi	s0,sp,32
    80004826:	84aa                	mv	s1,a0
    80004828:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000482a:	00004597          	auipc	a1,0x4
    8000482e:	e3658593          	addi	a1,a1,-458 # 80008660 <syscalls+0x240>
    80004832:	0521                	addi	a0,a0,8
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	342080e7          	jalr	834(ra) # 80000b76 <initlock>
  lk->name = name;
    8000483c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004840:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004844:	0204a423          	sw	zero,40(s1)
}
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6902                	ld	s2,0(sp)
    80004850:	6105                	addi	sp,sp,32
    80004852:	8082                	ret

0000000080004854 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004854:	1101                	addi	sp,sp,-32
    80004856:	ec06                	sd	ra,24(sp)
    80004858:	e822                	sd	s0,16(sp)
    8000485a:	e426                	sd	s1,8(sp)
    8000485c:	e04a                	sd	s2,0(sp)
    8000485e:	1000                	addi	s0,sp,32
    80004860:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004862:	00850913          	addi	s2,a0,8
    80004866:	854a                	mv	a0,s2
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	39e080e7          	jalr	926(ra) # 80000c06 <acquire>
  while (lk->locked) {
    80004870:	409c                	lw	a5,0(s1)
    80004872:	cb89                	beqz	a5,80004884 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004874:	85ca                	mv	a1,s2
    80004876:	8526                	mv	a0,s1
    80004878:	ffffe097          	auipc	ra,0xffffe
    8000487c:	a38080e7          	jalr	-1480(ra) # 800022b0 <sleep>
  while (lk->locked) {
    80004880:	409c                	lw	a5,0(s1)
    80004882:	fbed                	bnez	a5,80004874 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004884:	4785                	li	a5,1
    80004886:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004888:	ffffd097          	auipc	ra,0xffffd
    8000488c:	186080e7          	jalr	390(ra) # 80001a0e <myproc>
    80004890:	5d1c                	lw	a5,56(a0)
    80004892:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004894:	854a                	mv	a0,s2
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	424080e7          	jalr	1060(ra) # 80000cba <release>
}
    8000489e:	60e2                	ld	ra,24(sp)
    800048a0:	6442                	ld	s0,16(sp)
    800048a2:	64a2                	ld	s1,8(sp)
    800048a4:	6902                	ld	s2,0(sp)
    800048a6:	6105                	addi	sp,sp,32
    800048a8:	8082                	ret

00000000800048aa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048aa:	1101                	addi	sp,sp,-32
    800048ac:	ec06                	sd	ra,24(sp)
    800048ae:	e822                	sd	s0,16(sp)
    800048b0:	e426                	sd	s1,8(sp)
    800048b2:	e04a                	sd	s2,0(sp)
    800048b4:	1000                	addi	s0,sp,32
    800048b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b8:	00850913          	addi	s2,a0,8
    800048bc:	854a                	mv	a0,s2
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	348080e7          	jalr	840(ra) # 80000c06 <acquire>
  lk->locked = 0;
    800048c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffe097          	auipc	ra,0xffffe
    800048d4:	b64080e7          	jalr	-1180(ra) # 80002434 <wakeup>
  release(&lk->lk);
    800048d8:	854a                	mv	a0,s2
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	3e0080e7          	jalr	992(ra) # 80000cba <release>
}
    800048e2:	60e2                	ld	ra,24(sp)
    800048e4:	6442                	ld	s0,16(sp)
    800048e6:	64a2                	ld	s1,8(sp)
    800048e8:	6902                	ld	s2,0(sp)
    800048ea:	6105                	addi	sp,sp,32
    800048ec:	8082                	ret

00000000800048ee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048ee:	7179                	addi	sp,sp,-48
    800048f0:	f406                	sd	ra,40(sp)
    800048f2:	f022                	sd	s0,32(sp)
    800048f4:	ec26                	sd	s1,24(sp)
    800048f6:	e84a                	sd	s2,16(sp)
    800048f8:	e44e                	sd	s3,8(sp)
    800048fa:	1800                	addi	s0,sp,48
    800048fc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048fe:	00850913          	addi	s2,a0,8
    80004902:	854a                	mv	a0,s2
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	302080e7          	jalr	770(ra) # 80000c06 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000490c:	409c                	lw	a5,0(s1)
    8000490e:	ef99                	bnez	a5,8000492c <holdingsleep+0x3e>
    80004910:	4481                	li	s1,0
  release(&lk->lk);
    80004912:	854a                	mv	a0,s2
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	3a6080e7          	jalr	934(ra) # 80000cba <release>
  return r;
}
    8000491c:	8526                	mv	a0,s1
    8000491e:	70a2                	ld	ra,40(sp)
    80004920:	7402                	ld	s0,32(sp)
    80004922:	64e2                	ld	s1,24(sp)
    80004924:	6942                	ld	s2,16(sp)
    80004926:	69a2                	ld	s3,8(sp)
    80004928:	6145                	addi	sp,sp,48
    8000492a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000492c:	0284a983          	lw	s3,40(s1)
    80004930:	ffffd097          	auipc	ra,0xffffd
    80004934:	0de080e7          	jalr	222(ra) # 80001a0e <myproc>
    80004938:	5d04                	lw	s1,56(a0)
    8000493a:	413484b3          	sub	s1,s1,s3
    8000493e:	0014b493          	seqz	s1,s1
    80004942:	bfc1                	j	80004912 <holdingsleep+0x24>

0000000080004944 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004944:	1141                	addi	sp,sp,-16
    80004946:	e406                	sd	ra,8(sp)
    80004948:	e022                	sd	s0,0(sp)
    8000494a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000494c:	00004597          	auipc	a1,0x4
    80004950:	d2458593          	addi	a1,a1,-732 # 80008670 <syscalls+0x250>
    80004954:	0005e517          	auipc	a0,0x5e
    80004958:	e3c50513          	addi	a0,a0,-452 # 80062790 <ftable>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	21a080e7          	jalr	538(ra) # 80000b76 <initlock>
}
    80004964:	60a2                	ld	ra,8(sp)
    80004966:	6402                	ld	s0,0(sp)
    80004968:	0141                	addi	sp,sp,16
    8000496a:	8082                	ret

000000008000496c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000496c:	1101                	addi	sp,sp,-32
    8000496e:	ec06                	sd	ra,24(sp)
    80004970:	e822                	sd	s0,16(sp)
    80004972:	e426                	sd	s1,8(sp)
    80004974:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004976:	0005e517          	auipc	a0,0x5e
    8000497a:	e1a50513          	addi	a0,a0,-486 # 80062790 <ftable>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	288080e7          	jalr	648(ra) # 80000c06 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004986:	0005e497          	auipc	s1,0x5e
    8000498a:	e2248493          	addi	s1,s1,-478 # 800627a8 <ftable+0x18>
    8000498e:	0005f717          	auipc	a4,0x5f
    80004992:	dba70713          	addi	a4,a4,-582 # 80063748 <ftable+0xfb8>
    if(f->ref == 0){
    80004996:	40dc                	lw	a5,4(s1)
    80004998:	cf99                	beqz	a5,800049b6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000499a:	02848493          	addi	s1,s1,40
    8000499e:	fee49ce3          	bne	s1,a4,80004996 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049a2:	0005e517          	auipc	a0,0x5e
    800049a6:	dee50513          	addi	a0,a0,-530 # 80062790 <ftable>
    800049aa:	ffffc097          	auipc	ra,0xffffc
    800049ae:	310080e7          	jalr	784(ra) # 80000cba <release>
  return 0;
    800049b2:	4481                	li	s1,0
    800049b4:	a819                	j	800049ca <filealloc+0x5e>
      f->ref = 1;
    800049b6:	4785                	li	a5,1
    800049b8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049ba:	0005e517          	auipc	a0,0x5e
    800049be:	dd650513          	addi	a0,a0,-554 # 80062790 <ftable>
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	2f8080e7          	jalr	760(ra) # 80000cba <release>
}
    800049ca:	8526                	mv	a0,s1
    800049cc:	60e2                	ld	ra,24(sp)
    800049ce:	6442                	ld	s0,16(sp)
    800049d0:	64a2                	ld	s1,8(sp)
    800049d2:	6105                	addi	sp,sp,32
    800049d4:	8082                	ret

00000000800049d6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049d6:	1101                	addi	sp,sp,-32
    800049d8:	ec06                	sd	ra,24(sp)
    800049da:	e822                	sd	s0,16(sp)
    800049dc:	e426                	sd	s1,8(sp)
    800049de:	1000                	addi	s0,sp,32
    800049e0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049e2:	0005e517          	auipc	a0,0x5e
    800049e6:	dae50513          	addi	a0,a0,-594 # 80062790 <ftable>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	21c080e7          	jalr	540(ra) # 80000c06 <acquire>
  if(f->ref < 1)
    800049f2:	40dc                	lw	a5,4(s1)
    800049f4:	02f05263          	blez	a5,80004a18 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049f8:	2785                	addiw	a5,a5,1
    800049fa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049fc:	0005e517          	auipc	a0,0x5e
    80004a00:	d9450513          	addi	a0,a0,-620 # 80062790 <ftable>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	2b6080e7          	jalr	694(ra) # 80000cba <release>
  return f;
}
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6105                	addi	sp,sp,32
    80004a16:	8082                	ret
    panic("filedup");
    80004a18:	00004517          	auipc	a0,0x4
    80004a1c:	c6050513          	addi	a0,a0,-928 # 80008678 <syscalls+0x258>
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	b2a080e7          	jalr	-1238(ra) # 8000054a <panic>

0000000080004a28 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a28:	7139                	addi	sp,sp,-64
    80004a2a:	fc06                	sd	ra,56(sp)
    80004a2c:	f822                	sd	s0,48(sp)
    80004a2e:	f426                	sd	s1,40(sp)
    80004a30:	f04a                	sd	s2,32(sp)
    80004a32:	ec4e                	sd	s3,24(sp)
    80004a34:	e852                	sd	s4,16(sp)
    80004a36:	e456                	sd	s5,8(sp)
    80004a38:	0080                	addi	s0,sp,64
    80004a3a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a3c:	0005e517          	auipc	a0,0x5e
    80004a40:	d5450513          	addi	a0,a0,-684 # 80062790 <ftable>
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	1c2080e7          	jalr	450(ra) # 80000c06 <acquire>
  if(f->ref < 1)
    80004a4c:	40dc                	lw	a5,4(s1)
    80004a4e:	06f05163          	blez	a5,80004ab0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a52:	37fd                	addiw	a5,a5,-1
    80004a54:	0007871b          	sext.w	a4,a5
    80004a58:	c0dc                	sw	a5,4(s1)
    80004a5a:	06e04363          	bgtz	a4,80004ac0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a5e:	0004a903          	lw	s2,0(s1)
    80004a62:	0094ca83          	lbu	s5,9(s1)
    80004a66:	0104ba03          	ld	s4,16(s1)
    80004a6a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a6e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a72:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a76:	0005e517          	auipc	a0,0x5e
    80004a7a:	d1a50513          	addi	a0,a0,-742 # 80062790 <ftable>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	23c080e7          	jalr	572(ra) # 80000cba <release>

  if(ff.type == FD_PIPE){
    80004a86:	4785                	li	a5,1
    80004a88:	04f90d63          	beq	s2,a5,80004ae2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a8c:	3979                	addiw	s2,s2,-2
    80004a8e:	4785                	li	a5,1
    80004a90:	0527e063          	bltu	a5,s2,80004ad0 <fileclose+0xa8>
    begin_op();
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	ac0080e7          	jalr	-1344(ra) # 80004554 <begin_op>
    iput(ff.ip);
    80004a9c:	854e                	mv	a0,s3
    80004a9e:	fffff097          	auipc	ra,0xfffff
    80004aa2:	29c080e7          	jalr	668(ra) # 80003d3a <iput>
    end_op();
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	b2e080e7          	jalr	-1234(ra) # 800045d4 <end_op>
    80004aae:	a00d                	j	80004ad0 <fileclose+0xa8>
    panic("fileclose");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	bd050513          	addi	a0,a0,-1072 # 80008680 <syscalls+0x260>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a92080e7          	jalr	-1390(ra) # 8000054a <panic>
    release(&ftable.lock);
    80004ac0:	0005e517          	auipc	a0,0x5e
    80004ac4:	cd050513          	addi	a0,a0,-816 # 80062790 <ftable>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1f2080e7          	jalr	498(ra) # 80000cba <release>
  }
}
    80004ad0:	70e2                	ld	ra,56(sp)
    80004ad2:	7442                	ld	s0,48(sp)
    80004ad4:	74a2                	ld	s1,40(sp)
    80004ad6:	7902                	ld	s2,32(sp)
    80004ad8:	69e2                	ld	s3,24(sp)
    80004ada:	6a42                	ld	s4,16(sp)
    80004adc:	6aa2                	ld	s5,8(sp)
    80004ade:	6121                	addi	sp,sp,64
    80004ae0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ae2:	85d6                	mv	a1,s5
    80004ae4:	8552                	mv	a0,s4
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	374080e7          	jalr	884(ra) # 80004e5a <pipeclose>
    80004aee:	b7cd                	j	80004ad0 <fileclose+0xa8>

0000000080004af0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004af0:	715d                	addi	sp,sp,-80
    80004af2:	e486                	sd	ra,72(sp)
    80004af4:	e0a2                	sd	s0,64(sp)
    80004af6:	fc26                	sd	s1,56(sp)
    80004af8:	f84a                	sd	s2,48(sp)
    80004afa:	f44e                	sd	s3,40(sp)
    80004afc:	0880                	addi	s0,sp,80
    80004afe:	84aa                	mv	s1,a0
    80004b00:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	f0c080e7          	jalr	-244(ra) # 80001a0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b0a:	409c                	lw	a5,0(s1)
    80004b0c:	37f9                	addiw	a5,a5,-2
    80004b0e:	4705                	li	a4,1
    80004b10:	04f76863          	bltu	a4,a5,80004b60 <filestat+0x70>
    80004b14:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b16:	6c88                	ld	a0,24(s1)
    80004b18:	fffff097          	auipc	ra,0xfffff
    80004b1c:	068080e7          	jalr	104(ra) # 80003b80 <ilock>
    stati(f->ip, &st);
    80004b20:	fb840593          	addi	a1,s0,-72
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	2e4080e7          	jalr	740(ra) # 80003e0a <stati>
    iunlock(f->ip);
    80004b2e:	6c88                	ld	a0,24(s1)
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	112080e7          	jalr	274(ra) # 80003c42 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b38:	6505                	lui	a0,0x1
    80004b3a:	954a                	add	a0,a0,s2
    80004b3c:	46e1                	li	a3,24
    80004b3e:	fb840613          	addi	a2,s0,-72
    80004b42:	85ce                	mv	a1,s3
    80004b44:	7148                	ld	a0,160(a0)
    80004b46:	ffffd097          	auipc	ra,0xffffd
    80004b4a:	b3c080e7          	jalr	-1220(ra) # 80001682 <copyout>
    80004b4e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b52:	60a6                	ld	ra,72(sp)
    80004b54:	6406                	ld	s0,64(sp)
    80004b56:	74e2                	ld	s1,56(sp)
    80004b58:	7942                	ld	s2,48(sp)
    80004b5a:	79a2                	ld	s3,40(sp)
    80004b5c:	6161                	addi	sp,sp,80
    80004b5e:	8082                	ret
  return -1;
    80004b60:	557d                	li	a0,-1
    80004b62:	bfc5                	j	80004b52 <filestat+0x62>

0000000080004b64 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b64:	7179                	addi	sp,sp,-48
    80004b66:	f406                	sd	ra,40(sp)
    80004b68:	f022                	sd	s0,32(sp)
    80004b6a:	ec26                	sd	s1,24(sp)
    80004b6c:	e84a                	sd	s2,16(sp)
    80004b6e:	e44e                	sd	s3,8(sp)
    80004b70:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b72:	00854783          	lbu	a5,8(a0) # 1008 <_entry-0x7fffeff8>
    80004b76:	c3d5                	beqz	a5,80004c1a <fileread+0xb6>
    80004b78:	84aa                	mv	s1,a0
    80004b7a:	89ae                	mv	s3,a1
    80004b7c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b7e:	411c                	lw	a5,0(a0)
    80004b80:	4705                	li	a4,1
    80004b82:	04e78963          	beq	a5,a4,80004bd4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b86:	470d                	li	a4,3
    80004b88:	04e78d63          	beq	a5,a4,80004be2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b8c:	4709                	li	a4,2
    80004b8e:	06e79e63          	bne	a5,a4,80004c0a <fileread+0xa6>
    ilock(f->ip);
    80004b92:	6d08                	ld	a0,24(a0)
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	fec080e7          	jalr	-20(ra) # 80003b80 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b9c:	874a                	mv	a4,s2
    80004b9e:	5094                	lw	a3,32(s1)
    80004ba0:	864e                	mv	a2,s3
    80004ba2:	4585                	li	a1,1
    80004ba4:	6c88                	ld	a0,24(s1)
    80004ba6:	fffff097          	auipc	ra,0xfffff
    80004baa:	28e080e7          	jalr	654(ra) # 80003e34 <readi>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	00a05563          	blez	a0,80004bba <fileread+0x56>
      f->off += r;
    80004bb4:	509c                	lw	a5,32(s1)
    80004bb6:	9fa9                	addw	a5,a5,a0
    80004bb8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bba:	6c88                	ld	a0,24(s1)
    80004bbc:	fffff097          	auipc	ra,0xfffff
    80004bc0:	086080e7          	jalr	134(ra) # 80003c42 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bc4:	854a                	mv	a0,s2
    80004bc6:	70a2                	ld	ra,40(sp)
    80004bc8:	7402                	ld	s0,32(sp)
    80004bca:	64e2                	ld	s1,24(sp)
    80004bcc:	6942                	ld	s2,16(sp)
    80004bce:	69a2                	ld	s3,8(sp)
    80004bd0:	6145                	addi	sp,sp,48
    80004bd2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004bd4:	6908                	ld	a0,16(a0)
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	3fc080e7          	jalr	1020(ra) # 80004fd2 <piperead>
    80004bde:	892a                	mv	s2,a0
    80004be0:	b7d5                	j	80004bc4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004be2:	02451783          	lh	a5,36(a0)
    80004be6:	03079693          	slli	a3,a5,0x30
    80004bea:	92c1                	srli	a3,a3,0x30
    80004bec:	4725                	li	a4,9
    80004bee:	02d76863          	bltu	a4,a3,80004c1e <fileread+0xba>
    80004bf2:	0792                	slli	a5,a5,0x4
    80004bf4:	0005e717          	auipc	a4,0x5e
    80004bf8:	afc70713          	addi	a4,a4,-1284 # 800626f0 <devsw>
    80004bfc:	97ba                	add	a5,a5,a4
    80004bfe:	639c                	ld	a5,0(a5)
    80004c00:	c38d                	beqz	a5,80004c22 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c02:	4505                	li	a0,1
    80004c04:	9782                	jalr	a5
    80004c06:	892a                	mv	s2,a0
    80004c08:	bf75                	j	80004bc4 <fileread+0x60>
    panic("fileread");
    80004c0a:	00004517          	auipc	a0,0x4
    80004c0e:	a8650513          	addi	a0,a0,-1402 # 80008690 <syscalls+0x270>
    80004c12:	ffffc097          	auipc	ra,0xffffc
    80004c16:	938080e7          	jalr	-1736(ra) # 8000054a <panic>
    return -1;
    80004c1a:	597d                	li	s2,-1
    80004c1c:	b765                	j	80004bc4 <fileread+0x60>
      return -1;
    80004c1e:	597d                	li	s2,-1
    80004c20:	b755                	j	80004bc4 <fileread+0x60>
    80004c22:	597d                	li	s2,-1
    80004c24:	b745                	j	80004bc4 <fileread+0x60>

0000000080004c26 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c26:	00954783          	lbu	a5,9(a0)
    80004c2a:	14078563          	beqz	a5,80004d74 <filewrite+0x14e>
{
    80004c2e:	715d                	addi	sp,sp,-80
    80004c30:	e486                	sd	ra,72(sp)
    80004c32:	e0a2                	sd	s0,64(sp)
    80004c34:	fc26                	sd	s1,56(sp)
    80004c36:	f84a                	sd	s2,48(sp)
    80004c38:	f44e                	sd	s3,40(sp)
    80004c3a:	f052                	sd	s4,32(sp)
    80004c3c:	ec56                	sd	s5,24(sp)
    80004c3e:	e85a                	sd	s6,16(sp)
    80004c40:	e45e                	sd	s7,8(sp)
    80004c42:	e062                	sd	s8,0(sp)
    80004c44:	0880                	addi	s0,sp,80
    80004c46:	892a                	mv	s2,a0
    80004c48:	8aae                	mv	s5,a1
    80004c4a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c4c:	411c                	lw	a5,0(a0)
    80004c4e:	4705                	li	a4,1
    80004c50:	02e78263          	beq	a5,a4,80004c74 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c54:	470d                	li	a4,3
    80004c56:	02e78563          	beq	a5,a4,80004c80 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c5a:	4709                	li	a4,2
    80004c5c:	10e79463          	bne	a5,a4,80004d64 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c60:	0ec05e63          	blez	a2,80004d5c <filewrite+0x136>
    int i = 0;
    80004c64:	4981                	li	s3,0
    80004c66:	6b05                	lui	s6,0x1
    80004c68:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c6c:	6b85                	lui	s7,0x1
    80004c6e:	c00b8b9b          	addiw	s7,s7,-1024
    80004c72:	a851                	j	80004d06 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c74:	6908                	ld	a0,16(a0)
    80004c76:	00000097          	auipc	ra,0x0
    80004c7a:	254080e7          	jalr	596(ra) # 80004eca <pipewrite>
    80004c7e:	a85d                	j	80004d34 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c80:	02451783          	lh	a5,36(a0)
    80004c84:	03079693          	slli	a3,a5,0x30
    80004c88:	92c1                	srli	a3,a3,0x30
    80004c8a:	4725                	li	a4,9
    80004c8c:	0ed76663          	bltu	a4,a3,80004d78 <filewrite+0x152>
    80004c90:	0792                	slli	a5,a5,0x4
    80004c92:	0005e717          	auipc	a4,0x5e
    80004c96:	a5e70713          	addi	a4,a4,-1442 # 800626f0 <devsw>
    80004c9a:	97ba                	add	a5,a5,a4
    80004c9c:	679c                	ld	a5,8(a5)
    80004c9e:	cff9                	beqz	a5,80004d7c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004ca0:	4505                	li	a0,1
    80004ca2:	9782                	jalr	a5
    80004ca4:	a841                	j	80004d34 <filewrite+0x10e>
    80004ca6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004caa:	00000097          	auipc	ra,0x0
    80004cae:	8aa080e7          	jalr	-1878(ra) # 80004554 <begin_op>
      ilock(f->ip);
    80004cb2:	01893503          	ld	a0,24(s2)
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	eca080e7          	jalr	-310(ra) # 80003b80 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cbe:	8762                	mv	a4,s8
    80004cc0:	02092683          	lw	a3,32(s2)
    80004cc4:	01598633          	add	a2,s3,s5
    80004cc8:	4585                	li	a1,1
    80004cca:	01893503          	ld	a0,24(s2)
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	25e080e7          	jalr	606(ra) # 80003f2c <writei>
    80004cd6:	84aa                	mv	s1,a0
    80004cd8:	02a05f63          	blez	a0,80004d16 <filewrite+0xf0>
        f->off += r;
    80004cdc:	02092783          	lw	a5,32(s2)
    80004ce0:	9fa9                	addw	a5,a5,a0
    80004ce2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ce6:	01893503          	ld	a0,24(s2)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	f58080e7          	jalr	-168(ra) # 80003c42 <iunlock>
      end_op();
    80004cf2:	00000097          	auipc	ra,0x0
    80004cf6:	8e2080e7          	jalr	-1822(ra) # 800045d4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004cfa:	049c1963          	bne	s8,s1,80004d4c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004cfe:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d02:	0349d663          	bge	s3,s4,80004d2e <filewrite+0x108>
      int n1 = n - i;
    80004d06:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d0a:	84be                	mv	s1,a5
    80004d0c:	2781                	sext.w	a5,a5
    80004d0e:	f8fb5ce3          	bge	s6,a5,80004ca6 <filewrite+0x80>
    80004d12:	84de                	mv	s1,s7
    80004d14:	bf49                	j	80004ca6 <filewrite+0x80>
      iunlock(f->ip);
    80004d16:	01893503          	ld	a0,24(s2)
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	f28080e7          	jalr	-216(ra) # 80003c42 <iunlock>
      end_op();
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	8b2080e7          	jalr	-1870(ra) # 800045d4 <end_op>
      if(r < 0)
    80004d2a:	fc04d8e3          	bgez	s1,80004cfa <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004d2e:	8552                	mv	a0,s4
    80004d30:	033a1863          	bne	s4,s3,80004d60 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d34:	60a6                	ld	ra,72(sp)
    80004d36:	6406                	ld	s0,64(sp)
    80004d38:	74e2                	ld	s1,56(sp)
    80004d3a:	7942                	ld	s2,48(sp)
    80004d3c:	79a2                	ld	s3,40(sp)
    80004d3e:	7a02                	ld	s4,32(sp)
    80004d40:	6ae2                	ld	s5,24(sp)
    80004d42:	6b42                	ld	s6,16(sp)
    80004d44:	6ba2                	ld	s7,8(sp)
    80004d46:	6c02                	ld	s8,0(sp)
    80004d48:	6161                	addi	sp,sp,80
    80004d4a:	8082                	ret
        panic("short filewrite");
    80004d4c:	00004517          	auipc	a0,0x4
    80004d50:	95450513          	addi	a0,a0,-1708 # 800086a0 <syscalls+0x280>
    80004d54:	ffffb097          	auipc	ra,0xffffb
    80004d58:	7f6080e7          	jalr	2038(ra) # 8000054a <panic>
    int i = 0;
    80004d5c:	4981                	li	s3,0
    80004d5e:	bfc1                	j	80004d2e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004d60:	557d                	li	a0,-1
    80004d62:	bfc9                	j	80004d34 <filewrite+0x10e>
    panic("filewrite");
    80004d64:	00004517          	auipc	a0,0x4
    80004d68:	94c50513          	addi	a0,a0,-1716 # 800086b0 <syscalls+0x290>
    80004d6c:	ffffb097          	auipc	ra,0xffffb
    80004d70:	7de080e7          	jalr	2014(ra) # 8000054a <panic>
    return -1;
    80004d74:	557d                	li	a0,-1
}
    80004d76:	8082                	ret
      return -1;
    80004d78:	557d                	li	a0,-1
    80004d7a:	bf6d                	j	80004d34 <filewrite+0x10e>
    80004d7c:	557d                	li	a0,-1
    80004d7e:	bf5d                	j	80004d34 <filewrite+0x10e>

0000000080004d80 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d80:	7179                	addi	sp,sp,-48
    80004d82:	f406                	sd	ra,40(sp)
    80004d84:	f022                	sd	s0,32(sp)
    80004d86:	ec26                	sd	s1,24(sp)
    80004d88:	e84a                	sd	s2,16(sp)
    80004d8a:	e44e                	sd	s3,8(sp)
    80004d8c:	e052                	sd	s4,0(sp)
    80004d8e:	1800                	addi	s0,sp,48
    80004d90:	84aa                	mv	s1,a0
    80004d92:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d94:	0005b023          	sd	zero,0(a1)
    80004d98:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d9c:	00000097          	auipc	ra,0x0
    80004da0:	bd0080e7          	jalr	-1072(ra) # 8000496c <filealloc>
    80004da4:	e088                	sd	a0,0(s1)
    80004da6:	c551                	beqz	a0,80004e32 <pipealloc+0xb2>
    80004da8:	00000097          	auipc	ra,0x0
    80004dac:	bc4080e7          	jalr	-1084(ra) # 8000496c <filealloc>
    80004db0:	00aa3023          	sd	a0,0(s4)
    80004db4:	c92d                	beqz	a0,80004e26 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	d60080e7          	jalr	-672(ra) # 80000b16 <kalloc>
    80004dbe:	892a                	mv	s2,a0
    80004dc0:	c125                	beqz	a0,80004e20 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dc2:	4985                	li	s3,1
    80004dc4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004dc8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dcc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dd0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004dd4:	00004597          	auipc	a1,0x4
    80004dd8:	8ec58593          	addi	a1,a1,-1812 # 800086c0 <syscalls+0x2a0>
    80004ddc:	ffffc097          	auipc	ra,0xffffc
    80004de0:	d9a080e7          	jalr	-614(ra) # 80000b76 <initlock>
  (*f0)->type = FD_PIPE;
    80004de4:	609c                	ld	a5,0(s1)
    80004de6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dea:	609c                	ld	a5,0(s1)
    80004dec:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004df0:	609c                	ld	a5,0(s1)
    80004df2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004df6:	609c                	ld	a5,0(s1)
    80004df8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dfc:	000a3783          	ld	a5,0(s4)
    80004e00:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e04:	000a3783          	ld	a5,0(s4)
    80004e08:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e0c:	000a3783          	ld	a5,0(s4)
    80004e10:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e14:	000a3783          	ld	a5,0(s4)
    80004e18:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e1c:	4501                	li	a0,0
    80004e1e:	a025                	j	80004e46 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e20:	6088                	ld	a0,0(s1)
    80004e22:	e501                	bnez	a0,80004e2a <pipealloc+0xaa>
    80004e24:	a039                	j	80004e32 <pipealloc+0xb2>
    80004e26:	6088                	ld	a0,0(s1)
    80004e28:	c51d                	beqz	a0,80004e56 <pipealloc+0xd6>
    fileclose(*f0);
    80004e2a:	00000097          	auipc	ra,0x0
    80004e2e:	bfe080e7          	jalr	-1026(ra) # 80004a28 <fileclose>
  if(*f1)
    80004e32:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e36:	557d                	li	a0,-1
  if(*f1)
    80004e38:	c799                	beqz	a5,80004e46 <pipealloc+0xc6>
    fileclose(*f1);
    80004e3a:	853e                	mv	a0,a5
    80004e3c:	00000097          	auipc	ra,0x0
    80004e40:	bec080e7          	jalr	-1044(ra) # 80004a28 <fileclose>
  return -1;
    80004e44:	557d                	li	a0,-1
}
    80004e46:	70a2                	ld	ra,40(sp)
    80004e48:	7402                	ld	s0,32(sp)
    80004e4a:	64e2                	ld	s1,24(sp)
    80004e4c:	6942                	ld	s2,16(sp)
    80004e4e:	69a2                	ld	s3,8(sp)
    80004e50:	6a02                	ld	s4,0(sp)
    80004e52:	6145                	addi	sp,sp,48
    80004e54:	8082                	ret
  return -1;
    80004e56:	557d                	li	a0,-1
    80004e58:	b7fd                	j	80004e46 <pipealloc+0xc6>

0000000080004e5a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e5a:	1101                	addi	sp,sp,-32
    80004e5c:	ec06                	sd	ra,24(sp)
    80004e5e:	e822                	sd	s0,16(sp)
    80004e60:	e426                	sd	s1,8(sp)
    80004e62:	e04a                	sd	s2,0(sp)
    80004e64:	1000                	addi	s0,sp,32
    80004e66:	84aa                	mv	s1,a0
    80004e68:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	d9c080e7          	jalr	-612(ra) # 80000c06 <acquire>
  if(writable){
    80004e72:	02090d63          	beqz	s2,80004eac <pipeclose+0x52>
    pi->writeopen = 0;
    80004e76:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e7a:	21848513          	addi	a0,s1,536
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	5b6080e7          	jalr	1462(ra) # 80002434 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e86:	2204b783          	ld	a5,544(s1)
    80004e8a:	eb95                	bnez	a5,80004ebe <pipeclose+0x64>
    release(&pi->lock);
    80004e8c:	8526                	mv	a0,s1
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	e2c080e7          	jalr	-468(ra) # 80000cba <release>
    kfree((char*)pi);
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	b82080e7          	jalr	-1150(ra) # 80000a1a <kfree>
  } else
    release(&pi->lock);
}
    80004ea0:	60e2                	ld	ra,24(sp)
    80004ea2:	6442                	ld	s0,16(sp)
    80004ea4:	64a2                	ld	s1,8(sp)
    80004ea6:	6902                	ld	s2,0(sp)
    80004ea8:	6105                	addi	sp,sp,32
    80004eaa:	8082                	ret
    pi->readopen = 0;
    80004eac:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004eb0:	21c48513          	addi	a0,s1,540
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	580080e7          	jalr	1408(ra) # 80002434 <wakeup>
    80004ebc:	b7e9                	j	80004e86 <pipeclose+0x2c>
    release(&pi->lock);
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	ffffc097          	auipc	ra,0xffffc
    80004ec4:	dfa080e7          	jalr	-518(ra) # 80000cba <release>
}
    80004ec8:	bfe1                	j	80004ea0 <pipeclose+0x46>

0000000080004eca <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004eca:	7159                	addi	sp,sp,-112
    80004ecc:	f486                	sd	ra,104(sp)
    80004ece:	f0a2                	sd	s0,96(sp)
    80004ed0:	eca6                	sd	s1,88(sp)
    80004ed2:	e8ca                	sd	s2,80(sp)
    80004ed4:	e4ce                	sd	s3,72(sp)
    80004ed6:	e0d2                	sd	s4,64(sp)
    80004ed8:	fc56                	sd	s5,56(sp)
    80004eda:	f85a                	sd	s6,48(sp)
    80004edc:	f45e                	sd	s7,40(sp)
    80004ede:	f062                	sd	s8,32(sp)
    80004ee0:	ec66                	sd	s9,24(sp)
    80004ee2:	1880                	addi	s0,sp,112
    80004ee4:	84aa                	mv	s1,a0
    80004ee6:	8b2e                	mv	s6,a1
    80004ee8:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	b24080e7          	jalr	-1244(ra) # 80001a0e <myproc>
    80004ef2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	d10080e7          	jalr	-752(ra) # 80000c06 <acquire>
  for(i = 0; i < n; i++){
    80004efe:	09505963          	blez	s5,80004f90 <pipewrite+0xc6>
    80004f02:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004f04:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f08:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f0c:	6c05                	lui	s8,0x1
    80004f0e:	9c4a                	add	s8,s8,s2
    80004f10:	5cfd                	li	s9,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f12:	2184a783          	lw	a5,536(s1)
    80004f16:	21c4a703          	lw	a4,540(s1)
    80004f1a:	2007879b          	addiw	a5,a5,512
    80004f1e:	02f71b63          	bne	a4,a5,80004f54 <pipewrite+0x8a>
      if(pi->readopen == 0 || pr->killed){
    80004f22:	2204a783          	lw	a5,544(s1)
    80004f26:	c3d1                	beqz	a5,80004faa <pipewrite+0xe0>
    80004f28:	03092783          	lw	a5,48(s2)
    80004f2c:	efbd                	bnez	a5,80004faa <pipewrite+0xe0>
      wakeup(&pi->nread);
    80004f2e:	8552                	mv	a0,s4
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	504080e7          	jalr	1284(ra) # 80002434 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f38:	85a6                	mv	a1,s1
    80004f3a:	854e                	mv	a0,s3
    80004f3c:	ffffd097          	auipc	ra,0xffffd
    80004f40:	374080e7          	jalr	884(ra) # 800022b0 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f44:	2184a783          	lw	a5,536(s1)
    80004f48:	21c4a703          	lw	a4,540(s1)
    80004f4c:	2007879b          	addiw	a5,a5,512
    80004f50:	fcf709e3          	beq	a4,a5,80004f22 <pipewrite+0x58>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f54:	4685                	li	a3,1
    80004f56:	865a                	mv	a2,s6
    80004f58:	f9f40593          	addi	a1,s0,-97
    80004f5c:	0a0c3503          	ld	a0,160(s8) # 10a0 <_entry-0x7fffef60>
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	7ae080e7          	jalr	1966(ra) # 8000170e <copyin>
    80004f68:	03950563          	beq	a0,s9,80004f92 <pipewrite+0xc8>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f6c:	21c4a783          	lw	a5,540(s1)
    80004f70:	0017871b          	addiw	a4,a5,1
    80004f74:	20e4ae23          	sw	a4,540(s1)
    80004f78:	1ff7f793          	andi	a5,a5,511
    80004f7c:	97a6                	add	a5,a5,s1
    80004f7e:	f9f44703          	lbu	a4,-97(s0)
    80004f82:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004f86:	2b85                	addiw	s7,s7,1
    80004f88:	0b05                	addi	s6,s6,1
    80004f8a:	f97a94e3          	bne	s5,s7,80004f12 <pipewrite+0x48>
    80004f8e:	a011                	j	80004f92 <pipewrite+0xc8>
    80004f90:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004f92:	21848513          	addi	a0,s1,536
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	49e080e7          	jalr	1182(ra) # 80002434 <wakeup>
  release(&pi->lock);
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	d1a080e7          	jalr	-742(ra) # 80000cba <release>
  return i;
    80004fa8:	a039                	j	80004fb6 <pipewrite+0xec>
        release(&pi->lock);
    80004faa:	8526                	mv	a0,s1
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	d0e080e7          	jalr	-754(ra) # 80000cba <release>
        return -1;
    80004fb4:	5bfd                	li	s7,-1
}
    80004fb6:	855e                	mv	a0,s7
    80004fb8:	70a6                	ld	ra,104(sp)
    80004fba:	7406                	ld	s0,96(sp)
    80004fbc:	64e6                	ld	s1,88(sp)
    80004fbe:	6946                	ld	s2,80(sp)
    80004fc0:	69a6                	ld	s3,72(sp)
    80004fc2:	6a06                	ld	s4,64(sp)
    80004fc4:	7ae2                	ld	s5,56(sp)
    80004fc6:	7b42                	ld	s6,48(sp)
    80004fc8:	7ba2                	ld	s7,40(sp)
    80004fca:	7c02                	ld	s8,32(sp)
    80004fcc:	6ce2                	ld	s9,24(sp)
    80004fce:	6165                	addi	sp,sp,112
    80004fd0:	8082                	ret

0000000080004fd2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004fd2:	715d                	addi	sp,sp,-80
    80004fd4:	e486                	sd	ra,72(sp)
    80004fd6:	e0a2                	sd	s0,64(sp)
    80004fd8:	fc26                	sd	s1,56(sp)
    80004fda:	f84a                	sd	s2,48(sp)
    80004fdc:	f44e                	sd	s3,40(sp)
    80004fde:	f052                	sd	s4,32(sp)
    80004fe0:	ec56                	sd	s5,24(sp)
    80004fe2:	e85a                	sd	s6,16(sp)
    80004fe4:	0880                	addi	s0,sp,80
    80004fe6:	84aa                	mv	s1,a0
    80004fe8:	892e                	mv	s2,a1
    80004fea:	8a32                	mv	s4,a2
  int i;
  struct proc *pr = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	a22080e7          	jalr	-1502(ra) # 80001a0e <myproc>
    80004ff4:	8aaa                	mv	s5,a0
  char ch;

  acquire(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	c0e080e7          	jalr	-1010(ra) # 80000c06 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005000:	2184a703          	lw	a4,536(s1)
    80005004:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005008:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000500c:	02f71463          	bne	a4,a5,80005034 <piperead+0x62>
    80005010:	2244a783          	lw	a5,548(s1)
    80005014:	c385                	beqz	a5,80005034 <piperead+0x62>
    if(pr->killed){
    80005016:	030aa783          	lw	a5,48(s5)
    8000501a:	ebd1                	bnez	a5,800050ae <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000501c:	85a6                	mv	a1,s1
    8000501e:	854e                	mv	a0,s3
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	290080e7          	jalr	656(ra) # 800022b0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005028:	2184a703          	lw	a4,536(s1)
    8000502c:	21c4a783          	lw	a5,540(s1)
    80005030:	fef700e3          	beq	a4,a5,80005010 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005034:	4981                	li	s3,0
    80005036:	09405363          	blez	s4,800050bc <piperead+0xea>
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000503a:	6505                	lui	a0,0x1
    8000503c:	9aaa                	add	s5,s5,a0
    8000503e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005040:	2184a783          	lw	a5,536(s1)
    80005044:	21c4a703          	lw	a4,540(s1)
    80005048:	02f70d63          	beq	a4,a5,80005082 <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000504c:	0017871b          	addiw	a4,a5,1
    80005050:	20e4ac23          	sw	a4,536(s1)
    80005054:	1ff7f793          	andi	a5,a5,511
    80005058:	97a6                	add	a5,a5,s1
    8000505a:	0187c783          	lbu	a5,24(a5)
    8000505e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005062:	4685                	li	a3,1
    80005064:	fbf40613          	addi	a2,s0,-65
    80005068:	85ca                	mv	a1,s2
    8000506a:	0a0ab503          	ld	a0,160(s5)
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	614080e7          	jalr	1556(ra) # 80001682 <copyout>
    80005076:	01650663          	beq	a0,s6,80005082 <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507a:	2985                	addiw	s3,s3,1
    8000507c:	0905                	addi	s2,s2,1
    8000507e:	fd3a11e3          	bne	s4,s3,80005040 <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005082:	21c48513          	addi	a0,s1,540
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	3ae080e7          	jalr	942(ra) # 80002434 <wakeup>
  release(&pi->lock);
    8000508e:	8526                	mv	a0,s1
    80005090:	ffffc097          	auipc	ra,0xffffc
    80005094:	c2a080e7          	jalr	-982(ra) # 80000cba <release>
  return i;
}
    80005098:	854e                	mv	a0,s3
    8000509a:	60a6                	ld	ra,72(sp)
    8000509c:	6406                	ld	s0,64(sp)
    8000509e:	74e2                	ld	s1,56(sp)
    800050a0:	7942                	ld	s2,48(sp)
    800050a2:	79a2                	ld	s3,40(sp)
    800050a4:	7a02                	ld	s4,32(sp)
    800050a6:	6ae2                	ld	s5,24(sp)
    800050a8:	6b42                	ld	s6,16(sp)
    800050aa:	6161                	addi	sp,sp,80
    800050ac:	8082                	ret
      release(&pi->lock);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	c0a080e7          	jalr	-1014(ra) # 80000cba <release>
      return -1;
    800050b8:	59fd                	li	s3,-1
    800050ba:	bff9                	j	80005098 <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050bc:	4981                	li	s3,0
    800050be:	b7d1                	j	80005082 <piperead+0xb0>

00000000800050c0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050c0:	de010113          	addi	sp,sp,-544
    800050c4:	20113c23          	sd	ra,536(sp)
    800050c8:	20813823          	sd	s0,528(sp)
    800050cc:	20913423          	sd	s1,520(sp)
    800050d0:	21213023          	sd	s2,512(sp)
    800050d4:	ffce                	sd	s3,504(sp)
    800050d6:	fbd2                	sd	s4,496(sp)
    800050d8:	f7d6                	sd	s5,488(sp)
    800050da:	f3da                	sd	s6,480(sp)
    800050dc:	efde                	sd	s7,472(sp)
    800050de:	ebe2                	sd	s8,464(sp)
    800050e0:	e7e6                	sd	s9,456(sp)
    800050e2:	e3ea                	sd	s10,448(sp)
    800050e4:	ff6e                	sd	s11,440(sp)
    800050e6:	1400                	addi	s0,sp,544
    800050e8:	892a                	mv	s2,a0
    800050ea:	dea43423          	sd	a0,-536(s0)
    800050ee:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	91c080e7          	jalr	-1764(ra) # 80001a0e <myproc>
    800050fa:	84aa                	mv	s1,a0

  begin_op();
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	458080e7          	jalr	1112(ra) # 80004554 <begin_op>

  if((ip = namei(path)) == 0){
    80005104:	854a                	mv	a0,s2
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	232080e7          	jalr	562(ra) # 80004338 <namei>
    8000510e:	c93d                	beqz	a0,80005184 <exec+0xc4>
    80005110:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005112:	fffff097          	auipc	ra,0xfffff
    80005116:	a6e080e7          	jalr	-1426(ra) # 80003b80 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000511a:	04000713          	li	a4,64
    8000511e:	4681                	li	a3,0
    80005120:	e4840613          	addi	a2,s0,-440
    80005124:	4581                	li	a1,0
    80005126:	8556                	mv	a0,s5
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	d0c080e7          	jalr	-756(ra) # 80003e34 <readi>
    80005130:	04000793          	li	a5,64
    80005134:	00f51a63          	bne	a0,a5,80005148 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005138:	e4842703          	lw	a4,-440(s0)
    8000513c:	464c47b7          	lui	a5,0x464c4
    80005140:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005144:	04f70663          	beq	a4,a5,80005190 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005148:	8556                	mv	a0,s5
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	c98080e7          	jalr	-872(ra) # 80003de2 <iunlockput>
    end_op();
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	482080e7          	jalr	1154(ra) # 800045d4 <end_op>
  }
  return -1;
    8000515a:	557d                	li	a0,-1
}
    8000515c:	21813083          	ld	ra,536(sp)
    80005160:	21013403          	ld	s0,528(sp)
    80005164:	20813483          	ld	s1,520(sp)
    80005168:	20013903          	ld	s2,512(sp)
    8000516c:	79fe                	ld	s3,504(sp)
    8000516e:	7a5e                	ld	s4,496(sp)
    80005170:	7abe                	ld	s5,488(sp)
    80005172:	7b1e                	ld	s6,480(sp)
    80005174:	6bfe                	ld	s7,472(sp)
    80005176:	6c5e                	ld	s8,464(sp)
    80005178:	6cbe                	ld	s9,456(sp)
    8000517a:	6d1e                	ld	s10,448(sp)
    8000517c:	7dfa                	ld	s11,440(sp)
    8000517e:	22010113          	addi	sp,sp,544
    80005182:	8082                	ret
    end_op();
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	450080e7          	jalr	1104(ra) # 800045d4 <end_op>
    return -1;
    8000518c:	557d                	li	a0,-1
    8000518e:	b7f9                	j	8000515c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005190:	8526                	mv	a0,s1
    80005192:	ffffd097          	auipc	ra,0xffffd
    80005196:	940080e7          	jalr	-1728(ra) # 80001ad2 <proc_pagetable>
    8000519a:	8b2a                	mv	s6,a0
    8000519c:	d555                	beqz	a0,80005148 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000519e:	e6842783          	lw	a5,-408(s0)
    800051a2:	e8045703          	lhu	a4,-384(s0)
    800051a6:	c735                	beqz	a4,80005212 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051a8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051aa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800051ae:	6a05                	lui	s4,0x1
    800051b0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800051b4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800051b8:	6d85                	lui	s11,0x1
    800051ba:	7d7d                	lui	s10,0xfffff
    800051bc:	a489                	j	800053fe <exec+0x33e>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051be:	00003517          	auipc	a0,0x3
    800051c2:	50a50513          	addi	a0,a0,1290 # 800086c8 <syscalls+0x2a8>
    800051c6:	ffffb097          	auipc	ra,0xffffb
    800051ca:	384080e7          	jalr	900(ra) # 8000054a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051ce:	874a                	mv	a4,s2
    800051d0:	009c86bb          	addw	a3,s9,s1
    800051d4:	4581                	li	a1,0
    800051d6:	8556                	mv	a0,s5
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	c5c080e7          	jalr	-932(ra) # 80003e34 <readi>
    800051e0:	2501                	sext.w	a0,a0
    800051e2:	1aa91e63          	bne	s2,a0,8000539e <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    800051e6:	009d84bb          	addw	s1,s11,s1
    800051ea:	013d09bb          	addw	s3,s10,s3
    800051ee:	1f74f863          	bgeu	s1,s7,800053de <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    800051f2:	02049593          	slli	a1,s1,0x20
    800051f6:	9181                	srli	a1,a1,0x20
    800051f8:	95e2                	add	a1,a1,s8
    800051fa:	855a                	mv	a0,s6
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	e94080e7          	jalr	-364(ra) # 80001090 <walkaddr>
    80005204:	862a                	mv	a2,a0
    if(pa == 0)
    80005206:	dd45                	beqz	a0,800051be <exec+0xfe>
      n = PGSIZE;
    80005208:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000520a:	fd49f2e3          	bgeu	s3,s4,800051ce <exec+0x10e>
      n = sz - i;
    8000520e:	894e                	mv	s2,s3
    80005210:	bf7d                	j	800051ce <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005212:	4481                	li	s1,0
  iunlockput(ip);
    80005214:	8556                	mv	a0,s5
    80005216:	fffff097          	auipc	ra,0xfffff
    8000521a:	bcc080e7          	jalr	-1076(ra) # 80003de2 <iunlockput>
  end_op();
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	3b6080e7          	jalr	950(ra) # 800045d4 <end_op>
  p = myproc();
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	7e8080e7          	jalr	2024(ra) # 80001a0e <myproc>
    8000522e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005230:	6785                	lui	a5,0x1
    80005232:	00f50733          	add	a4,a0,a5
    80005236:	09873d03          	ld	s10,152(a4)
  sz = PGROUNDUP(sz);
    8000523a:	17fd                	addi	a5,a5,-1
    8000523c:	94be                	add	s1,s1,a5
    8000523e:	77fd                	lui	a5,0xfffff
    80005240:	8fe5                	and	a5,a5,s1
    80005242:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005246:	6609                	lui	a2,0x2
    80005248:	963e                	add	a2,a2,a5
    8000524a:	85be                	mv	a1,a5
    8000524c:	855a                	mv	a0,s6
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	1e4080e7          	jalr	484(ra) # 80001432 <uvmalloc>
    80005256:	8c2a                	mv	s8,a0
  ip = 0;
    80005258:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000525a:	14050263          	beqz	a0,8000539e <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000525e:	75f9                	lui	a1,0xffffe
    80005260:	95aa                	add	a1,a1,a0
    80005262:	855a                	mv	a0,s6
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	3ec080e7          	jalr	1004(ra) # 80001650 <uvmclear>
  stackbase = sp - PGSIZE;
    8000526c:	7afd                	lui	s5,0xfffff
    8000526e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005270:	df043783          	ld	a5,-528(s0)
    80005274:	6388                	ld	a0,0(a5)
    80005276:	c925                	beqz	a0,800052e6 <exec+0x226>
    80005278:	e8840993          	addi	s3,s0,-376
    8000527c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005280:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005282:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	c02080e7          	jalr	-1022(ra) # 80000e86 <strlen>
    8000528c:	0015079b          	addiw	a5,a0,1
    80005290:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005294:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005298:	13596763          	bltu	s2,s5,800053c6 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000529c:	df043d83          	ld	s11,-528(s0)
    800052a0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800052a4:	8552                	mv	a0,s4
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	be0080e7          	jalr	-1056(ra) # 80000e86 <strlen>
    800052ae:	0015069b          	addiw	a3,a0,1
    800052b2:	8652                	mv	a2,s4
    800052b4:	85ca                	mv	a1,s2
    800052b6:	855a                	mv	a0,s6
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	3ca080e7          	jalr	970(ra) # 80001682 <copyout>
    800052c0:	10054763          	bltz	a0,800053ce <exec+0x30e>
    ustack[argc] = sp;
    800052c4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052c8:	0485                	addi	s1,s1,1
    800052ca:	008d8793          	addi	a5,s11,8
    800052ce:	def43823          	sd	a5,-528(s0)
    800052d2:	008db503          	ld	a0,8(s11)
    800052d6:	c911                	beqz	a0,800052ea <exec+0x22a>
    if(argc >= MAXARG)
    800052d8:	09a1                	addi	s3,s3,8
    800052da:	fb3c95e3          	bne	s9,s3,80005284 <exec+0x1c4>
  sz = sz1;
    800052de:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052e2:	4a81                	li	s5,0
    800052e4:	a86d                	j	8000539e <exec+0x2de>
  sp = sz;
    800052e6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052e8:	4481                	li	s1,0
  ustack[argc] = 0;
    800052ea:	00349793          	slli	a5,s1,0x3
    800052ee:	f9040713          	addi	a4,s0,-112
    800052f2:	97ba                	add	a5,a5,a4
    800052f4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ff97ef8>
  sp -= (argc+1) * sizeof(uint64);
    800052f8:	00148693          	addi	a3,s1,1
    800052fc:	068e                	slli	a3,a3,0x3
    800052fe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005302:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005306:	01597663          	bgeu	s2,s5,80005312 <exec+0x252>
  sz = sz1;
    8000530a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000530e:	4a81                	li	s5,0
    80005310:	a079                	j	8000539e <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005312:	e8840613          	addi	a2,s0,-376
    80005316:	85ca                	mv	a1,s2
    80005318:	855a                	mv	a0,s6
    8000531a:	ffffc097          	auipc	ra,0xffffc
    8000531e:	368080e7          	jalr	872(ra) # 80001682 <copyout>
    80005322:	0a054a63          	bltz	a0,800053d6 <exec+0x316>
  p->trapframe->a1 = sp;
    80005326:	6785                	lui	a5,0x1
    80005328:	97de                	add	a5,a5,s7
    8000532a:	77dc                	ld	a5,168(a5)
    8000532c:	0727bc23          	sd	s2,120(a5) # 1078 <_entry-0x7fffef88>
  for(last=s=path; *s; s++)
    80005330:	de843783          	ld	a5,-536(s0)
    80005334:	0007c703          	lbu	a4,0(a5)
    80005338:	cf11                	beqz	a4,80005354 <exec+0x294>
    8000533a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000533c:	02f00693          	li	a3,47
    80005340:	a039                	j	8000534e <exec+0x28e>
      last = s+1;
    80005342:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005346:	0785                	addi	a5,a5,1
    80005348:	fff7c703          	lbu	a4,-1(a5)
    8000534c:	c701                	beqz	a4,80005354 <exec+0x294>
    if(*s == '/')
    8000534e:	fed71ce3          	bne	a4,a3,80005346 <exec+0x286>
    80005352:	bfc5                	j	80005342 <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80005354:	6985                	lui	s3,0x1
    80005356:	1a898513          	addi	a0,s3,424 # 11a8 <_entry-0x7fffee58>
    8000535a:	4641                	li	a2,16
    8000535c:	de843583          	ld	a1,-536(s0)
    80005360:	955e                	add	a0,a0,s7
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	af2080e7          	jalr	-1294(ra) # 80000e54 <safestrcpy>
  oldpagetable = p->pagetable;
    8000536a:	9bce                	add	s7,s7,s3
    8000536c:	0a0bb503          	ld	a0,160(s7) # 10a0 <_entry-0x7fffef60>
  p->pagetable = pagetable;
    80005370:	0b6bb023          	sd	s6,160(s7)
  p->sz = sz;
    80005374:	098bbc23          	sd	s8,152(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005378:	0a8bb783          	ld	a5,168(s7)
    8000537c:	e6043703          	ld	a4,-416(s0)
    80005380:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005382:	0a8bb783          	ld	a5,168(s7)
    80005386:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000538a:	85ea                	mv	a1,s10
    8000538c:	ffffc097          	auipc	ra,0xffffc
    80005390:	7e4080e7          	jalr	2020(ra) # 80001b70 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005394:	0004851b          	sext.w	a0,s1
    80005398:	b3d1                	j	8000515c <exec+0x9c>
    8000539a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000539e:	df843583          	ld	a1,-520(s0)
    800053a2:	855a                	mv	a0,s6
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	7cc080e7          	jalr	1996(ra) # 80001b70 <proc_freepagetable>
  if(ip){
    800053ac:	d80a9ee3          	bnez	s5,80005148 <exec+0x88>
  return -1;
    800053b0:	557d                	li	a0,-1
    800053b2:	b36d                	j	8000515c <exec+0x9c>
    800053b4:	de943c23          	sd	s1,-520(s0)
    800053b8:	b7dd                	j	8000539e <exec+0x2de>
    800053ba:	de943c23          	sd	s1,-520(s0)
    800053be:	b7c5                	j	8000539e <exec+0x2de>
    800053c0:	de943c23          	sd	s1,-520(s0)
    800053c4:	bfe9                	j	8000539e <exec+0x2de>
  sz = sz1;
    800053c6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053ca:	4a81                	li	s5,0
    800053cc:	bfc9                	j	8000539e <exec+0x2de>
  sz = sz1;
    800053ce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053d2:	4a81                	li	s5,0
    800053d4:	b7e9                	j	8000539e <exec+0x2de>
  sz = sz1;
    800053d6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800053da:	4a81                	li	s5,0
    800053dc:	b7c9                	j	8000539e <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053de:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053e2:	e0843783          	ld	a5,-504(s0)
    800053e6:	0017869b          	addiw	a3,a5,1
    800053ea:	e0d43423          	sd	a3,-504(s0)
    800053ee:	e0043783          	ld	a5,-512(s0)
    800053f2:	0387879b          	addiw	a5,a5,56
    800053f6:	e8045703          	lhu	a4,-384(s0)
    800053fa:	e0e6dde3          	bge	a3,a4,80005214 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053fe:	2781                	sext.w	a5,a5
    80005400:	e0f43023          	sd	a5,-512(s0)
    80005404:	03800713          	li	a4,56
    80005408:	86be                	mv	a3,a5
    8000540a:	e1040613          	addi	a2,s0,-496
    8000540e:	4581                	li	a1,0
    80005410:	8556                	mv	a0,s5
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	a22080e7          	jalr	-1502(ra) # 80003e34 <readi>
    8000541a:	03800793          	li	a5,56
    8000541e:	f6f51ee3          	bne	a0,a5,8000539a <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    80005422:	e1042783          	lw	a5,-496(s0)
    80005426:	4705                	li	a4,1
    80005428:	fae79de3          	bne	a5,a4,800053e2 <exec+0x322>
    if(ph.memsz < ph.filesz)
    8000542c:	e3843603          	ld	a2,-456(s0)
    80005430:	e3043783          	ld	a5,-464(s0)
    80005434:	f8f660e3          	bltu	a2,a5,800053b4 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005438:	e2043783          	ld	a5,-480(s0)
    8000543c:	963e                	add	a2,a2,a5
    8000543e:	f6f66ee3          	bltu	a2,a5,800053ba <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005442:	85a6                	mv	a1,s1
    80005444:	855a                	mv	a0,s6
    80005446:	ffffc097          	auipc	ra,0xffffc
    8000544a:	fec080e7          	jalr	-20(ra) # 80001432 <uvmalloc>
    8000544e:	dea43c23          	sd	a0,-520(s0)
    80005452:	d53d                	beqz	a0,800053c0 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80005454:	e2043c03          	ld	s8,-480(s0)
    80005458:	de043783          	ld	a5,-544(s0)
    8000545c:	00fc77b3          	and	a5,s8,a5
    80005460:	ff9d                	bnez	a5,8000539e <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005462:	e1842c83          	lw	s9,-488(s0)
    80005466:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000546a:	f60b8ae3          	beqz	s7,800053de <exec+0x31e>
    8000546e:	89de                	mv	s3,s7
    80005470:	4481                	li	s1,0
    80005472:	b341                	j	800051f2 <exec+0x132>

0000000080005474 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005474:	7179                	addi	sp,sp,-48
    80005476:	f406                	sd	ra,40(sp)
    80005478:	f022                	sd	s0,32(sp)
    8000547a:	ec26                	sd	s1,24(sp)
    8000547c:	e84a                	sd	s2,16(sp)
    8000547e:	1800                	addi	s0,sp,48
    80005480:	892e                	mv	s2,a1
    80005482:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005484:	fdc40593          	addi	a1,s0,-36
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	8c8080e7          	jalr	-1848(ra) # 80002d50 <argint>
    80005490:	04054063          	bltz	a0,800054d0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005494:	fdc42703          	lw	a4,-36(s0)
    80005498:	47bd                	li	a5,15
    8000549a:	02e7ed63          	bltu	a5,a4,800054d4 <argfd+0x60>
    8000549e:	ffffc097          	auipc	ra,0xffffc
    800054a2:	570080e7          	jalr	1392(ra) # 80001a0e <myproc>
    800054a6:	fdc42703          	lw	a4,-36(s0)
    800054aa:	22470793          	addi	a5,a4,548
    800054ae:	078e                	slli	a5,a5,0x3
    800054b0:	953e                	add	a0,a0,a5
    800054b2:	611c                	ld	a5,0(a0)
    800054b4:	c395                	beqz	a5,800054d8 <argfd+0x64>
    return -1;
  if(pfd)
    800054b6:	00090463          	beqz	s2,800054be <argfd+0x4a>
    *pfd = fd;
    800054ba:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054be:	4501                	li	a0,0
  if(pf)
    800054c0:	c091                	beqz	s1,800054c4 <argfd+0x50>
    *pf = f;
    800054c2:	e09c                	sd	a5,0(s1)
}
    800054c4:	70a2                	ld	ra,40(sp)
    800054c6:	7402                	ld	s0,32(sp)
    800054c8:	64e2                	ld	s1,24(sp)
    800054ca:	6942                	ld	s2,16(sp)
    800054cc:	6145                	addi	sp,sp,48
    800054ce:	8082                	ret
    return -1;
    800054d0:	557d                	li	a0,-1
    800054d2:	bfcd                	j	800054c4 <argfd+0x50>
    return -1;
    800054d4:	557d                	li	a0,-1
    800054d6:	b7fd                	j	800054c4 <argfd+0x50>
    800054d8:	557d                	li	a0,-1
    800054da:	b7ed                	j	800054c4 <argfd+0x50>

00000000800054dc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054dc:	1101                	addi	sp,sp,-32
    800054de:	ec06                	sd	ra,24(sp)
    800054e0:	e822                	sd	s0,16(sp)
    800054e2:	e426                	sd	s1,8(sp)
    800054e4:	1000                	addi	s0,sp,32
    800054e6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	526080e7          	jalr	1318(ra) # 80001a0e <myproc>
    800054f0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054f2:	6785                	lui	a5,0x1
    800054f4:	12078793          	addi	a5,a5,288 # 1120 <_entry-0x7fffeee0>
    800054f8:	97aa                	add	a5,a5,a0
    800054fa:	4501                	li	a0,0
    800054fc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800054fe:	6398                	ld	a4,0(a5)
    80005500:	cb19                	beqz	a4,80005516 <fdalloc+0x3a>
  for(fd = 0; fd < NOFILE; fd++){
    80005502:	2505                	addiw	a0,a0,1
    80005504:	07a1                	addi	a5,a5,8
    80005506:	fed51ce3          	bne	a0,a3,800054fe <fdalloc+0x22>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000550a:	557d                	li	a0,-1
}
    8000550c:	60e2                	ld	ra,24(sp)
    8000550e:	6442                	ld	s0,16(sp)
    80005510:	64a2                	ld	s1,8(sp)
    80005512:	6105                	addi	sp,sp,32
    80005514:	8082                	ret
      p->ofile[fd] = f;
    80005516:	22450793          	addi	a5,a0,548
    8000551a:	078e                	slli	a5,a5,0x3
    8000551c:	963e                	add	a2,a2,a5
    8000551e:	e204                	sd	s1,0(a2)
      return fd;
    80005520:	b7f5                	j	8000550c <fdalloc+0x30>

0000000080005522 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005522:	715d                	addi	sp,sp,-80
    80005524:	e486                	sd	ra,72(sp)
    80005526:	e0a2                	sd	s0,64(sp)
    80005528:	fc26                	sd	s1,56(sp)
    8000552a:	f84a                	sd	s2,48(sp)
    8000552c:	f44e                	sd	s3,40(sp)
    8000552e:	f052                	sd	s4,32(sp)
    80005530:	ec56                	sd	s5,24(sp)
    80005532:	0880                	addi	s0,sp,80
    80005534:	89ae                	mv	s3,a1
    80005536:	8ab2                	mv	s5,a2
    80005538:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000553a:	fb040593          	addi	a1,s0,-80
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	e18080e7          	jalr	-488(ra) # 80004356 <nameiparent>
    80005546:	892a                	mv	s2,a0
    80005548:	12050e63          	beqz	a0,80005684 <create+0x162>
    return 0;

  ilock(dp);
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	634080e7          	jalr	1588(ra) # 80003b80 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005554:	4601                	li	a2,0
    80005556:	fb040593          	addi	a1,s0,-80
    8000555a:	854a                	mv	a0,s2
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	b06080e7          	jalr	-1274(ra) # 80004062 <dirlookup>
    80005564:	84aa                	mv	s1,a0
    80005566:	c921                	beqz	a0,800055b6 <create+0x94>
    iunlockput(dp);
    80005568:	854a                	mv	a0,s2
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	878080e7          	jalr	-1928(ra) # 80003de2 <iunlockput>
    ilock(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	60c080e7          	jalr	1548(ra) # 80003b80 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000557c:	2981                	sext.w	s3,s3
    8000557e:	4789                	li	a5,2
    80005580:	02f99463          	bne	s3,a5,800055a8 <create+0x86>
    80005584:	0444d783          	lhu	a5,68(s1)
    80005588:	37f9                	addiw	a5,a5,-2
    8000558a:	17c2                	slli	a5,a5,0x30
    8000558c:	93c1                	srli	a5,a5,0x30
    8000558e:	4705                	li	a4,1
    80005590:	00f76c63          	bltu	a4,a5,800055a8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005594:	8526                	mv	a0,s1
    80005596:	60a6                	ld	ra,72(sp)
    80005598:	6406                	ld	s0,64(sp)
    8000559a:	74e2                	ld	s1,56(sp)
    8000559c:	7942                	ld	s2,48(sp)
    8000559e:	79a2                	ld	s3,40(sp)
    800055a0:	7a02                	ld	s4,32(sp)
    800055a2:	6ae2                	ld	s5,24(sp)
    800055a4:	6161                	addi	sp,sp,80
    800055a6:	8082                	ret
    iunlockput(ip);
    800055a8:	8526                	mv	a0,s1
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	838080e7          	jalr	-1992(ra) # 80003de2 <iunlockput>
    return 0;
    800055b2:	4481                	li	s1,0
    800055b4:	b7c5                	j	80005594 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055b6:	85ce                	mv	a1,s3
    800055b8:	00092503          	lw	a0,0(s2)
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	42c080e7          	jalr	1068(ra) # 800039e8 <ialloc>
    800055c4:	84aa                	mv	s1,a0
    800055c6:	c521                	beqz	a0,8000560e <create+0xec>
  ilock(ip);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	5b8080e7          	jalr	1464(ra) # 80003b80 <ilock>
  ip->major = major;
    800055d0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055d4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055d8:	4a05                	li	s4,1
    800055da:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4d6080e7          	jalr	1238(ra) # 80003ab6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055e8:	2981                	sext.w	s3,s3
    800055ea:	03498a63          	beq	s3,s4,8000561e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800055ee:	40d0                	lw	a2,4(s1)
    800055f0:	fb040593          	addi	a1,s0,-80
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	c80080e7          	jalr	-896(ra) # 80004276 <dirlink>
    800055fe:	06054b63          	bltz	a0,80005674 <create+0x152>
  iunlockput(dp);
    80005602:	854a                	mv	a0,s2
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	7de080e7          	jalr	2014(ra) # 80003de2 <iunlockput>
  return ip;
    8000560c:	b761                	j	80005594 <create+0x72>
    panic("create: ialloc");
    8000560e:	00003517          	auipc	a0,0x3
    80005612:	0da50513          	addi	a0,a0,218 # 800086e8 <syscalls+0x2c8>
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	f34080e7          	jalr	-204(ra) # 8000054a <panic>
    dp->nlink++;  // for ".."
    8000561e:	04a95783          	lhu	a5,74(s2)
    80005622:	2785                	addiw	a5,a5,1
    80005624:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005628:	854a                	mv	a0,s2
    8000562a:	ffffe097          	auipc	ra,0xffffe
    8000562e:	48c080e7          	jalr	1164(ra) # 80003ab6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005632:	40d0                	lw	a2,4(s1)
    80005634:	00003597          	auipc	a1,0x3
    80005638:	0c458593          	addi	a1,a1,196 # 800086f8 <syscalls+0x2d8>
    8000563c:	8526                	mv	a0,s1
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	c38080e7          	jalr	-968(ra) # 80004276 <dirlink>
    80005646:	00054f63          	bltz	a0,80005664 <create+0x142>
    8000564a:	00492603          	lw	a2,4(s2)
    8000564e:	00003597          	auipc	a1,0x3
    80005652:	0b258593          	addi	a1,a1,178 # 80008700 <syscalls+0x2e0>
    80005656:	8526                	mv	a0,s1
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	c1e080e7          	jalr	-994(ra) # 80004276 <dirlink>
    80005660:	f80557e3          	bgez	a0,800055ee <create+0xcc>
      panic("create dots");
    80005664:	00003517          	auipc	a0,0x3
    80005668:	0a450513          	addi	a0,a0,164 # 80008708 <syscalls+0x2e8>
    8000566c:	ffffb097          	auipc	ra,0xffffb
    80005670:	ede080e7          	jalr	-290(ra) # 8000054a <panic>
    panic("create: dirlink");
    80005674:	00003517          	auipc	a0,0x3
    80005678:	0a450513          	addi	a0,a0,164 # 80008718 <syscalls+0x2f8>
    8000567c:	ffffb097          	auipc	ra,0xffffb
    80005680:	ece080e7          	jalr	-306(ra) # 8000054a <panic>
    return 0;
    80005684:	84aa                	mv	s1,a0
    80005686:	b739                	j	80005594 <create+0x72>

0000000080005688 <sys_dup>:
{
    80005688:	7179                	addi	sp,sp,-48
    8000568a:	f406                	sd	ra,40(sp)
    8000568c:	f022                	sd	s0,32(sp)
    8000568e:	ec26                	sd	s1,24(sp)
    80005690:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005692:	fd840613          	addi	a2,s0,-40
    80005696:	4581                	li	a1,0
    80005698:	4501                	li	a0,0
    8000569a:	00000097          	auipc	ra,0x0
    8000569e:	dda080e7          	jalr	-550(ra) # 80005474 <argfd>
    return -1;
    800056a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a4:	02054363          	bltz	a0,800056ca <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056a8:	fd843503          	ld	a0,-40(s0)
    800056ac:	00000097          	auipc	ra,0x0
    800056b0:	e30080e7          	jalr	-464(ra) # 800054dc <fdalloc>
    800056b4:	84aa                	mv	s1,a0
    return -1;
    800056b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056b8:	00054963          	bltz	a0,800056ca <sys_dup+0x42>
  filedup(f);
    800056bc:	fd843503          	ld	a0,-40(s0)
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	316080e7          	jalr	790(ra) # 800049d6 <filedup>
  return fd;
    800056c8:	87a6                	mv	a5,s1
}
    800056ca:	853e                	mv	a0,a5
    800056cc:	70a2                	ld	ra,40(sp)
    800056ce:	7402                	ld	s0,32(sp)
    800056d0:	64e2                	ld	s1,24(sp)
    800056d2:	6145                	addi	sp,sp,48
    800056d4:	8082                	ret

00000000800056d6 <sys_read>:
{
    800056d6:	7179                	addi	sp,sp,-48
    800056d8:	f406                	sd	ra,40(sp)
    800056da:	f022                	sd	s0,32(sp)
    800056dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056de:	fe840613          	addi	a2,s0,-24
    800056e2:	4581                	li	a1,0
    800056e4:	4501                	li	a0,0
    800056e6:	00000097          	auipc	ra,0x0
    800056ea:	d8e080e7          	jalr	-626(ra) # 80005474 <argfd>
    return -1;
    800056ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f0:	04054163          	bltz	a0,80005732 <sys_read+0x5c>
    800056f4:	fe440593          	addi	a1,s0,-28
    800056f8:	4509                	li	a0,2
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	656080e7          	jalr	1622(ra) # 80002d50 <argint>
    return -1;
    80005702:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005704:	02054763          	bltz	a0,80005732 <sys_read+0x5c>
    80005708:	fd840593          	addi	a1,s0,-40
    8000570c:	4505                	li	a0,1
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	664080e7          	jalr	1636(ra) # 80002d72 <argaddr>
    return -1;
    80005716:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005718:	00054d63          	bltz	a0,80005732 <sys_read+0x5c>
  return fileread(f, p, n);
    8000571c:	fe442603          	lw	a2,-28(s0)
    80005720:	fd843583          	ld	a1,-40(s0)
    80005724:	fe843503          	ld	a0,-24(s0)
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	43c080e7          	jalr	1084(ra) # 80004b64 <fileread>
    80005730:	87aa                	mv	a5,a0
}
    80005732:	853e                	mv	a0,a5
    80005734:	70a2                	ld	ra,40(sp)
    80005736:	7402                	ld	s0,32(sp)
    80005738:	6145                	addi	sp,sp,48
    8000573a:	8082                	ret

000000008000573c <sys_write>:
{
    8000573c:	7179                	addi	sp,sp,-48
    8000573e:	f406                	sd	ra,40(sp)
    80005740:	f022                	sd	s0,32(sp)
    80005742:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005744:	fe840613          	addi	a2,s0,-24
    80005748:	4581                	li	a1,0
    8000574a:	4501                	li	a0,0
    8000574c:	00000097          	auipc	ra,0x0
    80005750:	d28080e7          	jalr	-728(ra) # 80005474 <argfd>
    return -1;
    80005754:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005756:	04054163          	bltz	a0,80005798 <sys_write+0x5c>
    8000575a:	fe440593          	addi	a1,s0,-28
    8000575e:	4509                	li	a0,2
    80005760:	ffffd097          	auipc	ra,0xffffd
    80005764:	5f0080e7          	jalr	1520(ra) # 80002d50 <argint>
    return -1;
    80005768:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576a:	02054763          	bltz	a0,80005798 <sys_write+0x5c>
    8000576e:	fd840593          	addi	a1,s0,-40
    80005772:	4505                	li	a0,1
    80005774:	ffffd097          	auipc	ra,0xffffd
    80005778:	5fe080e7          	jalr	1534(ra) # 80002d72 <argaddr>
    return -1;
    8000577c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577e:	00054d63          	bltz	a0,80005798 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005782:	fe442603          	lw	a2,-28(s0)
    80005786:	fd843583          	ld	a1,-40(s0)
    8000578a:	fe843503          	ld	a0,-24(s0)
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	498080e7          	jalr	1176(ra) # 80004c26 <filewrite>
    80005796:	87aa                	mv	a5,a0
}
    80005798:	853e                	mv	a0,a5
    8000579a:	70a2                	ld	ra,40(sp)
    8000579c:	7402                	ld	s0,32(sp)
    8000579e:	6145                	addi	sp,sp,48
    800057a0:	8082                	ret

00000000800057a2 <sys_close>:
{
    800057a2:	1101                	addi	sp,sp,-32
    800057a4:	ec06                	sd	ra,24(sp)
    800057a6:	e822                	sd	s0,16(sp)
    800057a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057aa:	fe040613          	addi	a2,s0,-32
    800057ae:	fec40593          	addi	a1,s0,-20
    800057b2:	4501                	li	a0,0
    800057b4:	00000097          	auipc	ra,0x0
    800057b8:	cc0080e7          	jalr	-832(ra) # 80005474 <argfd>
    return -1;
    800057bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057be:	02054563          	bltz	a0,800057e8 <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    800057c2:	ffffc097          	auipc	ra,0xffffc
    800057c6:	24c080e7          	jalr	588(ra) # 80001a0e <myproc>
    800057ca:	fec42783          	lw	a5,-20(s0)
    800057ce:	22478793          	addi	a5,a5,548
    800057d2:	078e                	slli	a5,a5,0x3
    800057d4:	97aa                	add	a5,a5,a0
    800057d6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057da:	fe043503          	ld	a0,-32(s0)
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	24a080e7          	jalr	586(ra) # 80004a28 <fileclose>
  return 0;
    800057e6:	4781                	li	a5,0
}
    800057e8:	853e                	mv	a0,a5
    800057ea:	60e2                	ld	ra,24(sp)
    800057ec:	6442                	ld	s0,16(sp)
    800057ee:	6105                	addi	sp,sp,32
    800057f0:	8082                	ret

00000000800057f2 <sys_fstat>:
{
    800057f2:	1101                	addi	sp,sp,-32
    800057f4:	ec06                	sd	ra,24(sp)
    800057f6:	e822                	sd	s0,16(sp)
    800057f8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fa:	fe840613          	addi	a2,s0,-24
    800057fe:	4581                	li	a1,0
    80005800:	4501                	li	a0,0
    80005802:	00000097          	auipc	ra,0x0
    80005806:	c72080e7          	jalr	-910(ra) # 80005474 <argfd>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000580c:	02054563          	bltz	a0,80005836 <sys_fstat+0x44>
    80005810:	fe040593          	addi	a1,s0,-32
    80005814:	4505                	li	a0,1
    80005816:	ffffd097          	auipc	ra,0xffffd
    8000581a:	55c080e7          	jalr	1372(ra) # 80002d72 <argaddr>
    return -1;
    8000581e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005820:	00054b63          	bltz	a0,80005836 <sys_fstat+0x44>
  return filestat(f, st);
    80005824:	fe043583          	ld	a1,-32(s0)
    80005828:	fe843503          	ld	a0,-24(s0)
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	2c4080e7          	jalr	708(ra) # 80004af0 <filestat>
    80005834:	87aa                	mv	a5,a0
}
    80005836:	853e                	mv	a0,a5
    80005838:	60e2                	ld	ra,24(sp)
    8000583a:	6442                	ld	s0,16(sp)
    8000583c:	6105                	addi	sp,sp,32
    8000583e:	8082                	ret

0000000080005840 <sys_link>:
{
    80005840:	7169                	addi	sp,sp,-304
    80005842:	f606                	sd	ra,296(sp)
    80005844:	f222                	sd	s0,288(sp)
    80005846:	ee26                	sd	s1,280(sp)
    80005848:	ea4a                	sd	s2,272(sp)
    8000584a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584c:	08000613          	li	a2,128
    80005850:	ed040593          	addi	a1,s0,-304
    80005854:	4501                	li	a0,0
    80005856:	ffffd097          	auipc	ra,0xffffd
    8000585a:	53e080e7          	jalr	1342(ra) # 80002d94 <argstr>
    return -1;
    8000585e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005860:	10054e63          	bltz	a0,8000597c <sys_link+0x13c>
    80005864:	08000613          	li	a2,128
    80005868:	f5040593          	addi	a1,s0,-176
    8000586c:	4505                	li	a0,1
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	526080e7          	jalr	1318(ra) # 80002d94 <argstr>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005878:	10054263          	bltz	a0,8000597c <sys_link+0x13c>
  begin_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	cd8080e7          	jalr	-808(ra) # 80004554 <begin_op>
  if((ip = namei(old)) == 0){
    80005884:	ed040513          	addi	a0,s0,-304
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	ab0080e7          	jalr	-1360(ra) # 80004338 <namei>
    80005890:	84aa                	mv	s1,a0
    80005892:	c551                	beqz	a0,8000591e <sys_link+0xde>
  ilock(ip);
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	2ec080e7          	jalr	748(ra) # 80003b80 <ilock>
  if(ip->type == T_DIR){
    8000589c:	04449703          	lh	a4,68(s1)
    800058a0:	4785                	li	a5,1
    800058a2:	08f70463          	beq	a4,a5,8000592a <sys_link+0xea>
  ip->nlink++;
    800058a6:	04a4d783          	lhu	a5,74(s1)
    800058aa:	2785                	addiw	a5,a5,1
    800058ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058b0:	8526                	mv	a0,s1
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	204080e7          	jalr	516(ra) # 80003ab6 <iupdate>
  iunlock(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	386080e7          	jalr	902(ra) # 80003c42 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058c4:	fd040593          	addi	a1,s0,-48
    800058c8:	f5040513          	addi	a0,s0,-176
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	a8a080e7          	jalr	-1398(ra) # 80004356 <nameiparent>
    800058d4:	892a                	mv	s2,a0
    800058d6:	c935                	beqz	a0,8000594a <sys_link+0x10a>
  ilock(dp);
    800058d8:	ffffe097          	auipc	ra,0xffffe
    800058dc:	2a8080e7          	jalr	680(ra) # 80003b80 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058e0:	00092703          	lw	a4,0(s2)
    800058e4:	409c                	lw	a5,0(s1)
    800058e6:	04f71d63          	bne	a4,a5,80005940 <sys_link+0x100>
    800058ea:	40d0                	lw	a2,4(s1)
    800058ec:	fd040593          	addi	a1,s0,-48
    800058f0:	854a                	mv	a0,s2
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	984080e7          	jalr	-1660(ra) # 80004276 <dirlink>
    800058fa:	04054363          	bltz	a0,80005940 <sys_link+0x100>
  iunlockput(dp);
    800058fe:	854a                	mv	a0,s2
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	4e2080e7          	jalr	1250(ra) # 80003de2 <iunlockput>
  iput(ip);
    80005908:	8526                	mv	a0,s1
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	430080e7          	jalr	1072(ra) # 80003d3a <iput>
  end_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	cc2080e7          	jalr	-830(ra) # 800045d4 <end_op>
  return 0;
    8000591a:	4781                	li	a5,0
    8000591c:	a085                	j	8000597c <sys_link+0x13c>
    end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	cb6080e7          	jalr	-842(ra) # 800045d4 <end_op>
    return -1;
    80005926:	57fd                	li	a5,-1
    80005928:	a891                	j	8000597c <sys_link+0x13c>
    iunlockput(ip);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	4b6080e7          	jalr	1206(ra) # 80003de2 <iunlockput>
    end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	ca0080e7          	jalr	-864(ra) # 800045d4 <end_op>
    return -1;
    8000593c:	57fd                	li	a5,-1
    8000593e:	a83d                	j	8000597c <sys_link+0x13c>
    iunlockput(dp);
    80005940:	854a                	mv	a0,s2
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	4a0080e7          	jalr	1184(ra) # 80003de2 <iunlockput>
  ilock(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	234080e7          	jalr	564(ra) # 80003b80 <ilock>
  ip->nlink--;
    80005954:	04a4d783          	lhu	a5,74(s1)
    80005958:	37fd                	addiw	a5,a5,-1
    8000595a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000595e:	8526                	mv	a0,s1
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	156080e7          	jalr	342(ra) # 80003ab6 <iupdate>
  iunlockput(ip);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	478080e7          	jalr	1144(ra) # 80003de2 <iunlockput>
  end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	c62080e7          	jalr	-926(ra) # 800045d4 <end_op>
  return -1;
    8000597a:	57fd                	li	a5,-1
}
    8000597c:	853e                	mv	a0,a5
    8000597e:	70b2                	ld	ra,296(sp)
    80005980:	7412                	ld	s0,288(sp)
    80005982:	64f2                	ld	s1,280(sp)
    80005984:	6952                	ld	s2,272(sp)
    80005986:	6155                	addi	sp,sp,304
    80005988:	8082                	ret

000000008000598a <sys_unlink>:
{
    8000598a:	7151                	addi	sp,sp,-240
    8000598c:	f586                	sd	ra,232(sp)
    8000598e:	f1a2                	sd	s0,224(sp)
    80005990:	eda6                	sd	s1,216(sp)
    80005992:	e9ca                	sd	s2,208(sp)
    80005994:	e5ce                	sd	s3,200(sp)
    80005996:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005998:	08000613          	li	a2,128
    8000599c:	f3040593          	addi	a1,s0,-208
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	3f2080e7          	jalr	1010(ra) # 80002d94 <argstr>
    800059aa:	18054163          	bltz	a0,80005b2c <sys_unlink+0x1a2>
  begin_op();
    800059ae:	fffff097          	auipc	ra,0xfffff
    800059b2:	ba6080e7          	jalr	-1114(ra) # 80004554 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059b6:	fb040593          	addi	a1,s0,-80
    800059ba:	f3040513          	addi	a0,s0,-208
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	998080e7          	jalr	-1640(ra) # 80004356 <nameiparent>
    800059c6:	84aa                	mv	s1,a0
    800059c8:	c979                	beqz	a0,80005a9e <sys_unlink+0x114>
  ilock(dp);
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	1b6080e7          	jalr	438(ra) # 80003b80 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059d2:	00003597          	auipc	a1,0x3
    800059d6:	d2658593          	addi	a1,a1,-730 # 800086f8 <syscalls+0x2d8>
    800059da:	fb040513          	addi	a0,s0,-80
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	66a080e7          	jalr	1642(ra) # 80004048 <namecmp>
    800059e6:	14050a63          	beqz	a0,80005b3a <sys_unlink+0x1b0>
    800059ea:	00003597          	auipc	a1,0x3
    800059ee:	d1658593          	addi	a1,a1,-746 # 80008700 <syscalls+0x2e0>
    800059f2:	fb040513          	addi	a0,s0,-80
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	652080e7          	jalr	1618(ra) # 80004048 <namecmp>
    800059fe:	12050e63          	beqz	a0,80005b3a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a02:	f2c40613          	addi	a2,s0,-212
    80005a06:	fb040593          	addi	a1,s0,-80
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	656080e7          	jalr	1622(ra) # 80004062 <dirlookup>
    80005a14:	892a                	mv	s2,a0
    80005a16:	12050263          	beqz	a0,80005b3a <sys_unlink+0x1b0>
  ilock(ip);
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	166080e7          	jalr	358(ra) # 80003b80 <ilock>
  if(ip->nlink < 1)
    80005a22:	04a91783          	lh	a5,74(s2)
    80005a26:	08f05263          	blez	a5,80005aaa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a2a:	04491703          	lh	a4,68(s2)
    80005a2e:	4785                	li	a5,1
    80005a30:	08f70563          	beq	a4,a5,80005aba <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a34:	4641                	li	a2,16
    80005a36:	4581                	li	a1,0
    80005a38:	fc040513          	addi	a0,s0,-64
    80005a3c:	ffffb097          	auipc	ra,0xffffb
    80005a40:	2c6080e7          	jalr	710(ra) # 80000d02 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a44:	4741                	li	a4,16
    80005a46:	f2c42683          	lw	a3,-212(s0)
    80005a4a:	fc040613          	addi	a2,s0,-64
    80005a4e:	4581                	li	a1,0
    80005a50:	8526                	mv	a0,s1
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	4da080e7          	jalr	1242(ra) # 80003f2c <writei>
    80005a5a:	47c1                	li	a5,16
    80005a5c:	0af51563          	bne	a0,a5,80005b06 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a60:	04491703          	lh	a4,68(s2)
    80005a64:	4785                	li	a5,1
    80005a66:	0af70863          	beq	a4,a5,80005b16 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	376080e7          	jalr	886(ra) # 80003de2 <iunlockput>
  ip->nlink--;
    80005a74:	04a95783          	lhu	a5,74(s2)
    80005a78:	37fd                	addiw	a5,a5,-1
    80005a7a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	036080e7          	jalr	54(ra) # 80003ab6 <iupdate>
  iunlockput(ip);
    80005a88:	854a                	mv	a0,s2
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	358080e7          	jalr	856(ra) # 80003de2 <iunlockput>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	b42080e7          	jalr	-1214(ra) # 800045d4 <end_op>
  return 0;
    80005a9a:	4501                	li	a0,0
    80005a9c:	a84d                	j	80005b4e <sys_unlink+0x1c4>
    end_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	b36080e7          	jalr	-1226(ra) # 800045d4 <end_op>
    return -1;
    80005aa6:	557d                	li	a0,-1
    80005aa8:	a05d                	j	80005b4e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aaa:	00003517          	auipc	a0,0x3
    80005aae:	c7e50513          	addi	a0,a0,-898 # 80008728 <syscalls+0x308>
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	a98080e7          	jalr	-1384(ra) # 8000054a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aba:	04c92703          	lw	a4,76(s2)
    80005abe:	02000793          	li	a5,32
    80005ac2:	f6e7f9e3          	bgeu	a5,a4,80005a34 <sys_unlink+0xaa>
    80005ac6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aca:	4741                	li	a4,16
    80005acc:	86ce                	mv	a3,s3
    80005ace:	f1840613          	addi	a2,s0,-232
    80005ad2:	4581                	li	a1,0
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	35e080e7          	jalr	862(ra) # 80003e34 <readi>
    80005ade:	47c1                	li	a5,16
    80005ae0:	00f51b63          	bne	a0,a5,80005af6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ae4:	f1845783          	lhu	a5,-232(s0)
    80005ae8:	e7a1                	bnez	a5,80005b30 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aea:	29c1                	addiw	s3,s3,16
    80005aec:	04c92783          	lw	a5,76(s2)
    80005af0:	fcf9ede3          	bltu	s3,a5,80005aca <sys_unlink+0x140>
    80005af4:	b781                	j	80005a34 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005af6:	00003517          	auipc	a0,0x3
    80005afa:	c4a50513          	addi	a0,a0,-950 # 80008740 <syscalls+0x320>
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	a4c080e7          	jalr	-1460(ra) # 8000054a <panic>
    panic("unlink: writei");
    80005b06:	00003517          	auipc	a0,0x3
    80005b0a:	c5250513          	addi	a0,a0,-942 # 80008758 <syscalls+0x338>
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	a3c080e7          	jalr	-1476(ra) # 8000054a <panic>
    dp->nlink--;
    80005b16:	04a4d783          	lhu	a5,74(s1)
    80005b1a:	37fd                	addiw	a5,a5,-1
    80005b1c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b20:	8526                	mv	a0,s1
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	f94080e7          	jalr	-108(ra) # 80003ab6 <iupdate>
    80005b2a:	b781                	j	80005a6a <sys_unlink+0xe0>
    return -1;
    80005b2c:	557d                	li	a0,-1
    80005b2e:	a005                	j	80005b4e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b30:	854a                	mv	a0,s2
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	2b0080e7          	jalr	688(ra) # 80003de2 <iunlockput>
  iunlockput(dp);
    80005b3a:	8526                	mv	a0,s1
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	2a6080e7          	jalr	678(ra) # 80003de2 <iunlockput>
  end_op();
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	a90080e7          	jalr	-1392(ra) # 800045d4 <end_op>
  return -1;
    80005b4c:	557d                	li	a0,-1
}
    80005b4e:	70ae                	ld	ra,232(sp)
    80005b50:	740e                	ld	s0,224(sp)
    80005b52:	64ee                	ld	s1,216(sp)
    80005b54:	694e                	ld	s2,208(sp)
    80005b56:	69ae                	ld	s3,200(sp)
    80005b58:	616d                	addi	sp,sp,240
    80005b5a:	8082                	ret

0000000080005b5c <sys_open>:

uint64
sys_open(void)
{
    80005b5c:	7131                	addi	sp,sp,-192
    80005b5e:	fd06                	sd	ra,184(sp)
    80005b60:	f922                	sd	s0,176(sp)
    80005b62:	f526                	sd	s1,168(sp)
    80005b64:	f14a                	sd	s2,160(sp)
    80005b66:	ed4e                	sd	s3,152(sp)
    80005b68:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6a:	08000613          	li	a2,128
    80005b6e:	f5040593          	addi	a1,s0,-176
    80005b72:	4501                	li	a0,0
    80005b74:	ffffd097          	auipc	ra,0xffffd
    80005b78:	220080e7          	jalr	544(ra) # 80002d94 <argstr>
    return -1;
    80005b7c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b7e:	0c054163          	bltz	a0,80005c40 <sys_open+0xe4>
    80005b82:	f4c40593          	addi	a1,s0,-180
    80005b86:	4505                	li	a0,1
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	1c8080e7          	jalr	456(ra) # 80002d50 <argint>
    80005b90:	0a054863          	bltz	a0,80005c40 <sys_open+0xe4>

  begin_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	9c0080e7          	jalr	-1600(ra) # 80004554 <begin_op>

  if(omode & O_CREATE){
    80005b9c:	f4c42783          	lw	a5,-180(s0)
    80005ba0:	2007f793          	andi	a5,a5,512
    80005ba4:	cbdd                	beqz	a5,80005c5a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ba6:	4681                	li	a3,0
    80005ba8:	4601                	li	a2,0
    80005baa:	4589                	li	a1,2
    80005bac:	f5040513          	addi	a0,s0,-176
    80005bb0:	00000097          	auipc	ra,0x0
    80005bb4:	972080e7          	jalr	-1678(ra) # 80005522 <create>
    80005bb8:	892a                	mv	s2,a0
    if(ip == 0){
    80005bba:	c959                	beqz	a0,80005c50 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bbc:	04491703          	lh	a4,68(s2)
    80005bc0:	478d                	li	a5,3
    80005bc2:	00f71763          	bne	a4,a5,80005bd0 <sys_open+0x74>
    80005bc6:	04695703          	lhu	a4,70(s2)
    80005bca:	47a5                	li	a5,9
    80005bcc:	0ce7ec63          	bltu	a5,a4,80005ca4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	d9c080e7          	jalr	-612(ra) # 8000496c <filealloc>
    80005bd8:	89aa                	mv	s3,a0
    80005bda:	10050263          	beqz	a0,80005cde <sys_open+0x182>
    80005bde:	00000097          	auipc	ra,0x0
    80005be2:	8fe080e7          	jalr	-1794(ra) # 800054dc <fdalloc>
    80005be6:	84aa                	mv	s1,a0
    80005be8:	0e054663          	bltz	a0,80005cd4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bec:	04491703          	lh	a4,68(s2)
    80005bf0:	478d                	li	a5,3
    80005bf2:	0cf70463          	beq	a4,a5,80005cba <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bf6:	4789                	li	a5,2
    80005bf8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bfc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c00:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c04:	f4c42783          	lw	a5,-180(s0)
    80005c08:	0017c713          	xori	a4,a5,1
    80005c0c:	8b05                	andi	a4,a4,1
    80005c0e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c12:	0037f713          	andi	a4,a5,3
    80005c16:	00e03733          	snez	a4,a4
    80005c1a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c1e:	4007f793          	andi	a5,a5,1024
    80005c22:	c791                	beqz	a5,80005c2e <sys_open+0xd2>
    80005c24:	04491703          	lh	a4,68(s2)
    80005c28:	4789                	li	a5,2
    80005c2a:	08f70f63          	beq	a4,a5,80005cc8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c2e:	854a                	mv	a0,s2
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	012080e7          	jalr	18(ra) # 80003c42 <iunlock>
  end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	99c080e7          	jalr	-1636(ra) # 800045d4 <end_op>

  return fd;
}
    80005c40:	8526                	mv	a0,s1
    80005c42:	70ea                	ld	ra,184(sp)
    80005c44:	744a                	ld	s0,176(sp)
    80005c46:	74aa                	ld	s1,168(sp)
    80005c48:	790a                	ld	s2,160(sp)
    80005c4a:	69ea                	ld	s3,152(sp)
    80005c4c:	6129                	addi	sp,sp,192
    80005c4e:	8082                	ret
      end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	984080e7          	jalr	-1660(ra) # 800045d4 <end_op>
      return -1;
    80005c58:	b7e5                	j	80005c40 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c5a:	f5040513          	addi	a0,s0,-176
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	6da080e7          	jalr	1754(ra) # 80004338 <namei>
    80005c66:	892a                	mv	s2,a0
    80005c68:	c905                	beqz	a0,80005c98 <sys_open+0x13c>
    ilock(ip);
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	f16080e7          	jalr	-234(ra) # 80003b80 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c72:	04491703          	lh	a4,68(s2)
    80005c76:	4785                	li	a5,1
    80005c78:	f4f712e3          	bne	a4,a5,80005bbc <sys_open+0x60>
    80005c7c:	f4c42783          	lw	a5,-180(s0)
    80005c80:	dba1                	beqz	a5,80005bd0 <sys_open+0x74>
      iunlockput(ip);
    80005c82:	854a                	mv	a0,s2
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	15e080e7          	jalr	350(ra) # 80003de2 <iunlockput>
      end_op();
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	948080e7          	jalr	-1720(ra) # 800045d4 <end_op>
      return -1;
    80005c94:	54fd                	li	s1,-1
    80005c96:	b76d                	j	80005c40 <sys_open+0xe4>
      end_op();
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	93c080e7          	jalr	-1732(ra) # 800045d4 <end_op>
      return -1;
    80005ca0:	54fd                	li	s1,-1
    80005ca2:	bf79                	j	80005c40 <sys_open+0xe4>
    iunlockput(ip);
    80005ca4:	854a                	mv	a0,s2
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	13c080e7          	jalr	316(ra) # 80003de2 <iunlockput>
    end_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	926080e7          	jalr	-1754(ra) # 800045d4 <end_op>
    return -1;
    80005cb6:	54fd                	li	s1,-1
    80005cb8:	b761                	j	80005c40 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cba:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cbe:	04691783          	lh	a5,70(s2)
    80005cc2:	02f99223          	sh	a5,36(s3)
    80005cc6:	bf2d                	j	80005c00 <sys_open+0xa4>
    itrunc(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	fc4080e7          	jalr	-60(ra) # 80003c8e <itrunc>
    80005cd2:	bfb1                	j	80005c2e <sys_open+0xd2>
      fileclose(f);
    80005cd4:	854e                	mv	a0,s3
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	d52080e7          	jalr	-686(ra) # 80004a28 <fileclose>
    iunlockput(ip);
    80005cde:	854a                	mv	a0,s2
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	102080e7          	jalr	258(ra) # 80003de2 <iunlockput>
    end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	8ec080e7          	jalr	-1812(ra) # 800045d4 <end_op>
    return -1;
    80005cf0:	54fd                	li	s1,-1
    80005cf2:	b7b9                	j	80005c40 <sys_open+0xe4>

0000000080005cf4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cf4:	7175                	addi	sp,sp,-144
    80005cf6:	e506                	sd	ra,136(sp)
    80005cf8:	e122                	sd	s0,128(sp)
    80005cfa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	858080e7          	jalr	-1960(ra) # 80004554 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d04:	08000613          	li	a2,128
    80005d08:	f7040593          	addi	a1,s0,-144
    80005d0c:	4501                	li	a0,0
    80005d0e:	ffffd097          	auipc	ra,0xffffd
    80005d12:	086080e7          	jalr	134(ra) # 80002d94 <argstr>
    80005d16:	02054963          	bltz	a0,80005d48 <sys_mkdir+0x54>
    80005d1a:	4681                	li	a3,0
    80005d1c:	4601                	li	a2,0
    80005d1e:	4585                	li	a1,1
    80005d20:	f7040513          	addi	a0,s0,-144
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	7fe080e7          	jalr	2046(ra) # 80005522 <create>
    80005d2c:	cd11                	beqz	a0,80005d48 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	0b4080e7          	jalr	180(ra) # 80003de2 <iunlockput>
  end_op();
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	89e080e7          	jalr	-1890(ra) # 800045d4 <end_op>
  return 0;
    80005d3e:	4501                	li	a0,0
}
    80005d40:	60aa                	ld	ra,136(sp)
    80005d42:	640a                	ld	s0,128(sp)
    80005d44:	6149                	addi	sp,sp,144
    80005d46:	8082                	ret
    end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	88c080e7          	jalr	-1908(ra) # 800045d4 <end_op>
    return -1;
    80005d50:	557d                	li	a0,-1
    80005d52:	b7fd                	j	80005d40 <sys_mkdir+0x4c>

0000000080005d54 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d54:	7135                	addi	sp,sp,-160
    80005d56:	ed06                	sd	ra,152(sp)
    80005d58:	e922                	sd	s0,144(sp)
    80005d5a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	7f8080e7          	jalr	2040(ra) # 80004554 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d64:	08000613          	li	a2,128
    80005d68:	f7040593          	addi	a1,s0,-144
    80005d6c:	4501                	li	a0,0
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	026080e7          	jalr	38(ra) # 80002d94 <argstr>
    80005d76:	04054a63          	bltz	a0,80005dca <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d7a:	f6c40593          	addi	a1,s0,-148
    80005d7e:	4505                	li	a0,1
    80005d80:	ffffd097          	auipc	ra,0xffffd
    80005d84:	fd0080e7          	jalr	-48(ra) # 80002d50 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d88:	04054163          	bltz	a0,80005dca <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d8c:	f6840593          	addi	a1,s0,-152
    80005d90:	4509                	li	a0,2
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	fbe080e7          	jalr	-66(ra) # 80002d50 <argint>
     argint(1, &major) < 0 ||
    80005d9a:	02054863          	bltz	a0,80005dca <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d9e:	f6841683          	lh	a3,-152(s0)
    80005da2:	f6c41603          	lh	a2,-148(s0)
    80005da6:	458d                	li	a1,3
    80005da8:	f7040513          	addi	a0,s0,-144
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	776080e7          	jalr	1910(ra) # 80005522 <create>
     argint(2, &minor) < 0 ||
    80005db4:	c919                	beqz	a0,80005dca <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	02c080e7          	jalr	44(ra) # 80003de2 <iunlockput>
  end_op();
    80005dbe:	fffff097          	auipc	ra,0xfffff
    80005dc2:	816080e7          	jalr	-2026(ra) # 800045d4 <end_op>
  return 0;
    80005dc6:	4501                	li	a0,0
    80005dc8:	a031                	j	80005dd4 <sys_mknod+0x80>
    end_op();
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	80a080e7          	jalr	-2038(ra) # 800045d4 <end_op>
    return -1;
    80005dd2:	557d                	li	a0,-1
}
    80005dd4:	60ea                	ld	ra,152(sp)
    80005dd6:	644a                	ld	s0,144(sp)
    80005dd8:	610d                	addi	sp,sp,160
    80005dda:	8082                	ret

0000000080005ddc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ddc:	7135                	addi	sp,sp,-160
    80005dde:	ed06                	sd	ra,152(sp)
    80005de0:	e922                	sd	s0,144(sp)
    80005de2:	e526                	sd	s1,136(sp)
    80005de4:	e14a                	sd	s2,128(sp)
    80005de6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	c26080e7          	jalr	-986(ra) # 80001a0e <myproc>
    80005df0:	892a                	mv	s2,a0
  
  begin_op();
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	762080e7          	jalr	1890(ra) # 80004554 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dfa:	08000613          	li	a2,128
    80005dfe:	f6040593          	addi	a1,s0,-160
    80005e02:	4501                	li	a0,0
    80005e04:	ffffd097          	auipc	ra,0xffffd
    80005e08:	f90080e7          	jalr	-112(ra) # 80002d94 <argstr>
    80005e0c:	04054d63          	bltz	a0,80005e66 <sys_chdir+0x8a>
    80005e10:	f6040513          	addi	a0,s0,-160
    80005e14:	ffffe097          	auipc	ra,0xffffe
    80005e18:	524080e7          	jalr	1316(ra) # 80004338 <namei>
    80005e1c:	84aa                	mv	s1,a0
    80005e1e:	c521                	beqz	a0,80005e66 <sys_chdir+0x8a>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	d60080e7          	jalr	-672(ra) # 80003b80 <ilock>
  if(ip->type != T_DIR){
    80005e28:	04449703          	lh	a4,68(s1)
    80005e2c:	4785                	li	a5,1
    80005e2e:	04f71263          	bne	a4,a5,80005e72 <sys_chdir+0x96>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e32:	8526                	mv	a0,s1
    80005e34:	ffffe097          	auipc	ra,0xffffe
    80005e38:	e0e080e7          	jalr	-498(ra) # 80003c42 <iunlock>
  iput(p->cwd);
    80005e3c:	6505                	lui	a0,0x1
    80005e3e:	992a                	add	s2,s2,a0
    80005e40:	1a093503          	ld	a0,416(s2)
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	ef6080e7          	jalr	-266(ra) # 80003d3a <iput>
  end_op();
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	788080e7          	jalr	1928(ra) # 800045d4 <end_op>
  p->cwd = ip;
    80005e54:	1a993023          	sd	s1,416(s2)
  return 0;
    80005e58:	4501                	li	a0,0
}
    80005e5a:	60ea                	ld	ra,152(sp)
    80005e5c:	644a                	ld	s0,144(sp)
    80005e5e:	64aa                	ld	s1,136(sp)
    80005e60:	690a                	ld	s2,128(sp)
    80005e62:	610d                	addi	sp,sp,160
    80005e64:	8082                	ret
    end_op();
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	76e080e7          	jalr	1902(ra) # 800045d4 <end_op>
    return -1;
    80005e6e:	557d                	li	a0,-1
    80005e70:	b7ed                	j	80005e5a <sys_chdir+0x7e>
    iunlockput(ip);
    80005e72:	8526                	mv	a0,s1
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	f6e080e7          	jalr	-146(ra) # 80003de2 <iunlockput>
    end_op();
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	758080e7          	jalr	1880(ra) # 800045d4 <end_op>
    return -1;
    80005e84:	557d                	li	a0,-1
    80005e86:	bfd1                	j	80005e5a <sys_chdir+0x7e>

0000000080005e88 <sys_exec>:

uint64
sys_exec(void)
{
    80005e88:	7145                	addi	sp,sp,-464
    80005e8a:	e786                	sd	ra,456(sp)
    80005e8c:	e3a2                	sd	s0,448(sp)
    80005e8e:	ff26                	sd	s1,440(sp)
    80005e90:	fb4a                	sd	s2,432(sp)
    80005e92:	f74e                	sd	s3,424(sp)
    80005e94:	f352                	sd	s4,416(sp)
    80005e96:	ef56                	sd	s5,408(sp)
    80005e98:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e9a:	08000613          	li	a2,128
    80005e9e:	f4040593          	addi	a1,s0,-192
    80005ea2:	4501                	li	a0,0
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	ef0080e7          	jalr	-272(ra) # 80002d94 <argstr>
    return -1;
    80005eac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eae:	0c054a63          	bltz	a0,80005f82 <sys_exec+0xfa>
    80005eb2:	e3840593          	addi	a1,s0,-456
    80005eb6:	4505                	li	a0,1
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	eba080e7          	jalr	-326(ra) # 80002d72 <argaddr>
    80005ec0:	0c054163          	bltz	a0,80005f82 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ec4:	10000613          	li	a2,256
    80005ec8:	4581                	li	a1,0
    80005eca:	e4040513          	addi	a0,s0,-448
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	e34080e7          	jalr	-460(ra) # 80000d02 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ed6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005eda:	89a6                	mv	s3,s1
    80005edc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ede:	02000a13          	li	s4,32
    80005ee2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ee6:	00391793          	slli	a5,s2,0x3
    80005eea:	e3040593          	addi	a1,s0,-464
    80005eee:	e3843503          	ld	a0,-456(s0)
    80005ef2:	953e                	add	a0,a0,a5
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	db6080e7          	jalr	-586(ra) # 80002caa <fetchaddr>
    80005efc:	02054a63          	bltz	a0,80005f30 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f00:	e3043783          	ld	a5,-464(s0)
    80005f04:	c3b9                	beqz	a5,80005f4a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	c10080e7          	jalr	-1008(ra) # 80000b16 <kalloc>
    80005f0e:	85aa                	mv	a1,a0
    80005f10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f14:	cd11                	beqz	a0,80005f30 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f16:	6605                	lui	a2,0x1
    80005f18:	e3043503          	ld	a0,-464(s0)
    80005f1c:	ffffd097          	auipc	ra,0xffffd
    80005f20:	de8080e7          	jalr	-536(ra) # 80002d04 <fetchstr>
    80005f24:	00054663          	bltz	a0,80005f30 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f28:	0905                	addi	s2,s2,1
    80005f2a:	09a1                	addi	s3,s3,8
    80005f2c:	fb491be3          	bne	s2,s4,80005ee2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f30:	10048913          	addi	s2,s1,256
    80005f34:	6088                	ld	a0,0(s1)
    80005f36:	c529                	beqz	a0,80005f80 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	ae2080e7          	jalr	-1310(ra) # 80000a1a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f40:	04a1                	addi	s1,s1,8
    80005f42:	ff2499e3          	bne	s1,s2,80005f34 <sys_exec+0xac>
  return -1;
    80005f46:	597d                	li	s2,-1
    80005f48:	a82d                	j	80005f82 <sys_exec+0xfa>
      argv[i] = 0;
    80005f4a:	0a8e                	slli	s5,s5,0x3
    80005f4c:	fc040793          	addi	a5,s0,-64
    80005f50:	9abe                	add	s5,s5,a5
    80005f52:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ff97e80>
  int ret = exec(path, argv);
    80005f56:	e4040593          	addi	a1,s0,-448
    80005f5a:	f4040513          	addi	a0,s0,-192
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	162080e7          	jalr	354(ra) # 800050c0 <exec>
    80005f66:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f68:	10048993          	addi	s3,s1,256
    80005f6c:	6088                	ld	a0,0(s1)
    80005f6e:	c911                	beqz	a0,80005f82 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	aaa080e7          	jalr	-1366(ra) # 80000a1a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f78:	04a1                	addi	s1,s1,8
    80005f7a:	ff3499e3          	bne	s1,s3,80005f6c <sys_exec+0xe4>
    80005f7e:	a011                	j	80005f82 <sys_exec+0xfa>
  return -1;
    80005f80:	597d                	li	s2,-1
}
    80005f82:	854a                	mv	a0,s2
    80005f84:	60be                	ld	ra,456(sp)
    80005f86:	641e                	ld	s0,448(sp)
    80005f88:	74fa                	ld	s1,440(sp)
    80005f8a:	795a                	ld	s2,432(sp)
    80005f8c:	79ba                	ld	s3,424(sp)
    80005f8e:	7a1a                	ld	s4,416(sp)
    80005f90:	6afa                	ld	s5,408(sp)
    80005f92:	6179                	addi	sp,sp,464
    80005f94:	8082                	ret

0000000080005f96 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f96:	7139                	addi	sp,sp,-64
    80005f98:	fc06                	sd	ra,56(sp)
    80005f9a:	f822                	sd	s0,48(sp)
    80005f9c:	f426                	sd	s1,40(sp)
    80005f9e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	a6e080e7          	jalr	-1426(ra) # 80001a0e <myproc>
    80005fa8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005faa:	fd840593          	addi	a1,s0,-40
    80005fae:	4501                	li	a0,0
    80005fb0:	ffffd097          	auipc	ra,0xffffd
    80005fb4:	dc2080e7          	jalr	-574(ra) # 80002d72 <argaddr>
    return -1;
    80005fb8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fba:	0e054663          	bltz	a0,800060a6 <sys_pipe+0x110>
  if(pipealloc(&rf, &wf) < 0)
    80005fbe:	fc840593          	addi	a1,s0,-56
    80005fc2:	fd040513          	addi	a0,s0,-48
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	dba080e7          	jalr	-582(ra) # 80004d80 <pipealloc>
    return -1;
    80005fce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fd0:	0c054b63          	bltz	a0,800060a6 <sys_pipe+0x110>
  fd0 = -1;
    80005fd4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fd8:	fd043503          	ld	a0,-48(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	500080e7          	jalr	1280(ra) # 800054dc <fdalloc>
    80005fe4:	fca42223          	sw	a0,-60(s0)
    80005fe8:	0a054263          	bltz	a0,8000608c <sys_pipe+0xf6>
    80005fec:	fc843503          	ld	a0,-56(s0)
    80005ff0:	fffff097          	auipc	ra,0xfffff
    80005ff4:	4ec080e7          	jalr	1260(ra) # 800054dc <fdalloc>
    80005ff8:	fca42023          	sw	a0,-64(s0)
    80005ffc:	06054e63          	bltz	a0,80006078 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006000:	6785                	lui	a5,0x1
    80006002:	97a6                	add	a5,a5,s1
    80006004:	4691                	li	a3,4
    80006006:	fc440613          	addi	a2,s0,-60
    8000600a:	fd843583          	ld	a1,-40(s0)
    8000600e:	73c8                	ld	a0,160(a5)
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	672080e7          	jalr	1650(ra) # 80001682 <copyout>
    80006018:	02054263          	bltz	a0,8000603c <sys_pipe+0xa6>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000601c:	6785                	lui	a5,0x1
    8000601e:	97a6                	add	a5,a5,s1
    80006020:	4691                	li	a3,4
    80006022:	fc040613          	addi	a2,s0,-64
    80006026:	fd843583          	ld	a1,-40(s0)
    8000602a:	0591                	addi	a1,a1,4
    8000602c:	73c8                	ld	a0,160(a5)
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	654080e7          	jalr	1620(ra) # 80001682 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006036:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006038:	06055763          	bgez	a0,800060a6 <sys_pipe+0x110>
    p->ofile[fd0] = 0;
    8000603c:	fc442783          	lw	a5,-60(s0)
    80006040:	22478793          	addi	a5,a5,548 # 1224 <_entry-0x7fffeddc>
    80006044:	078e                	slli	a5,a5,0x3
    80006046:	97a6                	add	a5,a5,s1
    80006048:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000604c:	fc042503          	lw	a0,-64(s0)
    80006050:	22450513          	addi	a0,a0,548 # 1224 <_entry-0x7fffeddc>
    80006054:	050e                	slli	a0,a0,0x3
    80006056:	9526                	add	a0,a0,s1
    80006058:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000605c:	fd043503          	ld	a0,-48(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	9c8080e7          	jalr	-1592(ra) # 80004a28 <fileclose>
    fileclose(wf);
    80006068:	fc843503          	ld	a0,-56(s0)
    8000606c:	fffff097          	auipc	ra,0xfffff
    80006070:	9bc080e7          	jalr	-1604(ra) # 80004a28 <fileclose>
    return -1;
    80006074:	57fd                	li	a5,-1
    80006076:	a805                	j	800060a6 <sys_pipe+0x110>
    if(fd0 >= 0)
    80006078:	fc442783          	lw	a5,-60(s0)
    8000607c:	0007c863          	bltz	a5,8000608c <sys_pipe+0xf6>
      p->ofile[fd0] = 0;
    80006080:	22478513          	addi	a0,a5,548
    80006084:	050e                	slli	a0,a0,0x3
    80006086:	9526                	add	a0,a0,s1
    80006088:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000608c:	fd043503          	ld	a0,-48(s0)
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	998080e7          	jalr	-1640(ra) # 80004a28 <fileclose>
    fileclose(wf);
    80006098:	fc843503          	ld	a0,-56(s0)
    8000609c:	fffff097          	auipc	ra,0xfffff
    800060a0:	98c080e7          	jalr	-1652(ra) # 80004a28 <fileclose>
    return -1;
    800060a4:	57fd                	li	a5,-1
}
    800060a6:	853e                	mv	a0,a5
    800060a8:	70e2                	ld	ra,56(sp)
    800060aa:	7442                	ld	s0,48(sp)
    800060ac:	74a2                	ld	s1,40(sp)
    800060ae:	6121                	addi	sp,sp,64
    800060b0:	8082                	ret
	...

00000000800060c0 <kernelvec>:
    800060c0:	7111                	addi	sp,sp,-256
    800060c2:	e006                	sd	ra,0(sp)
    800060c4:	e40a                	sd	sp,8(sp)
    800060c6:	e80e                	sd	gp,16(sp)
    800060c8:	ec12                	sd	tp,24(sp)
    800060ca:	f016                	sd	t0,32(sp)
    800060cc:	f41a                	sd	t1,40(sp)
    800060ce:	f81e                	sd	t2,48(sp)
    800060d0:	fc22                	sd	s0,56(sp)
    800060d2:	e0a6                	sd	s1,64(sp)
    800060d4:	e4aa                	sd	a0,72(sp)
    800060d6:	e8ae                	sd	a1,80(sp)
    800060d8:	ecb2                	sd	a2,88(sp)
    800060da:	f0b6                	sd	a3,96(sp)
    800060dc:	f4ba                	sd	a4,104(sp)
    800060de:	f8be                	sd	a5,112(sp)
    800060e0:	fcc2                	sd	a6,120(sp)
    800060e2:	e146                	sd	a7,128(sp)
    800060e4:	e54a                	sd	s2,136(sp)
    800060e6:	e94e                	sd	s3,144(sp)
    800060e8:	ed52                	sd	s4,152(sp)
    800060ea:	f156                	sd	s5,160(sp)
    800060ec:	f55a                	sd	s6,168(sp)
    800060ee:	f95e                	sd	s7,176(sp)
    800060f0:	fd62                	sd	s8,184(sp)
    800060f2:	e1e6                	sd	s9,192(sp)
    800060f4:	e5ea                	sd	s10,200(sp)
    800060f6:	e9ee                	sd	s11,208(sp)
    800060f8:	edf2                	sd	t3,216(sp)
    800060fa:	f1f6                	sd	t4,224(sp)
    800060fc:	f5fa                	sd	t5,232(sp)
    800060fe:	f9fe                	sd	t6,240(sp)
    80006100:	987fc0ef          	jal	ra,80002a86 <kerneltrap>
    80006104:	6082                	ld	ra,0(sp)
    80006106:	6122                	ld	sp,8(sp)
    80006108:	61c2                	ld	gp,16(sp)
    8000610a:	7282                	ld	t0,32(sp)
    8000610c:	7322                	ld	t1,40(sp)
    8000610e:	73c2                	ld	t2,48(sp)
    80006110:	7462                	ld	s0,56(sp)
    80006112:	6486                	ld	s1,64(sp)
    80006114:	6526                	ld	a0,72(sp)
    80006116:	65c6                	ld	a1,80(sp)
    80006118:	6666                	ld	a2,88(sp)
    8000611a:	7686                	ld	a3,96(sp)
    8000611c:	7726                	ld	a4,104(sp)
    8000611e:	77c6                	ld	a5,112(sp)
    80006120:	7866                	ld	a6,120(sp)
    80006122:	688a                	ld	a7,128(sp)
    80006124:	692a                	ld	s2,136(sp)
    80006126:	69ca                	ld	s3,144(sp)
    80006128:	6a6a                	ld	s4,152(sp)
    8000612a:	7a8a                	ld	s5,160(sp)
    8000612c:	7b2a                	ld	s6,168(sp)
    8000612e:	7bca                	ld	s7,176(sp)
    80006130:	7c6a                	ld	s8,184(sp)
    80006132:	6c8e                	ld	s9,192(sp)
    80006134:	6d2e                	ld	s10,200(sp)
    80006136:	6dce                	ld	s11,208(sp)
    80006138:	6e6e                	ld	t3,216(sp)
    8000613a:	7e8e                	ld	t4,224(sp)
    8000613c:	7f2e                	ld	t5,232(sp)
    8000613e:	7fce                	ld	t6,240(sp)
    80006140:	6111                	addi	sp,sp,256
    80006142:	10200073          	sret
    80006146:	00000013          	nop
    8000614a:	00000013          	nop
    8000614e:	0001                	nop

0000000080006150 <timervec>:
    80006150:	34051573          	csrrw	a0,mscratch,a0
    80006154:	e10c                	sd	a1,0(a0)
    80006156:	e510                	sd	a2,8(a0)
    80006158:	e914                	sd	a3,16(a0)
    8000615a:	6d0c                	ld	a1,24(a0)
    8000615c:	7110                	ld	a2,32(a0)
    8000615e:	6194                	ld	a3,0(a1)
    80006160:	96b2                	add	a3,a3,a2
    80006162:	e194                	sd	a3,0(a1)
    80006164:	4589                	li	a1,2
    80006166:	14459073          	csrw	sip,a1
    8000616a:	6914                	ld	a3,16(a0)
    8000616c:	6510                	ld	a2,8(a0)
    8000616e:	610c                	ld	a1,0(a0)
    80006170:	34051573          	csrrw	a0,mscratch,a0
    80006174:	30200073          	mret
	...

000000008000617a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000617a:	1141                	addi	sp,sp,-16
    8000617c:	e422                	sd	s0,8(sp)
    8000617e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006180:	0c0007b7          	lui	a5,0xc000
    80006184:	4705                	li	a4,1
    80006186:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006188:	c3d8                	sw	a4,4(a5)
}
    8000618a:	6422                	ld	s0,8(sp)
    8000618c:	0141                	addi	sp,sp,16
    8000618e:	8082                	ret

0000000080006190 <plicinithart>:

void
plicinithart(void)
{
    80006190:	1141                	addi	sp,sp,-16
    80006192:	e406                	sd	ra,8(sp)
    80006194:	e022                	sd	s0,0(sp)
    80006196:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	84a080e7          	jalr	-1974(ra) # 800019e2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061a0:	0085171b          	slliw	a4,a0,0x8
    800061a4:	0c0027b7          	lui	a5,0xc002
    800061a8:	97ba                	add	a5,a5,a4
    800061aa:	40200713          	li	a4,1026
    800061ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061b2:	00d5151b          	slliw	a0,a0,0xd
    800061b6:	0c2017b7          	lui	a5,0xc201
    800061ba:	953e                	add	a0,a0,a5
    800061bc:	00052023          	sw	zero,0(a0)
}
    800061c0:	60a2                	ld	ra,8(sp)
    800061c2:	6402                	ld	s0,0(sp)
    800061c4:	0141                	addi	sp,sp,16
    800061c6:	8082                	ret

00000000800061c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061c8:	1141                	addi	sp,sp,-16
    800061ca:	e406                	sd	ra,8(sp)
    800061cc:	e022                	sd	s0,0(sp)
    800061ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061d0:	ffffc097          	auipc	ra,0xffffc
    800061d4:	812080e7          	jalr	-2030(ra) # 800019e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061d8:	00d5179b          	slliw	a5,a0,0xd
    800061dc:	0c201537          	lui	a0,0xc201
    800061e0:	953e                	add	a0,a0,a5
  return irq;
}
    800061e2:	4148                	lw	a0,4(a0)
    800061e4:	60a2                	ld	ra,8(sp)
    800061e6:	6402                	ld	s0,0(sp)
    800061e8:	0141                	addi	sp,sp,16
    800061ea:	8082                	ret

00000000800061ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061ec:	1101                	addi	sp,sp,-32
    800061ee:	ec06                	sd	ra,24(sp)
    800061f0:	e822                	sd	s0,16(sp)
    800061f2:	e426                	sd	s1,8(sp)
    800061f4:	1000                	addi	s0,sp,32
    800061f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061f8:	ffffb097          	auipc	ra,0xffffb
    800061fc:	7ea080e7          	jalr	2026(ra) # 800019e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006200:	00d5151b          	slliw	a0,a0,0xd
    80006204:	0c2017b7          	lui	a5,0xc201
    80006208:	97aa                	add	a5,a5,a0
    8000620a:	c3c4                	sw	s1,4(a5)
}
    8000620c:	60e2                	ld	ra,24(sp)
    8000620e:	6442                	ld	s0,16(sp)
    80006210:	64a2                	ld	s1,8(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret

0000000080006216 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006216:	1141                	addi	sp,sp,-16
    80006218:	e406                	sd	ra,8(sp)
    8000621a:	e022                	sd	s0,0(sp)
    8000621c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000621e:	479d                	li	a5,7
    80006220:	06a7c963          	blt	a5,a0,80006292 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006224:	0005e797          	auipc	a5,0x5e
    80006228:	ddc78793          	addi	a5,a5,-548 # 80064000 <disk>
    8000622c:	00a78733          	add	a4,a5,a0
    80006230:	6789                	lui	a5,0x2
    80006232:	97ba                	add	a5,a5,a4
    80006234:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006238:	e7ad                	bnez	a5,800062a2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000623a:	00451793          	slli	a5,a0,0x4
    8000623e:	00060717          	auipc	a4,0x60
    80006242:	dc270713          	addi	a4,a4,-574 # 80066000 <disk+0x2000>
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000624e:	6314                	ld	a3,0(a4)
    80006250:	96be                	add	a3,a3,a5
    80006252:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006256:	6314                	ld	a3,0(a4)
    80006258:	96be                	add	a3,a3,a5
    8000625a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000625e:	6318                	ld	a4,0(a4)
    80006260:	97ba                	add	a5,a5,a4
    80006262:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006266:	0005e797          	auipc	a5,0x5e
    8000626a:	d9a78793          	addi	a5,a5,-614 # 80064000 <disk>
    8000626e:	97aa                	add	a5,a5,a0
    80006270:	6509                	lui	a0,0x2
    80006272:	953e                	add	a0,a0,a5
    80006274:	4785                	li	a5,1
    80006276:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000627a:	00060517          	auipc	a0,0x60
    8000627e:	d9e50513          	addi	a0,a0,-610 # 80066018 <disk+0x2018>
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	1b2080e7          	jalr	434(ra) # 80002434 <wakeup>
}
    8000628a:	60a2                	ld	ra,8(sp)
    8000628c:	6402                	ld	s0,0(sp)
    8000628e:	0141                	addi	sp,sp,16
    80006290:	8082                	ret
    panic("free_desc 1");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	4d650513          	addi	a0,a0,1238 # 80008768 <syscalls+0x348>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2b0080e7          	jalr	688(ra) # 8000054a <panic>
    panic("free_desc 2");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	4d650513          	addi	a0,a0,1238 # 80008778 <syscalls+0x358>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	2a0080e7          	jalr	672(ra) # 8000054a <panic>

00000000800062b2 <virtio_disk_init>:
{
    800062b2:	1101                	addi	sp,sp,-32
    800062b4:	ec06                	sd	ra,24(sp)
    800062b6:	e822                	sd	s0,16(sp)
    800062b8:	e426                	sd	s1,8(sp)
    800062ba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062bc:	00002597          	auipc	a1,0x2
    800062c0:	4cc58593          	addi	a1,a1,1228 # 80008788 <syscalls+0x368>
    800062c4:	00060517          	auipc	a0,0x60
    800062c8:	e6450513          	addi	a0,a0,-412 # 80066128 <disk+0x2128>
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	8aa080e7          	jalr	-1878(ra) # 80000b76 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062d4:	100017b7          	lui	a5,0x10001
    800062d8:	4398                	lw	a4,0(a5)
    800062da:	2701                	sext.w	a4,a4
    800062dc:	747277b7          	lui	a5,0x74727
    800062e0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062e4:	0ef71163          	bne	a4,a5,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062e8:	100017b7          	lui	a5,0x10001
    800062ec:	43dc                	lw	a5,4(a5)
    800062ee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062f0:	4705                	li	a4,1
    800062f2:	0ce79a63          	bne	a5,a4,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062f6:	100017b7          	lui	a5,0x10001
    800062fa:	479c                	lw	a5,8(a5)
    800062fc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062fe:	4709                	li	a4,2
    80006300:	0ce79363          	bne	a5,a4,800063c6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006304:	100017b7          	lui	a5,0x10001
    80006308:	47d8                	lw	a4,12(a5)
    8000630a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000630c:	554d47b7          	lui	a5,0x554d4
    80006310:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006314:	0af71963          	bne	a4,a5,800063c6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006318:	100017b7          	lui	a5,0x10001
    8000631c:	4705                	li	a4,1
    8000631e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006320:	470d                	li	a4,3
    80006322:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006324:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006326:	c7ffe737          	lui	a4,0xc7ffe
    8000632a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f9775f>
    8000632e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006330:	2701                	sext.w	a4,a4
    80006332:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006334:	472d                	li	a4,11
    80006336:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006338:	473d                	li	a4,15
    8000633a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000633c:	6705                	lui	a4,0x1
    8000633e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006340:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006344:	5bdc                	lw	a5,52(a5)
    80006346:	2781                	sext.w	a5,a5
  if(max == 0)
    80006348:	c7d9                	beqz	a5,800063d6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000634a:	471d                	li	a4,7
    8000634c:	08f77d63          	bgeu	a4,a5,800063e6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006350:	100014b7          	lui	s1,0x10001
    80006354:	47a1                	li	a5,8
    80006356:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006358:	6609                	lui	a2,0x2
    8000635a:	4581                	li	a1,0
    8000635c:	0005e517          	auipc	a0,0x5e
    80006360:	ca450513          	addi	a0,a0,-860 # 80064000 <disk>
    80006364:	ffffb097          	auipc	ra,0xffffb
    80006368:	99e080e7          	jalr	-1634(ra) # 80000d02 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000636c:	0005e717          	auipc	a4,0x5e
    80006370:	c9470713          	addi	a4,a4,-876 # 80064000 <disk>
    80006374:	00c75793          	srli	a5,a4,0xc
    80006378:	2781                	sext.w	a5,a5
    8000637a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000637c:	00060797          	auipc	a5,0x60
    80006380:	c8478793          	addi	a5,a5,-892 # 80066000 <disk+0x2000>
    80006384:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006386:	0005e717          	auipc	a4,0x5e
    8000638a:	cfa70713          	addi	a4,a4,-774 # 80064080 <disk+0x80>
    8000638e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006390:	0005f717          	auipc	a4,0x5f
    80006394:	c7070713          	addi	a4,a4,-912 # 80065000 <disk+0x1000>
    80006398:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000639a:	4705                	li	a4,1
    8000639c:	00e78c23          	sb	a4,24(a5)
    800063a0:	00e78ca3          	sb	a4,25(a5)
    800063a4:	00e78d23          	sb	a4,26(a5)
    800063a8:	00e78da3          	sb	a4,27(a5)
    800063ac:	00e78e23          	sb	a4,28(a5)
    800063b0:	00e78ea3          	sb	a4,29(a5)
    800063b4:	00e78f23          	sb	a4,30(a5)
    800063b8:	00e78fa3          	sb	a4,31(a5)
}
    800063bc:	60e2                	ld	ra,24(sp)
    800063be:	6442                	ld	s0,16(sp)
    800063c0:	64a2                	ld	s1,8(sp)
    800063c2:	6105                	addi	sp,sp,32
    800063c4:	8082                	ret
    panic("could not find virtio disk");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	3d250513          	addi	a0,a0,978 # 80008798 <syscalls+0x378>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	17c080e7          	jalr	380(ra) # 8000054a <panic>
    panic("virtio disk has no queue 0");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	3e250513          	addi	a0,a0,994 # 800087b8 <syscalls+0x398>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	16c080e7          	jalr	364(ra) # 8000054a <panic>
    panic("virtio disk max queue too short");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	3f250513          	addi	a0,a0,1010 # 800087d8 <syscalls+0x3b8>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	15c080e7          	jalr	348(ra) # 8000054a <panic>

00000000800063f6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063f6:	7119                	addi	sp,sp,-128
    800063f8:	fc86                	sd	ra,120(sp)
    800063fa:	f8a2                	sd	s0,112(sp)
    800063fc:	f4a6                	sd	s1,104(sp)
    800063fe:	f0ca                	sd	s2,96(sp)
    80006400:	ecce                	sd	s3,88(sp)
    80006402:	e8d2                	sd	s4,80(sp)
    80006404:	e4d6                	sd	s5,72(sp)
    80006406:	e0da                	sd	s6,64(sp)
    80006408:	fc5e                	sd	s7,56(sp)
    8000640a:	f862                	sd	s8,48(sp)
    8000640c:	f466                	sd	s9,40(sp)
    8000640e:	f06a                	sd	s10,32(sp)
    80006410:	ec6e                	sd	s11,24(sp)
    80006412:	0100                	addi	s0,sp,128
    80006414:	8aaa                	mv	s5,a0
    80006416:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006418:	00c52c83          	lw	s9,12(a0)
    8000641c:	001c9c9b          	slliw	s9,s9,0x1
    80006420:	1c82                	slli	s9,s9,0x20
    80006422:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006426:	00060517          	auipc	a0,0x60
    8000642a:	d0250513          	addi	a0,a0,-766 # 80066128 <disk+0x2128>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	7d8080e7          	jalr	2008(ra) # 80000c06 <acquire>
  for(int i = 0; i < 3; i++){
    80006436:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006438:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000643a:	0005ec17          	auipc	s8,0x5e
    8000643e:	bc6c0c13          	addi	s8,s8,-1082 # 80064000 <disk>
    80006442:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006444:	4b0d                	li	s6,3
    80006446:	a0ad                	j	800064b0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006448:	00fc0733          	add	a4,s8,a5
    8000644c:	975e                	add	a4,a4,s7
    8000644e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006452:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006454:	0207c563          	bltz	a5,8000647e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006458:	2905                	addiw	s2,s2,1
    8000645a:	0611                	addi	a2,a2,4
    8000645c:	19690d63          	beq	s2,s6,800065f6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006460:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006462:	00060717          	auipc	a4,0x60
    80006466:	bb670713          	addi	a4,a4,-1098 # 80066018 <disk+0x2018>
    8000646a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000646c:	00074683          	lbu	a3,0(a4)
    80006470:	fee1                	bnez	a3,80006448 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006472:	2785                	addiw	a5,a5,1
    80006474:	0705                	addi	a4,a4,1
    80006476:	fe979be3          	bne	a5,s1,8000646c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000647a:	57fd                	li	a5,-1
    8000647c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000647e:	01205d63          	blez	s2,80006498 <virtio_disk_rw+0xa2>
    80006482:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006484:	000a2503          	lw	a0,0(s4)
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	d8e080e7          	jalr	-626(ra) # 80006216 <free_desc>
      for(int j = 0; j < i; j++)
    80006490:	2d85                	addiw	s11,s11,1
    80006492:	0a11                	addi	s4,s4,4
    80006494:	ffb918e3          	bne	s2,s11,80006484 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006498:	00060597          	auipc	a1,0x60
    8000649c:	c9058593          	addi	a1,a1,-880 # 80066128 <disk+0x2128>
    800064a0:	00060517          	auipc	a0,0x60
    800064a4:	b7850513          	addi	a0,a0,-1160 # 80066018 <disk+0x2018>
    800064a8:	ffffc097          	auipc	ra,0xffffc
    800064ac:	e08080e7          	jalr	-504(ra) # 800022b0 <sleep>
  for(int i = 0; i < 3; i++){
    800064b0:	f8040a13          	addi	s4,s0,-128
{
    800064b4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800064b6:	894e                	mv	s2,s3
    800064b8:	b765                	j	80006460 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800064ba:	00060697          	auipc	a3,0x60
    800064be:	b466b683          	ld	a3,-1210(a3) # 80066000 <disk+0x2000>
    800064c2:	96ba                	add	a3,a3,a4
    800064c4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064c8:	0005e817          	auipc	a6,0x5e
    800064cc:	b3880813          	addi	a6,a6,-1224 # 80064000 <disk>
    800064d0:	00060697          	auipc	a3,0x60
    800064d4:	b3068693          	addi	a3,a3,-1232 # 80066000 <disk+0x2000>
    800064d8:	6290                	ld	a2,0(a3)
    800064da:	963a                	add	a2,a2,a4
    800064dc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800064e0:	0015e593          	ori	a1,a1,1
    800064e4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800064e8:	f8842603          	lw	a2,-120(s0)
    800064ec:	628c                	ld	a1,0(a3)
    800064ee:	972e                	add	a4,a4,a1
    800064f0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064f4:	20050593          	addi	a1,a0,512
    800064f8:	0592                	slli	a1,a1,0x4
    800064fa:	95c2                	add	a1,a1,a6
    800064fc:	577d                	li	a4,-1
    800064fe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006502:	00461713          	slli	a4,a2,0x4
    80006506:	6290                	ld	a2,0(a3)
    80006508:	963a                	add	a2,a2,a4
    8000650a:	03078793          	addi	a5,a5,48
    8000650e:	97c2                	add	a5,a5,a6
    80006510:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006512:	629c                	ld	a5,0(a3)
    80006514:	97ba                	add	a5,a5,a4
    80006516:	4605                	li	a2,1
    80006518:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000651a:	629c                	ld	a5,0(a3)
    8000651c:	97ba                	add	a5,a5,a4
    8000651e:	4809                	li	a6,2
    80006520:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006524:	629c                	ld	a5,0(a3)
    80006526:	973e                	add	a4,a4,a5
    80006528:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000652c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006530:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006534:	6698                	ld	a4,8(a3)
    80006536:	00275783          	lhu	a5,2(a4)
    8000653a:	8b9d                	andi	a5,a5,7
    8000653c:	0786                	slli	a5,a5,0x1
    8000653e:	97ba                	add	a5,a5,a4
    80006540:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006544:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006548:	6698                	ld	a4,8(a3)
    8000654a:	00275783          	lhu	a5,2(a4)
    8000654e:	2785                	addiw	a5,a5,1
    80006550:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006554:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006558:	100017b7          	lui	a5,0x10001
    8000655c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006560:	004aa783          	lw	a5,4(s5)
    80006564:	02c79163          	bne	a5,a2,80006586 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006568:	00060917          	auipc	s2,0x60
    8000656c:	bc090913          	addi	s2,s2,-1088 # 80066128 <disk+0x2128>
  while(b->disk == 1) {
    80006570:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006572:	85ca                	mv	a1,s2
    80006574:	8556                	mv	a0,s5
    80006576:	ffffc097          	auipc	ra,0xffffc
    8000657a:	d3a080e7          	jalr	-710(ra) # 800022b0 <sleep>
  while(b->disk == 1) {
    8000657e:	004aa783          	lw	a5,4(s5)
    80006582:	fe9788e3          	beq	a5,s1,80006572 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006586:	f8042903          	lw	s2,-128(s0)
    8000658a:	20090793          	addi	a5,s2,512
    8000658e:	00479713          	slli	a4,a5,0x4
    80006592:	0005e797          	auipc	a5,0x5e
    80006596:	a6e78793          	addi	a5,a5,-1426 # 80064000 <disk>
    8000659a:	97ba                	add	a5,a5,a4
    8000659c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800065a0:	00060997          	auipc	s3,0x60
    800065a4:	a6098993          	addi	s3,s3,-1440 # 80066000 <disk+0x2000>
    800065a8:	00491713          	slli	a4,s2,0x4
    800065ac:	0009b783          	ld	a5,0(s3)
    800065b0:	97ba                	add	a5,a5,a4
    800065b2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065b6:	854a                	mv	a0,s2
    800065b8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065bc:	00000097          	auipc	ra,0x0
    800065c0:	c5a080e7          	jalr	-934(ra) # 80006216 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065c4:	8885                	andi	s1,s1,1
    800065c6:	f0ed                	bnez	s1,800065a8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065c8:	00060517          	auipc	a0,0x60
    800065cc:	b6050513          	addi	a0,a0,-1184 # 80066128 <disk+0x2128>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	6ea080e7          	jalr	1770(ra) # 80000cba <release>
}
    800065d8:	70e6                	ld	ra,120(sp)
    800065da:	7446                	ld	s0,112(sp)
    800065dc:	74a6                	ld	s1,104(sp)
    800065de:	7906                	ld	s2,96(sp)
    800065e0:	69e6                	ld	s3,88(sp)
    800065e2:	6a46                	ld	s4,80(sp)
    800065e4:	6aa6                	ld	s5,72(sp)
    800065e6:	6b06                	ld	s6,64(sp)
    800065e8:	7be2                	ld	s7,56(sp)
    800065ea:	7c42                	ld	s8,48(sp)
    800065ec:	7ca2                	ld	s9,40(sp)
    800065ee:	7d02                	ld	s10,32(sp)
    800065f0:	6de2                	ld	s11,24(sp)
    800065f2:	6109                	addi	sp,sp,128
    800065f4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065f6:	f8042503          	lw	a0,-128(s0)
    800065fa:	20050793          	addi	a5,a0,512
    800065fe:	0792                	slli	a5,a5,0x4
  if(write)
    80006600:	0005e817          	auipc	a6,0x5e
    80006604:	a0080813          	addi	a6,a6,-1536 # 80064000 <disk>
    80006608:	00f80733          	add	a4,a6,a5
    8000660c:	01a036b3          	snez	a3,s10
    80006610:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006614:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006618:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000661c:	7679                	lui	a2,0xffffe
    8000661e:	963e                	add	a2,a2,a5
    80006620:	00060697          	auipc	a3,0x60
    80006624:	9e068693          	addi	a3,a3,-1568 # 80066000 <disk+0x2000>
    80006628:	6298                	ld	a4,0(a3)
    8000662a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000662c:	0a878593          	addi	a1,a5,168
    80006630:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006632:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006634:	6298                	ld	a4,0(a3)
    80006636:	9732                	add	a4,a4,a2
    80006638:	45c1                	li	a1,16
    8000663a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000663c:	6298                	ld	a4,0(a3)
    8000663e:	9732                	add	a4,a4,a2
    80006640:	4585                	li	a1,1
    80006642:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006646:	f8442703          	lw	a4,-124(s0)
    8000664a:	628c                	ld	a1,0(a3)
    8000664c:	962e                	add	a2,a2,a1
    8000664e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ff9700e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006652:	0712                	slli	a4,a4,0x4
    80006654:	6290                	ld	a2,0(a3)
    80006656:	963a                	add	a2,a2,a4
    80006658:	058a8593          	addi	a1,s5,88
    8000665c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000665e:	6294                	ld	a3,0(a3)
    80006660:	96ba                	add	a3,a3,a4
    80006662:	40000613          	li	a2,1024
    80006666:	c690                	sw	a2,8(a3)
  if(write)
    80006668:	e40d19e3          	bnez	s10,800064ba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000666c:	00060697          	auipc	a3,0x60
    80006670:	9946b683          	ld	a3,-1644(a3) # 80066000 <disk+0x2000>
    80006674:	96ba                	add	a3,a3,a4
    80006676:	4609                	li	a2,2
    80006678:	00c69623          	sh	a2,12(a3)
    8000667c:	b5b1                	j	800064c8 <virtio_disk_rw+0xd2>

000000008000667e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000667e:	1101                	addi	sp,sp,-32
    80006680:	ec06                	sd	ra,24(sp)
    80006682:	e822                	sd	s0,16(sp)
    80006684:	e426                	sd	s1,8(sp)
    80006686:	e04a                	sd	s2,0(sp)
    80006688:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000668a:	00060517          	auipc	a0,0x60
    8000668e:	a9e50513          	addi	a0,a0,-1378 # 80066128 <disk+0x2128>
    80006692:	ffffa097          	auipc	ra,0xffffa
    80006696:	574080e7          	jalr	1396(ra) # 80000c06 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000669a:	10001737          	lui	a4,0x10001
    8000669e:	533c                	lw	a5,96(a4)
    800066a0:	8b8d                	andi	a5,a5,3
    800066a2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066a4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066a8:	00060797          	auipc	a5,0x60
    800066ac:	95878793          	addi	a5,a5,-1704 # 80066000 <disk+0x2000>
    800066b0:	6b94                	ld	a3,16(a5)
    800066b2:	0207d703          	lhu	a4,32(a5)
    800066b6:	0026d783          	lhu	a5,2(a3)
    800066ba:	06f70163          	beq	a4,a5,8000671c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066be:	0005e917          	auipc	s2,0x5e
    800066c2:	94290913          	addi	s2,s2,-1726 # 80064000 <disk>
    800066c6:	00060497          	auipc	s1,0x60
    800066ca:	93a48493          	addi	s1,s1,-1734 # 80066000 <disk+0x2000>
    __sync_synchronize();
    800066ce:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066d2:	6898                	ld	a4,16(s1)
    800066d4:	0204d783          	lhu	a5,32(s1)
    800066d8:	8b9d                	andi	a5,a5,7
    800066da:	078e                	slli	a5,a5,0x3
    800066dc:	97ba                	add	a5,a5,a4
    800066de:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800066e0:	20078713          	addi	a4,a5,512
    800066e4:	0712                	slli	a4,a4,0x4
    800066e6:	974a                	add	a4,a4,s2
    800066e8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800066ec:	e731                	bnez	a4,80006738 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800066ee:	20078793          	addi	a5,a5,512
    800066f2:	0792                	slli	a5,a5,0x4
    800066f4:	97ca                	add	a5,a5,s2
    800066f6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800066f8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800066fc:	ffffc097          	auipc	ra,0xffffc
    80006700:	d38080e7          	jalr	-712(ra) # 80002434 <wakeup>

    disk.used_idx += 1;
    80006704:	0204d783          	lhu	a5,32(s1)
    80006708:	2785                	addiw	a5,a5,1
    8000670a:	17c2                	slli	a5,a5,0x30
    8000670c:	93c1                	srli	a5,a5,0x30
    8000670e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006712:	6898                	ld	a4,16(s1)
    80006714:	00275703          	lhu	a4,2(a4)
    80006718:	faf71be3          	bne	a4,a5,800066ce <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000671c:	00060517          	auipc	a0,0x60
    80006720:	a0c50513          	addi	a0,a0,-1524 # 80066128 <disk+0x2128>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	596080e7          	jalr	1430(ra) # 80000cba <release>
}
    8000672c:	60e2                	ld	ra,24(sp)
    8000672e:	6442                	ld	s0,16(sp)
    80006730:	64a2                	ld	s1,8(sp)
    80006732:	6902                	ld	s2,0(sp)
    80006734:	6105                	addi	sp,sp,32
    80006736:	8082                	ret
      panic("virtio_disk_intr status");
    80006738:	00002517          	auipc	a0,0x2
    8000673c:	0c050513          	addi	a0,a0,192 # 800087f8 <syscalls+0x3d8>
    80006740:	ffffa097          	auipc	ra,0xffffa
    80006744:	e0a080e7          	jalr	-502(ra) # 8000054a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
