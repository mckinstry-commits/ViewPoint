CREATE TABLE [dbo].[bJCID]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ItemTrans] [dbo].[bTrans] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[JCTransType] [varchar] (2) COLLATE Latin1_General_BIN NOT NULL,
[TransSource] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bTransDesc] NULL,
[PostedDate] [smalldatetime] NOT NULL,
[ActualDate] [smalldatetime] NOT NULL,
[ContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCID_ContractAmt] DEFAULT ((0)),
[ContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCID_ContractUnits] DEFAULT ((0)),
[UnitPrice] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bJCID_UnitPrice] DEFAULT ((0)),
[BilledUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCID_BilledUnits] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCID_BilledAmt] DEFAULT ((0)),
[ReceivedAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCID_ReceivedAmt] DEFAULT ((0)),
[CurrentRetainAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCID_CurrentRetainAmt] DEFAULT ((0)),
[BatchId] [dbo].[bBatchID] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[ACOJob] [dbo].[bJob] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLTransAcct] [dbo].[bGLAcct] NULL,
[GLOffsetAcct] [dbo].[bGLAcct] NULL,
[ReversalStatus] [tinyint] NOT NULL CONSTRAINT [DF_bJCID_ReversalStatus] DEFAULT ((0)),
[ARCo] [dbo].[bCompany] NULL,
[ARTrans] [int] NULL,
[ARTransLine] [smallint] NULL,
[ARInvoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ARCheck] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BilledTax] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SrcJCCo] [dbo].[bCompany] NULL,
[ProjUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCID_ProjUnits] DEFAULT ((0)),
[ProjDollars] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCID_ProjDollars] DEFAULT ((0)),
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
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btJCIDd    Script Date: 8/28/99 9:37:44 AM ******/
    CREATE   TRIGGER [dbo].[btJCIDd] ON [dbo].[bJCID] FOR delete AS
    

