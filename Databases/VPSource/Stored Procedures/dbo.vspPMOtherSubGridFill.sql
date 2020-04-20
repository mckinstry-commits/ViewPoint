SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************/
CREATE procedure [dbo].[vspPMOtherSubGridFill]
/************************************************************************
 * Created By:	GF 08/12/2005    
 * Modified By:    
 *
 * Purpose of Stored Procedure
 * Get list of subcontracts from SLHD for initializing other documents.
 * Called from PMOtherSubInit form.
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
select SLHD.SL, SLHD.Description
from SLHD with (nolock)
where SLHD.JCCo=@pmco and SLHD.Job=@project and SLHD.VendorGroup=@vendorgroup
and SLHD.SLCo=@apco and SLHD.Status in (0,3)
order by SLHD.SL, SLHD.Description






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMOtherSubGridFill] TO [public]
GO
