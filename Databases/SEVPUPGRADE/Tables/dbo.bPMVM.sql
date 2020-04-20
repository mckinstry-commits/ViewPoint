CREATE TABLE [dbo].[bPMVM]
(
[ViewName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMVMd    Script Date: 03/31/2004 ******/
CREATE   trigger [dbo].[btPMVMd] on [dbo].[bPMVM] for DELETE as
/*********************************************************************/
/*--------------------------------------------------------------
 *  Delete trigger for PMVM
 *  Created By:		GF 03/31/2004
 *  Modified Date:
 *
 *
 *--------------------------------------------------------------*/
declare @validcnt int

if @@rowcount = 0 return
set nocount on

---- delete all entries from bPMVC for the view(s)
delete bPMVC  
from bPMVC c join deleted d on d.ViewName=c.ViewName where d.ViewName <> 'Viewpoint'
---- check to make sure grid columns have been deleted for view(s)
select @validcnt = count(*) from deleted d join bPMVC g on g.ViewName=d.ViewName where d.ViewName <> 'Viewpoint'
if @validcnt <> 0
   	begin
   		RAISERROR('Grid columns exist for the Document Tracking View. Delete columns first. - cannot delete from PMVM', 11, -1)
   		rollback TRANSACTION
   		RETURN
   	end


---- delete all entries from bPMVC for the view(s)
delete bPMVG 
from bPMVG g join deleted d on d.ViewName=g.ViewName where d.ViewName <> 'Viewpoint'
---- check to make sure tabs have been deleted for view(s)
select @validcnt = count(*) from deleted d join bPMVG g on g.ViewName=d.ViewName where d.ViewName <> 'Viewpoint'
if @validcnt <> 0
   	begin
   		RAISERROR('Grid Forms exist for the Document Tracking View. - cannot delete from PMVM', 11, -1)
  		rollback TRANSACTION
  		RETURN
   	end


RETURN 
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMVMi    Script Date: 03/31/2004 ******/
CREATE   trigger [dbo].[btPMVMi] on [dbo].[bPMVM] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMVM
 *  Created By:		GF 03/31/2004
 *  Modified Date:
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @rcode int,
   		@viewname varchar(10)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- declare local cursor on inserted rows
if @numrows = 1
	begin
   	select @viewname=ViewName
   	from inserted
	end
else
   	begin
   	---- use a cursor to process each inserted row
   	declare bPMVM_insert cursor LOCAL FAST_FORWARD
   	for select ViewName
   	from inserted
   
   	open bPMVM_insert
   
   	fetch next from bPMVM_insert into @viewname
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end



insert_check:
---- do not allow ViewName = 'Viewpoint' reserved
if @viewname = 'Viewpoint'
   	begin
   	select @errmsg = 'The View Name (Viewpoint) is reserved. May not be used.'
   	goto error
   	end

---- execute SP to load grid views and grid columns for new view
exec @rcode = dbo.bspPMVGInitialize @viewname, @errmsg output
if @rcode <> 0 goto error



if @numrows > 1
   	begin
   	fetch next from bPMVM_insert into @viewname
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMVM_insert
   		deallocate bPMVM_insert
   		end
   	end



return



error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMVM'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   /****** Object:  Trigger dbo.btPMVMu    Script Date: 03/31/2004 ******/
   CREATE trigger [dbo].[btPMVMu] on [dbo].[bPMVM] for UPDATE as
   

/*********************************************************************/
   /*--------------------------------------------------------------
    *  Update trigger for PMVM
    *  Created By:		GF 03/31/2004
    *	Modified By:	JayR 03/28/2012 TK-00000 Remove unused variables and goto
    *
    *
    *--------------------------------------------------------------*/

   if @@rowcount = 0 return
   set nocount on
  
   
   -- check for changes to ViewName
   if update(ViewName)
      begin
      RAISERROR('Cannot change View Name', 11, -1)
      ROLLBACK TRANSACTION
      RETURN
      end
   
   
   
   RETURN 
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMVM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMVM] ON [dbo].[bPMVM] ([ViewName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
