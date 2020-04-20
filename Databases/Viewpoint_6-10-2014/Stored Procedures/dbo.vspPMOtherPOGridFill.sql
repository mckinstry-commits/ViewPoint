SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE procedure [dbo].[vspPMOtherPOGridFill]
/************************************************************************
 * Created By:	GF 08/12/2005    
 * Modified By:    
 *
 * Purpose of Stored Procedure
 * Get list of purchase orders from POHD for initializing other documents.
 * Called from PMOtherPOInit form.
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@pmco bCompany, @project bJob, @vendorgroup bGroup, @apco bCompany)
as
set nocount on

declare @rcode int
  
select @rcode = 0

-- -- -- return resultset of PO's from POHD where status in 0,3
select POHD.PO, POHD.Description
from POHD with (nolock)
where POHD.JCCo=@pmco and POHD.Job=@project and POHD.VendorGroup=@vendorgroup
and POHD.POCo=@apco and POHD.Status in (0,3)
order by POHD.PO, POHD.Description






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOtherPOGridFill] TO [public]
GO
