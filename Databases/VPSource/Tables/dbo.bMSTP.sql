CREATE TABLE [dbo].[bMSTP]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[PriceTemplate] [smallint] NOT NULL,
[Seq] [smallint] NOT NULL,
[LocGroup] [dbo].[bGroup] NOT NULL,
[FromLoc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Category] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Material] [dbo].[bMatl] NULL,
[UM] [dbo].[bUM] NOT NULL,
[OldRate] [dbo].[bRate] NOT NULL,
[OldUnitPrice] [dbo].[bUnitCost] NOT NULL,
[OldECM] [dbo].[bECM] NULL,
[OldMinAmt] [dbo].[bDollar] NOT NULL,
[NewRate] [dbo].[bRate] NOT NULL,
[NewUnitPrice] [dbo].[bUnitCost] NOT NULL,
[NewECM] [dbo].[bECM] NULL,
[NewMinAmt] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bMSTP] ADD
CONSTRAINT [CK_bMSTP_NewECM] CHECK (([NewECM]='E' OR [NewECM]='M' OR [NewECM]='C' OR [NewECM] IS NULL))
ALTER TABLE [dbo].[bMSTP] ADD
CONSTRAINT [CK_bMSTP_OldECM] CHECK (([OldECM]='E' OR [OldECM]='M' OR [OldECM]='C' OR [OldECM] IS NULL))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSTPd] on [dbo].[bMSTP] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 03/02/2000
    * Modified By: GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    * Validates and inserts HQ Master Audit entry.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- Audit deletions
   insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSTP', ' Key: ' + convert(varchar(3),d.MSCo) + '/'
       + convert(varchar(4),d.PriceTemplate) + '/' + convert(varchar(3),d.LocGroup)
       + '/' + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup) + '/' + isnull(d.Category,'') + '/'
       + isnull(d.Material,'') + '/' + isnull(d.UM,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditTemplates='Y'
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete Price Template Detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  trigger [dbo].[btMSTPi] on [dbo].[bMSTP] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/02/2000
    *  Modified By: allenn 05/14/02 - issue 17283, allow negative unit prices
    *				 GG  08/09/02 - #17811 - old and new prices
    *				 GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *
    *  Validates MSTP Columns.
    *  If Templates flagged for auditing, inserts HQ Master Audit entry.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @nullcnt int, @validcnt int, @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- validate Price Template
   select @validcnt = count(*) from inserted i join bMSTH c on
       c.MSCo = i.MSCo and c.PriceTemplate=i.PriceTemplate
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS Price Template!'
      goto error
      end
   
   -- validate Material Group
   select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.MatlGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Material Group'
   	goto error
   	end
   
   -- validate IN Location Group
   select @validcnt = count(*) from inserted i join bINLG c on
       c.INCo = i.MSCo and c.LocGroup=i.LocGroup
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location Group!'
      goto error
      end
   
   -- validate IN From Location
   select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
   select @nullcnt = count(*) from inserted where FromLoc is null
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid From Location!'
      goto error
      end
   
   -- validate IN Location Group for Location
   select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid Location Group for From Location!'
      goto error
      end
   
   -- validate HQ Material Category
   select @validcnt = count(*) from inserted i join bHQMC c on
       c.MatlGroup = i.MatlGroup and c.Category=i.Category
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Material Category!'
      goto error
      end
   
   -- validate HQ Material
   select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material
   select @nullcnt = count(*) from inserted where Material is null
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Material!'
      goto error
      end
   
   -- validate HQ Material valid for HQ Category
   select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
   if @validcnt+@nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
      goto error
      end
   
   -- validate HQ Unit of Measure
   select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
   IF @validcnt <> @numrows
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
   
   -- check for negative values
   select @validcnt = count(*) from inserted where OldRate<0
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid Old markup/discount rate, cannot be less than zero.'
       goto error
       end
   select @validcnt = count(*) from inserted where NewRate<0
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid New markup/discount rate, cannot be less than zero.'
       goto error
       end
   
   -- validate mimimum amount
   select @validcnt = count(*) from inserted where OldMinAmt<0
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid Old Minimum Amount, cannot be less than zero.'
       goto error
       end
   select @validcnt = count(*) from inserted where NewMinAmt<0
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid New Minimum Amount, cannot be less than zero.'
       goto error
       end
   
   -- validate OldECM
   select @validcnt = count(*) from inserted where OldECM in ('E','C','M')
   select @nullcnt = count(*) from inserted where OldECM is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid Old ECM, must be (E, C, or M)!'
      goto error
      end
   -- validate NewECM
   select @validcnt = count(*) from inserted where NewECM in ('E','C','M')
   select @nullcnt = count(*) from inserted where NewECM is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Invalid New ECM, must be (E, C, or M)!'
      goto error
      end
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSTP', ' Key: ' + convert(char(3), i.MSCo) + '/' + convert(varchar(4),i.PriceTemplate) + '/'
       + convert(varchar(3),i.LocGroup) + '/' + isnull(i.FromLoc,'') + '/' + convert(varchar(3),i.MatlGroup) + '/'
       + isnull(i.Category,'') + '/' + isnull(i.Material,'') + '/' + isnull(i.UM,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditTemplates = 'Y'
   
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSTP!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSTPu] on [dbo].[bMSTP] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 07/11/2000
    * Modified By: allenn 05/14/02 - issue 17283, allow negative unit prices
    *				GG 08/09/02 - #17811 - old and new prices
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls and isnull
    *
    *
    *  Update trigger for MSTP
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   -- check for key changes
   if UPDATE(MSCo)
       begin
       select @errmsg = 'MSCo may not be updated'
       goto error
       end
   
   if UPDATE(PriceTemplate)
       begin
       select @errmsg = 'Price Template may not be updated'
       goto error
       end
   
   if UPDATE(Seq)
       begin
       select @errmsg = 'Sequence may not be changed'
       goto error
       end
   
   -- validate Material Group
   IF UPDATE(MatlGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g on
       g.Grp =  i.MatlGroup
       if @validcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Material Group'
   	   goto error
   	   end
   END
   
   -- validate IN Location Group
   if UPDATE(LocGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bINLG c on
       c.INCo = i.MSCo and c.LocGroup=i.LocGroup
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Location Group!'
           goto error
           end
   END
   
   -- validate IN From Location
   IF UPDATE(FromLoc)
   BEGIN
       select @nullcnt = count(*) from inserted where FromLoc = ''
       if @nullcnt > 0
           begin
           select @errmsg = 'From Location must be null or have a value!'
           goto error
           end
   
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
       select @nullcnt = count(*) from inserted where FromLoc is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid From Location!'
           goto error
           end
   
       -- validate IN Location Group for Location
       select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc and c.LocGroup = i.LocGroup
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Location Group for From Location!'
           goto error
           end
   END
   
   -- validate HQ Material Category
   IF UPDATE(Category)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQMC c on
       c.MatlGroup = i.MatlGroup and c.Category=i.Category
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Material Category!'
           goto error
           end
   END
   
   -- validate HQ Material
   IF UPDATE(Material)
   BEGIN
       select @nullcnt = count(*) from inserted where Material = ''
       if @nullcnt > 0
           begin
           select @errmsg = 'HQ Material must be null or have a value!'
           goto error
           end
   
       select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material
       select @nullcnt = count(*) from inserted where Material is null
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Material!'
           goto error
           end
   
       -- validate HQ Material valid for HQ Category
       select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material and c.Category = i.Category
       if @validcnt+@nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid HQ Category assigned to HQ Material!'
           goto error
           end
   END
   
   -- validate HQ Unit of Measure
   IF UPDATE(UM)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
       IF @validcnt <> @numrows
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
   
   -- check for negative values
   IF UPDATE(OldRate)
   BEGIN
       select @validcnt = count(*) from inserted where OldRate<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid Old markup/discount rate, cannot be less than zero.'
           goto error
           end
   END
   IF UPDATE(NewRate)
   BEGIN
       select @validcnt = count(*) from inserted where NewRate<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid New markup/discount rate, cannot be less than zero.'
           goto error
           end
   END
   
   -- validate minimum amount
   IF UPDATE(OldMinAmt)
   BEGIN
       select @validcnt = count(*) from inserted where OldMinAmt<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid Old Minimum Amount, cannot be less than zero.'
           goto error
           end
   END
   IF UPDATE(NewMinAmt)
   BEGIN
       select @validcnt = count(*) from inserted where NewMinAmt<0
       if @validcnt > 0
           begin
           select @errmsg = 'Invalid New Minimum Amount, cannot be less than zero.'
           goto error
           end
   END
   -- validate OldECM
   IF UPDATE(OldECM)
   BEGIN
       select @validcnt = count(*) from inserted where OldECM in ('E','C','M')
   	select @nullcnt = count(*) from inserted where OldECM is null
       if @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Old ECM, must be (E, C, or M)!'
           goto error
           end
   END
   -- validate NewECM
   IF UPDATE(NewECM)
   BEGIN
       select @validcnt = count(*) from inserted where NewECM in ('E','C','M')
   	select @nullcnt = count(*) from inserted where NewECM is null
       if @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid New ECM, must be (E, C, or M)!'
           goto error
           end
   END
   
   -- Audit inserts
   IF UPDATE(LocGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Location Group', convert(varchar(3),d.LocGroup),
       convert(varchar(3),i.LocGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.LocGroup,'') <> isnull(i.LocGroup,'')
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'From Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Category)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Category',  d.Category, i.Category, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.Category,'') <> isnull(i.Category,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Material',  d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Unit of Measure',  d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.UM,'') <> isnull(i.UM,'')
   
   IF UPDATE(OldRate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Old MarkUp/Discount Rate', convert(varchar(12), d.OldRate),
       convert(varchar(12), i.OldRate), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.OldRate,'') <> isnull(i.OldRate,'')
   
   IF UPDATE(NewRate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'New MarkUp/Discount Rate', convert(varchar(12), d.NewRate),
       convert(varchar(12), i.NewRate), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.NewRate,'') <> isnull(i.NewRate,'')
   
   IF UPDATE(OldUnitPrice)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Old Unit Price', convert(varchar(10), d.OldUnitPrice),
       convert(varchar(10), i.OldUnitPrice), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.OldUnitPrice,'') <> isnull(i.OldUnitPrice,'')
   
   IF UPDATE(OldECM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Old ECM', d.OldECM, i.OldECM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.OldECM,'') <> isnull(i.OldECM,'')
   
   IF UPDATE(OldMinAmt)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'Old Minimum Amount', convert(varchar(10), d.OldMinAmt),
       convert(varchar(10), i.OldMinAmt), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.OldMinAmt,'') <> isnull(i.OldMinAmt,'')
   
   IF UPDATE(NewUnitPrice)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'New Unit Price', convert(varchar(10), d.NewUnitPrice),
       convert(varchar(10), i.NewUnitPrice), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.NewUnitPrice,'') <> isnull(i.NewUnitPrice,'')
   
   IF UPDATE(NewECM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'NEw ECM', d.NewECM, i.NewECM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.NewECM,'') <> isnull(i.NewECM,'')
   
   IF UPDATE(NewMinAmt)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSTP', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Price Template: ' + convert(varchar(4),i.PriceTemplate),
       i.MSCo, 'C', 'New Minimum Amount', convert(varchar(10), d.NewMinAmt),
       convert(varchar(10), i.NewMinAmt), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.PriceTemplate=i.PriceTemplate
       JOIN bMSCO ON i.MSCo=bMSCO.MSCo and bMSCO.AuditTemplates='Y'
       WHERE isnull(d.NewMinAmt,'') <> isnull(i.NewMinAmt,'')
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot update changes to MS Template Prices'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSTP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSTP] ON [dbo].[bMSTP] ([MSCo], [PriceTemplate], [LocGroup], [FromLoc], [MatlGroup], [Category], [Material], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSTPSeq] ON [dbo].[bMSTP] ([MSCo], [PriceTemplate], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSTP].[OldECM]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSTP].[NewECM]'
GO
