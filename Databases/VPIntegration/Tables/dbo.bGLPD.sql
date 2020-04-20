CREATE TABLE [dbo].[bGLPD]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[PartNo] [tinyint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE  trigger [dbo].[btGLPDi] on [dbo].[bGLPD] for INSERT as
/*-----------------------------------------------------------------
* Created: ?
* Modified: GG 5/2/07 - V6.0 mods for DD changes
*			AR 2/11/2011 - using FKs to replace trigger code
*
*
*	Insert trigger for bGLPD (GL Account Part Descriptions)  
*
*
*/----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @mask varchar(30),
   	@inputtype tinyint, @maxpart tinyint, @i tinyint, @char varchar(1)
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
/* validate GL Company */
-- 143291 - replacing with FK
   
/* get mask for GL Account datatype */
select @inputtype = InputType, @mask = InputMask 
from dbo.DDDTShared (nolock)
where Datatype = 'bGLAcct'
if @@rowcount = 0
	begin
	select @errmsg = 'Missing datatype (bGLAcct) in DD Datatypes'
	goto error
	end
if @inputtype <> 5	/* hardcoded InputType */
	begin
	select @errmsg = 'GL Account must be defined as (multi-part)'
	goto error
	end
   
/* count number of parts in GL Account */
select @i = 1, @maxpart = 0
while @i < datalength(@mask)
	begin
	select @char = substring(@mask,@i,1)
	select @i = @i + 1
	if @char not like '[0-9]'
		begin
		select @maxpart = @maxpart + 1
		select @i = @i + 1	/* skip the 'separator' character */
		end
	end
   
/* validate PartNo */
if exists(select * from inserted where PartNo < 1 or PartNo > @maxpart)
	begin
	select @errmsg = 'Invalid Part number'
	goto error
	end

return
   	
error:
   	select @errmsg = @errmsg + ' - cannot insert GL Account Part!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btGLPDu    Script Date: 8/28/99 9:37:31 AM ******/
   CREATE  trigger [dbo].[btGLPDu] on [dbo].[bGLPD] for UPDATE as
   

/*-----------------------------------------------------------------
    *	This trigger rejects update in bGLPD (GL Account Part Descriptions)
    *	if any of the following error conditions exist:
    *
    *		Cannot change GL Company
    *		Cannot change PartNo
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   /* check for key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.GLCo = i.GLCo and d.PartNo = i.PartNo
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change GL Company or Part#'
   	goto error
   	end
   
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update GL Account Part!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
  
 



GO
ALTER TABLE [dbo].[bGLPD] ADD CONSTRAINT [PK_bGLPD] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biGLPD] ON [dbo].[bGLPD] ([GLCo], [PartNo]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLPD] WITH NOCHECK ADD CONSTRAINT [FK_bGLPD_bGLCO_GLCo] FOREIGN KEY ([GLCo]) REFERENCES [dbo].[bGLCO] ([GLCo])
GO
