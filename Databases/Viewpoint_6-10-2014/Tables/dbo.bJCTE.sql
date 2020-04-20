CREATE TABLE [dbo].[bJCTE]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[LiabTemplate] [smallint] NOT NULL,
[LiabType] [dbo].[bLiabilityType] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btJCTEd    Script Date: 8/28/99 9:37:49 AM ******/
CREATE  trigger [dbo].[btJCTEd] on [dbo].[bJCTE] for DELETE 
/*-----------------------------------------------------------------
* Created by:	GF 03/15/2010 = issue #136066
* Modified BY:
*
* delete trigger for bJCTE (JC Liability Template Earning Codes)
*
*
*
****************************************************/
as
   
declare @numrows int, @errmsg varchar(255)
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCTE',  'Liab Template: ' + convert(char(3),deleted.LiabTemplate) + ' Liab Type: ' + 	convert(char(3),deleted.LiabType) + ' Earning Code: ' +convert(varchar(10),deleted.EarnCode),
   		deleted.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted inner join dbo.bJCCO with (nolock) on bJCCO.JCCo=deleted.JCCo
where deleted.JCCo=bJCCO.JCCo and bJCCO.AuditLiabilityTemplate='Y'


return


error:
	select @errmsg = @errmsg + ' - cannot delete Liability Template Earning Code!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btJCTEi    Script Date: 8/28/99 9:37:49 AM ******/
CREATE   trigger [dbo].[btJCTEi] on [dbo].[bJCTE] for INSERT 
/*-----------------------------------------------------------------
* Created by:	GF 03/15/2010 = issue #136066
* Modified BY:
*
* INsert trigger for bJCTE (JC Liability Template Earning Codes)
*
*
*
****************************************************/
as
   
declare @numrows int, @errmsg varchar(255)
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Audit inserts
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCTE',  'Liab Template: ' + convert(char(3),inserted.LiabTemplate) + ' Liab Type: ' + 	convert(char(3),inserted.LiabType) + ' Earning Code: ' +convert(varchar(10),inserted.EarnCode),
   		inserted.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted inner join dbo.bJCCO with (nolock) on bJCCO.JCCo=inserted.JCCo
where inserted.JCCo=bJCCO.JCCo and bJCCO.AuditLiabilityTemplate='Y'


return


error:
	select @errmsg = @errmsg + ' - cannot insert Liability Template Earning Code!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCTEi    Script Date: 8/28/99 9:37:49 AM ******/
CREATE trigger [dbo].[btJCTEu] on [dbo].[bJCTE] for UPDATE 
/*-----------------------------------------------------------------
* Created by:	GF 03/15/2010 - issue #136066
* Modified by:
*
*
* update trigger for bJCTE (JC Liability Template Earning Codes)
*
* HQMA audit
****************************************************/
as
   
declare @errmsg varchar(255), @validcnt int
declare  @errno int, @numrows int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- Insert records into HQMA for changes made to audited fields 
if update(EarnCode)
	begin
    insert into bHQMA select 'bJCTE',  'JCCo: ' + convert(varchar(3),i.JCCo) + ' Liab Template: ' + convert(char(3),i.LiabTemplate) + ' Liab Type: ' + 	convert(char(3),i.LiabType),
			i.JCCo, 'C', 'Earning Code', Convert(varchar(10),d.EarnCode), Convert(varchar(10),i.EarnCode), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.JCCo = d.JCCo
	join bJCCO c on i.JCCo = c.JCCo
	where c.AuditLiabilityTemplate='Y' and isnull(i.EarnCode,-1) <> isnull(d.EarnCode,-1)
	end


return



error:
	select @errmsg = @errmsg + ' - cannot insert Liability Template Earning Codes!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
  
 







GO
CREATE UNIQUE CLUSTERED INDEX [biJCTE] ON [dbo].[bJCTE] ([JCCo], [LiabTemplate], [LiabType], [EarnCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCTE] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
