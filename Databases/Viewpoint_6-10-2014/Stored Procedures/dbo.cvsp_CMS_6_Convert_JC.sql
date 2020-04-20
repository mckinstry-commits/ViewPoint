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
	
	EXEC cvsp_CMS_6_Convert_JC 1,15,50,1,'N'
			
**/

CREATE PROCEDURE [dbo].[cvsp_CMS_6_Convert_JC] 
	( @fromco1	smallint
	, @fromco2	smallint
	, @fromco3	smallint
	, @toco		smallint
	, @Delete	varchar(1)
	) /* Step 1 of 3: if using the counter below rem this line out */
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
	select getdate(),'cvsp_CMS_Convert_JC',@fromco1, @toco, 0, @errmsg
	return (1)
End

--JCCO
if not exists (select 1 from bJCCO where JCCo=@toco)
Begin
	select @errmsg='JCCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_JC',@fromco1, @toco, 0, @errmsg
	return (1)
End


--JC Columns and Indexes needed for conversion
exec @rc=dbo.cvsp_CMS_JC_AddColsIndexes  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_AddColsIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_AddColsIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

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


--Disable foreign keys
exec @rc = dbo.cvsp_Disable_Foreign_Keys;

--JC Contracts (JCCM)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCCM  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCM',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCM',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Contract Items (JCCI)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCCI  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCI',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCI',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Project Manager (JCMP)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCMP  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCMP',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCMP',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Job Master (JCJM)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCJM  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCJM',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCJM',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PM Project Addons (bPMPA)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_PMPA  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_PMPA',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_PMPA',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Job Phases (JCJP)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCJP  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCJP',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCJP',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

/*
--JC Phase Master (JCPM)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCPM  @fromco, @toco,@Delete, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCPM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCPM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
*/

--JC Original Job Estimates (JCCH)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCCH  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCCH',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCCH',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Original Job Estimates to JCCD 
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JC_JCCD_OrigEst  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_JCCD_OrigEst',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_JCCD_OrigEst',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Change Orders Temp Table
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCChangeOrderTempTable_custom  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCChangeOrderTempTable',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCChangeOrderTempTable',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCID
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Change Orders (JCOH/JCOI/JCOD and PMOH/PMOI/PMOL)
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCChangeOrders  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCChangeOrders',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCChangeOrders',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCID
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Detail (JCCD)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCCD  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCD',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCD',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Detail - Actual Units
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCCD_ActUnits  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCD_ActUnits',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCD_ActUnits',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC - JCCD
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCCD_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCCD_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Cost by Period (JCCP)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCCP  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCP',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCP',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Item Revenue by Period (JCIP)
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCIP  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCIP',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCIP',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update Amounts on JCCM/JCCI that need to show the detailed amounts
--Triggers would typically update these tables but triggers are turned off during inserts.
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCUpdate  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCUpdate',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCUpdate',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Original Estimates - updated with phase/ct's from JCCD that are not in JCCH
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JCCH_ZeroEst  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JCCH_ZeroEst',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JCCH_ZeroEst',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Phase Cost Types
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_MASTER_JCPC  @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_JCPC',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_JCPC',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Item/Phase Units flags
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JC_UnitFlags  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_UnitFlags',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_UnitFlags',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Overrides
--declare @rc varchar(100),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JC_Overides @fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_Overrides',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_Overrides',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--JC Rebuild Indexes
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec @rc=dbo.cvsp_CMS_JC_RebuildIndexes  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_JC_RebuildIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_JC_RebuildIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
--declare @rc varchar(100),@fromco int = 20,@toco int = 20, @errmsg varchar(1000) = '',@rowcount int = 0
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop

--      set @counter = @counter + 1
--end

--Enable foreign keys
exec @rc = dbo.cvsp_Enable_Foreign_Keys;


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
