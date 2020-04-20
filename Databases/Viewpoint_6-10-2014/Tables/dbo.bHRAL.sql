CREATE TABLE [dbo].[bHRAL]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NOT NULL,
[DaySeq] [int] NOT NULL,
[BeginDate] [dbo].[bDate] NOT NULL,
[EndDate] [dbo].[bDate] NULL,
[Days] [int] NULL,
[Type] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRALd    Script Date: 2/3/2003 7:10:28 AM ******/
   CREATE   trigger [dbo].[btHRALd] on [dbo].[bHRAL] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 3/15/04 23061
    *				 mh 4/18/08 127008
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
   insert into bHQMA select 'bHRAL','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(d.Accident,'')) +
       ' Seq: ' + convert(varchar(6),isnull(d.Seq,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d,  bHRCO e
       where e.HRCo = d.HRCo and e.AuditAccidentsYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRAL! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRALi    Script Date: 2/3/2003 7:07:32 AM ******/
   /****** Object:  Trigger dbo.btHRALi******/
   CREATE   trigger [dbo].[btHRALi] on [dbo].[bHRAL] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by: mh 3/15/04 23061
	 *				 mh 4/28/08 - 127008
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
   if not exists (select * from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditAccidentsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRAL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       ' Seq: ' + convert(varchar(6),isnull(i.Seq,'')) + ' DaySeq: ' + convert(varchar(6),isnull(i.DaySeq,'')),
      	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  bHRCO e
       where e.HRCo = i.HRCo and e.AuditAccidentsYN = 'Y'
   
       return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRAL!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRALu    Script Date: 2/3/2003 7:09:18 AM ******/
   /****** Object:  Trigger dbo.btHRALu    Script Date: 8/28/99 9:37:38 AM ******/
   CREATE   trigger [dbo].[btHRALu] on [dbo].[bHRAL] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by: mh 3/15/04 23061
	*				 mh 4/28/08 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   insert into bHQMA select 'bHRAL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       ' Seq: ' + convert(varchar(6),i.Seq) + ' DaySeq: ' + convert(varchar(6),isnull(i.DaySeq,'')),
       i.HRCo, 'C','BeginDate',
       convert(varchar(20),d.BeginDate), Convert(varchar(20),i.BeginDate),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.DaySeq = d.DaySeq
             and i.BeginDate <> d.BeginDate
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       ' Seq: ' + convert(varchar(6),i.Seq) + ' DaySeq: ' + convert(varchar(6),isnull(i.DaySeq,'')),
       i.HRCo, 'C','EndDate',
       convert(varchar(20),d.EndDate), Convert(varchar(20),i.EndDate),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.DaySeq = d.DaySeq
             and i.EndDate <> d.EndDate
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   insert into bHQMA select 'bHRAL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       ' Seq: ' + convert(varchar(6),i.Seq) + ' DaySeq: ' + convert(varchar(6),isnull(i.DaySeq,'')),
       i.HRCo, 'C','Days',
       convert(varchar(6),d.Days), Convert(varchar(6),i.Days),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.DaySeq = d.DaySeq
             and i.Days <> d.Days
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   
   insert into bHQMA select 'bHRAL', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')) +
       ' Seq: ' + convert(varchar(6),i.Seq) + ' DaySeq: ' + convert(varchar(6),isnull(i.DaySeq,'')),
       i.HRCo, 'C','Type',
       convert(varchar(20),d.Type), Convert(varchar(20),i.Type),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident and
             i.Seq = d.Seq and i.DaySeq = d.DaySeq
             and i.Type <> d.Type
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRAL!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRAL] ON [dbo].[bHRAL] ([HRCo], [Accident], [Seq], [DaySeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
