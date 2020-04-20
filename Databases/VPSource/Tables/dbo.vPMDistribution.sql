CREATE TABLE [dbo].[vPMDistribution]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Seq] [bigint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[SentToFirm] [dbo].[bFirm] NOT NULL,
[SentToContact] [dbo].[bEmployee] NOT NULL,
[ResponsiblePerson] [dbo].[bEmployee] NULL,
[Send] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMDistribution_Send] DEFAULT ('N'),
[PrefMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMDistribution_PrefMethod] DEFAULT ('M'),
[CC] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPMDistribution_CC] DEFAULT ('N'),
[DateSent] [dbo].[bDate] NULL,
[DateSigned] [dbo].[bDate] NULL,
[DrawingLogID] [bigint] NULL,
[SubmittalID] [bigint] NULL,
[TestLogID] [bigint] NULL,
[InspectionLogID] [bigint] NULL,
[PunchListID] [bigint] NULL,
[ContractID] [bigint] NULL,
[SubcontractID] [bigint] NULL,
[ProjectNotesID] [bigint] NULL,
[PurchaseOrderID] [bigint] NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[TestType] [dbo].[bDocType] NULL,
[TestCode] [dbo].[bDocument] NULL,
[InspectionType] [dbo].[bDocType] NULL,
[InspectionCode] [dbo].[bDocument] NULL,
[DrawingType] [dbo].[bDocType] NULL,
[Drawing] [dbo].[bDocument] NULL,
[Rev] [tinyint] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SubmittalType] [dbo].[bDocType] NULL,
[Submittal] [dbo].[bDocument] NULL,
[POCo] [dbo].[bCompany] NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLCo] [dbo].[bCompany] NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[IssueType] [dbo].[bDocType] NULL,
[Issue] [int] NULL,
[IssueID] [bigint] NULL,
[SubcontractCOID] [bigint] NULL,
[SubCO] [smallint] NULL,
[CORContract] [dbo].[bContract] NULL,
[COR] [smallint] NULL,
[CORID] [bigint] NULL,
[POCOID] [bigint] NULL,
[POCONum] [smallint] NULL,
[Contract] [dbo].[bContract] NULL,
[ID] [smallint] NULL,
[ContractCOID] [bigint] NULL,
[ApprovedCOID] [bigint] NULL,
[MeetingMinuteID] [bigint] NULL,
[SubmittalPackageID] [bigint] NULL,
[RFQID] [bigint] NULL,
[MeetingType] [dbo].[bDocType] NULL,
[Meeting] [int] NULL,
[MinutesType] [tinyint] NULL,
[ACO] [dbo].[bACO] NULL,
[PunchList] [dbo].[bDocument] NULL,
[SubmittalPackage] [dbo].[bDocument] NULL,
[SubmittalPackageRev] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[RFQ] [dbo].[bDocument] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_MeetingMinute] ON [dbo].[vPMDistribution] ([PMCo], [Project], [MeetingType], [Meeting], [MinutesType], [SentToFirm], [SentToContact]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_ACO] ON [dbo].[vPMDistribution] ([PMCo], [Project], [ACO]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_PunchList] ON [dbo].[vPMDistribution] ([PMCo], [Project], [PunchList]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_SubmittalPackage] ON [dbo].[vPMDistribution] ([PMCo], [Project], [SubmittalPackage], [SubmittalPackageRev]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_RFQ] ON [dbo].[vPMDistribution] ([PMCo], [Project], [RFQ]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_CCO] ON [dbo].[vPMDistribution] ([PMCo], [Project], [Contract], [ID]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_COR] ON [dbo].[vPMDistribution] ([PMCo], [Project], [CORContract], [COR]) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_vPMDistribution_POCO] ON [dbo].[vPMDistribution] ([PMCo], [Project], [POCo], [PO], [POCONum]) ON [PRIMARY]

ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bPMMM] FOREIGN KEY ([MeetingMinuteID]) REFERENCES [dbo].[bPMMM] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_vPMSubmittalPackage] FOREIGN KEY ([SubmittalPackageID]) REFERENCES [dbo].[vPMSubmittalPackage] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_vPMRequestForQuote] FOREIGN KEY ([RFQID]) REFERENCES [dbo].[vPMRequestForQuote] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bPMOH] FOREIGN KEY ([ApprovedCOID]) REFERENCES [dbo].[bPMOH] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bJCJM] FOREIGN KEY ([PMCo], [Project]) REFERENCES [dbo].[bJCJM] ([JCCo], [Job])
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bPMPU] FOREIGN KEY ([PunchListID]) REFERENCES [dbo].[bPMPU] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bPOHD] FOREIGN KEY ([PurchaseOrderID]) REFERENCES [dbo].[bPOHD] ([KeyID]) ON DELETE CASCADE
ALTER TABLE [dbo].[vPMDistribution] ADD
CONSTRAINT [FK_vPMDistribution_bSLHD] FOREIGN KEY ([SubcontractID]) REFERENCES [dbo].[bSLHD] ([KeyID]) ON DELETE CASCADE
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDistributioni    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMDistributioni] on [dbo].[vPMDistribution] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMDistribution
* Created By:	GF 07/10/2009
* Modified By:	GF 10/23/2009 - issue #134090 submittals
*				GF 10/24/2009 - issue #135479 drawing logs
*				GF 03/15/2010 - issue #120252 purchase orders
*				GF 10/02/2010 - issue #141553 project issues
*				GF 03/22/2011 - TK-03028
*				GF 04/08/2011 - TK-03859 TK-03562 TK-03845
*				JG 05/02/2011 - TK-04386 - Updated for Contract Change Order
*				JG 05/04/2011 - TK-04386 - Updated for ACO
*				JG 05/18/2011 - TK-05304 - Removed ACO
*				JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
*				SCOTTP 05/03/2013 TFS-42703 Added ACO, PunchList, Submittal Package, ReqQuote, Meeting Minutes
*				SCOTTP 07/11/2013 TFS-54435 Remove code that disallows multiple "TO" Contacts for Purchase Order
*
*--------------------------------------------------------------*/
DECLARE @errmsg varchar(255)


