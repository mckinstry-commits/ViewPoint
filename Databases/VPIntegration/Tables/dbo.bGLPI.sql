CREATE TABLE [dbo].[bGLPI]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[PartNo] [tinyint] NOT NULL,
[Instance] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
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
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLPIu    Script Date: 8/28/99 9:37:31 AM ******/
   CREATE  trigger [dbo].[btGLPIu] on [dbo].[bGLPI] for UPDATE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects update in bGLPI (Part Instances)
    *	if any of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change PartNo
    *		Cannot change Instance
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.PartNo = i.PartNo and d.Instance = i.Instance
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company, Part#, or Instance'
   	goto error
   	end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update GL Account Part Instances!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLPI] ADD CONSTRAINT [PK_bGLPI] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLPI] ON [dbo].[bGLPI] ([GLCo], [PartNo], [Instance]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLPI] WITH NOCHECK ADD CONSTRAINT [FK_bGLPI_bGLPD_GLCoPartNo] FOREIGN KEY ([GLCo], [PartNo]) REFERENCES [dbo].[bGLPD] ([GLCo], [PartNo])
GO
