SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspHQPMGroupCheck]
  /*************************************
  * Checks for matching Vendor Group and Phase Group in PMCO.
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
  	(@co bCompany, @vendorgroup bGroup = null, @phasegroup bGroup = null, @msg varchar(60) output)
  as 
  	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	select @msg = null

  	if @co is null
  	begin
	  	select @msg = 'Missing HQ Company', @rcode = 1
	  	goto bspexit
  	end

	if exists(select 1 from PMCO where PMCo = @co)
	begin
	  	if not exists(select 1 from PMCO where PMCo = @co and VendorGroup = @vendorgroup and PhaseGroup = @phasegroup)
		begin
			select @msg = 'PMCO Vendor Group or Phase Group differs.', @rcode = 1
		end
  	end

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQPMGroupCheck] TO [public]
GO
