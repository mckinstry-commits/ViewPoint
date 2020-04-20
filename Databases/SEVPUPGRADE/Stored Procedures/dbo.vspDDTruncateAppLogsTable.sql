SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          PROCEDURE [dbo].[vspDDTruncateAppLogsTable]
/**************************************************
* Created: JRK 06/01/05
* Modified: 
*
* Truncate the vDDAL table.
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

	Truncate table vDDAL

   
vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDTruncateAppLogsTable]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDTruncateAppLogsTable] TO [public]
GO
