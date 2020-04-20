CREATE TABLE [dbo].[bHRPT]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[TrainCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[RequiredYN] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
   
   
   CREATE   trigger [dbo].[btHRPTd] on [dbo].[bHRPT] for Delete
    as
    

	/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 23061 3/17/04
	*				 mh 10/29/2008 - 127008
    *
    *
    **************************************************************/
    
	declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    
	if @numrows = 0 return
    
	set nocount on
   
   /* Audit inserts */
   insert into bHQMA select 'bHRPT','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(d.PositionCode,'')) +
       ' TrainCode: ' + convert(varchar(10),isnull(d.TrainCode,'')) + ' RequiredYN: ' + convert(varchar(10),isnull(d.RequiredYN,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d join dbo.bHRCO e on e.HRCo = d.HRCo and e.AuditPositionsYN  = 'Y'
   
    Return

    error:

    select @errmsg = (@errmsg + ' - cannot delete HRPT! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   

	CREATE   trigger [dbo].[btHRPTi] on [dbo].[bHRPT] for INSERT as
    

	/*-----------------------------------------------------------------
     *  Created by: ae  3/31/00
     * 	Modified by: mh 23061 3/17/04
	 *				 mh 10/29/2008 - 127008
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
   
   insert into bHQMA select 'bHRPT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')) +
       ' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')) + ' RequiredYN: ' + convert(varchar(10),isnull(i.RequiredYN,'')),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i join dbo.bHRCO e on e.HRCo = i.HRCo and e.AuditPositionsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRPT!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  

   CREATE   trigger [dbo].[btHRPTu] on [dbo].[bHRPT] for UPDATE as
   

	/*-----------------------------------------------------------------
    *  Created by: ae 04/04/00
    * 	Modified by: mh 23061 3/17/04
	*				 mh 10/29/2008 - 127008
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

	if update(RequiredYN)
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,[DateTime], UserName) 
		select 'bHRPT', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')) +
		' TrainCode: ' + convert(varchar(10),isnull(i.TrainCode,'')),
		i.HRCo, 'C','RequiredYN',
		convert(varchar(1),d.RequiredYN), Convert(varchar(1),i.RequiredYN),
   		getdate(), SUSER_SNAME()
   		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.PositionCode = d.PositionCode and
        i.TrainCode = d.TrainCode and i.RequiredYN <> d.RequiredYN
		join dbo.bHRCO e on i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'

   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HRPT!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRPT] ON [dbo].[bHRPT] ([HRCo], [PositionCode], [TrainCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRPT] ([KeyID]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRPT].[RequiredYN]'
GO
