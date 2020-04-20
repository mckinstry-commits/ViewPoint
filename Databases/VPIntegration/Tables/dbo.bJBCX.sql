CREATE TABLE [dbo].[bJBCX]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ACOItem] [dbo].[bACOItem] NOT NULL,
[ChgOrderUnits] [dbo].[bUnits] NOT NULL,
[ChgOrderAmt] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCX_AuditYN] DEFAULT ('Y'),
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCX_Purge] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJBCXd    Script Date: 8/28/99 9:37:39 AM ******/
CREATE TRIGGER [dbo].[btJBCXd] ON [dbo].[bJBCX]
FOR DELETE AS

/**************************************************************
*	Created by:
*  	Modified by: ALLENN 11/16/2001 Issue #13667
*   	kb 2/19/2 - issue #16147
*		TJL 11/06/02 - Issue #18740, No need to update JBCC when bill is purged
*		TJL 12/17/03 - Issue #21076, Remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*
*	This trigger rejects delete of bJBCX (JC Cost Detail)
*	if the following error condition exists:
*		none
*
* 	Updates corresponding fields in JBCC.

**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@co bCompany, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, @chgorderamt bDollar,
   	@billmth bMonth, @purgeyn bYN, @opendeletecursor int
   
select @numrows = @@rowcount, @opendeletecursor = 0

if @numrows = 0 return
set nocount on

declare bcDeleted cursor local fast_forward for
select d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.ACO, d.ACOItem,
	d.ChgOrderAmt, d.Purge
from deleted d with (nolock)
order by d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.ACO, d.ACOItem
   
open bcDeleted
select @opendeletecursor = 1

fetch next from bcDeleted into @co, @billmth, @billnum, @job, @aco, @acoitem,
   	@chgorderamt, @purgeyn

while @@fetch_status = 0
   	begin	/* Begin Deleted loop */
   	/* If purge flag is set to 'Y', two conditions may exist.
   		1) If this is a single Bill being deleted by hitting 'Delete' Key
   		   then exit immediately to skip all unnecessary updates to detail
   		   records that are also being deleted.
   		2) If this is a True Purge then multiple Bills may exist in the 
   		   'delete' queue.  Again, it is OK to exit immediately since the
   		   'delete' queue will contain ONLY Bills (Detail Tables will contain
   		   ONLY records) marked for PURGE.  Therefore there is no sense in
   		   cycling through each Bill because they are ALL marked to be Purged.
   		****NOTE**** 
   		JB is unique in that a user is allowed to delete a bill and its detail
   		from a JB Bill Header form.  There is potential for leaving detail out
   		there if a JBIN record is removed ADHOC but user insist on this capability. */
   	if @purgeyn = 'Y' 
   		begin
   		if @opendeletecursor = 1
   			begin
   			close bcDeleted
   			deallocate bcDeleted
   			select @opendeletecursor = 0
   			end
   		return
   		end
   
   	update bJBCC 
   	set ChgOrderTot = ChgOrderTot - @chgorderamt, AuditYN = 'N' 
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum
		and Job = @job and ACO = @aco
   
	update bJBCC 
   	set AuditYN = 'Y' 
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum
		and Job = @job and ACO = @aco
   
   	fetch next from bcDeleted into @co, @billmth, @billnum, @job, @aco, @acoitem,
   		@chgorderamt, @purgeyn
   
	end		/* End Deleted loop */
   
delete bJBIS 
from bJBIS s
join deleted d on s.JBCo = d.JBCo and s.BillMonth = d.BillMonth and s.BillNumber = d.BillNumber and s.Job = d.Job 
	and s.ACO = d.ACO and s.ACOItem = d.ACOItem
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBCX', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),d.BillNumber) + 'Job: ' + d.Job + 'ACO: ' + d.ACO + 'ACOItem: ' + d.ACOItem, d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d with (nolock)
Join bJBCO c with (nolock) on c.JBCo = d.JBCo
Where c.AuditBills = 'Y' and d.AuditYN = 'Y'
   
if @opendeletecursor = 1
   	begin
   	close bcDeleted
   	deallocate bcDeleted
   	select @opendeletecursor = 0
   	end
   
return

error:
select @errmsg = @errmsg + ' - cannot delete JB Change Order Detail!'

RAISERROR(@errmsg, 11, -1);
rollback transaction

if @opendeletecursor = 1
   	begin
   	close bcDeleted
   	deallocate bcDeleted
   	select @opendeletecursor = 0
   	end
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btJBCXi    Script Date: 8/28/99 9:37:39 AM ******/
CREATE TRIGGER [dbo].[btJBCXi] ON [dbo].[bJBCX]
FOR INSERT AS

