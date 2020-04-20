SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDAddAppLog]  
/**************************************************  
* Created:  JK 07/13/04 - Cloned from vspDDAddAppLog  
* Modified: JK 07/20/04 - Add DateTime return argument.  
* Modified: JK 07/29/04 - Add LineNumber argument.  
* Modified: RM 03/01/05 - Make @stacktrace 2000 characters (from 1000) to be consistent with the table  
* Modified: Dave C 02/16/2010 - Make @object 256 characters (from 30) to be consistent with the table  
*  
* Called from the Logging class in RemoteHelper to add an application log,   
* usually an error message or an event such as a login attempt.  
*  
* Writes a row to vDDAL.  
* There is no output.  
*   
* Inputs  
*       @hostname  The workstation id where the activity originated.  
*       @username  Needed since we use a system connection.  
*       @assemblyname     
*       @classname     
*       @procedurename     
*       @assemblyversion     
*       @technicalmessage   Description/Message.  
*       @friendlymessage   Description/Message.  
*       @stacktrace   Description/Message.  
*       @errnbr   Error number, if any.  
*       @sqlretcode  Return code from SQL, if any.  
*       @unhandledexception  bit (set to 0 by default)  
*       @informationalmessage  bit (set to 0 by default)  
*       @linenumber    
*       @linenumber    
*       @company For all logs.  
*       @object  For customer logs.  Eg, "frmHQTX".    
*       @event  For customer logs.  Eg, "Opened"  
* @crystalerrorid  Crystal ErrorID  
* @errorprocedure  Name of VCS.Viewpoint procedure that caused exception to be logged.  
* Output  
* @datetime  Output the DateTime of the log written.  
* @errmsg  
*  
****************************************************/  
 (@hostname varchar(30) = null, @username bVPUserName = null,   
  @assemblyname varchar(128) = null, @classname varchar(128) = null,  
  @procedurename varchar(128) = null, @assemblyversion varchar(30) = null,  
  @technicalmessage varchar(1000) = null, @friendlymessage varchar(1000) = null,  
  @stacktrace varchar(2000) = null, @unhandledexception bit = null,  
  @informationalmessage bit = null, @errnbr int = null,  
  @sqlretcode varchar(10) = null, @linenumber varchar(10) = null,  
  @company tinyint = null, @object varchar(256) = null,   
  @event varchar(30) = null, @crystalerrorid int = null,  
  @errorprocedure varchar(128) = null,  
  @datetime datetime output, @errmsg varchar(512) output)  
as  
  
set nocount on   
declare @rcode int, @dt datetime  
select @rcode = 0, @dt = getdate()  
  
select @datetime = @dt -- Set the output parameter.  
  
-- Check for required fields:  None.  
  
if @unhandledexception is null  
 select @unhandledexception = 0  
if @informationalmessage is null  
 select @informationalmessage = 0  
  
-- Insert a row with the supplied data.  
-- Note "Description" is TechnicalMessage  
  
insert into DDALog (DateTime, HostName, UserName,   
 Assembly, Class, [Procedure], AssemblyVersion,  
 [Description], FriendlyMessage, StackTrace,  
 UnhandledError, Informational,  
 ErrorNumber, SQLRetCode, LineNumber,  
 Company, Object, Event, CrystalErrorID,  
 ErrorProcedure)  
 VALUES (@dt, @hostname, @username,  
 @assemblyname, @classname, @procedurename, @assemblyversion,  
 @technicalmessage, @friendlymessage, @stacktrace,  
 @unhandledexception, @informationalmessage,  
 @errnbr, @sqlretcode, @linenumber,  
 @company, @object, @event, @crystalerrorid,  
 @errorprocedure)  
  
vspexit:  
 if @rcode<>0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDAddAppLog]'  
   return @rcode  
GO
GRANT EXECUTE ON  [dbo].[vspDDAddAppLog] TO [public]
GO
