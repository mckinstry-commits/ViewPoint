SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSQuoteClose]
   /****************************************************************************
   * Created By:   GF 09/20/2000
   * Modified By:	GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
   *
   * USAGE:
   *   Closes a quote select from MSQuoteClose
   *
   * INPUT PARAMETERS:
   *   MS Company, Quote
   *
   * OUTPUT PARAMETERS:
   *
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@msco bCompany = null, @quote varchar(10) = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end
   
   if @quote is null
       begin
       select @msg = 'Missing Quote', @rcode = 1
       goto bspexit
       end
   
   -- set Active flag to 'N', this will close quote
   Update bMSQH set Active = 'N'
   where MSCo=@msco and Quote=@quote
   if @@rowcount = 0
       begin
       select @msg = 'Unable to update active flag in MSQH for quote ' + isnull(@quote,'') + '.', @rcode = 1
       goto bspexit
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'') + ' - [bspMSQuoteClose]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteClose] TO [public]
GO
