CREATE TABLE [dbo].[bHRAD]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Accident] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [int] NULL,
[BodyPart] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[InjuryType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRAD] ON [dbo].[bHRAD] ([HRCo], [Accident], [Seq], [BodyPart], [InjuryType]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRADd    Script Date: 2/3/2003 7:05:27 AM ******/
   CREATE   trigger [dbo].[btHRADd] on [dbo].[bHRAD] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: 3/15/04 mh 23061
	*					04/28/08 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
   insert into bHQMA select 'bHRAD', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(d.Accident,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d,  bHRCO e
       where e.HRCo = d.HRCo and e.AuditAccidentsYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRAD! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRADi    Script Date: 2/3/2003 7:03:16 AM ******/
   /****** Object:  Trigger dbo.btHRADi******/
   CREATE   trigger [dbo].[btHRADi] on [dbo].[bHRAD] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by: mh 3/15/04 23061
	 *				 mh 4/28/08 127008	
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
   if not exists (select 1 from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditAccidentsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRAD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
      	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  bHRCO e
       where e.HRCo = i.HRCo and e.AuditAccidentsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRAD!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRADu    Script Date: 2/3/2003 7:04:26 AM ******/
   /****** Object:  Trigger dbo.btHRADu    Script Date: 8/28/99 9:37:38 AM ******/
   CREATE   trigger [dbo].[btHRADu] on [dbo].[bHRAD] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by: mh 3/15/04 23061
	*				 mh 4/28/08 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   insert into bHQMA select 'bHRAD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','Seq',
       convert(varchar(6),d.Seq), Convert(varchar(6),i.Seq),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.Seq <> d.Seq
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   
   insert into bHQMA select 'bHRAD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','BodyPart',
       convert(varchar(10),d.BodyPart), Convert(varchar(10),i.BodyPart),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.BodyPart <> d.BodyPart
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   
   insert into bHQMA select 'bHRAD', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' Accident: ' + convert(varchar(10),isnull(i.Accident,'')),
       i.HRCo, 'C','InjuryType',
       convert(varchar(10),d.InjuryType), Convert(varchar(10),i.InjuryType),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bHRCO e
   	where i.HRCo = d.HRCo and i.Accident = d.Accident
             and i.InjuryType <> d.InjuryType
       and i.HRCo = e.HRCo and e.AuditAccidentsYN  = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRAD!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
  
 



GO
