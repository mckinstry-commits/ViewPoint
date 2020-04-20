SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMGetAPCOFlags]
   /*************************************
   * CREATED BY    : RBT  06/12/2003 for Issue #17557
   * LAST MODIFIED : 
   *
   * Gets PM AP Vendor related flags
   *
   * Pass:
   *	APCompany
   *
   * Returns:
   *	PMVendAddYN
   *	PMVendUpdYN
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@APCo bCompany, @PMInsertAP varchar(1) output, @PMUpdateAP varchar(1) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 1
   
   select @PMInsertAP = PMVendAddYN, @PMUpdateAP = PMVendUpdYN
   FROM APCO
   WHERE APCo = @APCo
   
   select @rcode = 0
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMGetAPCOFlags] TO [public]
GO
