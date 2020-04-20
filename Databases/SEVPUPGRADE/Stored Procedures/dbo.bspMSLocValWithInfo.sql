SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspMSLocValWithInfo]
   /***************************************************************************
   * Created By:   GG 02/07/02
   * Modified By:
   *
   * Used by MS Invoice Edit to validate Location and return CM info for auto payments
   *
   * Input:
   *	@co				MS/IN Company #
   *	@locgroup		Location Group restriction, may be null
   *	@loc			Location to validate
   *
   * Output:
   *	@cmco			CM Co# used for payments
   *	@cmacct			CM Account used for payments
   *	@msg			Location description or error message
   *
   * Returns:
   *	0 = success, 1 = error
   *****************************************************************************/
   (@co bCompany = null, @locgroup bGroup = null, @loc bLoc = null, @cmco bCompany output,
    @cmacct bCMAcct output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @arco bCompany, @arcmco bCompany, @arcmacct bCMAcct, @inlmgroup bGroup,
   	@inlmcmco bCompany, @inlmcmacct bCMAcct
   
   select @rcode = 0
   
   if @co is null
       begin
       select @msg = 'Missing Company!', @rcode = 1
       goto bspexit
       end
   if @loc is null
       begin
       select @msg = 'Missing Location!', @rcode = 1
       goto bspexit
       end
   
   -- get AR Co# from MS Company
   select @arco = ARCo from bMSCO where MSCo = @co
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid MS Company # ' + convert(varchar,@co), @rcode = 1
   	goto bspexit
   	end
   -- get default CM info from AR Company
   select @arcmco = CMCo, @arcmacct = CMAcct
   from bARCO where ARCo = @arco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid AR Company assigned in MS Co# ' + convert(varchar,@co), @rcode = 1
   	goto bspexit
   	end
   
   -- validate IN Location
   select @msg = Description, @inlmgroup = LocGroup, @inlmcmco = CMCo, @inlmcmacct = CMAcct
   from bINLM
   where INCo = @co and Loc = @loc
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Location!', @rcode = 1
       goto bspexit
       end
   if @locgroup is not null and @inlmgroup <> @locgroup
       begin
       select @msg = 'Location not set up for Location Group ' + convert(varchar,@locgroup), @rcode = 1
       goto bspexit
       end
   
   -- CM Co# and CM Account may be orverridden by Location
   select @cmco = isnull(@inlmcmco,@arcmco), @cmacct = isnull(@inlmcmacct, @arcmacct)
   
   bspexit:
       if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSLocValWithInfo] TO [public]
GO