/**************************************************************
 * Created By:		JRE			- 07/10/97
 * Modified By:		DanF		- Issue #16270 exit trigger if purging job so that contract amounts
 *			can be stored in contract history
 *			GH		6/11/02		- Issue 17606 Changing Start Month in JCCM was not removing
 *			dollars in old month from JCIP
 *			GF		10/28/2004	- issue #25828
 *			DC		2/8/05		- issue #27056
 *			DANF	03/10/2005	- issue 23336 Add revenue projections
 *			CHS		05/15/2009	- Issue #133437
 *
 * This trigger rejects delete in bJCID (JC Item Detail)
 *	 if the following error condition exists:
 *
 *
 *
 *      Updates corresponding fields in JCIP, JCCI, JCCM.
 *		note
 *		(Future checks AR)
 *
 **************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int, @opencursor tinyint,
            @jcco bCompany, @mth bMonth, @itemtrans bTrans, @contract bContract, 
    		@item bContractItem, @jctranstype char(2), @billedunits bUnits,
    		@billedamt bDollar,@billedtax bDollar, @receivedamt bDollar,
    		@currentretainamt bDollar, @origcontractunits bUnits, @origcontractamt bDollar,
            @contractunits bUnits, @contractamt bDollar, @jcci_exists int,
   		@ProjUnits bUnits, @ProjDollars bDollar
    
    SELECT @numrows = @@rowcount
    if @numrows = 0 return
    SET nocount on
    
    -- If purging job do not update JCIP so that contract amounts can be updated to Job History.
    select @validcnt = count(*) 
    from bJCJM j join deleted d on d.JCCo=j.JCCo and d.ACOJob=j.Job
    where j.ClosePurgeFlag='Y'
    if @numrows = @validcnt  return
    
    set @opencursor = 0
    
    
    -- -- -- process deleted transaction(s)
    if @numrows = 1
    	select @jcco=JCCo, @mth=Mth, @itemtrans=ItemTrans
    	from deleted  --DC 27056
    else
    	begin
    	-- use a cursor to process each updated row
    	declare bJCID_delete cursor LOCAL FAST_FORWARD
    	for select JCCo, Mth, ItemTrans
    	from deleted  --DC 27056
    
    	open bJCID_delete
    	set @opencursor = 1
    	
    	fetch next from bJCID_delete into @jcco, @mth, @itemtrans
    	
    	if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
    
    
    bJCID_delete:
    -- -- -- read the record
    select @contract=Contract, @item=Item, @jctranstype=JCTransType,
    		@billedunits=BilledUnits,@billedtax=d.BilledTax,@billedamt=d.BilledAmt,
    		@receivedamt=d.ReceivedAmt, @currentretainamt=d.CurrentRetainAmt,
    		@origcontractunits =Case when d.JCTransType='OC' then d.ContractUnits else 0 end,
    		@origcontractamt =  Case when d.JCTransType='OC' then d.ContractAmt else 0 end,
    		@contractunits = d.ContractUnits, @contractamt = d.ContractAmt,
   		@ProjUnits=d.ProjUnits, @ProjDollars=d.ProjDollars
    from deleted d
    where @jcco=d.JCCo AND @mth=d.Mth AND @itemtrans=d.ItemTrans
    
    
    -- -- -- test if JCCI still exists  - if not then skip JCIP & JCCI updates.
    select @jcci_exists=count(*) from bJCCI 
    where JCCo=@jcco and Contract=@contract and Item=@item
    If @jcci_exists = 0 goto SkipItemUpdates
    
    
    -- -- -- update bJCIP
    update bJCIP
    	set BilledUnits = ISNULL(BilledUnits,0) - ISNULL(@billedunits,0),
    		BilledTax = ISNULL(BilledTax,0) - ISNULL(@billedtax,0),
    		BilledAmt = ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
    		ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
    		CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0),
    		OrigContractUnits = ISNULL(OrigContractUnits,0) - ISNULL(@origcontractunits,0),
    		OrigContractAmt =ISNULL(OrigContractAmt,0) - ISNULL(@origcontractamt,0),
    		ContractUnits = ISNULL(ContractUnits,0) - ISNULL(@contractunits,0),
    		ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0),
   		ProjUnits = ISNULL(ProjUnits,0) - ISNULL(@ProjUnits,0),
   		ProjDollars = ISNULL(ProjDollars,0) - ISNULL(@ProjDollars,0)
    where JCCo=@jcco and Contract=@contract and Item=@item AND Mth=@mth
    
    -- -- -- Type OC is maintained in the JCCI triggers
    if @jctranstype <> 'OC' and 
   	(ISNULL(@billedunits,0)<>0 or ISNULL(@billedamt,0)<>0 or ISNULL(@receivedamt,0)<>0 or
   	ISNULL(@currentretainamt,0)<>0 or ISNULL(@contractunits,0)<>0 or ISNULL(@contractamt,0)<>0)
    	begin
    	-- -- -- OrigUnitPrice, OrigContractUnits, OrigContractAmt = dont UPDATE maintained directly
    	-- -- -- cant back out deleted UnitPrice
    	update bJCCI
    		set BilledUnits = ISNULL(BilledUnits,0) - ISNULL(@billedunits,0),
    			BilledAmt = ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
    			ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
    			CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0),
    			ContractUnits = ISNULL(ContractUnits,0) - ISNULL(@contractunits,0),
    			ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0)
    	where JCCo=@jcco and Contract=@contract and Item=@item
    	end
    
    
    SkipItemUpdates:
    
    -- -- -- update bJCCM
    update bJCCM 
    	set OrigContractAmt = ISNULL(OrigContractAmt,0) - ISNULL(@origcontractamt,0),
    		ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0),
    		BilledAmt =ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
    		ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
    		CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0)
    where JCCo=@jcco AND Contract=@contract
    
    
    
    if @numrows > 1
    	begin
    	fetch next from bJCID_delete into @jcco, @mth, @itemtrans
     	if @@fetch_status = 0
     		goto bJCID_delete
     	else
     		begin
     		close bJCID_delete
     		deallocate bJCID_delete
    		set @opencursor = 0
     		end
     	end
     
    
    return
    
    
	-- Issue #133437
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
			  select AttachmentID, suser_name(), 'Y' 
				  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
				  where d.UniqueAttchID is not null 
    
    
    error:
    	if @opencursor = 1
     		begin
     		close bJCID_delete
     		deallocate bJCID_delete
    		set @opencursor = 0
     		end
    
    	SELECT @errmsg = isnull(@errmsg,'') + ' - cannot delete Item Detail!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCIDi    Script Date: 8/28/99 9:37:44 AM ******/
