SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMSLMyPendingChangesGet]
/************************************************************
* CREATED:		CHS		7/05/07
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
c.ACO, c.ACOItem, c.Line, c.PhaseGroup, c.Phase, c.CostType, c.VendorGroup, 
c.Vendor, c.SLCo, c.SL, c.SLItem, c.SLItemDescription, c.SLItemType, 
c.SLAddon, c.SLAddonPct, c.Units, c.UM, c.UnitCost, c.Amount, c.SubCO, 
c.WCRetgPct, c.SMRetgPct, c.Supplier, c.InterfaceDate, c.SendFlag, 
c.Notes, c.SLMth, c.SLTrans, c.IntFlag, c.UniqueAttchID, c.KeyID,

isnull(c.WCRetgPct, 0) * 100 as WCRetgPctX100, isnull(c.SMRetgPct, 0) * 100 as SMRetgPctX100

from PMSL c

where c.PMCo = @JCCo and c.Project = @Job and c.Vendor = @Vendor and c.VendorGroup = @VendorGroup and
	(c.ACO is not null or c.PCO is not null) and c.InterfaceDate is null
	and c.KeyID = IsNull(@KeyID, c.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspPMSLMyPendingChangesGet] TO [VCSPortal]
GO
