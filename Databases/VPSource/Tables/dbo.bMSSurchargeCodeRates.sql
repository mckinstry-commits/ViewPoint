CREATE TABLE [dbo].[bMSSurchargeCodeRates]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[SurchargeCode] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Material] [dbo].[bMatl] NULL,
[TruckType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[UM] [dbo].[bUM] NULL,
[Zone] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SurchargeRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bMSSurchargeCodeRates_SurchargeRate] DEFAULT ((0)),
[MinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bMSSurchargeCodeRates_MinAmt] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[OldSurchargeRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bMSSurchargeCodeRates_OldSurchargeRate] DEFAULT ((0)),
[OldMinAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bMSSurchargeCodeRates_OldMinAmt] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeCodeRatesd] on [dbo].[bMSSurchargeCodeRates] for DELETE as
/*-----------------------------------------------------------------
* Created By:  TRL 03/25/10 Issue 129350
* Modified By: 
*				 
* Validates and inserts HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount

set nocount on

if @numrows = 0 return

-- Audit MS Haul Rate deletions
insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bMSSurchargeCodeRates ', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + convert(varchar,d.SurchargeCode) + '/' + ' Seq: ' + convert(varchar,d.Seq) + '/'
+ convert(varchar(3),d.LocGroup) + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup)
+ '/' + isnull(d.Category,'') + '/' + isnull(d.Material,'') + '/' + isnull(d.TruckType,'') + '/' + isnull(d.UM,'')
+ '/' + isnull(d.Zone,''),
d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted d join bMSCO p on p.MSCo = d.MSCo
where d.MSCo = p.MSCo and p.AuditHaulCodes='Y'

return

error:
	select @errmsg = @errmsg + ' - cannot delete Surcharge Rate!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btMSSurchargeCodeRatesi] on [dbo].[bMSSurchargeCodeRates] for INSERT as
/*-----------------------------------------------------------------
*  Created By:    TRL 03/25/10 Issue 129350
*  Modified By: 
*
*  Validates 
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @nullcnt int, @validcnt int, @numrows int

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

-- validate MS Company
select @validcnt = count(*) from inserted i inner join bMSCO c with(nolock)on c.MSCo = i.MSCo
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid MS company!'
	goto error
end

-- validate Surcharge Code
select @validcnt = count(*) from inserted i inner join bMSSurchargeCodes c with(nolock)on c.MSCo = i.MSCo and c.SurchargeCode=i.SurchargeCode 
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Surcharge Code!'
	goto error
end

-- validate Material Group
select @validcnt = count(*) from inserted i inner join bHQGP g with(nolock)on g.Grp = i.MatlGroup
if @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Material Group'
	goto error
end

-- validate IN Location Group
select @validcnt = count(*) from inserted i inner join bINLG c with(nolock)on c.INCo = i.MSCo and c.LocGroup=i.LocGroup
IF @validcnt <> @numrows
begin
	select @errmsg = 'Invalid Location Group!'
	goto error
end

-- validate Truck Type
select @validcnt = count(*) from inserted i inner join bMSTT t with(nolock)on t.MSCo = i.MSCo and t.TruckType = i.TruckType 
select @nullcnt = count(*) from inserted where TruckType is null
if @validcnt + @nullcnt <> @numrows
begin
	select @errmsg = 'Invalid Truck Type'
	goto error
end

-- validate HQ Unit of Measure
select @validcnt = count(*) from inserted i inner join bHQUM c with(nolock)on c.UM = i.UM 
select @nullcnt = count(*) from inserted where UM is null
IF @validcnt + @nullcnt <> @numrows
begin
	select @errmsg = 'Invalid HQ Unit of Measure!'
	goto error
end

-- check for 'LS' unit of measure
select @validcnt = count(*) from inserted where UM='LS'
if @validcnt > 0
begin
	select @errmsg = 'Invalid, unit of measure cannot be equal to (LS)'
	goto error
end

-- validate IN From Location
select @validcnt = count(*) from inserted i inner join bINLM c with(nolock)on c.INCo = i.MSCo and c.Loc = i.FromLoc
select @nullcnt = count(*) from inserted where FromLoc is null
if @validcnt+@nullcnt <> @numrows
begin
	select @errmsg = 'Invalid From Location!'
	goto error
end

-- validate IN Location Group for Location
select @validcnt = count(*) from inserted i inner join bINLM c with(nolock)on c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup 
if @validcnt+@nullcnt <> @numrows
begin
	select @errmsg = 'Invalid Location Group for From Location!'
	goto error
end

-- validate HQ Material Category
select @validcnt = count(*) from inserted i inner join bHQMC c with(nolock)on c.MatlGroup = i.MatlGroup and c.Category=i.Category
select @nullcnt = count(*) from inserted where Category is null
IF @validcnt + @nullcnt <> @numrows
begin
	select @errmsg = 'Invalid HQ Material Category!'
	goto error
end

-- validate HQ Material
select @validcnt = count(*) from inserted i inner join bHQMT c with(nolock)on c.MatlGroup = i.MatlGroup and c.Material = i.Material
select @nullcnt = count(*) from inserted where Material is null
if @validcnt+@nullcnt <> @numrows
begin
	select @errmsg = 'Invalid HQ Material!'
	goto error
end

-- validate HQ Material valid for HQ Category
select @validcnt = count(*) from inserted i inner join bHQMT c with(nolock)on c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
if @validcnt+@nullcnt <> @numrows
begin
	select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
	goto error
end

-- validate Zone
select @validcnt = count(*) from inserted i where Zone is null or Zone>''
if @validcnt <> @numrows
begin
	select @errmsg = 'Zone must be null or have a value!'
	goto error
end

-- Audit inserts
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bMSSurchargeCodeRates', ' Key: ' + convert(char(3), i.MSCo) + '/' + convert(varchar,i.SurchargeCode) 
+ '/' + convert(varchar,i.Seq) + '/' +  convert(varchar(3),i.LocGroup)
+ '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Category,'') + '/'
+ isnull(i.Material,'') + '/' + isnull(i.TruckType,'') + '/' + isnull(i.UM,'') + '/' + isnull(i.Zone,''),
i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i join bMSCO c on c.MSCo = i.MSCo
where i.MSCo = c.MSCo and c.AuditSurcharges = 'Y'

return


error:
SELECT @errmsg = @errmsg +  ' - cannot insert into MSSurchargeCodeRates!'
RAISERROR(@errmsg, 11, -1);
rollback transaction

GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btMSSurchargeCodeRatesu] on [dbo].[bMSSurchargeCodeRates] for UPDATE as
/*--------------------------------------------------------------
* Created By:    TRL 03/25/10 Issue 129350
* Modified By:	DAN SO 03/30/2010 - ISSUE: #129350 - Old/New SurchargeRate & MinAmt
*				GF 04/26/2013 TFS-48496 removed old rate/min amount check for less than zero
*
*				
*  Update trigger for MSHR
*
*--------------------------------------------------------------*/
declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255)
   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on
   
