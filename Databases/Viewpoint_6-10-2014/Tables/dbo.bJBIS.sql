CREATE TABLE [dbo].[bJBIS]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ACOItem] [dbo].[bACOItem] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UnitsBilled] [dbo].[bUnits] NOT NULL,
[AmtBilled] [dbo].[bDollar] NOT NULL,
[RetgBilled] [dbo].[bDollar] NOT NULL,
[RetgRel] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmount] [dbo].[bDollar] NOT NULL,
[AmountDue] [dbo].[bDollar] NOT NULL,
[PrevUnits] [dbo].[bUnits] NOT NULL,
[PrevAmt] [dbo].[bDollar] NOT NULL,
[PrevRetg] [dbo].[bDollar] NOT NULL,
[PrevRetgReleased] [dbo].[bDollar] NOT NULL,
[PrevTax] [dbo].[bDollar] NOT NULL,
[PrevDue] [dbo].[bDollar] NOT NULL,
[ARLine] [smallint] NULL,
[ARRelRetgLine] [smallint] NULL,
[ARRelRetgCrLine] [smallint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[CurrContract] [dbo].[bDollar] NOT NULL,
[ContractUnits] [dbo].[bUnits] NOT NULL,
[PrevWC] [dbo].[bDollar] NOT NULL,
[PrevWCUnits] [dbo].[bUnits] NOT NULL,
[WC] [dbo].[bDollar] NOT NULL,
[WCUnits] [dbo].[bUnits] NOT NULL,
[PrevSM] [dbo].[bDollar] NOT NULL,
[Installed] [dbo].[bDollar] NOT NULL,
[Purchased] [dbo].[bDollar] NOT NULL,
[SM] [dbo].[bDollar] NOT NULL,
[SMRetg] [dbo].[bDollar] NOT NULL,
[PrevSMRetg] [dbo].[bDollar] NOT NULL,
[PrevWCRetg] [dbo].[bDollar] NOT NULL,
[WCRetg] [dbo].[bDollar] NOT NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ChgOrderUnits] [dbo].[bUnits] NOT NULL,
[ChgOrderAmt] [dbo].[bDollar] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[WCRetPct] [dbo].[bPct] NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIS_Purge] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIS_AuditYN] DEFAULT ('Y'),
[RetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIS_RetgTax] DEFAULT ((0.00)),
[PrevRetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIS_PrevRetgTax] DEFAULT ((0.00)),
[RetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIS_RetgTaxRel] DEFAULT ((0.00)),
[PrevRetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIS_PrevRetgTaxRel] DEFAULT ((0.00)),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btJBISd    Script Date: 01/06/04 9:37:39 AM ******/
CREATE TRIGGER [dbo].[btJBISd] ON [dbo].[bJBIS]
FOR DELETE AS

/***********************************************************************
*
*  Created by: TJL 01/06/04 - Issue #21076, to update bJBIT.CurrContract
*  Modified by:  TJL 09/15/06 - Issue #122473 (5x - 119946), Prevent JBIS trigger update to Future Bills CurrContract on Bill Purge
*
*
*  
*  If the following error condition exists:
*	none
*
*  Updates bJBIT.CurrContract and bJBIT.ContractUnits.
*
*
*************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int, @rcode int,
   	@co bCompany, @billmth bMonth, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, 
   	@contractitem bContractItem, @contract bContract, @updateprevYN bYN,
   	@opendeletecursor int, @audityn bYN, @purgeyn bYN
   
select @numrows = @@rowcount, @rcode = 0, @opendeletecursor = 0

if @numrows = 0 return
set nocount on

declare bcDeleted cursor local fast_forward for
select d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.Item, d.ACO, d.ACOItem,
	d.Contract, c.PrevUpdateYN, d.AuditYN, d.Purge
from deleted d with (nolock)
join bJBCO c with (nolock) on c.JBCo = d.JBCo
order by d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.Item, d.ACO, d.ACOItem
   
open bcDeleted
select @opendeletecursor = 1

fetch next from bcDeleted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
   	@contract, @updateprevYN, @audityn, @purgeyn
while @@fetch_status = 0
   	begin	/* Begin Deleted loop */

   	/* If purge flag is set to 'Y', two conditions may exist.
   	1) If this is a single Bill being deleted by hitting 'Delete' Key
   	   then proceed and do updates to CurrentContract & ContractUnits Values in later bills. 

   	2) If this is a True Purge then multiple Bills may exist in the 
   	   'delete' queue.  Exit immediately since the 'delete' queue
   	   will contain ONLY Bills (Detail Tables will contain
   	   ONLY records) marked for PURGE.  Therefore there is no sense in
   	   cycling through each Bill because they are ALL marked to be Purged.
   	   DO NOT UPDATE CurrentContract & ContractUnits VALUES in later bills.
   	****NOTE**** 
   	JB is unique in that a user is allowed to delete a bill and its detail
   	from a JB Bill Header form.  There is potential for leaving detail out
   	there if a JBIN record is removed ADHOC but user insist on this capability. */

   	/* Bill Purge, Do NOT update CurrentContract & ContractUnits Amounts on Later bills. */
   	if @purgeyn = 'Y' and @audityn = 'N'
   		begin
   		if @opendeletecursor = 1
   			begin
   			close bcDeleted
   			deallocate bcDeleted
   			select @opendeletecursor = 0
   			end
   		return
   		end

   	/* Bill Delete, proceed to update CurrentContract & ContractUnits amounts on Later bills. 
	   (@purgeyn = 'Y' and @audityn = 'Y')

	   Update bJBIT.CurrContract and bJBIT.ContractUnits, which updates bJBIN.CurrContract.
   	   Job, ACO, and ACOItem must have value otherwise a nested trigger loop will occur.  
   	   		JBIS gets updated by bJBIT triggers when Job, ACO, and ACOItem are ''
   			JBIS gets updated by bJBCX triggers when Job, ACO, and ACOItem are not '' */
   	if @updateprevYN = 'Y' and (@job <> '' and @aco <> '' and @acoitem <> '')
   		begin
   		exec @rcode = bspJBUpdatePrevContractValues @co, @billmth, @billnum, null, null,
   			@contract, @contractitem, null, null, @updateprevYN, @errmsg output
   		if @rcode = 1 goto error
   		end
   
   	/* Get next JBIS record. */
   	fetch next from bcDeleted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
   		@contract, @updateprevYN, @audityn, @purgeyn
   	end		/* End Deleted loop */
   
