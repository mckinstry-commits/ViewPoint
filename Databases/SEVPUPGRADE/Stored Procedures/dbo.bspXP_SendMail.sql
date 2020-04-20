SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspXP_SendMail]
   /************************************************************************
   *    Created by:  TV 10/11/01
   *    Modified BY: TV 8/12/03- moved to CDOSYS
   *				  RT 4/27/04 - #24326, changed to pass in servername and fromaddress.
   *				 CC 04/11/08 - #127773 - Changed version selection logic for any Windows version prior to 2003 uses CDONTS, 2003 and later use CDOSYS
   *
   *    Purpose:
   *            To handle the email portion of the notifier.
   *
   *    inputs: @co Company
   *            @Recip recipiant's address/'s
   *            @message Body Text
   *            @query if Query results are requested
   *            @cc CC recipiant/s
   *            @blindcc Blind CC Ricipiants
   *            @subjuct Email subject line
   *
   ************************************************************************/
   (@co bCompany, @recip varchar(255), @message varchar(8000), @query varchar(255)= null, @cc varchar(255)= null,
   @blindcc varchar(255)= null, @subject Varchar (255), @servername varchar(60), @fromaddress varchar(255))
   as
   
   set nocount on
   
   declare @emailstring varchar(500), @MailID int, @hr int
   
   --issue #24326, removed retrieval of servername and moved to bspVAWDNotifier.
   
   create table  #Version (myindex int, myname varchar(55), internalval int, version varchar(115))
   insert #Version
   exec master.dbo.xp_msver WindowsVersion
   if EXISTS(SELECT * FROM #Version WHERE CAST(LEFT(version,3) AS float) < 5.2)--if not Windows server 2003
       begin
       --CDONTS style. Not supported after windows 2000
       --uses the IIS SMTP to send mail  
       EXEC @hr = sp_OACreate 'CDONTS.NewMail', @MailID OUT
       EXEC @hr = sp_OASetProperty @MailID, 'From', @fromaddress
       EXEC @hr = sp_OASetProperty @MailID, 'Body', @message
       EXEC @hr = sp_OASetProperty @MailID, 'BCC',@blindcc
       EXEC @hr = sp_OASetProperty @MailID, 'CC', @cc
       EXEC @hr = sp_OASetProperty @MailID, 'Subject', @subject
       EXEC @hr = sp_OASetProperty @MailID, 'To', @recip
       EXEC @hr = sp_OAMethod @MailID, 'Send', NULL
       EXEC @hr = sp_OADestroy @MailID 
       end
   else
       begin
       --CDOSYS Style. to be used on post 2003 installs
       EXEC @hr = sp_OACreate 'CDO.Message', @MailID OUT
       EXEC @hr = sp_OASetProperty @MailID, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/sendusing").Value','2'
       EXEC @hr = sp_OASetProperty @MailID, 'Configuration.fields("http://schemas.microsoft.com/cdo/configuration/smtpserver").Value', @servername 
       EXEC @hr = sp_OAMethod @MailID, 'Configuration.Fields.Update', null
       EXEC @hr = sp_OASetProperty @MailID, 'To', @recip
       EXEC @hr = sp_OASetProperty @MailID, 'BCC', @blindcc
       EXEC @hr = sp_OASetProperty @MailID, 'CC', @cc
       EXEC @hr = sp_OASetProperty @MailID, 'From', @fromaddress
       EXEC @hr = sp_OASetProperty @MailID, 'Subject', @subject
       EXEC @hr = sp_OASetProperty @MailID, 'TextBody', @message
       EXEC @hr = sp_OAMethod @MailID, 'Send', NULL
       EXEC @hr = sp_OADestroy @MailID
       end
       
   drop table #Version
   
   
   return @hr

GO
GRANT EXECUTE ON  [dbo].[bspXP_SendMail] TO [public]
GO
