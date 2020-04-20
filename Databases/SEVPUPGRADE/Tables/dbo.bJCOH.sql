CREATE TABLE [dbo].[bJCOH]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ACOSequence] [smallint] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ApprovedBy] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ApprovalDate] [dbo].[bDate] NOT NULL,
[ChangeDays] [smallint] NULL,
[NewCmplDate] [dbo].[bDate] NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[IntExt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCOH_IntExt] DEFAULT ('E'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
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

/****** Object:  Trigger dbo.btJCOHd    Script Date: 8/28/99 9:37:46 AM ******/
CREATE   trigger [dbo].[btJCOHd] on [dbo].[bJCOH] for delete as
/*-----------------------------------------------------------------
* Created By:	JRE  Feb 26 1997  3:07PM
* Modified By:	bc 12/29/99 08:04
*				kb 5/22/00 - changed bBillGroup to be bBillingGroup
*				bc 11/12/02 - Issue 19330 - Removed Interfaced status from the JBIN check. 
*							Danf backed this issue out.
*				GF 10/15/2003 - issue #22726 - ACO was not included in JBCC check.
*				GF 11/07/2003 - issue #22944 - clean up trigger - check current days update to JCCM.
*				DANF 07/12/04 - Issue #25077 - Corrected cursor fetch statment.
*				GF 01/29/2008 - Issue #122541 allow delete from JB when InvStatus = 'I'. Remove 'I' from check.
*
*
*
* This trigger rejects delete in bJCOH
* if the following error condition exists:
*
*
*-----------------------------------------------------------------*/
declare @errmsg varchar(255), @validcnt int, @numrows int, @opencursor tinyint,
 @jcco bCompany, @job bJob, @aco bACO, @contract bContract, @retcode int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

set @opencursor = 0

-- Check bJCOI for detail - can be run outside of cursor
if exists(select 1 from deleted d join bJCOI o with (nolock) on d.JCCo = o.JCCo and d.Job = o.Job and d.ACO = o.ACO)
	begin
	select @errmsg = 'Entries exist in Change Order Items (JCOI)'
	goto error
	end


---- Check bJBCC for records - can be run outside of cursor
---- #122541 removed InvStatus = 'I' from bJBIN check
select @validcnt = count(*) from deleted d
join bJBIN n with (nolock) on n.JBCo = d.JCCo and n.Contract = d.Contract and n.InvStatus in('C','D','A')
JOIN bJBCC x with (nolock) ON d.JCCo = x.JBCo and d.Job = x.Job and d.ACO = x.ACO
if @validcnt <> 0
	begin
	select @errmsg = 'ACO exists in JB Progress Bill Change Orders (JBCC)'
	goto error
	end



-- if @numrows > 1 use a cursor to process each deleted row
if @numrows = 1
	begin
	select @jcco = JCCo, @job = Job, @aco = ACO, @contract = Contract
	from deleted
	end
else
	begin   
	declare bJCOH_delete cursor LOCAL FAST_FORWARD
	for select JCCo, Job, ACO, Contract
	from deleted

	open bJCOH_delete
	set @opencursor = 1

	fetch next from bJCOH_delete into @jcco, @job, @aco, @contract
	if @@fetch_status <> 0
		begin
        select @errmsg = 'Cursor error'
        goto error
		end
	end


delete_check:

-- update JCCM.CurrentDays
exec @retcode = dbo.bspJCCMCurrentDaysUpdate @jcco, @contract

-- get next record
if @numrows > 1
	begin
	fetch next from bJCOH_delete into @jcco, @job, @aco, @contract
	if @@fetch_status = 0 
		goto delete_check
	else
		begin
		close bJCOH_delete
		deallocate bJCOH_delete
		set @opencursor = 0
		end
	end


-- Audit HQ deletions
insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCOH',' JC Co#:' + convert(varchar(3),d.JCCo) + ' Job: ' + isnull(d.Job,'') + ' ACO: ' + isnull(d.ACO,''),
		d.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d join bJCCO c with (nolock) on d.JCCo = c.JCCo 
where c.AuditChngOrders = 'Y'



return


error:
	if @opencursor = 1
		begin
		close bJCOH_delete
		deallocate bJCOH_delete
		end

	select @errmsg = @errmsg + ' - cannot delete Change Order!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
    
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btJCOHi    Script Date: 8/28/99 9:37:46 AM ******/
   CREATE    trigger [dbo].[btJCOHi] on [dbo].[bJCOH] for insert as
   

/*-----------------------------------------------------------------
    * Created By:	JRE  Feb 26 1997
    * Modified By: GG 04/22/99 (SQL 7.0)
    *              kb 5/22/00 - changed bBillGroup to be bBillingGroup
    *				TV 04/05/01 - Update JCCM Current Days
    *				GF 11/07/2003 - issue #22944 - trigger clean-up and JCCM.CurrentDays update
    *
    *
    *
    * Rejects insert if Job not in JCJM
    *                if Contract not the same as JCJM.Contract
    *				  if ACO Sequence is null
    *
    * Updates:       The CurrentDays in JCCM
    *                The ProjCloseDate in JCCM
    *
    *-----------------------------------------------------------------*/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @opencursor tinyint,
   		@jcco bCompany, @job bJob, @aco bACO, @contract bContract, @retcode int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- check for ACO Sequence equal to Null
   select @validcnt = Count(*) from inserted where ACOSequence is Null
   if @validcnt <> 0
   	begin
       select @errmsg = 'ACO Sequence cannot be Null!'
       goto error
       end
   
   -- validate job
   select @validcnt = count(*) from inserted i join bJCJM j with (nolock) on j.JCCo = i.JCCo and j.Job = i.Job
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Job!'
       goto error
       end
   
   -- validate contract is assigned to job
   select @validcnt = count(*) from inserted i join bJCJM j with (nolock) 
   	on j.JCCo = i.JCCo and j.Job = i.Job and j.Contract = i.Contract
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Contract!'
   	goto error
   	end
   
   
   -- update JCCM.ProjCloseDate when newCmplDate is not null
   update bJCCM set ProjCloseDate = i.NewCmplDate
   from inserted i join bJCCM c on c.JCCo=i.JCCo and c.Contract=i.Contract
   where i.NewCmplDate is not null and isnull(i.NewCmplDate,'') <> isnull(c.ProjCloseDate,'')
   
   
   if @numrows = 1
   	select @jcco = JCCo, @job = Job, @aco = ACO, @contract = Contract
       from inserted
   else
       begin 
       declare bJCOH_insert cursor LOCAL FAST_FORWARD
   	for select JCCo, Job, ACO, Contract
   	from inserted
   
       open bJCOH_insert
       select @opencursor=1
   
       fetch next from bJCOH_insert into @jcco, @job, @aco, @contract
       if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   update_check:
   
   -- update JCCM.CurrentDays
   exec @retcode = dbo.bspJCCMCurrentDaysUpdate @jcco, @contract
   
   
   if @numrows > 1
   	begin
   	fetch next from bJCOH_insert into @jcco, @job, @aco, @contract
   	if @@fetch_status = 0
   		goto update_check
       else
       	begin
   		close bJCOH_insert
   		deallocate bJCOH_insert
   		end
   	end
   
   
   -- Audit inserts
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bJCOH',' JC Co#: ' + convert(varchar(3),i.JCCo) + ' Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
   		i.JCCo, 'A', null, null, null, getdate(), suser_sname()
   from inserted i join bJCCO c with (nolock) on c.JCCo = i.JCCo
   where c.AuditChngOrders = 'Y'
   
   
   
   
   return
   
   
   error:
   	if @opencursor = 1
   	 	begin
   	    close bJCOH_insert
   	   	deallocate bJCOH_insert
   	 	end
   
   	select @errmsg = @errmsg + ' - cannot insert Change Order!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCOHu    Script Date: 8/28/99 9:37:46 AM ******/
    CREATE  trigger [dbo].[btJCOHu] on [dbo].[bJCOH] for update as
    

/*-----------------------------------------------------------------
     * Created By:	JRE  Feb 26 1997  3:07PM
     * Modified By: GG 04/22/99 (SQL 7.0)
     *              kb 5/22/00 - changed bBillGroup to be bBillingGroup
     *				TV 01/24/02 - Update change in days needs to compare PMOI to JCOI
     *				DANF 02/20/02 - Added check for temp table #changedays before dropPing it.
     *				GF 11/07/2003 - issue #22944 problem with ChangeDays updating to JCCM.
     *
     *
     *             
     *-----------------------------------------------------------------*/
    declare @errmsg varchar(255), @validcnt int, @numrows int, @opencursor tinyint,
    		@jcco bCompany, @job bJob, @aco bACO, @contract bContract,
    		@changedays smallint, @oldchangedays smallint, @retcode int
     
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    set @opencursor = 0
     
    -- check for changes to JCCo
    if update(JCCo)
    	begin
    	select @errmsg = 'Cannot change JCCo'
    	goto error
    	end
     
    -- check for changes to Job
    if update(Job)
    	begin
    	select @errmsg = 'Cannot change Job'
    	goto error
    	end
     
    -- check for changes to Contract
    if update(Contract)
    	begin
    	select @errmsg = 'Cannot change Contract'
    	goto error
    	end
     
    -- check for changes to ACO
    if update(ACO)
    	begin
    	select @errmsg = 'Cannot change ACO'
    	goto error
    	end
     
    -- check for ACO Sequence equal to Null
    set @validcnt = 0
    select @validcnt = Count(*) from inserted where ACOSequence is Null
    if @validcnt <> 0
    	begin
    	select @errmsg = 'ACO Sequence cannot be Null'
    	goto error
    	end
    
    -- check to see if contract has changed
    set @validcnt = 0
    select @validcnt = count(*) from inserted i 
    join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO and d.Contract <> i.Contract
    if @validcnt <> 0
    	begin
    	select @errmsg = 'Contract may not be changed'
    	goto error
    	end
    
    -- when NewCmplDate has changed, update new completion date to JCCM.ProjCloseDate
    if update(NewCmplDate)
    BEGIN
    	update bJCCM set ProjCloseDate = i.NewCmplDate
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCM c on c.JCCo=i.JCCo and c.Contract=i.Contract
    	where c.JCCo=i.JCCo and c.Contract=i.Contract and i.NewCmplDate is not null
    	and i.NewCmplDate <> d.NewCmplDate  and c.ProjCloseDate <> i.NewCmplDate
    END
    
     
     
    if @numrows = 1
    	select  @jcco=i.JCCo, @job=i.Job, @aco=i.ACO, @contract=i.Contract, @changedays=i.ChangeDays, 
    			@oldchangedays=d.ChangeDays
    	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    else
    	begin
    	declare bJCOH_update cursor LOCAL FAST_FORWARD 
    	for select i.JCCo, i.Job, i.ACO, i.Contract, i.ChangeDays, d.ChangeDays
    	from inserted i join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    
    	open bJCOH_update
    	set @opencursor = 1
    
    	fetch next from bJCOH_update into @jcco, @job, @aco, @contract, @changedays, @oldchangedays
    	if @@fetch_status <> 0
    		begin
            select @errmsg = 'Cursor error'
            goto error
    		end
    	end
    
    
    
    update_check:
    
    -- update the JCCM.CurrentDays with change in days
    if isnull(@changedays,0) <> isnull(@oldchangedays,0)
       	begin
    	exec @retcode = dbo.bspJCCMCurrentDaysUpdate @jcco, @contract
       	end
    
    
    
    if @numrows > 1
    	begin
    	fetch next from bJCOH_update into @jcco, @job, @aco, @contract, @changedays, @oldchangedays
    	if @@fetch_status = 0
    		goto update_check
    	else
    		begin
            close bJCOH_update
            deallocate bJCOH_update
    		set @opencursor = 0
    		end
    	end
    
    
    
    Audit_Check:
    if not exists(select top 1 1 from inserted i join bJCCO c with (nolock) on i.JCCo=c.JCCo where c.AuditChngOrders = 'Y')
    	goto Trigger_End
    
    
    -- Insert records into HQMA for changes made to audited fields
    if update(Description)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.Description,'') <> isnull(i.Description,'') and c.AuditChngOrders = 'Y'
    END
    
    if update(ApprovedBy)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'ApprovedBy', d.ApprovedBy, i.ApprovedBy, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.ApprovedBy,'') <> isnull(i.ApprovedBy,'') and c.AuditChngOrders = 'Y'
    END
    if update(ApprovalDate)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'ApprovalDate', convert(char(8),d.ApprovalDate,1), convert(char(8),i.ApprovalDate,1), 
    			getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.ApprovalDate,'') <> isnull(i.ApprovalDate,'') and c.AuditChngOrders = 'Y'
    END
    if update(ChangeDays)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'ChangeDays', convert(varchar(6), isnull(d.ChangeDays,0)), convert(varchar(6), isnull(i.ChangeDays,0)), 
    			getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.ChangeDays,'') <> isnull(i.ChangeDays,'') and c.AuditChngOrders = 'Y'
    END
    if update(NewCmplDate)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'NewCmplDate', convert(char(8),d.NewCmplDate,1), convert(char(8),i.NewCmplDate,1),
    			getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.NewCmplDate,'') <> isnull(i.NewCmplDate,'') and c.AuditChngOrders = 'Y'
    END
    if update(BillGroup)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'BillGroup', d.BillGroup, i.BillGroup, getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.BillGroup,'') <> isnull(i.BillGroup,'') and c.AuditChngOrders = 'Y'
    END
    if update(ACOSequence)
    BEGIN
    	insert bHQMA select 'bJCOH', 'Job: ' + isnull(i.Job,'') + ' ACO: ' + isnull(i.ACO,''),
                i.JCCo, 'C', 'ACOSequence', convert(varchar(6), isnull(d.ACOSequence,0)), convert(varchar(6), isnull(i.ACOSequence,0)), 
    			getdate(), SUSER_SNAME()
    	from inserted i 
    	join deleted d on d.JCCo=i.JCCo and d.Job=i.Job and d.ACO=i.ACO
    	join bJCCO c with (nolock) on c.JCCo = i.JCCo
    	where isnull(d.ACOSequence,'') <> isnull(i.ACOSequence,'') and c.AuditChngOrders = 'Y'
    END
    
    
    
    
    Trigger_End:
    	return
    
    
    error:
    	if @opencursor = 1
    		begin
    		close bJCOH_update
    		deallocate bJCOH_update
    		end
    
    	select @errmsg = @errmsg + ' - cannot update Change Order!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
    
   
   
  
 




GO
CREATE UNIQUE CLUSTERED INDEX [biJCOH] ON [dbo].[bJCOH] ([JCCo], [Job], [ACO]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCOH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
