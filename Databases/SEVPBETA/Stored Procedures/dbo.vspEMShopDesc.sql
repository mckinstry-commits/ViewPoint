SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMShopDesc    Script Date: 05/03/2005 ******/
CREATE  proc [dbo].[vspEMShopDesc]
/*************************************
 * Created By:	DANF 03/19/07
 * Modified By:
 *
 *
 * USAGE:
 * Called from EM Shop to get key description for Shop. 
 *
 *
 * INPUT PARAMETERS
 * @emco		EM Company
 * @shop		EM Shop
 * 
 *
 * Success returns:
 *	0 and Description from EMSX
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@shopgroup bGroup, @shop varchar(20), @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

if isnull(@shop,'') = ''
	begin
   	select @msg = 'Shop cannot be null.', @rcode = 1
   	goto bspexit
	end

-- -- -- get shop description
select @msg=Description
from EMSX with (nolock) 
where ShopGroup=@shopgroup and Shop=@shop

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMShopDesc] TO [public]
GO
