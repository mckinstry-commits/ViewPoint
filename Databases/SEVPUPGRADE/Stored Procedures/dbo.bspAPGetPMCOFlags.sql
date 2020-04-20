SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPGetPMCOFlags]
   /*************************************
   * CREATED BY    : RBT  06/17/2003 for Issue #17557
   * LAST MODIFIED : 
   *
   * Gets AP PM Firm related flags
   *
   * Pass:
   *	PMCompany
   *
   * Returns:
   *	APVendUpdYN
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@PMCo bCompany, @APUpdatePM varchar(1) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 1
   
   select @APUpdatePM = APVendUpdYN
   FROM PMCO
   WHERE PMCo = @PMCo
   
   select @rcode = 0
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPGetPMCOFlags] TO [public]
GO
