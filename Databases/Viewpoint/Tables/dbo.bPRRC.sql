CREATE TABLE [dbo].[bPRRC]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Race] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[EEOCat] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biPRRC] ON [dbo].[bPRRC] ([PRCo], [Race]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRRC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
/****** Object:  Trigger [dbo].[btPRRCd]    Script Date: 10/09/2007 14:15:00 ******/
    CREATE     trigger [dbo].[btPRRCd] on [dbo].[bPRRC] for DELETE as
     
/*-----------------------------------------------------------------
      *	Created by: EN 10/09/07
      *	Modified:	
      *
      */----------------------------------------------------------------
     declare @errmsg varchar(255), @numrows int
   
     select @numrows = @@rowcount
   
     if @numrows = 0 return
   
     if exists(select * from dbo.bPREH h with (nolock) join deleted d on h.PRCo=d.PRCo and h.Race=d.Race)
     	begin
     	select @errmsg='Code is in use in Employee Header'
     	goto error
     	end
   
     return
     error:
     	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PR Race(s)!'
         	RAISERROR(@errmsg, 11, -1);
         	rollback transaction
   
   
   
   
  
 



GO
