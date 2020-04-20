CREATE TABLE [dbo].[bHRCA]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[Asset] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[AssetCategory] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AssetDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Manufacturer] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UnassignLoc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ModelYear] [char] (4) COLLATE Latin1_General_BIN NULL,
[Model] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Identifier] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PurchDate] [dbo].[bDate] NULL,
[BookValue] [dbo].[bDollar] NULL,
[Phone] [dbo].[bPhone] NULL,
[LicNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LicState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LicExpDate] [dbo].[bDate] NULL,
[Warranty] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[WarrExpDate] [dbo].[bDate] NULL,
[Assigned] [dbo].[bHRRef] NULL,
[MemoInOut] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Status] [tinyint] NULL,
[StatusMemo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRCA] ON [dbo].[bHRCA] ([HRCo], [Asset]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRCA] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  Trigger [dbo].[btHRCAd] on [dbo].[bHRCA] for Delete
    as
    

/**************************************************************
    * Created: mh 9/21/2005
    *	
    *
    **************************************************************/
    declare @errmsg varchar(255), @numrows int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
   	If exists (Select 1 from dbo.bHRTA a 
   	join deleted d on a.HRCo = d.HRCo and a.Asset = d.Asset)
   	begin
   		select @errmsg = 'Check In/Out tracking records exist for Asset ' + (select top 1 Asset from deleted)
   		goto error
   	end
   
   /* Audit inserts */
   insert into bHQMA select 'bHRCA', 'HRCo: ' + convert(char(3),isnull(d.HRCo,'')) + ' ' + 'Asset: ' + d.Asset,
    	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
    	from deleted d
   	join bHRCO e on d.HRCo = e.HRCo
       where e.AuditAssetYN = 'Y'
   
    Return
    error:
    select @errmsg = (@errmsg + ' - cannot delete Asset from HRCA! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   CREATE trigger [dbo].[btHRCAi] on [dbo].[bHRCA] for INSERT as
/*-----------------------------------------------------------------
*  Created: mh 6/2/04
*  Modified: GG 06/12/08 - #128324 - remove cursor, add HR Co# validation, cleanup auditing
*
* 
*/----------------------------------------------------------------

declare @errmsg varchar(255), @validcnt int, @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- validate HR Co#
select @validcnt = count(1) from inserted i
join dbo.bHRCO c on c.HRCo = i.HRCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid HR Company #'
	goto error
	end
	 
-- audit inserted records
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
from inserted i
join dbo.bHRCO e on e.HRCo = i.HRCo
where e.AuditAssetYN = 'Y' 
   
return

error:
	SELECT @errmsg = @errmsg +  ' - cannot insert HR Company Asset!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
CREATE trigger [dbo].[btHRCAu] on [dbo].[bHRCA] for UPDATE as
/*-----------------------------------------------------------------
* Created: mh 6/2/04
* Modified: GG 06/12/08 - #128324 - remove cursor, add key validation, cleanup auditing
*
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
   
-- check for primary key changes
if update(HRCo) or update(Asset) 
	begin
	select @errmsg = 'You are not allowed to change primary key values '
	goto error
	end

-- audit changes
if update(AssetCategory)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','AssetCategory',d.AssetCategory, i.AssetCategory, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.AssetCategory,'') <> isnull(i.AssetCategory,'') and c.AuditAssetYN  = 'Y'
if update(AssetDesc)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','AssetDesc',d.AssetDesc, i.AssetDesc, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.AssetDesc,'') <> isnull(i.AssetDesc,'') and c.AuditAssetYN  = 'Y'
if update(Manufacturer)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Manufacturer',d.Manufacturer, i.Manufacturer, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Manufacturer,'') <> isnull(i.Manufacturer,'') and c.AuditAssetYN  = 'Y'
if update(UnassignLoc)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','UnassignLoc',d.UnassignLoc, i.UnassignLoc, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.UnassignLoc,'') <> isnull(i.UnassignLoc,'') and c.AuditAssetYN  = 'Y'
if update(ModelYear)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','ModelYear',d.ModelYear, i.ModelYear, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.ModelYear,'') <> isnull(i.ModelYear,'') and c.AuditAssetYN  = 'Y'
if update(Model)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Model',d.Model, i.Model, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Model,'') <> isnull(i.Model,'') and c.AuditAssetYN  = 'Y'
if update(Identifier)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Identifier',d.Identifier, i.Identifier, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Identifier,'') <> isnull(i.Identifier,'') and c.AuditAssetYN  = 'Y'
if update(PurchDate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','PurchDate',convert(varchar,d.PurchDate,1), convert(varchar,i.PurchDate,1),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.PurchDate,'') <> isnull(i.PurchDate,'') and c.AuditAssetYN  = 'Y'
if update(BookValue)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','BookValue',convert(varchar,d.BookValue), convert(varchar,i.BookValue),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.BookValue,0) <> isnull(i.BookValue,0) and c.AuditAssetYN  = 'Y'
if update(Phone)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Phone',d.Phone, i.Phone, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Phone,'') <> isnull(i.Phone,'') and c.AuditAssetYN  = 'Y'
if update(LicNumber)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','LicNumber',d.LicNumber, i.LicNumber, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.LicNumber,'') <> isnull(i.LicNumber,'') and c.AuditAssetYN  = 'Y'
if update(LicState)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','LicState',d.LicState, i.LicState, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.LicState,'') <> isnull(i.LicState,'') and c.AuditAssetYN  = 'Y'
if update(LicExpDate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','LicExpDate',convert(varchar,d.LicExpDate,1), convert(varchar,i.LicExpDate,1),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.LicExpDate,'') <> isnull(i.LicExpDate,'') and c.AuditAssetYN  = 'Y'
if update(Warranty)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Warranty',d.Warranty, i.Warranty, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Warranty,'') <> isnull(i.Warranty,'') and c.AuditAssetYN  = 'Y'
if update(WarrExpDate)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','WarrExpDate',convert(varchar,d.WarrExpDate,1), convert(varchar,i.WarrExpDate,1),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.WarrExpDate,'') <> isnull(i.WarrExpDate,'') and c.AuditAssetYN  = 'Y'
if update(Assigned)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Assigned',convert(varchar,d.Assigned), convert(varchar,i.Assigned),
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Assigned,0) <> isnull(i.Assigned,0) and c.AuditAssetYN  = 'Y'
if update(MemoInOut)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','MemoInOut',d.MemoInOut, i.MemoInOut, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.MemoInOut,'') <> isnull(i.MemoInOut,'') and c.AuditAssetYN  = 'Y'
if update([Status])
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Status',
		case d.Status when 0 then '0 - Available' when 1 then '1 - Unavailable' when 2 then '2 - Disposed' else 'Unknown' end,
   		case i.Status when 0 then '0 - Available' when 1 then '1 - Unavailable' when 2 then '2 - Disposed' else 'Unknown' end,
		getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.[Status],255) <> isnull(i.[Status],255) and c.AuditAssetYN  = 'Y'
if update(StatusMemo)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','StatusMemo',d.StatusMemo, i.StatusMemo, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.StatusMemo,'') <> isnull(i.StatusMemo,'') and c.AuditAssetYN  = 'Y'
if update(Country)
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRCA', 'HRCo: ' + convert(varchar,i.HRCo) + ' Asset: ' + convert(varchar,i.Asset),
		i.HRCo, 'C','Country',d.Country, i.Country, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on i.HRCo = d.HRCo and i.Asset = d.Asset
	join dbo.bHRCO c on c.HRCo = i.HRCo
	where isnull(d.Country,'') <> isnull(i.Country,'') and c.AuditAssetYN  = 'Y'
	
return
   
error:
   	select @errmsg = @errmsg + ' - cannot update HR Company Assets!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 



GO
