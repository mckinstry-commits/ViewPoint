SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLItemValForJC    Script Date: 8/28/99 9:33:41 AM ******/
   CREATE    proc [dbo].[bspSLItemValForJC]
   /***********************************************************
    * CREATED BY  : DANF 01/10/2000
    * MODIFIED BY : RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
    *				 DANF 03/29/2005 - Issue 27498 error message needs to convert numeric to a sting.
    *				DC 6/25/10 - #135813 - expand subcontract number
    *
    * USAGE:
    * validates SL item
    *
    * INPUT PARAMETERS
    *   SLCo  SL Co to validate against
    *   SL to validate
    *   SL Item to validate
   
    *
    * OUTPUT PARAMETERS
    *
    *   @msg      error message if error occurs otherwise Description of SL
   
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
    (@slco bCompany = 0, @sl VARCHAR(30) = NULL, --bSL = null, DC #135813
    @slitem bItem=null, @msg varchar(100) output )
   as
   
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @slco is null
	begin
	select @msg = 'Missing SL Company!', @rcode = 1
	goto bspexit
	end
   
   if @sl is null
   	begin
   	select @msg = 'Missing SL!', @rcode = 1
   	goto bspexit
   	end
   
   if @slitem is null
   	begin
   	select @msg = 'Missing SL Item#!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg=SLIT.Description from SLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
   if @@rowcount=0
      begin
      select @msg='SL item ' + convert(varchar(6),isnull(@slitem,'')) + ' is not not file.', @rcode=1
      goto bspexit
      end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLItemValForJC] TO [public]
GO
