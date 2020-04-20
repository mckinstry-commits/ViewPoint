CREATE TABLE [dbo].[bPOCD]
(
[POCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[POTrans] [int] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[POItem] [dbo].[bItem] NOT NULL,
[ChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeCurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NULL,
[ChangeCurCost] [dbo].[bDollar] NOT NULL,
[ChangeBOUnits] [dbo].[bUnits] NOT NULL,
[ChangeBOCost] [dbo].[bDollar] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Seq] [int] NULL,
[ChgTotCost] [dbo].[bDollar] NULL CONSTRAINT [DF_bPOCD_ChgTotCost] DEFAULT ((0)),
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCD_PurgeYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ChgToTax] [dbo].[bDollar] NULL,
[POCONum] [smallint] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPOCD] ON [dbo].[bPOCD] ([POCo], [PO], [POItem], [Mth], [POTrans], [Seq]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOCD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biPOCDTrans] ON [dbo].[bPOCD] ([POTrans], [Mth], [POCo]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
     CREATE          trigger [dbo].[btPOCDd] on [dbo].[bPOCD] for DELETE as
    

/*--------------------------------------------------------------
     *  Created By: MV 07/21/04 - #24999 - audit change order deletes
     *  Modified:	 MV 10/21/04 - #25465 - isnull wrap ChangeOrder 
     *				Jonathan 05/29/09 - 133438 - Updated to handle attachments.	
     *		
     *  Delete trigger for PO Change Orders
     *
     *--------------------------------------------------------------*/
    declare @numrows int, @errmsg varchar(255)
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    set nocount on
     
   
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bPOCD','Mth: ' + convert(varchar(8),d.Mth, 1) + ' POTrans: ' + convert(varchar(20),d.POTrans) +
   	  ' PO: ' + rtrim(d.PO) + ' POItem: ' + convert(varchar(10),d.POItem) + ' ChgOrder: ' + isnull(ltrim(d.ChangeOrder),''),
   	  d.POCo,'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d
   join bPOCO c on d.POCo = c.POCo
   where c.AuditPOs = 'Y' and d.PurgeYN='N'
   
   
	-- Delete attachments if they exist. Make sure UniqueAttchID is not null
	insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
	  select AttachmentID, suser_name(), 'Y' 
		  from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID                  
		  where d.UniqueAttchID is not null                               

   
    return
    
    error:
       select @errmsg = @errmsg + ' - cannot audit Change Order delete (bPOCD)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOCDi    Script Date: 12/16/99 02:32:00 PM ******/
      
      CREATE      trigger [dbo].[btPOCDi] on [dbo].[bPOCD] for INSERT as
      

/*--------------------------------------------------------------
       *  Insert trigger for POCD
       *  Created By: EN
       *  Date:       12/16/99
       *	Modified By:	MV 7/21/04 - #24999 auditing
       *					MV 10/04/04 - @25658 - isnull wrap ChangeOrder in audit KeyString
       *
       *  Insert trigger for POCD - PO Change Order Detail
       *
       *--------------------------------------------------------------*/
      declare @numrows int, @validcnt int, @errmsg varchar(255)
      
      select @numrows = @@rowcount
      if @numrows = 0 return
      
      set nocount on
      
      -- validate PO
      select @validcnt = count(*)
      from bPOHD r
      JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
      if @validcnt <> @numrows
         begin
         select @errmsg = 'PO is Invalid '
         goto error
         end
      
      -- validate PO Item
      select @validcnt = count(*)
      from bPOIT r
      JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO and i.POItem = r.POItem
      if @validcnt <> @numrows
         begin
         select @errmsg = 'PO Item is Invalid '
         goto error
         end
      
      -- HQ Auditing
      insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
      select 'bPOCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
      		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
      	    i.POCo,'A', null, null, null, getdate(), SUSER_SNAME()
      from inserted i
      join bPOCO c on i.POCo = c.POCo
      where c.AuditPOs = 'Y'
      
      return
      
      error:
          select @errmsg = @errmsg + ' - cannot insert PO Change Order Detail'
          RAISERROR(@errmsg, 11, -1);
          rollback transaction
      
      
      
      
      
     
    
    
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOCDu    Script Date: 8/28/99 9:38:06 AM ******/
   
    CREATE      trigger [dbo].[btPOCDu] on [dbo].[bPOCD] for UPDATE as
   

/****************************************************
    *	Created: EN 12/16/99
    *	Modified: GG 04/25/02 - #17051 cleanup
    *			  MV 07/21/04 - #24999 audit updates
    *			  MV 10/21/04 - #25465 - isnull wrap ChangeOrder 
    *
    *	Update trigger for PO Change Order Detail
    *
    *  Rejects any primary key changes and validates PO and PO Item.
    ****************************************************/
   
   declare @numrows int, @errmsg varchar(255), @validcnt int, @rcode tinyint
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.POCo = i.POCo and d.Mth = i.Mth and d.POTrans = i.POTrans
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Company, Month, or PO Trans#', @rcode = 1
   	goto error
   	end
   
   -- validate PO
   if update(PO)
   	begin
   	select @validcnt = count(*)
   	from bPOHD r
   	JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
   	if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'PO is Invalid '
   	   goto error
   	   end
   	end
   
   -- validate PO Item
   if update(PO) or update(POItem)
   	begin
   	select @validcnt = count(*)
   	from bPOIT r
   	JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO and i.POItem = r.POItem
   	if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'PO Item is Invalid '
   	   goto error
   	   end
   	end
   
    -- Insert records into HQMA for changes made to audited fields
    if  exists (select 1 from inserted i join bPOCO c with (nolock) on c.POCo = i.POCo where c.AuditPOs = 'Y')
    begin
     
    	if update(ChangeOrder)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   	  	i.POCo,'C','Change Order', d.ChangeOrder, i.ChangeOrder, getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem
   		where isnull(i.ChangeOrder,'') <> isnull(d.ChangeOrder,'') 
   
   	if update(ActDate)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   	  	i.POCo,'C','Act Date', convert(varchar(8),d.ActDate,1), convert(varchar(8),i.ActDate,1), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem
    	    where isnull(i.ActDate,'') <> isnull(d.ActDate,'') 
   	
    	if update(Description)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   		 i.POCo, 'C','Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem
    	    where isnull(i.Description,'') <> isnull(d.Description,'') 
      
    	if update(ChangeCurUnits)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   		 i.POCo, 'C','Current Units', convert(varchar(20),d.ChangeCurUnits), convert(varchar(20),i.ChangeCurUnits), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem
    	    where i.ChangeCurUnits <> d.ChangeCurUnits 
    
    	if update(CurUnitCost)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
    		i.POCo, 'C','Current Unit Cost', convert(varchar(20),d.CurUnitCost), convert(varchar(20),i.CurUnitCost), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.PO = d.PO and i.POItem = d.POItem
    	    where i.CurUnitCost <> d.CurUnitCost 
     
    	if update(ChangeCurCost)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   		i.POCo, 'C','Total Cost', convert(varchar(20),d.ChangeCurCost), convert(varchar(20),i.ChangeCurCost), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem where i.ChangeCurCost <> d.ChangeCurCost 
    
   	if update(ChangeBOUnits)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   		i.POCo, 'C','Change BO Units', convert(varchar(20),d.ChangeBOUnits), convert(varchar(20),i.ChangeBOUnits), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem where i.ChangeBOUnits <> d.ChangeBOUnits 
   
   	if update(ChangeBOCost)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bPOCD','Mth: ' + convert(varchar(8),i.Mth, 1) + ' POTrans: ' + convert(varchar(20),i.POTrans) +
   		' PO: ' + rtrim(i.PO) + ' POItem: ' + convert(varchar(10),i.POItem) + ' ChgOrder: ' + isnull(ltrim(i.ChangeOrder),''),
   		i.POCo, 'C','Change BO Cost', convert(varchar(20),d.ChangeBOCost), convert(varchar(20),i.ChangeBOCost), getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.POCo = d.POCo and i.Mth = d.Mth and i.POTrans = d.POTrans and
   		i.PO = d.PO and i.POItem = d.POItem where i.ChangeBOCost <> d.ChangeBOCost 
    		
   end
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot update PO Change Order Detail'
       RAISERROR(@errmsg, 11, -1);
   
       rollback transaction
   
   
   
   
   
   
  
 



GO

EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPOCD].[CurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bPOCD].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCD].[PurgeYN]'
GO
