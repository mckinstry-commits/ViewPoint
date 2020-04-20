SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Convert all SL/AP tables (master and transaction)
	Created:	10.14.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
*/


CREATE PROCEDURE [dbo].[cvsp_CMS_5_Convert_AP] 
(@fromco smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */
as

declare @errmsg varchar(1000), @rowcount int, @rc int
/*
--  Step 2 of 3
--  un-rem this section if you would like to use a counter for multiple company, 2nd section at bottom of code also  
--  and a multi company xref will need to be created dbo.budXRefCompany(Fromco, Toco, Seq)

declare @counter int, @toco smallint, @fromco smallint
set @counter = 1
while (@counter <= (select MAX(Seq) from  dbo.budXRefCompany))
begin
      select @toco = Toco, @fromco=Fromco from  dbo.budXRefCompany where  Seq = @counter;

select @counter , @toco, @fromco;
*/




if not exists(select name from sysobjects where name='cvLog')
create table cvLog(ProcDate smalldatetime null, ProcName varchar(50) null,
	FromCo smallint null, ToCo smallint null,
	RowsConvert int null, ErrMsg varchar(1000) null); 

--PMCO
if not exists (select 1 from bPMCO where PMCo=@toco)
Begin
	select @errmsg='PMCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_AP',@fromco, @toco, 0, @errmsg
	return (1)
End

--APCO
if not exists (select 1 from bAPCO where APCo=@toco)
Begin
	select @errmsg='APCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_AP',@fromco, @toco, 0, @errmsg
	return (1)
End


--Add columns/indexes
exec @rc= dbo.cvsp_CMS_AP_AddColsIndexes @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP_AddColsIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update PO Source tables 
exec @rc=dbo.cvsp_CMS_PO_UpdateSource  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PO_UpdateSource',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PO_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--AP Vendors
exec @rc=dbo.cvsp_CMS_MASTER_APVM  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_APVM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_APVM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Subcontract Detail - Originals
exec @rc=dbo.cvsp_CMS_PMSL  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PMSL',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PMSL',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Subcontract Detail - Change Orders
exec @rc=dbo.cvsp_CMS_PMSL_COs  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PMSL_COs',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PMSL_COs',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Subcontracts - Assign SL numbers
exec @rc=dbo.cvsp_CMS_SLNumbers  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLNumbers',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLNumbers',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Items (SLIT)
exec @rc=dbo.cvsp_CMS_SLIT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLIT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLIT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Change Orders (SLCD)
exec @rc=dbo.cvsp_CMS_SLCD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLCD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLCD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for SLCD
exec @rc=dbo.cvsp_CMS_HQTC_SLCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_SLCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_SLCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

/** PURCHASE ORDER TABLES **/
--PO Purchase Order Header
exec @rc=dbo.cvsp_CMS_POHD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select GETDATE(), 'cvsp_CMS_POHD', @fromco, @toco, @rowcount, @errmsg;
select GETDATE(), 'cvsp_CMS_POHD', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PO Purchase Order Item
exec @rc=dbo.cvsp_CMS_POIT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select GETDATE(), 'cvsp_CMS_POIT', @fromco, @toco, @rowcount, @errmsg;
select GETDATE(), 'cvsp_CMS_POIT', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PO Purchase Order Item Lines
exec @rc=dbo.cvsp_CMS_POItemLine  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select GETDATE(), 'cvsp_CMS_POItemLine', @fromco, @toco, @rowcount, @errmsg;
select GETDATE(), 'cvsp_CMS_POItemLine', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PO Purchase Order Change Orders
exec @rc=dbo.cvsp_CMS_POCD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select GETDATE(), 'cvsp_CMS_POCD', @fromco, @toco, @rowcount, @errmsg;
select GETDATE(), 'cvsp_CMS_POCD', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--------------------------------BEGIN AP TABLES --------------------------------

--HQTC Update for APTH
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update AP Source tables 
exec @rc=dbo.cvsp_CMS_AP_UpdateSource  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP_UpdateSource',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Header (APTH)
exec @rc=dbo.cvsp_CMS_APTH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for APTH
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Lines (APTL)
exec @rc=dbo.cvsp_CMS_APTL  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTL',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTL',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Detail (APTD)
exec @rc=dbo.cvsp_CMS_APTD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Detail - Cleared entries(APTD)
exec @rc=dbo.cvsp_CMS_APTD_Cleared  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTD_Cleared',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTD_Cleared',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Detail - Open entries(APTD)
exec @rc=dbo.cvsp_CMS_APTD_Open  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTD_Open',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTD_Open',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Detail - Correct Rounding(APTD)
exec @rc=dbo.cvsp_CMS_APTD_Rounding  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APTD_Rounding',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APTD_Rounding',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for APTH
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Open Retainge inserts
exec @rc=dbo.cvsp_CMS_AP_OpenRetainage  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP_OpenRetainage',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP_OpenRetainage',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for APTH
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Hold Codes
exec @rc=dbo.cvsp_CMS_APHD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APHD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APHD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update Invoice Cost in SLIT
exec @rc=dbo.cvsp_CMS_SLIT_InvCost  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLIT_InvCost',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLIT_InvCost',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Payment History
exec @rc=dbo.cvsp_CMS_APPH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APPH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APPH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Payment Detail
exec @rc=dbo.cvsp_CMS_APPD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APPD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APPD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Subcontract Status
exec @rc=dbo.cvsp_CMS_SLStatus  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLStatus',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLStatus',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Subcontract Committed insert into JCCD
exec @rc=dbo.cvsp_CMS_SLCmtd_Insert  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_SLCmtd_Insert',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_SLCmtd_Insert',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Committed insert into JCCD
exec @rc=dbo.cvsp_CMS_APActuals_to_JC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_APActuals_to_JC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_APActuals_to_JC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP 1099 Data
exec @rc=dbo.cvsp_CMS_AP1099  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP1099',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP1099',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Rebuild Indexes
exec @rc=dbo.cvsp_CMS_AP_RebuildIndexes  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP_RebuildIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP_RebuildIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/


-- to be on safe side re-enable all SL/JC/AP triggers
alter table bAPVM enable trigger all;
alter table bPMSL enable trigger all;
alter table bSLHD enable trigger all;
alter table bSLIT enable trigger all;
alter table bSLCD enable trigger all;
alter table bAPTH enable trigger all;
alter table bAPTL enable trigger all;
alter table bAPTD enable trigger all;
alter table bAPPH enable trigger all;
alter table bAPPD enable trigger all;
alter table bJCCD enable trigger all;
alter table bHQTC enable trigger all;
alter table bAPFT enable trigger all;



return @@error
GO
