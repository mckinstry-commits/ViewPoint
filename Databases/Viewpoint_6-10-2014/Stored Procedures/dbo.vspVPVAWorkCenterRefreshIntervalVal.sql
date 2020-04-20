SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspVPVAWorkCenterRefreshIntervalVal]
   /*************************************
   *Created by HH 03/28/13
   *Modified by 
   *			
   *
   * Usage:
   *	validates Refresh Interval
   *
   * Input params:
   *	@RefreshInterval	RefreshInterval to be validated
   *
   *Output params:
   *	@msg		error text
   *
   * Return code:
   *	0 = success, 1= failure
   *
   **************************************/
   	(@RefreshInterval int = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @RefreshInterval is null
   	begin
   	select @msg = 'Missing Refresh Interval.', @rcode = 1
   	goto bspexit
   	end
   
   
   if @RefreshInterval <= 0 or isnumeric(@RefreshInterval) = 0
   	begin
   	select @msg = 'Not a valid Refresh Interval. Must be at least 1 minute.', @rcode = 1
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspVPVAWorkCenterRefreshIntervalVal] TO [public]
GO
