SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










 CREATE    proc [dbo].[vspRPVPFile]
(@rptlocation as varchar(10), @msg varchar(256) output)

/********************************
* Created: TL 06/15/05  
* Modified:	
*
* Called from RPcParameterLookups form to retrieve
* standard and overriden report type information.
*
* Input:
*	none
*
* Output:
*	resultset - current report type information
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

-- resultset of current Report Types --
select  FileName   From RPRTShared Where ReportID <= 9999 and Location = @rptlocation


vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPVPFile] TO [public]
GO
