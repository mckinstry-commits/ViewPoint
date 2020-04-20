SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**
=========================================================================
Copyright © 2012 Viewpoint Construction Software (VCS)
The TSQL code in this procedure may not be reproduced, copied, modified,
or executed without written consent from VCS.
=========================================================================
	Title:		Convert all JC tables (master and transaction)
	Created:	10.15.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
			
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_6_Convert_JC] 
(@fromco smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */
as
declare @errmsg varchar(1000), @rowcount int, @rc int

--  Step 2 of 3
--  un-rem this section if you would like to use a counter for multiple company, 2nd section at bottom of code also  
--  and a multi company xref will need to be created dbo.budXRefCompany(Fromco, Toco, Seq)

--declare @counter int, @toco smallint, @fromco smallint
--set @counter = 1
--while (@counter <= (select MAX(Seq) from  dbo.budXRefGLCompany))
--begin
--      select @toco = Toco, @fromco=Fromco from  dbo.budXRefGLCompany where  Seq = @counter;

--select @counter , @toco, @fromco;






if not exists(select name from sysobjects where name='cvLog')
create table cvLog(ProcDate smalldatetime null, ProcName varchar(50) null,
	FromCo smallint null, ToCo smallint null,
	RowsConvert int null, ErrMsg varchar(1000) null); 

--PMCO
if not exists (select 1 from bPMCO where PMCo=@toco)
Begin
	select @errmsg='PMCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_JC',@fromco, @toco, 0, @errmsg
	return (1)
End

--JCCO
if not exists (select 1 from bJCCO where JCCo=@toco)
Begin
	select @errmsg='JCCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_JC',@fromco, @toco, 0, @errmsg
	return (1)
End


--JC Columns and Indexes needed for conversion
exec @rc=dbo.cvsp_CMS_JC_AddColsIndexes  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_AddColsIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----CMS CO Types 
--exec @rc=dbo.cvsp_CMS_COTypes  @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_COTypes',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_COTypes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
/*
--Phase Cross-references
exec @rc=dbo.cvsp_CMS_XREF_Phase  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_XREF_Phase',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_XREF_Phase',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
*/
--JC Contracts (JCCM)
exec @rc=dbo.cvsp_CMS_MASTER_JCCM  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Contract Items (JCCI)
exec @rc=dbo.cvsp_CMS_MASTER_JCCI  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCI',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCI',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Project Manager (JCMP)
exec @rc=dbo.cvsp_CMS_MASTER_JCMP  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCMP',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCMP',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Job Master (JCJM)
exec @rc=dbo.cvsp_CMS_MASTER_JCJM  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCJM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCJM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Job Phases (JCJP)
exec @rc=dbo.cvsp_CMS_MASTER_JCJP  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCJP',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCJP',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Phase Master (JCPM)
--exec @rc=dbo.cvsp_CMS_MASTER_JCPM  @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_JCPM',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_JCPM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Original Job Estimates (JCCH)
exec @rc=dbo.cvsp_CMS_MASTER_JCCH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Original Job Estimates to JCCD 
exec @rc=dbo.cvsp_CMS_JC_JCCD_OrigEst  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_JCCD_OrigEst',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_JCCD_OrigEst',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Change Orders Temp Table
exec @rc=dbo.cvsp_CMS_JCChangeOrderTempTable  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCChangeOrderTempTable',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCChangeOrderTempTable',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCID
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Change Orders (JCOH/JCOI/JCOD and PMOH/PMOI/PMOL)
exec @rc=dbo.cvsp_CMS_JCChangeOrders  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCChangeOrders',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCChangeOrders',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCID
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Detail (JCCD)
exec @rc=dbo.cvsp_CMS_JCCD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Detail - Actual Units
exec @rc=dbo.cvsp_CMS_JCCD_ActUnits  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCD_ActUnits',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCD_ActUnits',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Cost by Period (JCCP)
exec @rc=dbo.cvsp_CMS_JCCP  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCP',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCP',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Item Revenue by Period (JCIP)
exec @rc=dbo.cvsp_CMS_JCIP  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCIP',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCIP',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update Amounts on JCCM/JCCI that need to show the detailed amounts
--Triggers would typically update these tables but triggers are turned off during inserts.
exec @rc=dbo.cvsp_CMS_JCUpdate  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCUpdate',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCUpdate',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Original Estimates - updated with phase/ct's from JCCD that are not in JCCH
exec @rc=dbo.cvsp_CMS_JCCH_ZeroEst  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCH_ZeroEst',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCH_ZeroEst',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Phase Cost Types
exec @rc=dbo.cvsp_CMS_MASTER_JCPC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCPC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCPC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Item/Phase Units flags
exec @rc=dbo.cvsp_CMS_JC_UnitFlags  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_UnitFlags',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_UnitFlags',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Rebuild Indexes
exec @rc=dbo.cvsp_CMS_JC_RebuildIndexes  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_RebuildIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_RebuildIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop

--      set @counter = @counter + 1
--end


-- to be on safe side re-enable all SL/JC/AP triggers
alter table bJCCM enable trigger all;
alter table bJCCI enable trigger all;
alter table bJCMP enable trigger all;
alter table bJCJM enable trigger all;
alter table bJCJP enable trigger all;
alter table bJCPC enable trigger all;
alter table bJCPM enable trigger all;
alter table bJCCH enable trigger all;
alter table bJCOH enable trigger all;
alter table bJCOI enable trigger all;
alter table bJCOD enable trigger all;
alter table bPMOH enable trigger all;
alter table bPMOI enable trigger all;
alter table bPMOL enable trigger all;
alter table bJCID enable trigger all;
alter table bJCCD enable trigger all;
alter table bJCIP enable trigger all;
alter table bJCCP enable trigger all;

return @@error

GO
