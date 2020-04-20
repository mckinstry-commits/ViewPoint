SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHRBenGrpVal    Script Date: 2/4/2003 6:49:10 AM ******/
   /****** Object:  Stored Procedure dbo.bspHRBenGrpVal   ******/
   CREATE  procedure [dbo].[bspHRBenGrpVal]
   /*************************************
   * validates HR Benefit Groups
   *
   * Created by: ae 12/5/99
   *
   * Pass:
   *	HRCo - Human Resources Company
   *   BenefitGroup - Benefit Group to be Validated
   *
   *
   * Success returns:
   *	Description
   *
   * Error returns:
   
   *	1 and error message
   **************************************/
   	(@HRCo bCompany = null, @BenefitGroup varchar(10), @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int
      	select @rcode = 0
   
   if @HRCo is null
   	begin
   	select @msg = 'Missing HR Company', @rcode = 1
   	goto bspexit
   	end
   
   if @BenefitGroup is null
   	begin
   	select @msg = 'Missing Benefit Group', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from HRBG where HRCo = @HRCo and BenefitGroup = @BenefitGroup
   	if @@rowcount = 0
   		begin
   		select @msg = 'Not a valid HR Benefit Group', @rcode = 1
           goto bspexit
         	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRBenGrpVal] TO [public]
GO
