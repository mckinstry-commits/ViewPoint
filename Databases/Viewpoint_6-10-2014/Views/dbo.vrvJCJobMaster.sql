SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[vrvJCJobMaster]


/*******
 Created:	DH 8/12/2010
 Modified:	HH 4/21/2011 - changed MonthClosed from '12/1/2050' to '12/2/2050' 
			for empty ThroughMonth parameters on report (logic related to #142697)
 Usage:		View selects columns from JCJM, JCCM and converts null MonthClosed to 12/1/2050 with a Contract Status 
			of 1 (Open) so that the comparison MonthClosed > Report Parameter Through Month will return open contracts.  
			Used in all JC reports with jobs that use the (O)pen,(S)oft Closed/Open,(C)losed or (A)ll
			Parameter.
*******/  

as

Select    JCJM.JCCo
		, JCJM.Job
		, JCJM.Description
		, JCJM.Contract
		, JCJM.JobStatus
		, case when JCCM.ContractStatus<>1 then JCCM.MonthClosed else '12/2/2050' end as MonthClosedForReport
		, JCJM.BidNumber
		, JCJM.ProjectMgr
		, JCJM.JobPhone
		, JCJM.JobFax
		, JCJM.MailAddress
		, JCJM.MailCity
		, JCJM.MailZip
		, JCJM.MailAddress2
		, JCJM.ShipAddress
		, JCJM.ShipCity
		, JCJM.ShipState
		, JCJM.ShipZip
		, JCJM.ShipAddress2
		, JCJM.LiabTemplate
		, JCJM.TaxGroup
		, JCJM.TaxCode
		, JCJM.InsTemplate
		, JCJM.MarkUpDiscRate
		, JCJM.PRLocalCode
		, JCJM.PRStateCode
		, JCJM.EEORegion
		, JCJM.SMSACode
		, JCJM.ProjMinPct
		, JCJM.Notes
		, JCJM.SLCompGroup
		, JCJM.POCompGroup
		, JCJM.VendorGroup
		, JCJM.ArchEngFirm
		, JCJM.GeoCode
		, JCJM.ContactCode
		, JCJM.OurFirm
		, JCJM.AutoAddItemYN
		, JCJM.OverProjNotes
		, JCJM.HrsPerManDay
From JCJM
Inner Join JCCM
On JCJM.JCCo=JCCM.JCCo and JCJM.Contract = JCCM.Contract


GO
GRANT SELECT ON  [dbo].[vrvJCJobMaster] TO [public]
GRANT INSERT ON  [dbo].[vrvJCJobMaster] TO [public]
GRANT DELETE ON  [dbo].[vrvJCJobMaster] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCJobMaster] TO [public]
GRANT SELECT ON  [dbo].[vrvJCJobMaster] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvJCJobMaster] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvJCJobMaster] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvJCJobMaster] TO [Viewpoint]
GO