CREATE  TRIGGER [dbo].[btJCIDi] ON [dbo].[bJCID] FOR insert AS
/**************************************************************
* Modified By:      DANF 04/11/02  Added InterCompany Transaction Type.
*                   TV 11/26/02 Added the 'RU'(roll up) Trans Type
*                   GF 10/26/2004 - issue #25828 clean-up trigger performance
*                   DANF 03/10/2005 - issue 23336 Add revenue projections
*                   jime 01/13/08 - Removed Cursors
*
*
*  This trigger rejects insert in bJCID (JC Item Detail)
* if the following error condition exists:
*
*   Invalid JCCI
*       JCTransType not in ('OC','CO','RA','AR','JB','IC', 'RU', 'RP')
*       TransSource in ('JC OrigEst','JC ChngOrd','JC RevAdj',
*                   'AR Inv','AR Cash','AR RelRet','AR FinChg', 'JC RevProj')
*
*      UPDATEs corresponding fields in JCIP, JCCI, JCCM.
*
*  Note JCCI is not UPDATE when i.JCTransType='OC' because JCCI is writing
*       this record(s) AND thus has already been UPDATEi.
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
		@jcco bCompany, @mth bMonth, @itemtrans bTrans, @Contract bContract,
		@Item bContractItem, @JCTransType char(2), @BilledUnits bUnits,
		@BilledAmt bDollar,@BilledTax bDollar, @ReceivedAmt bDollar,
		@CurrentRetainAmt bDollar, @OrigContractUnits bUnits,
		@OrigContractAmt bDollar, @ContractUnits bUnits, @ContractAmt bDollar,
		@ProjUnits bUnits, @ProjDollars bDollar, @opencursor tinyint

SELECT @numrows = @@rowcount
if @numrows = 0 return
SET nocount on

begin

-- -- -- validate JCTransType -- 11/12/96 only original contractis currently allowed
if exists (select top 1 i.JCTransType from inserted i 
where JCTransType not in ('OC','CO','JC','AR','JB','IC','RU','RP'))  
	begin
	SELECT @errmsg = 'Invalid Transaction Type'
	goto error
	end

-- -- -- validate Source
if exists (select top 1 i.TransSource from inserted i 
	where TransSource not in ('JC OrigEst','JC ChngOrd','JC RevAdj','AR Invoice','AR Receipt','AR RelRet',
			'ARFinanceC', 'ARRelease', 'JB', 'Roll Up','JC RevProj'))
	begin
	SELECT @errmsg = 'Invalid Source'
	goto error
	end

-- -- -- check if Contract Item exists
if exists (select top 1 i.Contract from inserted i 
	left join bJCCI c on c.JCCo = i.JCCo AND c.Contract=i.Contract AND c.Item=i.Item where c.Item is null)
	begin
	SELECT @errmsg = 'Contract item does not exist'
	goto error
	end

-- -- -- check if original estimate is in the start month
--if exists (select top 1 i.Contract from inserted i 
--	join bJCCM c on c.JCCo=i.JCCo AND c.Contract=i.Contract
--			where i.JCTransType='OC' and i.Mth<>c.StartMonth)
--	begin
--	SELECT @errmsg = 'Original Estimates must use the Contract Start Month for the Month'
--	goto error
--	end




/******************************/
/* UPDATE bJCIP, bJCCI, bJCCM */
/******************************/
-- -- -- first make sure that the JCIP records exists
insert into bJCIP (JCCo, Contract, Item, Mth)
select distinct i.JCCo, i.Contract, i.Item, i.Mth
from inserted i 
where not exists(select top 1 1 from bJCIP j where j.JCCo=i.JCCo
         and j.Contract=i.Contract and j.Item=i.Item and j.Mth = i.Mth)


