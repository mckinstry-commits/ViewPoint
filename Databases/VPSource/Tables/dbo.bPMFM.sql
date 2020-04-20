CREATE TABLE [dbo].[bPMFM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[FirmNumber] [dbo].[bFirm] NOT NULL,
[FirmName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[FirmType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[ContactName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MailCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[MailZip] [dbo].[bZip] NULL,
[MailAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShipState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ShipZip] [dbo].[bZip] NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[URL] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UpdateAP] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMFM_UpdateAP] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MailCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ShipCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ExcludeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMFM_ExcludeYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/****** Object:  Trigger dbo.btPMFMd    Script Date: 8/28/99 9:37:52 AM ******/
CREATE trigger [dbo].[btPMFMd] on [dbo].[bPMFM] for DELETE as
    

/***  basic declares for SQL Triggers ****/

/*--------------------------------------------------------------
 * Delete trigger for PMFM
 * Created By:  LM 12/18/97
 * Modified By:	GF 12/13/2006 - 6.x HQMA
 *				JayR 03/21/2012
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct 'bPMFM','Key: ' + isnull(convert(varchar(3),d.VendorGroup),'') + '/' + isnull(convert(varchar(8),d.FirmNumber),''),
	null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d
join bHQCO h on h.VendorGroup=d.VendorGroup
join bPMCO c on c.APCo=h.HQCo
where c.AuditPMFM = 'Y'


RETURN 
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMFMi ******/
CREATE trigger [dbo].[btPMFMi] on [dbo].[bPMFM] for INSERT as
/*--------------------------------------------------------------
* Created:	LM 12/18/97
* Modified:	GF 05/02/2006 6.x
*			GF 03/08/2008 - issue #127076 country and state validation
*			GG 10/08/08 - #130130 - fix State validation
*			JayR 03/21/2012 - TK-00000 Change to use FK for validation.
*           JayR 08/15/2012 TK-17195 Fix issue where ShipState is allowed to be null.  
* Insert trigger for PMFM
*
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

--FK cannot validate this because country may not be correct.
if EXISTS(SELECT 1 from inserted i WHERE i.MailState IS NOT NULL AND NOT EXISTS (SELECT 1 FROM bHQST WHERE i.MailState = bHQST.State))
	begin
		RAISERROR('Invalid Mail State - cannot update PMFM', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	end

--FK cannot validate this because country may not be correct.	
if EXISTS(SELECT 1 from inserted i WHERE i.ShipState IS NOT NULL AND NOT EXISTS (SELECT 1 FROM bHQST WHERE i.ShipState = bHQST.State))
	begin
		RAISERROR('Invalid Ship State - cannot update PMFM', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select distinct 'bPMFM', ' Key: ' + isnull(convert(varchar(3),i.VendorGroup),'') + '/' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i
join bHQCO h on h.VendorGroup=i.VendorGroup
join bPMCO c on c.APCo=h.HQCo
where c.AuditPMFM = 'Y'


RETURN 
   
   
   
  
 







GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMFMu    Script Date: 8/28/99 9:37:52 AM ******/
CREATE  trigger [dbo].[btPMFMu] on [dbo].[bPMFM] for UPDATE as
/*--------------------------------------------------------------
* Created:	LM 12/18/97
* Modified:	bc 08/05/02 - added VendorGroup to the Vendor Validation
*			GF 05/02/2005 6.x
*			GF 03/08/2008 - issue #127076 country and state validation and APVM update
*			GG 10/08/08 - #130130 - fix State validation
*			GF 01/05/2011 TK-11536 audit change for Vendor incorrect
*			GF 01/05/2011 TK-11536 fixed so that only one per change not per company
*           JayR 08/15/2012 TK-17195 Fix issue where ShipState is allowed to be null.  
* 
* Update trigger for PMFM
*
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- check for changes to VendorGroup
if update(VendorGroup)
    begin
    RAISERROR('Cannot change VendorGroup - cannot update PMFM', 11, -1)
    ROLLBACK TRANSACTION
    RETURN 
    end

---- check for changes to FirmNumber
if update(FirmNumber)
	begin
    RAISERROR('Cannot change FirmNumber - cannot update PMFM', 11, -1)
    ROLLBACK TRANSACTION
    RETURN 
    END

--FK cannot validate this because country may not be correct.
if EXISTS(SELECT 1 from inserted i WHERE i.MailState IS NOT NULL AND NOT EXISTS (SELECT 1 FROM bHQST WHERE i.MailState = bHQST.State))
	begin
		RAISERROR('Invalid Mail State - cannot update PMFM', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	end

--FK cannot validate this because country may not be correct.	
if EXISTS(SELECT 1 from inserted i WHERE i.ShipState IS NOT NULL AND NOT EXISTS (SELECT 1 FROM bHQST WHERE i.ShipState = bHQST.State))
	begin
		RAISERROR('Invalid Ship State - cannot update PMFM', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
    
---- now update bAPVM when UpdateAP flag is 'Y'. Columns to update:
---- FirmName, SortName, Contact, Phone, Fax, EMail, URL, MailAddress, ShipAddress
---- example: if PMFM.FirmName is changed, and APVM.Name is same as old PMFM.FirmName
---- or null, then the APVM.Name is changed to the updated PMFM.FirmName
if not exists(select 1 from inserted i where i.UpdateAP = 'Y') goto Update_Done

---- firm name - name
update bAPVM set Name = i.FirmName
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.FirmName,'') <> isnull(d.FirmName,'')
and (v.Name is null or (isnull(v.Name,'') = isnull(d.FirmName,'')))
---- contact name - contact
update bAPVM set Contact = i.ContactName
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ContactName,'') <> isnull(d.ContactName,'')
and (v.Contact is null or (isnull(v.Contact,'') = isnull(d.ContactName,'')))
---- phone
update bAPVM set Phone = i.Phone
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.Phone,'') <> isnull(d.Phone,'')
and (v.Phone is null or (isnull(v.Phone,'') = isnull(d.Phone,'')))
---- fax
update bAPVM set Fax = i.Fax
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.Fax,'') <> isnull(d.Fax,'')
and (v.Fax is null or (isnull(v.Fax,'') = isnull(d.Fax,'')))
---- email
update bAPVM set EMail = i.EMail
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.EMail,'') <> isnull(d.EMail,'')
and (v.EMail is null or (isnull(v.EMail,'') = isnull(d.EMail,'')))
---- URL
update bAPVM set URL = i.URL
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.URL,'') <> isnull(d.URL,'')
and (v.URL is null or (isnull(v.URL,'') = isnull(d.URL,'')))
---- mail address - address
update bAPVM set Address = i.MailAddress
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailAddress,'') <> isnull(d.MailAddress,'')
and (v.Address is null or (isnull(v.Address,'') = isnull(d.MailAddress,'')))
---- mail address2 - address2
update bAPVM set Address2 = i.MailAddress2
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailAddress2,'') <> isnull(d.MailAddress2,'')
and (v.Address2 is null or (isnull(v.Address2,'') = isnull(d.MailAddress2,'')))
---- mail city - city
update bAPVM set City = i.MailCity
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailCity,'') <> isnull(d.MailCity,'')
and (v.City is null or (isnull(v.City,'') = isnull(d.MailCity,'')))
---- mail state - state
update bAPVM set State = i.MailState
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailState,'') <> isnull(d.MailState,'')
and (v.State is null or (isnull(v.State,'') = isnull(d.MailState,'')))
---- mail zip - zip
update bAPVM set Zip = i.MailZip
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailZip,'') <> isnull(d.MailZip,'')
and (v.Zip is null or (isnull(v.Zip,'') = isnull(d.MailZip,'')))
---- ship address - POaddress
update bAPVM set POAddress = i.ShipAddress
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipAddress,'') <> isnull(d.ShipAddress,'')
and (v.POAddress is null or (isnull(v.POAddress,'') = isnull(d.ShipAddress,'')))
---- ship address2 - POaddress2
update bAPVM set POAddress2 = i.ShipAddress2
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipAddress2,'') <> isnull(d.ShipAddress2,'')
and (v.POAddress2 is null or (isnull(v.POAddress2,'') = isnull(d.ShipAddress2,'')))
---- ship city - POcity
update bAPVM set POCity = i.ShipCity
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipCity,'') <> isnull(d.ShipCity,'')
and (v.POCity is null or (isnull(v.POCity,'') = isnull(d.ShipCity,'')))
---- ship state - POstate
update bAPVM set POState = i.ShipState
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipState,'') <> isnull(d.ShipState,'')
and (v.POState is null or (isnull(v.POState,'') = isnull(d.ShipState,'')))
---- ship zip - POzip
update bAPVM set POZip = i.ShipZip
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipZip,'') <> isnull(d.ShipZip,'')
and (v.POZip is null or (isnull(v.POZip,'') = isnull(d.ShipZip,'')))
---- sort name
update bAPVM set SortName = i.SortName
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.SortName,'') <> isnull(d.SortName,'')
and (v.SortName is null or (isnull(v.SortName,'') = isnull(d.SortName,'')))
---- ship country
update bAPVM set POCountry = i.ShipCountry
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.ShipCountry,'') <> isnull(d.ShipCountry,'')
and (v.POCountry is null or (isnull(v.POCountry,'') = isnull(d.ShipCountry,'')))
---- mail country
update bAPVM set Country = i.MailCountry
from inserted i join deleted d on i.VendorGroup=d.VendorGroup and i.FirmNumber=d.FirmNumber
join bAPVM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdateAP = 'Y' and isnull(i.MailCountry,'') <> isnull(d.MailCountry,'')
and (v.Country is null or (isnull(v.Country,'') = isnull(d.MailCountry,'')))




Update_Done:

---- TK-011536
---- check here to see if we are auditing vendors in any company that uses the vendor group
---- if not then we are done and do not need to do audits
if NOT EXISTS(select 1 from inserted i
	INNER JOIN dbo.bHQCO h on h.VendorGroup=i.VendorGroup
	INNER JOIN dbo.bPMCO c on c.APCo=h.HQCo
	WHERE c.AuditPMFM = 'Y')
		BEGIN
		GOTO Trigger_Done
        END


---- HQMA inserts
if update(FirmName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'FirmName', d.FirmName, i.FirmName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.FirmName,'') <> isnull(i.FirmName,'')
	end
if update(FirmType)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'FirmType', d.FirmType, i.FirmType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.FirmType,'') <> isnull(i.FirmType,'')
	end
if update(SortName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'SortName', d.SortName, i.SortName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.SortName,'') <> isnull(i.SortName,'')
	end
if update(ContactName)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ContactName', d.ContactName, i.ContactName, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ContactName,'') <> isnull(i.ContactName,'')
	end
if update(MailAddress)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailAddress', d.MailAddress, i.MailAddress, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailAddress,'') <> isnull(i.MailAddress,'')
	end
if update(MailCity)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailCity', d.MailCity, i.MailCity, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailCity,'') <> isnull(i.MailCity,'')
	end
if update(MailState)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailState', d.MailState, i.MailState, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailState,'') <> isnull(i.MailState,'')
	end
if update(MailZip)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailZip', d.MailZip, i.MailZip, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailZip,'') <> isnull(i.MailZip,'')
	end
if update(MailAddress2)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailAddress2', d.MailAddress2, i.MailAddress2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailAddress2,'') <> isnull(i.MailAddress2,'')
	end
if update(ShipAddress)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipAddress', d.ShipAddress, i.ShipAddress, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ShipAddress,'') <> isnull(i.ShipAddress,'')
	end
if update(ShipCity)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipCity', d.ShipCity, i.ShipCity, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/isnull(d.ShipCity,'') <> isnull(i.ShipCity,'')
	end
if update(ShipState)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipState', d.ShipState, i.ShipState, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ShipState,'') <> isnull(i.ShipState,'')
	end
if update(ShipZip)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipZip', d.ShipZip, i.ShipZip, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ShipZip,'') <> isnull(i.ShipZip,'')
	end
if update(ShipAddress2)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipAddress2', d.ShipAddress2, i.ShipAddress2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ShipAddress2,'') <> isnull(i.ShipAddress2,'')
	end
if update(Phone)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'Phone', d.Phone, i.Phone, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.Phone,'') <> isnull(i.Phone,'')
	end
if update(Fax)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'Fax', d.Fax, i.Fax, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.Fax,'') <> isnull(i.Fax,'')
	end
if update(EMail)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'EMail', d.EMail, i.EMail, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.EMail,'') <> isnull(i.EMail,'')
	end
if update(URL)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'URL', d.URL, i.URL, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.URL,'') <> isnull(i.URL,'')
	end
if update(Vendor)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'Vendor', isnull(convert(varchar(8),d.Vendor),''), isnull(convert(varchar(8),i.Vendor),''), getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	---- TK-11536
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.Vendor,'') <> isnull(i.Vendor,'')
	end
if update(MailCountry)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'MailCountry', d.MailCountry, i.MailCountry, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.MailCountry,'') <> isnull(i.MailCountry,'')
	end
if update(ShipCountry)
	begin
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFM', 'VendorGroup: ' + isnull(convert(varchar(3),i.VendorGroup),'') + ' Firm: ' + isnull(convert(varchar(8),i.FirmNumber),''),
		null, 'C', 'ShipCountry', d.ShipCountry, i.ShipCountry, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.VendorGroup=i.VendorGroup and d.FirmNumber=i.FirmNumber
	--join bHQCO h on h.VendorGroup=i.VendorGroup
	--join bPMCO c on c.APCo=h.HQCo
	where /*c.AuditPMFM = 'Y' AND*/ isnull(d.ShipCountry,'') <> isnull(i.ShipCountry,'')
	end



Trigger_Done:
---- last set the PMFM.UpdateAP flag to 'N'
update dbo.bPMFM set UpdateAP = 'N'
from inserted i where i.UpdateAP = 'Y'


RETURN
















GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMFM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMFM] ON [dbo].[bPMFM] ([VendorGroup], [FirmNumber]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMFM_VendorVendorGroup] ON [dbo].[bPMFM] ([VendorGroup], [Vendor]) INCLUDE ([FirmNumber]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bPMFT] FOREIGN KEY ([FirmType]) REFERENCES [dbo].[bPMFT] ([FirmType])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bHQCountry_MailCountry] FOREIGN KEY ([MailCountry]) REFERENCES [dbo].[bHQCountry] ([Country])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bHQST_MailState] FOREIGN KEY ([MailCountry], [MailState]) REFERENCES [dbo].[bHQST] ([Country], [State])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bHQCountry_ShipCountry] FOREIGN KEY ([ShipCountry]) REFERENCES [dbo].[bHQCountry] ([Country])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bHQST_ShipState] FOREIGN KEY ([ShipCountry], [ShipState]) REFERENCES [dbo].[bHQST] ([Country], [State])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bHQGP] FOREIGN KEY ([VendorGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bPMFM] WITH NOCHECK ADD CONSTRAINT [FK_bPMFM_bAPVM] FOREIGN KEY ([VendorGroup], [Vendor]) REFERENCES [dbo].[bAPVM] ([VendorGroup], [Vendor])
GO
