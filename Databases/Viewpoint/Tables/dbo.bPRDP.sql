CREATE TABLE [dbo].[bPRDP]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRDept] [dbo].[bDept] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[JCFixedRateGLAcct] [dbo].[bGLAcct] NULL,
[EMFixedRateGLAcct] [dbo].[bGLAcct] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRDP] ON [dbo].[bPRDP] ([PRCo], [PRDept]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRDP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
/****** Object:  Trigger [dbo].[btPRDPd]    Script Date: 10/01/2007 14:29:04 ******/
    CREATE     trigger [dbo].[btPRDPd] on [dbo].[bPRDP] for DELETE as
     

/*-----------------------------------------------------------------
      *	Created by: EN 10/01/07
      *	Modified:	
      *
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
   
     if exists(select * from dbo.bPRTH h with (nolock) join deleted d on h.PRCo=d.PRCo and h.PRDept=d.PRDept)
     	begin
     	select @errmsg='Code is in use in Timecard Header'
     	goto error
     	end
   
     return
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Department(s)!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction
   
   
   
   
  
 



GO
