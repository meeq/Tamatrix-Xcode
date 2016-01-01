/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tamaemu.h"
#include "i2c.h"
#include "ir.h"

int PAGECT=20;

#define BUTTONRELEASETIME FCPU/15;

#define REG(x) t->ioreg[(x)-0x3000]

static void tamaDumpBin(int val, int bits) {
	int x;
	for (x=bits-1; x>=0; --x) {
		printf("%d", (val&(1<<x))?1:0);
	}
}


void tamaDumpHw(M6502 *cpu) {
	const char *intfdesc[]={"FP", "SPI", "SPU", "FOSC/8K", "FOSC/2K", "x", "x", "TM0", 
			"EX", "x", "TBL", "TBH", "x", "TM1", "x", "x"};
	const char *nmidesc[]={"LV", "TM1", "x", "x", "x", "x", "x", "NMIEN"};
	const char *tbldiv[]={"2HZ", "8HZ", "4HZ", "16HZ"};
	const char *tbhdiv[]={"128HZ", "512HZ", "256HZ", "1KHZ"};
	const char *t0diva[]={"VSS", "Rosc", "32KHz", "ECLK", "VDD", "x", "x", "x"};
	const char *t0divb[]={"VDD", "TBL", "TBH", "EXTI", "2HZ", "8HZ", "32HZ", "64HZ"};
	const char *t1div[]={"VSS", "Rosc", "32KHz", "TIMER0"};
	const char *ccdiv[]={"/2", "/4", "/8", "/16", "/32", "/64", "/128", "OFF"};
	Tamagotchi *t=(Tamagotchi *)cpu->User;
	TamaHw *hw=&t->hw;
	TamaClk *clk=&t->clk;
	int i;
	int ien=t->ioreg[0x70]+(t->ioreg[0x71]<<8);
	printf("Ints enabled: (0x%X)", ien);
	for (i=0; i<16; i++) {
		if (ien&(1<<i)) printf("%s ", intfdesc[i]);
	}
	printf("\nInt flags: ");
	for (i=0; i<16; i++) {
		if (hw->iflags&(1<<i)) printf("%s ", intfdesc[i]);
	}
	printf("\nLast active int: ");
	for (i=0; i<16; i++) {
		if (hw->lastInt&(1<<i)) printf("%s ", intfdesc[i]);
	}
	printf("\nNMI ena:");
	for (i=0; i<8; i++) {
		if (REG(R_NMICTL)&(1<<i)) printf("%s ", nmidesc[i]);
	}
	printf("\n");
	printf("Timebase: tbl: %s, ", tbldiv[((REG(R_TIMBASE)>>2)&3)]);
	printf("tbh %s, ", tbhdiv[((REG(R_TIMBASE)>>0)&3)]);
	printf("t0A %s, ", t0diva[((REG(R_TIMCTL)>>5)&7)]);
	printf("t0B %s, ", t0divb[((REG(R_TIMCTL)>>2)&7)]);
	printf("T1 %s, ", t1div[((REG(R_TIMCTL)>>0)&3)]);
	printf("CPU %s\n", ccdiv[REG(R_CLKCTL)&7]);
	printf("Prescalers: tbl: %07d/%07d, tbh: %05d/%05d, c8k: %04d, c2k %04d, t0: %04d/%04d, t1: %04d/%04d, cpu: %04d/%04d\n",
		clk->tblCtr, clk->tblDiv, clk->tbhCtr, clk->tbhDiv, clk->c8kCtr, clk->c2kCtr, clk->t0Ctr, clk->t0Div, clk->t1Ctr, clk->t1Div, clk->cpuCtr, clk->cpuDiv);
	printf("Btn port reads since last press: %d\n", t->btnReads);
	printf("Current bank: %d\n", hw->bankSel);
	printf("Output bits: A:");
	tamaDumpBin(hw->portAout, 8);
	printf(" B:");
	tamaDumpBin(hw->portBout, 8);
	printf(" C:");
	tamaDumpBin(hw->portCout, 8);
	printf("\n");
}