if @@rowcount = 0 return
set nocount on

---- validate uniqueness of sent to firm contact for ACO using ApprovedCOID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.ApprovedCOID = v.ApprovedCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.ApprovedCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Approved Change Order.'
	goto error
	end

---- validate uniqueness of sent to firm contact for PunchList using PunchListID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.PunchListID = v.PunchListID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.PunchListID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Punch List.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for Submittal Package using SubmittalPackageID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubmittalPackageID = v.SubmittalPackageID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.SubmittalPackageID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Submittal Package.'
	goto error
	end

---- validate uniqueness of sent to firm contact for Request for Quote using RFQID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.RFQID = v.RFQID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.RFQID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Request for Quote.'
	goto error
	end
		
---- validate uniqueness of sent to firm contact for Meeting Minutes using MeetingMinuteID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.MeetingMinuteID = v.MeetingMinuteID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.MeetingMinuteID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Meeting Minutes.'
	goto error
	end
			
---- validate uniqueness of sent to firm contact for TEST logs using TestLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.TestLogID = v.TestLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.TestLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Test log.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for INSPECTION logs using InspectionLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.InspectionLogID = v.InspectionLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.InspectionLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Inspection log.'
	goto error
	end	
	
----#134090	
------ validate uniqueness of sent to firm contact for SUBMITTAL logs using SubmittalID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubmittalID = v.SubmittalID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.SubmittalID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Submittal.'
	goto error
	end	

----#135479
---- validate uniqueness of sent to firm contact for DRAWING logs using DrawingLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.DrawingLogID = v.DrawingLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.DrawingLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Drawing Log.'
	goto error
	end	

----#120252
---- validate uniqueness of sent to firm contact for Purchase Orders using PurchaseOrderID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.PurchaseOrderID = v.PurchaseOrderID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.PurchaseOrderID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Purchase Order.'
	goto error
	end	
	
----#141553
---- validate uniqueness of sent to firm contact for Project Issues using IssueID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.IssueID = v.IssueID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.IssueID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Project Issue.'
	goto error
	end	


---- validate uniqueness of sent to firm contact for Subcontrract Change Orders using SubcontractCOID TK-03859
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubcontractCOID = v.SubcontractCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.SubcontractCOID <> v.SubcontractCOID AND i.SubcontractCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Subcontract Change Order.'
	goto error
	end	

---- validate uniqueness of sent to firm contact for Contract Change Order using ContractCOID TK-04386
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.ContractCOID = v.ContractCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.ContractCOID <> v.ContractCOID AND i.ContractCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Contract Change Order.'
	goto error
	end	

