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
	Title:		Convert all EM tables (master and transaction)
	Created:	10.14.09
	Created by:	CR
	Revisions:	
		1. 03/19/2012 BBA - Corrected sp name above. 
*/


CREATE PROCEDURE [dbo].[cvsp_CMS_10_Convert_EM] 
(@fromco smallint, @toco smallint)
AS

/* Step 1 of 3: if using the counter below rem this line out */

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

--EMCO
if not exists (select 1 from bEMCO where EMCo=@toco)
Begin
	select @errmsg='EMCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_EM',@fromco, @toco, 0, @errmsg
	return (1)
End

--JCCO
if not exists (select 1 from bJCCO where JCCo=@toco)
Begin
	select @errmsg='JCCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_EM',@fromco, @toco, 0, @errmsg
	return (1)
End

--APCO
if not exists (select 1 from bAPCO where APCo=@toco)
Begin
	select @errmsg='APCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_EM',@fromco, @toco, 0, @errmsg
	return (1)
End

--PRCO
if not exists (select 1 from bPRCO where PRCo=@toco)
Begin
	select @errmsg='PRCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_EM',@fromco, @toco, 0, @errmsg
	return (1)
End


--EM Equipment
exec @rc=dbo.cvsp_CMS_MASTER_EMEM  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_EMEM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_EMEM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--EM Location History
exec @rc=dbo.cvsp_CMS_EMLH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMLH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMLH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

/*  NEED EMRR information */
--EM Category Revenue
exec @rc=dbo.cvsp_CMS_EMBG  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMBG',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMBG',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--EM Category Revenue
exec @rc=dbo.cvsp_CMS_EMCM  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMCM',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMCM',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Rates by Category
exec @rc=dbo.cvsp_CMS_EMRR  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMRR',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMRR',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Rates by Equipment
exec @rc=dbo.cvsp_CMS_EMRH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMRH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMRH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Meter Readings
exec @rc=dbo.cvsp_CMS_EMMR  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMMR',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMMR',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Revenue Detail
exec @rc=dbo.cvsp_CMS_EMRD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMRD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMRD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Cost Detail
exec @rc=dbo.cvsp_CMS_EMCD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMCD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMCD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Monthly Costs
exec @rc=dbo.cvsp_CMS_EMMC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMMC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMMC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--EM Asset Master
exec @rc=dbo.cvsp_CMS_EMDP  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMDP',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMDP',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Depr Schedule
exec @rc=dbo.cvsp_CMS_EMDS  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMDS',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMDS',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--EM Depr Schedule Calculate
exec @rc=dbo.cvsp_CMS_EMDSFill_Cursor  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_EMDSFill_Cursor',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_EMDSFill_Cursor',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


/*************************		End Task:	Execute GL Stored Procedures	*************************/
--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/


-- to be on safe side re-enable all SL/JC/AP triggers
alter table bEMEM enable trigger all;
alter table bEMCD enable trigger all;
alter table bEMRD enable trigger all;
alter table bEMMR enable trigger all;
alter table bEMDP enable trigger all;
alter table bEMDS enable trigger all;
alter table bEMMC enable trigger all;

return @@error





GO
