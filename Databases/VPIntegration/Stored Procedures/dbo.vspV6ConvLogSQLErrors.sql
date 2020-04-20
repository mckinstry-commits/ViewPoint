SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspV6ConvLogSQLErrors]
/**************************************************
* Created:  DANF / GG 08/13/07
* Modified: GG 09/28/07
*
* Called from the V6 Conversion procedures to log error messages in DDAL.
*
* Input
*       @friendlymessage			Description/Message.
* Output
*	No Ouput
*
****************************************************/
(@friendlymessage varchar(1000) = null)
AS
set nocount on

declare @hostname varchar(30), @username bVPUserName, 
	 @assemblyname varchar(128), @classname varchar(128),
	 @procedurename varchar(128), @assemblyversion varchar(30),
	 @technicalmessage varchar(1000), @stacktrace varchar(2000),
	 @unhandledexception bit, @informationalmessage bit, @errnbr int,
	 @sqlretcode varchar(10), @linenumber varchar(10),
	 @company tinyint, @object varchar(30), @event varchar(30),
	 @crystalerrorid int, @errorprocedure varchar(128),
	 @datetime datetime, @errmsg varchar(512), @rcode int

	 
select @hostname = host_name(), @username = suser_name(), @procedurename = error_procedure(),
	@technicalmessage = error_message(), @errnbr = error_number(), @linenumber = error_line(),
	@errorprocedure = error_procedure(), @rcode = 0
	
exec @rcode = dbo.vspDDAddAppLog @hostname, @username, @assemblyname, @classname, @procedurename,
	@assemblyversion, @technicalmessage, @friendlymessage, @stacktrace, @unhandledexception,
	@informationalmessage, @errnbr, @sqlretcode, @linenumber, @company, @object, @event,
	@crystalerrorid, @errorprocedure, @datetime output, @errmsg output

	

GO
GRANT EXECUTE ON  [dbo].[vspV6ConvLogSQLErrors] TO [public]
GO
