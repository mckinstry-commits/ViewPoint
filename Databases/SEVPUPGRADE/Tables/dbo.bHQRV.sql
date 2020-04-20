CREATE TABLE [dbo].[bHQRV]
(
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[RevEmail] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE       trigger [dbo].[btHQRVd] on [dbo].[bHQRV] for DELETE as
   
   

/***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @errno tinyint, @validcnt int
   
   /*--------------------------------------------------------------
    *
    *  Delete trigger for HQRV
    *  Created By:     RM 06/14/04
    *  Modified By:
    *
    *
    *
    *--------------------------------------------------------------*/
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   
   if exists(select top 1 1 from bHQRP h join deleted d on h.Reviewer=d.Reviewer)
   begin
   	select @errmsg = 'Reviewer Logins exist for this Reviewer'
   	goto error
   end
   
   
   return
   
   error:
      select @errmsg = @errmsg + ' - cannot delete Reviewer'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQRV] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQRV] ON [dbo].[bHQRV] ([Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