unsigned char **loadRoms(const char *dir) {
	char fname[1024];
	unsigned char **roms;
	int i;
//	int l;
	int noLoaded=0;
	FILE *f;
	long len;
	roms=malloc(sizeof(char*)*PAGECT);
	for (i=0; i<PAGECT; i++) {
		sprintf(fname, "%s/p%d.bin", dir, i);
		f=fopen(fname, "rb");
		if (f==NULL) {
			sprintf(fname, "%s/p%d", dir, i);
			f=fopen(fname, "rb");
			if (f==NULL) {
				perror(fname);
				//Newer Tamas have empty pages. Don't crap out if one is missing.
//				exit(1);
			}
		}
		roms[i]=malloc(32*1024);
		if (f!=NULL) {
			fseek(f, 0, SEEK_END);
			len=ftell(f);
			if (len>32768) {
				//Probably a dump of the entire 6502 address space. Seek to the start of the page.
				fseek(f, 0x4000, SEEK_SET);
			} else {
				//Dump of only the page.
				fseek(f, 0, SEEK_SET);
			}
			fread(roms[i], 1, 32768, f);
//			l=fread(roms[i], 1, 32768, f);
//			printf("ROM loaded: %s - %d bytes\n", fname, l);
//			printf("%x %x\n", roms[i][0x3ffc], roms[i][0x3ffd]);
			fclose(f);
			noLoaded++;
		}
	}
	if (noLoaded<2) {
		printf("Couldn't load ROM pages! Bailing out.\n");
		exit(1);
	}
	return roms;
}

void freeRoms(unsigned char **roms) {
	int i;
	for (i=0; i<PAGECT; i++) {
		free(roms[i]);
	}
	free(roms);
}

void tamaClkRecalc(Tamagotchi *t) {
//	TamaHw *hw=&t->hw;
	TamaClk *clk=&t->clk;
	const int tbldiv[]={FCPU/2, FCPU/8, FCPU/4, FCPU/16};
	const int tbhdiv[]={FCPU/128, FCPU/512, FCPU/256, FCPU/1000};
	const int t0diva[]={0, 1, FCPU/32767, 1, 0, 0, 0, 0};
	const int t0divb[]={0, 0, 0, 0, FCPU/2, FCPU/8, FCPU/32, FCPU/64};
//	const int t1div[]={0, 1, FCPU/32768, 0};
	const int t1div[]={0, 1, 1, 0}; //HACK! Real table seems to increase T1 too slowly.
	const int ccdiv[]={2, 4, 8, 16, 32, 64, 128, 0};

	clk->tblDiv=tbldiv[((REG(R_TIMBASE)>>2)&3)];
	clk->tbhDiv=tbhdiv[((REG(R_TIMBASE)>>0)&3)];
	clk->t0Div=t0diva[((REG(R_TIMCTL)>>5)&7)];
	if (clk->t0Div==0) {
		clk->t0Div=t0divb[((REG(R_TIMCTL)>>2)&7)];
	}
	clk->t1Div=t1div[((REG(R_TIMCTL)>>0)&3)];
	clk->cpuDiv=ccdiv[REG(R_CLKCTL)&7];
}


void tamaToggleBkunk(Tamagotchi *t) {
	t->bkUnk=!t->bkUnk;
}

//feed R_WAKEFL value
void tamaWakeSrc(Tamagotchi *t, int src) {
//	TamaHw *hw=&t->hw;
	TamaClk *clk=&t->clk;
	REG(R_WAKEFL)|=src;
	if (((REG(R_CLKCTL)&7)==7) && ((REG(R_WAKEEN))&src)!=0) {
		REG(R_CLKCTL)=(REG(R_CLKCTL)&0xf8)|2;
		clk->cpuDiv=8;
	}
}

