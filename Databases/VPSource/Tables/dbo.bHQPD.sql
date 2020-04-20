CREATE TABLE [dbo].[bHQPD]
(
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[PriceIndex] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Seq] [bigint] NOT NULL,
[FromDate] [dbo].[bDate] NOT NULL,
[ToDate] [dbo].[bDate] NOT NULL,
[EnglishPrice] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHQPD_EnglishPrice] DEFAULT ((0)),
[MetricPrice] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHQPD_MetricPrice] DEFAULT ((0)),
[Factor] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bHQPD_Factor] DEFAULT ((0)),
[MinDays] [int] NOT NULL CONSTRAINT [DF_bHQPD_MinDays] DEFAULT ((0)),
[MinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bHQPD_MinAmt] DEFAULT ((0)),
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
CREATE trigger [dbo].[btHQPDd] on [dbo].[bHQPD] for DELETE as
/*----------------------------------------------------------
* Created By:	GF 03/13/2009 - issue #129409 - price escalation
* Modified By:
*
* This trigger rejects delete in bHQPD (Price Escalation)
* if a dependent record is found in:
*
*
*/---------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   

---- Audit HQ Price Index deletions
----insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bHQPD', 'Country: ' + isnull(d.Country,'') + ', State: ' + isnull(d.State,'') + ', PriceIndex: ' + isnull(d.PriceIndex,'') + ', Seq: ' + convert(varchar(8),d.Seq),
----       null, 'D', null, null, null, getdate(), SUSER_SNAME()
----from deleted d
----join dbo.bHQCO c with (nolock) join d.HQCo = c.HQCo and c.AuditPriceIndex = 'Y'



return
   
error:
	select @errmsg = @errmsg + ' - cannot delete HQ Price Index Adjustment!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************************/
CREATE trigger [dbo].[btHQPDi] on [dbo].[bHQPD] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GF 03/13/2009 - issue #129409 price escalation
* Modified By: 
*
*
* This trigger rejects insertion in bHQPD (Price Escalation Adjustments)
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

---- validate price index
select @validcnt = count(1) FROM dbo.bHQPO p with (nolock) join inserted i
				ON i.Country=p.Country AND i.State=p.State and i.PriceIndex=p.PriceIndex
IF @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country, State, and Price Index combination'
	goto error
	end

---- check from and to date range, to date cannot be less than from date
if exists(select top 1 1 from inserted i where i.ToDate < i.FromDate)
	begin
	select @errmsg = 'Invalid To Date, must not be earlier than from date'
	goto error
	end

---- here is the tricky part
---- we need to check the date range for inserted rows does not
---- already exist in another HQPD row.
---- check from date
select @validcnt = count(1) from dbo.bHQPD a with (nolock) join inserted i
			on i.Country=a.Country AND i.State=a.State and i.PriceIndex=a.PriceIndex
			and i.Seq <> a.Seq and i.FromDate between a.FromDate and a.ToDate
if @validcnt <> 0
	begin
	select @errmsg = 'Invalid From Date, already exists within a date range in another adjustment row'
	goto error
	end

---- check to date
select @validcnt = count(1) from dbo.bHQPD a with (nolock) join inserted i
			on i.Country=a.Country AND i.State=a.State and i.PriceIndex=a.PriceIndex
			and i.Seq <> a.Seq and i.ToDate between a.FromDate and a.ToDate
if @validcnt <> 0
	begin
	select @errmsg = 'Invalid to Date, already exists within a date range in another adjustment row'
	goto error
	end






---- add HQ Master Audit entry - not enabled yet are we auditing and if so what is the company??
----insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
----select 'bHQPD',  'Country: ' + isnull(i.Country,'') + ', State: ' + isnull(i.State,'') + ', PriceIndex: ' + isnull(i.PriceIndex,'') + ', Seq: ' + convert(varchar(8),i.Seq),
----		null, 'A', null, null, null, getdate(), SUSER_SNAME() 
----from inserted i
----join bHQCO a on i.HQCo=a.HQCo where a.AuditPriceIndex='Y'



return

error:
   	select @errmsg = @errmsg + ' - cannot insert HQ Price Escalation Adjustment!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
ALTER TABLE [dbo].[bHQPD] ADD CONSTRAINT [PK_bHQPD] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biHQPD] ON [dbo].[bHQPD] ([Country], [State], [PriceIndex], [Seq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQPDDates] ON [dbo].[bHQPD] ([State], [FromDate], [ToDate]) ON [PRIMARY]
GO