---- validate uniqueness of sent to firm contact for Purchase Change Order using POCOID TK-03845
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.POCOID = v.POCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.POCOID <> v.POCOID AND i.POCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Purchase Change Order.'
	goto error
	end	

return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMDistribution'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDistributionu    Script Date: 8/28/99 9:37:55 AM ******/
CREATE trigger [dbo].[btPMDistributionu] on [dbo].[vPMDistribution] for UPDATE as
/*--------------------------------------------------------------
* Update trigger for PMDistribution
* Created By:	GF 07/10/2009
* Modified By:	GF 10/23/2009 - issue #134090 submittals
*				GF 10/24/2009 - issue #135479 drawing logs
*				GF 03/15/2010 - issue #120252 purchase orders
*				GF 10/02/2010 - issue #141553 project issues
*				GF 03/22/2011 - TK-03028
*				GF 04/08/2011 - TK-03859 TK-03562 TK-03845
*				JG 05/02/2011 - TK-04386 - Updated for Contract Change Order
*				JG 05/04/2011 - TK-04386 - Updated for ACO
*				JG 05/18/2011 - TK-05304 - Removed ACO
*				JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
*				SCOTTP 05/03/2013 TFS-42703 Added ACO, PunchList, Submittal Package, ReqQuote, Meeting Minutes
*				SCOTTP 07/11/2013 TFS-54435 Remove code that disallows multiple "TO" Contacts for Purchase Order
*
*--------------------------------------------------------------*/
declare @errmsg varchar(255)

if @@rowcount = 0 return
set nocount on

-- check for changes to PMCo
if update(PMCo)
  begin
  select @errmsg = 'Cannot change PMCo'
  goto error
  end

-- check for changes to Project
if update(Project)
  begin
  select @errmsg = 'Cannot change Project'
  goto error
  end

---- validate uniqueness of sent to firm contact for ACO using ApprovedCOID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.ApprovedCOID = v.ApprovedCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.ApprovedCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Approved Change Order.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for PunchList using PunchListID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.PunchListID = v.PunchListID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.PunchListID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Punch List.'
	goto error
	end

---- validate uniqueness of sent to firm contact for Submittal Package using SubmittalPackageID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubmittalPackageID = v.SubmittalPackageID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.SubmittalPackageID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Submittal Package.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for Request for Quote using RFQID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.RFQID = v.RFQID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.RFQID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Request for Quote.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for Meeting Minutes using MeetingMinuteID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.MeetingMinuteID = v.MeetingMinuteID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.MeetingMinuteID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Meeting Minutes.'
	goto error
	end
					
---- validate uniqueness of sent to firm contact for TEST logs using TestLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.TestLogID = v.TestLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.TestLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Test log.'
	goto error
	end
	
---- validate uniqueness of sent to firm contact for INSPECTION logs using InspectionLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.InspectionLogID = v.InspectionLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.InspectionLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Inspection log.'
	goto error
	end	

----#134090	
---- validate uniqueness of sent to firm contact for SUBMITTAL logs using SubmittalID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubmittalID = v.SubmittalID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.SubmittalID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Submittal.'
	goto error
	end	

----#135479
---- validate uniqueness of sent to firm contact for DRAWING logs using DrawingLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.DrawingLogID = v.DrawingLogID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.DrawingLogID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Drawing Log.'
	goto error
	end	

----#120252
---- validate uniqueness of sent to firm contact for DRAWING logs using DrawingLogID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.PurchaseOrderID = v.PurchaseOrderID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.PurchaseOrderID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Purchase Order.'
	goto error
	end	

----#141553
---- validate uniqueness of sent to firm contact for Project Issues using IssueID
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.IssueID = v.IssueID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.KeyID <> v.KeyID AND i.IssueID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Project Issue.'
	goto error
	end	

---- validate uniqueness of sent to firm contact for Subcontract Change Order using SubcontractCOID TK-03859
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.SubcontractCOID = v.SubcontractCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.SubcontractCOID <> v.SubcontractCOID AND i.SubcontractCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Subcontract Change Order.'
	goto error
	end	

---- validate uniqueness of sent to firm contact for Change Order Request using CORID TK-03562
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.CORID = v.CORID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.CORID <> v.CORID AND i.CORID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Change Order Request.'
	goto error
	end	
	
