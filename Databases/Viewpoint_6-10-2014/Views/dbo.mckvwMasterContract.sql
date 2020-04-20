SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE view [dbo].[mckvwMasterContract] as
SELECT      m.Title, m.Vendor, m.VendorGroup, m.Insurance as udInsurance, 
			m.SpecTandC as udSpecTandC, m.StateTandC as udStateTandC, m.ExecDate, m.OrigDate, m.BalancingYN as udBalancing, 
			m.ConsultingYN as udConsulting, m.ControlsYN as udControls, m.DesignYN as udDesign, 
			m.FacilityServicesYN as udFacility, m.ProfessionalYN as udProServYN, m.NegotiatedModYN, 
			m.LightingYN as udLighting, m.RoofingYN as udRoofing, 
			m.SafetyYN as udSafety, m.EEOYN as udEEO, m.InvoicingYN as udInvYN, m.GenTerms as udGTC, 
			m.CommissioningYN as udCommissioningYN, m.ProServSoftYN as udSoftProServ, 
			m.SupportMaintSoftYN as udSoftSupMaintYN, m.LicenseSoftYN as udSoftLicense ,
			m.HostingSoftYN as udSoftHost, m.CostPlusYN as udCostPlusYN , 
			m.FederalYN as udFederalYN, m.AddendumYN as udAddendum , m.MasInsurance as udmasIns, 
			m.CertPRPrevWageYN as udCertPRPrevYN, m.PayPerfBondYN as udPerfBondYN, m.ConstructionYN as udConstruction,
			COALESCE(me.State,'0') as StateExhibit,v.Name as VendorName,v.Address as VendorAddress,
			v.City as VendorCity,v.State as VendorState,v.Zip as VendorZip,v.Contact as VendorContactName,
			v.Phone as VendorPhone,v.EMail as VendorEmail ,c.Name as OurCompany, c.HQCo as CompanyNumber ,
			m.Sample , m.Seq
			--,me.KeyID as StateExhibitID
FROM        udMSA m LEFT OUTER JOIN 
			dbo.HQCO AS c ON m.VendorGroup = c.VendorGroup LEFT outer JOIN   
			dbo.APVM v ON m.VendorGroup = v.VendorGroup AND m.Vendor = v.Vendor LEFT outer JOIN 
			udMasterSubExhibits me ON me.Vendor = m.Vendor AND me.VendorGroup = m.VendorGroup  AND me.MasterSub = m.Seq 




GO
GRANT SELECT ON  [dbo].[mckvwMasterContract] TO [public]
GRANT INSERT ON  [dbo].[mckvwMasterContract] TO [public]
GRANT DELETE ON  [dbo].[mckvwMasterContract] TO [public]
GRANT UPDATE ON  [dbo].[mckvwMasterContract] TO [public]
GO
