CREATE TABLE [dbo].[bJCRT]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[RateTemplate] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[EffectiveDate] [dbo].[bDate] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btJCRTi] on [dbo].[bJCRT] for INSERT as
-------------------------------------------------------------------
-- Created: GG 11/16/06
-- Modified:
--
-- Insert trigger on JC Fixed Rate Template Header (bJCRT)
-- Rejects insertion if any of the following conditions exist:
--		Invalid JC Co#
--
-- Add HQMA audit entry based on JC Co Audit Dept flag
--
------------------------------------------------------------------
declare @errmsg varchar(255), @errno int, @numrows int,	@validcnt int 
  
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- validate Company 
select @validcnt = count(*)
from inserted i
join dbo.bJCCO j (nolock) on j.JCCo = i.JCCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Company.'
	goto error
	end

-- audit inserts 
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCRT','JC Co#: ' + convert(varchar, i.JCCo) + ' Rate Template: ' + convert(varchar,i.RateTemplate),
	i.JCCo, 'A', NULL, NULL, NULL, getdate(), suser_name()
from inserted i
join dbo.bJCCO j (nolock) on j.JCCo = i.JCCo
where j.AuditDepts = 'Y'

return

error:
	select @errmsg = @errmsg + ' - cannot insert JC Fixed Rate Template!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btJCRTu] ON [dbo].[bJCRT] FOR UPDATE AS
--------------------------------------------------------
-- Created: GG 11/16/06
-- Modified: 
--
-- Update trigger on JC Fixed Rate Template Header (bJCRT)
--
-- Rejects update if the following conditions exist:
--	Change primary key
--
--
-- Add HQMA audit entry for updated values based on JC Co Audit Dept flag
--
----------------------------------------------------------
 
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int
  
select @numrows = @@rowcount 
if @numrows = 0 return

set nocount on 

-- check for update to primary key
if update(JCCo) or update(RateTemplate)
	begin
	select @validcnt = count(*)
	from inserted i
	join deleted d on i.JCCo = d.JCCo and i.RateTemplate = d.RateTemplate
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Cannot change JC Co# or Rate Template'
		goto error
		end
	end
 
-- Audit updates 
if update(Description)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCRT', 'JC Co#: ' + convert(varchar,i.JCCo) + ' Rate Template: ' + convert(varchar,i.RateTemplate),
		i.JCCo, 'C', 'Description', d.Description, i.Description, getdate(), suser_name()
 	from inserted i
	join deleted d on i.JCCo = d.JCCo and i.RateTemplate = d.RateTemplate
	join dbo.bJCCO j (nolock) on i.JCCo = j.JCCo
 	where isnull(i.Description,'') <> isnull(d.Description,'') and j.AuditDepts = 'Y'
if update(EffectiveDate)
	insert dbo.bHQMA(TableName,KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCRT', 'JC Co#: ' + convert(varchar,i.JCCo) + ' Rate Template: ' + convert(varchar,i.RateTemplate),
		i.JCCo, 'C', 'EffectiveDate', convert(varchar,d.EffectiveDate,101), convert(varchar,i.EffectiveDate,101),
		getdate(), suser_name()
 	from inserted i
	join deleted d on i.JCCo = d.JCCo and i.RateTemplate = d.RateTemplate
	join dbo.bJCCO j (nolock) on i.JCCo = j.JCCo
 	where i.EffectiveDate <> d.EffectiveDate and j.AuditDepts = 'Y'

return
 
 
error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot update JC Fixed Rate Template'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biJCRT] ON [dbo].[bJCRT] ([JCCo], [RateTemplate]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCRT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
