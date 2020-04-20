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
			
	EXEC cvsp_CMS_5_Convert_AP 1,15,50,1
*/


CREATE PROCEDURE [dbo].[cvsp_CMS_5_Convert_AP] 
(@fromco1 smallint,@fromco2 smallint,@fromco3 smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */
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
	--insert into cvLog
	select getdate(),'cvsp_CMS_Convert_AP',@fromco1, @toco, 0, @errmsg
	return (1)
End

--APCO
if not exists (select 1 from bAPCO where APCo=@toco)
Begin
	select @errmsg='APCO is not setup for company'+convert(varchar(3),@toco)
	--insert into cvLog
	select getdate(),'cvsp_CMS_Convert_AP',@fromco1, @toco, 0, @errmsg
	return (1)
End


--Add columns/indexes
exec @rc= dbo.cvsp_CMS_AP_AddColsIndexes @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_AP_AddColsIndexes',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--Add columns/indexes
exec @rc= dbo.cvsp_CMS_PO_AddColsIndexes @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_PO_AddColsIndexes',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update PO Source tables 
exec @rc=dbo.cvsp_CMS_PO_UpdateSource  @fromco1, @toco, @errmsg output, @rowcount output;
----insert into cvLog
select getdate(),'cvsp_CMS_PO_UpdateSource',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_PO_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--Disable foreign keys
exec @rc = dbo.cvsp_Disable_Foreign_Keys;


--AP Vendors
if @toco = 1
begin
	--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
	exec @rc=dbo.cvsp_CMS_MASTER_APVM  @fromco1, @toco, @errmsg output, @rowcount output;
	----insert into cvLog
	select getdate(),'cvsp_CMS_MASTER_APVM',@fromco1, @toco, @rowcount, @errmsg;
	--select getdate(),'cvsp_CMS_MASTER_APVM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
end

--PM Firms
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=cvsp_CMS_MASTER_PMFM_Vend  @fromco1, @toco, @errmsg output, @rowcount output;
----insert into cvLog
select getdate(),'cvsp_CMS_MASTER_PMFM_Vend',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_PMFM_Vend',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Subcontract Detail - Originals
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_PMSL  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
----insert into cvLog
select getdate(),'cvsp_CMS_PMSL',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_PMSL',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Subcontract Detail - Change Orders
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_PMSL_COs  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_PMSL_COs',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_PMSL_COs',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----PM Subcontracts - Assign SL numbers
----declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
--exec @rc=dbo.cvsp_CMS_SLNumbers  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
----insert into cvLog
--select getdate(),'cvsp_CMS_SLNumbers',@fromco1, @toco, @rowcount, @errmsg;
----select getdate(),'cvsp_CMS_SLNumbers',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Items (SLIT)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_SLIT  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_SLIT',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_SLIT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Change Orders (SLCD)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_SLCD  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_SLCD',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_SLCD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for SLCD
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_SLCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_SLCD_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_SLCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

WAITFOR DELAY '00:00:45';

/*****************************/
/*****************************/
/** PURCHASE ORDER TABLES ****/
/*****************************/
/*****************************/
--PO Purchase Order Header
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_POHD  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select GETDATE(), 'cvsp_CMS_POHD', @fromco1, @toco, @rowcount, @errmsg;
--select GETDATE(), 'cvsp_CMS_POHD', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----PO Purchase Order Item
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_POIT  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select GETDATE(), 'cvsp_CMS_POIT', @fromco1, @toco, @rowcount, @errmsg;
--select GETDATE(), 'cvsp_CMS_POIT', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PO Purchase Order Item Lines
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_POItemLine @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select GETDATE(), 'cvsp_CMS_POItemLine', @fromco1, @toco, @rowcount, @errmsg;
--select GETDATE(), 'cvsp_CMS_POItemLine', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PO Purchase Order Change Orders
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_POCD @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select GETDATE(), 'cvsp_CMS_POCD', @fromco1, @toco, @rowcount, @errmsg;
--select GETDATE(), 'cvsp_CMS_POCD', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_POCD_Update @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select GETDATE(), 'cvsp_CMS_HQTC_POCD_Update', @fromco1, @toco, @rowcount, @errmsg;
--select GETDATE(), 'cvsp_CMS_POCD', [FromCo]=@fromco, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

WAITFOR DELAY '00:00:45';

--------------------------------BEGIN AP TABLES --------------------------------

--HQTC Update for APTH
--declare @rc varchar(100),@fromco1 int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update AP Source tables 
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_AP_UpdateSource  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_AP_UpdateSource',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Header (APTH)
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTH  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTH',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for APTH
--declare @rc varchar(100),@fromco1 int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Transaction Lines (APTL)
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTL  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTL',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTL',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
WAITFOR DELAY '00:00:45';
SELECT 'START cvsp_CMS_APTD' PROCSTAT
--AP Transaction Detail (APTD)
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTD  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTD',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
WAITFOR DELAY '00:00:45';
SELECT 'START cvsp_CMS_APTD_Cleared' PROCSTAT
--AP Transaction Detail - Cleared entries(APTD)
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTD_Cleared  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTD_Cleared',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTD_Cleared',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
WAITFOR DELAY '00:00:45';
SELECT 'START cvsp_CMS_APTD_Open' PROCSTAT
--AP Transaction Detail - Open entries(APTD)
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTD_Open  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTD_Open',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTD_Open',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
WAITFOR DELAY '00:00:45';
SELECT 'START cvsp_CMS_APTD_Rounding' PROCSTAT
--AP Transaction Detail - Correct Rounding(APTD)
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APTD_Rounding	@fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APTD_Rounding',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APTD_Rounding',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
WAITFOR DELAY '00:00:45';

--HQTC Update for APTH
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Open Retainge inserts
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_AP_OpenRetainage  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_AP_OpenRetainage',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP_OpenRetainage',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for APTH
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_APTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_APTH_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_APTH_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Hold Codes
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APHD  @fromco1,@fromco2,@fromco3,@toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APHD',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APHD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update Invoice Cost in SLIT
exec @rc=dbo.cvsp_CMS_SLIT_InvCost  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_SLIT_InvCost',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_SLIT_InvCost',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Payment History
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APPH  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APPH',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APPH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
--------------------------------
--AP Payment Detail
--declare @rc varchar(100),@fromco int = 10,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APPD  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APPD',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APPD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Subcontract Status
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_SLStatus  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_SLStatus',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_SLStatus',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--SL Subcontract Committed insert into JCCD
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_SLCmtd_Insert  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_SLCmtd_Insert',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_SLCmtd_Insert',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Committed insert into JCCD
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_APActuals_to_JC  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_APActuals_to_JC',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_APActuals_to_JC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for JCCD
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP 1099 Data
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_AP1099  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_AP1099',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP1099',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Rebuild Indexes
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_AP_RebuildIndexes  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
select getdate(),'cvsp_CMS_AP_RebuildIndexes',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AP_RebuildIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/

--Enable foreign keys
--declare @rc varchar(100),@fromco int = 1,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc = dbo.cvsp_Enable_Foreign_Keys;


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
