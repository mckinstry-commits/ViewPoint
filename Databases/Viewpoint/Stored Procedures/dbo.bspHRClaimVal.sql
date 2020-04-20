SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRClaimVal    Script Date: 2/4/2003 6:49:56 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspHRClaimVal    Script Date: 8/28/99 9:32:49 AM ******/
   CREATE  procedure [dbo].[bspHRClaimVal]
   /*************************************
   * validates HR Codes
   *
   * Pass:
   *	HRCo - Company
   *   Claim - Claim to be Validated
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   
   	(@HRCo bCompany = null, @Claim varchar(10), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @Claim is null
   	begin
   	select @msg = 'Missing Claim Contact', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Name from HRCC where HRCo = @HRCo and ClaimContact = @Claim
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid Claim Contact.', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRClaimVal] TO [public]
GO
