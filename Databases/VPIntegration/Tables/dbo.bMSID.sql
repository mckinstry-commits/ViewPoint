CREATE TABLE [dbo].[bMSID]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SaleDate] [dbo].[bDate] NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[Ticket] [dbo].[bTic] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSIDd] on [dbo].[bMSID] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: GG 11/11/00
    * Modified: GG 01/30/02 - #14176 - Audit tickets removed from invoice
    *
    * Delete trigger on bMSID - MS Invoice Batch Detail.
    *
    * Unlocks corresponding MS Transaction Detail
    *
    */----------------------------------------------------------------
   
   declare  @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- 'unlock' existing MS Transaction Detail
   update bMSTD set InUseBatchId = null
   from bMSTD t
   join deleted d on d.Co = t.MSCo and d.Mth = t.Mth and d.MSTrans = t.MSTrans
   if @@rowcount <> @numrows
       begin
       select @errmsg = 'Unable to unlock Transaction detail'
       goto error
       end
   
   
   -- add HQ Audit - #14176
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSID',' Mth: ' + convert(varchar(8),d.Mth,1) + ' Batch: ' + convert(varchar(6),d.BatchId)
   	+ ' MS Trans#: ' + convert(varchar(8),d.MSTrans) + ' Inv: ' + b.MSInv,
   	d.Co, 'D', null, null, null, getdate(), suser_sname()
   from deleted d join bMSCO c with (nolock) on c.MSCo = d.Co
   join bMSIB b with (nolock) on b.Co = d.Co and b.Mth = d.Mth and b.BatchId = d.BatchId and b.BatchSeq = d.BatchSeq
   where c.AuditInvDetail = 'Y' and b.PrintedYN = 'Y'	 -- only audit if printed
    
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Invoice Batch Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSIDi] on [dbo].[bMSID] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GG 11/11/00
    * Modified By: MB 07/10/01 - Issue 13947 change to InUseBatchId check
    *				GG 01/17/02 - #15839 - use AR Co# CustGroup for interco sales
    *				GG 01/18/02 - #15948 - interco invoices by Job
    *				GG 01/30/02 - #14176 - audit invoice changes if printed
    *
    * Insert trigger bMSID - MS Invoice Batch Detail
    *
    * Performs validation on critical columns.
    *
    * Locks bMSTD entries pulled into batch
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @co bCompany, @mth bMonth,
        @batchid bBatchID, @batchseq int, @mstrans bTrans, @msidcustjob varchar(20), @msidcustpo varchar(20),
        @msidsaledate bDate, @msidfromloc bLoc, @msidmatlgroup bGroup, @msidmaterial bMatl, @msidum bUM,
        @msidunitprice bUnitCost, @msidticket bTic, @msibmsinv varchar(10), @msibcustgroup bGroup,
        @msibcustomer bCustomer, @msibcustjob varchar(20), @msibcustpo varchar(20), @msibpaymenttype char(1),
        @intercoinv bYN, @msiblocgroup bGroup, @msibloc bLoc, @interfaced bYN, @void bYN, @msihmth bMonth,
        @msihinusebatchid bBatchID, @mstdsaledate bDate, @mstdticket bTic, @mstdfromloc bLoc, @saletype char(1),
        @mstdcustgroup bGroup, @mstdcustomer bCustomer, @mstdcustjob varchar(20), @mstdcustpo varchar(20),
        @mstdpaymenttype char(1), @hold bYN, @jcco bCompany, @inco bCompany, @mstdmatlgroup bGroup,
        @mstdmaterial bMatl, @mstdum bUM, @mstdunitprice bUnitCost, @mstdvoid bYN, @mstdmsinv varchar(10),
        @mstdinusebatchid bBatchID, @locgroup bGroup, @toco bCompany, @job bJob
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   set @opencursor = 0
   
    -- cursor only needed if more than a single row inserted
    if @numrows = 1
        select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @mstrans = MSTrans, @msidcustjob = CustJob,
            @msidcustpo = CustPO, @msidsaledate = SaleDate, @msidfromloc = FromLoc, @msidmatlgroup = MatlGroup,
            @msidmaterial = Material, @msidum = UM, @msidunitprice = UnitPrice, @msidticket = Ticket
        from inserted
    else
    	begin
    	 -- use a cursor to process each inserted row
    	 declare bMSID_insert cursor LOCAL FAST_FORWARD
   	 for select Co, Mth, BatchId, BatchSeq, MSTrans, CustJob, CustPO, SaleDate, FromLoc, MatlGroup, Material,
            UM, UnitPrice, Ticket
    	 from inserted
   
    	 open bMSID_insert
    	 set @opencursor = 1
   
    	 fetch next from bMSID_insert into @co, @mth, @batchid, @batchseq, @mstrans, @msidcustjob, @msidcustpo,
            @msidsaledate, @msidfromloc, @msidmatlgroup, @msidmaterial, @msidum, @msidunitprice, @msidticket
    	 if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
   
    MSID_insert_check:
    -- validate with Invoice Batch Header
    select @msibmsinv = MSInv, @msibcustgroup = CustGroup, @msibcustomer = Customer, @msibcustjob = CustJob,
        @msibcustpo = CustPO, @msibpaymenttype = PaymentType, @intercoinv = InterCoInv, @msiblocgroup = LocGroup,
        @msibloc = Location, @interfaced = Interfaced, @void = Void
    from bMSIB with (nolock) 
    where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
    if @@rowcount = 0
        begin
        select @errmsg = 'Missing Invoice Batch Header'
        goto error
        end
    if @msibcustjob is not null and isnull(@msidcustjob,'') <> @msibcustjob
        begin
        select @errmsg = 'Customer Job does not match Invoice Header'
        goto error
        end
    if @msibcustpo is not null and isnull(@msidcustpo,'') <> @msibcustpo
        begin
        select @errmsg = 'Customer PO# does not match Invoice Header'
        goto error
        end
    -- validate entries associated with Interfaced (reprint) or (to be) Void(ed) invoices
    if @interfaced = 'Y' or @void = 'Y'
        begin
        select @msihmth = Mth, @msihinusebatchid = InUseBatchId
         from bMSIH with (nolock) where MSCo = @co and MSInv = @msibmsinv
        if @@rowcount = 0
            begin
            select @errmsg = 'Invalid Invoice #'
            goto error
            end
        if @msihmth <> @mth
            begin
            select @errmsg = 'Invoice was posted in another month'
            goto error
            end
        if @msihinusebatchid <> @batchid and @msihinusebatchid is not null  -- <--------------- added check for Not NULL
            begin
            select @errmsg = 'Invoice already in use by batch ID ' + convert(varchar(10),isnull(@msihinusebatchid,''))
            goto error
            end
        if not exists(select top 1 1 from bMSIL with (nolock) where MSCo = @co and MSInv = @msibmsinv and MSTrans = @mstrans)
            begin
            select @errmsg = 'Missing Line detail'
            goto error
            end
        end
    -- validate with MS Trans and lock
    select @mstdsaledate = SaleDate, @mstdticket = Ticket, @mstdfromloc = FromLoc, @saletype = SaleType,
   		@mstdcustgroup = CustGroup, @mstdcustomer = Customer, @mstdcustjob = CustJob, @mstdcustpo = CustPO,
   		@mstdpaymenttype = PaymentType, @hold = Hold, @jcco = JCCo, @job = Job, @inco = INCo, @mstdmatlgroup = MatlGroup,
   		@mstdmaterial = Material, @mstdum = UM, @mstdunitprice = UnitPrice, @mstdvoid = Void, @mstdmsinv = MSInv,
   		@mstdinusebatchid = InUseBatchId
    from bMSTD with (nolock) 
    where MSCo = @co and Mth = @mth and MSTrans = @mstrans
    if @@rowcount = 0
        begin
        select @errmsg = 'References an invalid Trans#'
        goto error
        end
    if @hold = 'Y'
        begin
        select @errmsg = 'Transaction is on hold'
        goto error
        end
    if @mstdvoid = 'Y'
        begin
        select @errmsg = 'Transaction is void'
        goto error
        end
    if @mstdinusebatchid is not null
        begin
        select @errmsg = 'Transaction already in use by batch ID ' + convert(varchar(10),isnull(@mstdinusebatchid,''))
        goto error
        end
    if isnull(@msidsaledate,@mstdsaledate) <> @mstdsaledate -- Sale Date is null in batch if invoice not sorted by date
        begin
        select @errmsg = 'Sale date does not match Transaction'
        goto error
        end
    if isnull(@msidfromloc,@mstdfromloc) <> @mstdfromloc -- From Loc is null in batch detail if invoice not sorted by Location
        begin
        select @errmsg = 'From Location does not match Transaction'
        goto error
        end
    if isnull(@msibloc,@mstdfromloc) <> @mstdfromloc    -- Location is null in header unless invoice resticted by Location
        begin
        select @errmsg = 'Location on transaction does not match Invoice Header'
        goto error
        end
    if @msiblocgroup is not null
        begin
        select @locgroup = LocGroup from bINLM with (nolock) where INCo = @co and Loc = @mstdfromloc
        if @@rowcount = 0
            begin
            select @errmsg = 'Invalid From Location on transaction'
            goto error
            end
        if @locgroup <> @msiblocgroup
            begin
            select @errmsg = 'Location belongs to a Group that does match Invoice Header'
            goto error
            end
        end
    if isnull(@msidticket,'') <> isnull(@mstdticket,'')
        begin
        select @errmsg = 'Ticket # does not match Transaction'
        goto error
        end
    if @saletype in ('J','I')
        begin
        if @intercoinv ='N'
            begin
            select @errmsg = 'Transaction sale type requires an intercompany invoice'
            goto error
            end
   
       select @toco = case @saletype when 'J' then @jcco else @inco end
   	if @saletype = 'J' select @mstdcustjob = @job
   
   	-- get AR Co# Customer Group
   	select @mstdcustgroup = CustGroup
   	from bHQCO h with (nolock) 
   	join bMSCO m with (nolock) on m.ARCo = h.HQCo where m.MSCo = @co
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid AR Company, cannot get Customer Group #'
   		goto error
   		end
   	-- get 'sell to' Co# Customer #
       select @mstdcustomer = Customer from bHQCO with (nolock) where HQCo = @toco
       if @@rowcount = 0
            begin
            select @errmsg = 'Invalid (sell to) Company, cannot get Customer #'
            goto error
            end
        end
    if @msibcustgroup <> @mstdcustgroup or @msibcustomer <> @mstdcustomer
        begin
        select @errmsg = 'Customer on transaction does not match Invoice Header'
        goto error
        end
     if isnull(@msidcustjob,'') <> isnull(@mstdcustjob,'')
        begin
        select @errmsg = 'Customer Job does not match Transaction'
        goto error
        end
    if isnull(@msidcustpo,'') <> isnull(@mstdcustpo,'')
        begin
     select @errmsg = 'Customer PO# does not match Transaction'
        goto error
        end
    if @msibpaymenttype <> isnull(@mstdpaymenttype,'A')     -- will be null for interco sales, so assume 'On Account'
        begin
        select @errmsg = 'Payment Type on transaction does not match Invoice Header'
        goto error
        end
    if @msidmatlgroup <> @mstdmatlgroup or @msidmaterial <> @mstdmaterial
        begin
        select @errmsg = 'Material does not match Transaction'
        goto error
        end
    if @msidum <> @mstdum
        begin
        select @errmsg = 'Material UM does not match Transaction'
        goto error
        end
    if @msidunitprice <> @mstdunitprice
        begin
        select @errmsg = 'Material unit price does not match Transaction'
        goto error
        end
   
    -- lock Transaction Detail
    update bMSTD set InUseBatchId = @batchid where MSCo = @co and Mth = @mth and MSTrans = @mstrans
    if @@rowcount <> 1
        begin
        select @errmsg = 'Unable to lock Transaction'
        goto error
        end
   
   if @numrows > 1
   	begin
   	fetch next from bMSID_insert into @co, @mth, @batchid, @batchseq, @mstrans, @msidcustjob, @msidcustpo,
            @msidsaledate, @msidfromloc, @msidmatlgroup, @msidmaterial, @msidum, @msidunitprice, @msidticket
   	if @@fetch_status = 0 goto MSID_insert_check
   
   	close bMSID_insert
   	deallocate bMSID_insert
   	set @opencursor = 0
    	end
   
   -- add HQ Audit - #14176
   insert bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSID',' Mth: ' + convert(varchar(8),i.Mth,1) + ' Batch: ' + convert(varchar(6),i.BatchId)
   	+ ' MS Trans#: ' + convert(varchar(8),i.MSTrans) + ' Inv: ' + b.MSInv,
   	i.Co, 'A', null, null, null, getdate(), suser_sname()
   from inserted i join bMSCO c with (nolock) on c.MSCo = i.Co
   join bMSIB b with (nolock) on b.Co = i.Co and b.Mth = i.Mth and b.BatchId = i.BatchId and b.BatchSeq = i.BatchSeq
   where c.AuditInvDetail = 'Y' and b.PrintedYN = 'Y'	 -- only audit if printed
   
   
   return
   
   
   
   error:
       select @errmsg = @errmsg + ' - cannot insert MS Invoice Batch Detail'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSIDu] on [dbo].[bMSID] for UPDATE as
   

/*-----------------------------------------------------------------
    * Created: GG 11/11/00
    * Modified:
    *
    * Update trigger on bMSID - MS Invoice Batch Detail - prohibits all changes
    *
    * Users may only insert and delete entries in this table.
    *
    */----------------------------------------------------------------
   
   declare  @numrows int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   select @errmsg = 'You may only add and delete transactions'
   goto error
   
   return
   error:
       select @errmsg = @errmsg +  ' - cannot update MS Invoice Batch Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSID] ON [dbo].[bMSID] ([Co], [Mth], [BatchId], [BatchSeq], [MSTrans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSIDTrans] ON [dbo].[bMSID] ([Co], [Mth], [MSTrans]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSID] ([KeyID]) ON [PRIMARY]
GO
