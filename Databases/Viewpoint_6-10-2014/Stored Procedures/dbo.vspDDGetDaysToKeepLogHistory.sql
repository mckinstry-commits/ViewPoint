SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            PROCEDURE [dbo].[vspDDGetDaysToKeepLogHistory]
/**************************************************
* Created: JRK 06/27/05
* Modified: JRK 03/08/06 to use DDVS instead of vDDVS.
*
* Read the number of days to keep application logs.
*
* Inputs:
*	none
*
* Output:
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

	Select 180

   
vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDGetDaysToKeepLogHistory]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDGetDaysToKeepLogHistory] TO [public]
GRANT EXECUTE ON  [dbo].[vspDDGetDaysToKeepLogHistory] TO [VCSPortal]
GO
