CREATE TABLE [dbo].[bHQBC]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[Source] [dbo].[bSource] NOT NULL,
[TableName] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[InUseBy] [dbo].[bVPUserName] NULL,
[DateCreated] [smalldatetime] NOT NULL,
[CreatedBy] [dbo].[bVPUserName] NOT NULL,
[Status] [tinyint] NOT NULL,
[Rstrict] [dbo].[bYN] NOT NULL,
[Adjust] [dbo].[bYN] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PREndDate] [dbo].[bDate] NULL,
[DatePosted] [dbo].[bDate] NULL,
[DateClosed] [smalldatetime] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btHQBCd] on [dbo].[bHQBC] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: GG 11/20/00
    * Modified:
    *
    * Delete trigger on HQ Batch Control.  Status must be 5 or 6
    *
    * Delete any bHQBE and bHQCC entries that may still exist
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   -- validate Status (must be 'posted'(5) or 'canceled'(6) to delete)
   if exists(select 1 from deleted where Status < 5)
   	begin
   	select @errmsg = 'Batch status must be (5 = Posted) or (6 = Canceled)'
   	goto error
   	end
   
   -- clean up any remaining HQ Batch Errors
   delete bHQBE
   from deleted d
   join bHQBE e with (nolock) on e.Co = d.Co and e.Mth = d.Mth and e.BatchId = d.BatchId
   
   -- clean up and remain HQ Close Control entries
   delete bHQCC
   from deleted d
   join bHQCC c with (nolock) on c.Co = d.Co and c.Mth = d.Mth and c.BatchId = d.BatchId
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Batch Control!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   
   
CREATE   trigger [dbo].[btHQBCi] on [dbo].[bHQBC] for INSERT as
/*-----------------------------------------------------------------
* Created: GG 11/20/00
* Modified: GF 08/11/2003 - issue #22110 speed improvements
*			GG 02/18/07 - added date validation
*			GG 07/25/07 - #120561 - add bHQCC entries for all batches
*			DAN SO 01/30/09 - #132093 - PM Source validation needed?
*
*	Insert trigger on HQ Batch Control
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Day, must be first day of month
if exists(select top 1 1 from inserted where Datepart(day,Mth) <> 1)
	begin
	select @errmsg = 'Must be assigned to the first day of the Month'
	goto error
	end

-- validate Company
select @validcnt = count(*) from bHQCO c with (nolock) join inserted i on c.HQCo = i.Co
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Company #, must be setup in HQ'
	goto error
	end
-- validate Status
if exists(select 1 from inserted where Status not in (0,1,2,3,4,5,6))
	begin
	select @errmsg = 'Invalid Status, must be between 0 and 6'
	goto error
	end

-- #120561 - add HQ Close Control based on Batch Source
select @validcnt = count(*) from inserted where Source like 'AP%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bAPCO c (nolock) on c.APCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an AP Source require a valid AP Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'AR%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bARCO c (nolock) on c.ARCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an AR Source require a valid AR Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'CM%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bCMCO c (nolock) on c.CMCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a CM Source require a valid CM Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'EM%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bEMCO c (nolock) on c.EMCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an EM Source require a valid EM Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'GL%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bGLCO c (nolock) on c.GLCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a GL Source require a valid GL Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'HR%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, p.GLCo	-- use PR GL Co#
	from inserted i
	join dbo.bHRCO c (nolock) on c.HRCo = i.Co
	join dbo.bPRCO p (nolock) on c.PRCo = p.PRCo
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an HR Source require a valid HR and PR Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'IN%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bINCO c (nolock) on c.INCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an IN Source require a valid IN Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'JB%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo	-- use AR GL Co#
	from inserted i
	join dbo.bJBCO j (nolock) on j.JBCo = i.Co
	join dbo.bARCO c (nolock) on c.ARCo = i.Co	-- JB and AR Co#s must match
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a JB Source require a valid JB and AR Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'JC%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bJCCO c (nolock) on c.JCCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a JC Source require a valid JC Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'MS%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bMSCO c (nolock) on c.MSCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an MS Source require a valid MS Company#'
		goto error
		end
	end

-- ************** --
-- Issue: #132093 --
-- ************** --
--select @validcnt = count(*) from inserted where Source like 'PM%'
--if @validcnt > 0
--	begin
--	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
--	select i.Co, i.Mth, i.BatchId, c.GLCo	-- use JC GL Co#
--	from inserted i
--	join dbo.bPMCO j (nolock) on j.PMCo = i.Co
--	join dbo.bJCCO c (nolock) on c.JCCo = i.Co	-- PM and JC Co#s must match
--	if @@rowcount <> @validcnt
--		begin
--		select @errmsg = 'Batches referencing a PM Source require a valid PM and JC Company#'
--		goto error
--		end
--	end

select @validcnt = count(*) from inserted where Source like 'PO%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo	-- use AP GL Co#
	from inserted i
	join dbo.bPOCO j (nolock) on j.POCo = i.Co
	join dbo.bAPCO c (nolock) on c.APCo = i.Co	-- PO and AP Co#s must match
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a PO Source require a valid PO and AP Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'PR%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo
	from inserted i
	join dbo.bPRCO c (nolock) on c.PRCo = i.Co
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing a PR Source require a valid PR Company#'
		goto error
		end
	end
select @validcnt = count(*) from inserted where Source like 'SL%'
if @validcnt > 0
	begin
	insert dbo.bHQCC(Co, Mth, BatchId, GLCo)
	select i.Co, i.Mth, i.BatchId, c.GLCo	-- use AP GL Co#
	from inserted i
	join dbo.bSLCO j (nolock) on j.SLCo = i.Co
	join dbo.bAPCO c (nolock) on c.APCo = i.Co	-- SL and AP Co#s must match
	if @@rowcount <> @validcnt
		begin
		select @errmsg = 'Batches referencing an SL Source require a valid SL and AP Company#'
		goto error
		end
	end
	

return
   
   
error:
	select @errmsg = @errmsg + ' - cannot insert HQ Batch Control!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE trigger [dbo].[btHQBCu] on [dbo].[bHQBC] for UPDATE as
/*-----------------------------------------------------------------
 * Created: GG 11/20/00
 * Modified: GG 02/12/01 - don't delete bHQBE entries if source is PM
 *			GG 3/2/09 - #120561 - cleanup any remaining bHQCC entries when batch status set to 5 or 6 (completed or canceled)
 *
 *	Update trigger on HQ Batch Control
 *
 */----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
    
