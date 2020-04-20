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
	Title:		Convert all PR tables (master and transaction)
	Created:	10.27.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
*/



CREATE PROCEDURE [dbo].[cvsp_CMS_7_Convert_PR] 
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

--PRCO
if not exists (select 1 from bPRCO where PRCo=@toco)
Begin
	select @errmsg='PRCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_PR',@fromco, @toco, 0, @errmsg
	return (1)
End


--Add columns/indexes
exec @rc= dbo.cvsp_CMS_PR_AddColsIndexes @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_AddColsIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update Source Tables
exec @rc= dbo.cvsp_CMS_PR_UpdateSource @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_UpdateSource',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Employees
exec @rc=dbo.cvsp_CMS_MASTER_PREH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_PREH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_PREH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Employee Deductions
exec @rc=dbo.cvsp_CMS_MASTER_PRED  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_PRED',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_PRED',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Employee Add'l Direct Deposit
exec @rc=dbo.cvsp_CMS_MASTER_PRDD  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_MASTER_PRDD',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_MASTER_PRDD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Auto Earnings (PRAE)
exec @rc=dbo.cvsp_CMS_PRAE  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRAE',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRAE',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Regular Timecards
exec @rc=dbo.cvsp_CMS_PRTH_Regular  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_Regular',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_Regular',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Overtime Timecards
exec @rc=dbo.cvsp_CMS_PRTH_OT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_OT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_OT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Other Timecards
exec @rc=dbo.cvsp_CMS_PRTH_Other  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_Other',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_Other',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Adj Timecards
exec @rc=dbo.cvsp_CMS_PRTH_Adj  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_Adj',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_Adj',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Negative Timecards
exec @rc=dbo.cvsp_CMS_PRTH_Neg  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_Neg',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_Neg',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Benefit Timecards
exec @rc=dbo.cvsp_CMS_PRTH_Ben  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_Ben',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_Ben',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--PR Pay Period Control
exec @rc=dbo.cvsp_CMS_PRPC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRPC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRPC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PRDT - Earnings - Pulls from PRTH
exec @rc=dbo.cvsp_CMS_PRDT_Earnings  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRDT_Earnings',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRDT_Earnings',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PRDT - Builds table to hold ded/liab before subj/elig calculated
exec @rc=dbo.cvsp_CMS_PR_DedLiabTable  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_DedLiabTable',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_DedLiabTable',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Deduction/Liability Subject and Eligible Amounts
exec @rc=dbo.cvsp_CMS_PR_DedLiabSubjElig  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_DedLiabSubjElig',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_DedLiabSubjElig',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PRDT - Insert Ded/Liab
exec @rc=dbo.cvsp_CMS_PRDT_DedLiab  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRDT_DedLiab',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRDT_DedLiab',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Employee Pay Sequence (PRSQ)
exec @rc=dbo.cvsp_CMS_PRSQ  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRSQ',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRSQ',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Employee Accumulations (PREA)
exec @rc=dbo.cvsp_CMS_PREA  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PREA',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PREA',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Timecards - $0 - pay periods exist in PRDT that may not exist in PRTH.
exec @rc=dbo.cvsp_CMS_PRTH_ZeroTC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRTH_ZeroTC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_ZeroTC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Timecards cleanup (removes phases when no job exists)
exec @rc=dbo.cvsp_CMS_PRTH_UpdateTC  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'ccvsp_CMS_PRTH_UpdateTC',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRTH_UpdateTC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--PR Payment History (PRPH)
exec @rc=dbo.cvsp_CMS_PRPH  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRPH',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRPH',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Insurance accumulations (PRIA)
exec @rc=dbo.cvsp_CMS_PRIA  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRIA',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRIA',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Craft Accumulations
exec @rc=dbo.cvsp_CMS_PRCA  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRCA',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRCA',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--PR Craft Accumulations Detail
exec @rc=dbo.cvsp_CMS_PRCX  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRCX',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRCX',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

/* WB doesn't use leave so those have not been converted to stds yet.  
--PR Leave (PRLEAVEHISTORY)
--PR Leave History (PRLEAVEHISTORY2)
--Rebuild PR Security
*/

--Rebuild PR Security
exec @rc=dbo.cvsp_CMS_PRSecurity  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PRSecurity',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PRSecurity',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--PR Rebuild Indexes
exec @rc=dbo.cvsp_CMS_PR_RebuildIndexes  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_RebuildIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_RebuildIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/

-- to be on safe side re-enable all PR triggers
alter table bPREH enable trigger all;
alter table bPRED enable trigger all;
alter table bPRDD enable trigger all;
alter table bPRAE enable trigger all;
alter table bPRTH enable trigger all;
alter table bPRPC enable trigger all;
alter table bPRDT enable trigger all;
alter table bPRSQ enable trigger all;
alter table bPREA enable trigger all;
alter table bPRPS enable trigger all;
alter table bPRTL enable trigger all;
alter table bPRPH enable trigger all;
alter table bPRIA enable trigger all;
alter table bPRCA enable trigger all;
alter table bPRCX enable trigger all;
alter table bPRGS enable trigger all;

return @@error



GO