void tamaToggleBtn(Tamagotchi *t, int btn) {
	TamaHw *hw=&t->hw;
	hw->portAdata^=(1<<(btn));
	tamaWakeSrc(t, (1<<0));
}

//0, 1, 2
void tamaPressBtn(Tamagotchi *t, int btn) {
	if (t->btnReleaseTm!=0) return;
	tamaToggleBtn(t, btn);
	t->btnPressed=btn;
	t->btnReleaseTm=BUTTONRELEASETIME;
	t->btnReads=0;
}

//1 - fully implemented
//2 - ToDo
//3 - SPU
static char implemented[]={
//	0 1 2 3 4 5 6 7 8 9 A B C D E F
	1,1,0,0,1,0,3,1,1,0,0,0,0,0,0,0, //00
	0,1,0,0,0,0,1,0,0,1,0,0,0,0,0,0, //10
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //20
	1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0, //30
	0,0,0,0,0,0,0,0,0,1,3,0,0,0,0,0, //40
	0,3,3,3,3,3,3,3,3,3,3,3,3,0,3,0, //50
	1,0,3,0,3,3,0,0,0,0,0,0,0,0,0,0, //60
	1,1,0,1,1,0,1,1,0,0,0,0,0,0,0,0, //70
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //80
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //90
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //A0
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //B0
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //C0
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //D0
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //E0
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //F0
	};


uint8_t ioRead(M6502 *cpu, register word addr) {
	Tamagotchi *t=(Tamagotchi *)cpu->User;
	TamaHw *hw=&t->hw;
	if (addr==R_PADATA) {
//		printf("PA: %X\n", hw->portAdata);
//		if (t->bkUnk) cpu->Trace=1;
		t->btnReads++;
		hw->portALastRead=hw->portAdata;
		return hw->portAdata;
	} else if (addr==R_PBDATA) {
		return hw->portBdata;
	} else if (addr==R_PCDATA) {
//		cpu->Trace=1;
		return hw->portCdata;
	} else if (addr==R_INTCTLLO) {
		return hw->iflags&0xff;
	} else if (addr==R_INTCTLMI) {
		return hw->iflags>>8;
	} else if (addr==R_NMICTL) {
		return (t->ioreg[R_NMICTL-0x3000]&0x80)|hw->nmiflags;
	} else if (addr==R_LVCTL) {
		return t->ioreg[R_LVCTL-0x3000]&0x83; //battery is always full
	} else if (addr==0x3055) {
		cpu->Trace=1;
		printf("eek unimplemented ioRd 0x%04X\n", addr);
	} else {
		if (!implemented[addr&0xff] && t->bkUnk) {
			if (!cpu->Trace) printf("Unimplemented ioRd 0x%04X\n", addr);
			cpu->Trace=1;
		}
		if (implemented[addr&0xff]==3) {
			if (!cpu->Trace) printf("Unimplemented ioRd 0x%04X\n", addr);
			cpu->Trace=1;
		}
		return t->ioreg[addr-0x3000];
	}
	return 0; //unimplemented
}

