CREATE TABLE [dbo].[bJCRD]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[RateTemplate] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[Craft] [dbo].[bCraft] NULL,
[Class] [dbo].[bClass] NULL,
[Shift] [int] NULL,
[EarnFactor] [dbo].[bRate] NULL,
[Employee] [dbo].[bEmployee] NULL,
[OldRate] [dbo].[bUnitCost] NOT NULL,
[NewRate] [dbo].[bUnitCost] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btJCRDi] on [dbo].[bJCRD] for INSERT as
-------------------------------------------------------------------
-- Created: GG 11/16/06
-- Modified:
--
-- Insert trigger on JC Fixed Rate Template Detail (bJCRD)
-- Rejects insertion if any of the following conditions exist:
--		Invalid JC Co#
--		Invalid Fixed Rate Template
--		Invalid PR Co#
--
-- Add HQMA audit entry based on JC Co Audit Dept flag
--
------------------------------------------------------------------
declare @errmsg varchar(255), @numrows int,	@validcnt int 
  
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
-- validate Rate Template
select @validcnt = count(*)
from inserted i
join dbo.bJCRT j (nolock) on j.JCCo = i.JCCo and j.RateTemplate = i.RateTemplate
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JC Rate Template.'
	goto error
	end
-- validate PR Company
select @validcnt = count(*)
from inserted i
join dbo.bPRCO p (nolock) on p.PRCo = i.PRCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid PR Company.'
	goto error
	end


-- audit inserts 
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCRD','JC Co#: ' + convert(varchar, i.JCCo) + ' Rate Template: ' + convert(varchar,i.RateTemplate) + ' Seq: ' + convert(varchar,i.Seq),
	i.JCCo, 'A', NULL, NULL, NULL, getdate(), suser_name()
from inserted i
join dbo.bJCCO j (nolock) on j.JCCo = i.JCCo
where j.AuditDepts = 'Y'

return

error:
	select @errmsg = @errmsg + ' - cannot insert JC Fixed Rate Detail!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [biJCRD] ON [dbo].[bJCRD] ([JCCo], [RateTemplate], [PRCo], [Craft], [Class], [Shift], [EarnFactor], [Employee]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biJCRDSeq] ON [dbo].[bJCRD] ([JCCo], [RateTemplate], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
