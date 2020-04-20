SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 5/3/2004 9:31:36 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 8/28/99 9:34:31 AM ******/
   CREATE     proc [dbo].[bspEMShopVal]
   /*************************************
   * Validates EM Shop
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
   (@co bCompany, @shop varchar(20), @invloc bLoc output, @msg varchar(60) output)
   
   as
   
   
   
   set nocount on
   
   declare @rcode int,@shopgroup bGroup
   
   select @rcode = 0
   
     if @co is null
     	begin
     	select @msg = 'Missing Company', @rcode = 1
     	goto bspexit
     	end
    
     if @shop is null
     	begin
     	select @msg = 'Missing EM Shop', @rcode = 1
     	goto bspexit
     	end
   
   
   select @shopgroup = ShopGroup from bHQCO where HQCo = @co
   
   
   select @msg = Description, @invloc = InvLoc
   from bEMSX
   where Shop = @shop and ShopGroup = @shopgroup
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Shop', @rcode = 1
   	end
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMShopVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMShopVal] TO [public]
GO