void ioWrite(M6502 *cpu, register word addr, register byte val) {
	Tamagotchi *t=(Tamagotchi *)cpu->User;
	TamaHw *hw=&t->hw;

	if (addr==R_BANK) {
		if (val>20) {
			printf("Unimplemented bank: 0x%02X\n", val);
		} else {
//			printf("Bank switch %d\n", val);
			hw->bankSel=val;
		}
	} else if (addr==R_PADATA) {
		//0 - Button 1
		//1 - Button 2
		//2 - Button 3
		//3 - LV detect
		hw->portAout=val;
		//4-7 - SPI for Tamago
	} else if (addr==R_PBDATA) {
		hw->portBout=val;
		//Port B:
		//0 - I2C SDA
		//1 - I2C SCL
		//2 - IR enable?
		//3 - IR LED
		//4-7 - SPI for Tamago
		irActive(val&0x8);
		hw->portBdata&=~1;
		if (i2cHandle(t->i2cbus, val&2, val&1) && (val&1)) hw->portBdata|=1;
	} else if (addr==R_PCDATA) {
		//Probably unused.
		hw->portCout=val;
	} else if (addr==R_INTCLRLO) {
		int msk=0xffff^(val);
		hw->iflags&=msk;
	} else if (addr==R_INTCLRMI) {
		int msk=0xffff^(val<<8);
		hw->iflags&=msk;
	} else if (addr==R_IFFPCLR) {
		hw->iflags&=~(1<<0);
	} else if (addr==R_IF8KCLR) {
		hw->iflags&=~(1<<3);
	} else if (addr==R_IF2KCLR) {
		hw->iflags&=~(1<<4);
	} else if (addr==R_IFTM0CLR) {
		hw->iflags&=~(1<<7);
	} else if (addr==R_IFTBLCLR) {
		hw->iflags&=~(1<<10);
	} else if (addr==R_IFTBHCLR) {
		hw->iflags&=~(1<<11);
	} else if (addr==R_IFTM1CLR) {
		hw->iflags&=~(1<<13);
	} else if (addr==R_LCDSEG) {
		t->lcd.sizex=(val+1)*8;
	} else if (addr==R_LCDCOM) {
		t->lcd.sizey=(val+1);
	} else if (addr==R_NMICTL) {
		t->ioreg[addr-0x3000]=val;
		hw->nmiflags&=val;
	} else if (addr==R_TIMBASE || addr==R_TIMCTL || addr==R_CLKCTL) {
		t->ioreg[addr-0x3000]=val;
		tamaClkRecalc(t);
		if (t->clk.cpuDiv==0 && (REG(R_WAKEFL)&REG(R_WAKEEN))) {
			//Wake up immediately
			REG(R_CLKCTL)=(REG(R_CLKCTL)&0xf8)|2;
			t->clk.cpuDiv=8;
		}
	} else if (addr==R_WAKEFL) {
		//Make sure the write _clears_ the flag
		val=t->ioreg[R_WAKEFL-0x3000]&(~(val));
	} else if (addr>=0x3080 && addr<0x3090) {
		printf("Data\n");
		t->cpu->Trace=1;
//	} else if (addr==0x3055) {
//		cpu->Trace=1;
//		printf("wuctl unimplemented ioWr 0x%04X 0x%02X\n", addr, val);
	} else {
		if (!implemented[addr&0xff] && t->bkUnk) {
			printf("unimplemented ioWr 0x%04X 0x%02X\n", addr, val);
			cpu->Trace=1;
		}
	}
	t->ioreg[addr-0x3000]=val;
}


