SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQCustGrpGet    Script Date: 8/28/99 9:34:50 AM ******/
   CREATE    proc [dbo].[bspHQCustGrpGet]
   /********************************************************
   * CREATED BY: 	SE 4/30/97
   * MODIFIED BY:
    *				RM 02/13/04 = #23061, Add isnulls to all concatenated strings
   * USAGE:
   * 	Retrieves the Customer Group from bHQCO
   *
   * INPUT PARAMETERS:
   *	HQ Company number
   *
   * OUTPUT PARAMETERS:
   *	Customer Group from bHQCO
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   	(@hqco bCompany = 0, @CustGroup tinyint output, @msg varchar(60) output)
   as 
   	set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   
   if @hqco = 0
   	begin
   	select @msg = 'Missing HQ Company!', @rcode = 1
   	goto bspexit
   	end
   
   select @CustGroup = CustGroup from bHQCO with (nolock) where HQCo = @hqco
   if @@rowcount = 1 
      select @rcode=0
   else
      select @msg = 'HQ company does not exist!', @rcode=1, @CustGroup=0
   
   if @CustGroup is Null
      select @msg = 'Customer Group not setup for Company ' + isnull(convert(varchar(3), @hqco),'') + ' in HQ!', @rcode=1, @CustGroup=0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQCustGrpGet] TO [public]
GO
