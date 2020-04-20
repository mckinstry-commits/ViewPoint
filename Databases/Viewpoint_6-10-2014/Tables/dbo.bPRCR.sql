CREATE TABLE [dbo].[bPRCR]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Crew] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase1] [dbo].[bPhase] NULL,
[Phase2] [dbo].[bPhase] NULL,
[Phase3] [dbo].[bPhase] NULL,
[Phase4] [dbo].[bPhase] NULL,
[Phase5] [dbo].[bPhase] NULL,
[Phase6] [dbo].[bPhase] NULL,
[Phase7] [dbo].[bPhase] NULL,
[Phase8] [dbo].[bPhase] NULL,
[RegECOvride] [dbo].[bEDLCode] NULL,
[OTECOvride] [dbo].[bEDLCode] NULL,
[DblECOvride] [dbo].[bEDLCode] NULL,
[PRGroup] [dbo].[bGroup] NULL,
[Shift] [tinyint] NULL,
[ApprovalReq] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRCR_ApprovalReq] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCRd    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCRd] on [dbo].[bPRCR] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/28/03
    *	Modified:	EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * Deletes Crew Code only if no crew details (bPRCW) exist.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check for Crew Details
   if exists(select * from dbo.bPRCW w with (nolock) join deleted d on w.PRCo = d.PRCo and w.Crew = d.Crew)
    	begin
   	select @errmsg = 'Crew Details exist'
   	goto error
   	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Crew Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btPRCRi    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE   trigger [dbo].[btPRCRi] on [dbo].[bPRCR] for INSERT as
   

/*-----------------------------------------------------------------
    *   	Created by: EN 4/28/03
    *		Modified: EN 02/11/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    *  Validates PR Company.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate PR Company */
   select @validcnt = count(*) from dbo.bHQCO c with (nolock) join inserted i on c.HQCo = i.PRCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Company# '
   	goto error
   	end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Crew Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPRCRu    Script Date: 8/28/99 9:38:10 AM ******/
   CREATE    trigger [dbo].[btPRCRu] on [dbo].[bPRCR] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: EN 4/28/03
    *	Modified:	EN 02/11/03 - issue 23061  added isnull check
    *
    * Cannot change primary key.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(PRCo)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change PR Company '
        	goto error
        	end
       end
   if update(Crew)
       begin
       select @validcnt = count(*) from deleted d
            join inserted i on d.PRCo = i.PRCo and d.Crew = i.Crew
        if @validcnt <> @numrows
        	begin
        	select @errmsg = 'Cannot change Crew '
        	goto error
        	end
       end
   
   
   return
   error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PR Crew Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bPRCR] WITH NOCHECK ADD CONSTRAINT [CK_bPRCR_ApprovalReq] CHECK (([ApprovalReq]='Y' OR [ApprovalReq]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRCR] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRCR] ON [dbo].[bPRCR] ([PRCo], [Crew]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
