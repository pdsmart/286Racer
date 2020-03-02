/****************************************************************************
 * TurboRacer 286 ACCELerator software                                      *
 * -----------------------------------                                      *
 *                                                                          *
 * (C) 1987,1988 P.D. Smart.                                                *
 *                                                                          *
 *                                                                          *
 * This file contains startup and initialisation code for the accelerator.  *
 *                                                                          *
 * Basically, it resets the ADRAM controller and the 286 processor, and     *
 * awaits the return of a self test validation code. If the accelerator     *
 * does not pass it's self test, then this programs terminates back to the  *
 * DOS enviroment being run on the PC. It also processes user option flags, *
 * and passes the necessary information to the accelerator. Whilst the      *
 * accelerator is running, the server code, which is written in assembly    *
 * language and bonded to this C program, services the accelerator. If an   *
 * error occurs, or the user abandons the accelerator, then control returns *
 * to this program, and a termination message is printed. The program then  *
 * terminates back to the DOS enviroment being run on the PC.               *
 *                                                                          *
 * HISTORY                                                                  *
 * -------                                                                  *
 *                                                                          *
 * V1.0 - Basic program structure prepared and implemented.                 *
 *                                                                          *
 *                                                                          *
 ****************************************************************************/
#include <stdio.h>							     	
#include <io.h>
#include <time.h>
#include <stddef.h>

#define BOOTDOS	  0x01
#define COPYBOOT  0x02
#define	LOADBIOS  0x03
#define LOADTEST  0x04
#define MEMTEST   0x05
#define VERSION   "1.00"
#define DATEREL   "6th April 1988"

int BOOTflag;
char BIOSFILE[80];

main(argc,argv)
int argc;
char *argv[];
{
   FILE *fp1;
   int result;
   unsigned char data,intno;
   char tempbuf[80];

	  /* Sign on message. */
	  printf("TurboRacer 286 Accelerator\n");
          printf("Version %s, Released %s\n",VERSION,DATEREL);
	  printf("(C) 1987,1988 P.D. Smart. All rights reserved.\n\n");

	  /* Process flags. */
	  BOOTflag=0;
	  strcpy(BIOSFILE,"TURBOROM.OBJ");
	  while(argc>1)
	     {
	     strcpy(tempbuf,*++argv);
	     flags(tempbuf);
	     argc--;
	  }

	  /* Reset ADRAM controller, then 286 processor. */
	  outp(0x211,0x01);
	  outp(0x211,0x00);
	  if(readstat()) readlink(); /* Clear link. */
	  outp(0x211,0x02);

          /* Once 286 reset, a self test is performed. A value is returned
	     on the link indicating status of accelerator board. */ 
	  printf("286 performing memory test.....");
	  if(data=readlink())
	     error(data,"");
	  else
	     printf("Memory OK.\n");

	  /* If the bootflag is set, then the BIOS contained on the 
	     accelerator will not be used, instead, a new BIOS, contained
	     within the file named by BIOSFILE, will be loaded into the
	     accelerator. */
	  if(BOOTflag)
	     {
	     printf("Loading new BIOS.....");
	     if((fp1=fopen(BIOSFILE,"rb"))==NULL)
		error(3,BIOSFILE);
	     writelink(LOADBIOS); /* Send command to accelerator to load
		                     a new BIOS. */ 
	     while(!feof(fp1))
		{
		data=fgetc(fp1);
		writelink(data);
	     }
             fclose(fp1);
	     /* Once the new BIOS is loaded, it re-performs the self-test,
		returning a result code over the link. */
	     if(data=readlink())
	       error(4,"");
	     else
	       printf("BIOS loaded OK.\n");
	     writelink(BOOTDOS); /* Send command to accelerator to boot DOS.*/
	  } else
	     writelink(COPYBOOT); /* Use internal BIOS and boot DOS. */

	  /* Execute the server software, which is written in assembler. 
	     If the accelerator is terminated by user, or error, a result is
	     returned. If the high byte of the result is not zero, then the
	     low byte contains an error code. If the high byte of the result 
	     is zero, then the user terminated the accelerator. */
	  result=setup();
	  if((result>>8)&0x00ff)
	     {
	     printf("\n\nAccelerator terminated, ");
	     switch(result&0x00ff)
	     	    {
		    case 0:
		       printf("Divide error exception occurred.\n");
		       break;
	     	    case 1:
		       printf("Single step interrupt occurred.\n");
	               break;
		    case 3:
		       printf("Breakpoint intercepted.\n");
		       break;
		    case 4:
		       printf("Overflow exception occurred.\n");
		       break;
		    case 5:
		       printf("Range exceeded exception occurred.\n");
		       break;
		    case 6:
		       printf("Invalid opcode exception occurred.\n");
		       break;
		    case 7:
		       printf("No math unit available exception occurred.\n");
		       break;
		    case 8:
		       printf("IDT too small exception occurred.\n");
		       break;
		    case 10:
		    case 11:
		    case 12:
		    case 14:
		    case 15:
		    case 24:
		    case 29:
		    case 30:
		    case 31:
		       printf("Reserved interrupt - %02X occurred.\n",result&0x00ff);
		       break;
		    case 13:
		       printf("Segment overrun exception occurred.\n");
		       break;
	            default:
		       printf("Illegal interrupt - %02X occurred.\n",result&0x00ff);
	               break;
	     }
	  } else
	     printf("\n\nAccelerator terminated by user.\n");
}	      	   


/* This subroutine processes flags present on the input line. A flag begins
   with a '-' sign, followed by a letter. */
flags(tempbuf)
char *tempbuf;
{
   int cnt=0;
   int index=0;

   	while(tempbuf[cnt]!=0)
	   {
	   if(tempbuf[cnt++]!='-')
	      error(5,tempbuf);
	   switch(tempbuf[cnt++])
	      {
	      case 'B':
	      case 'b':
		 BOOTflag=1;
	         break;
	      case 'F':
	      case 'f':
		 while(tempbuf[cnt]!=0)
		    BIOSFILE[index++]=tempbuf[cnt++];
		 BIOSFILE[index]=0;
		 break;
	      default:
		 error(5,tempbuf);
		 break;
	   }
	}
}

/* This subroutine processes errors, indicating on the standard output, an
   internal processing error, or a hardware error on the accelerator. */ 
error(errno,tempbuf)
int errno;
char *tempbuf;
{
	printf("\nACCEL: ");
   	switch(errno)
	   {
	   case 1:
	      printf("286 processor failure...\n");
	      exit(-1);
	      break;
	   case 2:
	      printf("286 memory failure...\n");
	      exit(-2);
	      break;
	   case 3:
	      printf("Can't open '%s'\n",tempbuf);
	      exit(-3);
	      break;
	   case 4:
	      printf("BIOS loading failed...\n");
	      exit(-4);
	      break;
	   case 5:
	      printf("Illegal flag '%s'.\n",tempbuf);
	      exit(-5);
	      break;
	}
}
