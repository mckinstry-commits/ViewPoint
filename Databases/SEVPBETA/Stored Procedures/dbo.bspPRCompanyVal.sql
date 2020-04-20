SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCompanyVal    Script Date: 8/28/99 9:35:30 AM ******/
   /****** Object:  Stored Procedure dbo.bspPRCompanyVal    Script Date: 2/12/97 3:25:03 PM ******/
   CREATE  proc [dbo].[bspPRCompanyVal]
   /*************************************
   * MODIFIED BY:	EN 10/7/02 - issue 18877 change double quotes to single
   *
   * validates PR Company number and returns Description from HQCo
   *
   * Pass:
   *	PR Company number
   *
   * Success returns:
   *	0 and Company name from bPRCO
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@prco bCompany = 0, @msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @prco = 0
   	begin
   	select @msg = 'Missing PR Company#', @rcode = 1
   	goto bspexit
   	end
   
   if exists(select * from bPRCO where @prco = PRCo)
   	begin
   	select @msg = Name from bHQCO where HQCo = @prco
   	goto bspexit
   	end
   else
   	begin
   	select @msg = 'Not a valid PR company ', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCompanyVal] TO [public]
GO
