SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 4/16/2002 10:14:43 AM ******/
    
    
    /****** Object:  Stored Procedure dbo.bspEMShopVal    Script Date: 8/28/99 9:34:31 AM ******/
    CREATE    proc [dbo].[bspEMShopValForWOInit]
    /*************************************
    * Validates EM Shop
    *		Modified: TV 02/11/04 - 23061 added isnulls
    *
    *
    * Pass:
    *	EM Shop
    *
    * Success returns:
    *	0 and Description, InvLoc and INCo from bEMSX
    *
    * Error returns:
    *	1 and error message
    **************************************/
    (@co bCompany, 
   @shop varchar(20) = null, 
   @invloc bLoc output, 
   @inco bCompany output,
   @msg varchar(60) output)
    
    as
    
    
    
    set nocount on
    
    declare @rcode int,@shopgroup bGroup
    
    select @rcode = 0
    
    select @shopgroup = ShopGroup from bHQCO where HQCo = @co
    
    select @msg = Description, @invloc = InvLoc, @inco = INCo
    from bEMSX
    where Shop = @shop and ShopGroup = @shopgroup
    
    if @@rowcount = 0
    	begin
    	select @msg = 'Not a valid Shop', @rcode = 1
    	end
    
    bspexit:
    	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMShopValForWOInit]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMShopValForWOInit] TO [public]
GO
