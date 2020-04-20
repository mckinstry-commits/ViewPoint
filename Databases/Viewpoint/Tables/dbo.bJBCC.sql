CREATE TABLE [dbo].[bJBCC]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ChgOrderTot] [dbo].[bDollar] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCC_AuditYN] DEFAULT ('Y'),
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBCC_Purge] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biJBCC] ON [dbo].[bJBCC] ([JBCo], [BillMonth], [BillNumber], [Job], [ACO]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBCC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btJBCCi    Script Date: 8/28/99 9:37:39 AM ******/
   CREATE TRIGGER [dbo].[btJBCCd] ON [dbo].[bJBCC]
   FOR DELETE AS
   

/**************************************************************
   * This trigger rejects delete of bJBCC (JB Change Order Header)
   *
   * Modified:  11/10/99 bc  -  only update JBIN if it exists
   *  		09/19/00 bc - change JBIN.InvStatus if neccessary
   *		11/16/2001 ALLENN Issue #13667
   *		kb 2/19/2 - issue #16147
   *		TJL 11/06/02 - Issue #18740, No need to update JBIN when bill is purged
   *		TJL 12/17/03 - Issue #21076, Do not change InvStatus when ChgOrderAmt changes.
   *						Remove psuedo cursor
   *		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   * if the following error condition exists:
   *	none
   *
   * Updates corresponding fields in JBCC.
   *	
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@co bCompany, @billnum int,  @changeordertot bDollar, @contract bContract,
    	@job bJob, @aco bACO, @billmth bMonth, @purgeyn bYN, @opendeletecursor int
   
   select @numrows = @@rowcount, @opendeletecursor = 0
   
   if @numrows = 0 return
   set nocount on
   
   declare bcDeleted cursor local fast_forward for
   select d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.ACO,
   	d.ChgOrderTot, d.Purge
   from deleted d with (nolock)
   order by d.JBCo, d.BillMonth, d.BillNumber, d.Job, d.ACO
   
   open bcDeleted
   select @opendeletecursor = 1
   
   fetch next from bcDeleted into @co, @billmth, @billnum, @job, @aco,
   	@changeordertot, @purgeyn
   while @@fetch_status = 0
   	begin /* Begin Deleted loop */
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
   
   	/* Delete lines for this change order.  This must occur here, before updating bJBIN,
   	   because the bJBCX lines must be gone by the time that the bJBIN update trigger
   	   begins to update Previous ChgOrderAdds/Deds. */
       update bJBCX 
   	set AuditYN = 'N' 
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
   
   	delete bJBCX 
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
   
   	/* Update ChgOrderAmt in bJBIN, which will update Previous ChgOrderAdds/Deds. */
   	update bJBIN 
   	set AuditYN = 'N', ChgOrderAmt = ChgOrderAmt - @changeordertot
   	from bJBIN with (nolock)
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
   	if @@rowcount = 0
       	begin
       	select @errmsg = 'Error updating Bill Header'
   		goto error
           end
   
   	update bJBIN 
   	set AuditYN = 'Y'
    	from bJBIN with (nolock)
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
   
   	fetch next from bcDeleted into @co, @billmth, @billnum, @job, @aco,
   		@changeordertot, @purgeyn
   
   	end		/* End Deleted loop */
   
   /*Issue 13667*/
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
        Select 'bJBCC', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),d.BillNumber) + 'Job: ' + d.Job + 'ACO: ' + d.ACO, d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
        From deleted d
        Join bJBCO c on c.JBCo = d.JBCo
        Where c.AuditBills = 'Y' and d.AuditYN = 'Y'
   
   if @opendeletecursor = 1
   	begin
   	close bcDeleted
   	deallocate bcDeleted
   	select @opendeletecursor = 0
   	end
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot delete JB Change Order Header!'
   
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

/****** Object:  Trigger dbo.btJBCCi    Script Date: 8/28/99 9:37:39 AM ******/
CREATE TRIGGER [dbo].[btJBCCi] ON [dbo].[bJBCC]
FOR INSERT AS

