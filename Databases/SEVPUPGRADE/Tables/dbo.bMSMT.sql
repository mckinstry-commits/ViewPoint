CREATE TABLE [dbo].[bMSMT]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[TransMth] [dbo].[bMonth] NOT NULL,
[MSTrans] [dbo].[bTrans] NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[Ticket] [dbo].[bTic] NULL,
[SaleDate] [dbo].[bDate] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Units] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[PECM] [dbo].[bECM] NOT NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[TotalCost] [dbo].[bDollar] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[TaxType] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /***************************************************************/
   CREATE  trigger [dbo].[btMSMTd] on [dbo].[bMSMT] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:	GF 02/17/2005
    * Modified By:
    *
    *
    *	Unlock any associated MS Detail - set InUseBatchId to null.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- 'unlock' existing MS Detail
   update bMSTD set InUseBatchId = null
   from bMSTD t
   join deleted d on d.Co = t.MSCo and d.TransMth = t.Mth and d.MSTrans = t.MSTrans
   if @@rowcount <> @numrows
        begin
        select @errmsg = 'Unable to unlock MS Transaction Detail'
        goto error
        end
   
   return
   
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Material Vendor Worksheet Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/**************************************************************/
CREATE trigger [dbo].[btMSMTi] on [dbo].[bMSMT] for INSERT as
/*--------------------------------------------------------------
* Created By:	GF 02/17/2005
* Modified By:	GF 07/17/2008 - issue #128458 for GST/PST international tax
*						
*
* Performs validation on critical columns.
*
* Locks bMSTD entries pulled into batch
*
* Adds bHQCC entries as needed
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint,
		@msglco bCompany, @co bCompany, @mth bMonth, @batchid bBatchID,
		@apco bCompany,  @glco bCompany, @taxtype tinyint, @taxcode bTaxCode,
		@valueadd varchar(1), @taxgroup bGroup

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0

-- validate batch
select @validcnt = count(*)
from bHQBC r with (Nolock) 
join inserted i ON i.Co = r.Co and i.Mth = r.Mth and i.BatchId = r.BatchId
where r.Status = 0  -- must be Open
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid or missing Batch, must be Open!'
	goto error
	end

-- validate with Worksheet Batch Header
select @validcnt = count(*)
from bMSMH h with (Nolock) 
join inserted i ON i.Co = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId and i.BatchSeq = h.BatchSeq
if @validcnt <> @numrows
	begin
	select @errmsg = 'Worksheet detail references an invalid or missing Worksheet Header!'
	goto error
	end

-- lock & validate MS Trans#, Matl Vendor in bMSTD must match Vendor in bMSMH
update bMSTD set InUseBatchId = i.BatchId
from bMSTD t
join inserted i on i.Co = t.MSCo and i.TransMth = t.Mth and i.MSTrans = t.MSTrans
join bMSMH h with (Nolock) on i.Co = h.Co and i.Mth = h.Mth and i.BatchId = h.BatchId
and i.BatchSeq = h.BatchSeq and h.VendorGroup = t.VendorGroup and h.MatlVendor = t.MatlVendor
where t.InUseBatchId is null and t.MatlAPRef is null and t.Void = 'N'
if @@rowcount <> @numrows
	begin
	select @errmsg = 'Invalid or ineligible MS Transaction!'
	goto error
	end


-- cursor for MSMT detail validate tax type and add entries to HQ Close Control if needed.
if @numrows = 1
	begin
	select @co=i.Co, @mth=i.Mth, @batchid=i.BatchId, @apco=c.APCo, @msglco=c.GLCo,
			@taxtype=i.TaxType, @taxcode=i.TaxCode, @taxgroup=TaxGroup
	from inserted i join bMSCO c with (nolock) on i.Co = c.MSCo
	end
else
	begin
	-- use a cursor to process each inserted row
	declare bMSMT_insert cursor LOCAL FAST_FORWARD
	for select distinct i.Co, i.Mth, i.BatchId, c.APCo, c.GLCo, i.TaxType, i.TaxCode, i.TaxGroup
	from inserted i join bMSCO c with (Nolock) on i.Co = c.GLCo

	open bMSMT_insert
	set @opencursor = 1

	fetch next from bMSMT_insert into @co, @mth, @batchid, @apco, @msglco, @taxtype, @taxcode, @taxgroup
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end

insert_HQCC_check:

---- validate Tax info
if @taxcode is not null
	begin
	---- must have tax type
	if @taxtype is null
		begin
		select @errmsg = 'Missing Tax Type'
		goto error
		end
  
	---- validate tax code
	select @valueadd=ValueAdd
	from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '.'
		goto error
		end
	-- validate tax type
	if @taxtype is null
		begin
		select @errmsg = 'Invalid tax type - no tax type assigned.'
		goto error
		end
	if @taxtype not in (1,3)
		begin
		select @errmsg = 'Invalid Tax Type, must be 1, or 3.'
		goto error
		end
	if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
		goto error
		end
	end



-- add entry to HQ Close Control for MS Company GLCo
if not exists(select top 1 1 from bHQCC with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @msglco)
	begin
	insert bHQCC (Co, Mth, BatchId, GLCo)
	values (@co, @mth, @batchid, @msglco)
	end

-- get AP GL Company
select @glco = GLCo from bAPCO with (Nolock) where APCo = @apco
if @@rowcount <> 0
	begin
	-- add entry to HQ Close Control for AP Co#
	if not exists(select top 1 1 from bHQCC with (Nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
		begin
		insert bHQCC (Co, Mth, BatchId, GLCo)
		values (@co, @mth, @batchid, @glco)
		end
	end




if @numrows > 1
	begin
	fetch next from bMSMT_insert into @co, @mth, @batchid,  @apco, @msglco, @taxtype, @taxcode, @taxgroup
	if @@fetch_status = 0 goto insert_HQCC_check

	close bMSMT_insert
	deallocate bMSMT_insert
	set @opencursor = 0
	end
    
   
   
   return
    
   
   
error:
   select @errmsg = @errmsg + ' - cannot insert MS Material Vendor Worksheet Detail'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****************************************************************/
