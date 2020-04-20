SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWHTaxYearGet    Script Date: 8/28/99 9:35:29 AM ******/
   CREATE proc [dbo].[bspPRWHTaxYearGet]
   /********************************************************
   * CREATED BY: 	EN 2/9/01
   * MODIFIED BY:
   *
   * USAGE:
   * 	Retrieves most recent Tax Year initialized in PRWH.  Used in PR W2 initialization.
   *
   * INPUT PARAMETERS:
   *	@prco   Company
   *
   * OUTPUT PARAMETERS:
   *	Most recent Tax Year from PRWH
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@prco bCompany=0)
   as
   set nocount on
   
   select Year=max(TaxYear) from bPRWH where PRCo= @prco
   
   bspexit:

GO
GRANT EXECUTE ON  [dbo].[bspPRWHTaxYearGet] TO [public]
GO
