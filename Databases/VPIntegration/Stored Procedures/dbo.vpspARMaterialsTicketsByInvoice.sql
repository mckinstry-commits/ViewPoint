SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspARMaterialsTicketsByInvoice]
/************************************************************
* CREATED:		8/7/07		CHS
* MODIFIED:		12/20/07	CHS
*		TJL 03/06/08 - Issue #127077, International Addresses
*
* USAGE:
*   Returns the AR Invoice Line Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    Mth, Invoice 
*
************************************************************/
(@Mth bMonth, @Invoice varchar(10), @KeyID int = Null)

AS
	SET NOCOUNT ON;
	
select 
i.MSCo, i.Mth, i.MSTrans, i.HaulTrans, i.SaleDate, i.Ticket, i.FromLoc, 
i.VendorGroup, i.MatlVendor, i.SaleType, i.CustGroup, i.Customer, i.CustJob, 
i.CustPO, i.PaymentType, i.CheckNo, i.Hold, i.JCCo, i.Job, i.PhaseGroup, 
i.INCo, i.ToLoc, i.MatlGroup, 

i.Material, 

m.Description as 'MaterialDescription',

i.UM, i.MatlPhase, i.MatlJCCType, 
i.GrossWght, i.TareWght, i.WghtUM, i.MatlUnits, i.UnitPrice, i.ECM, 
i.MatlTotal, i.MatlCost, i.HaulerType, i.HaulVendor, i.Truck, i.Driver, 
i.EMCo, i.Equipment, i.EMGroup, i.PRCo, i.Employee, i.TruckType, i.StartTime, 
i.StopTime, i.Loads, i.Miles, i.Hours, i.Zone, i.HaulCode, i.HaulPhase, 
i.HaulJCCType, i.HaulBasis, i.HaulRate, i.HaulTotal, i.PayCode, i.PayBasis, 
i.PayRate, i.PayTotal, i.RevCode, i.RevBasis, i.RevRate, i.RevTotal, 
i.TaxGroup, i.TaxCode, i.TaxType, i.TaxBasis, i.TaxTotal, i.DiscBasis, 
i.DiscRate, i.DiscOff, i.TaxDisc, i.Void, i.MSInv, i.APRef, i.VerifyHaul, 
i.BatchId, i.InUseBatchId, i.AuditYN, i.Purge, i.Changed, i.ReasonCode, 
i.ShipAddress, i.City, i.State, i.Zip, i.Country, i.UniqueAttchID, i.APCo, i.APMth, 
i.MatlAPCo, i.MatlAPMth, i.MatlAPRef --, i.KeyID

from MSTD i with (nolock)
	left join HQMT m with (nolock) on i.MatlGroup = m.MatlGroup and i.Material = m.Material
	
where i.Mth = @Mth and i.MSInv = @Invoice --and i.KeyID = IsNull(@KeyID, i.KeyID)

GO
GRANT EXECUTE ON  [dbo].[vpspARMaterialsTicketsByInvoice] TO [VCSPortal]
GO
