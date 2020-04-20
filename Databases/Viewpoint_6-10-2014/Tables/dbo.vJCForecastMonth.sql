CREATE TABLE [dbo].[vJCForecastMonth]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[Contract] [dbo].[bContract] NOT NULL,
[ForecastMonth] [dbo].[bMonth] NOT NULL,
[RevenuePct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vJCForecastMonth_RevenuePct] DEFAULT ((0)),
[CostPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vJCForecastMonth_CostPct] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************/
CREATE trigger [dbo].[vtJCForecastMonthd] ON [dbo].[vJCForecastMonth] for DELETE as
/*-----------------------------------------------------------------
* Created By:	GF 09/03/2009
* Modified By:
*
*
* Audits deletes in HQMA
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int
    
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
  


---- Audit inserts
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vJCForecastMonth', 'Co: ' + convert(varchar(3), d.JCCo) + ' Contract:' + d.Contract + ' Forecast Month: ' + isnull(convert(varchar(8),d.ForecastMonth,1),''), 
		d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d 
   
return
   
error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete JC Forecast Month!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************/
CREATE TRIGGER [dbo].[vtJCForecastMonthi] on [dbo].[vJCForecastMonth] for INSERT AS 
/*-----------------------------------------------------------------
* Created By:	GF 09/03/2009
* Modified By: 
*
* Trigger validates contract
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @rcode int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- validate contract
select @validcnt = count(*) from inserted i join dbo.bJCCM c with (nolock) on c.JCCo=i.JCCo and c.Contract=i.Contract
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Contract'
	goto error
	end
	
	
---- Audit inserts 
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vJCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
   		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
FROM inserted i



return

error:
	select @errmsg = @errmsg + ' - cannot insert JC Forecast Month!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************/
CREATE TRIGGER [dbo].[vtJCForecastMonthu] on [dbo].[vJCForecastMonth] for update AS 
/*-----------------------------------------------------------------
* Created By:	GF 09/03/2009
* Modified By: 
*
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @rcode int, @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on



---- Audit inserts
IF UPDATE(RevenuePct)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
			i.JCCo, 'C', 'RevenuePct',  convert(varchar(10),d.RevenuePct), convert(varchar(10),i.RevenuePct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo and d.Contract=i.Contract and d.ForecastMonth=i.ForecastMonth
	WHERE isnull(d.RevenuePct,'') <> isnull(i.RevenuePct,'')
	END
IF UPDATE(CostPct)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
			i.JCCo, 'C', 'CostPct',  convert(varchar(10),d.CostPct), convert(varchar(10),i.CostPct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  and d.Contract=i.Contract and d.ForecastMonth=i.ForecastMonth
	WHERE isnull(d.CostPct,'') <> isnull(i.CostPct,'')
	END





return

error:
	select @errmsg = @errmsg + ' - cannot update PC Forecast Month!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
ALTER TABLE [dbo].[vJCForecastMonth] ADD CONSTRAINT [PK_vJCForecastMonth] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vJCForecastMonth] ON [dbo].[vJCForecastMonth] ([JCCo], [Contract], [ForecastMonth]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vJCForecastMonth] WITH NOCHECK ADD CONSTRAINT [FK_vJCForecastMonth_bJCCM] FOREIGN KEY ([JCCo], [Contract]) REFERENCES [dbo].[bJCCM] ([JCCo], [Contract]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vJCForecastMonth] NOCHECK CONSTRAINT [FK_vJCForecastMonth_bJCCM]
GO
