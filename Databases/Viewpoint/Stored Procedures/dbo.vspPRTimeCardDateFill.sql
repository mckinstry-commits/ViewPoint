SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[vspPRTimeCardDateFill]    Script Date: 10/29/2007 09:21:12 ******/
  CREATE        proc [dbo].[vspPRTimeCardDateFill]
/*************************************
* CREATED BY	: EN 10/29/07
* MODIFIED BY	: 
*
* Returns date as description for display in PRTimeCards.
*
* Pass:
*	TCDate	Timecard Date
*
* Returns:
*	TCDate as description
*
* Error returns:
*	1 and error message
**************************************/
(@tcdate bDate, @msg varchar(10) output)

as 
 	set nocount on
  	declare @rcode int
  	select @rcode = 0
  	
select @msg = convert(varchar,@tcdate,101)


vspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTimeCardDateFill] TO [public]
GO
