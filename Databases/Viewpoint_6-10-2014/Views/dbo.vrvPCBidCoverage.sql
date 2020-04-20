SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[vrvPCBidCoverage]
AS 

/***********************************************************************
*	Created: 06/18/2010
*	Author : Dan Koslicki
*	Purpose: This view is intended to build upon the PCBidCoverage View
*			It is intended to show the same content that appears in 
*			dbo.PCBidCoverage but  more gracefully handle NULL values 
*			for reporting / user purposes
*
*	Reports: PCBidCoverage.rpt
*
*	Mods:	 HH - changed INNER JOIN [dbo].[PCPotentialWork] PW to 
*					LEFT JOIN [dbo].[PCPotentialWork] PW
***********************************************************************/

SELECT		HQ.[HQCo], 
			HQ.[Name], 
			PW.[BidJCDept], 
			PW.[BidNumber], 
			BP.[BidPackage], 
			SC.[ScopeCode], 
			[ScopeDescription]		= SC.[Description], 
			PM.[Phase], 
			[PhaseDescription]		= PM.[Description], 
			BC.[CoveragePotentialProject], 
			[ProjectDescription]	= PW.[Description], 
			PW.[JobSiteStreet], 
			PW.[JobSiteCity], 
			PW.[JobSiteState], 
			PW.[JobSiteZip], 
			PW.[BidStarted], 
			[VendorName]			= PQ.[Name], 
			[ContactName]			= PCC.[Name], 
			BC.[MessageStatus], 
			[MessageStatusDisplayValue] = CIM.DisplayValue,
			[BidResponse]				= ISNULL(BC.[BidResponse],'N'),
			[BidResponseDisplayValue]	= ISNULL(CIR.DisplayValue,'N - No Response'),
			BC.[BidAwarded], 
			[BidReceived]				= ISNULL(BC.[BidReceived], 'N'),
			BC.[BidAmount], 
			BC.[CoverageBidPackage], 
			BC.[CoverageScopeCode], 
			BC.[CoveragePhase], 
			BC.[CoverageVendor], 
			BC.[CoverageJCCo], 
			PW.[BidStatus], 
			[BidStatusDisplayValue]		= CIS.DisplayValue,
			PQ.[SortName], 
			PW.[BidEstimator], 
			PW.[ProjectDetails]

FROM		[dbo].[PCBidCoverage] BC 

INNER JOIN	[dbo].[PCBidPackage] BP 
		ON	BC.[CoverageJCCo]				= BP.[JCCo]
		AND BC.[CoveragePotentialProject]	= BP.[PotentialProject]
		AND BC.[CoverageBidPackage]			= BP.[BidPackage]

LEFT JOIN	[dbo].[PCPotentialWork] PW
		ON	BC.[CoverageJCCo]				= PW.[JCCo] 
		AND BC.[CoverageVendorGroup]		= PW.[VendorGroup]
		AND BC.[CoveragePotentialProject]	= PW.[PotentialProject]

LEFT JOIN	[dbo].[PCScopeCodes] SC
		ON	BC.[CoverageVendorGroup]		= SC.[VendorGroup] 
		AND BC.[CoverageScopeCode]			= SC.[ScopeCode] 

LEFT JOIN	[dbo].[JCPM] PM 
		ON	BC.[CoveragePhaseGroup]			= PM.[PhaseGroup] 
		AND BC.[CoveragePhase]				= PM.[Phase]

LEFT JOIN	[dbo].[PCQualifications] PQ 
		ON	BC.[CoverageVendorGroup]		= PQ.[VendorGroup] 
		AND BC.[CoverageVendor]				= PQ.[Vendor] 

LEFT JOIN	[dbo].[PCContacts] PCC 
		ON	BC.[CoverageVendorGroup]		= PCC.[VendorGroup] 
		AND BC.[CoverageVendor]				= PCC.[Vendor] 
		AND BC.[CoverageContactSeq]			= PCC.[Seq]

LEFT JOIN	[dbo].[HQCO] HQ
		ON	BC.[CoverageJCCo]				= HQ.[HQCo]

LEFT JOIN	[dbo].[DDCI] CIM
		ON	CIM.[ComboType]					= 'PCMessageStatus'
		AND	CIM.DatabaseValue				= BC.[MessageStatus]
		
LEFT JOIN	[dbo].[DDCI] CIR
		ON	CIR.[ComboType]					= 'PCBidResponse'
		AND	CIR.[DatabaseValue]				= BC.[BidResponse]
		
LEFT JOIN	[dbo].[DDCI] CIS
		ON	CIS.[ComboType]					= 'PCBidStatus'
		AND	CIS.[DatabaseValue]				= PW.[BidStatus]



GO
GRANT SELECT ON  [dbo].[vrvPCBidCoverage] TO [public]
GRANT INSERT ON  [dbo].[vrvPCBidCoverage] TO [public]
GRANT DELETE ON  [dbo].[vrvPCBidCoverage] TO [public]
GRANT UPDATE ON  [dbo].[vrvPCBidCoverage] TO [public]
GRANT SELECT ON  [dbo].[vrvPCBidCoverage] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPCBidCoverage] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPCBidCoverage] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPCBidCoverage] TO [Viewpoint]
GO
