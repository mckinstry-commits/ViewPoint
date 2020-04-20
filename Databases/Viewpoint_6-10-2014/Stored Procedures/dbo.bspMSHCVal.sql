SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSHCVal]
   /*************************************
   * Created By:   GF 09/23/2000
   * Modified By:
   *
   * validates MS Haul Code
   *
   * Pass:
   *	MSCo,HaulCode
   *
   * Success returns:
   *	0 and Description from bMSHC
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @haulcode bHaulCode = null,@emgroup bGroup = null , @revcode bRevCode = null, @revbased bYN = null output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int,@haulbased bYN,@revbasis char(1),@basis tinyint,@revum bUM, @haulum bUM
   
   select @rcode=0
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @haulcode is null
   	begin
   	select @msg = 'Missing MS Haul Code', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=Description, @revbased = RevBased,@basis = HaulBasis,@haulum = UM from bMSHC where MSCo=@msco and HaulCode=@haulcode
   if @@rowcount = 0
       begin
       select @msg = 'Not a valid MS Haul Code', @rcode = 1
       goto bspexit
       end
   
   select @haulbased = HaulBased,@revbasis = Basis,@revum = WorkUM from bEMRC where EMGroup = @emgroup and RevCode = @revcode
   
   if @revbased = 'Y'
   begin
   
   if @haulbased = 'Y'
   begin
   	select @rcode = 1,@msg = 'Cannot Use Haul Code based on Rev Code while Rev Code is based on Haul Code.'
   	goto bspexit
   end
   
   if  ((@basis in (1,3,4,5) and @revbasis <> 'U') or (@basis= 2 and @revbasis <> 'H')) and @revbasis is not null
   begin
   	select @rcode = 1,@msg = 'When using a Haul Code that is based on the Rev Code, the basis must be the same.'
   	goto bspexit
   end
   
   if @basis in (3,4,5) and @haulum <> @revum
   begin
   
   	select @rcode = 1,@msg = 'When using a Haul Code that is based on the Rev Code, the UM must be the same.'
   	goto bspexit
   end
   
   end
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHCVal] TO [public]
GO
