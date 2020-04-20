CREATE TABLE [dbo].[bHQAT]
(
[HQCo] [dbo].[bCompany] NOT NULL,
[FormName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[KeyField] [varchar] (500) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[AddedBy] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[AddDate] [dbo].[bDate] NULL,
[DocName] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[AttachmentID] [int] NOT NULL,
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[OrigFileName] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[DocAttchYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAT_DocAttchYN] DEFAULT ('N'),
[CurrentState] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHQAT_CurrentState] DEFAULT ('A'),
[AttachmentTypeID] [int] NULL,
[IsEmail] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHQAT_IsEmail] DEFAULT ('N')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btHQATd] on [dbo].[bHQAT] for DELETE as
/*-----------------------------------------------------------------
    *  Created ??
    *  Modified by: TV No issue. This was just stupid code 11/18/03 Rick said he did it.
    *				 RT 04/08/04 - Issue #24302, Delete Document Routing info.
    *				 GF 04/24/2008 - issue #125958 delete PMHA documement audit attachment id
    *				 JonathanP 05/15/2008 - Issue #128344 The audit records for an attachment will be deleted now.
    *				 JonathanP 09/29/2008 - Issue #130005 We now delete the corresponding HQAF records if they exist.
    *				 JonathanP 01/29/2008 - Issue #129917 Delete any corresponding annotations.
    *				 JonathanP 01/12/2010 - See #131182. Removed the delete from bHQAF
    *
    *	This trigger deletes all HQAI records when an HQAT record is deleted.
    */----------------------------------------------------------------
declare  @errmsg varchar(255)

delete bHQAI from bHQAI i join deleted d on i.AttachmentID = d.AttachmentID

delete bHQDR from bHQDR r join deleted d on r.AttachmentID = d.AttachmentID

-- issue #131182. We do not delete from bHQAF anymore since it may exist in another database.
--delete bHQAF from bHQAF f join deleted d on f.AttachmentID = d.AttachmentID

---- issue #125958
delete bPMHA from bPMHA h join deleted d on h.AttachmentID = d.AttachmentID

-- Since the attachments are getting fully deleted, we can not audit them because the audit record needs to
-- point back to an attachment ID. So, delete all the audit records for these attachments.
DELETE DMAttachmentAuditLog from DMAttachmentAuditLog a JOIN deleted d on a.AttachmentID = d.AttachmentID

-- See issue #129917 Delete any annotations for these attachments.
delete vDMAnnotations from vDMAnnotations a join deleted d on a.AttachmentID = d.AttachmentID


/*TV No issue. This was just stupid code 11/18/03
if exists(select 1 from bHQAI i with (nolock) join deleted d on i.AttachmentID = d.AttachmentID)
   	begin
   	select @errmsg = 'Unable to delete indexes for this attachment.'
   	goto error
   	end*/

return


error:
   	select @errmsg = isnull(@errmsg,'') + ' - Cannot Delete Attachment!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/15/08
-- Description:	Insert trigger.
-- Modified: JonathanP 04/16/09 - Changed except statement into a join to make it so a result set is not returned.
-- =============================================
CREATE TRIGGER [dbo].[btHQATi]
   ON  [dbo].[bHQAT]
   FOR Insert
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	
	declare @rowcount int	
	
	-- Check to make sure the attachment type exists.	
	select @rowcount = count(i.AttachmentTypeID)
		from inserted i with(nolock)			
		where i.AttachmentTypeID is not null 
			and i.AttachmentTypeID not in (select AttachmentTypeID from DMAttachmentTypesShared with(nolock))		

	IF @rowcount > 0
	BEGIN
		RAISERROR('Attachment type(s) do not exist.', 11, -1)
		ROLLBACK TRANSACTION
	END	

END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		JonathanP
-- Create date: 04/15/08
-- Description:	Update trigger.
-- =============================================
CREATE TRIGGER [dbo].[btHQATu]
   ON  [dbo].[bHQAT]
   FOR Update
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @rowcount int	

	-- Check to make sure the attachment type exists.	
	select @rowcount = count(i.AttachmentTypeID)
		from inserted i with(nolock)			
		where i.AttachmentTypeID is not null 
			and i.AttachmentTypeID not in (select AttachmentTypeID from DMAttachmentTypesShared with(nolock))		

	IF @rowcount > 0
	BEGIN
		RAISERROR('Attachment type(s) do not exist.', 11, -1)
		ROLLBACK TRANSACTION
	END	
END

GO
CREATE UNIQUE CLUSTERED INDEX [biHQAT] ON [dbo].[bHQAT] ([AttachmentID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQAT_AttchID] ON [dbo].[bHQAT] ([AttachmentID], [FormName], [UniqueAttchID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQAT_AttachmentTypeID] ON [dbo].[bHQAT] ([AttachmentTypeID]) INCLUDE ([AddDate], [AttachmentID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bHQAT_CurrentState] ON [dbo].[bHQAT] ([CurrentState]) INCLUDE ([TableName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQAT_OrigFileName] ON [dbo].[bHQAT] ([OrigFileName]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biHQATUniqueAttchID] ON [dbo].[bHQAT] ([UniqueAttchID]) INCLUDE ([AttachmentID]) ON [PRIMARY]
GO
