CREATE TABLE [dbo].[bHQPO]
(
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[PriceIndex] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (120) COLLATE Latin1_General_BIN NULL,
[Factor] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bHQPO_Factor] DEFAULT ((0)),
[MinDays] [int] NOT NULL CONSTRAINT [DF_bHQPO_MinDays] DEFAULT ((0)),
[MinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHQPO_MinAmt] DEFAULT ((0)),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************/
CREATE trigger [dbo].[btHQPOd] on [dbo].[bHQPO] for DELETE as
/*----------------------------------------------------------
* Created By:	GF 03/13/2009 - issue #129409 - price escalation
* Modified By:
*
* This trigger rejects delete in bHQPO (Price Escalation)
* if a dependent record is found in:
*
* HQPD - Price Escalation Date adjustments
* HQPM - Price Escalation Materials
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- check for Price Index in HQPD
if exists(select top 1 1 from dbo.bHQPD c with (nolock) join deleted d on d.Country=c.Country
			and d.State = c.State and d.PriceIndex = c.PriceIndex)
	begin
	select @errmsg = 'Price Index has date addjustments assigned.'
	goto error
	end
   
---- check Price Index in HQPM
if exists(select top 1 1 from dbo.bHQPM m with (nolock) join deleted d on d.Country=m.Country
			and d.State = m.State and d.PriceIndex = m.PriceIndex)
	begin
	select @errmsg = 'Price Index has materials assigned.'
	goto error
	end


---- Audit HQ Price Index deletions
----insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bHQPO', 'Country: ' + isnull(d.Country,'') + ', State: ' + isnull(d.State,'') + ', PriceIndex: ' + isnull(d.PriceIndex,''),
----       null, 'D', null, null, null, getdate(), SUSER_SNAME()
----from deleted d
----join dbo.bHQCO c with (nolock) join d.HQCo = c.HQCo and c.AuditPriceIndex = 'Y'



return
   
error:
	select @errmsg = @errmsg + ' - cannot delete HQ Price Index!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE trigger [dbo].[btHQPOi] on [dbo].[bHQPO] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GF 03/13/2009 - issue #129409 price escalation
* Modified By: 
*
*
* This trigger rejects insertion in bHQPO (Price Escalation)
* if any of the following error conditions exist:
*
* Invalid Country
* Invalud State
*
*/----------------------------------------------------------------
declare @numrows int, @validcnt int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- validate Country
select @validcnt = count(1) from dbo.bHQCountry c (nolock) join inserted i on i.Country = c.Country
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Country'
   	goto error
   	end

---- validate state
select @validcnt = count(*) FROM dbo.bHQST s with (nolock) join inserted i ON i.Country = s.Country AND i.State = s.State
IF @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid State and Country combination'
	goto error
	end



---- add HQ Master Audit entry - not enabled yet are we auditing and if so what is the company??
----insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bHQPO',  'Country: ' + isnull(d.Country,'') + ', State: ' + isnull(d.State,'') + ', PriceIndex: ' + isnull(d.PriceIndex,''),
----		null, 'A', null, null, null, getdate(), SUSER_SNAME() 
----from inserted i
----join bHQCO a on i.HQCo=a.HQCo where a.AuditPriceIndex='Y'



return

error:
   	select @errmsg = @errmsg + ' - cannot insert HQ Price Escalation Index!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
ALTER TABLE [dbo].[bHQPO] ADD CONSTRAINT [PK_bHQPO] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biHQPO] ON [dbo].[bHQPO] ([Country], [State], [PriceIndex]) ON [PRIMARY]
GO