/* check for key changes */
if update(Co)
    begin
	select @errmsg = 'Cannot change HQ Company'
	goto error
	end
if update(Mth)
    begin
	select @errmsg = 'Cannot change Batch Month'
	goto error
	end
if update(BatchId)
    begin
	select @errmsg = 'Cannot change BatchId'
	goto error
	end
-- prevent changes to other critical column values
if update(Source) or update(TableName)
	begin
    select @errmsg = 'Cannot change Batch Source or Table Name.'
	goto error
    end
-- validate Status
if exists(select 1 from inserted where Status not in (0,1,2,3,4,5,6))
    begin
	select @errmsg = 'Invalid Status, must be between 0 and 6'
	goto error
	end
    
-- remove any HQ Batch Errors for canceled batches
delete bHQBE
from inserted i
join bHQBE e with (nolock) on e.Co = i.Co and e.Mth = i.Mth and e.BatchId = i.BatchId
where i.Status = 6 and i.Source <> 'PM Intface'  -- PM Interface will clean up

-- remove any HQ Close Control entries 
delete bHQCC
from inserted i
join bHQCC c with (nolock) on c.Co = i.Co and c.Mth = i.Mth and c.BatchId = i.BatchId
where i.Status in (5,6)		-- #120561 remove Close Control entries when batch status goes to 5 or 6 (complete or canceled)

return


error:
	select @errmsg = @errmsg + ' - cannot update HQ Batch Control!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHQBC] ON [dbo].[bHQBC] ([Co], [Mth], [BatchId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQBC] ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQBCPREndDate] ON [dbo].[bHQBC] ([PREndDate]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bHQBC_UniqueAttchID] ON [dbo].[bHQBC] ([UniqueAttchID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQBC].[Rstrict]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHQBC].[Adjust]'
GO
