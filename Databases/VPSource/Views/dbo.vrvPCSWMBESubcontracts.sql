SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*******************************************************************************
 *	Author			: Dan Koslicki
 *	Created			: 05/24/2010
 *	Related Reports	: PCSWMBESubcontractAwards.rpt
 *	Issue #			: 
 *	This view is intended to provide a list of SL Subcontracts, Vendors, 
 *	Projects, and Contracts
 *	
 ******************************************************************************/ 

CREATE VIEW [dbo].[vrvPCSWMBESubcontracts] AS 

SELECT		IT.JCCo,
			HD.VendorGroup,
			HD.Vendor,
			VM.Name,
			PM.Project,
			PM.Description,
			PM.ProjectMgr,
			PW.ProjectType,
			CM.Department,
			CM.Contract,
			CM.OrigContractAmt,
			CM.ContractAmt,
			CM.ContractStatus,
			ContractStatusDisplayValue = ISNULL(CI.DisplayValue, '0-Pending'),
			--JM.BidNumber,
			PM.BidNumber,
			--BC.CoverageScopeCode, -- This may not be needed as it appears that this is only handled at the PC Level
			IT.PhaseGroup,
			IT.Phase,
			PC.Certificate,
			PC.CertificateType,
			CT.Description AS CertificateDescription,
			GoalPercentage = ISNULL(PPC.GoalPct, 0),
			IT.OrigCost,
			IT.CurCost,
			IT.InvCost,
			IT.SLItem
			
FROM		SLIT	IT

LEFT JOIN	SLHD	HD
		ON	IT.SLCo		= HD.SLCo 
		AND IT.SL		= HD.SL             

JOIN		HQCO	HQ
		ON	HQ.HQCo		= IT.SLCo            

LEFT JOIN	JCJM	JM
		ON	JM.JCCo		= IT.JCCo 
		AND JM.Job		= IT.Job            

LEFT JOIN	JCCM	CM
		ON	CM.JCCo		= JM.JCCo 
		AND CM.Contract	= JM.Contract 
		AND CM.ContractStatus <> 0 

INNER JOIN	PCPotentialWork PW
		ON	CM.JCCo = PW.JCCo
		AND CM.Contract = PW.Contract
		AND CM.PotentialProject = PW.PotentialProject 

LEFT JOIN	APVM	VM
		ON	VM.VendorGroup = HD.VendorGroup
		AND	VM.Vendor = HD.Vendor

LEFT JOIN	DDCI	CI
		ON	CM.ContractStatus = CI.DatabaseValue
		AND CI.ComboType = 'JCContractStatus'

INNER JOIN	PCCertificates	PC
		ON	PC.VendorGroup = HD.VendorGroup 
		AND PC.Vendor = HD.Vendor

INNER JOIN	PCCertificateTypes	CT
		ON	CT.VendorGroup = PW.VendorGroup
		AND	CT.CertificateType = PC.CertificateType

INNER JOIN  JCJMPM PM
		ON	PM.JCCo = IT.JCCo
		AND PM.Job = IT.Job
		AND	PM.Contract = CM.Contract
		
LEFT JOIN PCPotentialProjectCertificate PPC
		ON	PPC.JCCo = IT.JCCo 
		AND PPC.PotentialProject = CM.PotentialProject
		AND PPC.VendorGroup = IT.VendorGroup 
		AND PPC.CertificateType = PC.CertificateType

LEFT JOIN	JCMP MP
		ON	MP.JCCo = IT.JCCo
		AND MP.ProjectMgr = PM.ProjectMgr

GO
GRANT SELECT ON  [dbo].[vrvPCSWMBESubcontracts] TO [public]
GRANT INSERT ON  [dbo].[vrvPCSWMBESubcontracts] TO [public]
GRANT DELETE ON  [dbo].[vrvPCSWMBESubcontracts] TO [public]
GRANT UPDATE ON  [dbo].[vrvPCSWMBESubcontracts] TO [public]
GO