if @opendeletecursor = 1
   	begin
   	close bcDeleted
   	deallocate bcDeleted
   	select @opendeletecursor = 0
   	end
   
   return
   
error:
select @errmsg = @errmsg + ' - cannot delete JBIS Detail!'

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
 
 
 /****** Object:  Trigger dbo.btJBISi    Script Date: 01/06/04 9:37:39 AM ******/
 CREATE TRIGGER [dbo].[btJBISi] ON [dbo].[bJBIS]
 FOR INSERT AS
/***********************************************************************
*
*  Created by: TJL 01/06/04 - Issue #21076, to update bJBIT.CurrContract
*  Modified by:  TJL 09/15/06 - Issue #122473 (5x - 119946), Prevent JBIS trigger update to Future Bills CurrContract on Bill Purge
*		CHS 12/16/2011 - B-08120 - Move bills to next month
*
*  
*  If the following error condition exists:
*	none
*
*  Updates bJBIT.CurrContract and bJBIT.ContractUnits.
*
*
*************************************************************************/
 declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int, @rcode int,
 	@co bCompany, @billmth bMonth, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, 
 	@contractitem bContractItem, @contract bContract, @updateprevYN bYN,
 	@openinsertcursor int, @audityn bYN, @purgeyn bYN
 
 select @numrows = @@rowcount, @rcode = 0, @openinsertcursor = 0
 
 if @numrows = 0 return
 set nocount on
 
 declare bcInserted cursor local fast_forward for
 select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.Item, i.ACO, i.ACOItem,
 	n.Contract, c.PrevUpdateYN, i.AuditYN, i.Purge
 from inserted i with (nolock)
 join bJBIN n with (nolock) on n.JBCo = i.JBCo and n.BillMonth = i.BillMonth and n.BillNumber = i.BillNumber
 join bJBCO c with (nolock) on c.JBCo = i.JBCo
 order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.Item, i.ACO, i.ACOItem
 
 open bcInserted
 select @openinsertcursor = 1
 
 fetch next from bcInserted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
 	@contract, @updateprevYN, @audityn, @purgeyn
 while @@fetch_status = 0
 	begin	/* Begin Inserted loop */
   	/* Bill Purge, Do NOT update CurrentContract & ContractUnits Amounts on Later bills. */
   	if @purgeyn = 'Y' and @audityn = 'N'
   		begin
		if @openinsertcursor = 1
			begin
			close bcInserted
			deallocate bcInserted
			select @openinsertcursor = 0
			end
   		return
   		end


   	if @purgeyn = 'Y' and @audityn = 'Y'
   		begin
		if @openinsertcursor = 1
			begin
			close bcInserted
			deallocate bcInserted
			select @openinsertcursor = 0
			end
   		return
   		end
   		
 	/* Update bJBIT.CurrContract and bJBIT.ContractUnits, which updates bJBIN.CurrContract. 
 	   Job, ACO, and ACOItem must have value otherwise a nested trigger loop will occur.  
 	   		JBIS gets updated by bJBIT triggers when Job, ACO, and ACOItem are ''
 			JBIS gets updated by bJBCX triggers when Job, ACO, and ACOItem are not '' */
 	if @updateprevYN = 'Y' and (@job <> '' and @aco <> '' and @acoitem <> '')
 		begin
 		exec @rcode = bspJBUpdatePrevContractValues @co, @billmth, @billnum, null, null,
 			@contract, @contractitem, null, null, @updateprevYN, @errmsg output
 		if @rcode = 1 goto error
 		end
 	
 	/* Get next JBIS record. */
 	fetch next from bcInserted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
 		@contract, @updateprevYN, @audityn, @purgeyn
 	end		/* End Inserted loop */
 
 if @openinsertcursor = 1
 	begin
 	close bcInserted
 	deallocate bcInserted
 	select @openinsertcursor = 0
 	end
 	
 
 return


 
 error:
 select @errmsg = @errmsg + ' - cannot insert JBIS Detail!'
 
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
 
 /****** Object:  Trigger dbo.btJBISu    Script Date: 01/06/04 9:37:39 AM ******/
 CREATE TRIGGER [dbo].[btJBISu] ON [dbo].[bJBIS]
 FOR UPDATE AS
 /***********************************************************************
 *
 *  Created by: TJL 01/06/04 - Issue #21076, to update bJBIT.CurrContract
 *  Modified by:  TJL 09/15/06 - Issue #122473 (5x - 119946), Prevent JBIS trigger update to Future Bills CurrContract on Bill Purge
 *
 *
 *  
 *  If the following error condition exists:
 *	none
 *
 *  Updates bJBIT.CurrContract and bJBIT.ContractUnits.
 *
 *
  *************************************************************************/
 declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int, @rcode int,
 	@co bCompany, @billmth bMonth, @billnum int, @job bJob, @aco bACO, @acoitem bACOItem, 
 	@contractitem bContractItem, @contract bContract, @updateprevYN bYN,
 	@openinsertcursor int, @audityn bYN, @purgeyn bYN
 
 select @numrows = @@rowcount, @rcode = 0, @openinsertcursor = 0
 
 if @numrows = 0 return
 set nocount on
 
 declare bcInserted cursor local fast_forward for
 select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.Item, i.ACO, i.ACOItem,
 	n.Contract, c.PrevUpdateYN, i.AuditYN, i.Purge
 from inserted i with (nolock)
 join bJBIN n with (nolock) on n.JBCo = i.JBCo and n.BillMonth = i.BillMonth and n.BillNumber = i.BillNumber
 join bJBCO c with (nolock) on c.JBCo = i.JBCo
 order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.Item, i.ACO, i.ACOItem
 
 open bcInserted
 select @openinsertcursor = 1
 
 fetch next from bcInserted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
 	@contract, @updateprevYN, @audityn, @purgeyn
 while @@fetch_status = 0
 	begin	/* Begin Inserted loop */
   	/* Bill Purge, Do NOT update CurrentContract & ContractUnits Amounts on Later bills. */
   	if @purgeyn = 'Y' and @audityn = 'N'
   		begin
		if @openinsertcursor = 1
			begin
			close bcInserted
			deallocate bcInserted
			select @openinsertcursor = 0
			end
   		return
   		end

 	/* Update bJBIT.CurrContract and bJBIT.ContractUnits, which updates bJBIN.CurrContract. 
 	   Job, ACO, and ACOItem must have value otherwise a nested trigger loop will occur.  
 	   		JBIS gets updated by bJBIT triggers when Job, ACO, and ACOItem are ''
 			JBIS gets updated by bJBCX triggers when Job, ACO, and ACOItem are not '' */
 	if @updateprevYN = 'Y' and (@job <> '' and @aco <> '' and @acoitem <> '')
 		begin
 		exec @rcode = bspJBUpdatePrevContractValues @co, @billmth, @billnum, null, null,
 			@contract, @contractitem, null, null, @updateprevYN, @errmsg output
 		if @rcode = 1 goto error
 		end
 
 	/* Get next JBIS record. */
 	fetch next from bcInserted into @co, @billmth, @billnum, @job, @contractitem, @aco, @acoitem,
 		@contract, @updateprevYN, @audityn, @purgeyn
 	end		/* End Inserted loop */
 
 if @openinsertcursor = 1
 	begin
 	close bcInserted
 	deallocate bcInserted
 	select @openinsertcursor = 0
 	end
 
 return
 
 error:
 select @errmsg = @errmsg + ' - cannot update JBIS Detail!'
 
 RAISERROR(@errmsg, 11, -1);
 rollback transaction
 
 if @openinsertcursor = 1
 	begin
 	close bcInserted
 	deallocate bcInserted
 	select @openinsertcursor = 0
 	end
 
 
 
 
 
 


GO
CREATE UNIQUE CLUSTERED INDEX [biJBIS] ON [dbo].[bJBIS] ([JBCo], [BillMonth], [BillNumber], [Job], [Item], [ACO], [ACOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bJBIS_Contract] ON [dbo].[bJBIS] ([JBCo], [Item], [BillMonth], [BillNumber], [Contract], [Job], [ACO], [ACOItem]) INCLUDE ([ChgOrderAmt], [ChgOrderUnits]) WITH (FILLFACTOR=70) ON [PRIMARY]
GO
