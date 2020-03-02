#include <windows.h>
#include <io.h>
#include <time.h>
#include <stddef.h>

WINDOWPTR w0, w1, w2, w3, w4;
FILE *fp1,*fp2,*fp3;
int count,cntlo,cnthi,debug,dot,flag,i,printer;
unsigned st,st2;
char filein[80],filelo[80],filehi[80],store[80];
unsigned char data;

main(argc,argv)
int argc;
char *argv[];
{
	  v_smode(C8025);

	  w0 = wn_open(0,12,0,78,10,(BLUE<<4|WHITE),GREEN);
	  wn_puts(w0,2,20,"             TurboRacer 286             ");
	  wn_puts(w0,4,20,"     8086 16bit - 8bit splitter aid     ");
	  wn_puts(w0,6,20,"       (C) March 1988, P.D. Smart       ");
	  pause(1);
	  wn_close(w0);

	  count=dot=0;
	  if(argc==1 || argc>2) 
	    {
	    printf("SPLIT: Invalid arguments\n");
	    exit(-1);
	  }
	  strcpy(store,*++argv);
	  while(store[count]!=0)
	       {
		filein[count]=store[count];
		if(filein[count]=='.') dot=count;
		count++;
	  }
          if(dot) store[dot]=0;
	  filein[count]=0;
	  strcpy(filelo,store);
	  strcpy(filehi,store);
	  strcat(filelo,".LO");
	  strcat(filehi,".HI");

	  if((fp1=fopen(filein,"rb"))==NULL)
	     {
	     printf("SPLIT: File '%s' does not exist\n",filein);
	     exit(-1);
	  }
          if((fp2=fopen(filelo,"wb"))==NULL)
	     {
	     printf("SPLIT: Can't create '%s'... Directory or Disk full\n",filelo);
	     exit(-1);
	  }
          if((fp3=fopen(filehi,"wb"))==NULL)
	     {
	     printf("SPLIT: Can't create '%s'... Directory or Disk full\n",filehi);
	     exit(-1);
	  }

	  w0 = wn_open(0,1,0,78,22,YELLOW,RED);
	  wn_wrap(w0,TRUE);
	  wn_scroll(w0,BIOS);

	  wn_clr(w0);
	  wn_printf(w0,"Splitting file: %s -> %s, %s\n",filein,filelo,filehi);
	  
	  count=cntlo=cnthi=flag=i=0;
	  wn_printf(w0,"Splitting word: 0000");
	  while(1)
	     {
	     if(feof(fp1)) break;
	     data=fgetc(fp1);
	     count++;
	     if(!flag)
		{
		fputc(data,fp2);
		cntlo++;
		flag=1;
	     } else
		{
		fputc(data,fp3);
		cnthi++;
		flag=0;
	     }
	     if(i++>255)
		{
		wn_printf(w0,"%cSplitting word: %04X",0x0d,count/2);
	      	i=0;
	     }
	  }
	  wn_printf(w0,"\nBytes written to file: %s = %04X\n",filelo,cntlo);
	  wn_printf(w0,"Bytes written to file: %s = %04X\n",filehi,cnthi);
	  pause(1);
       	  fclose(fp1);
	  fclose(fp2);
	  fclose(fp3);
	  wn_close(w0);
}

pause(seconds)
int seconds;
{
   unsigned cnt,cnt2;
   for(cnt=0;cnt<seconds;cnt++)
      for(cnt2=0;cnt2<30000;cnt2++);
}




