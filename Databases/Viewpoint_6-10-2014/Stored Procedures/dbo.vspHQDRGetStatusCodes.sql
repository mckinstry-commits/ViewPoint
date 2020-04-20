SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspHQDRGetStatusCodes]
  /********************************************************
  * CREATED BY: 	RT 12/8/05
  * MODIFIED BY:
  *
  * USAGE:
  * 	Returns the status codes from HQDS.
  *
  * RETURN VALUE:
  * 	0 			- Success
  *	    1 & message - Failure
  *
  **********************************************************/
  
  	
  as 
  	set nocount on
  	declare @rcode int
  	select @rcode = 1
  	
  	Select Status, Description from HQDS order by Seq

	select @rcode = 0

  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDRGetStatusCodes] TO [public]
GO
