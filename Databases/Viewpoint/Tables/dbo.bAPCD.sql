CREATE TABLE [dbo].[bAPCD]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[Remaining] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biAPCD] ON [dbo].[bAPCD] ([Co], [Mth], [BatchId], [BatchSeq], [GLCo], [GLAcct]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btAPCDi    Script Date: 8/28/99 9:36:52 AM ******/
   CREATE  trigger [dbo].[btAPCDi] on [dbo].[bAPCD] for INSERT as
   

/*-----------------------------------------------------------------
    *	Created : 8/24/98 EN
    *	Modified : 8/24/98 EN
    *			 10/17/02 - 18878 quoted identifier project.
    *
    *	This trigger rejects insertion in bAPCD (clear distributions)
    *	if a header in APCT does not exist.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
    
   /* check APCT for header */
   select @validcnt = count(*) from bAPCT c, inserted i 
   	where c.Co=i.Co and c.Mth=i.Mth and c.BatchId=i.BatchId and c.BatchSeq=i.BatchSeq
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Clear Transactions entry is missing'
   	goto error
   	end
   
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert Clear Distributions entry!'
       	RAISERROR(@errmsg, 11, -1);
   
       	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btAPCDu    Script Date: 8/28/99 9:36:52 AM ******/
   CREATE  trigger [dbo].[btAPCDu] on [dbo].[bAPCD] for UPDATE as
   

/*-----------------------------------------------------------------
    *	Created : 8/24/98 EN
    *	Modified : 8/24/98 EN
    *			 10/17/02 - MV 18878 quoted identifier project.
    *
    *	This trigger rejects update in bAPCD (Clear Distributions)
    *	if any of the following error conditions exist:
    *
    *		Cannot change Co
    *		Cannot change Mth
    *		Cannot change BatchId
    *		Cannot change BatchSeq
    *		Cannot change GLCo
    *		Cannot change GLAcct
    *		
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return 
   
   set nocount on
   
   /* verify primary key not changed */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.Co = i.Co and d.Mth = i.Mth and d.BatchId = i.BatchId and
   	d.BatchSeq = i.BatchSeq and d.GLCo = i.GLCo and d.GLAcct = i.GLAcct
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Primary Key'
   	goto error
   	end
   	
   	
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update Clear Distributions!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
  
 



GO