int tamaHwTick(Tamagotchi *t, int gran) {
	TamaHw *hw=&t->hw;
	TamaClk *clk=&t->clk;
	M6502 *R=t->cpu;
	int t0Tick=0, t1Tick=0;
	int nmiTrigger=0;
	int ien;

	//Do IR ticks
	if (irTick(gran, &t->irnx)) t->hw.portAdata&=~0xf0; else t->hw.portAdata|=0xf0;
	if (t->irnx!=0) {
		t->irnx-=gran;
		if (t->irnx<0) t->irnx=0;
		return gran;
	}


	clk->tblCtr+=gran;
	clk->tbhCtr+=gran;
	clk->c8kCtr+=gran;
	clk->c2kCtr+=gran;
	clk->fpCtr+=gran;
	if (clk->cpuDiv!=0) clk->cpuCtr+=gran;
	if (clk->t0Div!=0) clk->t0Ctr+=gran;
	if (clk->t1Div!=0) clk->t1Ctr+=gran;

	while (clk->tblCtr>=clk->tblDiv) {
		clk->tblCtr-=clk->tblDiv;
		hw->iflags|=(1<<10);
		if (((REG(R_TIMCTL)>>2)&7)==1) t0Tick++;
		tamaWakeSrc(t, (1<<1));
	}

	while (clk->tbhCtr>=clk->tbhDiv) {
		clk->tbhCtr-=clk->tbhDiv;
		hw->iflags|=(1<<11);
		if (((REG(R_TIMCTL)>>2)&7)==2) t0Tick++;
		tamaWakeSrc(t, (1<<3));
	}

	if (clk->c2kCtr>=2048) {
		clk->c2kCtr&=2047;
		hw->iflags|=(1<<4);
	}
	if (clk->c8kCtr>=8192) {
		clk->c8kCtr&=8191;
		hw->iflags|=(1<<3);
	}
	if (clk->cpuDiv!=0 && (clk->cpuCtr>=clk->cpuDiv)) {
		hw->remCpuCycles+=clk->cpuCtr/clk->cpuDiv;
		clk->cpuCtr=clk->cpuCtr%clk->cpuDiv;
	}
	while (clk->t0Div!=0 && clk->t0Ctr>=clk->t0Div) {
		clk->t0Ctr-=clk->t0Div;
		t0Tick++;
	}
	if (clk->fpCtr>=(FCPU/60)) {
		hw->iflags|=(1<<0);
	}

	while (t0Tick) {
		REG(R_TM0LO)++;
		if (REG(R_TM0LO)==0) {
			REG(R_TM0HI)++;
			if (REG(R_TM0HI)==0) {
				hw->iflags|=(1<<7);
				if (((REG(R_TIMCTL))&3)==3) t1Tick++;
				tamaWakeSrc(t, (1<<2));
			}
		}
		t0Tick--;
	}

	while (clk->t1Div!=0 && clk->t1Ctr>=clk->t1Div) {
		clk->t1Ctr-=clk->t1Div;
		t1Tick++;
	}

	while (t1Tick) {
		REG(R_TM1LO)++;
		if (REG(R_TM1LO)==0) {
			REG(R_TM1HI)++;
			if (REG(R_TM1HI)==0) {
				hw->iflags|=(1<<13);
				nmiTrigger|=(1<<1);
				tamaWakeSrc(t, (1<<4));
			}
		}
		t1Tick--;
	}


	//Fire interrupts if enabled
	ien=REG(R_INTCTLLO)|(REG(R_INTCTLMI)<<8);
//	if (ien&hw->iflags) printf("Firing int because of iflags 0x%X\n", (ien&hw->iflags));
	if ((ien&hw->iflags)&(1<<0)) Int6502(R, INT_IRQ, IRQVECT_FP);
	if ((ien&hw->iflags)&(1<<1)) Int6502(R, INT_IRQ, IRQVECT_SPI);
	if ((ien&hw->iflags)&(1<<2)) Int6502(R, INT_IRQ, IRQVECT_SPU);
	if ((ien&hw->iflags)&(1<<3)) Int6502(R, INT_IRQ, IRQVECT_FROSCD8K);
	if ((ien&hw->iflags)&(1<<4)) Int6502(R, INT_IRQ, IRQVECT_FROSCD2K);
	if ((ien&hw->iflags)&(1<<7)) Int6502(R, INT_IRQ, IRQVECT_T0);
	if ((ien&hw->iflags)&(1<<10)) Int6502(R, INT_IRQ, IRQVECT_TBL); //seems to be for animation, 2Hz
	if ((ien&hw->iflags)&(1<<11)) Int6502(R, INT_IRQ, IRQVECT_TBH);
	if ((ien&hw->iflags)&(1<<13)) Int6502(R, INT_IRQ, IRQVECT_T1);
	//debug: remember last irq somewhere
	if (ien&hw->iflags) hw->lastInt=(ien&hw->iflags);

	//Fire NMI
	if (REG(R_NMICTL)&0x80) {
		//Should be edge triggered. The timer is. An implementation of lv may not be.
		hw->nmiflags|=nmiTrigger;
		if (REG(R_NMICTL)&nmiTrigger) {
			Int6502(R, INT_NMI, 0);
		}
	}

	//Handle stupid hackish button release...
	if (t->btnReleaseTm>0) {
		t->btnReleaseTm-=gran;
		if (t->btnReleaseTm<=0) {
			t->btnReleaseTm=0;
			tamaToggleBtn(t, t->btnPressed);
			printf("Release btn %d\n", t->btnPressed);
		}
	}
	
	if (hw->portALastRead!=hw->portAdata) {
		tamaWakeSrc(t, 1<<0);
	}

	//Now would be a good time to run the cpu, if needed.
	if (hw->remCpuCycles>0) {
		hw->remCpuCycles=Exec6502(t->cpu, hw->remCpuCycles);
	}
	return gran;
}

