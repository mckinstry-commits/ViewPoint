SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           PROCEDURE [dbo].[vspDDDeleteAppLogs]
/**************************************************
* Created: JRK 06/01/05
* Modified: JRK 03/08/06 Use DDAL instead of vDDAL.
*
* Delete logs older than the specified date.
*
* Inputs:
*	@deldate	Delete logs older than this date.
*
* Output:
*	@errmsg		Error message
*
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@deldate varchar(30), @errmsg varchar(512) output)
as

set nocount on 

declare @rcode int
select @rcode = 0

if @deldate = null
	begin
	select @errmsg = 'Missing required input parameter: @deldate (cut-off date)', @rcode = 1
	goto vspexit
	end

	Delete from DDAL where [DateTime] < @deldate

   
vspexit:

	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDDeleteAppLogs]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDeleteAppLogs] TO [public]
GO
