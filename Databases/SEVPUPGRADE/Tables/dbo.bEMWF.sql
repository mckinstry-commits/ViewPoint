CREATE TABLE [dbo].[bEMWF]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[Sequence] [int] NOT NULL,
[Manufacturer] [char] (30) COLLATE Latin1_General_BIN NULL,
[PartNo] [char] (20) COLLATE Latin1_General_BIN NULL,
[SerialNo] [char] (30) COLLATE Latin1_General_BIN NULL,
[PartDescription] [dbo].[bItemDesc] NULL,
[WarrantyDesc] [dbo].[bItemDesc] NULL,
[APCo] [dbo].[bCompany] NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[APVendor] [int] NULL,
[APRef] [dbo].[bAPReference] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[HQMaterial] [dbo].[bMatl] NULL,
[DatePurchased] [smalldatetime] NULL,
[DateInstalled] [smalldatetime] NULL,
[MilesAtInstall] [numeric] (18, 0) NULL,
[HoursAtInstall] [numeric] (18, 0) NULL,
[InstalledBy] [char] (20) COLLATE Latin1_General_BIN NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NULL,
[InactiveDate] [smalldatetime] NULL,
[WarrantyHours] [numeric] (18, 0) NULL,
[WarrantyMiles] [numeric] (18, 0) NULL,
[WarrantyDays] [smallint] NULL,
[WarrantyMonths] [smallint] NULL,
[WarrantyYears] [smallint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[WarrantyStartDate] [dbo].[bDate] NULL,
[WarrantyExpirationDate] [dbo].[bDate] NULL,
[WarrantyUM] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     trigger [dbo].[btEMWFd] on [dbo].[bEMWF] for delete as
/*--------------------------------------------------------------
* Created:  TRL 12/10/08 Issue 130859
* Modified: 
*			
* Delete trigger for EM Warranties
*
*--------------------------------------------------------------*/
   
declare @rcode int, @numrows int, @errmsg varchar(255)
   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

--Check to see if Equipment code is being changed.
--Check Old Equipment Code

If exists (select LastUsedEquipmentCode from bEMEM e with(nolock)
Inner Join inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end
--Check New Equipment Code
If exists(select i.Equipment from bEMEM e with (nolock)
Inner Join inserted i on  e.EMCo = i.EMCo and e.Equipment = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end

   
if exists(select 1 from inserted i  Inner join bEMCO c on i.EMCo=c.EMCo where c.AuditWarrantys = 'Y')
BEGIN
	-- Audit inserts
	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bEMWF','EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
	i.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	Inner Join EMCO e on i.EMCo=e.EMCo
	where e.AuditWarrantys = 'Y'
END
return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMWF'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   
CREATE trigger [dbo].[btEMWFi] on [dbo].[bEMWF] for insert as
/*--------------------------------------------------------------
* Created:  TRL 12/10/08 Issue 130859
* Modified:  TRL 134938 --rewrote triggers to allow for a massupdate
*			
*  Insert trigger for EM Warranties
*
*--------------------------------------------------------------*/
declare @rcode int,
@matlvalid bYN,
@numrows int,
 @n varchar(3),
@materialcnt int,
 @hqmatlcnt int, 
 @emeppartcnt int, 
 @errmsg varchar(255)
                   
select @numrows = @@rowcount

if @numrows = 0 return

set nocount on
      
select @materialcnt =0, @hqmatlcnt =0, @emeppartcnt = 0 

--Check to see if Equipment code is being changed.
--Check Old Equipment Code
If exists (select LastUsedEquipmentCode from bEMEM e with(nolock)
Inner Join inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end
--Check New Equipment Code
If exists(select i.Equipment from bEMEM e with (nolock)
Inner Join inserted i on  e.EMCo = i.EMCo and e.Equipment = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end

select @matlvalid=IsNull(c.MatlValid,'N')from inserted i
Inner join bEMCO c on c.EMCo=i.EMCo

-- Validate EMCo
If not exists (select e.EMCo from bEMCO e with (nolock) Inner JOIN inserted i ON i.EMCo = e.EMCo)
begin
	select @errmsg = 'EM Company is Invalid '
    goto error
end


-- Validate Status
if exists(select top 1 1 from inserted where inserted.Status not in ('I','A'))
begin
	select @errmsg = 'Invalid Status '
	goto error
end

-- Validate WarrantyUM
if exists(select top 1 1 from inserted where inserted.WarrantyUM  not in ('Days','Months','Years'))
begin
	select @errmsg = 'Invalid Warranty UM '
	goto error
end

-- Validate APCo
If  exists (select top 1 1 from bAPCO a with (nolock) Left Join inserted i ON i.APCo = a.APCo where i.APCo is not null and a.APCo is null)
begin
	select @errmsg = 'Invalid AP Company'
	goto error
end

--Validate Vendor/APVendorGroup
-- Validate Vendor Group
If  exists (select top 1 1 from bHQGP g with (nolock) left  Join inserted i ON i.VendorGroup = g.Grp where i.VendorGroup is not null and g.Grp is null)
begin
	select @errmsg = 'Invalid Vendor Group'
	goto error
end
-- Validate Vendor
If  exists (select top 1 1  from bAPVM v with (nolock) left Join inserted i ON i.VendorGroup = v.VendorGroup and i.APVendor=v.Vendor
			where i.VendorGroup is not null and i.APVendor is not null and v.Vendor is null)
begin
	select @errmsg = 'Invalid AP Vendor'
	goto error
end

--Validate Material/MatlGroup
-- Validate Matl Group
If  exists (select top 1 1 from bHQGP g with (nolock) left  Join inserted i ON i.MatlGroup = g.Grp where i.MatlGroup is not null and g.Grp is null)
begin
	select @errmsg = 'Invalid Matl Group'
	goto error
end
if @matlvalid = 'Y' 
begin
		select @materialcnt = count(*) from inserted i where isnull(i.HQMaterial,'') <> ''
		
		select @hqmatlcnt =count(*) from dbo.HQMT h with(nolock)
		Inner Join inserted i on h.MatlGroup = i.MatlGroup and h.Material = i.HQMaterial
		 where isnull(i.HQMaterial,'') <> ''
							
		select @emeppartcnt = count(*) from dbo.EMEP e with(nolock)
		Inner Join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment and e.PartNo = i.HQMaterial
		 where isnull(i.HQMaterial,'') <> ''
		
		if  @materialcnt <> @hqmatlcnt + @emeppartcnt
		begin
			select @errmsg = 'Invalid Material'
			goto error
		end				
end


if exists(select 1 from inserted i  Inner join bEMCO c on i.EMCo=c.EMCo where  c.AuditWarrantys = 'Y')
BEGIN 
	-- Audit inserts
	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bEMWF','EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
	i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
	from inserted i
	Inner Join bEMCO e on i.EMCo=e.EMCo
	where e.AuditWarrantys = 'Y'
END
return
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMWF'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
    
    
   


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btEMWFu] on [dbo].[bEMWF] for update as
/*--------------------------------------------------------------
* Created:  TRL 12/10/08 Issue 130859
* Modified:  TRL 134938 --rewrote triggers to allow for a massupdate
*			
*  Update trigger for EM Warranties
*
*--------------------------------------------------------------*/
declare @rcode int,@matlvalid bYN, @numrows int,
@materialcnt int, @hqmatlcnt int, @emeppartcnt int ,@n varchar(3),
@errmsg varchar(255)

set nocount on     

select @numrows = @@rowcount

if @numrows = 0 return

select @materialcnt =0, @hqmatlcnt =0, @emeppartcnt = 0 

--Check to see if Equipment code is being changed.
--Check Old Equipment Code
If exists (select LastUsedEquipmentCode from bEMEM e with(nolock)
Inner Join inserted i on e.EMCo = i.EMCo and e.LastUsedEquipmentCode = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end
--Check New Equipment Code
If exists(select i.Equipment from bEMEM e with (nolock)
Inner Join inserted i on  e.EMCo = i.EMCo and e.Equipment = i.Equipment
where e.ChangeInProgress = 'Y')
begin
	select @errmsg = 'Equipment code change in progress'
	GoTo error
end

select @matlvalid=IsNull(c.MatlValid,'N')
from inserted i
Inner join bEMCO c on c.EMCo=i.EMCo

-- see if any fields have changed that is not allowed
if update(EMCo) or Update(Equipment)or Update(Sequence)
begin
	If (select  count(*) from inserted i
    Inner JOIN deleted d ON d.EMCo = i.EMCo and d.Equipment=i.Equipment and d.Sequence=i.Sequence)>=1
    begin
		select @errmsg = 'Primary key fields may not be changed'
		GoTo error
    End
End


-- Validate Status
if exists(select top 1 1 from inserted where inserted.Status not in ('I','A'))
begin
	select @errmsg = 'Invalid Status '
	goto error
end

-- Validate WarrantyUM
if exists(select top 1 1 from inserted where inserted.WarrantyUM  not in ('Days','Months','Years'))
begin
	select @errmsg = 'Invalid Warranty UM '
	goto error
end


-- Validate APCo
If  exists (select top 1 1 from bAPCO a with (nolock) Left Join inserted i ON i.APCo = a.APCo where i.APCo is not null and a.APCo is null)
begin
	select @errmsg = 'Invalid AP Company '
	goto error
end

--Validate Vendor/APVendorGroup
-- Validate Vendor Group
If  exists (select top 1 1 from bHQGP g with (nolock) left  Join inserted i ON i.VendorGroup = g.Grp where i.VendorGroup is not null  and g.Grp is null)
begin
	select @errmsg = 'Invalid Vendor Group'
	goto error
end
-- Validate Vendor
If  exists (select top 1 1  from bAPVM v with (nolock) left Join inserted i ON i.VendorGroup = v.VendorGroup and i.APVendor=v.Vendor
			where i.VendorGroup is not null and i.APVendor is not null and v.Vendor is null)
begin
	select @errmsg = 'Invalid AP Vendor'
	goto error
end

--Validate Material/MatlGroup
-- Validate Matl Group
If  exists (select top 1 1 from bHQGP g with (nolock) left  Join inserted i ON i.MatlGroup = g.Grp where i.MatlGroup is not null and g.Grp is null)
begin
	select @errmsg = 'Invalid Matl Group'
	goto error
end
if @matlvalid = 'Y' 
begin
		select @materialcnt = count(*) from inserted i where isnull(i.HQMaterial,'') <> ''
		
		select @hqmatlcnt =count(*) from dbo.HQMT h with(nolock)
		Inner Join inserted i on h.MatlGroup = i.MatlGroup and h.Material = i.HQMaterial
		 where isnull(i.HQMaterial,'') <> ''
							
		select @emeppartcnt = count(*) from dbo.EMEP e with(nolock)
		Inner Join inserted i on e.EMCo = i.EMCo and e.Equipment = i.Equipment and e.PartNo = i.HQMaterial
		 where isnull(i.HQMaterial,'') <> ''
		
		if  @materialcnt <> @hqmatlcnt + @emeppartcnt
		begin
			select @errmsg = 'Invalid Material'
			goto error
		end				
end
  
-- Insert records into HQMA for changes made to audited fields
if exists(select 1 from inserted i  Inner join bEMCO c on i.EMCo=c.EMCo where  c.AuditWarrantys = 'Y')
BEGIN
	if update(Manufacturer)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'Manufacturer', d.Manufacturer, i.Manufacturer, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.Manufacturer,'') <> isnull(d.Manufacturer,'') and e.AuditWarrantys = 'Y' 
	end

	if update(PartNo)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment  +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'PartNo', d.PartNo, i.PartNo, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.PartNo,'') <> isnull(d.PartNo,'') and e.AuditWarrantys = 'Y' 
	end

    if update(SerialNo)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'SerialNo', d.SerialNo, i.SerialNo, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.SerialNo,'') <> isnull(d.SerialNo,'') and e.AuditWarrantys = 'Y' 
	end    

	if update(PartDescription)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'PartDescription', d.PartDescription, i.PartDescription, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.PartDescription,'') <> isnull(d.PartDescription,'') and e.AuditWarrantys = 'Y' 
	end    

	if update(WarrantyDesc)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyDesc', d.WarrantyDesc, i.WarrantyDesc, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyDesc,'') <> isnull(d.WarrantyDesc,'') and e.AuditWarrantys = 'Y' 
	end

	if update(APCo)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'APCo', d.APCo, i.APCo, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.APCo,0) <> isnull(d.APCo,0) and e.AuditWarrantys = 'Y' 
	end

	if update(VendorGroup)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'VendorGroup', d.VendorGroup, i.VendorGroup, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.VendorGroup,0) <> isnull(d.VendorGroup,0) and e.AuditWarrantys = 'Y' 
	end

	if update(APVendor)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'APVendor', d.APVendor, i.APVendor, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.APVendor,0) <> isnull(d.APVendor,0) and e.AuditWarrantys = 'Y' 
	end   

	if update(APRef)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'APRef', d.APRef, i.APRef, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.APRef,'') <> isnull(d.APRef,'') and e.AuditWarrantys = 'Y' 
	end

    if update(HQMaterial)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'HQMaterial', d.HQMaterial, i.HQMaterial, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.HQMaterial,'') <> isnull(d.HQMaterial,'') and e.AuditWarrantys = 'Y'
	end

   if update(DatePurchased)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'DatePurchased', d.DatePurchased, i.DatePurchased, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.DatePurchased,'') <> isnull(d.DatePurchased,'') and e.AuditWarrantys = 'Y' 
	end

    if update(DateInstalled)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'DateInstalled', d.DateInstalled, i.DateInstalled, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.DateInstalled,'') <> isnull(d.DateInstalled,'') and e.AuditWarrantys = 'Y' 
	end

    if update(MilesAtInstall)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'MilesAtInstall', d.MilesAtInstall, i.MilesAtInstall, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.MilesAtInstall,0) <> isnull(d.MilesAtInstall,0) and e.AuditWarrantys = 'Y' 
	end

	if update(HoursAtInstall)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'HoursAtInstall', d.HoursAtInstall, i.HoursAtInstall, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.HoursAtInstall,0) <> isnull(d.HoursAtInstall,0) and e.AuditWarrantys = 'Y' 
	end

	if update(InstalledBy)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'InstalledBy', d.InstalledBy, i.InstalledBy, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.InstalledBy,'') <> isnull(d.InstalledBy,'') and e.AuditWarrantys = 'Y' 
	end

	if update(Status)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo) + 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'Status', d.Status, i.Status, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.Status,'') <> isnull(d.Status,'') and e.AuditWarrantys = 'Y' 
	end

	if update(InactiveDate)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'InactiveDate', d.InactiveDate, i.InactiveDate, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.InactiveDate,'') <> isnull(d.InactiveDate,'') and e.AuditWarrantys = 'Y' 
	end
     
	if update(WarrantyHours)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyHours', d.WarrantyHours, i.WarrantyHours, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyHours,0) <> isnull(d.WarrantyHours,0) and e.AuditWarrantys = 'Y' 
	end

	if update(WarrantyMiles)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyMiles', d.WarrantyMiles, i.WarrantyMiles, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyMiles,0) <> isnull(d.WarrantyMiles,0) and e.AuditWarrantys = 'Y' 
	end

	if update(WarrantyDays)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyDays', d.WarrantyDays, i.WarrantyDays, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyDays,0) <> isnull(d.WarrantyDays,0) and e.AuditWarrantys = 'Y' 
	end
     
	if update(WarrantyMonths)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyMonths', d.WarrantyMonths, i.WarrantyMonths, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyMonths,0) <> isnull(d.WarrantyMonths,0) and e.AuditWarrantys = 'Y' 
	end
     
	if update(WarrantyYears)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		 i.EMCo, 'C', 'WarrantyYears', d.WarrantyYears, i.WarrantyYears, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo 		
		where isnull(i.WarrantyYears,0) <> isnull(d.WarrantyYears,0) and e.AuditWarrantys = 'Y' 
	end
     
	if update(WarrantyStartDate)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyStartDate', d.WarrantyStartDate, i.WarrantyStartDate, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo
		where isnull(i.WarrantyStartDate,'') <> isnull(d.WarrantyStartDate,'') and e.AuditWarrantys = 'Y' 
	end
     
	if update(WarrantyExpirationDate)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		i.EMCo, 'C', 'WarrantyExpirationDate', d.WarrantyExpirationDate, i.WarrantyExpirationDate, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo
		where isnull(i.WarrantyExpirationDate,'') <> isnull(d.WarrantyExpirationDate,'') and e.AuditWarrantys = 'Y' 
	end
     	
	if update(WarrantyUM)
	begin
		insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bEMWF', 'EM Company: ' + convert(char(3),i.EMCo)+ 'Equipment: ' + i.Equipment +' Sequence: ' + convert(char(3), i.Sequence) , 
		 i.EMCo, 'C', 'WarrantyUM', d.WarrantyUM, i.WarrantyUM, getdate(), SUSER_SNAME()
		from inserted i
		Inner Join  deleted d on  i.EMCo = d.EMCo and i.Equipment = d.Equipment and i.Sequence=d.Sequence
		Inner Join	bEMCO e on i.EMCo=e.EMCo
		where isnull(i.WarrantyUM,'') <> isnull(d.WarrantyUM,'')and e.AuditWarrantys = 'Y'
	end
END     
return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMWF!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biEMWF] ON [dbo].[bEMWF] ([EMCo], [Equipment], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMWF] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