-- -- -- update bJCIP
update bJCIP 
   set BilledUnits = ISNULL(bJCIP.BilledUnits,0) + ISNULL(i.sBilledUnits,0),
        BilledTax = ISNULL(bJCIP.BilledTax,0) + ISNULL(i.sBilledTax,0),
        BilledAmt = ISNULL(bJCIP.BilledAmt,0) + ISNULL(i.sBilledAmt,0),
        ReceivedAmt =ISNULL(bJCIP.ReceivedAmt,0) + ISNULL(i.sReceivedAmt,0),
        CurrentRetainAmt= ISNULL(bJCIP.CurrentRetainAmt,0) + ISNULL(i.sCurrentRetainAmt,0),
        OrigContractUnits = ISNULL(bJCIP.OrigContractUnits,0) + ISNULL(i.sOrigContractUnits,0),
        OrigContractAmt =ISNULL(bJCIP.OrigContractAmt,0) + ISNULL(i.sOrigContractAmt,0),
        ContractUnits = ISNULL(bJCIP.ContractUnits,0) + ISNULL(i.sContractUnits,0),
        ContractAmt = ISNULL(bJCIP.ContractAmt,0) + ISNULL(i.sContractAmt,0),
        ProjUnits = ISNULL(bJCIP.ProjUnits,0) + ISNULL(i.sProjUnits,0),
        ProjDollars = ISNULL(bJCIP.ProjDollars,0) + ISNULL(i.sProjDollars,0)
from bJCIP
join (select JCCo, Contract, Item, Mth
        ,sBilledUnits=sum(BilledUnits) 
        ,sBilledTax = sum(BilledTax)
        ,sBilledAmt = sum(BilledAmt)
        ,sReceivedAmt =sum(ReceivedAmt)
        ,sCurrentRetainAmt= sum(CurrentRetainAmt)
        ,sOrigContractUnits = sum(Case when JCTransType='OC' then ContractUnits else 0 end)
        ,sOrigContractAmt =sum(Case when JCTransType='OC' then ContractAmt else 0 end)
        ,sContractUnits = sum(ContractUnits)
        ,sContractAmt = sum(ContractAmt)
        ,sProjUnits = sum(ProjUnits)
        ,sProjDollars = sum(ProjDollars)
	from inserted 
	group by JCCo, Contract, Item, Mth)
    as i on i.JCCo=bJCIP.JCCo and i.Contract=bJCIP.Contract
         and i.Item=bJCIP.Item AND i.Mth=bJCIP.Mth


-- -- -- update bJCCI - Type OC is maintained in the bJCCI triggers
update bJCCI 
	set BilledUnits = ISNULL(bJCCI.BilledUnits,0) + ISNULL(i.sBilledUnits,0),
		BilledAmt = ISNULL(bJCCI.BilledAmt,0) + ISNULL(i.sBilledAmt,0),
		ReceivedAmt =ISNULL(bJCCI.ReceivedAmt,0) + ISNULL(i.sReceivedAmt,0),
		CurrentRetainAmt= ISNULL(bJCCI.CurrentRetainAmt,0) + ISNULL(i.sCurrentRetainAmt,0),
		ContractUnits = ISNULL(bJCCI.ContractUnits,0) + ISNULL(i.sContractUnits,0),
		ContractAmt = ISNULL(bJCCI.ContractAmt,0) + ISNULL(i.sContractAmt,0)
from bJCCI
join   (select JCCo, Contract, Item
			,sBilledUnits=sum(BilledUnits) 
			,sBilledAmt = sum(BilledAmt)
			,sReceivedAmt =sum(ReceivedAmt)
			,sCurrentRetainAmt= sum(CurrentRetainAmt)
			,sContractUnits = sum(ContractUnits)
			,sContractAmt = sum(ContractAmt)
		from inserted a 
		where JCTransType<>'OC' 
		group by JCCo, Contract, Item)
		as i on i.JCCo=bJCCI.JCCo and i.Contract=bJCCI.Contract and i.Item=bJCCI.Item 
where (ISNULL(sBilledUnits,0)<>0
or ISNULL(sBilledAmt,0)<>0 or ISNULL(sReceivedAmt,0)<>0
or ISNULL(sCurrentRetainAmt,0)<>0 or ISNULL(sContractUnits,0)<>0 
or ISNULL(sContractAmt,0)<>0)


