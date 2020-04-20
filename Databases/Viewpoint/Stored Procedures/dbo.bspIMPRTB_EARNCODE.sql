SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMPRTB_EARNCODE    Script Date: 8/28/99 9:34:28 AM ******/
   CREATE   proc [dbo].[bspIMPRTB_EARNCODE]
   /********************************************************
   * CREATED BY: 	DANF 05/16/00
   * MODIFIED BY:
   *
   * USAGE:
   * 	Retrieves PR CERT FROM PREH
   *
   * INPUT PARAMETERS:
   *	PR Company
   *   PR Employee
   *
   * OUTPUT PARAMETERS:
   *	EARNINGS CODE from bPREH
   *	Error Message, if one
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   
   (@prco bCompany = 0, @employee bEmployee, @earncode bEDLCode output, @msg varchar(60) output) as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @prco = 0
   	begin
   	select @msg = 'Missing PR Company#!', @rcode = 1
   	goto bspexit
   	end
   
   select @earncode = EarnCode
   from bPREH
   where PRCo = @prco and Employee = @employee
   
   if @@rowcount = 0
      select @msg = 'Employee is not on File.', @rcode=1, @employee=0, @earncode = null
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'Earnings Code') + char(13) + char(10) + '[bspIMPRTB_EARNCODE]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_EARNCODE] TO [public]
GO
