CREATE TABLE [dbo].[bUDVH]
(
[ValProc] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[ProcView] [varchar] (7000) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biUDVH] ON [dbo].[bUDVH] ([ValProc]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bUDVH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*
*	Created by: Who knows.
*   Modified by: Jonathan Paullin 09/10/07 - Delete the associated validation procedure if it exists.
*				 RM 09/08/08 - execute as viewpoint for drop permissions
*				 
*/   
   
CREATE TRIGGER [dbo].[btUDVHd] ON [dbo].[bUDVH]
with execute as 'viewpointcs'	-- required for dynamic query
FOR DELETE 
AS
     
declare @procname varchar(30), @procstring varchar(60), @dynamicSQL nvarchar(255)
   
   
   
	-- On delete, delete all Tables associated with this record   
	delete bUDVT
	from bUDVT t join deleted d
	on t.ValProc = d.ValProc
   
	-- Check if the stored procedure exists.
	select @procname = name from deleted d join sys.objects o on d.ValProc = o.name

	-- If the procedure does exist, remove it.
	if @@ROWCOUNT = 1
	begin
		-- Remove stored procedure
		select @dynamicSQL = 'drop procedure ' + @procname
		exec sp_executesql @dynamicSQL
	end

	
   	
	
 



GO
