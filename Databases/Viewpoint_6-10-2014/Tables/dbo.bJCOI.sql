CREATE TABLE [dbo].[bJCOI]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[ACO] [dbo].[bACO] NOT NULL,
[ACOItem] [dbo].[bACOItem] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ApprovedMonth] [dbo].[bMonth] NOT NULL,
[ContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCOI_ContractUnits] DEFAULT ((0)),
[ContUnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCOI_ContUnitPrice] DEFAULT ((0)),
[ContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCOI_ContractAmt] DEFAULT ((0)),
[BillGroup] [dbo].[bBillingGroup] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ChangeDays] [smallint] NULL,
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

/****** Object:  Trigger dbo.btJCOId    Script Date: 8/28/99 9:37:46 AM ******/
CREATE   trigger [dbo].[btJCOId] on [dbo].[bJCOI] for DELETE as
/*--------------------------------------------------------------
*
*  Delete trigger for JCOI
*  Created By:	 JRE 02/27/97
*  Modified By: bc 12/29/99 added check on JBCX
*		 	     TV 04/06/01 Updates JCOH Change in days.
*               bc 11/12/02 - Issue 19330 - Removed Interfaced status from the JBIN check. Danf removed this issue.
*				GF 06/19/2003 - issue 21564 - the join on JBCX was only by JCCo and Job, needs ACO and ACOItem also.
*				GF 11/25/2003 - issue #23085 - changed error message when JCOD entries exist
*				GF 07/08/2004 - #25037 @ChangeDays update to JCOH need only check for not null. Missing zero change days
*				GF 11/02/2004 - issue #25054 set PMOI.InterfacedDate to null when deleted from bJCOI
*				GF 01/29/2008 - Issue #122541 allow delete from JB when InvStatus = 'I'. Remove 'I' from check.
*				TJL 01/18/2010 - Issue #135432, Reverse what was done in Issue #122541.  (See New Issue #137606)
*
*
*--------------------------------------------------------------*/
/***  basic declares for SQL Triggers ****/
declare @numrows int, @errmsg varchar(255), @opencursor int, @validcnt int, 
		@ChangeDays smallint, @jcco bCompany, @Job bJob, @Contract bContract, 
		@aco bACO, @acoitem bACOItem
    
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0

-- Check bJCOD for detail
if exists(select * from deleted d JOIN bJCOD o ON
	d.JCCo = o.JCCo and d.Job = o.Job and d.ACO = o.ACO and d.ACOItem = o.ACOItem)
	begin
	select @errmsg = 'Phase Detail exists for Change Order Item (JCOD). Cannot delete Change Order Item.'
	goto error
	end
      
---- Check bJBCX for detail
---- #122541 removed InvStatus = 'I' from bJBIN check  (See Issue 137606 relative to this problem)
---- #135432 put InvStatus = "I" back into bJBIN check  
select @validcnt = count(*)
from deleted d
join bJBIN n on n.JBCo = d.JCCo and n.Contract = d.Contract and n.InvStatus in('I','C','D','A')
JOIN bJBCX x on d.JCCo = x.JBCo and d.Job = x.Job and d.ACO = x.ACO and d.ACOItem = x.ACOItem
JOIN bJCJM m with (nolock) on m.JCCo = d.JCCo and m.Job = d.Job
WHERE NOT (n.InvStatus = 'I' AND m.ClosePurgeFlag = 'Y') -- #137606 - Allow delete if purging and 'I' record
if @validcnt <> 0
	begin
	select @errmsg = 'Item exists in JB Progress Bill Change Orders (JBCX)'
	goto error
	end
  
---- Delete bJCID detail
delete bJCID
from deleted where deleted.Job=bJCID.ACOJob and deleted.ACO=bJCID.ACO and deleted.ACOItem=bJCID.ACOItem

---- Audit deletes 
insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
select 'bJCOI','Job: ' + d.Job + ' ACO '+ d.ACO+' ACOItem ' + d.ACOItem, d.JCCo, 'D',null, null, null, getdate(), SUSER_SNAME()
from deleted d join bJCCO j on d.JCCo=j.JCCo where j.AuditChngOrders='Y'
    
-- Updates JCOH.ChangeDays and PMOI.InterfacedDate is exists
if @numrows = 1
	begin
	select @ChangeDays=ChangeDays, @jcco=JCCo, @Job=Job, @Contract=Contract,
		@aco=ACO, @acoitem=ACOItem
	from Deleted
	end