-- -- -- update bJCCM
update bJCCM set OrigContractAmt = ISNULL(bJCCM.OrigContractAmt,0) + ISNULL(i.sOrigContractAmt,0),
                ContractAmt = ISNULL(bJCCM.ContractAmt,0) + ISNULL(i.sContractAmt,0),
                BilledAmt = ISNULL(bJCCM.BilledAmt,0) + ISNULL(i.sBilledAmt,0),
                ReceivedAmt =ISNULL(bJCCM.ReceivedAmt,0) + ISNULL(i.sReceivedAmt,0),
                CurrentRetainAmt= ISNULL(bJCCM.CurrentRetainAmt,0) + ISNULL(i.sCurrentRetainAmt,0)
from bJCCM
join (select JCCo, Contract
            ,sOrigContractAmt =sum(Case when a.JCTransType='OC' then a.ContractAmt else 0 end)
            ,sContractAmt = sum(ContractAmt) 
            ,sBilledAmt = sum(BilledAmt)
            ,sReceivedAmt =sum(ReceivedAmt)
            ,sCurrentRetainAmt= sum(CurrentRetainAmt)
      from inserted a 

      group by JCCo, Contract
) as i on i.JCCo=bJCCM.JCCo and i.Contract=bJCCM.Contract

where isnull(sOrigContractAmt,0)<>0
	or ISNULL(sContractAmt,0)<>0
	or ISNULL(sBilledAmt,0)<>0
	or ISNULL(sReceivedAmt,0)<>0
	or ISNULL(sCurrentRetainAmt,0)<>0


end



return
   

error: 
  SELECT @errmsg = isnull(@errmsg,'') +  ' - cannot insert Item Detail!'
  RAISERROR(@errmsg, 11, -1);
  rollback transaction

   
   


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/****** Object:  Trigger dbo.btJCIDu    Script Date: 8/28/99 9:37:45 AM ******/
   CREATE    TRIGGER [dbo].[btJCIDu] ON [dbo].[bJCID] FOR update AS
   