-- check for key changes
IF UPDATE(MSCo)
begin
	select @errmsg = 'MSCo may not be updated'
	goto error
end
   
IF UPDATE(SurchargeCode)
begin
       select @errmsg = 'Surcharge Code may not be updated'
       goto error
 end
   
IF UPDATE(Seq)
begin
     select @errmsg = 'Sequence may not be updated'
      goto error
end
   
-- validate Material Group
IF UPDATE(MatlGroup)
BEGIN
	select @validcnt = count(*) from inserted i join bHQGP g with(nolock)on g.Grp = i.MatlGroup
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Invalid Material Group'
		goto error
	end
END
   
-- validate IN Location Group
if UPDATE(LocGroup)
BEGIN
  select @validcnt = count(*) from inserted i join bINLG c with(nolock)on  c.INCo = i.MSCo and c.LocGroup=i.LocGroup
  IF @validcnt <> @numrows
      begin
		select @errmsg = 'Invalid Location Group!'
		goto error
      end
END
   
-- validate Truck Type
if UPDATE(TruckType)
BEGIN
	select @validcnt = count(*) from inserted i join bMSTT t with(nolock)on 	t.MSCo = i.MSCo and t.TruckType = i.TruckType
	select @nullcnt = count(*) from inserted where TruckType is null
	if @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Truck Type!'
		goto error
	end
END
   
-- validate IN From Location
IF UPDATE(FromLoc)
BEGIN
	select @validcnt = count(*) from inserted i inner join bINLM c with(nolock)on c.INCo = i.MSCo and c.Loc = i.FromLoc
	select @nullcnt = count(*) from inserted where FromLoc is null
	if @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid From Location!'
		goto error
	end

	-- validate IN Location Group for Location
	select @validcnt = count(*) from inserted i inner join bINLM c with(nolock)on c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
	if @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Location Group for From Location!'
		goto error
	end
END
   
