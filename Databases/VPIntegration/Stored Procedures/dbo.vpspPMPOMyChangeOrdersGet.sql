SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMPOMyChangeOrdersGet]
/************************************************************
* CREATED:		CHS		7/09/07
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, Vendor, and VendorGroup from pUsers --%Vendor% & %VendorGroup%
*
************************************************************/
(@JCCo bCompany, @Job bJob, @Vendor bVendor, @VendorGroup bGroup,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select
c.PMCo, c.Project, c.Seq, c.RecordType, c.PCOType, c.PCO, c.PCOItem, 
c.ACO, c.ACOItem, c.MaterialGroup, c.MaterialCode, 
c.MtlDescription, c.PhaseGroup, c.Phase, c.CostType, c.MaterialOption, 
c.VendorGroup, c.Vendor, c.POCo, c.PO, c.POItem, c.RecvYN, c.Location, 
c.MO, c.MOItem, c.UM, c.Units, c.UnitCost, c.ECM, c.Amount, c.ReqDate, 
c.InterfaceDate, c.TaxGroup, c.TaxCode, c.TaxType, c.SendFlag, c.Notes, 
c.RequisitionNum, c.MSCo, c.Quote, c.INCo, c.UniqueAttchID, c.RQLine, 
c.IntFlag, c.KeyID

from PMMF c

where c.PMCo = @JCCo and c.Project = @Job and c.Vendor = @Vendor 
and c.VendorGroup = @VendorGroup
and c.KeyID = IsNull(@KeyID, c.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspPMPOMyChangeOrdersGet] TO [VCSPortal]
GO
