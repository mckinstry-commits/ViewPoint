CREATE TABLE [dbo].[bPMVG]
(
[ViewName] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[ViewGrid] [smallint] NULL,
[GridTitle] [dbo].[bDesc] NULL,
[Hide] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMVG_Hide] DEFAULT ('Y'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMVGi    Script Date: 03/31/2004 ******/
CREATE trigger [dbo].[btPMVGi] on [dbo].[bPMVG] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMVG
 *  Created By:		GF 03/31/2004
 *  Modified Date:  AW 01/11/2013 TK-20642 / 147448 PMVC needs to exist prior to PMVG so moving init to bspPMVGInitialize
 *						Leaving trigger as a placeholder as it no longer does anything
 *					AW 6/18/13 Reverting back for PMVG insert
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int,
   		@viewname varchar(10), @form varchar(30)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- declare local cursor on inserted rows
if @numrows = 1
	begin
   	select @viewname=ViewName, @form=Form
	from inserted
	end
else
	begin
   	---- use a cursor to process each inserted row
   	declare bPMVM_insert cursor LOCAL FAST_FORWARD
   	for select ViewName, Form
   	from inserted
   
   	open bPMVM_insert

	fetch next from bPMVM_insert into @viewname, @form
	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end




insert_check:
---- execute SP to load grid views and grid columns for new view
exec @rcode = dbo.bspPMVCInitialize @viewname, @form, @errmsg output
if @rcode <> 0 goto error




if @numrows > 1
   	begin
   	fetch next from bPMVM_insert into @viewname, @form
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
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMVG'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMVGu    Script Date: 03/31/2004 ******/
CREATE  trigger [dbo].[btPMVGu] on [dbo].[bPMVG] for UPDATE as
/*--------------------------------------------------------------
 *  Update trigger for PMVG
 *  Created By:		GF 03/31/2004
 *	Modified By:	JayR 03/28/2012 Remove gotos
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check for changes to ViewName
if update(ViewName)
	begin
	RAISERROR('Cannot change View Name - cannot update PMVG', 11, -1)
	rollback TRANSACTION
	RETURN
	end

if update(ViewGrid)
	begin
	RAISERROR('Cannot change Grid View - cannot update PMVG', 11, -1)
	rollback TRANSACTION
	RETURN
	end


return

   
  
 



GO
ALTER TABLE [dbo].[bPMVG] WITH NOCHECK ADD CONSTRAINT [CK_bPMVG_Hide] CHECK (([Hide]='Y' OR [Hide]='N'))
GO
ALTER TABLE [dbo].[bPMVG] ADD CONSTRAINT [PK_bPMVG] PRIMARY KEY CLUSTERED  ([ViewName], [Form]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMVG] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
