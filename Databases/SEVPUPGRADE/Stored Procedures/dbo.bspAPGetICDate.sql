SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspAPGetICDate]
   /*************************************
   * CREATED BY    : MAV  07/09/2003 for Issue #15528
   * LAST MODIFIED : 
   *
   * Gets ICRptDate from bAPFT - the last I.C. reported activity date  
   * It looks at the previous year if there is no bAPFT for the current
   * year or no ICRptDate for the current year. 
   *
   * Pass:
   *	APCompany
   *
   * Returns:
   *	ICRptDate
   *
   * Success returns:
   *   0
   *
   * Error returns:
   *	1 
   **************************************/
   (@APCo bCompany, @ICRptDate varchar(11) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @year as varchar (4)
   
   select @rcode = 0
   SELECT @year = DATEPART(yy, GETDATE()) 
   
   
   select @ICRptDate = max(ICRptDate)
   FROM bAPFT with (nolock)
   WHERE APCo = @APCo and datepart(yy,YEMO) = @year
   if @@rowcount = 0 or @ICRptDate is null
   begin
   	SELECT @year = DATEPART(yy, GETDATE())-1 
   	select @ICRptDate = max(ICRptDate)
   	FROM bAPFT with (nolock)
   	WHERE APCo = @APCo and datepart(yy,YEMO) = @year
   end
   
   if @ICRptDate is null select @ICRptDate = ''
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPGetICDate] TO [public]
GO
