SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMMaterialsNeededGet]
/************************************************************
* CREATED:		02/06/08  CHS
* Modified By:	GF 11/16/2011 TK-10027
*
* USAGE:
*   Returns the PM Materials Needed
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

SELECT  m.PMCo
		,m.Project
		,m.Seq
		,m.RecordType
		,m.PCOType
		,m.PCO
		,m.PCOItem
		,m.ACO
		,m.ACOItem
		,m.MaterialGroup
		,m.MaterialCode
		,m.MtlDescription
		,m.PhaseGroup
		,m.Phase
		,p.Description as 'PhaseDescription' 
		,m.CostType
		,ct.Description as 'CostTypeDescription'
		,m.MaterialOption
		,m.VendorGroup
		,m.Vendor
		,f.Name as 'VendorName'
		,m.POCo
		,m.PO
		,m.POItem
		,m.RecvYN
		,case m.RecvYN
			when 'Y' then 'Yes'
			when 'N' then 'No'
			end as 'ReceiveYesNo'

		,m.Location
		,l.Description as 'LocationDescription'
		,m.MO
		,m.MOItem
		,m.UM
		,m.Units
		,m.UnitCost
		,'$' + cast(m.UnitCost as varchar(30)) as 'StringUnitCost'
		,m.ECM
		,m.Amount
		,'$' + cast(m.Amount as varchar(30)) as 'StringAmount'
		,m.ReqDate
		,m.InterfaceDate
		,m.TaxGroup
		,m.TaxCode
		,m.POTrans
		,m.POMth
		,m.TaxType
		,m.SendFlag
		,m.Notes
		,m.RequisitionNum
		,m.MSCo
		,m.Quote
		,m.INCo
		,m.UniqueAttchID
		,m.RQLine
		,m.IntFlag
		,m.KeyID

From dbo.PMMF m with (nolock)
Left Join dbo.JCCT ct with (nolock) on ct.PhaseGroup=m.PhaseGroup and ct.CostType = m.CostType
Left Join dbo.JCJP p with (nolock) on p.JCCo=m.PMCo and p.Job=m.Project and p.PhaseGroup=m.PhaseGroup and p.Phase=m.Phase
Left Join dbo.INLM l with (nolock) on m.INCo=l.INCo and m.Location=l.Loc
left join dbo.APVM f with (nolock) on m.Vendor = f.Vendor and f.VendorGroup = m.VendorGroup
Where m.PMCo=@JCCo and m.Project = @Job and m.InterfaceDate is NULL
	AND m.KeyID = ISNULL(@KeyID,m.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMMaterialsNeededGet] TO [VCSPortal]
GO
