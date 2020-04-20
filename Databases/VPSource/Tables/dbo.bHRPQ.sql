CREATE TABLE [dbo].[bHRPQ]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[SkillCode] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[RequiredYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bHRPQ] ADD
CONSTRAINT [CK_bHRPQ_RequiredYN] CHECK (([RequiredYN]='Y' OR [RequiredYN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE  trigger [dbo].[btHRPQd] on [dbo].[bHRPQ] for Delete
    as
    

	/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified:	mh 10/29/2008 - Issue 127008
    *
    *
    **************************************************************/

    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
    select @numrows = @@rowcount

    if @numrows = 0 return

    set nocount on
   
   /* Audit inserts */
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)
	select 'bHRPQ','HRCo: ' + convert(char(3),d.HRCo) + ' PositionCode: ' + convert(varchar(10),d.PositionCode) +
    ' SkillCode: ' + convert(varchar(10),d.SkillCode) + ' RequiredYN: ' + convert(varchar(10),d.RequiredYN),
    d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    from deleted d join dbo.bHRCO e on e.HRCo = d.HRCo and e.AuditPositionsYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRPQ! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE  trigger [dbo].[btHRPQi] on [dbo].[bHRPQ] for INSERT as
    

	/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 		Modified by:  mh 10/29/2008 - 127008
     *
     *
     */----------------------------------------------------------------

    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount

    if @numrows = 0 return

    set nocount on
   
    /* Audit inserts */
	if not exists (select 1 from inserted i join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN = 'Y')
		return

	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName)   
	select 'bHRPQ', 'HRCo: ' + convert(char(3),i.HRCo) + ' PositionCode: ' + convert(varchar(10),i.PositionCode) +
    ' SkillCode: ' + convert(varchar(10),i.SkillCode) + ' RequiredYN: ' + convert(varchar(10),i.RequiredYN),
    i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    from inserted i join dbo.bHRCO e on e.HRCo = i.HRCo and e.AuditPositionsYN = 'Y'
   
	return
   
    error:

    	select @errmsg = @errmsg + ' - cannot insert into HRPQ!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

	CREATE  trigger [dbo].[btHRPQu] on [dbo].[bHRPQ] for UPDATE as
   

	/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by:	mh 10/29/2008 - 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

   select @numrows = @@rowcount

   if @numrows = 0 return

   set nocount on
   
	if update(RequiredYN)
		insert into bHQMA select 'bHRPQ', 'HRCo: ' + convert(char(3),i.HRCo) + ' PositionCode: ' + convert(varchar(10),i.PositionCode) +
		' SkillCode: ' + convert(varchar(10),i.SkillCode),
		i.HRCo, 'C','RequiredYN', convert(varchar(1),d.RequiredYN), Convert(varchar(1),i.RequiredYN),
		getdate(), SUSER_SNAME()
		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode and
	    i.SkillCode = d.SkillCode and i.RequiredYN <> d.RequiredYN
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRPQ!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRPQ] ON [dbo].[bHRPQ] ([HRCo], [PositionCode], [SkillCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRPQ] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRPQ].[RequiredYN]'
GO
