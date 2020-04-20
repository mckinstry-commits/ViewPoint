CREATE TABLE [dbo].[vPCForecastMonth]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ForecastMonth] [dbo].[bMonth] NOT NULL,
[RevenuePct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPCForecastMonth_RevenuePct] DEFAULT ((0)),
[CostPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPCForecastMonth_CostPct] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************/
CREATE trigger [dbo].[vtPCForecastMonthd] ON [dbo].[vPCForecastMonth] for DELETE as
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
select 'vPCForecastMonth', 'Co: ' + convert(varchar(3), d.JCCo) + ' Potential Project:' + d.PotentialProject + ' Forecast Month: ' + isnull(convert(varchar(8),d.ForecastMonth,1),''), 
		d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d 
   
return
   
error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete PC Forecast Month!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************/
CREATE TRIGGER [dbo].[vtPCForecastMonthi] on [dbo].[vPCForecastMonth] for INSERT AS 
/*-----------------------------------------------------------------
* Created By:	GF 09/03/2009
* Modified By: 
*
* Trigger validates Potential Project
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @rcode int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- validate potential project
select @validcnt = count(*) from inserted i join dbo.PCPotentialWork p with (nolock) on p.JCCo=i.JCCo and p.PotentialProject=i.PotentialProject
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Potential Project'
	goto error
	end
	
	
---- Audit inserts 
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vPCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
   		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
FROM inserted i



return

error:
	select @errmsg = @errmsg + ' - cannot insert PC Forecast Month!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************/
CREATE TRIGGER [dbo].[vtPCForecastMonthu] on [dbo].[vPCForecastMonth] for update AS 
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
	SELECT 'vPCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
			i.JCCo, 'C', 'RevenuePct',  convert(varchar(10),d.RevenuePct), convert(varchar(10),i.RevenuePct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo and d.PotentialProject=i.PotentialProject and d.ForecastMonth=i.ForecastMonth
	WHERE isnull(d.RevenuePct,'') <> isnull(i.RevenuePct,'')
	END
IF UPDATE(CostPct)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vPCForecastMonth','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject + ' Forecast Month: ' + isnull(convert(varchar(8),i.ForecastMonth,1),''), 
			i.JCCo, 'C', 'CostPct',  convert(varchar(10),d.CostPct), convert(varchar(10),i.CostPct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo and d.PotentialProject=i.PotentialProject and d.ForecastMonth=i.ForecastMonth
	WHERE isnull(d.CostPct,'') <> isnull(i.CostPct,'')
	END





return

error:
	select @errmsg = @errmsg + ' - cannot update PC Forecast Month!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
GO
ALTER TABLE [dbo].[vPCForecastMonth] ADD CONSTRAINT [PK_vPCForecastMonth] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPCForecastMonth] ON [dbo].[vPCForecastMonth] ([JCCo], [PotentialProject], [ForecastMonth]) ON [PRIMARY]
GO
