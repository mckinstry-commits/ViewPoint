CREATE TABLE [dbo].[budBidders]
(
[Co] [dbo].[bCompany] NOT NULL,
[AwardedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udBidders_AwardedYN] DEFAULT ('N'),
[Project] [dbo].[bProject] NOT NULL,
[RejectReason] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[RejectedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udBidders_RejectedYN] DEFAULT ('N'),
[Vendor] [dbo].[bVendor] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Invited] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udBidders_Invited] DEFAULT ('N'),
[SubmittedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udBidders_SubmittedYN] DEFAULT ('N'),
[BidAmt] [dbo].[bDollar] NULL,
[BidDate] [dbo].[bDate] NULL,
[InviteDate] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudBidders_Audit_Delete ON dbo.budBidders
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:29AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(deleted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(deleted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , deleted.Co , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudBidders_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudBidders_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudBidders_Audit_Insert ON dbo.budBidders
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:29AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , ISNULL(inserted.Co, '') , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudBidders_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudBidders_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudBidders_Audit_Update ON dbo.budBidders
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:29AM

 BEGIN TRY 

 IF UPDATE([Co])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Co]' ,  CONVERT(VARCHAR(MAX), deleted.[Co]) ,  CONVERT(VARCHAR(MAX), inserted.[Co]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Co] <> deleted.[Co]) OR (inserted.[Co] IS NULL AND deleted.[Co] IS NOT NULL) OR (inserted.[Co] IS NOT NULL AND deleted.[Co] IS NULL))



 END 

 IF UPDATE([AwardedYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[AwardedYN]' ,  CONVERT(VARCHAR(MAX), deleted.[AwardedYN]) ,  CONVERT(VARCHAR(MAX), inserted.[AwardedYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[AwardedYN] <> deleted.[AwardedYN]) OR (inserted.[AwardedYN] IS NULL AND deleted.[AwardedYN] IS NOT NULL) OR (inserted.[AwardedYN] IS NOT NULL AND deleted.[AwardedYN] IS NULL))



 END 

 IF UPDATE([Project])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Project]' ,  CONVERT(VARCHAR(MAX), deleted.[Project]) ,  CONVERT(VARCHAR(MAX), inserted.[Project]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Project] <> deleted.[Project]) OR (inserted.[Project] IS NULL AND deleted.[Project] IS NOT NULL) OR (inserted.[Project] IS NOT NULL AND deleted.[Project] IS NULL))



 END 

 IF UPDATE([RejectReason])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[RejectReason]' ,  CONVERT(VARCHAR(MAX), deleted.[RejectReason]) ,  CONVERT(VARCHAR(MAX), inserted.[RejectReason]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[RejectReason] <> deleted.[RejectReason]) OR (inserted.[RejectReason] IS NULL AND deleted.[RejectReason] IS NOT NULL) OR (inserted.[RejectReason] IS NOT NULL AND deleted.[RejectReason] IS NULL))



 END 

 IF UPDATE([RejectedYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[RejectedYN]' ,  CONVERT(VARCHAR(MAX), deleted.[RejectedYN]) ,  CONVERT(VARCHAR(MAX), inserted.[RejectedYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[RejectedYN] <> deleted.[RejectedYN]) OR (inserted.[RejectedYN] IS NULL AND deleted.[RejectedYN] IS NOT NULL) OR (inserted.[RejectedYN] IS NOT NULL AND deleted.[RejectedYN] IS NULL))



 END 

 IF UPDATE([Vendor])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Vendor]' ,  CONVERT(VARCHAR(MAX), deleted.[Vendor]) ,  CONVERT(VARCHAR(MAX), inserted.[Vendor]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Vendor] <> deleted.[Vendor]) OR (inserted.[Vendor] IS NULL AND deleted.[Vendor] IS NOT NULL) OR (inserted.[Vendor] IS NOT NULL AND deleted.[Vendor] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 IF UPDATE([Invited])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Invited]' ,  CONVERT(VARCHAR(MAX), deleted.[Invited]) ,  CONVERT(VARCHAR(MAX), inserted.[Invited]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Invited] <> deleted.[Invited]) OR (inserted.[Invited] IS NULL AND deleted.[Invited] IS NOT NULL) OR (inserted.[Invited] IS NOT NULL AND deleted.[Invited] IS NULL))



 END 

 IF UPDATE([SubmittedYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[SubmittedYN]' ,  CONVERT(VARCHAR(MAX), deleted.[SubmittedYN]) ,  CONVERT(VARCHAR(MAX), inserted.[SubmittedYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[SubmittedYN] <> deleted.[SubmittedYN]) OR (inserted.[SubmittedYN] IS NULL AND deleted.[SubmittedYN] IS NOT NULL) OR (inserted.[SubmittedYN] IS NOT NULL AND deleted.[SubmittedYN] IS NULL))



 END 

 IF UPDATE([BidAmt])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[BidAmt]' ,  CONVERT(VARCHAR(MAX), deleted.[BidAmt]) ,  CONVERT(VARCHAR(MAX), inserted.[BidAmt]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[BidAmt] <> deleted.[BidAmt]) OR (inserted.[BidAmt] IS NULL AND deleted.[BidAmt] IS NOT NULL) OR (inserted.[BidAmt] IS NOT NULL AND deleted.[BidAmt] IS NULL))



 END 

 IF UPDATE([BidDate])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[BidDate]' ,  CONVERT(VARCHAR(MAX), deleted.[BidDate]) ,  CONVERT(VARCHAR(MAX), inserted.[BidDate]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[BidDate] <> deleted.[BidDate]) OR (inserted.[BidDate] IS NULL AND deleted.[BidDate] IS NOT NULL) OR (inserted.[BidDate] IS NOT NULL AND deleted.[BidDate] IS NULL))



 END 

 IF UPDATE([InviteDate])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budBidders' , '<KeyString Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" Vendor = "' + REPLACE(CAST(inserted.[Vendor] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[InviteDate]' ,  CONVERT(VARCHAR(MAX), deleted.[InviteDate]) ,  CONVERT(VARCHAR(MAX), inserted.[InviteDate]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[InviteDate] <> deleted.[InviteDate]) OR (inserted.[InviteDate] IS NULL AND deleted.[InviteDate] IS NOT NULL) OR (inserted.[InviteDate] IS NOT NULL AND deleted.[InviteDate] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudBidders_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudBidders_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudBidders] ON [dbo].[budBidders] ([Co], [Project], [Vendor]) ON [PRIMARY]
GO