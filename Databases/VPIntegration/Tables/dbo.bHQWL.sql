CREATE TABLE [dbo].[bHQWL]
(
[Location] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[Path] [varchar] (132) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[LocType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHQWL_LocType] DEFAULT ('UNC'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWLd] on [dbo].[bHQWL] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for HQWL
 * Created By:	GF 11/20/2001
 * Modified By:
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @errno tinyint, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check HQWD for document template that use this location
if exists(select * from deleted d join bHQWD o ON d.Location = o.Location)
	begin
	select @errmsg = 'Document Templates exist that use this Location'
	goto error
	end


return


error:
	select @errmsg = @errmsg + ' - cannot delete Location from HQWL'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWLi] on [dbo].[bHQWL] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for HQWL
 * Created By:	GF 02/14/2007
 * Modified By:	
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate Location is not 'PMStandard' or 'PMCustom' these are reserved for the 6.x repository
select @validcnt = count(*) from inserted i where i.Location in ('PMStandard', 'PMCustom')
if @validcnt <> 0
	begin
	select @errmsg = 'Invalid Location, (PMStandard) and (PMCustom) are reserved for the repository.'
	goto error
   	end


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert location into HQWL'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btHQWLu] on [dbo].[bHQWL] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for HQWL
 * Created By:	GF 11/20/2001
 * Modified By:
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- check HQWD for word document templates
if update(Location)
	begin
   	if exists(select * from deleted d join bHQWD o ON d.Location = o.Location)
   		begin
   		select @errmsg = 'Document Templates exist that use this Location'
   		goto error
   		end
	end



return



error:
	select @errmsg = @errmsg + ' - cannot update Document Location in HQWL'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
	   
   
   
   
  
 





GO
ALTER TABLE [dbo].[bHQWL] ADD CONSTRAINT [PK_bHQWL] PRIMARY KEY CLUSTERED  ([Location]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQWL] ([KeyID]) ON [PRIMARY]
GO
