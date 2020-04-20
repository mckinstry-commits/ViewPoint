SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspEFTRoutingIDVal]
	/******************************************************
	* CREATED BY:	MarkH 10/10/2008 
	* MODIFIED By:	mh 12/15/08.  Need to pass country into bspEFTRouteIDVal  
	*				EN 2/24/2011 #143236 change input params on bspEFTRoutIDVal to pass in co/routeid rather than routeid/default country
	*
	* Usage:	Validates Routing number for EFT.  Country specific.
	*		
	*
	* Input params:  
	*				@co Company
	*				@routid Routing ID
	*
	* Output params:
	*	@msg		Description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
	(@co bCompany, @routeid varchar(9) = null, @msg varchar(60) = null output)   
	
	as 

	set nocount on

	declare @rcode int, @defaultcountry varchar(2)

	select @rcode = 0

	select @defaultcountry = DefaultCountry from HQCO where HQCo = @co

	if @defaultcountry = 'US'
	begin
		exec @rcode = bspEFTRouteIDVal @co, @routeid, @msg output
		goto vspexit
	end

	if @defaultcountry = 'AU'
	begin
		if len(@routeid) <> 6 or isnumeric(@routeid) = 0
		begin
			select @msg = 'BSB number must be 6 digits, numeric only.', @rcode = 1
			goto vspexit
		end
   
		if charindex(',', @routeid) <> 0 or
   			charindex('-',@routeid) <> 0 or
   			charindex('.',@routeid) <> 0 or
   			charindex('+',@routeid) <> 0 
   		begin
   			select @msg = 'BSB number must be 6 digits, numeric only.', @rcode = 1
   			goto vspexit
   		end
	end


	if @defaultcountry = 'CA'
	begin
		goto vspexit
	end
	 
	vspexit:

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEFTRoutingIDVal] TO [public]
GO
