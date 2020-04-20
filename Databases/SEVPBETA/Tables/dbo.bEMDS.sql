CREATE TABLE [dbo].[bEMDS]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Month] [dbo].[bMonth] NOT NULL,
[AmtToTake] [dbo].[bDollar] NOT NULL,
[AmtTaken] [dbo].[bDollar] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDSd    Script Date: 8/28/99 9:37:18 AM ******/
   CREATE   trigger [dbo].[btEMDSd] on [dbo].[bEMDS] for Delete as
   

/*--------------------------------------------------------------
    *
    *  Delete trigger for EMDS
    *  Created By:  ae  03/03/00
    *  Modified by:  TV 02/11/04 - 23061 added isnulls
    *
    *
    *--------------------------------------------------------------*/
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
           @errno tinyint, @audit bYN, @latestcnt int, @priorcnt int, @nullcnt int
   
   /* Audit inserts */
   
   insert into bHQMA select 'bEMDS', 'EM Company: ' + convert(char(3),d.EMCo) + ' Equipment: ' + convert(varchar(10),d.Equipment) +
    	' Asset: ' + convert(varchar(20),d.Asset),
    	d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    	from deleted d,  EMCO e
       where e.EMCo = d.EMCo and e.AuditAsset = 'Y'
   
   
   return
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete EMDS'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btEMDSu  ******/
   CREATE   trigger [dbo].[btEMDSu] on [dbo].[bEMDS] for update as
   
    

/*--------------------------------------------------------------
     *
     *  Insert trigger for EMDS
     *  Created By:  ae 03/3/00
     *  Modified by:  TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
            @rcode int
   
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
    	where i.EMCo = e.EMCo and e.AuditAsset = 'Y')
    	return
   
   insert into bHQMA select 'bEMDS', 'EM Company: ' + convert(char(3),i.EMCo) + ' Equipment: ' + convert(varchar(10),i.Equipment) +
    	' Asset: ' + convert(varchar(20),i.Asset),
    	i.EMCo, 'C', 'AmtTaken', d.AmtTaken, i.AmtTaken, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Asset = d.Asset
       and e.EMCo = i.EMCo and e.AuditAsset = 'Y'
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot update EMDS'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMDS] ON [dbo].[bEMDS] ([EMCo], [Equipment], [Asset], [Month]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMDS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