else
	begin
  	declare bChangeDays_cur cursor LOCAL FAST_FORWARD 
	for select ChangeDays, JCCo, Job, Contract, ACO, ACOItem
  	from Deleted

  	open bChangeDays_cur
	select @opencursor = 1

	fetch next from bChangeDays_cur into @ChangeDays, @jcco, @Job, @Contract, @aco, @acoitem
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		GoTo error
		End
  	end


--Update JCOH
update bJCOH 
	set ChangeDays = (Select Sum(isnull(ChangeDays,0)) from bJCOI where ACO=@aco and Job=@Job and JCCo=@jcco)
where JCCo=@jcco and Job=@Job and ACO=@aco

-- -- -- update bPMOI if exists
update bPMOI set InterfacedDate = null
where PMCo=@jcco and Project=@Job and ACO=@aco and ACOItem=@acoitem

if @opencursor = 1
	begin
	fetch next from bChangeDays_cur into @ChangeDays, @jcco, @Job, @Contract, @aco, @acoitem
	if @@fetch_status = 0
		begin
		Close bChangeDays_cur
		deallocate bChangeDays_cur
		set @opencursor = 0
		end
	End

Return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete from JCOI'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCOIi    Script Date: 8/28/99 9:38:24 AM ******/
CREATE       trigger [dbo].[btJCOIi] on [dbo].[bJCOI] for insert as

