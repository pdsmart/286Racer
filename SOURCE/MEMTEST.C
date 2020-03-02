#include <windows.h>
#include <io.h>
#include <time.h>
#include <stddef.h>

WINDOWPTR w0, w1, w2;

main(argc,argv)
int argc;
char *argv[];
{
   int key,flag;
   unsigned char databyte;

   	  v_smode(C8025);

	  w0 = wn_open(0,12,0,78,10,(BLUE<<4|WHITE),GREEN);
	  wn_puts(w0,2,20,"             TurboRacer 286             ");
	  wn_puts(w0,4,20,"     Memory Read/Write testing aid      ");
	  wn_puts(w0,6,20,"       (C) March 1988, P.D. Smart       ");
	  pause(2);
	  wn_close(w0);

	  w0 = wn_open(0,1,0,78,18,YELLOW,RED);
	  wn_wrap(w0,TRUE);
	  wn_scroll(w0,BIOS);
	  w1 = wn_open(1000,0,0,78,1,BOLD|YELLOW,BLACK);
	  w2 = wn_open(1000,21,0,80,4,CYAN,BLACK);
	  wn_wrap(w2,TRUE);
	  wn_scroll(w2,BIOS);

	  reset();
	  wn_clr(w1);
	  wn_puts(w1,0,25,"MEMORY READ/WRITE TESTER MENU");
	  while(1)
	     {
	     wn_clr(w0);
	     wn_puts(w0,2,30, "[A] - Read memory");
	     wn_puts(w0,4,30, "[B] - Write memory");
	     wn_puts(w0,6,30, "[C] - Partial memory test");
	     wn_puts(w0,8,30, "[D] - Full memory Test");
	     wn_puts(w0,10,30,"[E] - Search for value");
	     wn_puts(w0,12,30,"[F] - Reset accelerator");
	     wn_puts(w0,14,30,"[G] - Quit");
	     wn_puts(w0,17,14," Select option by pressing a bracketed key ");
	     wn_clr(w2);
	     key=' ';
	     while(key!='A'&&key!='a'&&key!='B'&&key!='b'&&key!='C'&&key!='c'
		   &&key!='D'&&key!='d'&&key!='E'&&key!='e'&&key!='f'
		   &&key!='F'&&key!='g'&&key!='G')
		{
		while(!kbhit())
		   {
		   if(readstat())
		      {
		      databyte=readbyte();
		      wn_printf(w2,"%c",databyte);
		   }
		}
	        key=v_getch()&0xff;
	     }
	     switch(key)
	        {
	        case 'A':
	        case 'a':
                   readmem();
	           break;
		case 'B':
		case 'b':
		   writemem();
		   break;
		case 'C':
		case 'c':
		   parttest();
		   break;
		case 'D':
		case 'd':
		   fulltest();
		   break;
		case 'E':
		case 'e':
		   search();
		   break;
		case 'F':
		case 'f':
		   reset();
		   break;
		case 'G':
		case 'g':
		   W_exit(0);
		   break;
	     }
	  }
}

fulltest()
{
   unsigned ss,bp,ds,bx,error;
   unsigned char databyte;
   FILE *fp1;

   	error=0;
   	if((fp1=fopen("FULLTEST.DAT","wb"))==NULL)
	   {
	   wn_printf(w0,"Can't open FULLTEST.DAT\n");
	   pause(2);
	   return(1);
	}
   	wn_clr(w0);
	wn_clr(w2);
	if(readstat()) readbyte();
	wn_printf(w2,"\nSending command to 286...");
	writebyte(0x04);
	wn_clr(w2);
	wn_printf(w2,"Performing full test...");

	while(1)
	   {
	   while(!readstat())
	      {
	      if(kbhit()) 
		{
		databyte=v_getch()&0xff;
		if(databyte=='q' || databyte=='Q')
		   {
		   reset();
		   fclose(fp1);
		   return(1);
		}
	        if(databyte==' ')
		   while(!kbhit());
	      }
	   }
	   ss=readword();
	   bp=readword();
	   ds=readword();
	   bx=readword();
	   databyte=readbyte();
	   wn_puts(w0,1,1,"SS:BP = ");
	   wn_printf(w0,"%04X:%04X",ss,bp);
	   if(databyte!=0)
	      {
	      error++;
	      fprintf(fp1,"SS=%04X, BP=%04X, DS=%04X, BX=%04X, AL=%02X - **ERROR**%c%c"
		         ,ss,bp,ds,bx,databyte,0x0d,0x0a);
	   }
	   wn_puts(w0,2,1,"Errors = ");
	   wn_printf(w0,"%04X",error);
	   if(ss==0x8000 && bp==0xffff)
	      {
	      reset();
	      fclose(fp1);
	      return(1);
	   }
	}
}


