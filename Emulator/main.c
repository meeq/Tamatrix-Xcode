/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * Jeroen Domburg <jeroen@spritesmods.com> wrote this file. As long as you retain 
 * this notice you can do whatever you want with this stuff. If we meet some day, 
 * and you think this stuff is worth it, you can buy me a beer in return. 
 * ----------------------------------------------------------------------------
 */


#include <sys/time.h>
#include <time.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/select.h>
#include <string.h>

#include "tamaemu.h"
#include "lcd.h"
#include "benevolentai.h"
#include "udp.h"

Tamagotchi *tama;
int needRestart=0;

void sigintHdlr(int sig)  {
	if (tama->cpu->Trace) {
		printf("\n");
		udpExit();
		exit(1);
	}
	tama->cpu->Trace=1;
}

void sighupHdlr(int sig) {
	needRestart=(rand()%1200)+1;
}


int getKey() {
	char buff[100];
	fd_set fds;
	struct timeval tv;
	FD_ZERO(&fds);
	FD_SET(0, &fds);
	tv.tv_sec=0;
	tv.tv_usec=0;
	select(1, &fds, NULL, NULL, &tv);
	if (FD_ISSET(0, &fds)) {
		fgets(buff, 99, stdin);
		return buff[0];
	} else {
		return 0;
	}
}


#define FPS 15

int main(int argc, char **argv) {
	unsigned char **rom;
	long us;
	int k, i;
	int speedup=0;
	int stopDisplay=0;
	int aiEnabled=1;
    int silent=0;
	int t=0;
	char *eeprom="tama.eep";
	char *host="127.0.0.1";
	char *romdir="rom";
	struct timespec tstart, tend;
	uint8_t *dram;
	int sizex, sizey;
	Display display;
	int err=0;

	srand(time(NULL));
	for (i=1; i<argc; i++) {
		if (strcmp(argv[i],"-h")==0 && argc>i+1) {
			i++;
			host=argv[i];
		} else if (strcmp(argv[i],"-e")==0 && argc>i+1) {
			i++;
			eeprom=argv[i];
		} else if (strcmp(argv[i],"-r")==0 && argc>i+1) {
			i++;
			romdir=argv[i];
		} else if (strcmp(argv[i], "-n")==0) {
			aiEnabled=0;
        } else if (strcmp(argv[i], "-s")==0) {
            silent=1;
		} else {
			printf("Unrecognized option - %s\n", argv[i]);
			err=1;
			break;
		}
	}

	if (err) {
		printf("Usage: %s [options]\n", argv[0]);
		printf("-h host - change tamaserver host address (def 127.0.0.1)\n");
		printf("-e eeprom.eep - change eeprom file (def tama.eep)\n");
		printf("-r rom/ - change rom dir\n");
		printf("-n - disable AI\n");
        printf("-s - disable console noise\n");
		exit(0);
	}

	signal(SIGINT, sigintHdlr);
	signal(SIGHUP, sighupHdlr);
	rom=loadRoms(romdir);
	tama=tamaInit(rom, eeprom);
	dram=(uint8_t *)tama->dram;
	benevolentAiInit();
	udpInit(host);
	while(1) {
		clock_gettime(CLOCK_MONOTONIC, &tstart);
		tamaRun(tama, FCPU/FPS-1);
		sizex=tama->lcd.sizex;
		sizey=tama->lcd.sizey;
		lcdRender(dram, sizex, sizey, &display);
		udpTick();
		if (aiEnabled) {
			k=benevolentAiRun(&display, 1000/FPS);
		} else {
			k=0;
		}
		if (!speedup || (t&15)==0) {
            udpSendDisplay(&display);
            if (!silent) {
                lcdShow(&display);
                tamaDumpHw(tama->cpu);
                benevolentAiDump();
            }
		}
		if ((k&8)) {
			//If anything interesting happens, make a LCD dump.
			lcdDump(dram, sizex, sizey, "lcddump.lcd");
			if (stopDisplay) {
				tama->cpu->Trace=1;
				speedup=0;
			}
		}
		if (k&1) tamaPressBtn(tama, 0);
		if (k&2) tamaPressBtn(tama, 1);
		if (k&4) tamaPressBtn(tama, 2);
		clock_gettime(CLOCK_MONOTONIC, &tend);
		us=(tend.tv_nsec-tstart.tv_nsec)/1000;
		us+=(tend.tv_sec-tstart.tv_sec)*1000000L;
		us=(1000000L/FPS)-us;
//		printf("Time left in frame: %d us\n", us);
		if (!speedup && us>0) usleep(us);
		k=getKey();
		if (k=='1') tamaPressBtn(tama, 0);
		if (k=='2') tamaPressBtn(tama, 1);
		if (k=='3') tamaPressBtn(tama, 2);
		if (k=='s') speedup=!speedup;
		if (k=='d') stopDisplay=!stopDisplay;
		t++;
		//If we receive a SIGHUP, we will wait a random amount of time and then restart.
		if (needRestart!=0) {
			needRestart--;
			if (needRestart==0) {
				udpExit();
				tamaDeinit(tama);
				execvp(argv[0], argv);
			}
		}
	}
}
