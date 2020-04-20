CREATE TABLE [dbo].[bHQDR]
(
[UserName] [dbo].[bVPUserName] NOT NULL,
[AttachmentID] [int] NOT NULL,
[DateAdded] [smalldatetime] NOT NULL,
[AddedBy] [dbo].[bVPUserName] NOT NULL,
[Status] [dbo].[bStatus] NOT NULL,
[StatusDate] [smalldatetime] NOT NULL,
[Instructions] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Comments] [varchar] (7000) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  trigger [dbo].[btHQDRi] on [dbo].[bHQDR] for INSERT as
  
/****************************************************************
   * Created:  09/18/03 RBT - #21492 
   * Modified: 12/12/05 - GG - validate user in vDDUP
   * Modified: 3/4/09 JVH Added email #129482
   *
   * Insert trigger for HQ Document Routing table.
   *
   ****************************************************************/
  
  declare @errmsg varchar(255), @numrows int, @validcount int
  
  select @numrows = @@rowcount
  if @numrows = 0 return
  
  set nocount on
  
  select @validcount = count(*) from inserted i join DDUP a
  on i.UserName = a.VPUserName
  if @validcount <> @numrows
  begin
  	select @errmsg = 'UserName does not exist in DDUP'
  	goto error
  end
  
  select @validcount = count(*) from inserted i join HQAT a
  on i.AttachmentID = a.AttachmentID
  if @validcount <> @numrows
  begin
  	select @errmsg = 'AttachmentID not found in HQAT'
  	goto error
  end
  
  select @validcount = count(*) from inserted i join DDUP a
  on i.AddedBy = a.VPUserName
  if @validcount <> @numrows
  begin
  	select @errmsg = 'AddedBy user does not exist in DDUP'
  	goto error
  end
  
  select @validcount = count(*) from inserted i join HQDS a
  on i.Status = a.Status
  if @validcount <> @numrows
  begin
  	select @errmsg = 'Invalid Status, must be in HQDS'
  	goto error
  end
  
  
  --set StatusDate to today's date
  update bHQDR set StatusDate = getdate()
  from bHQDR a join inserted i on a.AttachmentID = i.AttachmentID and
  a.UserName = i.UserName
  
  --set DateAdded to today's date
  update bHQDR set DateAdded = getdate()
  from bHQDR a join inserted i on a.AttachmentID = i.AttachmentID and
  a.UserName = i.UserName
  
  --set AddedBy to current logged on user
  update bHQDR set AddedBy = SUSER_SNAME()
  from bHQDR a join inserted i on a.AttachmentID = i.AttachmentID and
  a.UserName = i.UserName;
  
  
	/* Find all the inserted records that do not have an email address for the given username
	We will then log an error as proof that we tried to email the user but the system was not setup correctly*/
	WITH 
		noEmailForUserCTE AS
		(
			SELECT 'Could not find valid TO Email address for: ' + ISNULL(UserName, 'N/A') + ' Notification Email could not be sent.' AS ErrorMessag
			FROM INSERTED WITH (NOLOCK) LEFT JOIN vDDUP WITH (NOLOCK) ON INSERTED.UserName = vDDUP.VPUserName
			WHERE EMail IS NULL
		)

	INSERT INTO vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational, Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company, Object, CrystalErrorID, ErrorProcedure)
	SELECT CURRENT_TIMESTAMP, HOST_NAME(), SUSER_NAME(), ERROR_NUMBER(), ERROR_MESSAGE(), NULL, 0, 1, 'DM', NULL, 'btHQDRi', NULL, NULL, ErrorMessag, ERROR_LINE(), NULL, NULL, NULL, NULL, NULL
	FROM noEmailForUserCTE;


	/* Now we will send an email to all the users that need to review a document.*/

	/*First we get the email address to send the emails from*/
	DECLARE @FromEmailAddress AS VARCHAR(MAX)

	SELECT TOP 1 @FromEmailAddress = EMail
	FROM vDDUP
	WHERE VPUserName = SUSER_SNAME();

	/* Now we create the rest of the email information*/
	WITH 
		emailCTE (ToEmailAddress, EmailSubject, EmailBody, EmailSource) AS
		(
			SELECT EMail,
				'New document to review',
				'User Name: ' + ISNULL(UserName, 'N/A') + CHAR(13) + CHAR(10) +
					'Description: ' + ISNULL(Description, 'N/A') + CHAR(13) + CHAR(10) +
					'Date Added: ' + ISNULL(CAST(DateAdded AS VARCHAR), 'N/A') + CHAR(13) + CHAR(10) +
					'Added By: ' + ISNULL(INSERTED.AddedBy, 'N/A') + CHAR(13) + CHAR(10) +
					'Instructions: ' + ISNULL(Instructions, 'N/A') + CHAR(13) + CHAR(10) +
					'Comments: ' + ISNULL(Comments, 'N/A') + CHAR(13) + CHAR(10) +
					'You have a document to review. Please run the Document Review form.',
				Source
			FROM INSERTED WITH (NOLOCK)
				LEFT JOIN bHQAT on bHQAT.AttachmentID = INSERTED.AttachmentID 
				LEFT JOIN vDDUP WITH (NOLOCK) ON INSERTED.UserName = vDDUP.VPUserName
				LEFT JOIN vDDNotificationPrefs ON INSERTED.UserName = vDDNotificationPrefs.VPUserName AND vDDNotificationPrefs.Source = 'Document Review'
			WHERE EMail IS NOT NULL
		)

	/* Insert the records so that emails will be sent off.
	If the source is null the mailqueue will route to the default preference
	If the from email address is null the mailqueue will use the system default for
	the email address*/
	INSERT INTO vMailQueue([To], [From], [Subject], Body, Source) 
	SELECT ToEmailAddress, @FromEmailAddress, EmailSubject, EmailBody, EmailSource
	FROM emailCTE

  return
  
  error:
  	select @errmsg = @errmsg + ' - cannot insert HQ Document Review!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
  
  
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btHQDRu] on [dbo].[bHQDR] for UPDATE as
   

/****************************************************************
    * Created:  09/17/03 RBT - #21492 
    * Modified: 
    *
    * Update trigger for HQ Document Routing table.
    *
    ****************************************************************/
   
   declare @errmsg varchar(255), @numrows int, @validcount int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   --do not allow changes to key fields
   select @validcount = count(*) from inserted i join deleted d
   on i.AttachmentID = d.AttachmentID and i.UserName = d.UserName
   if @validcount <> @numrows 
   begin	
   	select 'Cannot change UserName or AttachmentID'
   	goto error
   end
   
   --automatically set StatusDate to current date if Status is changed.
   update bHQDR set StatusDate = convert(smalldatetime,getdate(),1)
   from bHQDR a join inserted i on a.UserName = i.UserName
   and a.AttachmentID = i.AttachmentID join deleted d on i.UserName = d.UserName
   and i.AttachmentID = d.AttachmentID 
   where i.Status <> d.Status
   
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot update HQ Document Review table!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQDR] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQDR] ON [dbo].[bHQDR] ([UserName], [AttachmentID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQDR_ATT_Status2] ON [dbo].[bHQDR] ([UserName], [DateAdded], [AttachmentID]) ON [PRIMARY]
GO
