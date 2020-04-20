SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDLCodeValForEFT   **/
   CREATE   procedure [dbo].[bspPRDLCodeValForEFT]
   /*************************************
   * Created by:  MV 1/1/02	
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *
   * validates DLCode for EFT child support addenda data
   *
   * Pass:
   *   PRCo - Human Resources Company
   *   DLCode - Code to be Validated
   *   Employee - employee number
   *   
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@prco bCompany, @dlcode bEDLCode, @employee bEmployee, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @dlcode is null
   	begin
   	select @msg = 'Missing DLCode', @rcode = 1
   	goto bspexit
   	end
   
   if @employee is null
   	begin
   	select @msg = 'Missing Employee', @rcode = 1
   	goto bspexit
   	end
   
   select * from bPRED where PRCo=@prco and Employee=@employee and DLCode=@dlcode
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid DLCode for this employee', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDLCodeValForEFT] TO [public]
GO
