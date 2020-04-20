SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 1/31/2007 9:31:36 AM ******/
   
CREATE    proc [dbo].[vspEMShopVal]
   /*************************************
   * Validates EM Shop
   *  modified 1/31/2007 TRL  return INCo
   *		Modified: 11/26/01 RM Added Shop Group 
   *		TV 02/11/04 - 23061 added isnulls
   *		DC 04/29/04 - 20981 Added validation on @co and @shop
   *
   * Pass:
   *	EM Shop
   *
   * Success returns:
   *	0 and Description, InvLoc from bEMSX
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@co bCompany, @shop varchar(20), @inco bCompany output, @invloc bLoc output, @msg varchar(60) output)
   
   as
   
   
   
   set nocount on
   
   declare @rcode int,@shopgroup bGroup
   
   select @rcode = 0
   
     if @co is null
     	begin
     	select @msg = 'Missing EM Company!', @rcode = 1
     	goto vspexit
     	end
    
     if @shop is null
     	begin
     	select @msg = 'Missing EM Shop!', @rcode = 1
     	goto vspexit
     	end
   
   
   select @shopgroup = ShopGroup from dbo.HQCO with (nolock) where HQCo = @co
   
   
   select @msg = Description, @inco = INCo, @invloc = InvLoc
   from dbo.EMSX with (nolock)
   where Shop = @shop and ShopGroup = @shopgroup
   
   if @@rowcount = 0
   	begin
   		select @msg = 'Invalid EM Shop!', @rcode = 1
   	end
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMShopVal] TO [public]
GO