uint8_t tamaReadCb(M6502 *cpu, register word addr) {
	Tamagotchi *t=(Tamagotchi *)cpu->User;
	uint8_t r=0xff;
	if (addr<0x600) {
		r=t->ram[addr];
	} else if (addr>=0x1000 &&  addr<0x1200) {
		r=t->dram[addr-0x1000];
	} else if (addr>=0x3000 &&  addr<0x4000) {
		r=ioRead(cpu, addr);
	} else if (addr>=0x4000 &&  addr<0xc000) {
		r=t->rom[t->hw.bankSel][addr-0x4000];
	} else if (addr>=0xc000) {
		r=t->rom[0][addr-0xc000];
	} else {
		printf("TamaEmu: invalid read: addr 0x%02X\n", addr);
		cpu->Trace=1;
	}
//	printf("Rd 0x%04X 0x%02X\n", addr, r);
	return r;
}

void tamaWriteCb(M6502 *cpu, register word addr, register byte val) {
	Tamagotchi *t=(Tamagotchi *)cpu->User;
//	printf("Wr 0x%04X 0x%02X\n", addr, val);
	if (addr<0x600) {
		t->ram[addr]=val;
	} else if (addr>=0x1000 &&  addr<0x1200) {
		t->dram[addr-0x1000]=val;
	} else if (addr>=0x3000 &&  addr<0x4000) {
		ioWrite(cpu, addr, val);
	} else {
		printf("TamaEmu: invalid write: addr 0x%04X val 0x%02X\n", addr, val);
		cpu->Trace=1;
	}
}

byte Patch6502(register byte Op, register M6502 *R) {
	return 0;
}

byte Loop6502(register M6502 *R) {
	return 0;
}

void tamaDeinit(Tamagotchi *tama) {
	//ToDo: do more here
	i2ceepromDeinit(tama->i2ceeprom);
}

Tamagotchi *tamaInit(unsigned char **rom, const char *eepromFile) {
	Tamagotchi *tama=malloc(sizeof(Tamagotchi));
	memset(tama, 0, sizeof(Tamagotchi));
	tama->cpu=malloc(sizeof(M6502));
	memset(tama->cpu, 0, sizeof(M6502));
	tama->rom=rom;
	tama->i2cbus=i2cInit();
	tama->i2ceeprom=i2ceepromInit(eepromFile);
	i2cAddDev(tama->i2cbus, &tama->i2ceeprom->i2cdev, 0xA0);
	tama->cpu->Rd6502=tamaReadCb;
	tama->cpu->Wr6502=tamaWriteCb;
	tama->cpu->User=(void*)tama;
	tama->hw.bankSel=0;
	tama->hw.portAdata=0xf; //7-IR recv, 3-batlo 2-but2 1-but1 0-but0
	tama->hw.portBdata=0xfe;	//0, 1: I2C; 3: IR send,
	tama->hw.portCdata=0xff;
	Reset6502(tama->cpu);
	tama->ioreg[R_CLKCTL-0x3000]=0x2; //Fosc/8 is default
	tama->irnx=0;
	tamaClkRecalc(tama);
	return tama;
}

void tamaRun(Tamagotchi *tama, int cycles) {
	while (cycles>0) cycles-=tamaHwTick(tama, 128);
}



