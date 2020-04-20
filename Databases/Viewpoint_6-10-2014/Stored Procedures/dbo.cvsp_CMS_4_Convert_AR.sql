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
	Title:		Convert all AR tables (master and transaction)
	Created:	10.12.09
	Created by:	Viewpoint Technical Services - JRE
	Revisions:	
			1. 03/19/2012 BBA - Corrected sp name in drop table code.
	EXEC cvsp_CMS_4_Convert_AR 1,15,50,1
*/

CREATE PROCEDURE [dbo].[cvsp_CMS_4_Convert_AR] 
(@fromco1 smallint, @fromco2 smallint, @fromco3 smallint, @toco smallint)/* Step 1 of 3: if using the counter below rem this line out */

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

exec cvsp_CMS_4_Convert_AR 1,15,50,1
*/





if not exists(select name from sysobjects where name='cvLog')
create table cvLog(ProcDate smalldatetime null, ProcName varchar(50) null,
	FromCo smallint null, ToCo smallint null,
	RowsConvert int null, ErrMsg varchar(1000) null); 

--check before running
if not exists (select 1 from bARCO where ARCo=@toco)
Begin
	select @errmsg='ARCO is not setup for company'+convert(varchar(3),@toco)
	insert into cvLog
	select getdate(),'cvsp_CMS_AR_RunAll',@fromco1, @toco, 0, @errmsg
	return (1)
End

--Add columns/indexes
exec @rc= dbo.cvsp_CMS_AR_AddColsIndexes @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AR_AddColsIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AR_AddColsIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

----Update values on CMS tables
--exec @rc=dbo.cvsp_CMS_AR_UpdateSource  @fromco1, @toco, @errmsg output, @rowcount output;
--insert into cvLog
--select getdate(),'cvsp_CMS_AR_UpdateSource',@fromco1, @toco, @rowcount, @errmsg;
--select getdate(),'cvsp_CMS_AR_UpdateSource',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AR Customers
IF @toco = 1
BEGIN
	exec @rc=dbo.cvsp_CMS_MASTER_ARCM  @fromco1, @toco, @errmsg output, @rowcount output;
	insert into cvLog
	select getdate(),'cvsp_CMS_MASTER_ARCM',@fromco1, @toco, @rowcount, @errmsg;
	select getdate(),'cvsp_CMS_MASTER_ARCM',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;
END
--PM Firms
exec @rc = dbo.cvsp_CMS_MASTER_PMFM_Cust  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select GETDATE(), 'cvsp_CMS_MASTER_PMFM_Cust', @fromco1, @toco, @rowcount, @errmsg;
select GETDATE(), 'cvsp_CMS_MASTER_PMFM_Cust', [FromCo]=@fromco1, [ToCo]=@toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--ARTH Invoice
exec @rc=dbo.cvsp_CMS_ARTHInvoice @fromco1, @fromco2, @fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTHInvoice',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTHInvoice',[FromCo1]=@fromco1, [FromCo2]=@fromco2, [FromCo3]=@fromco3, [ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--ARTL Invoice
exec @rc=dbo.cvsp_CMS_ARTLInvoice  @fromco1, @fromco2, @fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTLInvoice',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTLInvoice',[FromCo1]=@fromco1, [FromCo2]=@fromco2, [FromCo3]=@fromco3,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update ARTL Lines 
exec @rc=dbo.cvsp_CMS_ARTLUpdate  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTLUpdate',@fromco1,@toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTLUpdate',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for ARTH
exec @rc=dbo.cvsp_CMS_HQTC_ARTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',[FromCo]=@fromco1, [ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update AR Receipts (ARTH/ARTL)
exec @rc=dbo.cvsp_CMS_AR_Receipts @fromco1, @fromco2, @fromco3, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AR_Receipts',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AR_Receipts',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for ARTH
exec @rc=dbo.cvsp_CMS_HQTC_ARTH_Update @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--ARTH Insert for zero sums
exec @rc=dbo.cvsp_CMS_ARTHZeroSums  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTHZeroSums',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTHZeroSums',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--ARTL Insert for zero sums
exec @rc=dbo.cvsp_CMS_ARTLZeroSums  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTLZeroSums',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTLZeroSums',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update ARTH from lines
exec @rc=dbo.cvsp_CMS_ARTHUpdateFromLines  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARTHUpdateFromLines',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARTHUpdateFromLines',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for ARTH
exec @rc=dbo.cvsp_CMS_HQTC_ARTH_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_ARTH_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for JCID
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AR Invoices to JC
--declare @rc varchar(1000),@fromco int = 1,@toco int = 1,@errmsg varchar(2000),@rowcount int = 0
exec @rc=dbo.cvsp_CMS_ARInvoices_to_JC  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARInvoices_to_JC',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARInvoices_to_JC',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for JCID
--declare @rc varchar(1000),@fromco int = 1,@toco int = 1,@errmsg varchar(2000),@rowcount int = 0
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--AR Receipts to JC
--declare @rc varchar(1000),@fromco int = 1,@toco int = 1,@errmsg varchar(2000),@rowcount int = 0
exec @rc=dbo.cvsp_CMS_ARReceipts_to_JC  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_ARReceipts_to_JC', @fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_ARReceipts_to_JC',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for JCID
exec @rc=dbo.cvsp_CMS_HQTC_JCID_Update  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_JCID_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_JCID_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update CMDT with AR Receipts
exec @rc=dbo.cvsp_CMS_AR_CMDT  @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AR_CMDT',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AR_CMDT',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Update HQTC for CMDT
exec @rc=dbo.cvsp_CMS_HQTC_CMDT_Update @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_HQTC_CMDT_Update',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--Rebuild AR/JC Indexes
exec @rc=dbo.cvsp_CMS_AR_RebuildIndexes @fromco1, @toco, @errmsg output, @rowcount output;
insert into cvLog
select getdate(),'cvsp_CMS_AR_RebuildIndexes',@fromco1, @toco, @rowcount, @errmsg;
select getdate(),'cvsp_CMS_AR_RebuildIndexes',[FromCo]=@fromco1,[ToCo]= @toco, [Rows]=@rowcount, [ErrMsg]=@errmsg;

--One final check to make sure HQTC is correct
exec cvsp_CMS_HQTC_Update_AllTables  @toco, null;


-- Step 3 of 3:  un-rem this section for the multi company loop
/*
      set @counter = @counter + 1
end
*/


-- to be on safe side re-enable all AR triggers
alter table bARCM enable trigger all;
alter table bARTH enable trigger all;
alter table bARTL enable trigger all;
alter table bJCID enable trigger all;
alter table bJCCI enable trigger all;

return @@error




GO