/**************************************************************
*
* Modified by: bc added Job to the JBIS insert statement
* 		kb 9/26/1 - issue #14680
*  		ALLENN 11/16/2001 Issue #13667
*   	kb 2/19/2 - issue #16147
*   	bc 3/5/3 - fixed the Description
*		TJL 12/17/03 - Issue #21076, Remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 09/06/06 - Issue #28678, Correct JBIS.ACOItem Description truncates at 30 chars.  Modify @desc bDesc, change to @desc bItemDesc
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 03/24/09 - Issue #132867, ANSI Null evaluating FALSE instead of TRUE
*		TJL 08/26/09 - Issue #133896, JBIS Description should be kept the same for Bill Item as well as associated Bill Item ACO's
*		CHS 12/16/2011 - B-08120 - Move bills to next month
*
* This trigger rejects insert of bJBCX (JC Cost Detail)
* if the following error condition exists:
*	none
*
* Updates corresponding fields in JBCC.
*
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, @chgorderamt bDollar,
	@contract bContract, @contractitem bContractItem, @billmth bMonth, @desc bItemDesc,
	@openinsertcursor int, @purgeyn bYN
   
select @numrows = @@rowcount, @openinsertcursor = 0

if @numrows = 0 return
set nocount on

declare bcInserted cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO, i.ACOItem,
	i.ChgOrderAmt, i.Purge
from inserted i with (nolock)
order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO, i.ACOItem

open bcInserted
select @openinsertcursor = 1

fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco, @acoitem,
	@chgorderamt, @purgeyn
while @@fetch_status = 0
	begin	/* Begin Inserted loop */
	
	   	if @purgeyn = 'Y' 
   		begin
   		if @openinsertcursor = 1
   			begin
   			close bcInserted
   			deallocate bcInserted
   			select @openinsertcursor = 0
   			end
   		goto begin_audit
   		end
	
	
	select @desc = null
	
	update bJBCC 
	set ChgOrderTot = ChgOrderTot + @chgorderamt, AuditYN = 'N'
	from bJBCC with (nolock)
	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
	if @@rowcount = 0
		begin
		insert bJBCC (JBCo, BillMonth, BillNumber, Job, ACO, ChgOrderTot, AuditYN)
		select @co, @billmth, @billnum, @job, @aco, @chgorderamt, 'N'
		end
   
	update bJBCC 
   	set AuditYN = 'Y'
   	from bJBCC with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco
   
	select @contractitem = Item
	from bJCOI with (nolock)
	where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem

	select @contract = Contract
	from bJBIN with (nolock)
	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum

	/* JBIS ACO records will get the Item description from JBIT when a Change Order is added to a pre-existing bill.
	   At other times, during bill initialization, changes orders get added before the JBIT record.  In this case, we
	   will first set the description from the JCCI item value.  This will be the same value that gets initialized
	   onto the bill item later.  */
	if exists(select top 1 1 from bJBIT with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @contractitem)
		begin
		select @desc = Description
		from bJBIT with (nolock) 
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @contractitem
		end
	else
		begin
		select @desc = case when BillDescription is null then Description else BillDescription end
		from bJCCI with (nolock)
		where JCCo = @co and Contract = @contract and Item = @contractitem
		end
		
	insert bJBIS (JBCo,BillMonth, BillNumber, Job, Item, ACO, ACOItem, Description,
		UnitsBilled,AmtBilled,RetgBilled,RetgTax,RetgRel,RetgTaxRel,Discount,TaxBasis,TaxAmount,AmountDue,
		PrevUnits,PrevAmt,PrevRetg,PrevRetgTax,PrevRetgReleased,PrevRetgTaxRel,PrevTax,PrevDue,
		CurrContract,ContractUnits,PrevWC,PrevWCUnits,WC,WCUnits,PrevSM,Installed,Purchased,
		SM,SMRetg,PrevSMRetg,PrevWCRetg,WCRetg,WCRetPct,
		ChgOrderUnits, ChgOrderAmt, Contract)
	select JBCo, BillMonth, BillNumber, Job, @contractitem, ACO, ACOItem, @desc,
		0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,
		ChgOrderUnits, ChgOrderAmt, @contract
	from inserted
	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco and ACOItem = @acoitem
   
   	fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco, @acoitem,
   		@chgorderamt, @purgeyn
   
	end	/* End Inserted loop */

begin_audit:
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBCX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Job: ' + i.Job + 'ACO: ' + i.ACO + 'ACOItem: ' + i.ACOItem, i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i with (nolock)
Join bJBCO c with (nolock) on c.JBCo = i.JBCo
Where c.AuditBills = 'Y' and i.AuditYN = 'Y'
   
if @openinsertcursor = 1
	begin
	close bcInserted
	deallocate bcInserted
	select @openinsertcursor = 0
	end

return

error:
select @errmsg = @errmsg + ' - cannot insert JB Change Order Detail!'

RAISERROR(@errmsg, 11, -1);
rollback transaction

if @openinsertcursor = 1
	begin
	close bcInserted
	deallocate bcInserted
	select @openinsertcursor = 0
	end
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJBCXu    Script Date: 8/28/99 9:37:39 AM ******/
CREATE TRIGGER [dbo].[btJBCXu] ON [dbo].[bJBCX]
FOR UPDATE AS

