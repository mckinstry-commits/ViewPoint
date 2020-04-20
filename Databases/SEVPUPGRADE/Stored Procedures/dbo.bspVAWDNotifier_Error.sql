SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspVAWDNotifier_Error]
   /*******************************************************
   *    Created: TV 1/30/03
   *				TV - 23061 added isnulls	
   *				RT 4/27/04 - 24326 Get servername and fromaddress to pass to bspXP_SendMail.
   *
   *    Purpose: sends a notification email to the Notifier
   *             operators email.
   *
   *    inputs: @JobName
   *
   *    outputs: none
   *
   *******************************************************/
   (@jobname varchar(55))
   
   as
   
   set nocount on
   
   Declare @emailto varchar(55),@emailsubject varchar(55), @emailbody varchar(55),
   		@servername varchar(60), @fromaddress varchar(255)
   
   --Get the mail server and "from" address (issue #24326)
   select @servername = Value
   from WDSettings 
   where Setting = 'Server'
   
   if @servername is null or @servername = 'VIEWPOINT' select @servername = @@servername
   
   select @fromaddress = Value
   from WDSettings
   where Setting = 'FromAddress'
   
   if @fromaddress is null select @fromaddress = 'Notifier'
   
   
   select @emailto = (select email_address from msdb.dbo.sysoperators where lower(name) = 'notifier'),
          @emailsubject = @jobname + ' Failed.', 
          @emailbody = @jobname + ' Failed. ' + isnull(convert(varchar(55),getdate()),'')
   
   if isnull(@emailto, '') <> '' exec bspXP_SendMail 99, @emailto, @emailbody, '', '', '', @emailsubject, @servername, @fromaddress
   
   return

GO
GRANT EXECUTE ON  [dbo].[bspVAWDNotifier_Error] TO [public]
GO
