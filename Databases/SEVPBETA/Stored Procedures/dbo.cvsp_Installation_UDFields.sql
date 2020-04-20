SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2011 Viewpoint Construction Software (VCS) 
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:	Installation: Add UD Fields for Conversions to Viewpoint Tables	
	Created: 2010
	Created by:	VCS Technical Services
	Revisions:	1. 10/11/2010 BBA - Added udTLCustomerNumber to bAPVM
				2. 03/08/2011 BBA - Renamed procedure.
				3. 03/28/2011 BBA - Added IF NOT EXISTS code to all. Added new
				udVendor to bAPTD for bAPPH sp and ease of reconciliation.
				Rearranged in alpha order.
				4. 04/25/2011 BBA - Added udTLPayGroup to bPRGR and udTLPONumber to bPOHD.
				5. 02/10/2012 MTG - Changed for use in CGC
				6. 01/16/2012 BTC - Commented out the field adds for APHD.
				
				
	Notes: 	This procedure is being run when during the installation procedure.
	There is no need to manually run this procedure if using the install process 
	or there are changes made to the sp.		
**/

CREATE PROCEDURE [dbo].[cvsp_Installation_UDFields] 

AS

/** In Viewpoint add columns or user defined fields needed for conversion **/

	
	/** AP Accounts Payable **/
		
	/************APTH******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTH') and name='udRetgInvYN')
	alter table bAPTH add udRetgInvYN char(1) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTH') and name='udPaidAmt')
	alter table bAPTH add udPaidAmt decimal(12,2)  null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTH') and name='udYSN')
	alter table bAPTH add udYSN decimal(12,0)  null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTH') and name='udRCCD')
	alter table bAPTH add udRCCD int null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTH') and name='udRetgInvYN')
	alter table bAPTH add udRetgInvYN char(1) null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTH') and name='udSource')
	alter table bAPTH add udSource varchar(30) null
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTH') and name='udConv')
	alter table bAPTH add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTH') and name='udCGCTable')
	alter table bAPTH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTH') and name='udCGCTableID')
	alter table bAPTH add udCGCTableID decimal(12,0)  null;

	/************APTL******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTL') and name='udPaidAmt')
	alter table bAPTL add udPaidAmt decimal(12,2) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTL') and name='udYSN')
	alter table bAPTL add udYSN decimal(12,0) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTL') and name='ud1099Type')
	alter table bAPTL add ud1099Type varchar(3) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTL') and name='udRCCD')
	alter table bAPTL add udRCCD int null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTL') and name='udSubHistYN')
	alter table bAPTL add udSubHistYN char(1) null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTL') and name='udSource')
	alter table bAPTL add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTL') and name='udConv')
	alter table bAPTL add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTL') and name='udCGCTable')
	alter table bAPTL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTL') and name='udCGCTableID')
	alter table bAPTL add udCGCTableID decimal(12,0)  null;
	
	/************APTD******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTD') and name='udYSN')
	alter table bAPTD add udYSN decimal(12,0) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTD') and name='udRCCD')
	alter table bAPTD add udRCCD int null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTD') and name='udTotalChkAmt')
	alter table bAPTD add udTotalChkAmt numeric(12,2) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTD') and name='udMultiPay')
	alter table bAPTD add udMultiPay char(1) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bAPTD') and name='udRetgHistory')
	alter table bAPTD add udRetgHistory char(1) null;

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTD') and name='udSource')
	alter table bAPTD add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTD') and name='udConv')
	alter table bAPTD add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTD') and name='udCGCTable')
	alter table bAPTD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPTD') and name='udCGCTableID')
	alter table bAPTD add udCGCTableID decimal(12,0)  null;
	/************AP OTHER******************/
	
	
	/** I am commenting out this section.  APHD is not eligible for ud fields.  There is a procedure in the 
		AP Payment Workfile which has an Insert APHD command where no fields are specified.  The entire table is 
		assumed, but of course only the standard fields are addressed in the associated select statement.
		APHD is not accessible from a Viewpoint form and is not eligible for ud fields in the VA Custom Fields wizard.
		So we should not add fields to it.  --Bryan Clark, 1/16/2013
	
	--if not exists (select name from syscolumns	
	--	where id=OBJECT_ID('bAPHD') and name='udSource')
	--alter table bAPHD add udSource varchar(30) null
	
	--if not exists (select name from syscolumns	
	--	where id=OBJECT_ID('bAPHD') and name='udConv')
	--alter table bAPHD add udConv varchar(1) null
	
	--if not exists (select name from syscolumns	
	--	where id=OBJECT_ID('bAPHD') and name='udCGCTable')
	--alter table bAPHD add udCGCTable varchar(10)  null;
			
	--if not exists (select name from syscolumns	
	--	where id=OBJECT_ID('bAPHD') and name='udCGCTableID')
	--alter table bAPHD add udCGCTableID decimal(12,0)  null;
	
	**/
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPD') and name='udSource')
	alter table bAPPD add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPD') and name='udConv')
	alter table bAPPD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPD') and name='udCGCTable')
	alter table bAPPD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPD') and name='udCGCTableID')
	alter table bAPPD add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPH') and name='udSource')
	alter table bAPPH add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPH') and name='udConv')
	alter table bAPPH add udConv varchar(1) null
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPH') and name='udCGCTable')
	alter table bAPPH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPPH') and name='udCGCTableID')
	alter table bAPPH add udCGCTableID decimal(12,0)  null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPVM') and name='udSource')
	alter table bAPVM add udSource varchar(30) null	

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPVM') and name='udConv')
	alter table bAPVM add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPVM') and name='udCGCTable')
	alter table bAPVM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bAPVM') and name='udCGCTableID')
	alter table bAPVM add udCGCTableID decimal(12,0)  null;
	
	/** AR Accounts Receivable **/
	/************AR OTHER******************/
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARCM') and name='udSource')
	alter table bARCM add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARCM') and name='udConv')
	alter table bARCM add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARCM') and name='udCGCTable')
	alter table bARCM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARCM') and name='udCGCTableID')
	alter table bARCM add udCGCTableID decimal(12,0)  null;
	
	/*****  ARTH  *********/

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udARTOPCID')
	alter table bARTH add udARTOPCID bigint null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udPAYARTOPCID')
	alter table bARTH add udPAYARTOPCID bigint null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udPAYARTOPDID')
	alter table bARTH add udPAYARTOPDID varchar(20) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udCheckNo')
	alter table bARTH add udCheckNo varchar(20) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udCMSContract')
	alter table bARTH add udCMSContract varchar(20) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udMiscPayYN')
	alter table bARTH add udMiscPayYN varchar(1) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udRetgClearYN')
	alter table bARTH add udRetgClearYN varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udCVStoredProc')
	alter table bARTH add udCVStoredProc nvarchar(30) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udRetgHistYN')
	alter table bARTH add udRetgHistYN varchar(1) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTH') and name='udHistYN')
	alter table bARTH add udHistYN varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udPaidMth')
	alter table bARTH add udPaidMth smalldatetime null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udPaidDate')
	alter table bARTH add udPaidDate smalldatetime null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udCashRcptsDate')
	alter table bARTH add udCashRcptsDate smalldatetime null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udSource')
	alter table bARTH add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udConv')
	alter table bARTH add udConv varchar(1) null	

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udCGCTable')
	alter table bARTH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTH') and name='udCGCTableID')
	alter table bARTH add udCGCTableID decimal(12,0)  null;
	
	/*****  ARTL   *********/

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udHistYN')
	alter table bARTL add udHistYN varchar(1) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udHistCMRef')
	alter table bARTL add udHistCMRef varchar(15) null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udARTOPDID')
	alter table bARTL add udARTOPDID bigint null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udSeqNo')
	alter table bARTL add udSeqNo int null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udSeqNo05')
	alter table bARTL add udSeqNo05 int null

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bARTL') and name='udCVStoredProc')
	alter table bARTL add udCVStoredProc varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTL') and name='udRecCode')
	alter table bARTL add udRecCode varchar(1) null

	if not exists (select name from syscolumns      
		  where id=OBJECT_ID('bARTL') and name='udItemsBilled')
	alter table bARTL add udItemsBilled decimal(16,4) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTL') and name='udSource')
	alter table bARTL add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTL') and name='udConv')
	alter table bARTL add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTL') and name='udCGCTable')
	alter table bARTL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bARTL') and name='udCGCTableID')
	alter table bARTL add udCGCTableID decimal(12,0)  null;
	
	/** CM Cash Management **/

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bCMDT') and name='udSource')
	alter table bCMDT add udSource varchar(305) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bCMDT') and name='udConv')
	alter table bCMDT add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bCMDT') and name='udCGCTable')
	alter table bCMDT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bCMDT') and name='udCGCTableID')
	alter table bCMDT add udCGCTableID decimal(12,0)  null;
		
	/** EM Equipment Management **/
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMAR') and name='udSource')
	alter table bEMAR add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMAR') and name='udConv')
	alter table bEMAR add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMAR') and name='udCGCTable')
	alter table bEMAR add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMAR') and name='udCGCTableID')
	alter table bEMAR add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMBG') and name='udSource')
	alter table bEMBG add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMBG') and name='udConv')
	alter table bEMBG add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMBG') and name='udCGCTable')
	alter table bEMBG add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMBG') and name='udCGCTableID')
	alter table bEMBG add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCD') and name='udSource')
	alter table bEMCD add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCD') and name='udConv')
	alter table bEMCD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCD') and name='udCGCTable')
	alter table bEMCD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCD') and name='udCGCTableID')
	alter table bEMCD add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCM') and name='udSource')
	alter table bEMCM add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCM') and name='udConv')
	alter table bEMCM add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCM') and name='udCGCTable')
	alter table bEMCM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMCM') and name='udCGCTableID')
	alter table bEMCM add udCGCTableID decimal(12,0)  null;
					
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDP') and name='udSource')
	alter table bEMDP add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDP') and name='udConv')
	alter table bEMDP add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDP') and name='udCGCTable')
	alter table bEMDP add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDP') and name='udCGCTableID')
	alter table bEMDP add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDS') and name='udSource')
	alter table bEMDS add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDS') and name='udConv')
	alter table bEMDS add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDS') and name='udCGCTable')
	alter table bEMDS add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMDS') and name='udCGCTableID')
	alter table bEMDS add udCGCTableID decimal(12,0)  null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMEM') and name='udSource')
	alter table bEMEM add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMEM') and name='udConv')
	alter table bEMEM add udConv varchar(1) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMEM') and name='udCGCTable')
	alter table bEMEM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMEM') and name='udCGCTableID')
	alter table bEMEM add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMLH') and name='udSource')
	alter table bEMLH add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMLH') and name='udConv')
	alter table bEMLH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMLH') and name='udCGCTable')
	alter table bEMLH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMLH') and name='udCGCTableID')
	alter table bEMLH add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMC') and name='udSource')
	alter table bEMMC add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMC') and name='udConv')
	alter table bEMMC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMC') and name='udCGCTable')
	alter table bEMMC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMC') and name='udCGCTableID')
	alter table bEMMC add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMR') and name='udSource')
	alter table bEMMR add udSource varchar(305) null
	
		if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMR') and name='udConv')
	alter table bEMMR add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMR') and name='udCGCTable')
	alter table bEMMR add udCGCTable varchar(10)  null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMMR') and name='udCGCTableID')
	alter table bEMMR add udCGCTableID decimal(12,0)  null;
	
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udConv')
	alter table bEMRR add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udCGCTable')
	alter table bEMRR add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udCGCTableID')
	alter table bEMRR add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRD') and name='udSource')
	alter table bEMRD add udSource varchar(305) null 
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRD') and name='udConv')
	alter table bEMRD add udConv varchar(1) null 

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRD') and name='udCGCTable')
	alter table bEMRD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRD') and name='udCGCTableID')
	alter table bEMRD add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRH') and name='udSource')
	alter table bEMRH add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRH') and name='udConv')
	alter table bEMRH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRH') and name='udCGCTable')
	alter table bEMRH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRH') and name='udCGCTableID')
	alter table bEMRH add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udSource')
	alter table bEMRR add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udConv')
	alter table bEMRR add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udCGCTable')
	alter table bEMRR add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bEMRR') and name='udCGCTableID')
	alter table bEMRR add udCGCTableID decimal(12,0)  null;
				
	/** GL General Ledger **/
	
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bGLAC') and name='udActive')
	alter table bGLAC add udActive char(1) null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAC') and name='udSource')
	alter table bGLAC add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAC') and name='udConv')
	alter table bGLAC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAC') and name='udCGCTable')
	alter table bGLAC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAC') and name='udCGCTableID')
	alter table bGLAC add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAS') and name='udSource')
	alter table bGLAS add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAS') and name='udConv')
	alter table bGLAS add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAS') and name='udCGCTable')
	alter table bGLAS add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLAS') and name='udCGCTableID')
	alter table bGLAS add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBC') and name='udSource')
	alter table bGLBC add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBC') and name='udConv')
	alter table bGLBC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBC') and name='udCGCTable')
	alter table bGLBC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBC') and name='udCGCTableID')
	alter table bGLBC add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBD') and name='udSource')
	alter table bGLBD add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBD') and name='udConv')
	alter table bGLBD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBD') and name='udCGCTable')
	alter table bGLBD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLBD') and name='udCGCTableID')
	alter table bGLBD add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLDT') and name='udSource')
	alter table bGLDT add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLDT') and name='udConv')
	alter table bGLDT add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLDT') and name='udCGCTable')
	alter table bGLDT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLDT') and name='udCGCTableID')
	alter table bGLDT add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLFY') and name='udSource')
	alter table bGLFY add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLFY') and name='udConv')
	alter table bGLFY add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLFY') and name='udCGCTable')
	alter table bGLFY add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLFY') and name='udCGCTableID')
	alter table bGLFY add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLPI') and name='udSource')
	alter table bGLPI add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLPI') and name='udConv')
	alter table bGLPI add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLPI') and name='udCGCTable')
	alter table bGLPI add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLPI') and name='udCGCTableID')
	alter table bGLPI add udCGCTableID decimal(12,0)  null;
					
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLYB') and name='udSource')
	alter table bGLYB add udSource varchar(305) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLYB') and name='udConv')
	alter table bGLYB add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLYB') and name='udCGCTable')
	alter table bGLYB add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bGLYB') and name='udCGCTableID')
	alter table bGLYB add udCGCTableID decimal(12,0)  null;
			
	/** JB Job Billing **/	
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCC') and name='udSource')
	alter table bJBCC add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCC') and name='udConv')
	alter table bJBCC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCC') and name='udCGCTable')
	alter table bJBCC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCC') and name='udCGCTableID')
	alter table bJBCC add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCX') and name='udSource')
	alter table bJBCX add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCX') and name='udConv')
	alter table bJBCX add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCX') and name='udCGCTable')
	alter table bJBCX add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBCX') and name='udCGCTableID')
	alter table bJBCX add udCGCTableID decimal(12,0)  null;
					
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIN') and name='udSource')
	alter table bJBIN add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIN') and name='udConv')
	alter table bJBIN add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIN') and name='udCGCTable')
	alter table bJBIN add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIN') and name='udCGCTableID')
	alter table bJBIN add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIS') and name='udSource')
	alter table bJBIS add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIS') and name='udConv')
	alter table bJBIS add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIS') and name='udCGCTable')
	alter table bJBIS add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIS') and name='udCGCTableID')
	alter table bJBIS add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIT') and name='udSource')
	alter table bJBIT add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIT') and name='udConv')
	alter table bJBIT add udConv varchar(1) null	

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIT') and name='udCGCTable')
	alter table bJBIT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJBIT') and name='udCGCTableID')
	alter table bJBIT add udCGCTableID decimal(12,0)  null;
		
	/** JC Job Cost **/
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCD') and name='udSource')
	alter table bJCCD add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCD') and name='udConv')
	alter table bJCCD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCD') and name='udCGCTable')
	alter table bJCCD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCD') and name='udCGCTableID')
	alter table bJCCD add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCH') and name='udSource')
	alter table bJCCH add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCH') and name='udConv')
	alter table bJCCH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCH') and name='udCGCTable')
	alter table bJCCH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCH') and name='udCGCTableID')
	alter table bJCCH add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCI') and name='udSource')
	alter table bJCCI add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCI') and name='udConv')
	alter table bJCCI add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCI') and name='udCGCTable')
	alter table bJCCI add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCI') and name='udCGCTableID')
	alter table bJCCI add udCGCTableID decimal(12,0)  null;
					
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCM') and name='udSource')
	alter table bJCCM add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCM') and name='udConv')
	alter table bJCCM add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCM') and name='udCGCTable')
	alter table bJCCM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCM') and name='udCGCTableID')
	alter table bJCCM add udCGCTableID decimal(12,0)  null;
							
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCP') and name='udSource')
	alter table bJCCP add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCP') and name='udConv')
	alter table bJCCP add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCP') and name='udCGCTable')
	alter table bJCCP add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCCP') and name='udCGCTableID')
	alter table bJCCP add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCID') and name='udSource')
	alter table bJCID add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCID') and name='udConv')
	alter table bJCID add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCID') and name='udCGCTable')
	alter table bJCID add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCID') and name='udCGCTableID')
	alter table bJCID add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCIP') and name='udSource')
	alter table bJCIP add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCIP') and name='udConv')
	alter table bJCIP add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCIP') and name='udCGCTable')
	alter table bJCIP add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCIP') and name='udCGCTableID')
	alter table bJCIP add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJM') and name='udSource')
	alter table bJCJM add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJM') and name='udConv')
	alter table bJCJM add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJM') and name='udCGCTable')
	alter table bJCJM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJM') and name='udCGCTableID')
	alter table bJCJM add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJP') and name='udSource')
	alter table bJCJP add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJP') and name='udConv')
	alter table bJCJP add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJP') and name='udCGCTable')
	alter table bJCJP add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCJP') and name='udCGCTableID')
	alter table bJCJP add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOD') and name='udSource')
	alter table bJCOD add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOD') and name='udConv')
	alter table bJCOD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOD') and name='udCGCTable')
	alter table bJCOD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOD') and name='udCGCTableID')
	alter table bJCOD add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOH') and name='udSource')
	alter table bJCOH add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOH') and name='udConv')
	alter table bJCOH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOH') and name='udCGCTable')
	alter table bJCOH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOH') and name='udCGCTableID')
	alter table bJCOH add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOI') and name='udSource')
	alter table bJCOI add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOI') and name='udConv')
	alter table bJCOI add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOI') and name='udCGCTable')
	alter table bJCOI add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCOI') and name='udCGCTableID')
	alter table bJCOI add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCMP') and name='udSource')
	alter table bJCMP add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCMP') and name='udConv')
	alter table bJCMP add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCMP') and name='udCGCTable')
	alter table bJCMP add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCMP') and name='udCGCTableID')
	alter table bJCMP add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPC') and name='udSource')
	alter table bJCPC add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPC') and name='udConv')
	alter table bJCPC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPC') and name='udCGCTable')
	alter table bJCPC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPC') and name='udCGCTableID')
	alter table bJCPC add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPM') and name='udSource')
	alter table bJCPM add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPM') and name='udConv')
	alter table bJCPM add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPM') and name='udCGCTable')
	alter table bJCPM add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bJCPM') and name='udCGCTableID')
	alter table bJCPM add udCGCTableID decimal(12,0)  null;			
	
	/** PM Project Management **/
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOH') and name='udSource')
	alter table bPMOH add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOH') and name='udConv')
	alter table bPMOH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOH') and name='udCGCTable')
	alter table bPMOH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOH') and name='udCGCTableID')
	alter table bPMOH add udCGCTableID decimal(12,0)  null;		
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOI') and name='udSource')
	alter table bPMOI add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOI') and name='udConv')
	alter table bPMOI add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOI') and name='udCGCTable')
	alter table bPMOI add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOI') and name='udCGCTableID')
	alter table bPMOI add udCGCTableID decimal(12,0)  null;	
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOL') and name='udSource')
	alter table bPMOL add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOL') and name='udConv')
	alter table bPMOL add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOL') and name='udCGCTable')
	alter table bPMOL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMOL') and name='udCGCTableID')
	alter table bPMOL add udCGCTableID decimal(12,0)  null;	
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMSL') and name='udSource')
	alter table bPMSL add udSource varchar(30) null
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMSL') and name='udConv')
	alter table bPMSL add udConv varchar(1) null
		
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPMSL') and name='udSLContractNo')
	alter table bPMSL add udSLContractNo varchar(15)  null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPMSL') and name='udCMSItem')
	alter table bPMSL add udCMSItem varchar(10)  null;

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMSL') and name='udCGCTable')
	alter table bPMSL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPMSL') and name='udCGCTableID')
	alter table bPMSL add udCGCTableID decimal(12,0)  null;	
		
	/** PR Payroll **/
		/************PRDT******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRDT') and name='udPaidDate')
	alter table bPRDT add udPaidDate smalldatetime null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDT') and name='udSource')
	alter table bPRDT add udSource varchar(30) null
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDT') and name='udConv')
	alter table bPRDT add udConv varchar(1) null
	
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRDT') and name='udCMCo')
	alter table bPRDT add udCMCo tinyint null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRDT') and name='udCMAcct')
	alter table bPRDT add udCMAcct int null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRDT') and name='udCMRef')
	alter table bPRDT add udCMRef varchar(15) null;

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDT') and name='udCGCTable')
	alter table bPRDT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDT') and name='udCGCTableID')
	alter table bPRDT add udCGCTableID decimal(12,0)  null;	
		
	/************PREH******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPREH') and name='udOrigHireDate')
	alter table bPREH add udOrigHireDate smalldatetime null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPREH') and name='udEmpGroup')
	alter table bPREH add udEmpGroup varchar(25) null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREH') and name='udSource')
	alter table bPREH add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREH') and name='udConv')
	alter table bPREH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREH') and name='udCGCTable')
	alter table bPREH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREH') and name='udCGCTableID')
	alter table bPREH add udCGCTableID decimal(12,0)  null;	
			
	/************PRTH******************/
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udPaidDate')
	alter table bPRTH add udPaidDate smalldatetime null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udCMCo')
	alter table bPRTH add udCMCo tinyint null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udCMAcct')
	alter table bPRTH add udCMAcct int null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udCMRef')
	alter table bPRTH add udCMRef varchar(15) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udTCSource')
	alter table bPRTH add udTCSource varchar(4) null;

	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRTH') and name='udSchool')
	alter table bPRTH add udSchool smallint null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTH') and name='udSource')
	alter table bPRTH add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTH') and name='udConv')
	alter table bPRTH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTH') and name='udCGCTable')
	alter table bPRTH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTH') and name='udCGCTableID')
	alter table bPRTH add udCGCTableID decimal(12,0)  null;
				
	/************PR OTHER******************/	
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAE') and name='udSource')
	alter table bPRAE add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAE') and name='udConv')
	alter table bPRAE add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAE') and name='udCGCTable')
	alter table bPRAE add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAE') and name='udCGCTableID')
	alter table bPRAE add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAF') and name='udSource')
	alter table bPRAF add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAF') and name='udConv')
	alter table bPRAF add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAF') and name='udCGCTable')
	alter table bPRAF add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRAF') and name='udCGCTableID')
	alter table bPRAF add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bPRCA') and name='udRate')
	alter table bPRCA add udRate decimal(5,3) null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCA') and name='udSource')
	alter table bPRCA add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCA') and name='udConv')
	alter table bPRCA add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCA') and name='udCGCTable')
	alter table bPRCA add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCA') and name='udCGCTableID')
	alter table bPRCA add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCX') and name='udSource')
	alter table bPRCX add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCX') and name='udConv')
	alter table bPRCX add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCX') and name='udCGCTable')
	alter table bPRCX add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRCX') and name='udCGCTableID')
	alter table bPRCX add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDD') and name='udSource')
	alter table bPRDD add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDD') and name='udConv')
	alter table bPRDD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDD') and name='udCGCTable')
	alter table bPRDD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRDD') and name='udCGCTableID')
	alter table bPRDD add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREA') and name='udSource')
	alter table bPREA add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREA') and name='udConv')
	alter table bPREA add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREA') and name='udCGCTable')
	alter table bPREA add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREA') and name='udCGCTableID')
	alter table bPREA add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRED') and name='udSource')
	alter table bPRED add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRED') and name='udConv')
	alter table bPRED add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRED') and name='udCGCTable')
	alter table bPRED add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRED') and name='udCGCTableID')
	alter table bPRED add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREL') and name='udSource')
	alter table bPREL add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREL') and name='udConv')
	alter table bPREL add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREL') and name='udCGCTable')
	alter table bPREL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPREL') and name='udCGCTableID')
	alter table bPREL add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRIA') and name='udSource')
	alter table bPRIA add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRIA') and name='udConv')
	alter table bPRIA add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRIA') and name='udCGCTable')
	alter table bPRIA add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRIA') and name='udCGCTableID')
	alter table bPRIA add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRLH') and name='udSource')
	alter table bPRLH add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRLH') and name='udConv')
	alter table bPRLH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRLH') and name='udCGCTable')
	alter table bPRLH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRLH') and name='udCGCTableID')
	alter table bPRLH add udCGCTableID decimal(12,0)  null;
					
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPC') and name='udSource')
	alter table bPRPC add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPC') and name='udConv')
	alter table bPRPC add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPC') and name='udCGCTable')
	alter table bPRPC add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPC') and name='udCGCTableID')
	alter table bPRPC add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPH') and name='udSource')
	alter table bPRPH add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPH') and name='udConv')
	alter table bPRPH add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPH') and name='udCGCTable')
	alter table bPRPH add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPH') and name='udCGCTableID')
	alter table bPRPH add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPS') and name='udSource')
	alter table bPRPS add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPS') and name='udConv')
	alter table bPRPS add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPS') and name='udCGCTable')
	alter table bPRPS add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRPS') and name='udCGCTableID')
	alter table bPRPS add udCGCTableID decimal(12,0)  null;
				
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRSQ') and name='udSource')
	alter table bPRSQ add udSource varchar(30) null		

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRSQ') and name='udConv')
	alter table bPRSQ add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRSQ') and name='udCGCTable')
	alter table bPRSQ add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRSQ') and name='udCGCTableID')
	alter table bPRSQ add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTL') and name='udSource')
	alter table bPRTL add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTL') and name='udConv')
	alter table bPRTL add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTL') and name='udCGCTable')
	alter table bPRTL add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPRTL') and name='udCGCTableID')
	alter table bPRTL add udCGCTableID decimal(12,0)  null;
		
	/** PO Purchase Order **/

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOCD') and name='udSource')
	alter table bPOCD add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOCD') and name='udConv')
	alter table bPOCD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOCD') and name='udCGCTable')
	alter table bPOCD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOCD') and name='udCGCTableID')
	alter table bPOCD add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOHD') and name='udSource')
	alter table bPOHD add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOHD') and name='udConv')
	alter table bPOHD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOHD') and name='udCGCTable')
	alter table bPOHD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOHD') and name='udCGCTableID')
	alter table bPOHD add udCGCTableID decimal(12,0)  null;
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOIT') and name='udSource')
	alter table bPOIT add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOIT') and name='udConv')
	alter table bPOIT add udConv varchar(1) null		

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOIT') and name='udCGCTable')
	alter table bPOIT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bPOIT') and name='udCGCTableID')
	alter table bPOIT add udCGCTableID decimal(12,0)  null;
	
		/** SL Subcontract Ledger**/
		
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLCD') and name='udSource')
	alter table bSLCD add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLCD') and name='udConv')
	alter table bSLCD add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLCD') and name='udCGCTable')
	alter table bSLCD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLCD') and name='udCGCTableID')
	alter table bSLCD add udCGCTableID decimal(12,0)  null;
			
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bSLHD') and name='udSLContractNo')
	alter table bSLHD add udSLContractNo varchar(15)  null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLHD') and name='udSource')
	alter table bSLHD add udSource varchar(30) null
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLHD') and name='udConv')
	alter table bSLHD add udConv varchar(1) null	

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLHD') and name='udCGCTable')
	alter table bSLHD add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLHD') and name='udCGCTableID')
	alter table bSLHD add udCGCTableID decimal(12,0)  null;
	
	if not exists (select name from syscolumns 
	  where id=OBJECT_ID('bSLIT') and name='udSLContractNo')
	alter table bSLIT add udSLContractNo varchar(15)  null;
	
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLIT') and name='udSource')
	alter table bSLIT add udSource varchar(30) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLIT') and name='udConv')
	alter table bSLIT add udConv varchar(1) null

	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLIT') and name='udCGCTable')
	alter table bSLIT add udCGCTable varchar(10)  null;
			
	if not exists (select name from syscolumns	
		where id=OBJECT_ID('bSLIT') and name='udCGCTableID')
	alter table bSLIT add udCGCTableID decimal(12,0)  null;	
GO
