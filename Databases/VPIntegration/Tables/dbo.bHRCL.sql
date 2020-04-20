CREATE TABLE [dbo].[bHRCL]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[ContactSeq] [int] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[ClaimContact] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ClaimSeq] [int] NULL,
[Witness] [char] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHRCLd    Script Date: 2/3/2003 9:30:28 AM ******/
   CREATE  trigger [dbo].[btHRCLd] on [dbo].[bHRCL] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified:	mh 10/29/2008 - 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
	/* Audit inserts */
	insert into bHQMA select 'bHRCL', 'HRCo: ' + convert(char(3),d.HRCo) + ' Accident: ' + convert(varchar(10),d.Accident),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join bHRCO e on e.HRCo = d.HRCo and e.AuditAccidentsYN  = 'Y'
   
    Return

    error:
    select @errmsg = (@errmsg + ' - cannot delete HRCL! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

	CREATE  trigger [dbo].[btHRCLi] on [dbo].[bHRCL] for INSERT as
    

	/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 		Modified by: mh 10/29/2008 - 127008 
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
	if not exists (select 1 from inserted i join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN = 'Y')

	return

	insert into bHQMA select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident),
	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
	from inserted i join bHRCO e on e.HRCo = i.HRCo and e.AuditAccidentsYN = 'Y'
   
	return

	error:
		select @errmsg = @errmsg + ' - cannot insert into HRCL!'
		RAISERROR(@errmsg, 11, -1);
		rollback transaction

   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   

	CREATE  trigger [dbo].[btHRCLu] on [dbo].[bHRCL] for UPDATE as
   

	/*-----------------------------------------------------------------
    *	Created by: ae 04/04/00
    * 	Modified by:	mh 10/29/2008 - 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

	if update(Seq)  
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','Seq', convert(varchar(6),d.Seq), Convert(varchar(6),i.Seq), getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and 
		i.Seq <> d.Seq
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'

	if update(ContactSeq)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','Seq', convert(varchar(6),d.Seq), Convert(varchar(6),i.Seq),
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq and
		i.ContactSeq <> d.ContactSeq
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'

	if update(Date)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','Date', convert(varchar(20),d.Date), Convert(varchar(20),i.Date),
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and i.Seq = d.Seq
		and i.Date <> d.Date
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
	if update(ClaimContact)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','ClaimContact', 
		convert(varchar(10),d.ClaimContact), Convert(varchar(10),i.ClaimContact),
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and 
		i.ClaimContact <> d.ClaimContact
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
	if update(ClaimSeq)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','ClaimSeq',
		convert(varchar(6),d.ClaimSeq), Convert(varchar(6),i.ClaimSeq),
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and 
		i.ClaimSeq <> d.ClaimSeq
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
	if update(Witness)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
		select 'bHRCL', 'HRCo: ' + convert(char(3),i.HRCo) + ' Accident: ' + convert(varchar(10),i.Accident)
		+ ' Seq: ' + convert(varchar, i.Seq) + ' ContactSeq: ' + convert(varchar, i.ContactSeq),
		i.HRCo, 'C','Witness',
		convert(varchar(1),d.Witness), Convert(varchar(1),i.Witness),
   		getdate(), SUSER_SNAME()
   		from inserted i join deleted d on i.HRCo = d.HRCo and i.Accident = d.Accident and 
		i.Witness <> d.Witness
		join bHRCO e on i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'

  
	return
   
	error:
   		select @errmsg = @errmsg + ' - cannot update HRCL!'
   		RAISERROR(@errmsg, 11, -1);
   
   		rollback transaction
   
GO
CREATE UNIQUE CLUSTERED INDEX [biHRCL] ON [dbo].[bHRCL] ([HRCo], [Accident], [Seq], [ContactSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRCL] ([KeyID]) ON [PRIMARY]
GO