/**************************************************************
*
* Modified by: ALLENN 11/16/2001 Issue #13667
*		kb 2/19/2 - issue #16147
*		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
*		TJL 12/17/03 - Issue #21076, Remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*
* This trigger rejects update of bJBCX (JC Cost Detail)
* if the following error condition exists:
*	none
*
* Updates corresponding fields in JBCC.

**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@co bCompany, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem,
	@oldchgorderamt bDollar, @newchgorderamt bDollar, @billmth bMonth,
   	@openinsertcursor int
   
select @numrows = @@rowcount, @openinsertcursor = 0

if @numrows = 0 return
set nocount on

/*Issue 13667*/
If Update(Purge)
   	Begin
   	return
   	End
   
If Update(JBCo)
    Begin
    select @errmsg = 'Cannot change JBCo'
    GoTo error
    End

If Update(BillMonth)
    Begin
    select @errmsg = 'Cannot change BillMonth'
    GoTo error
    End

If Update(BillNumber)
    Begin
    select @errmsg = 'Cannot change BillNumber'
    GoTo error
    End

If Update(Job)
    Begin
    select @errmsg = 'Cannot change Job'
    GoTo error
    End

If Update(ACO)
    Begin
    select @errmsg = 'Cannot change ACO'
    GoTo error
    End

If Update(ACOItem)
    Begin
    select @errmsg = 'Cannot change ACOItem'
    GoTo error
    End
   
declare bcInserted cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO, i.ACOItem,
	i.ChgOrderAmt
from inserted i with (nolock)
order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO, i.ACOItem

open bcInserted
select @openinsertcursor = 1

fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco, @acoitem,
	@newchgorderamt
while @@fetch_status = 0
   	begin	/* Begin Inserted loop */
	select @oldchgorderamt = d.ChgOrderAmt
   	from deleted d with (nolock)
   	where d.JBCo = @co and d.BillMonth = @billmth and d.BillNumber = @billnum and d.Job = @job 
   		and	d.ACO = @aco and d.ACOItem = @acoitem 
   
	update bJBCC 
   	set ChgOrderTot = ChgOrderTot + (@newchgorderamt - @oldchgorderamt), AuditYN = 'N' 
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
   
	update bJBCC 
   	set AuditYN = 'Y' 
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
   
   	fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco, @acoitem,
   		@newchgorderamt
   
	end		/* End Inserted loop */
   
update bJBIS 
set bJBIS.ChgOrderAmt = i.ChgOrderAmt,	bJBIS.ChgOrderUnits = i.ChgOrderUnits 
from bJBIS 
join inserted i on bJBIS.JBCo = i.JBCo and bJBIS.BillMonth = i.BillMonth and bJBIS.BillNumber = i.BillNumber 
	and	bJBIS.Job = i.Job and bJBIS.ACO = i.ACO and bJBIS.ACOItem = i.ACOItem
   	  
/*Issue 13667*/
If exists(select 1 from inserted i with (nolock) join bJBCO c with (nolock) on i.JBCo = c.JBCo where c.AuditBills = 'Y')
	BEGIN
	If Update(ChgOrderUnits)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBCX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Job: ' + i.Job + 'ACO: ' + i.ACO + 'ACOItem: ' + i.ACOItem, i.JBCo, 'C', 'ChgOrderUnits', convert(varchar(13), d.ChgOrderUnits), convert(varchar(13), i.ChgOrderUnits), getdate(), SUSER_SNAME()
		From inserted i with (nolock)
		Join deleted d with (nolock) on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Job = i.Job and d.ACO = i.ACO and d.ACOItem = i.ACOItem
		Join bJBCO c with (nolock) on c.JBCo = i.JBCo
		Where d.ChgOrderUnits <> i.ChgOrderUnits
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

	If Update(ChgOrderAmt)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBCX', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Job: ' + i.Job + 'ACO: ' + i.ACO + 'ACOItem: ' + i.ACOItem, i.JBCo, 'C', 'ChgOrderAmt', convert(varchar(13), d.ChgOrderAmt), convert(varchar(13), i.ChgOrderAmt), getdate(), SUSER_SNAME()
		From inserted i with (nolock)
		Join deleted d with (nolock) on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Job = i.Job and d.ACO = i.ACO and d.ACOItem = i.ACOItem
		Join bJBCO c with (nolock) on c.JBCo = i.JBCo
		Where d.ChgOrderAmt <> i.ChgOrderAmt
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
	END
   
if @openinsertcursor = 1
	begin
	close bcInserted
	deallocate bcInserted
	select @openinsertcursor = 0
	end
   
return

error:
select @errmsg = @errmsg + ' - cannot update JB Change Order Detail!'

RAISERROR(@errmsg, 11, -1);
rollback transaction

if @openinsertcursor = 1
   	begin
   	close bcInserted
   	deallocate bcInserted
   	select @openinsertcursor = 0
   	end
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJBCX] ON [dbo].[bJBCX] ([JBCo], [BillMonth], [BillNumber], [Job], [ACO], [ACOItem]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBCX] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBCX].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBCX].[Purge]'
GO
