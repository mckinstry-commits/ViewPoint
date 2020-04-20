CREATE TABLE [dbo].[bPMPM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FirmNumber] [dbo].[bFirm] NOT NULL,
[ContactCode] [dbo].[bEmployee] NOT NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[MiddleInit] [char] (1) COLLATE Latin1_General_BIN NULL,
[Title] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[PhoneExt] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[MobilePhone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ExcludeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPM_ExcludeYN] DEFAULT ('N'),
[MailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MailCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[MailZip] [dbo].[bZip] NULL,
[MailAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AllowPortalAccess] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPM_AllowPortalAccess] DEFAULT ('N'),
[PortalUserName] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PortalPassword] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[PortalDefaultRole] [int] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MailCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[UseAddressOvr] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMPM_UseAddressOvr] DEFAULT ('N'),
[CourtesyTitle] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[FormattedFax] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[UseFaxServerName] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMPM_UseFaxServerName] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btPMPMd    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPMd] on [dbo].[bPMPM] for DELETE as
/*--------------------------------------------------------------
 * Delete trigger for PMPM
 * Created By:
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/26/2012 - TK-00000 Switch to FKs for validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct 'bPMPM','Key: ' + isnull(convert(varchar(3),d.VendorGroup),'') + '/' + isnull(convert(varchar(10),d.FirmNumber),'') + '/' + isnull(convert(varchar(10),d.ContactCode),''),
	null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bHQCO h on h.VendorGroup=d.VendorGroup
join bPMCO c on c.APCo=h.HQCo
where c.AuditPMPM = 'Y'


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMPMi    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPMi] on [dbo].[bPMPM] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMPM
* Created By:	LM 12/18/97
* Modified By:	GF 12/13/2006 - 6.x HQMA
*			GF 03/08/2008 - issue #127076 country and state validation
*			GG 10/08/08 - #130130 - fix State validation
*			JayR 03/26/2012 - TK-00000 Change to use FKs for validation.
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct 'bPMPM', ' Key: ' + isnull(convert(varchar(3),i.VendorGroup),'') + '/' + isnull(convert(varchar(8),i.FirmNumber),'') + '/' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i
join bHQCO h on h.VendorGroup=i.VendorGroup
join bPMCO c on c.APCo=h.HQCo
where c.AuditPMPM = 'Y'


RETURN 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPMPMu    Script Date: 8/28/99 9:37:59 AM ******/
CREATE trigger [dbo].[btPMPMu] on [dbo].[bPMPM] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMPM
* Created:	LM 12/18/97
* Modified:	GF 12/13/2006 - 6.x HQMA
*			GF 03/08/2008 - issue #127076 country and state validation
*			GG 10/08/08 - #130130 - fix State validation
*			GF 07/17/2009 - issue #134122 courtesy title
*			gf 01/17/2012 TK-11762 #144126 limit to one audit only
*			JayR 03/26/2012 TK-00000 Change to use FKs for validation
*			GF 06/18/2012 TK-15757 audit for formatted fax
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to VendorGroup
if update(VendorGroup)
      begin
      RAISERROR('Cannot change VendorGroup - cannot update PMPM', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to FirmNumber
if update(FirmNumber)
      begin
      RAISERROR('Cannot change FirmNumber - cannot update PMPM', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      end

---- check for changes to ContactCode
if update(ContactCode)
      begin
      RAISERROR('Cannot change ContactCode - cannot update PMPM', 11, -1)
      ROLLBACK TRANSACTION
      RETURN 
      END
      
      ---- validate mail State - all State values must exist in bHQST
      --NOTE: The FK constraint is on MailState and MailCountry but because MailCountry can 
      -- be null the FK check allows bad data through.
if EXISTS(SELECT 1 from inserted i WHERE i.MailState IS NOT NULL AND NOT EXISTS (SELECT 1 FROM bHQST WHERE i.MailState = bHQST.State))
	begin
		RAISERROR('Invalid Mail State - cannot update PMPM', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	end


---- TK-11536 TK-11762
---- check here to see if we are auditing vendors in any company that uses the vendor group
---- if not then we are done and do not need to do audits
if NOT EXISTS(select 1 from inserted i
	INNER JOIN dbo.bHQCO h on h.VendorGroup=i.VendorGroup
	INNER JOIN dbo.bPMCO c on c.APCo=h.HQCo
	WHERE c.AuditPMFM = 'Y')
		BEGIN
		RETURN
		END

---- HQMA inserts
if update(SortName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'SortName', d.SortName, i.SortName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and */ isnull(d.SortName,'') <> isnull(i.SortName,'')
	end
if update(LastName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'LastName', d.LastName, i.LastName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/  isnull(d.LastName,'') <> isnull(i.LastName,'')
	end
if update(FirstName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'FirstName', d.FirstName, i.FirstName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.FirstName,'') <> isnull(i.FirstName,'')
	end
if update(MiddleInit)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MiddleInit', d.MiddleInit, i.MiddleInit, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/  isnull(d.MiddleInit,'') <> isnull(i.MiddleInit,'')
	end
if update(Title)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'Title', d.Title, i.Title, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.Title,'') <> isnull(i.Title,'')
	end
if update(Phone)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'Phone', d.Phone, i.Phone, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.Phone,'') <> isnull(i.Phone,'')
	end
if update(PhoneExt)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'PhoneExt', d.PhoneExt, i.PhoneExt, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.PhoneExt,'') <> isnull(i.PhoneExt,'')
	end
if update(MobilePhone)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MobilePhone', d.MobilePhone, i.MobilePhone, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MobilePhone,'') <> isnull(i.MobilePhone,'')
	end
if update(Fax)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'Fax', d.Fax, i.Fax, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.Fax,'') <> isnull(i.Fax,'')
	end
if update(EMail)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'EMail', d.EMail, i.EMail, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.EMail,'') <> isnull(i.EMail,'')
	end
