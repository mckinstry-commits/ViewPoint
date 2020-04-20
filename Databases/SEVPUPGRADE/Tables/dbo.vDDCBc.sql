CREATE TABLE [dbo].[vDDCBc]
(
[ComboType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[vtDDCBcd] on [dbo].[vDDCBc] for DELETE
/************************************
* Created: GG 01/27/06
* Modified: 
*
* Delete trigger on vDDCBc (DD Custom ComboTypes)
*
* Rejects deletion if any of the following conditions exist:
*	ComboItems (DDCIShared) Exist
*	Exists in a DDFIShared entry
*
* Adds HQ Audit entry
*
************************************/
as



declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on

-- check ComboTypes
if exists(select top 1 1 from deleted d join dbo.DDCIShared i (nolock) on d.ComboType = i.ComboType)
	begin
  	select @errmsg = 'ComboType Items exist'
  	goto error
  	end
  
-- check Form Inputs 
if exists (select top 1 1 from deleted d join dbo.DDFIShared i (nolock) on d.ComboType = i.ComboType)
  	begin
  	select @errmsg = 'In use on Form Inputs'
  	goto error
  	end
  	
/* HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDCBc',  'Combo Type: ' + ComboType, null, 'D',
   	 null, null, null, getdate(), SUSER_SNAME()
from deleted  
   

return
  
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Custom ComboType!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 








GO
CREATE UNIQUE CLUSTERED INDEX [viDDCBc] ON [dbo].[vDDCBc] ([ComboType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
