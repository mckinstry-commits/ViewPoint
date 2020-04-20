SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPRW2LocalGridFill]
    /****************************************************************************
    * Created By:	GF 07/17/2003
    * Modified By:	GF 11/06/2003 - issue #22884 - change description to electronic filing
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * 	Fills grid with state local codes to populate grid for local code 
    *	electronic filing export.
    *	PRW2Generate form
    *
    * INPUT PARAMETERS:
    *  PR Company, TaxYear, State
    *
    * OUTPUT PARAMETERS:
    *
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    *****************************************************************************/
   (@prco bCompany = null, @taxyear char(4), @state varchar(4) = null)
   as
   set nocount on
   
   declare @rcode int, @retcode int
   
   select @rcode = 0, @retcode = 0
   
   
   -- create resultset to return to form
   select distinct(a.LocalCode), b.Description, 'N'
   from PRWL a with (nolock)
   join PRLI b with (nolock) on b.PRCo=a.PRCo and b.LocalCode=a.LocalCode
   where a.PRCo=@prco and a.TaxYear=@taxyear and a.State=@state
   
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2LocalGridFill] TO [public]
GO
