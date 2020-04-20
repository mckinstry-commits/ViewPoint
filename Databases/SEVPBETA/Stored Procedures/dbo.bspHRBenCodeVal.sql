SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRBenCodeVal    Script Date: 2/4/2003 6:46:36 AM ******/
   
   
   /****** Object:  Stored Procedure dbo.bspHRBenCodeVal    Script Date: 8/28/99 9:32:49 AM ******/
   CREATE   procedure [dbo].[bspHRBenCodeVal]
   /*************************************
   * validates HR Benefit Codes
   *
   *	Modified 6/28/01 MH Per issue 12365
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   BenCode - Benefit Code to be Validated
   *
   *
   * Success returns:
   *	Description
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @BenCode varchar(10), @UpdatePRYN bYN output, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @BenCode is null
   	begin
   	select @msg = 'Missing Benefit Code', @rcode = 1
   	goto bspexit
   	end
   
   --Issue 12365 - Return UpdatePRYN to HRBenefitCodes.  mh 6/28
   --select @msg = Description from HRBC where HRCo = @HRCo and BenefitCode = @BenCode
   select @msg = Description, @UpdatePRYN = UpdatePRYN from HRBC where HRCo = @HRCo and BenefitCode = @BenCode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HR Benefit Code.', @rcode = 1
           goto bspexit
         	end
    
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBenCodeVal] TO [public]
GO
