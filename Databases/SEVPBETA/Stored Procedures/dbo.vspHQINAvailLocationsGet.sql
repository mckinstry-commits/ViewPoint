SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQINAvailLocationsGet]
  /*************************************
  * CREATED BY:  TRL 05/11/06
  * Modified By:
  *
  * Gets the  IN Locations 
  * Used by HQ Material Insert Locations
  *
  * Pass:
  *   INCo - Inventory Company  
  *  MatlGroup
  *  Material
  *  All Locations 
  *  Active Locations Y/N
  * Success returns: Loc and Description and Active
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
(@inco bCompany=0, @matlgroup bGroup=0, @material varchar(20)=null, @allLoc varchar(2) = 'AV', @activeloc bYN='N',  @msg varchar(256) output)
as 

set nocount on

declare @rcode int

select @rcode = 0

if IsNull(@inco,0)=0
  	begin
  	select @msg = 'Missing IN Company.', @rcode = 1
  	goto vspexit
  	end

if IsNull(@matlgroup,0)=0
  	begin
  	select @msg = 'Missing Material Group.', @rcode = 1
  	goto vspexit
  	end

if @material is null
  	begin
  	select @msg = 'Missing Material.', @rcode = 1
  	goto vspexit
  	end

If @activeloc = 'Y'
	Begin
		If @allLoc = 'AV'
			begin
				select Loc, Description,Active  
				from dbo.INLM with (nolock) 
				Inner Join HQCO with(nolock) on INLM.INCo = HQCO.HQCo
				where INCo = @inco   and Loc Not In (Select Loc From INMT  Where INCo = @inco and Material = @material and MatlGroup = @matlgroup) 
				 and HQCO.MatlGroup = @matlgroup and Active = 'Y'
			end
		If @allLoc = 'AL'
			begin
				select Loc, Description,Active
				from dbo.INLM with (nolock) 
				Inner Join HQCO with(nolock) on INLM.INCo = HQCO.HQCo
				where INCo = @inco  and Active = 'Y' and MatlGroup=@matlgroup
			end 
	End

If @activeloc = 'N'
	Begin
		If @allLoc = 'AV'
			begin
				select Loc, Description,Active  
				from dbo.INLM with (nolock) 
				Inner Join HQCO with(nolock) on INLM.INCo = HQCO.HQCo
				where INCo = @inco   and Loc Not In (Select Loc From INMT  Where INCo = @inco and Material = @material and MatlGroup = @matlgroup) 
			end
		If @allLoc = 'AL'
			begin
				select Loc, Description,Active
				from dbo.INLM with (nolock) 
				Inner Join HQCO with(nolock) on INLM.INCo = HQCO.HQCo
				where INCo = @inco and MatlGroup=@matlgroup
			end 
		End
vspexit:
		if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspHQINAvailLocationsGet]'
  		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQINAvailLocationsGet] TO [public]
GO
