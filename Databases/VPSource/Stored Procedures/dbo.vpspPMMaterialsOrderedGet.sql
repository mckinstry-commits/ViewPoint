SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMaterialsOrderedGet]
/************************************************************
* CREATED:		02/06/08  CHS
*
* USAGE:
*   Returns the PM Materials Ordered
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job
*   
************************************************************/	
(@JCCo bCompany, @Job bJob, @KeyID int = Null)

AS

SET NOCOUNT ON;

Select
m.PMCo, m.Project, m.Seq, m.RecordType, m.PCOType, m.PCO, m.PCOItem, 
m.ACO, m.ACOItem, m.MaterialGroup, m.MaterialCode, 
m.MtlDescription, m.PhaseGroup, m.Phase, 

p.Description as 'PhaseDescription', 

m.CostType, 

ct.Description as 'CostTypeDescription',

m.MaterialOption, 
m.VendorGroup, m.Vendor, 

f.Name as 'VendorName', 

m.POCo, m.PO, 

o.Description as 'PODescription',

m.POItem, 

i.Description as 'POItemDescription',

m.RecvYN, 

case m.RecvYN
	when 'Y' then 'Yes'
	when 'N' then 'No'
end as 'ReceiveYesNo',

m.Location, 

l.Description as 'LocationDescription',

m.MO, m.MOItem, m.UM, m.Units, m.UnitCost, m.ECM, m.Amount, m.ReqDate, 
m.InterfaceDate, m.TaxGroup, m.TaxCode, 

t.Description as 'TaxCodeName',

m.TaxType, m.SendFlag, m.Notes, 
m.RequisitionNum, m.MSCo, m.Quote, m.INCo, m.UniqueAttchID, m.RQLine, 
m.IntFlag, m.KeyID

From PMMF m with (nolock)
		Left Join JCCT ct with (nolock) on ct.PhaseGroup=m.PhaseGroup 
			and ct.CostType = m.CostType
		Left Join JCJP p with (nolock) on p.JCCo=m.PMCo 
			and p.Job=m.Project 
			and p.PhaseGroup=m.PhaseGroup 
			and p.Phase=m.Phase
		Left  Join PMPL l with (nolock) on m.PMCo=l.PMCo 
			and m.Project=l.Project 
			and m.Location=l.Location
		left join APVM f with (nolock) on m.Vendor = f.Vendor and f.VendorGroup = m.VendorGroup
		left join HQTX t with (nolock) on m.TaxGroup = t.TaxGroup and m.TaxCode = t.TaxCode
		left join POHD o with (nolock) on m.PMCo = o.POCo and m.PO = o.PO
		left join POIT i with (nolock) on m.PMCo = i.POCo and m.PO = i.PO and m.POItem = i.POItem

Where m.PMCo=@JCCo and m.Project = @Job and m.InterfaceDate is not null
GO
GRANT EXECUTE ON  [dbo].[vpspPMMaterialsOrderedGet] TO [VCSPortal]
GO