/*-----------------------------------------------------------------
*   This trigger rejects insert in bJCOI
*    if the following error condition exists:
*
*   Author: JRE Feb 26 1997  4:39PM
*   Revs: JM 8/6/98 - Converted date inserted/updated in bJCID to midnight rather than current system time.
*         kb 5/22/00 - changed bBillGroup to be bBillingGroup
*	      TV 04/04/01 - Update JCOH change of days
*		GF 05/31/2001 - Update OrigUnitPrice in JCCI if zero and one entered in JCOI.
*		GF 07/08/2004 - #25037 @ChangeDays update to JCOH need only check for not null. Missing zero change days
*
*-----------------------------------------------------------------*/
    declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,@itemtrans int,
    		@ApprovalDate smalldatetime, @opencursor tinyint, @key varchar(30), 
    		@JCCo bCompany,  @Job bJob, @ACO bACO, @ACOItem bACOItem, @Contract bContract, 
    		@Item bContractItem, @Description bDesc, @ApprovedMonth bMonth, @ContractUnits bUnits, 
    		@ContractAmt bDollar, @ContUnitPrice bUnitCost, @BillGroup bBillingGroup, @ChangeDays smallint
    		
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    set @opencursor = 0
    
    if @numrows = 1
        select  @JCCo = JCCo, @Job = Job, @ACO = ACO, @ACOItem = ACOItem, @Contract = Contract, @Item = Item, 
    		@Description = Description, @ApprovedMonth = ApprovedMonth, @ContractUnits = ContractUnits,
			@ContractAmt = ContractAmt, @ContUnitPrice=ContUnitPrice, @BillGroup = BillGroup, @ChangeDays = ChangeDays
        From inserted
    Else
    	begin
    	-- use a cursor to process each updated row
    	declare bJCOI_insert cursor LOCAL FAST_FORWARD
    		for select JCCo, Job, ACO, ACOItem, Contract, Item, Description, ApprovedMonth,
    			ContractUnits,ContractAmt, ContUnitPrice, BillGroup, ChangeDays
            From inserted
    
            open bJCOI_insert
            select @opencursor = 1
    
            fetch next from bJCOI_insert into @JCCo, @Job, @ACO, @ACOItem, @Contract, @Item, @Description, @ApprovedMonth,
    			@ContractUnits, @ContractAmt, @ContUnitPrice, @BillGroup, @ChangeDays
            if @@fetch_status <> 0
                begin
                select @errmsg = 'Cursor error'
                GoTo error
                End
        End
    
    update_check:
    if not exists (select * from bJCCI where JCCo = @JCCo and Contract =@Contract and Item = @Item)
        begin
        select @errmsg = 'Contract Item is Invalid '
        GoTo error
        End
    
    -- Validate ACO
    select  @ApprovalDate=ApprovalDate from bJCOH where JCCo = @JCCo and Job =@Job and ACO=@ACO
    if @@rowcount<>1
        begin
        select @errmsg = 'Change order header does not exist '
        GoTo error
        End
    
    if not exists (select Contract from bJCOH where JCCo = @JCCo and Job =@Job and ACO=@ACO)
        begin
        select @errmsg = 'Contract is different than Change Order Header '
        GoTo error
        End
    
    -- update Contract item Detail
    Update bJCID set Description=@Description, PostedDate=convert(varchar(10),getdate(),101),
		ContractAmt=@ContractAmt, ContractUnits= @ContractUnits, UnitPrice=@ContUnitPrice
    where JCCo=@JCCo and Contract=@Contract and Item=@Item and Mth=@ApprovedMonth and ACOJob=@Job and ACO=@ACO and ACOItem=@ACOItem
    -- insert bJCID record
    if @@rowcount=0
        begin
        EXEC @itemtrans = bspHQTCNextTrans 'bJCID', @JCCo, @ApprovedMonth, @errmsg output
        -- see IF next transaction number was good or not
        IF @itemtrans=0 goto error  -- error message comes FROM bspHQTCNextTrans
        -- insert JCID record here
        insert into bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource, Description,
                PostedDate, ActualDate, ContractAmt, ContractUnits, UnitPrice, ACOJob, ACO, ACOItem)
        select @JCCo, @ApprovedMonth, @itemtrans, @Contract, @Item, 'CO', 'JC ChngOrd', @Description,
                convert(varchar(10),getdate(),101), @ApprovalDate, @ContractAmt, @ContractUnits, @ContUnitPrice, @Job, @ACO, @ACOItem
        End
    
    -- update bJCCI OrigUnitPrice when zero and UnitPrice <> 0 and UM <> 'LS'
    if @ContUnitPrice <> 0
        begin
        update bJCCI set OrigUnitPrice = @ContUnitPrice
        where JCCo=@JCCo and Contract=@Contract and Item=@Item and OrigUnitPrice = 0 and UM <> 'LS'
        end
    
    -- Update ChangeDays in JCOH
    if @ChangeDays is not null
    	begin
    	update bJCOH
    	set ChangeDays = ChangeDays + @ChangeDays
    	where ACO = @ACO and Job = @Job and JCCo = @JCCo
    	end

    if @opencursor = 1
        begin
        fetch next from bJCOI_insert into @JCCo, @Job, @ACO, @ACOItem, @Contract,
            @Item, @Description, @ApprovedMonth, @ContractUnits, @ContractAmt,
            @ContUnitPrice, @BillGroup, @ChangeDays
    
        if @@fetch_status = 0 GoTo update_check
    
        Close bJCOI_insert
        deallocate bJCOI_insert
        End
      
    -- Audit inserts
    insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
    select 'bJCOI','Job: ' + i.Job + ' ACO '+ i.ACO+' ACOItem ' + i.ACOItem, i.JCCo, 'A',null, null, null, getdate(), SUSER_SNAME()
    from inserted i join bJCCO j on i.JCCo=j.JCCo
    where j.AuditChngOrders='Y'
    
    
    Return
    
    
    error:
    	if @opencursor = 1
    		begin
    		Close bJCOI_insert
    		deallocate bJCOI_insert
    		End
    
    	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Change Order Item!'
    	RAISERROR(@errmsg, 11, -1);
    	Rollback transaction
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCOIu    Script Date: 8/28/99 9:38:24 AM ******/
    CREATE   trigger [dbo].[btJCOIu] on [dbo].[bJCOI] for update as
    

