CREATE TABLE [dbo].[vDDFLc]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [smallint] NOT NULL,
[Lookup] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[LookupParams] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL,
[LoadSeq] [tinyint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




create trigger [dbo].[vtDDFLci] on [dbo].[vDDFLc] for INSERT
/*****************************
* Created: GG 08/02/07
* Modified: 
*
* Insert trigger on vDDFLc (DD Custom Form Lookups)
*
* Rejects insert if the following conditions exist:
*	Invalid Form/Seq 
*	Invalid Lookup
*
* Adds DD Audit entry
*
*************************************/

as


declare @errmsg varchar(255), @numrows int, @validcnt int
  
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

-- validate Form/Seq
select @validcnt = count(*)
from inserted i
join dbo.DDFIShared f with (nolock) on i.Form = f.Form and i.Seq = f.Seq
if @validcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Form and Seq# - must exist in DDFIShared'
  	goto error
  	end
-- validate Lookup
select @validcnt = count(*)
from inserted i
join dbo.DDLHShared h with (nolock) on i.Lookup = h.Lookup
if @validcnt <> @numrows
	begin
  	select @errmsg = 'Invalid Lookup - must exist in DDLHShared'
  	goto error
  	end

--needs validation to make sure entry does not duplicate vDDFL or active datatype lookup 
  
-- DD Audit  
insert vDDDA (TableName, Action, KeyString, FieldName, OldValue, 
  	NewValue, RevDate, UserName, HostName)
select 'vDDFLc', 'I', 'Form: ' + rtrim(Form) + ' Seq: ' + convert(varchar,Seq) + ' Lookup: ' + Lookup,
	null, null,	null, getdate(), SUSER_SNAME(), host_name()
from inserted 
  	 	 	 
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert Custom Form Lookup!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
    




GO
CREATE UNIQUE CLUSTERED INDEX [viDDFLc] ON [dbo].[vDDFLc] ([Form], [Seq], [Lookup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDFLc].[Active]'
GO
