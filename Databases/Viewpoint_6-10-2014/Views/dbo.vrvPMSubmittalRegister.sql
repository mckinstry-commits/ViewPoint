SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***********************************************************************
*	Created: 11/09/2012
*	Author : Sean O'Halloran
*	Purpose: This view is intended to provide access and calculated fields
*            on the PM Submittal Register for report generation purposes
*
*	Reports: PM Submittal Register.rpt
*			 PM Submittal Schedule
*
*	Mods:	 Added ProjDesc - 1/2/2013
***********************************************************************/

CREATE VIEW [dbo].[vrvPMSubmittalRegister] AS
SELECT PMS.PMCo AS Company
	,PMS.Project
	,CASE WHEN JCJMPM.Description IS NULL 
		THEN ''
		ELSE JCJMPM.Description
	END AS ProjDesc	
	,PMS.Seq as Sequence
	,CASE WHEN PMS.Package IS NULL 
		THEN '' 
		ELSE PMS.Package
		END + CASE WHEN PMS.PackageRev IS NULL 
					THEN '' 
					ELSE  + '.' + PMS.PackageRev 
	END AS PackageNumRev
	,CASE WHEN PMS.SubmittalNumber IS NULL 
		THEN '' 
		ELSE PMS.SubmittalNumber END + CASE WHEN PMS.SubmittalRev IS NULL 
												THEN '' 
												ELSE + '.' + PMS.SubmittalRev 
	END AS SubmittalNumRev
    ,PMS.SubmittalNumber AS SubmittalNumber
    ,PMS.SubmittalRev AS SubmittalRev
    ,docType.Description AS DocumentTypeDescription
    ,PMS.Package
    ,PMS.PackageRev AS PkgRev
    ,PMS.Description
    ,PMS.Status
    ,statusID.Description AS StatusDescription
    ,PMS.SpecSection
	,ourFirm.Name AS OurFirmName    
	,apprFirm.FirmName AS ApprovFirmFirmname
	,respFirm.FirmName AS ResponsibleFirmName
	,respFirmContact.FirstName + ' ' + respFirmContact.LastName AS RespFirmContactName
	,PMS.Subcontract
	,PMS.PurchaseOrder
	,PMS.ActivityID
	,PMS.LeadDays1
	,PMS.LeadDays2
	,PMS.LeadDays3
	,PMS.DueToResponsibleFirm
	,PMS.SentToResponsibleFirm
	,PMS.DueFromResponsibleFirm
	,PMS.ReceivedFromResponsibleFirm
	,PMS.DueToApprovingFirm
	,PMS.SentToApprovingFirm
	,PMS.DueFromApprovingFirm
	,PMS.ReceivedFromApprovingFirm
	,PMS.ReturnedToResponsibleFirm
	,PMS.ActivityDate
	,PMS.Closed
	,PMS.Notes
FROM [dbo].[PMSubmittal] PMS	
JOIN JCJMPM ON JCJMPM.PMCo = PMS.PMCo 
	AND JCJMPM.Project = PMS.Project
LEFT JOIN HQCO ourFirm ON ourFirm.HQCo = PMS.PMCo
LEFT JOIN PMFM apprFirm ON apprFirm.VendorGroup = PMS.VendorGroup 
	AND apprFirm.FirmNumber = PMS.ApprovingFirm
LEFT JOIN PMPM apprFirmContact ON apprFirmContact.VendorGroup = PMS.VendorGroup 
	AND apprFirmContact.FirmNumber = PMS.ApprovingFirm 
	AND apprFirmContact.ContactCode = PMS.ApprovingFirmContact
LEFT JOIN PMFM respFirm ON respFirm.VendorGroup = PMS.VendorGroup 
	AND respFirm.FirmNumber = PMS.ResponsibleFirm
LEFT JOIN PMPM respFirmContact ON respFirmContact.VendorGroup = PMS.VendorGroup 
	AND respFirmContact.FirmNumber = PMS.ResponsibleFirm 
	AND respFirmContact.ContactCode = PMS.ResponsibleFirmContact
LEFT JOIN PMDT docType ON docType.DocType = PMS.DocumentType
LEFT JOIN PMSC statusID ON statusID.[Status] = PMS.[Status]
LEFT JOIN PMCO ON PMCO.PMCo = PMS.PMCo
LEFT JOIN SLHD sl ON sl.SLCo = PMCO.APCo 
	AND sl.SL = PMS.Subcontract
LEFT JOIN POHD po ON po.POCo = PMCO.APCo 
	AND po.PO = PMS.PurchaseOrder
GO
GRANT SELECT ON  [dbo].[vrvPMSubmittalRegister] TO [public]
GRANT INSERT ON  [dbo].[vrvPMSubmittalRegister] TO [public]
GRANT DELETE ON  [dbo].[vrvPMSubmittalRegister] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMSubmittalRegister] TO [public]
GRANT SELECT ON  [dbo].[vrvPMSubmittalRegister] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMSubmittalRegister] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMSubmittalRegister] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMSubmittalRegister] TO [Viewpoint]
GO