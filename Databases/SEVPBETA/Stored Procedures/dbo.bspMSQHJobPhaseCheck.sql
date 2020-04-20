SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSQHJobPhaseCheck]
   /***********************************************************
    * Created By:  GF 03/08/2000
    * Modified By: GF 03/16/2004 - #24036 check MSQD.Phase, MSMD.Phase, and MSHO.Phase added
    *
    * USAGE:
    * Checks if MS Quote Job phases exists.
    *
    * INPUT PARAMETERS
    *  MSCo    MS Company
    *  Quote   Quote to check
    *
    * RETURN VALUE
    *   0         No Records exists
    *   1         Records exists
    *****************************************************/
   (@msco bCompany = 0, @quote varchar(10), @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int
   
   select @rcode=0
   
   -- check MSJP - Quote Job Phases
   select @validcnt = count(*) from bMSJP with (nolock) where MSCo=@msco and Quote=@quote
   if @validcnt > 0
      begin
      select @msg = 'Quote Job Phases exists', @rcode = 1
      goto bspexit
      end
   
   select @validcnt = count(*) from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and Phase is not null
   if @validcnt > 0
      begin
      select @msg = 'Quote Detail has phases assigned, remove phases before changing quote type', @rcode = 1
      goto bspexit
      end
   
   select @validcnt = count(*) from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and Phase is not null
   if @validcnt > 0
      begin
      select @msg = 'Price Overrides has phases assigned, remove phases before changing quote type', @rcode = 1
      goto bspexit
      end
   
   select @validcnt = count(*) from bMSHO with (nolock) where MSCo=@msco and Quote=@quote and Phase is not null
   if @validcnt > 0
      begin
      select @msg = 'Haul Code Overrides has phases assigned, remove phases before changing quote type', @rcode = 1
      goto bspexit
      end
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHJobPhaseCheck] TO [public]
GO
