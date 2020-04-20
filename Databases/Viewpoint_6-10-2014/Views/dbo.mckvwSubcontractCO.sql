SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[mckvwSubcontractCO] as
SELECT distinct SCO.SL,SCO.SubCO,
		I.Seq,
		SCO.Project as JObNumber,
		SCO.Description as ChangeOrderName
		,SCO.Details
		,SCO.Reference
		,FORMAT(SCO.Date,'MM/dd/yyyy', 'en-US' )  as ChangeOrderDate
		,J.Description as JobName
		, J.MailAddress as JobAddress
		, J.MailAddress2 as JobAddress2
		, J.MailCity as JobCity
		, J.MailState as JobState
		, J.MailZip as JobZip
		, J.JobPhone as JobPhone
		, J.ContactCode
		, J.ProjectMgr
		, jmp.Email as PMEmail
		,(jmp.Name) as ProjectManager,
		v.Name as VendorName,
		t5.MailAddress AS VendorAddress, 
		t5.MailAddress2 AS VendorAddress2, 
		t5.MailCity AS VendorCity, 
		t5.MailState AS VendorState, 
        t5.MailZip AS VendorZip,
		c.Name as OurCompany, 
		c.HQCo as CompanyNumber 
		, COALESCE(t5.EMail,pp.EMail,'') as VendorEmail
		, t5.Phone as VendorPhone
		, COALESCE(pp.FirstName + ' ' + pp.LastName,'') as VendorContactName  
		,I.SLItem 
		,I.SLItemDescription
		,I.SLItemType
		,I.Phase
		,I.CostType
		,I.Units
		,FORMAT(I.UnitCost, 'C', 'en-us') as UnitCost
		,I.UM
		,FORMAT(I.Amount, 'C', 'en-us') as Amount
		,FORMAT(T.SLTotalOriginal,'C','en-us')  as SLTotalOriginal
		,FORMAT(T.SLAmtPrior + T.PMSLAmtPrior,'C','en-us') as AmountSubCOPrevious
		,FORMAT(T.SLTotalOriginal + T.SLAmtPrior + T.PMSLAmtPrior,'C','en-us') as CurrentSubcontract
		,FORMAT(T.PMSLAmtCurrent, 'C', 'en-us') as AmountSubCOCurrent 
		,FORMAT((T.SLTotalOriginal + T.SLAmtPrior + T.PMSLAmtPrior+T.PMSLAmtCurrent), 'C','en-us') as TotalPendingSubcontract
		,ct.Description as CostTypeValue
		
FROM dbo.PMSubcontractCO SCO INNER JOIN
      dbo.PMSL I on SCO.SL = I.SL and SCO.SLCo = I.SLCo and SCO.SubCO = I.SubCO  /*<-New Value*/ /*I.SLItem  <-OLD VALUE*/ LEFT OUTER JOIN
      dbo.HQCO AS c ON I.SLCo = c.HQCo /*and I.VendorGroup = c.VendorGroup  NOT NEEDED  Vendor group can be retrieved this way.  Should not be used for join.*/ LEFT OUTER JOIN 
         dbo.APVM AS v ON I.VendorGroup = v.VendorGroup and I.Vendor = v.Vendor  LEFT OUTER JOIN /*This isn't wrong but we might be able to do it better.*/
      dbo.bJCJM J on SCO.Project = J.Job and SCO.PMCo = J.JCCo LEFT outer JOIN /**/
      dbo.JCMP jmp on J.ProjectMgr = jmp.ProjectMgr and J.JCCo = jmp.JCCo  Left outer JOIN /**/
      dbo.JCMP pm on J.ProjectMgr = pm.ProjectMgr and J.JCCo = pm.JCCo  Left outer Join
      dbo.PMDistribution ps ON ps.SLCo = SCO.SLCo and ps.SL = SCO.SL and ps.Send='Y' and ps.CC='N'  LEFT OUTER JOIN
      dbo.PMPM pp on pp.FirmNumber = ps.SentToFirm and  pp.VendorGroup = ps.VendorGroup and pp.ContactCode = ps.SentToContact LEFT OUTER JOIN
      dbo.PMFM t5 ON t5.VendorGroup = pp.VendorGroup and t5.FirmNumber= pp.FirmNumber and t5.Vendor = ps.SentToFirm LEFT OUTER JOIN
      dbo.PMSCOTotal T on T.SL = SCO.SL and T.SLCo = SCO.SLCo and T.SubCO = SCO.SubCO LEFT OUTER JOIN
      dbo.JCCT ct on I.CostType = ct.CostType and I.PhaseGroup = ct.PhaseGroup

--where SCO.SL = '998994-00100001'


GO
GRANT SELECT ON  [dbo].[mckvwSubcontractCO] TO [public]
GRANT INSERT ON  [dbo].[mckvwSubcontractCO] TO [public]
GRANT DELETE ON  [dbo].[mckvwSubcontractCO] TO [public]
GRANT UPDATE ON  [dbo].[mckvwSubcontractCO] TO [public]
GO
