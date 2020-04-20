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
	
*/

CREATE proc [dbo].[cvsp_CMS_3_Convert_GL] 
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

--GLCO
if not exists (select 1 from bGLCO where GLCo=@toco)
Begin
	select @errmsg='GLCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_GL',@fromco, @toco, 0, @errmsg
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
exec @rc= dbo.cvsp_CMS_GL_AddColsIndexes @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_AddColsIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_AddColsIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Update Source Tables 
exec @rc= dbo.cvsp_CMS_GL_UpdateSource @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_UpdateSource',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_UpdateSource',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

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
exec @rc= dbo.cvsp_CMS_GLYB @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLYB',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLYB',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Reset HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Detail
exec @rc= dbo.cvsp_CMS_GLDT @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLDT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLDT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Account Summary (GLAS)
exec @rc= dbo.cvsp_CMS_GLAS @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GLAS',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GLAS',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--GL Rebuild Indexes
exec @rc= dbo.cvsp_CMS_GL_RebuildIndexes @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_GL_RebuildIndexes',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_GL_RebuildIndexes',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for GLDT
exec @rc= dbo.cvsp_CMS_HQTC_GLDT_Update @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_GLDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;



/*************************		End Task:	Execute GL Stored Procedures	*************************/
--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/



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