reset()
{
   unsigned char databyte;

   	  wn_clr(w2);
	  wn_clr(w0);
	  wn_putsa(w2,0,1,"RESETTING 8207 MEMORY CONTROLLER",YELLOW|BLINK);
	  outp(0x211,0x01);
	  pause(1);
	  outp(0x211,0x00);
	  wn_clr(w2);
	  wn_putsa(w2,0,1,"RESETTING 286 PROCESSOR",YELLOW|BLINK);
	  pause(1);
	  if(readstat()) readbyte();
   	  outp(0x211,0x02);

	  wn_clr(w2);
	  wn_printf(w2,"Awaiting test result.....");
	  databyte=readbyte();
	  if(databyte!=0)
	        wn_printf(w2,"Failed, Error code=%02X\n",databyte);
	     else
		{
		wn_printf(w2,"PASSED.\n");
		writebyte(0x05);
	  }
}	      		 

search()
{
   unsigned ax,bx,ds;
   unsigned char databyte;
   char bufin[80];
   
   	  if(readstat()) readbyte();
	  wn_printf(w2,"\nSending command to 286...");
	  writebyte(0x05);

	  wn_clr(w2);
	  wn_putsa(w0,10,36,"SEARCH FOR VALUE",YELLOW|BLINK);
	  wn_printf(w2,"\nEnter search value <00>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) databyte=0x00;
	    else
	       {
	       sscanf(bufin,"%x",&databyte);
	  }
       	  writebyte(databyte);

	  while(1)
	     {
	     ax=readword();
	     ds=readword();
	     bx=readword();
	     if(ax==0xffff)
		return(1);
	     wn_printf(w2,"Failure at %04X:%04X, Byte read=%02X\n"
		         ,ds,bx,ax&0x00ff);
	     if(kbhit()) 
		{
		databyte=v_getch()&0xff;
		if(databyte=='q' || databyte=='Q' )
		   {
		   reset();
		   return(1);
		}
	        if(databyte==' ')
		   while(!kbhit());
	     }				
	  }
}

parttest()
{
   unsigned ax,bx,ds;
   unsigned char ercode;

	  if(readstat()) readbyte();
	  wn_printf(w2,"\nSending command to 286...");
	  writebyte(0x03);

   	  wn_clr(w2);
	  wn_putsa(w0,6,36,"PARTIAL MEMORY TEST",YELLOW|BLINK);
	  wn_printf(w2,"286 running memory test...waiting\n");
	  ercode=readbyte();
	  ax=readword();
	  bx=readword();
	  ds=readword();
	  wn_printf(w2,"AX=%04X, BX=%04X, DS=%04X: ",ax,bx,ds);
	  switch(ercode)
	     {
	     case 0:
		wn_printf(w2,"Memory test successful\n");
	     	break;
	     case 1:
		wn_printf(w2,"Failure writing 55AAH\n");
	     	break;
	     case 2:
		wn_printf(w2,"Failure writing AA55H\n");
	     	break;
	     case 3:
		wn_printf(w2,"Failure writing 00FFH\n");
	     	break;
	     case 4:
		wn_printf(w2,"Failure writing FF00H\n");
	     	break;
	     case 5:
		wn_printf(w2,"Failure writing byte 00 (1)\n");
	     	break;
	     case 6:
		wn_printf(w2,"Failure writing byte FF (1)\n");
	     	break;
	     case 7:
		wn_printf(w2,"Failure writing byte 00 (2)\n");
	     	break;
	     case 8:
		wn_printf(w2,"Failure writing byte FF (2)\n");
	     	break;
	  }  
	  pause(4); 
}

readmem()
{
   	  long start,end,i;
	  char bufin[80];
	  unsigned char cnt, databyte;
	  unsigned dataword;

	  wn_clr(w2);

	  wn_putsa(w0,2,36,"READ MEMORY",YELLOW|BLINK);
	  wn_printf(w2,"\nEnter start address <00000>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) start=0x00000;
            else
	       {
	       sscanf(bufin,"%lx",&start);
	       if(start>0xfffff) start=0xfffff;
	  }
          wn_clr(w2);
	  wn_printf(w2,"\nEnter end address <00100>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) end=0x00100;
            else
	       {
	       sscanf(bufin,"%lx",&end);
	       if(end>0xfffff) end=0xfffff;
	  }
          wn_clr(w2);

	  wn_printf(w2,"\nSending command to 286...");
	  if(readstat()) readbyte();
	  writebyte(0x01);		/* Send command.  */
	  dataword=(start>>4)&0xf000; 	/* Start segment. */
	  writeword(dataword);		
	  dataword=start&0xffff;	/* Start address. */
	  writeword(dataword);
	  dataword=(end>>4)&0xf000;     /* End segment.   */
	  writeword(dataword);
	  dataword=end&0xffff;		/* End address.   */
	  writeword(dataword);		

          wn_clr(w2);
	  wn_clr(w0);
	  cnt=16;
	  for(i=start;i<=end;i++)
	     {
	     if(cnt++>=15)
		{
		cnt=0;
		wn_printf(w0,"\n%05lX ",i);
	     }
	     databyte=readbyte();
	     wn_printf(w0," %02X ",databyte);
	     if(kbhit()) 
		{
		databyte=v_getch()&0xff;
		if(databyte=='q' || databyte=='Q')
		   {
		   reset();
		   break;
		}
	        if(databyte==' ')
		   while(!kbhit());
	     }
	  }
}	  	    

	
writemem()
{
   	  long start,end,i;
	  char bufin[80];
	  unsigned char cnt;
	  unsigned dataword,temp;

	  wn_clr(w2);

	  wn_putsa(w0,4,36,"WRITE MEMORY",YELLOW|BLINK);
	  wn_printf(w2,"\nEnter start address <00000>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) start=0x00000;
            else
	       {
	       sscanf(bufin,"%lx",&start);
	       if(start>0xfffff) start=0xfffff;
	  }
          wn_clr(w2);
	  wn_printf(w2,"\nEnter end address <7FFFF>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) end=0x7ffff;
            else
	       {
	       sscanf(bufin,"%lx",&end);
	       if(end>0xfffff) end=0xfffff;
	  }
          wn_clr(w2);
	  wn_printf(w2,"\nEnter data <00>: ");
	  wn_sync(w2,TRUE);
	  wn_fixcsr(w2);
	  wn_gets(w2,bufin,6,"0123456789AaBbCcDdEeFf");
	  if(bufin[0]==0x00) temp=0x00;
            else
	       {
	       sscanf(bufin,"%x",&temp);
	       if(temp>0xff) temp=0x00ff;
	  }

          wn_clr(w2);

	  wn_printf(w2,"\nSending command to 286...");
	  if(readstat()) readbyte();
	  writebyte(0x02);		/* Send command.  */
	  dataword=(start>>4)&0xf000; 	/* Start segment. */
	  writeword(dataword);		
	  dataword=start&0xffff;	/* Start address. */
	  writeword(dataword);
	  dataword=(end>>4)&0xf000;     /* End segment.   */
	  writeword(dataword);
	  dataword=end&0xffff;		/* End address.   */
	  writeword(dataword);
          writebyte(temp);		/* Data.          */		

}

pause(seconds)
int seconds;
{
   unsigned cnt,cnt2;
   for(cnt=0;cnt<seconds;cnt++)
      for(cnt2=0;cnt2<30000;cnt2++);
}


W_exit(no)
int no;
{
	  wn_close(w1);
	  wn_close(w2);
	  wn_close(w0);

	  switch(no)
	     {
	     case 0:
	        break;
	     case 1:
		break;
	     case 3:
	        break;
	     case 4:
	        break;
	     case 5:
	        break;
	     case 6:
	        break;
	  }
          exit(no);
}