if update(PrefMethod)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'PrefMethod', d.PrefMethod, i.PrefMethod, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.PrefMethod,'') <> isnull(i.PrefMethod,'')
	end
if update(ExcludeYN)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'ExcludeYN', d.ExcludeYN, i.ExcludeYN, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.ExcludeYN,'') <> isnull(i.ExcludeYN,'')
	end
if update(UseAddressOvr)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'UseAddressOvr', d.UseAddressOvr, i.UseAddressOvr, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.UseAddressOvr,'') <> isnull(i.UseAddressOvr,'')
	end
if update(MailAddress)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailAddress', d.MailAddress, i.MailAddress, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailAddress,'') <> isnull(i.MailAddress,'')
	end
if update(MailCity)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailCity', d.MailCity, i.MailCity, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailCity,'') <> isnull(i.MailCity,'')
	end
if update(MailState)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailState', d.MailState, i.MailState, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailState,'') <> isnull(i.MailState,'')
	end
if update(MailZip)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailZip', d.MailZip, i.MailZip, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailZip,'') <> isnull(i.MailZip,'')
	end
if update(MailAddress2)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailAddress2', d.MailAddress2, i.MailAddress2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailAddress2,'') <> isnull(i.MailAddress2,'')
	end
if update(AllowPortalAccess)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'AllowPortalAccess', d.AllowPortalAccess, i.AllowPortalAccess, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.AllowPortalAccess,'') <> isnull(i.AllowPortalAccess,'')
	end
if update(PortalUserName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'PortalUserName', d.PortalUserName, i.PortalUserName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.PortalUserName,'') <> isnull(i.PortalUserName,'')
	end
if update(PortalPassword)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'PortalPassword', d.PortalPassword, i.PortalPassword, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.PortalPassword,'') <> isnull(i.PortalPassword,'')
	end
if update(PortalDefaultRole)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMPM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'PortalDefaultRole', convert(varchar(10),d.PortalDefaultRole), convert(varchar(10),i.PortalDefaultRole), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(convert(varchar(10),d.PortalDefaultRole),'') <> isnull(convert(varchar(10),i.PortalDefaultRole),'')
	end
if update(MailCountry)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'MailCountry', d.MailCountry, i.MailCountry, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.MailCountry,'') <> isnull(i.MailCountry,'')
	end
if update(CourtesyTitle)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'CourtesyTitle', d.CourtesyTitle, i.CourtesyTitle, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMPM = 'Y' and*/ isnull(d.CourtesyTitle,'') <> isnull(i.CourtesyTitle,'')
	end

----TK-15757
if update(FormattedFax)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),'') + ' Contact: ' + isnull(convert(varchar(8),i.ContactCode),''),
		null, 'C', 'FormattedFax', d.FormattedFax, i.FormattedFax, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber and d.ContactCode=i.ContactCode
	where isnull(d.FormattedFax,'') <> isnull(i.FormattedFax,'')
	end


RETURN 


GO
ALTER TABLE [dbo].[bPMPM] ADD CONSTRAINT [PK_bPMPM] PRIMARY KEY CLUSTERED  ([VendorGroup], [FirmNumber], [ContactCode]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMPM] ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMPM] WITH NOCHECK ADD CONSTRAINT [FK_bPMPM_bHQCountry] FOREIGN KEY ([MailCountry]) REFERENCES [dbo].[bHQCountry] ([Country])
GO
ALTER TABLE [dbo].[bPMPM] WITH NOCHECK ADD CONSTRAINT [FK_bPMPM_bHQST] FOREIGN KEY ([MailCountry], [MailState]) REFERENCES [dbo].[bHQST] ([Country], [State])
GO
ALTER TABLE [dbo].[bPMPM] WITH NOCHECK ADD CONSTRAINT [FK_bPMPM_bPMFM] FOREIGN KEY ([VendorGroup], [FirmNumber]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMPM].[ExcludeYN]'
GO
