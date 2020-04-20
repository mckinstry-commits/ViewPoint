CREATE TABLE [dbo].[vDDSLc]
(
[TableName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Datatype] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[InstanceColumn] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[QualifierColumn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[InUse] [dbo].[bYN] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   trigger [dbo].[vtDDSLcd] on [dbo].[vDDSLc] for DELETE
/************************************
* Created: AL 2/24/08
*  
*
* Delete trigger on vDDSLc 
*
* 
*
*
************************************/
as


declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on


-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSLc', 'D', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME() from deleted
return
  
  


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   trigger [dbo].[vtDDSLci] on [dbo].[vDDSLc] for INSERT
/************************************
* Created: AL 2/24/08
*  
*
* Delete trigger on vDDSLc 
*
* 
*
*
************************************/
as

declare @errmsg varchar(255)
  
if @@rowcount = 0 return
set nocount on


-- HQMA Audit	 	 	 
insert bHQMA (TableName, RecType, KeyString, FieldName, OldValue, 
  	NewValue, DateTime, UserName)
select 'vDDSLc', 'I', 'Datatype: ' + rtrim(Datatype), null, null,
	null, getdate(), SUSER_SNAME() from inserted
return
  
  

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[vtDDSLcu] on [dbo].[vDDSLc] for UPDATE
/************************************
* Created: AL 03/02/08
* 
*
* Update trigger on vDDSLc 
*
* 
*
************************************/

as

declare @numrows int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
  

--HQMA Audit
if update(InUse)
	insert dbo.bHQMA(TableName, RecType, KeyString, FieldName,
		OldValue, NewValue, DateTime, UserName)
	select  'vDDSLc', 'U', 'Datatype: ' + rtrim(i.Datatype), 'InUse',
		d.InUse, i.InUse, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.Datatype = d.Datatype 
  	where isnull(i.InUse,'') <> isnull(d.InUse,'')

return
  

GO
ALTER TABLE [dbo].[vDDSLc] WITH NOCHECK ADD CONSTRAINT [CK_vDDSLc_InUse] CHECK (([InUse]='Y' OR [InUse]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [viDDSLc] ON [dbo].[vDDSLc] ([TableName], [Datatype], [InstanceColumn]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
