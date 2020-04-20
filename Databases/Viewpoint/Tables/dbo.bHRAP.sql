CREATE TABLE [dbo].[bHRAP]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PartTimeYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Part_time_Hours] [dbo].[bHrs] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRAP] ON [dbo].[bHRAP] ([HRCo], [HRRef], [PositionCode]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRAP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHRAPd    Script Date: 2/3/2003 8:41:02 AM ******/
   CREATE   trigger [dbo].[btHRAPd] on [dbo].[bHRAP] for Delete
    as
    

/**************************************************************
    * Created: 04/03/00 ae
    * Last Modified: mh 3/15/04 23061
	*				 mh 04/28/07 127008
    *
    *
    **************************************************************/
    declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @errno int, @numrows int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   /* Audit inserts */
   insert into bHQMA select 'bHRAP','HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' HRRef: ' + convert(varchar(10),isnull(d.HRRef,'')) +
       ' PositionCode : ' + convert(varchar(10),isnull(d.PositionCode,'')) + ' PartTimeYN: ' + convert(varchar(10),isnull(d.PartTimeYN,'')),
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d,  bHRCO e
       where e.HRCo = d.HRCo and e.AuditPositionsYN  = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete HRAP! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHRAPi******/
   CREATE  trigger [dbo].[btHRAPi] on [dbo].[bHRAP] for INSERT as
    

/*-----------------------------------------------------------------
     *   	Created by: ae  3/31/00
     * 	Modified by: mh 3/15/04 23061
	 *				 mh 04/28/08 127008
     *
     *
     */----------------------------------------------------------------
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
    /* Audit inserts */
   if not exists (select * from inserted i, bHRCO e
    	where i.HRCo = e.HRCo and e.AuditPositionsYN = 'Y')
    	return
   
   insert into bHQMA select 'bHRAP', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(10),isnull(i.HRRef,'')) +
       ' PositionCode : ' + convert(varchar(10),isnull(i.PositionCode,'')) + ' PartTimeYN: ' + convert(varchar(10),isnull(i.PartTimeYN,'')),
    	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
    	from inserted i,  bHRCO e
       where e.HRCo = i.HRCo and e.AuditPositionsYN = 'Y'
   
   return
   
    error:
    	select @errmsg = @errmsg + ' - cannot insert into HRAP!'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btHRAPu    Script Date: 8/28/99 9:37:38 AM ******/
    CREATE   trigger [dbo].[btHRAPu] on [dbo].[bHRAP] for UPDATE as
    

/*-----------------------------------------------------------------
     *  Created by: ae 04/04/00
     * 	Modified by: mh 3/15/04 23061
     *					mh 4/29/2005 - 28581
	 *					mh 04/28/08 - 127008
     */----------------------------------------------------------------
    
    declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    insert into bHQMA select 'bHRAP', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','PartTimeYN',
        convert(varchar(1),d.PartTimeYN), Convert(varchar(1),i.PartTimeYN),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d, bHRCO e
    	where i.HRCo = d.HRCo and i.HRRef = d.HRRef and
              i.PositionCode = d.PositionCode
              and i.PartTimeYN <> d.PartTimeYN
        and i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'
    
    insert into bHQMA select 'bHRAP', 'HRCo: ' + convert(char(3),isnull(i.HRCo,'')) + ' HRRef: ' + convert(varchar(6),isnull(i.HRRef,'')) +
        ' PositionCode: ' + convert(varchar(10),isnull(i.PositionCode,'')),
        i.HRCo, 'C','Part_time_Hours',
        convert(varchar(10),d.Part_time_Hours), Convert(varchar(10),i.Part_time_Hours),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d, bHRCO e
    	where i.HRCo = d.HRCo and i.HRRef = d.HRRef and
              i.PositionCode = d.PositionCode
              and i.Part_time_Hours <> d.Part_time_Hours
        and i.HRCo = e.HRCo and e.AuditPositionsYN  = 'Y'
    
    return
    
    error:
    	select @errmsg = @errmsg + ' - cannot update HRAP!'
    	RAISERROR(@errmsg, 11, -1);
    
    	rollback transaction
    
    
    
    
   
   
  
 



GO
