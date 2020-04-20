SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRDLTypeDescVal    Script Date: 8/28/99 9:33:17 AM ******/
   CREATE   procedure [dbo].[bspPRDLTypeDescVal]
   /*************************************
   * Created by:  ae 4/21/99	
   * MODIFIED BY:	EN 10/8/02 - issue 18877 change double quotes to single
   *				mh 10/23/03 - issue 22737 added @rateamt1 output param
   * validates and returns D/L Type and Description from PRDL
   *
   * Pass:
   *   PRCo - Human Resources Company
   *   DLCode - Code to be Validated
   *   
   * Returns:
   *   DLType - Type
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@PRCo bCompany = null, @DLCode bEDLCode, @DLType char(1) output, @Description bDesc output,
   	@rateamt1 bUnitCost output, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @PRCo is null
   	begin
   	select @msg = 'Missing PR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @DLCode is null
   	begin
   	select @msg = 'Missing Code', @rcode = 1
   	goto bspexit
   	end
   
   --select @Description = Description, @DLType = DLType  from PRDL where PRCo = @PRCo and DLCode = @DLCode
   select @Description = Description, @DLType = DLType, @rateamt1 = RateAmt1
   from PRDL with (nolock) where PRCo = @PRCo and DLCode = @DLCode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid D/L Code.', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRDLTypeDescVal] TO [public]
GO
