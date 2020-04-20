SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRBICodeVal    Script Date: 2/4/2003 6:45:00 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRBICodeVal    Script Date: 8/28/99 9:32:53 AM ******/
   CREATE     procedure [dbo].[bspHRBICodeVal]
   /*************************************
   * Returns the description of a code.
   * Created : 11/17/99 a.e.
   *	modified:  08/06/03 mh Issue 22054.
   *
   * Pass:
   *   @HRCo           HR Company
   *   @BenefitCode    Benefit Code
   *   @EDLType        (E)arning / (D)eduction / (L)iability Type
   *   @EDLCode        (E)arning / (D)eduction / (L)iability Code
   *
   * Success returns:
   *   0 and Code Description
   * Error returns:
   *	1 and error message
   **************************************/
   
   	(@HRCo bCompany = null, @BenefitCode varchar(10), @EDLType char(1),
       @EDLCode bEDLCode, @EDLTypeOut char(1) output, @CalcCat char(1) output,
   	 @msg varchar(75) output)
   as
   	set nocount on
   	declare @rcode int, @prco bCompany
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @BenefitCode is null
   	begin
   	select @msg = 'Missing Benefit Code', @rcode = 1
   	goto bspexit
   	end
   
   if @EDLType is null
   	begin
   	select @msg = 'Missing EDL Type', @rcode = 1
   	goto bspexit
   	end
   
   if @EDLCode is null
   	begin
   	select @msg = 'Missing EDL Code', @rcode = 1
   	goto bspexit
   	end
   
   select @prco = PRCo from HRCO where HRCo = @HRCo
   
   if @prco is null
   begin
   	select @msg = 'PR Company must be defined in HR Company', @rcode = 1
   	goto bspexit
   end
   
   /*
   if @EDLType = 'D'
       begin
       select @EDLTypeOut = PRDL.DLType from PRDL
           where PRDL.PRCo = @HRCo and PRDL.DLCode = @EDLCode
       Select @msg = PRDL.Description from PRDL
   	   where PRDL.PRCo = @HRCo and PRDL.DLCode = @EDLCode AND
   	      PRDL.DLType = @EDLTypeOut
       if @@rowcount = 0
        begin
   	  select @msg = 'Not a valid D/L Code!', @rcode = 1
   	  goto bspexit
   	 end
       goto bspexit
       end
   */
   
   if @EDLType = 'D'
       begin
       select @EDLTypeOut = PRDL.DLType from PRDL
           where PRDL.PRCo = @prco and PRDL.DLCode = @EDLCode
       Select @msg = PRDL.Description, @CalcCat = CalcCategory from PRDL
   	   where PRDL.PRCo = @prco and PRDL.DLCode = @EDLCode AND
   	      PRDL.DLType = @EDLTypeOut
       if @@rowcount = 0
        begin
   	  select @msg = 'Not a valid D/L Code!', @rcode = 1
   	  goto bspexit
   	 end
       goto bspexit
       end
   
   /*
   if @EDLType = 'E'
       begin
       select @EDLTypeOut = 'E'
       Select @msg = PREC.Description from PREC
   	   where PREC.PRCo = @HRCo and PREC.EarnCode = @EDLCode
       if @@rowcount = 0
        begin
   	  select @msg = 'Not a valid Earnings Code!', @rcode = 1
   	  goto bspexit
   	 end
       goto bspexit
       end
   */
   
   if @EDLType = 'E'
       begin
       select @EDLTypeOut = 'E'
       Select @msg = PREC.Description from PREC
   	   where PREC.PRCo = @prco and PREC.EarnCode = @EDLCode
       if @@rowcount = 0
        begin
   	  select @msg = 'Not a valid Earnings Code!', @rcode = 1
   	  goto bspexit
   	 end
       goto bspexit
       end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBICodeVal] TO [public]
GO
