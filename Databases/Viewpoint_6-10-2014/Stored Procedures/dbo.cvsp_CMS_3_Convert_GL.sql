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
	Title:		Convert all GL tables (master and transaction)
	Created:	10.14.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
	EXEC cvsp_CMS_3_Convert_GL 2014,1,15,50,1
*/

CREATE proc [dbo].[cvsp_CMS_3_Convert_GL] 
(@lFiscalYear int,@fromco1 smallint, @fromco2 smallint, @fromco3 smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */

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

--GLCO
if not exists (select 1 from bGLCO where GLCo=@toco)
Begin
	select @errmsg='GLCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_GL',@fromco1, @toco, 0, @errmsg
	return (1)
End

/*
--Xref GL Accounts
exec @rc= dbo.cvsp_CMS_XREF_GL @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_XREF_GL',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_XREF_GL',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Xref GL Account Types
exec @rc= dbo.cvsp_CMS_XREF_GLAcctType @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_XREF_GLAcctType',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_XREF_GLAcctType',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----Create Journal type table
--exec @rc= dbo.cvsp_CMS_GLJournalTypes_WB @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_GLJournalTypes_WB',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_GLJournalTypes_WB',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
*/
--GL Add Columns/Indexes
exec @rc= dbo.cvsp_CMS_GL_AddColsIndexes @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_AddColsIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_AddColsIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Update Source Tables 
exec @rc= dbo.cvsp_CMS_GL_UpdateSource @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_UpdateSource',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_UpdateSource',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Disable Foreign Keys
exec @rc = dbo.cvsp_Disable_Foreign_Keys;

----GL Chart of Accounts (GLAC)
--exec @rc= dbo.cvsp_CMS_MASTER_GLAC @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_GLAC',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_GLAC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----GL Account Parts
--exec @rc=cvsp_CMS_MASTER_GLPI @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_GLPI',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_GLPI',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Fiscal Years (GLFY)
--exec @rc= dbo.cvsp_CMS_MASTER_GLFY @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_GLFY',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_GLFY',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

/* NO idea if Mckinstry is converting GL Budgets */
----GL Budget Codes (GLBC)
--exec @rc= dbo.cvsp_CMS_MASTER_GLBC @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_GLBC',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_GLBC',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----GL Budgets 
--exec @rc= dbo.cvsp_CMS_MASTER_GLBD @fromco, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_MASTER_GLBD',@fromco, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_MASTER_GLBD',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Beginning Balances 
--declare @rc varchar(50),@fromco1 int = 1,@fromco2 int = 15,@fromco3 int = 50,@toco int = 1,@errmsg varchar(1000) = '',@rowcount int = 0
exec @rc= dbo.cvsp_CMS_GLYB @lFiscalYear,@fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLYB',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLYB',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Reset HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Detail
exec @rc= dbo.cvsp_CMS_GLDT @lFiscalYear,@fromco1,@fromco2,@fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLDT',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLDT',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Account Summary (GLAS)
exec @rc= dbo.cvsp_CMS_GLAS @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLAS',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLAS',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Rebuild Indexes
exec @rc= dbo.cvsp_CMS_GL_RebuildIndexes @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_RebuildIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_RebuildIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;



/*************************		End Task:	Execute GL Stored Procedures	*************************/
--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/

--Enable foreign keys
exec @rc = dbo.cvsp_Enable_Foreign_Keys;

-- to be on safe side re-enable all SL/JC/AP triggers
alter table bGLBC enable trigger all;
alter table bGLBD enable trigger all;
alter table bGLAC enable trigger all;
alter table bGLDT enable trigger all;
alter table bGLAS enable trigger all;
alter table bGLBL enable trigger all;
alter table bGLYB enable trigger all;
alter table bGLFY enable trigger all;
alter table bGLRF enable trigger all;
alter table bGLPI enable trigger all;

return @@error












GO
