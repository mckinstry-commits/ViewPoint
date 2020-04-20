SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQDRCheckStatusInUse]
  /*************************************
  * Checks for existing status in HQDR.
  *
  * Pass:
  *	status code to check for in HQDR
  *
  * Success returns:
  *	0
  *
  * Error returns:
  *	1
  **************************************/
  	(@status bStatus)
  as 
  	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	  
	if exists(select top 1 1 from HQDR where rtrim(Status) = @status)
		select @rcode = 1
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDRCheckStatusInUse] TO [public]
GO