CREATE trigger [dbo].[btMSMTu] on [dbo].[bMSMT] for UPDATE as
/*-----------------------------------------------------------------
* Created By:	GF 02/17/2005
* Modified By:	GF 07/17/2008 - issue #128458 for GST/PST international tax
*
* Cannot change Company, Mth, BatchId, Seq, or MS Trans
*
*----------------------------------------------------------------*/
declare @numrows int, @validcount int, @errmsg varchar(255), @opencursor tinyint,
		@taxtype tinyint, @taxcode bTaxCode, @valueadd varchar(1), @taxgroup bGroup

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0
    
-- check for key changes
select @validcount = count(*)
from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
    and d.BatchSeq = i.BatchSeq and d.TransMth = i.TransMth and d.MSTrans = i.MSTrans
if @numrows <> @validcount
	begin
	select @errmsg = 'Cannot change Company, Month, Batch ID #, Sequence #, Trans Month, or MS Trans #'
	goto error
	end


-- cursor for MSMT detail validate tax type
if @numrows = 1
	begin
	select @taxtype=i.TaxType, @taxcode=i.TaxCode, @taxgroup=TaxGroup
	from inserted i
	end
else
	begin
	-- use a cursor to process each inserted row
	declare bMSMT_update cursor LOCAL FAST_FORWARD
	for select i.TaxType, i.TaxCode, i.TaxGroup
	from inserted i

	open bMSMT_update
	set @opencursor = 1

	fetch next from bMSMT_update into @taxtype, @taxcode, @taxgroup
	if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
	end

MSMT_update_check:

---- validate Tax info
if @taxcode is not null
	begin
	---- must have tax type
	if @taxtype is null
		begin
		select @errmsg = 'Missing Tax Type'
		goto error
		end
  
	---- validate tax code
	select @valueadd=ValueAdd
	from bHQTX with (nolock) where TaxGroup = @taxgroup and TaxCode = @taxcode
	if @@rowcount = 0
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '.'
		goto error
		end
	-- validate tax type
	if @taxtype is null
		begin
		select @errmsg = 'Invalid tax type - no tax type assigned.'
		goto error
		end
	if @taxtype not in (1,3)
		begin
		select @errmsg = 'Invalid Tax Type, must be 1, or 3.'
		goto error
		end
	if @taxtype = 3 and isnull(@valueadd,'N') <> 'Y'
		begin
		select @errmsg = 'Invalid Tax Code: ' + isnull(@taxcode,'') + '. Must be a value added tax code!'
		goto error
		end
	end



if @numrows > 1
	begin
	fetch next from bMSMT_update into @taxtype, @taxcode, @taxgroup
	if @@fetch_status = 0 goto MSMT_update_check

	close bMSMT_update
	deallocate bMSMT_update
	set @opencursor = 0
	end





return
    
   
   
error:
	select @errmsg = @errmsg + ' - cannot update MS Material Vendor Worksheet Detail!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSMT] ON [dbo].[bMSMT] ([Co], [Mth], [BatchId], [BatchSeq], [TransMth], [MSTrans]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSMT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSMT].[PECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSMT].[ECM]'
GO
