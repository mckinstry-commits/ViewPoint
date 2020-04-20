CREATE TABLE [dbo].[bHREH]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[DateChanged] [dbo].[bDate] NOT NULL,
[Seq] [smallint] NOT NULL,
[Code] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ExpReturnDate] [dbo].[bDate] NULL,
[Supervisor] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btHREHd] on [dbo].[bHREH] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 3/15/04 23061
	*				 mh 10/29/2008 - 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHREH','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(6),d.HRRef) +
    ' DateChanged: ' + convert(varchar(20),isnull(d.DateChanged,'')) + ' Seq: ' + convert(varchar(6),isnull(d.Seq,'')),
   	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
   	from deleted d, bHRCO e
    where e.HRCo = d.HRCo and e.AuditEmplHistYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HREH! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHREHi******/
   CREATE  trigger [dbo].[btHREHi] on [dbo].[bHREH] for INSERT as
    

	/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 		Modified by: mh 3/15/04 23061
	 *					 mh 10/29/2008 - 127008
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
	if not exists (select 1 from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditEmplHistYN = 'Y')
    	return
   
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHREH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),i.HRRef) +
    ' DateChanged: ' + convert(varchar(20),isnull(i.DateChanged,'')) + ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditEmplHistYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HREH!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
   
   /****** Object:  Trigger dbo.btHREHu    Script Date: 8/28/99 9:37:38 AM ******/
    CREATE   trigger [dbo].[btHREHu] on [dbo].[bHREH] for UPDATE as
    

	/*-----------------------------------------------------------------
     *  Created by: ae 04/05/00
     * 	Modified by: mh 3/16/04 23061
   	 *				mh 4/29/2005 - 28581 - Change HRRef conversion from varchar(5) to varchar(6)
     *				mh 10/29/2008 - 127008
	 *
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
	if update(Code)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHREH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' DateChanged: ' + convert(varchar(20),isnull(i.DateChanged,'')) + ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','Code',
        convert(varchar(10),d.Code), Convert(varchar(10),i.Code),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
        i.DateChanged = d.DateChanged and i.Seq = d.Seq
        and i.Code <> d.Code
		join dbo.bHRCO e on  i.HRCo = e.HRCo and e.AuditEmplHistYN  = 'Y'
    
	if update(ExpReturnDate)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHREH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' DateChanged: ' + convert(varchar(20),isnull(i.DateChanged,'')) + ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','ExpReturnDate',
        convert(varchar(20),d.ExpReturnDate), Convert(varchar(20),i.ExpReturnDate),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
        i.DateChanged = d.DateChanged and i.Seq = d.Seq
        and i.ExpReturnDate <> d.ExpReturnDate
		join dbo.bHRCO e on  i.HRCo = e.HRCo and e.AuditEmplHistYN  = 'Y'


	if update(Supervisor)    
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHREH', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' DateChanged: ' + convert(varchar(20),isnull(i.DateChanged,'')) + ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')),
        i.HRCo, 'C','Supervisor',
        convert(varchar(30),d.Supervisor), Convert(varchar(30),i.Supervisor),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef and
        i.DateChanged = d.DateChanged and i.Seq = d.Seq
        and i.Supervisor <> d.Supervisor
		join dbo.bHRCO e on  i.HRCo = e.HRCo and e.AuditEmplHistYN  = 'Y'
  
    
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update HR Resource Grievance!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction
    
    
    
    
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHREH] ON [dbo].[bHREH] ([HRCo], [HRRef], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHREH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
