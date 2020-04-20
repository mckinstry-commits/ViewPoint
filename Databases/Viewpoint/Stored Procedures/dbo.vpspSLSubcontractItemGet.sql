SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLSubcontractItemGet]
/************************************************************
* CREATED:     3/13/07  CHS
*				GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*
* USAGE:
*   gets Subcontract Headers
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    SLCo and SL
*
************************************************************/
(@SLCo bCompany, @SL VARCHAR(30),
	@KeyID int = Null)

AS
SET NOCOUNT ON;

select 
i.SLCo,
i.SL,
i.SLItem,
i.ItemType,
i.Addon,
i.AddonPct,
i.JCCo,
i.Job,
i.PhaseGroup,
i.Phase,
i.JCCType,
i.Description,
i.UM,
i.GLCo,
i.GLAcct,
i.WCRetPct,
i.SMRetPct,
i.VendorGroup,
i.Supplier,
i.OrigUnits,
i.OrigUnitCost,
i.OrigCost,
i.CurUnits,
i.CurUnitCost,
i.CurCost,
i.StoredMatls,
i.InvUnits,
i.InvCost,
i.InUseMth,
i.InUseBatchId,
i.Notes,
i.AddedMth,
i.AddedBatchID,
i.UniqueAttchID,
i.Notes 'SubItemNotes',
i.KeyID

from SLIT i with (nolock)

where i.SLCo = @SLCo and i.SL = @SL
and i.KeyID = IsNull(@KeyID, i.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspSLSubcontractItemGet] TO [VCSPortal]
GO
