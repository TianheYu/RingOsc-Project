#include <stdio.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xscugic.h"
#include "xil_exception.h"
#include "scugic_header.h"
#include "xdmaps.h"
#include "dmaps_header.h"
#include "xdevcfg.h"
#include "devcfg_header.h"
#include "xscutimer.h"
#include "scutimer_header.h"
#include "xscuwdt.h"
#include "scuwdt_header.h"
#include "xparameters.h"

#define Row_MAX 144
#define  Col_MAX 33
#define PL_FRE 50
#define TEST_COUNT 10
int main() 
{
	unsigned int check=0;
	unsigned int Addr=1,Row_i=144,Col_i=33;
	unsigned int R_value=0;
	int i = 0;
	Xil_ICacheEnable();
	Xil_DCacheEnable();
	print("TH");
		for(i=0;i<TEST_COUNT;i++)
		{
		   Xil_Out32(XPAR_RINGOSC_0_S00_AXI_BASEADDR+4,100000);  //
		   Xil_Out32(XPAR_RINGOSC_0_S00_AXI_BASEADDR,0x53);
		   Xil_Out32(XPAR_RINGOSC_0_S00_AXI_BASEADDR,0x54);
		   while(1){
			   check =  Xil_In32(XPAR_RINGOSC_0_S00_AXI_BASEADDR);
			   if((check&0x00000100) != 0)
				   break;
		   }
		   Xil_Out32(XPAR_RINGOSC_0_S00_AXI_BASEADDR,0x55);
		   while(1){
			   check =  Xil_In32(XPAR_RINGOSC_0_S00_AXI_BASEADDR);
			   if((check&0x00000100) == 0)
				   break;
			  }
		   for(Row_i=0;Row_i<Row_MAX;Row_i++)
			   for(Col_i=0;Col_i<Col_MAX;Col_i++)
			   {
				   Xil_Out32(XPAR_RINGOSC_0_S00_AXI_BASEADDR+8,Addr);
				   R_value =  Xil_In32(XPAR_RINGOSC_0_S00_AXI_BASEADDR+12);
				   Addr++;
				   xil_printf("%d",R_value);
			   }
		   print("/");
		   Addr=1;
		   Col_i=0;
		   Row_i=0;
		}
		print(".");
	   Xil_DCacheDisable();
	   Xil_ICacheDisable();
	   return 0;
}
