CREATE TABLE [dbo].[bMSIB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[MSInv] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PaymentType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RecType] [tinyint] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[DiscDate] [dbo].[bDate] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[ApplyToInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InterCoInv] [dbo].[bYN] NOT NULL,
[LocGroup] [dbo].[bGroup] NULL,
[Location] [dbo].[bLoc] NULL,
[PrintLvl] [tinyint] NOT NULL,
[SubtotalLvl] [tinyint] NOT NULL,
[SepHaul] [dbo].[bYN] NOT NULL,
[Interfaced] [dbo].[bYN] NOT NULL,
[Void] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PrintedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSIB_PrintedYN] DEFAULT ('N'),
[CheckNo] [dbo].[bCMRef] NULL,
[CMCo] [dbo].[bCompany] NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_CMAcct] CHECK (([CMAcct] IS NULL OR [CMAcct]>(0) AND [CMAcct]<(10000)))
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_InterCoInv] CHECK (([InterCoInv]='N' OR [InterCoInv]='Y'))
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_Interfaced] CHECK (([Interfaced]='N' OR [Interfaced]='Y'))
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_PrintedYN] CHECK (([PrintedYN]='N' OR [PrintedYN]='Y'))
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_SepHaul] CHECK (([SepHaul]='N' OR [SepHaul]='Y'))
ALTER TABLE [dbo].[bMSIB] ADD
CONSTRAINT [CK_bMSIB_Void] CHECK (([Void]='N' OR [Void]='Y'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSIBd] on [dbo].[bMSIB] for DELETE as
    

/*-----------------------------------------------------------------
     * Created By:  GG 11/13/00
     * Modified By: TV 03/21/02 delete HQAT records
     *				 GF 07/29/2003 - issue #21933 - speed improvements
	 *				DAN SO 05/18/09 - Issue: #133441 - Delete Attachments
     *
     * Delete trigger on bMSIB - MS Invoice Header Batch
     *
     * Check for existing Batch detail, and unlock any associated
     * MS Invoices - set InUseBatchId to null.
     *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    --check for Invoice Batch Detail, must be deleted before Invoice Header
    if exists(select 1 from bMSID i with (nolock) join deleted d on d.Co = i.Co 
    			and d.Mth = i.Mth and d.BatchId = i.BatchId and d.BatchSeq = i.BatchSeq)
        begin
        select @errmsg = 'Batch detail still exists for Invoice Header'
        goto error
        end
    
    -- get # of Invoices to be unlocked
    select @validcnt = count(*) from deleted where Interfaced = 'Y' or Void = 'Y'
    
    -- 'unlock' existing Invoice Headers 
    update bMSIH
    set InUseBatchId = null
    from bMSIH h
    join deleted d on d.Co = h.MSCo and d.MSInv = h.MSInv
    where d.Interfaced = 'Y' or d.Void = 'Y' --only previously interfaced or 'to be' voided invoices will have locked entries in bMSIH
    if @@rowcount <> @validcnt
    	begin
    	select @errmsg = 'Unable to unlock existing Invoice Header'
    	goto error
    	end



	-- ISSUE: #133441
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null.
	INSERT vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
		SELECT AttachmentID, SUSER_NAME(), 'Y' 
          FROM bHQAT h JOIN deleted d 
			ON h.UniqueAttchID = d.UniqueAttchID
         WHERE h.UniqueAttchID NOT IN(SELECT t.UniqueAttchID 
										FROM bMSIH t JOIN deleted d1 
										  ON t.UniqueAttchID = d1.UniqueAttchID)
           AND d.UniqueAttchID IS NOT NULL    


------------------------------------
-- OLD ATTACHMENT DELETION METHOD --
------------------------------------
---------- delete HQAT entries if not exists in MSIH
------delete bHQAT 
------from bHQAT h with (nolock) 
------join deleted d on h.UniqueAttchID = d.UniqueAttchID
------where d.UniqueAttchID is not null
------and not exists(select top 1 1 from bMSIH t with (nolock) where t.MSCo=d.Co
------			and t.MSInv=d.MSInv and t.UniqueAttchID=d.UniqueAttchID)



return


error:
	select @errmsg = @errmsg + ' - cannot delete Invoice Batch Header!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE   trigger [dbo].[btMSIBi] on [dbo].[bMSIB] for INSERT as
   

/*--------------------------------------------------------------
    * Created By: GG 11/11/00
    *
    * Insert trigger bMSIB - MS Invoice Batch Header
    *
    * Performs validation on critical columns.
    *
    * Locks bMSIH entries pulled into batch for reprint or void
    *
    * Adds bHQCC entries as needed
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @co bCompany, 
   		@mth bMonth, @batchid bBatchID, @batchseq int, @msinv varchar(10), @interfaced bYN, 
   		@void bYN, @msihmth bMonth, @msihinusebatchid bBatchID, @msihvoid bYN, @glco bCompany, 
   		@arco bCompany
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- validate Batch #
   select @validcnt = count(*)
   from bHQBC b with (nolock)
   join inserted i on i.Co = b.Co and i.Mth = b.Mth and i.BatchId = b.BatchId
   where b.TableName = 'MSIB' and b.InUseBy = suser_sname()  and b.Status = 0
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Batch ID# - must be an open Invoice batch, in use by ' + suser_name()
   	goto error
   	end
   
   -- cursor only needed if more than a single row inserted
   if @numrows = 1
       select @co = Co, @mth = Mth, @batchid = BatchId, @batchseq = BatchSeq, @msinv = MSInv,
   			@interfaced = Interfaced, @void = Void
       from inserted
   else
   	begin
   	 -- use a cursor to process each inserted row
   	 declare bMSIB_insert cursor LOCAL FAST_FORWARD
   	 for select Co, Mth, BatchId, BatchSeq, MSInv, Interfaced, Void
   	 from inserted
   
   	 open bMSIB_insert
   	 set @opencursor = 1
   
   	 fetch next from bMSIB_insert into @co, @mth, @batchid, @batchseq, @msinv, @interfaced, @void
   	 if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   MSIB_insert_check:
   -- validate entries associated with Interfaced (reprint) or (to be) Void(ed) invoices
   if @interfaced = 'Y' or @void = 'Y'
       begin
       select @msihmth = Mth, @msihinusebatchid = InUseBatchId, @msihvoid = Void
       from bMSIH with (nolock) where MSCo = @co and MSInv = @msinv
       if @@rowcount = 0
           begin
           select @errmsg = 'Invalid Invoice #'
           goto error
           end
       if @msihvoid = 'Y'
           begin
           select @errmsg = 'Invoice has been voided'
           goto error
           end
       if @msihmth <> @mth
           begin
           select @errmsg = 'Invoice was posted in another month'
           goto error
           end
       if @msihinusebatchid is not null
           begin
           select @errmsg = 'Invoice already in use by batch ID ' + convert(varchar(10),@msihinusebatchid)
           goto error
           end
   
       -- lock Invoice Header
       update bMSIH set InUseBatchId = @batchid where MSCo = @co and MSInv = @msinv
       if @@rowcount <> 1
           begin
           select @errmsg = 'Unable to lock Invoice'
           goto error
           end
       end
   
   -- add entry to HQ Close Control for MS Company GLCo
   select @glco = GLCo, @arco = ARCo
   from bMSCO with (nolock) where MSCo = @co
   if @@rowcount <> 1
       begin
       select @errmsg = 'Invalid MS Co#'
       goto error
       end
   
   if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   	begin
       insert bHQCC (Co, Mth, BatchId, GLCo)
   	values (@co, @mth, @batchid, @glco)
   	end
   
   -- get AR GL Company
   select @glco = GLCo from bARCO with (nolock) where ARCo = @arco
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid AR Co#'
       goto error
       end
   
   -- add entry to HQ Close Control for AR GL Co#
   if not exists(select top 1 1 from bHQCC with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and GLCo = @glco)
   	begin
       insert bHQCC (Co, Mth, BatchId, GLCo)
       values (@co, @mth, @batchid, @glco)
   	end
   
   
   if @numrows > 1
       begin
       fetch next from bMSIB_insert into @co, @mth, @batchid, @batchseq, @msinv, @interfaced, @void
       if @@fetch_status = 0 goto MSIB_insert_check
   
   	close bMSIB_insert
   	deallocate bMSIB_insert
   	set @opencursor = 0
   	end
   
   
   
   return
   
   
   
   error:
      select @errmsg = @errmsg + ' - cannot insert MS Invoice Batch Header'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btMSIBu] on [dbo].[bMSIB] for UPDATE as
/*--------------------------------------------------------------
* Created By:	GG 11/13/00
* Modified By: MV 07/06/01 allow updates if no changes to data and
*                 Interfaced or Void = 'Y' for BatchUserMemoInsertExisting
*				GF 06/23/03 - issue #21577 - allow location group to be nulled out.
*				GF 12/03/2003 - issue #23147 changes for ansi nulls
*				GF 03/11/2008 - issue #127082 MSIB.Country
*
*
* Update trigger bMSIB - MS Invoice Batch Header
*
* Performs validation on critical columns.
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @opencursor tinyint, @co bCompany, @mth bMonth,
		@batchid bBatchID, @batchseq int, @custgroup bGroup, @customer bCustomer, @custjob varchar(20),
		@custpo varchar(20), @paymenttype char(1), @locgroup bGroup, @loc bLoc, @oldcustgroup bGroup,
		@oldcustomer bCustomer, @oldcustjob varchar(20), @oldcustpo varchar(20), @oldpaymenttype char(1),
		@oldlocgroup bGroup, @oldloc bLoc
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   set @opencursor = 0 
   
    -- check for key changes
    select @validcnt = count(*)
    from deleted d join inserted i on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
        and d.BatchSeq = i.BatchSeq
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month, Batch ID #, or Sequence #'
    	goto error
    	end
    --check other 'unchangeable' columns
    if update(InterCoInv)
        begin
        select @errmsg = 'Cannot change Intercompany Invoice flag'
        goto error
        end
    if update(Interfaced)
        begin
        select @errmsg = 'Cannot change Interfaced flag'
        goto error
        end
    if update(Void)
        begin
        select @errmsg = 'Cannot change Void flag'
        goto error
        end
   
   
-- no changes allowed to Interfaced or Voided Invoices - Check each field for changes, if non,
-- allow updating the batch record for BatchUserMemoInsertExisting
if (select count(*) from inserted i join deleted d on d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId
	and d.BatchSeq = i.BatchSeq where (i.Interfaced = 'Y' or i.Void = 'Y') and  (i.CustGroup <> d.CustGroup or
	i.Customer <> d.Customer or isnull(i.CustJob,'') <> isnull(d.CustJob,'') or isnull(i.CustPO,'') <>
	isnull(d.CustPO,'') or isnull(i.Description,'') <> isnull(d.Description,'') or isnull(i.ShipAddress,'')<>
	isnull(d.ShipAddress,'') or isnull(i.City,'') <> isnull(d.City,'') or isnull(i.State,'') <> isnull(d.State,'')
	or isnull(i.Zip,'')<> isnull(d.Zip,'') or isnull(i.ShipAddress2,'')<> isnull(d.ShipAddress2,'')
	or isnull(i.Country,'') <> isnull(d.Country,'') or i.PaymentType <> d.PaymentType
	or i.RecType <> d.RecType or isnull(i.PayTerms,'')<> isnull(d.PayTerms,'')
	or i.InvDate <> d.InvDate or isnull(i.DiscDate,'') <> isnull(d.DiscDate,'') or i.DueDate <> d.DueDate or
	isnull(i.ApplyToInv,'')<> isnull(d.ApplyToInv,'') or i.InterCoInv <> d.InterCoInv or isnull(i.LocGroup,'')<>
	isnull(d.LocGroup,'') or isnull(i.Location,'')<> isnull(d.Location,'') or i.PrintLvl <> d.PrintLvl or
	i.SubtotalLvl <> d.SubtotalLvl or i.SepHaul <> d.SepHaul)) > 0
	begin
	select @errmsg = 'Cannot change previously Interfaced or Void Invoices'
	goto error
	end
   
    -- cursor only needed if more than a single row updated
    if @numrows = 1
        select @co = i.Co, @mth = i.Mth, @batchid = i.BatchId, @batchseq = i.BatchSeq, @custgroup = i.CustGroup,
   			@customer = i.Customer, @custjob = i.CustJob, @custpo = i.CustPO, @paymenttype = i.PaymentType,
   			@locgroup = i.LocGroup, @loc = i.Location, @oldcustgroup = d.CustGroup, @oldcustomer = d.Customer,
   			@oldcustjob = d.CustJob, @oldcustpo = d.CustPO, @oldpaymenttype = d.PaymentType, @oldlocgroup = d.LocGroup,
   			@oldloc = d.Location
        from inserted i
        join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
    else
    	begin
    	 -- use a cursor to process each inserted row
    	 declare bMSIB_update cursor LOCAL FAST_FORWARD
   	 for select i.Co, i.Mth, i.BatchId, i.BatchSeq, i.CustGroup, i.Customer, i.CustJob, i.CustPO, i.PaymentType,
            i.LocGroup, i.Location, d.CustGroup, d.Customer, d.CustJob, d.CustPO, d.PaymentType, d.LocGroup, d.Location
    	 from inserted i
        join deleted d on i.Co = d.Co and i.Mth = d.Mth and i.BatchId = d.BatchId and i.BatchSeq = d.BatchSeq
   
    	 open bMSIB_update
    	 set @opencursor = 1
   
    	 fetch next from bMSIB_update into @co, @mth, @batchid, @batchseq, @custgroup, @customer, @custjob,
            @custpo, @paymenttype, @locgroup, @loc, @oldcustgroup, @oldcustomer, @oldcustjob, @oldcustpo,
    	   @oldpaymenttype, @oldlocgroup, @oldloc
    	 if @@fetch_status <> 0
    		begin
    		select @errmsg = 'Cursor error'
    		goto error
    		end
    	end
   
    MSIB_update_check:
    -- limit changes if Detail already assigned to the Invoice
    if exists(select 1 from bMSID with (nolock) where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq)
        begin
        if @custgroup <> @oldcustgroup or @customer <> @oldcustomer
            begin
            select @errmsg = 'Invoice detail exists, cannot change Customer'
            goto error
            end
        if isnull(@custjob,'') <> isnull(@oldcustjob,'') or isnull(@custpo,'') <> isnull(@oldcustpo,'')
            begin
            select @errmsg = 'Invoice detail exists, cannot change Customer Job or PO#'
            goto error
         end
        if @paymenttype <> @oldpaymenttype
        	begin
   	 	select @errmsg = 'Invoice detail exists, cannot change Payment Type'
   	 	goto error
   	 	end
   	 if isnull(@locgroup,0) <> isnull(@oldlocgroup,0) and @locgroup is not null
   		begin
   	    select @errmsg = 'Invoice detail exists, cannot change Location Group'
   	    goto error
   	    end
   	 if isnull(@loc,'') <> isnull(@oldloc,'')
           begin
           select @errmsg = 'Invoice detail exists, cannot change Location'
           goto error
           end
         end
   
   if @numrows > 1
   	begin
   	fetch next from bMSIB_update into @co, @mth, @batchid, @batchseq, @custgroup, @customer, @custjob,
   			@custpo, @paymenttype, @locgroup, @loc, @oldcustgroup, @oldcustomer, @oldcustjob, @oldcustpo,
   			@oldpaymenttype, @oldlocgroup, @oldloc
   	if @@fetch_status = 0 goto MSIB_update_check
   
   	close bMSIB_update
   	deallocate bMSIB_update
   	set @opencursor = 0
    	end
   
   
   return
   
   
   
   error:
       select @errmsg = @errmsg + ' - cannot update MS Invoice Batch Header'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biMSIB] ON [dbo].[bMSIB] ([Co], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSIB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIB].[InterCoInv]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIB].[SepHaul]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIB].[Interfaced]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIB].[Void]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSIB].[PrintedYN]'
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bMSIB].[CMAcct]'
GO
