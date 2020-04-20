CREATE TABLE [dbo].[bSLXB]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[RemainCost] [dbo].[bDollar] NOT NULL,
[CloseDate] [dbo].[bDate] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btSLXBd    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE trigger [dbo].[btSLXBd] on [dbo].[bSLXB] for DELETE as
   
   

declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @validcnt3 int
   
   /*--------------------------------------------------------------
    *  Created: 5/28/97 kf
    *  Modified: 04/22/99 GG    (SQL 7.0)
    *
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
   
    if @numrows = 0 return
   
   set nocount on
   
   update bSLHD
   set InUseBatchId = null, InUseMth = null
   from deleted d, bSLHD t
   where d.Co=t.SLCo and d.SL=t.SL and d.SL not in (select SL from bSLCB r where
   	r.Co=d.Co and r.SL=d.SL and r.Mth=d.Mth and r.BatchId=d.BatchId)
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete SL Close Batch'
   
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btSLXBi    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE   trigger [dbo].[btSLXBi] on [dbo].[bSLXB] for INSERT as 
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), 
          @validcnt int, @validcnt2 int, @keyco bCompany,
          @keymth bMonth, @keybatchid bBatchID, @glco bCompany
   
   /*-------------------------------------------------------------- 
    *
    *  Insert trigger for SLXB
    *  Created By: kf 
    *  Date:       5/14/97
    *  Modified by: kb 1/4/99
    *				 MV 06/06/03 - #17050 - pseudo cursor cleanup.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount 
    if @numrows = 0 return
    set nocount on
    
   /* validate batch */
   
   
   select @validcnt = count(*) from bHQBC r JOIN inserted i ON 
   	i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Invalid Batch ID#'
   	goto error
   	end
   
   select @validcnt = count(*) from bHQBC r JOIN inserted i ON
   	i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and not r.BatchId is null
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Batch (In Use) name must first be updated.'
   	goto error
   	end
   
   select @validcnt = count(*) from bHQBC r JOIN inserted i ON
   	i.Co=r.Co and i.Mth=r.Mth and i.BatchId=r.BatchId and r.Status=0
   if @validcnt<>@numrows
   	begin
   	select @errmsg = 'Must be an open batch.'
   
   	goto error
   	end
   
   -- add HQ Close Control for GL Co#s referenced by SLXB
     insert bHQCC (Co, Mth, BatchId, GLCo)
     select Co, Mth, BatchId, a.GLCo 
     from inserted i, bAPCO a where i.Co = a.APCo and not exists (select 1 from bHQCC h
   	 join inserted i on h.Co = i.Co and h.Mth = i.Mth and h.BatchId = i.BatchId)
     group by Co, Mth, BatchId, a.GLCo
   
   /*select @keyco = min(Co) from inserted 
   while @keyco is not null
   	begin
   	select @keymth = min(Mth) from inserted where Co = @keyco
   	while @keymth is not null
   		begin
   		select @keybatchid = min(BatchId) from inserted i where Co = @keyco and Mth = @keymth
   		while @keybatchid is not null
   			begin
   			select @glco = a.GLCo
   			  from inserted i, bAPCO a where i.Co = a.APCo and 
   			  i.Co = @keyco and i.Mth = @keymth and i.BatchId = @keybatchid
   
   			-- insert the HQCC record for the GL Company for the CM account 
   			if not exists(select * from bHQCC where Co = @keyco and Mth = @keymth and BatchId = @keybatchid 
   			  and GLCo = @glco)
   				begin
   				insert bHQCC (Co, Mth, BatchId, GLCo)
   				values (@keyco, @keymth, @keybatchid, @glco)
   				end
   			select @keybatchid = min(BatchId) from inserted where Co = @keyco and  Mth = @keymth
   				and BatchId > @keybatchid
   			if @@rowcount = 0 select @keybatchid = null
   			end
   		select @keymth = min(Mth) from inserted where Co = @keyco and Mth > @keymth
   		if @@rowcount = 0 select @keymth = null
   		end
   	select @keyco = min(Co) from inserted where Co > @keyco 
   	if @@rowcount = 0 select @keyco = null
   	end*/
   
   /* validate SLCo */
   select @validcnt = count(*) from bSLCO r JOIN inserted i ON
       i.Co = r.SLCo
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'SL Company is Invalid '
   	goto error
   	end
   
   /* Validate SL */
   select @validcnt = count(*) from bSLHD r JOIN inserted i ON
   	i.Co = r.SLCo
       	and i.SL = r.SL
   
   if @validcnt <> @numrows
   	begin
    	select @errmsg = 'SL is Invalid '
    	goto error
    	end
   
   update bSLHD
   set InUseBatchId=i.BatchId, InUseMth=i.Mth from bSLHD r, inserted i 
   	where i.SL=r.SL and i.Co=r.SLCo
   
   if @@rowcount<>@numrows
   	begin
   	select @errmsg = 'Unable to flag SL as (In Use).'
   	goto error
   	end
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot insert SL Close Batch'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btSLXBu    Script Date: 8/28/99 9:38:18 AM ******/
   
   CREATE trigger [dbo].[btSLXBu] on [dbo].[bSLXB] for UPDATE as
   

/*--------------------------------------------------------------
    *
    *  Update trigger for SLXB
    *  Created: EN 3/28/00
    *
    *  Reject primary key changes.
    *  Validate SL.
    *--------------------------------------------------------------*/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   select @validcnt = count(*) from deleted d
       join inserted i on i.Co=d.Co and i.Mth=d.Mth and i.BatchId=d.BatchId and i.BatchSeq=d.BatchSeq
   if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Cannot change Primary key'
    	goto error
    	end
   
   /* Validate SL */
   select @validcnt = count(*) from bSLHD r JOIN inserted i ON i.Co = r.SLCo and i.SL = r.SL
   if @validcnt <> @numrows
   	begin
    	select @errmsg = 'SL is Invalid '
    	goto error
    	end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot update SL Close Batch'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biSLXB] ON [dbo].[bSLXB] ([Co], [Mth], [BatchId], [SL]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
