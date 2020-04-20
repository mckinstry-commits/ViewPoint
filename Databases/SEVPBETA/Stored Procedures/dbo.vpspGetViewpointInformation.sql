SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE dbo.vpspGetViewpointInformation
/************************************************************
* CREATED:     SDE 9/12/2005
* MODIFIED:    
*
* USAGE:
*   Returns the HQCO and HRRM tables
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*           
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
AS
	SET NOCOUNT ON;
SELECT Address, Address2, AuditCoParams, AuditMatl, AuditTax, City, CustGroup, Customer, EMGroup, Fax, FedTaxId,
	HQCo, MatlGroup, Name, Notes, PhaseGroup, Phone, STEmpId, ShopGroup, State, TaxGroup, UniqueAttchID,
	Vendor, VendorGroup, Zip from bHQCO
select * from bHRRM


GO
GRANT EXECUTE ON  [dbo].[vpspGetViewpointInformation] TO [VCSPortal]
GO