/**************************************************************
*  Modified by: kb 3/27/00
*  		kb 5/22/00 - changed bBillGroup to be bBillingGroup
*  		kb 8/29/00 - removed approvedmth restriction for JCOI
*    	bc 09/19/00 - change JBIN.InvStatus is neccessary
*    	kb 2/19/2 - issue #16147
*  		ALLENN 11/16/2001 - Issue #13667
*		TJL 12/17/03 - Issue #21076, Do not change InvStatus when ChgOrderAmt changes.
*						Remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/11/04 - Issue #24178, Add correct HQMA Auditing
*		TJL 02/03/09 - Issue #132154, Attempt to improve performance when Change Orders added to bill
*		CHS 12/16/2011 - B-08120 - Move bills to next month
*
* This trigger rejects insert of bJBCC (JB Change Order Header)
* if the following error condition exists:
*	none
*
* Updates corresponding fields in JBCC.
*

**************************************************************/
declare @co bCompany, @billmth bMonth, @billnum int, @errmsg varchar(255), @numrows int, 
   	@job bJob, @aco bACO, @acoitem bACOItem, @changeordertot bDollar, @contract bContract, 
   	@contractitem bContractItem, @JCOIchgorderunits bUnits, @JCOIchgorderunitprice bUnitCost,
   	@JCOIchgorderamt bDollar, @itembillgroup bBillingGroup,
   	@restrictbyYN bYN, @openinsertcursor int, @purgeyn bYN
   
select @numrows = @@rowcount, @openinsertcursor = 0

if @numrows = 0 return
set nocount on
   
declare bcInserted cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO, 
   	i.ChgOrderTot, Purge
from inserted i with (nolock)
order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO
   
open bcInserted
select @openinsertcursor = 1

fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco, 
   	@changeordertot, @purgeyn
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
   	
   	
   	select @restrictbyYN = RestrictBillGroupYN, @itembillgroup = BillGroup,
   		@contract = Contract
   	from bJBIN with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
   	select @acoitem = min(ACOItem)
   	from bJCOI with (nolock)
   	where JCCo = @co and Job = @job and ACO = @aco
   	while @acoitem is not null
   		begin	/* Begin ACOItem Loop */
   		if not exists(select 1 from bJBCX with (nolock) where JBCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem)
			/* insert JBCX records only if they do not exist on another bill's change order for this job and aco */
			begin
			/* Get Change Order Item Amounts. */
   			select @JCOIchgorderunits = ContractUnits, @contractitem = Item,
   				@JCOIchgorderunitprice = ContUnitPrice, @JCOIchgorderamt = ContractAmt
   			from bJCOI with (nolock)
   			where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem

			/* Validate the Change Order Items related ContractItem. - ContractItem must exist as a 'P' or 'B' type and 
			   if so, if restricting by BillGroup must be set to the appropriate BillGroup value. */
			if not exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract and Item = @contractitem and
				(BillType = 'P' or BillType = 'B')
				and ((@restrictbyYN = 'N')
				or (@restrictbyYN = 'Y' and ((BillGroup is null and @itembillgroup is null) or (@itembillgroup is not null and BillGroup = @itembillgroup)))))
           		begin
				goto GetNext
				end

   	 		/* back out old JBCX record if one already exists on this bill */
			if exists(select 1 from bJBCX where JBCo = @co and BillMonth = @billmth and  BillNumber = @billnum and
           		Job = @job and ACO = @aco and ACOItem = @acoitem)
				begin
				update bJBCX 
   				set ChgOrderUnits = @JCOIchgorderunits, ChgOrderAmt = @JCOIchgorderamt, AuditYN = 'N'
				where JBCo = @co and BillMonth = @billmth and  BillNumber = @billnum and
					Job = @job and ACO = @aco and ACOItem = @acoitem
				end
			else
				begin
   				insert bJBCX (JBCo, BillMonth,BillNumber, Job, ACO, ACOItem, ChgOrderUnits, ChgOrderAmt, AuditYN)
   				select @co, @billmth, @billnum, @job, @aco, @acoitem, @JCOIchgorderunits, @JCOIchgorderamt, 'N'
				end

			update bJBCX 
   			set AuditYN = 'Y'
			where JBCo = @co and BillMonth = @billmth and  BillNumber = @billnum and
				Job = @job and ACO = @aco and ACOItem = @acoitem
   
   			end

       	/*get next aco item*/
       	GetNext:
   		select @acoitem = min(ACOItem)
   		from bJCOI with (nolock)
   		where JCCo = @co and Job = @job and ACO = @aco and  ACOItem > @acoitem
   
		if @@rowcount = 0 select @acoitem = null
   		end		/* End ACOItem Loop */
   
   	update bJBIN
   	set ChgOrderAmt = ChgOrderAmt + @changeordertot, AuditYN = 'N'
   	from bJBIN with (nolock)
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
   	if @@rowcount = 0
		begin
   		select @errmsg = 'Error updating Bill Header.'
   		goto error
   		end
   
   	update bJBIN
   	set AuditYN = 'Y'
   	from bJBIN with (nolock)
   	where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
   
   	fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco,
   		@changeordertot, @purgeyn
   
   	end		/* End Inserted loop */


