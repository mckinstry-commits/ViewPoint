SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupVal    Script Date: 8/28/99 9:34:50 AM ******/
  CREATE  proc [dbo].[vspHQCOGroupGet]
  /*************************************
  * validates HQ VendorGroup, MatlGroup, PhaseGroup, or CustGroup
  *	Modified:	01/29/10 MV	#136500 - return APCO flag
  *				11/30/10 MV #141846 - removed APCO flag return
  *
  * Pass:
  *	HQ Group to be validated
  *
  * Success returns:
  *	0 and Group Description from bHQGP
  *
  * Error returns:
  *	1 and error message
  **************************************/
  	(@co bCompany, @matlgroup bGroup output, @phasegroup bGroup output, 
	@vendorgroup bGroup output, @customergroup bGroup output, @emgroup bGroup output, 
	@taxgroup bGroup output,@msg varchar(60) output)
  as 
  	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	
  if @co is null
  	begin
  	select @msg = 'Missing HQ Company', @rcode = 1
  	goto bspexit
  	end
  
  select @matlgroup =MatlGroup, @phasegroup =PhaseGroup,
	@vendorgroup =VendorGroup, @customergroup =CustGroup , @emgroup =EMGroup,
	@taxgroup =TaxGroup from HQCO with (nolock) where HQCo = @co 
  	if @@rowcount = 0
  		begin
  		select @msg = 'Error getting group info', @rcode = 1
  		end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCOGroupGet] TO [public]
GO
