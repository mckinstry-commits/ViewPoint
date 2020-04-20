SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPICRptGetAPCOInfo]
   /*************************************
   * CREATED BY    : MAV  07/06/2003 for Issue #15528
   * LAST MODIFIED : 
   *
   * Gets APCO flags: ICRptYN
   *
   * Pass:
   *	APCompany
   *
   * Returns:
   *	ICRptYN, ICRptTitle
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@APCo bCompany, @ICRptYN varchar(1) output, @ICRptName varchar(40) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   select @ICRptYN = ICRptYN, @ICRptName = ICRptTitle
   FROM APCO
   WHERE APCo = @APCo
   if @@rowcount = 0
   begin
   	select @msg = 'Invalid AP Company',@rcode = 1
   end
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPICRptGetAPCOInfo] TO [public]
GO
