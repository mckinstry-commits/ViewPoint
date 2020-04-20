SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE      view [dbo].[brvJCJobMaster] as
---------------------------------
-- Created: ??
-- Modified: GG 07/30/07 - correct reference to DDDTShared for V6
--			 huyh 07/26/2010 - #132621: select only fields needed in JCJM
--
-- Used: PM Project Master and JC Job Master reports
--
----------------------------------
select j.JCCo,
		j.Job,
		j.Description,
		j.Contract,
		j.JobStatus,
		j.ProjectMgr,
		j.BidNumber,
		j.LockPhases,
		j.JobPhone,
		j.JobFax,
		j.MailAddress,
		j.MailCity,
		j.MailState,
		j.MailZip,
		j.MailAddress2,
		j.ShipAddress,
		j.ShipCity,
		j.ShipState,
		j.ShipZip,
		j.ShipAddress2,
		j.LiabTemplate,
		j.TaxCode,
		j.InsTemplate,
		j.MarkUpDiscRate,
		j.PRLocalCode,
		j.PRStateCode,
		j.Certified,
		j.EEORegion,
		j.SMSACode,
		j.CraftTemplate,
		j.ProjMinPct,
		j.Notes,
		j.SLCompGroup,
		j.POCompGroup,
		j.ArchEngFirm,
		j.OTSched,
		j.PriceTemplate,
		j.HaulTaxOpt,
		j.GeoCode,
		j.BaseTaxOn,
		j.OurFirm,
		j.AutoAddItemYN,
		j.WghtAvgOT,
		j.HrsPerManDay,
		j.AutoGenSubNo,
		j.SecurityGroup,
		j.DefaultStdDaysDue,
		j.DefaultRFIDaysDue,
		j.UpdateAPActualsYN,
		j.UpdateMSActualsYN,
		j.RateTemplate,
		j.RevGrpInv,
		--j.RevGrpPO,
		j.MailCountry,
		j.ShipCountry,
		j.ApplyEscalators,
		j.CertDate,
		j.ClosePurgeFlag,
		j.ContactCode,
		j.TaxGroup,
		j.UpdatePlugs,
		j.UseTaxYN,
		j.VendorGroup,		
	    c.PRCo, d.Secure 
From dbo.JCJM j (nolock)
Left Join JCCO c ( nolock)  ON  j.JCCo = c.JCCo
Left Outer Join dbo.DDDTShared d (nolock) on Datatype = 'bJob'





GO
GRANT SELECT ON  [dbo].[brvJCJobMaster] TO [public]
GRANT INSERT ON  [dbo].[brvJCJobMaster] TO [public]
GRANT DELETE ON  [dbo].[brvJCJobMaster] TO [public]
GRANT UPDATE ON  [dbo].[brvJCJobMaster] TO [public]
GRANT SELECT ON  [dbo].[brvJCJobMaster] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvJCJobMaster] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvJCJobMaster] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvJCJobMaster] TO [Viewpoint]
GO
