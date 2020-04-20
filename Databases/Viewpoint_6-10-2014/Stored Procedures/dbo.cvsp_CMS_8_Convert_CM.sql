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
	Title:		Convert all CM tables (master and transaction)
	Created:	11.06.09
	Created by:	Viewpoint Technical Services - JJH
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
			
	exec cvsp_CMS_8_Convert_CM 1,1
*/


CREATE PROCEDURE [dbo].[cvsp_CMS_8_Convert_CM]    
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

--CMCO
if not exists (select 1 from bCMCO where CMCo=@toco)
Begin
	select @errmsg='CMCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_Convert_CM',@fromco, @toco, 0, @errmsg
	return (1)
End


--Update HQTC for CMDT
exec @rc=dbo.cvsp_CMS_HQTC_CMDT_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AP Check insert into CMDT
exec @rc=dbo.cvsp_CMS_AP_CMDT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AP_CMDT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AP_CMDT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--HQTC Update for CMDT
exec @rc=dbo.cvsp_CMS_HQTC_CMDT_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update CMDT with AR Receipts
exec @rc=dbo.cvsp_CMS_AR_CMDT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AR_CMDT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AR_CMDT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for CMDT
exec @rc=dbo.cvsp_CMS_HQTC_CMDT_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update PR checks to CMDT 
exec @rc=dbo.cvsp_CMS_PR_CMDT  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_PR_CMDT',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_PR_CMDT',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--CMDT HQTC Update
exec @rc=dbo.cvsp_CMS_HQTC_CMDT_Update  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;


--Clear past checks as of the date customer specified
exec @rc=dbo.cvsp_CMS_CM_ClearEntries  @fromco, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_CM_ClearEntries',@fromco, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_CM_ClearEntries',[FromCo]=@fromco,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;

-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/


-- to be on safe side re-enable all triggers
alter table bCMDT enable trigger all;
alter table bHQTC enable trigger all;


return @@error

GO