---- validate uniqueness of sent to firm contact for Contract Change Order using ContractCOID TK-04386
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.ContractCOID = v.ContractCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.ContractCOID <> v.ContractCOID AND i.ContractCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Contract Change Order.'
	goto error
	end		
	
---- validate uniqueness of sent to firm contact for Purchase Change Order using POCOID TK-03845
IF (SELECT COUNT(*) FROM dbo.vPMDistribution v JOIN INSERTED i ON
		i.POCOID = v.POCOID AND i.VendorGroup = v.VendorGroup 
		AND i.SentToFirm = v.SentToFirm AND i.SentToContact = v.SentToContact
		WHERE i.POCOID <> v.POCOID AND i.POCOID IS NOT NULL) > 0
	begin
	select @errmsg = 'Sent To Firm and Contact already exists for Purchase Change Order.'
	goto error
	end	


return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMDistribution'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO

ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [CK_vPMDistribution_CC] CHECK (([CC]='N' OR [CC]='C' OR [CC]='B'))
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [CK_vPMDistribution_PrefMethod] CHECK (([PrefMethod]='M' OR [PrefMethod]='E' OR [PrefMethod]='F'))
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [CK_vPMDistribution_Send] CHECK (([Send]='Y' OR [Send]='N'))
GO
ALTER TABLE [dbo].[vPMDistribution] ADD CONSTRAINT [PK_vPMDistribution] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_DrawingLog] ON [dbo].[vPMDistribution] ([PMCo], [Project], [DrawingType], [Drawing], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_InspectionLog] ON [dbo].[vPMDistribution] ([PMCo], [Project], [InspectionType], [InspectionCode], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_Issue] ON [dbo].[vPMDistribution] ([PMCo], [Project], [Issue], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_PO] ON [dbo].[vPMDistribution] ([PMCo], [Project], [POCo], [PO], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_SL] ON [dbo].[vPMDistribution] ([PMCo], [Project], [SLCo], [SL], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_SubcontractCO] ON [dbo].[vPMDistribution] ([PMCo], [Project], [SubCO], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_Submittal] ON [dbo].[vPMDistribution] ([PMCo], [Project], [SubmittalType], [Submittal], [Rev], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_TestLog] ON [dbo].[vPMDistribution] ([PMCo], [Project], [TestType], [TestCode], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_PurchaseOrderID] ON [dbo].[vPMDistribution] ([PurchaseOrderID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vPMDistribution_VendorGroup] ON [dbo].[vPMDistribution] ([VendorGroup], [SentToFirm], [SentToContact]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_vPMContractChangeOrder] FOREIGN KEY ([ContractCOID]) REFERENCES [dbo].[vPMContractChangeOrder] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_vPMChangeOrderRequest] FOREIGN KEY ([CORID]) REFERENCES [dbo].[vPMChangeOrderRequest] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMDG] FOREIGN KEY ([DrawingLogID]) REFERENCES [dbo].[bPMDG] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMIL] FOREIGN KEY ([InspectionLogID]) REFERENCES [dbo].[bPMIL] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMIM] FOREIGN KEY ([IssueID]) REFERENCES [dbo].[bPMIM] ([KeyID]) ON DELETE CASCADE
GO

ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_vPMPOCO_POCOID] FOREIGN KEY ([POCOID]) REFERENCES [dbo].[vPMPOCO] ([KeyID]) ON DELETE CASCADE
GO

ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_vPMSubcontractCO] FOREIGN KEY ([SubcontractCOID]) REFERENCES [dbo].[vPMSubcontractCO] ([KeyID]) ON DELETE CASCADE
GO

ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMSM] FOREIGN KEY ([SubmittalID]) REFERENCES [dbo].[bPMSM] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMTL] FOREIGN KEY ([TestLogID]) REFERENCES [dbo].[bPMTL] ([KeyID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMFM] FOREIGN KEY ([VendorGroup], [SentToFirm]) REFERENCES [dbo].[bPMFM] ([VendorGroup], [FirmNumber])
GO
ALTER TABLE [dbo].[vPMDistribution] WITH NOCHECK ADD CONSTRAINT [FK_vPMDistribution_bPMPM] FOREIGN KEY ([VendorGroup], [SentToFirm], [SentToContact]) REFERENCES [dbo].[bPMPM] ([VendorGroup], [FirmNumber], [ContactCode])
GO
