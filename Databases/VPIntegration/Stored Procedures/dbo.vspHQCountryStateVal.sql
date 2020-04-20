SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspHQCountryStateVal]	
/******************************************************
* CREATED BY:	mh 3/3/2008 
* MODIFIED By:  MV 3/12/08 - isnull wrapped @country, @state for errmsg
*				GG 5/27/08 - #128324 - allow missing Country and/or State params		
*
* Usage: Validates Country, State, and combination when both are available.  If Country is not
*		passed use default Country from HQ Company.
*	
*
* Input params:
*	@hqco		Company #
*	@country	Country 
*	@state		State
*
* Output params:
*	@msg		State name or error message
*
* Return code:
*	0 = success, 1 = failure
*******************************************************/

(@hqco bCompany = null, @country char(2) = null, @state varchar(4) = null, @msg varchar(100) output)

as 
set nocount on
declare @rcode int

select @rcode = 0

-- get default Country assigned by company, if not passed (optional) 
if @country is null
	select @country = DefaultCountry from dbo.bHQCO (nolock) where HQCo = @hqco

-- must have Country, passed or pulled from bHQCO
if @country is null
	begin
	select @msg = 'Missing Country, must be setup in HQ Company!', @rcode = 1
	goto vspexit
	end
	
-- validate Country (if not passed, must be in bHQCO)	
if not exists(select top 1 1 from dbo.bHQCountry (nolock) where Country = @country)
	begin
	select @msg = @country + ' is an invalid Country!', @rcode = 1
	goto vspexit
	end
	
-- validate State/Country commbination, if both available
if @state is not null
	begin
	select @msg = Name from dbo.bHQST (nolock) where State = @state and Country = @country
	if @@rowcount = 0
		begin
		select @msg = @state + ' and ' + @country + ' is an invalid State/Country combination!', @rcode = 1
		goto vspexit
		end
	end
	 
vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQCountryStateVal] TO [public]
GO