-- validate HQ Material Category
IF UPDATE(Category)
BEGIN
	select @validcnt = count(*) from inserted i inner join bHQMC c with(nolock)on c.MatlGroup = i.MatlGroup and c.Category=i.Category
	select @nullcnt = count(*) from inserted where Category is null
	IF @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid Material Category!'
		goto error
	end
END
   
-- validate HQ Material
IF UPDATE(Material)
BEGIN
	select @validcnt = count(*) from inserted i inner join bHQMT c with(nolock)on	c.MatlGroup = i.MatlGroup and c.Material = i.Material
	select @nullcnt = count(*) from inserted where Material is null
	if @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid HQ Material!'
		goto error
	end
   
      -- validate HQ Material valid for HQ Category
      select @validcnt = count(*) from inserted i inner join bHQMT c with(nolock)on c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
      if @validcnt+@nullcnt <> @numrows
      begin
           select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
           goto error
      end
END
   
-- validate HQ Unit of Measure
IF UPDATE(UM)
BEGIN
	select @validcnt = count(*) from inserted i inner join bHQUM c with(nolock)on c.UM = i.UM
	select @nullcnt = count(*) from inserted where UM is null
	IF @validcnt+@nullcnt <> @numrows
	begin
		select @errmsg = 'Invalid HQ Unit of Measure!'
		goto error
	end

	select @validcnt = count(*) from inserted where UM='LS'
	if @validcnt > 0
	begin
		select @errmsg = 'Invalid, unit of measure cannot be (LS)'
		goto error
	end
END
   
-- validate Zone
IF UPDATE(Zone)
BEGIN
	select @validcnt = count(*) from inserted i where Zone is null or Zone > ''
	if @validcnt <> @numrows
	begin
		select @errmsg = 'Zone must be null or have a value!'
		goto error
	end
END
   
   
-- Audit inserts
IF UPDATE(LocGroup)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
	convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')

IF UPDATE(FromLoc)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()	
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')

IF UPDATE(MatlGroup)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
	convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')

IF UPDATE(Category)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.Category,'') <> isnull(i.Category,'')

IF UPDATE(Material)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)	
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.Material,'') <> isnull(i.Material,'')

IF UPDATE(UM)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.UM,'') <> isnull(i.UM,'')

IF UPDATE(Zone)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Zone', d.Zone, i.Zone, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.Zone,'') <> isnull(i.Zone,'')

IF UPDATE(SurchargeRate)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Surcharge Rate', convert(varchar, d.SurchargeRate),	convert(varchar, i.SurchargeRate), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.SurchargeRate,'') <> isnull(i.SurchargeRate,'')

IF UPDATE(MinAmt)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Minimum Amount', convert(varchar(10), d.MinAmt),
	convert(varchar(10), i.MinAmt), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.OldMinAmt,'') <> isnull(i.OldMinAmt,'')
 
IF UPDATE(OldMinAmt)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Old Minimum Amount', convert(varchar(10), d.OldMinAmt),
	convert(varchar(10), i.OldMinAmt), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.OldMinAmt,'') <> isnull(i.OldMinAmt,'')
	
IF UPDATE(OldSurchargeRate)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSSurchargeCodeRates', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Surcharge Code: ' + convert(varchar,i.SurchargeCode) + ' Seq: ' + convert(varchar,i.Seq),
	i.MSCo, 'C', 'Old Surcharge Rate', convert(varchar(20), d.OldSurchargeRate),	convert(varchar(20), i.OldSurchargeRate), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.SurchargeCode=i.SurchargeCode
	JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditSurcharges='Y'
	WHERE isnull(d.OldSurchargeRate,'') <> isnull(i.OldSurchargeRate,'')


   
   
 return
   
 error:
   	select @errmsg = @errmsg + ' - cannot update into MSSurchargeCodeRates'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction


GO

ALTER TABLE [dbo].[bMSSurchargeCodeRates] ADD CONSTRAINT [PK_bMSSurchargeCodeRates] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bMSSurchargeCodeRates] ON [dbo].[bMSSurchargeCodeRates] ([MSCo], [SurchargeCode], [LocGroup], [FromLoc], [Category], [MatlGroup], [Material], [TruckType], [UM], [Zone]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_bMSSurchargeCodeRatesSeq] ON [dbo].[bMSSurchargeCodeRates] ([MSCo], [SurchargeCode], [Seq]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bMSSurchargeCodeRates] WITH NOCHECK ADD CONSTRAINT [FK_bMSSurchargeCodeRates_bMSSurchargeCodes] FOREIGN KEY ([MSCo], [SurchargeCode]) REFERENCES [dbo].[bMSSurchargeCodes] ([MSCo], [SurchargeCode])
GO
