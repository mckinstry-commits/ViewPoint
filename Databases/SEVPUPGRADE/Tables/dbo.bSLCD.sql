CREATE TABLE [dbo].[bSLCD]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[SLTrans] [dbo].[bTrans] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[SLChangeOrder] [smallint] NOT NULL,
[AppChangeOrder] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ActDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NOT NULL,
[ChangeCurUnits] [dbo].[bUnits] NOT NULL,
[ChangeCurUnitCost] [dbo].[bUnitCost] NOT NULL,
[ChangeCurCost] [dbo].[bDollar] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[PostedDate] [dbo].[bDate] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCD_PurgeYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ChgToTax] [dbo].[bDollar] NULL,
[ChgToJCCmtdTax] [dbo].[bDollar] NULL,
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
 
   
   
   CREATE trigger [dbo].[btSLCDd] on [dbo].[bSLCD] for DELETE as
/*--------------------------------------------------------------
     *  Created By: MV 07/21/04 - #24999 - audit change order deletes
     *  Modified: 	DC 0515/09 - #133440 - Ensure stored procedures/triggers are using the correct attachment delete proc
     *		
     *  Delete trigger for SLChange Orders
     *
     *--------------------------------------------------------------*/
    declare @numrows int, @errmsg varchar(255)
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    set nocount on
        
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bSLCD', 'Mth: ' + convert(varchar(8),d.Mth, 1) + ' SLTrans: ' + convert(varchar(10),d.SLTrans)+
   	 	' SL: ' + rtrim(d.SL) + ' SLItem: ' + convert(varchar(10),d.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),d.SLChangeOrder),
   	  d.SLCo,'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d
   join bSLCO c on d.SLCo = c.SLCo
   where c.AuditSLs = 'Y' and d.PurgeYN='N'
   
   -- Delete attachments if they exist. Make sure UniqueAttchID is not null
   insert vDMAttachmentDeletionQueue (AttachmentID, UserName, DeletedFromRecord)
   select AttachmentID, suser_name(), 'Y' 
        	from bHQAT h join deleted d on h.UniqueAttchID = d.UniqueAttchID   			
   			where d.UniqueAttchID is not null      			   		
   		          
    return
    
    error:
       select @errmsg = @errmsg + ' - cannot audit Change Order delete (bSLCD)'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLCDi    Script Date: 8/28/99 9:38:17 AM ******/
   
    CREATE    trigger [dbo].[btSLCDi] on [dbo].[bSLCD] for INSERT as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
    /*--------------------------------------------------------------
     *
     *  Insert trigger for SLCD
     *  Created By: EN  12/30/99
     *	 Modified By:	MV 07/21/04 - #24999 audit inserts
     *
     *  Validate SL and SL Item.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /*validate SL Company */
    select @validcnt = count(*) from bSLCO r
       JOIN inserted i on i.SLCo = r.SLCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL company '
    	goto error
    	end
   
    /*validate SL */
    select @validcnt = count(*) from bSLHD r
       JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL '
    	goto error
    	end
   
    /*verify SL Item */
    select @validcnt = count(*) from bSLIT r
       JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL and i.SLItem = r.SLItem
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL Item '
    	goto error
    	end
   
   -- HQ Auditing
   insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 ' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 convert(varchar(5),i.SLChangeOrder),
   	  i.SLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   from inserted i join bSLCO c on i.SLCo = c.SLCo
   where c.AuditSLs = 'Y'
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot insert into SL Change Order Detail'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLCDu    Script Date: 8/28/99 9:38:18 AM ******/
   CREATE    trigger [dbo].[btSLCDu] on [dbo].[bSLCD] for UPDATE as
   
    

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
   /*--------------------------------------------------------------
    *
    *  Update trigger for SLCD
    *  Created By: EN  12/30/99
    *  Modified by: EN 4/12/00 - add validation for SL and SLItem
    *				 MV 07/22/04 - audit changes
    *
    *  Reject key changes.
    *--------------------------------------------------------------*/
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    select @validcnt=0
   
    set nocount on
   
    /* check for key changes */
    select @validcnt = count(*) from deleted d, inserted i
    	where d.SLCo = i.SLCo and d.Mth = i.Mth and d.SLTrans = i.SLTrans
    if @numrows <> @validcnt
    	begin
    	select @errmsg = 'Cannot change Company, Month or Transaction number '
    	goto error
    	end
   
    /*validate SL */
    if update(SL)
       begin
        select @validcnt = count(*) from bSLHD r
           JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Invalid SL '
        	goto error
        	end
       end
   
    /*verify SL Item */
    if update(SLItem)
       begin
        select @validcnt = count(*) from bSLIT r
           JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL and i.SLItem = r.SLItem
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Invalid SL Item '
        	goto error
        	end
       end
   
   -- Insert records into HQMA for changes made to audited fields
    if  exists (select 1 from inserted i join bSLCO c with (nolock) on c.SLCo = i.SLCo where c.AuditSLs = 'Y')
    begin
     
    	if update(SLChangeOrder)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','SL Change Order', convert(varchar(5),d.SLChangeOrder), convert(varchar(5),i.SLChangeOrder),
   		 getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.SLChangeOrder,'') <> isnull(d.SLChangeOrder,'')
    
   	if update(AppChangeOrder)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','App Change Order', convert(varchar(10),d.AppChangeOrder), convert(varchar(10),i.AppChangeOrder),
   		 getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.AppChangeOrder,'') <> isnull(d.AppChangeOrder,'') 
   
   	if update(ActDate)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','Actual Date', convert(varchar(20),d.ActDate,1), convert(varchar(20),i.ActDate,1),
   		 getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.ActDate,'') <> isnull(d.ActDate,'') 
   
   	if update(Description)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','Description',d.Description, i.Description,getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.Description,'') <> isnull(d.Description,'')
   
   	if update(ChangeCurUnits)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','Change to Units', convert(varchar(20),d.ChangeCurUnits), convert(varchar(20),i.ChangeCurUnits),
   		getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.ChangeCurUnits,'') <> isnull(d.ChangeCurUnits,'') 
   
   	if update(ChangeCurUnitCost)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','Change to Unit Cost', convert(varchar(20),d.ChangeCurUnitCost), convert(varchar(20),i.ChangeCurUnitCost),
   		getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.ChangeCurUnitCost,'') <> isnull(d.ChangeCurUnitCost,'')
   
   	if update(ChangeCurCost)
    	    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    		select 'bSLCD', 'Mth: ' + convert(varchar(8),i.Mth, 1) + ' SLTrans: ' + convert(varchar(10),i.SLTrans)+
   	 	' SL: ' + rtrim(i.SL) + ' SLItem: ' + convert(varchar(10),i.SLItem) + ' SL ChgOrder: ' +
   	 	convert(varchar(5),i.SLChangeOrder),
   	  	d.SLCo,'C','Change to Cost', convert(varchar(20),d.ChangeCurCost), convert(varchar(20),i.ChangeCurCost),
   		getdate(), SUSER_SNAME()
    	    from inserted i join deleted d on i.SLCo = d.SLCo and i.Mth = d.Mth and i.SLTrans = d.SLTrans and
   		i.SL = d.SL and i.SLItem = d.SLItem
   		where isnull(i.ChangeCurCost,'') <> isnull(d.ChangeCurCost,'')
   
    end
   
   
   return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into SL Change Order Detail '
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLCD] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLCD] ON [dbo].[bSLCD] ([SLCo], [Mth], [SLTrans]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biSLCDACO] ON [dbo].[bSLCD] ([SLCo], [SL], [AppChangeOrder], [Mth], [SLTrans]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLCD].[ChangeCurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCD].[PurgeYN]'
GO