/**************************************************************
    * Created By:	JRE
    * Modified By:	DANF 04/11/02 - Added Inter Company transaction type.
    *				GF 10/26/2004 - issue #25828 clean-up trigger performance
    *				DANF 03/10/2005 - issue 23336 Add revenue projections
    *				DANF 01/19/2005 - Issue 119779 Correct transaction source validation.
    *   			JonathanP 01/09/08 - #128879 - Added code to skip procedure if only UniqueAttachID changed.
    *
    * This trigger rejects update in bJCID (JC Item Detail)
    * IF the following error condition exists:
    *           
    *
    *   	 Invalid JCCI
    *       JCTransType not in ('OC','CO','RA','AR','JB','IC', 'RP')
    *       TransSource in ('JC OrigEst','JC ChngOrd','JC RevAdj',
    *                   'AR Inv','AR Cash','AR RelRet','ARFinanceC', 'ARRelease', 'JC RevProj')
    *
    *      Updates corresponding fields in JCIP, JCCI, JCCM.
    *		note
    *  Note JCCI is not UPDATE when i.JCTransType='OC' because JCCI is writing
    *       this record(s) AND thus has already been UPDATEd.
    **************************************************************/
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
   		@opencursor tinyint, @jcco bCompany, @mth bMonth, @itemtrans bTrans,
   		@contract bContract, @item bContractItem, @jctranstype char(2),
   		@billedunits bUnits, @billedamt bDollar, @billedtax bDollar,
   		@receivedamt bDollar, @currentretainamt bDollar,
   		@origcontractunits bUnits, @origcontractamt bDollar,
   		@contractunits bUnits, @contractamt bDollar,
   		@ProjUnits bUnits, @ProjDollars bDollar
   
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
   
    --If the only column that changed was UniqueAttachID, then skip validation.        
	IF dbo.vfOnlyColumnUpdated(COLUMNS_UPDATED(), 'bJCID', 'UniqueAttchID') = 1
	BEGIN 
		goto Trigger_Skip
	END    
   
   set @opencursor = 0
   
   -- -- -- check key parts for changes
   if update(JCCo) or update(Mth) or update(ItemTrans)
   	begin
   	select @errmsg = 'JCCo, Month, and Item Trans # may not be changed'
     	goto error
     	end
   
   -- -- -- check if Type of 'OC' was updated
   if exists(select * from inserted i join deleted d on i.JCCo=d.JCCo and i.Mth=d.Mth and i.ItemTrans=d.ItemTrans
   		where (i.JCTransType='OC' and d.JCTransType<>'OC') or (i.JCTransType<>'OC' and d.JCTransType='OC'))
   	begin
   	select @errmsg = 'Transaction Type may not be changed'
     	goto error
     	end
   
   -- -- -- validate JCTransType
   -- -- -- 11/12/96 only original contractis currently allowed
   select @validcnt = count(*) from inserted i 
   where JCTransType in ('OC','CO','JC','AR','JB','IC','RP')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Transaction Type'
     	goto error
     	end
   
   -- -- -- validate Source
   select @validcnt = count(*) from inserted i
   where TransSource in ('JC OrigEst','JC ChngOrd','JC RevAdj','AR Invoice','AR Receipt','AR RelRet','ARFinanceC', 'ARRelease', 'JB','JC RevProj')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Source'
     	goto error
     	end
   
   -- -- -- check IF Contract Item exists
   select @validcnt = count(*) FROM inserted i
   join bJCCI d on d.JCCo = i.JCCo AND i.Contract=d.Contract AND i.Item=d.Item
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Contract item does not exist'
     	goto error
     	end
   
   -- -- -- -- -- -- check IF original estimate is in the start month
   -- -- -- if update(Mth)
   -- -- -- 	begin
   -- -- -- 	select @nullcnt = count(*) FROM inserted i
   -- -- -- 	join bJCCM c ON c.JCCo=i.JCCo AND c.Contract=i.Contract
   -- -- -- 	where i.JCTransType='OC' AND i.Mth <> c.StartMonth
   -- -- -- 	if @nullcnt <> 0
   -- -- -- 		begin
   -- -- -- 		select @errmsg = 'Original Estimates must use the Contract Start Month for the Month'
   -- -- -- 		goto error
   -- -- -- 		end
   -- -- -- 	end
   
   
   
   /******************************/
   /* UPDATE bJCIP, bJCCI, bJCCM */
   /******************************/
   /***********************************************/
   /* first make sure that the JCIP record exists */
   /***********************************************/
   insert into bJCIP (JCCo,Contract,Item,Mth)
   select distinct i.JCCo, i.Contract, i.Item, i.Mth
  
   from inserted i where not exists(select 1 from bJCIP j where j.JCCo=i.JCCo
   					and j.Contract=i.Contract and j.Item=i.Item and j.Mth=i.Mth)
   
   
   -- -- -- process inserted transaction
   if @numrows = 1
   	select @jcco=JCCo, @mth=Mth, @itemtrans=ItemTrans
   	from inserted
   else
   	begin
   	-- use a cursor to process each updated row
   	declare bJCID_insert cursor LOCAL FAST_FORWARD
   	for select JCCo, Mth, ItemTrans
   	from inserted
   
   	open bJCID_insert
   	set @opencursor = 1
   	
   	fetch next from bJCID_insert into @jcco, @mth, @itemtrans
   	
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   bJCID_insert:
   -- -- -- read inserted record
   select @contract=Contract, @item=Item, @jctranstype=JCTransType,
   		@billedunits=BilledUnits, @billedamt=i.BilledAmt, @billedtax=i.BilledTax,
   		@receivedamt=i.ReceivedAmt, @currentretainamt=i.CurrentRetainAmt,
   		@origcontractunits =Case when i.JCTransType='OC' then i.ContractUnits else 0 end,
   		@origcontractamt =  Case when i.JCTransType='OC' then i.ContractAmt else 0 end,
   		@contractunits = i.ContractUnits, @contractamt = i.ContractAmt,
   		@ProjUnits=i.ProjUnits, @ProjDollars=i.ProjDollars
   from inserted i
   where i.JCCo = @jcco and i.Mth = @mth and i.ItemTrans = @itemtrans
   
   
   -- -- -- add the new amounts
   update bJCIP
   	set BilledUnits = ISNULL(BilledUnits,0) + ISNULL(@billedunits,0),
   		BilledTax = ISNULL(BilledTax,0) + ISNULL(@billedtax,0),
   		BilledAmt = ISNULL(BilledAmt,0) + ISNULL(@billedamt,0),
   		ReceivedAmt =ISNULL(ReceivedAmt,0) + ISNULL(@receivedamt,0),
   		CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) + ISNULL(@currentretainamt,0),
   		OrigContractUnits = ISNULL(OrigContractUnits,0) + ISNULL(@origcontractunits,0),
   		OrigContractAmt =ISNULL(OrigContractAmt,0) + ISNULL(@origcontractamt,0),
   		ContractUnits = ISNULL(ContractUnits,0) + ISNULL(@contractunits,0),
   		ContractAmt = ISNULL(ContractAmt,0) + ISNULL(@contractamt,0),
   		ProjUnits = ISNULL(ProjUnits,0) + ISNULL(@ProjUnits,0),
   		ProjDollars = ISNULL(ProjDollars,0) + ISNULL(@ProjDollars,0)
   where JCCo=@jcco and Contract=@contract and Item=@item and Mth=@mth
   
   
   -- -- -- Type OC is maintained in the JCCI triggers
   if @jctranstype <> 'OC' and 
   	(ISNULL(@billedunits,0)<>0 or ISNULL(@billedamt,0)<>0 or ISNULL(@receivedamt,0)<>0 or
   	ISNULL(@currentretainamt,0)<>0 or ISNULL(@contractunits,0)<>0 or ISNULL(@contractamt,0)<>0)
   	begin
   	-- -- -- OrigUnitPrice, OrigContractUnits, OrigContractAmt = dont UPDATE maintained directly
       -- -- -- cant back out inserted UnitPrice
   	update bJCCI
   		set BilledUnits = ISNULL(BilledUnits,0) + ISNULL(@billedunits,0),
   			BilledAmt = ISNULL(BilledAmt,0) + ISNULL(@billedamt,0),
   			ReceivedAmt =ISNULL(ReceivedAmt,0) + ISNULL(@receivedamt,0),
   			CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) + ISNULL(@currentretainamt,0),
   			ContractUnits = ISNULL(ContractUnits,0) + ISNULL(@contractunits,0),
   			ContractAmt = ISNULL(ContractAmt,0) + ISNULL(@contractamt,0)
   	where JCCo=@jcco and Contract=@contract and Item=@item
   	end
   
   if (ISNULL(@origcontractamt,0)<>0 or ISNULL(@contractamt,0)<>0 or 
   	ISNULL(@billedamt,0)<>0 or ISNULL(@receivedamt,0)<>0 or ISNULL(@currentretainamt,0)<>0)
   	begin
   	-- -- -- update contract bJCCM
   	update bJCCM
   		set OrigContractAmt = ISNULL(OrigContractAmt,0) + ISNULL(@origcontractamt,0),
   			ContractAmt = ISNULL(ContractAmt,0) + ISNULL(@contractamt,0),
   			BilledAmt =ISNULL(BilledAmt,0) + ISNULL(@billedamt,0),
   			ReceivedAmt =ISNULL(ReceivedAmt,0) + ISNULL(@receivedamt,0),
   			CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) + ISNULL(@currentretainamt,0)
   	where JCCo=@jcco and Contract=@contract
   	end
   
   
   -- -- -- subtract the old - read the deleted record
   select @contract=Contract, @item=Item, @jctranstype=JCTransType,
   		@billedunits=BilledUnits, @billedamt=d.BilledAmt, @billedtax=d.BilledTax,
   		@receivedamt=d.ReceivedAmt, @currentretainamt=d.CurrentRetainAmt,
   		@origcontractunits = Case when d.JCTransType='OC' then d.ContractUnits else 0 end,
   		@origcontractamt = Case when d.JCTransType='OC' then d.ContractAmt else 0 end,
   		@contractunits = d.ContractUnits, @contractamt = d.ContractAmt,
   		@ProjUnits=d.ProjUnits, @ProjDollars=d.ProjDollars
   from deleted d
   where d.JCCo=@jcco and d.Mth=@mth and d.ItemTrans=@itemtrans
   
   -- -- -- update bJCIP
   update bJCIP
   	set BilledUnits = ISNULL(BilledUnits,0) - ISNULL(@billedunits,0),
   		BilledTax = ISNULL(BilledTax,0) - ISNULL(@billedtax,0),
   		BilledAmt = ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
   		ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
   		CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0),
   		OrigContractUnits = ISNULL(OrigContractUnits,0) - ISNULL(@origcontractunits,0),
   		OrigContractAmt =ISNULL(OrigContractAmt,0) - ISNULL(@origcontractamt,0),
   		ContractUnits = ISNULL(ContractUnits,0) - ISNULL(@contractunits,0),
   		ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0),
   		ProjUnits = ISNULL(ProjUnits,0) - ISNULL(@ProjUnits,0),
   		ProjDollars = ISNULL(ProjDollars,0) - ISNULL(@ProjDollars,0)
   where JCCo=@jcco and Contract=@contract and Item=@item and Mth=@mth
   
   -- -- -- Type OC is maintained in the JCCI triggers
   if @jctranstype <> 'OC' and 
   	(ISNULL(@billedunits,0)<>0 or ISNULL(@billedamt,0)<>0 or ISNULL(@receivedamt,0)<>0 or
   	ISNULL(@currentretainamt,0)<>0 or ISNULL(@contractunits,0)<>0 or ISNULL(@contractamt,0)<>0)
   	begin
   	-- -- -- OrigUnitPrice, OrigContractUnits, OrigContractAmt = dont UPDATE maintained directly
   	-- -- -- cant back out deleted UnitPrice
   	update bJCCI
   		set BilledUnits = ISNULL(BilledUnits,0) - ISNULL(@billedunits,0),
   			BilledAmt = ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
   			ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
   			CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0),
   			ContractUnits = ISNULL(ContractUnits,0) - ISNULL(@contractunits,0),
   			ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0)
   	where JCCo=@jcco and Contract=@contract and Item=@item
   	end
   
   if (ISNULL(@origcontractamt,0)<>0 or ISNULL(@contractamt,0)<>0 or 
   	ISNULL(@billedamt,0)<>0 or ISNULL(@receivedamt,0)<>0 or ISNULL(@currentretainamt,0)<>0)
   	begin
   	-- -- -- update contract bJCCM
   	update bJCCM
   		set OrigContractAmt = ISNULL(OrigContractAmt,0) - ISNULL(@origcontractamt,0),
   			ContractAmt = ISNULL(ContractAmt,0) - ISNULL(@contractamt,0),
   			BilledAmt =ISNULL(BilledAmt,0) - ISNULL(@billedamt,0),
   			ReceivedAmt =ISNULL(ReceivedAmt,0) - ISNULL(@receivedamt,0),
   			CurrentRetainAmt= ISNULL(CurrentRetainAmt,0) - ISNULL(@currentretainamt,0)
   	where JCCo=@jcco and Contract=@contract
   	end
   
   
   
   if @numrows > 1
   	begin
   	fetch next from bJCID_insert into @jcco, @mth, @itemtrans
    	if @@fetch_status = 0
    		goto bJCID_insert
    	else
    		begin
    		close bJCID_insert
    		deallocate bJCID_insert
   		set @opencursor = 0
    		end
    	end
   
   
Trigger_Skip:
   
   return
   
   
   
   
   error:
   	if @opencursor = 1
    		begin
    		close bJCID_insert
    		deallocate bJCID_insert
   		set @opencursor = 0
    		end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update Item Detail! '
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 




GO
ALTER TABLE [dbo].[bJCID] ADD CONSTRAINT [biJCID] PRIMARY KEY CLUSTERED  ([JCCo], [Mth], [ItemTrans]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bJCID_CoContractItemTransMth] ON [dbo].[bJCID] ([JCCo], [Contract], [Item], [TransSource], [Mth]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
