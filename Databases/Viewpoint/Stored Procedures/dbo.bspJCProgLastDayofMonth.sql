SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCProgActualDateVal    Script Date: 9/08/03 ******/
   CREATE    proc [dbo].[bspJCProgLastDayofMonth]
   /****************************************************************************
   * CREATED BY:	GF 09/08/2003
   * MODIFIED BY: TV - 23061 added isnulls 
   *
   * USAGE:
   * 	Returns last day of month for batch, warning if actual > last day of batch month - JCPP
   *
   * INPUT PARAMETERS:
   *	Month
   *	
   * OUTPUT PARAMETERS:
   *	Last Day of Month
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@mth bMonth = null, @actualdate bDate = null, @lastdayofmonth bDate output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @newmonth bMonth
   
   set @rcode = 0
   
   /*
   if @mth is null
   	begin
   	select @msg = 'Missing Batch Month!', @rcode = 1
   	goto bspexit
   	end
   
   if @actualdate is null
   	begin
   	select @msg = 'Missing Actual Date!', @rcode = 1
   	goto bspexit
   	end
   */
   
   set @newmonth = DATEADD ( month , 1, @mth ) 
   
   set @lastdayofmonth = DATEADD (DAY, -1, @newmonth)
   
   if @actualdate < @mth or @actualdate > @lastdayofmonth
   	begin
   	select @msg = 'Actual date is outside Batch Month date range.', @rcode = 1
   	end
   	
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCProgLastDayofMonth] TO [public]
GO