begin_audit:
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBCC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Job: ' + i.Job + 'ACO: ' + i.ACO, i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i
Join bJBCO c on c.JBCo = i.JBCo
Where c.AuditBills = 'Y' and i.AuditYN = 'Y'
   
if @openinsertcursor = 1
   	begin
   	close bcInserted
   	deallocate bcInserted
   	select @openinsertcursor = 0
   	end
   
return

error:
select @errmsg = @errmsg + ' - cannot insert JB Change Order Header!'
   
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
 
  
   
   
   /****** Object:  Trigger dbo.btJBCCu    Script Date: 8/28/99 9:37:39 AM ******/
   CREATE TRIGGER [dbo].[btJBCCu] ON [dbo].[bJBCC]
   FOR UPDATE AS
   

/**************************************************************
   * Modified: bc 09/19/00 - added update to JBIN.InvStatus if neccessary
   *  		ALLENN 11/16/2001 Issue #13667
   *     	kb 2/19/2 - issue #16147
   *		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
   *		TJL 12/17/03 - Issue #21076, Do not change InvStatus when ChgOrderAmt changes.
   *						Remove psuedo cursor
   *		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
   *		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
   *
   *
   * This trigger rejects update of bJBCC (JB Change Order Header)
   * if the following error condition exists:
   *	none
   *
   * Updates corresponding fields in JBCC.
   *
   *
   **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@co bCompany, @billnum int,  @changeordertot bDollar, @contract bContract, @job bJob, @aco bACO,
   	@billmth bMonth, @openinsertcursor int
   
   select @numrows = @@rowcount, @openinsertcursor = 0
   
   if @numrows = 0 return
   set nocount on
   
   /*Issue 13667*/
   If Update(Purge)
   	begin
   	return
   	end
   
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
   
   if update(ChgOrderTot)
   	begin
   	declare bcInserted cursor local fast_forward for
   	select i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO,
   		i.ChgOrderTot
   	from inserted i with (nolock)
   	order by i.JBCo, i.BillMonth, i.BillNumber, i.Job, i.ACO
   	
   	open bcInserted
   	select @openinsertcursor = 1
   	
   	fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco,
   		@changeordertot
   	while @@fetch_status = 0
    		begin
   		/* Get the difference or changed amount for ChgOrderTot. (Inserted - Deleted) */
   		select @changeordertot = @changeordertot - ChgOrderTot 
   		from deleted d with (nolock)
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco 
   
   		update bJBIN
         	set ChgOrderAmt = ChgOrderAmt + @changeordertot, AuditYN = 'N'
   		from bJBIN with (nolock)
   		where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
        	if @@rowcount = 0
   	    	begin
   			select @errmsg = 'Error updating Bill Header.'
   			goto error
   	        end
   
   		update bJBIN
         	set AuditYN = 'Y'
   		from bJBIN with (nolock)
   		where JBCo=@co and BillMonth = @billmth and BillNumber = @billnum 
   
   		fetch next from bcInserted into @co, @billmth, @billnum, @job, @aco,
   			@changeordertot
   
         	end
       end
   
   /*Issue 13667*/
   If exists(select 1 from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditBills = 'Y')
   	begin
   	If Update(ChgOrderTot)
   		begin
   		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   		Select 'bJBCC', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Job: ' + i.Job + 'ACO: ' + i.ACO, i.JBCo, 'C', 'ChgOrderTot', convert(varchar(13), d.ChgOrderTot), convert(varchar(13), i.ChgOrderTot), getdate(), SUSER_SNAME()
   		From inserted i
   		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Job = i.Job and d.ACO = i.ACO
   		Join bJBCO c on c.JBCo = i.JBCo
   		Where d.ChgOrderTot <> i.ChgOrderTot
   		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
   		end
   	end
   
   if @openinsertcursor = 1
   	begin
   	close bcInserted
   	deallocate bcInserted
   	select @openinsertcursor = 0
   	end
   
   return
   
   error:
   select @errmsg = @errmsg + ' - cannot update JB Change Order Header!'
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   if @openinsertcursor = 1
   	begin
   	close bcInserted
   	deallocate bcInserted
   	select @openinsertcursor = 0
   	end
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBCC].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBCC].[Purge]'
GO
