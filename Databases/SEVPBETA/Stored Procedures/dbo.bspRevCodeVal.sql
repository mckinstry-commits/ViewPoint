SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspRevCodeVal    Script Date: 8/28/99 9:33:40 AM ******/
   CREATE proc [dbo].[bspRevCodeVal]
   /******************************************
   * validate Revenue Code
   *
   * Pass;
   *	EM group and Revenue Code
   *
   * Succuss returns:
   *	0 and description from EMRC
   *
   * Error returns:
   *	1 and error message
   *******************************************/
   	(@emgroup bGroup = null, @revcode bRevCode = null,@haulcode bHaulCode = null, @haulbased bYN = null output, @msco bCompany = null output, @msg varchar(60) = null output)
   as
   	set nocount on
   	declare @rcode int,@revbased bYN,@basis tinyint,@haulum bUM,@revum bUM,@revbasis char(1)
   	select @rcode = 0
   
   if @revcode is null
   	begin
   	select @msg = 'Missing Revenue Code', @rcode = 1
   
   	goto bspexit
   	end
   
   select @msg = Description, @haulbased = HaulBased,@revbasis = Basis,@revum = WorkUM from bEMRC where EMGroup = @emgroup and RevCode = @revcode
   	if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid Revenue Code', @rcode = 1
   	end
   
   select  @basis=HaulBasis,@haulum = UM,@revbased = RevBased
   from bMSHC where MSCo=@msco and HaulCode=@haulcode
   
   if @haulbased = 'Y'
   begin
   
   if @revbased = 'Y'
   begin
   	select @rcode = 1,@msg = 'Cannot Use Rev Code based on Haul Code while Haul Code is based on Rev Code.'
   	goto bspexit
   end
   
   
   
   if  ((@basis in (1,3,4,5) and @revbasis <> 'U') or (@basis= 2 and @revbasis <> 'H')) and @revbasis is not null
   begin
   	select @rcode = 1,@msg = 'When using a Rev Code that is based on theHaul Code, the basis must be the same.'
   	goto bspexit
   end
   
   
   if  @basis <> 2 and @revum <> isnull(@haulum,@revum)
   begin
   	select @rcode = 1,@msg = 'When using a Rev Code that is based on the Haul Code, the UM must be the same.'
   	goto bspexit
   end
   
   end
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspRevCodeVal] TO [public]
GO
