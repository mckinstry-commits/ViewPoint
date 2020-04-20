CREATE TABLE [dbo].[bHQCG]
(
[CompGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHQCG] ON [dbo].[bHQCG] ([CompGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQCG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQCGd    Script Date: 8/28/99 9:37:32 AM ******/
   CREATE  trigger [dbo].[btHQCGd] on [dbo].[bHQCG] for DELETE as
   

/*----------------------------------------------------------
    *	This trigger rejects delete in bHQCG (HQ Compliance Groups)
    *	if a dependent record is found in:
    *
    *		HQCX - Compliance Group Codes
    *
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check HQ Compliance Group Codes */
   if exists(select * from bHQCX g, deleted d where 
   	g.CompGroup = d.CompGroup)
   	begin
   	select @errmsg = 'Compliance codes assigned to this Compliance Group'
   	goto error
   	end
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete HQ Compliance Group!'
   	RAISERROR(@errmsg, 11, -1);
   
   	rollback transaction
   
   
  
 



GO