/*-----------------------------------------------------------------
    *   This trigger rejects update in bJCOI
    *    if the following error condition exists:
    *
    *   Author: JRE Feb 26 1997  4:39PM
    *   Revs: JM 8/6/98 - Converted date inserted/updated in bJCID to
    *		midnight rather than current system time.
    *              kb 5/22/00 - changed bBillGroup to be bBillingGroup
    *		tv 04/04/01 - Updates JCOH Change of Days and PMOI
    *       MV 05/16/01 - Updates JCCI BillUnitPrice if UM <> LS and BillUnitPrice=0
    *       MV 05/24/01 - removed update to JCCI BillUnitPrice
    *		GF 05/31/2001 - Update OrigUnitPrice in JCCI if zero and one entered in JCOI.
    *		GF 07/08/2004 - #25037 @ChangeDays update to JCOH need only check for not null. Missing zero change days
    *
    *-----------------------------------------------------------------*/
    declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int ,@itemtrans int, 
    		@AuditChngOrders bYN, @ApprovalDate smalldatetime,
    		@opencursor tinyint, @key varchar(30), @JCCo bCompany, @Job bJob, @ACO bACO,
    		@ACOItem bACOItem, @Contract bContract,@Item bContractItem, @Description bDesc,
    		@ApprovedMonth bMonth, @ContractUnits bUnits, @ContractAmt bDollar, @ContUnitPrice bUnitCost, 
    		@BillGroup bBillingGroup, @oldDescription bDesc, @oldApprovedMonth bMonth, @oldItem bContractItem, 
    		@oldContractUnits bUnits, @oldContractAmt bDollar, @oldContUnitPrice bUnitCost, 
    		@oldBillGroup bBillingGroup, @ChangeDays Smallint, @oldchangedays smallint
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    set @opencursor = 0
    
    if update(JCCo)
        begin
        select @errmsg = 'Company may not be changed!'
        GoTo error
        end
    
    if update(Job)
        begin
        select @errmsg = 'Job may not be changed!'
        GoTo error
        end
    
    if update(ACO)
        begin
        select @errmsg = 'ACO may not be changed!'
        GoTo error
        end
    
    if update(ACOItem)
        begin
        select @errmsg = 'ACOItem may not be changed!'
        GoTo error
        end
    
    if update(Contract)
        begin
        select @errmsg = 'Contract may not be changed!'
        GoTo error
        end
    
    if update(ApprovedMonth)
        begin
        select @errmsg = 'Approved Month may not be changed!'
        GoTo error
        end
    
    if @numrows = 1
        select  @JCCo = JCCo, @Job = Job, @ACO = ACO, @ACOItem = ACOItem,
    		@Contract = Contract, @Item = Item, @Description = Description,
    		@ApprovedMonth = ApprovedMonth, @ContractUnits = ContractUnits,
    		@ContractAmt = ContractAmt, @ContUnitPrice=ContUnitPrice, @BillGroup = BillGroup, @ChangeDays = ChangeDays
        From inserted
    Else
    	begin
    	-- -- -- use a cursor to process each updated row
    	declare bJCOI_update cursor LOCAL FAST_FORWARD
    	for select JCCo, Job, ACO, ACOItem, Contract, Item, Description, ApprovedMonth,
    				ContractUnits, ContractAmt, ContUnitPrice, BillGroup, ChangeDays
    	From inserted
    
    	open bJCOI_update
    	select @opencursor = 1
    	fetch next from bJCOI_update into @JCCo, @Job, @ACO, @ACOItem, @Contract, @Item, @Description, @ApprovedMonth,
    			@ContractUnits, @ContractAmt, @ContUnitPrice, @BillGroup, @ChangeDays
            if @@fetch_status <> 0
                begin
                select @errmsg = 'Cursor error'
                GoTo error
                End
        End
    
    update_check:
    -- get old values
    select @oldItem=Item, @oldDescription = Description,@oldApprovedMonth =  ApprovedMonth,
            @oldContractUnits = ContractUnits, @oldContractAmt = ContractAmt,
            @oldContUnitPrice=ContUnitPrice, @oldBillGroup = BillGroup, @oldchangedays = ChangeDays
    from deleted where JCCo = @JCCo and Job = @Job and ACO = @ACO and ACOItem = @ACOItem
    if @@rowcount<>1
        begin
        select @errmsg = 'Could not find original Change Order Item'
        GoTo error
        End
    
    if not exists (select * from bJCCI where JCCo = @JCCo and Contract =@Contract and Item = @Item)
        begin
        select @errmsg = 'Contract Item is Invalid '
        GoTo error
        End
    
    -- Validate ACO
    select  @ApprovalDate=ApprovalDate from bJCOH where JCCo = @JCCo and Job =@Job and ACO=@ACO
    if @@rowcount<>1
        begin
        select @errmsg = 'Change order header does not exist '
        GoTo error
        End
    
    if not exists (select Contract from bJCOH where JCCo = @JCCo and Job =@Job and ACO=@ACO )
        begin
        select @errmsg = 'Contract is different than Change Order Header '
        GoTo error
        End
    
    --  update Contract item Detail
    Update bJCID set Item=@Item, Description=@Description, PostedDate=convert(varchar(10),getdate(),101),
            ContractAmt=@ContractAmt, ContractUnits= @ContractUnits, UnitPrice=@ContUnitPrice
    where JCCo=@JCCo and Mth=@ApprovedMonth and ACOJob=@Job and ACO=@ACO and ACOItem = @ACOItem
     -- for some reason the record was not out in bJCID record
    if @@rowcount=0
        begin
        EXEC @itemtrans = bspHQTCNextTrans 'bJCID', @JCCo, @ApprovedMonth, @errmsg output
        -- see IF next transaction number was good or not
        IF @itemtrans=0 goto error  -- error message comes FROM bspHQTCNextTrans
        -- insert JCID record here
        insert into bJCID (JCCo, Mth, ItemTrans, Contract, Item, JCTransType, TransSource, Description,
            PostedDate, ActualDate, ContractAmt, ContractUnits, UnitPrice, ACOJob, ACO, ACOItem)
        select @JCCo, @ApprovedMonth, @itemtrans, @Contract, @Item, 'CO', 'JC ChngOrd', @Description,
            convert(varchar(10),getdate(),101),@ApprovalDate,@ContractAmt, @ContractUnits,
            @ContUnitPrice, @Job, @ACO, @ACOItem
        End
    
    -- update bJCCI OrigUnitPrice when zero and UnitPrice <> 0 and UM <> 'LS'
    if @ContUnitPrice <> 0
        begin
        update bJCCI set OrigUnitPrice = @ContUnitPrice
        where JCCo=@JCCo and Contract=@Contract and Item=@Item and OrigUnitPrice = 0 and UM <> 'LS'
        end
    
    -- Update JCOH.ChangeDays if changed
    if @ChangeDays <> @oldchangedays
    	begin
    	update bJCOH
    	set ChangeDays = (Select Sum(isnull(ChangeDays,0)) from bJCOI where ACO = @ACO and Job = @Job and JCCo = @JCCo)
    	where JCCo=@JCCo and Job=@Job and ACO=@ACO
    	--update PMOI
    	update bPMOI
    	set ChangeDays = @ChangeDays
    	where ACO = @ACO and ACOItem = @ACOItem and PMCo = @JCCo and Project = @Job
    	end
    
    
    -- Audit updates
    if (select @AuditChngOrders from bJCCO where JCCo=@JCCo)='Y'
    BEGIN
       select @key='Job: ' + @Job + ' ACO '+ @ACO+' ACOItem ' + @ACOItem
       if @Description<>@oldDescription
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key,@JCCo, 'C', 'Description', @oldDescription, @Description,getdate(), SUSER_SNAME()
          end
    
       if @Item<>@oldItem
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key, @JCCo, 'C', 'Item', @oldItem, @Item,getdate(), SUSER_SNAME()
          end
    
       if @ContractUnits<>@oldContractUnits
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key, @JCCo, 'C', 'ContractUnits', convert(varchar(18),@oldContractUnits),
                 convert(varchar(18),@ContractUnits), getdate(), SUSER_SNAME()
          end
    
       if @ContUnitPrice<>@oldContUnitPrice
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key, @JCCo, 'C', 'ContUnitPrice', convert(varchar(18),@oldContUnitPrice),
                 convert(varchar(18),@ContUnitPrice), getdate(), SUSER_SNAME()
          end
    
       if @ContractAmt<>@oldContractAmt
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key, @JCCo, 'C', 'ContractAmt', convert(varchar(18),@oldContractAmt),
                 convert(varchar(18),@ContractAmt), getdate(), SUSER_SNAME()
          end
    
     if @BillGroup<>@oldBillGroup
          begin
          insert into bHQMA (TableName, KeyString, Co, RecType,FieldName,OldValue,NewValue,DateTime,UserName)
          select 'bJCOI',@key, @JCCo, 'C', 'BillGroup', @oldBillGroup, @BillGroup, getdate(), SUSER_SNAME()
          end
    END
    
    if @opencursor = 1
        begin
        fetch next from bJCOI_update into @JCCo,@Job,@ACO,@ACOItem,@Contract,
                @Item,@Description,@ApprovedMonth,@ContractUnits,
                @ContractAmt,@ContUnitPrice,@BillGroup, @ChangeDays
    
        if @@fetch_status = 0 GoTo update_check
    
        Close bJCOI_update
        deallocate bJCOI_update
        select @opencursor = 0
        End
    
    Return
    
    
    
    
    error:
        if @opencursor = 1
            begin
            Close bJCOI_update
            deallocate bJCOI_update
            End
    
        select @errmsg = isnull(@errmsg,'') + ' - cannot update Change Order Item!'
        RAISERROR(@errmsg, 11, -1);
        Rollback transaction
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCOI] ON [dbo].[bJCOI] ([JCCo], [Job], [ACO], [ACOItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCOI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
