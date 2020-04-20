CREATE TABLE [dbo].[vDDCIc]
(
[ComboType] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[DatabaseValue] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[DisplayValue] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  trigger [dbo].[vtDDCIcd] on [dbo].[vDDCIc] for DELETE
/************************************
* Created: 01/27/06
* Modified: 
*
* Delete trigger on vDDCIc (DD Custom ComboType Items)
*
* Rejects deletion if any of the following conditions exist:
*	none
*
* Adds HQ Audit entry
*
************************************/
as



declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on

/* HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vDDCIc',  'Combo Type: ' + rtrim(ComboType) + ' Seq: ' + convert(varchar,Seq), null, 'D',
   	 null, null, null, getdate(), SUSER_SNAME()
from deleted   
  
return

-- error not used 
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Custom ComboType Item!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
  
  
  
  
 








GO
CREATE UNIQUE CLUSTERED INDEX [viDDCIc] ON [dbo].[vDDCIc] ([ComboType], [Seq]) ON [PRIMARY]
GO
