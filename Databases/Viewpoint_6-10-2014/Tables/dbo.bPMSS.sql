CREATE TABLE [dbo].[bPMSS]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[SendToFirm] [dbo].[bFirm] NULL,
[SendToContact] [dbo].[bEmployee] NULL,
[ResponsibleFirm] [dbo].[bFirm] NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Seq] [bigint] NOT NULL,
[Send] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSS_Send] DEFAULT ('Y'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSS_PrefMethod] DEFAULT ('M'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMSS_CC] DEFAULT ('N'),
[DateSent] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMSSi    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMSSi] on [dbo].[bPMSS] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMSS
* Created By:	ScottP 05/01/2013
* Modified By:	AW 09/19/2013 TFS-62011 Prevent TO contacts if not to the SL vendor
*
*--------------------------------------------------------------*/

if @@rowcount = 0 RETURN
SET NOCOUNT ON
	
 ---- validate uniqueness of vendor + firm + contact
	IF EXISTS(SELECT 1 FROM dbo.bPMSS v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.SLCo = v.SLCo AND i.SL = v.SL
		AND i.VendorGroup = v.VendorGroup 
		AND i.SendToFirm = v.SendToFirm AND i.SendToContact = v.SendToContact
		WHERE i.KeyID <> v.KeyID)
	BEGIN
		RAISERROR('Sent To Firm and Contact already exists - cannot insert into PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END

-- TFS-62011 Prevent TO contacts if not to the correct vendor

	IF EXISTS(SELECT 1 
		FROM inserted i 
		JOIN dbo.SLHDPM s on i.PMCo = s.PMCo AND i.Project = s.Project AND i.SLCo = s.SLCo AND i.SL = s.SL
		JOIN dbo.PMFM f on i.VendorGroup = f.VendorGroup AND i.SendToFirm = f.FirmNumber
		WHERE dbo.vfToString(s.Vendor) <> dbo.vfToString(f.Vendor) AND i.CC = 'N')
	BEGIN
		RAISERROR('Vendor on firm does not match the subcontract vendor - cannot insert PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END

	-- TFS-62011 Prevent more than one TO contacts

	IF EXISTS(SELECT 1 
		FROM inserted i 
		JOIN dbo.bPMSS v ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.SLCo = v.SLCo AND i.SL = v.SL AND i.CC = v.CC
		WHERE i.CC = 'N' and v.KeyID <> i.KeyID)
	BEGIN
		RAISERROR('Subcontract can only be addressed to one TO contact - cannot insert PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END
	
RETURN 
   
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
/****** Object:  Trigger dbo.btPMSSu    Script Date: 8/28/99 9:37:50 AM ******/
CREATE  TRIGGER [dbo].[btPMSSu] ON [dbo].[bPMSS]
    FOR UPDATE
AS
   /*--------------------------------------------------------------
    *
    * Update trigger for PMSS
    * Created By:	SCOTTP 05/01/2013
    * Modified By:	AW 09/19/2013 TFS-62011 Prevent TO contacts if not to the SL vendor	
    *
    *--------------------------------------------------------------*/
    IF @@rowcount = 0 RETURN
    SET nocount ON
   
   -- check for changes to PMCo
    IF UPDATE(PMCo) 
        BEGIN
            RAISERROR('Cannot change PMCo - cannot update PMSS', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to Project
    IF UPDATE(Project) 
        BEGIN
            RAISERROR('Cannot change Project - cannot update PMSS', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to SLCo
    IF UPDATE(SLCo) 
        BEGIN
            RAISERROR('Cannot change SLCo - cannot update PMSS', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
   
   -- check for changes to SL
    IF UPDATE(SL) 
        BEGIN
            RAISERROR('Cannot change SL - cannot update PMSS', 11, -1)
            ROLLBACK TRANSACTION
            RETURN
        END
      
   ---- validate uniqueness of vendor + firm + contact
	IF EXISTS(SELECT 1 FROM dbo.bPMSS v JOIN INSERTED i ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.SLCo = v.SLCo AND i.SL = v.SL
		AND i.VendorGroup = v.VendorGroup 
		AND i.SendToFirm = v.SendToFirm AND i.SendToContact = v.SendToContact
		WHERE i.KeyID <> v.KeyID)
	BEGIN
		RAISERROR('Sent To Firm and Contact already exists - cannot update PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END

	-- TFS-62011 Prevent TO contacts if not to the correct vendor

	IF EXISTS(SELECT 1 
		FROM inserted i 
		JOIN dbo.SLHDPM s on i.PMCo = s.PMCo AND i.Project = s.Project AND i.SLCo = s.SLCo AND i.SL = s.SL
		JOIN dbo.PMFM f on i.VendorGroup = f.VendorGroup AND i.SendToFirm = f.FirmNumber
		WHERE dbo.vfToString(s.Vendor) <> dbo.vfToString(f.Vendor) AND i.CC = 'N')
	BEGIN
		RAISERROR('Vendor on firm does not match the subcontract vendor - cannot update PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END

	-- TFS-62011 Prevent more than one TO contacts

	IF EXISTS(SELECT 1 
		FROM inserted i 
		JOIN dbo.bPMSS v ON
		i.PMCo = v.PMCo AND i.Project = v.Project
		AND i.SLCo = v.SLCo AND i.SL = v.SL AND i.CC = v.CC
		WHERE i.CC = 'N' and v.KeyID <> i.KeyID)
	BEGIN
		RAISERROR('Subcontract can only be addressed to one TO contact - cannot update PMSS', 11, -1)
		ROLLBACK TRANSACTION 
		RETURN
	END
	
    RETURN
    
       
GO
ALTER TABLE [dbo].[bPMSS] WITH NOCHECK ADD CONSTRAINT [CK_bPMSS_CC] CHECK (([CC]='N' OR [CC]='C' OR [CC]='B'))
GO
ALTER TABLE [dbo].[bPMSS] WITH NOCHECK ADD CONSTRAINT [CK_bPMSS_PrefMethod] CHECK (([PrefMethod]='M' OR [PrefMethod]='E' OR [PrefMethod]='F'))
GO
ALTER TABLE [dbo].[bPMSS] WITH NOCHECK ADD CONSTRAINT [CK_bPMSS_Send] CHECK (([Send]='Y' OR [Send]='N'))
GO
ALTER TABLE [dbo].[bPMSS] ADD CONSTRAINT [PK_bPMSS] PRIMARY KEY CLUSTERED  ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bPMSS_Contact] ON [dbo].[bPMSS] ([PMCo], [Project], [SLCo], [SL], [VendorGroup], [SendToFirm], [SendToContact]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
