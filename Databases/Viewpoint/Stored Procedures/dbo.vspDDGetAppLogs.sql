SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                         PROCEDURE [dbo].[vspDDGetAppLogs]
/**************************************************
* Created:  JK 12/19/03
* Modified: GG supplied SQL on 4/7/04 to get records with null fields.
* Modified: JRK 07/15/04 Simplify since we only select based on the min and max dates.
* Modified: JRK 07/29/04 Return LineNumber.
* Modified: JRK 06/20/05 Added Company, Object and Event (customer log data)
* Modified: JRK 08/12/05 Added ErrorProcedure field.
* Modified: JRK 03/08/06 Use DDAL instead of vDDAL.
*
* Retrieves logs based on criteria passed in.
*
* There is no output.
* 
* Inputs:  All will default to "all".
*       @maxdate		Upper end of date range.
*	@mindate		Lower end of date range.
*  drop-->     @hostname		The workstation id where the activity originated.
*  drop-->     @username		Needed since we use a system connection.
*  drop-->     @source			Concatenation of assembly, module and routine names.
*  drop-->     @errnbr			Error number, if any.
*  drop-->     @desc		Message property of an Exception or SQLException.
*  drop-->     @sqlretcode		Return code from SQL, if any.
*
* Output
*	@errmsg
*
****************************************************/
	(@maxdate varchar(30) = null, @mindate varchar(30) = null,
	 --@hostname varchar(30) = null, @username bVPUserName = null, 
	 --@source varchar(256) = null, @errnbr int = null,
	 --@desc varchar(256) = null, @sqlretcode varchar(10) = null,
	 @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int, @dt datetime
select @rcode = 0, @dt = getdate()

/*
-- If most fields are null then do a simple select.
if (@mindate is null and @hostname is null and @username is null 
and @source is null and @errnbr is null and @desc is null
and @sqlretcode is null)
begin
	select DateTime, HostName, UserName, Source, ErrorNumber, Description, SQLRetCode from DDAL
	order by DateTime DESC
	goto vspexit
end
*/


-- Gary's code:
-- The order of the columns affects the column order in the grid.
select 
	[DateTime], 
	HostName, 
	UserName, 
	Company As Co,
	Informational As Info, 
	FriendlyMessage As FriendlyMsg,
	[Description] as ExceptionMsg, 
	ErrorProcedure,
	[Object] As WhoWhat,
	[Event] As Action,
	StackTrace,
	Assembly, 
	AssemblyVersion,
	Class,
	[Procedure], 
	LineNumber,
	SQLRetCode as SQLExceptionNbr,
	CrystalErrorID,
	UnhandledError 
from vDDAL

where (DateTime >= isnull(@mindate,'01/01/1900')) and (DateTime <= isnull(@maxdate,'12/31/2099'))
--and Description like 'Clear%'  
/*
and (@hostname is null or HostName like @hostname + '%')

and (@username is null or UserName like @username + '%')

and (@source is null or Source like @source + '%')

and (@errnbr is null or ErrorNumber = isnull(@errnbr,ErrorNumber))

and (@desc is null or Description like @desc + '%')

and (@sqlretcode is null or SQLRetCode like @sqlretcode + '%')
*/

ORDER BY DateTime DESC

GOTO vspexit


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDGetAppLogs] TO [public]
GO
