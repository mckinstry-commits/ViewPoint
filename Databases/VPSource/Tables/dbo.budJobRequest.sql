CREATE TABLE [dbo].[budJobRequest]
(
[Co] [dbo].[bCompany] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[RequestNum] [int] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[CertifiedPRYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udJobRequest_CertifiedPRYN] DEFAULT ('N'),
[Contract] [dbo].[bContract] NULL,
[Customer] [dbo].[bCustomer] NULL,
[Department] [dbo].[bDept] NULL,
[NTPYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udJobRequest_NTPYN] DEFAULT ('N'),
[POC] [dbo].[bProjectMgr] NULL,
[PublicYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udJobRequest_PublicYN] DEFAULT ('N'),
[WMBEYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udJobRequest_WMBEYN] DEFAULT ('N'),
[Workstream] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[QueueDate] [dbo].[bDate] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudJobRequest_Audit_Delete ON dbo.budJobRequest
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Oct  2 2013  4:41PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(deleted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , deleted.Co , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', d.Co, d.Contract, 'budJobRequest'
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(d.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudJobRequest_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Delete]', 'last', 'delete', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Delete]', 'last', 'delete', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Delete]', 'last', 'delete', null
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudJobRequest_Audit_Insert ON dbo.budJobRequest
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Oct  2 2013  4:41PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , ISNULL(inserted.Co, '') , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted
 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudJobRequest_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Insert]', 'last', 'insert', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Insert]', 'last', 'insert', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Insert]', 'last', 'insert', null
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudJobRequest_Audit_Update ON dbo.budJobRequest
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on Oct  2 2013  4:41PM

 BEGIN TRY 
DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);
 IF UPDATE([Co])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Co]' ,  CONVERT(VARCHAR(MAX), deleted.[Co]) ,  CONVERT(VARCHAR(MAX), inserted.[Co]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Co] <> deleted.[Co]) OR (inserted.[Co] IS NULL AND deleted.[Co] IS NOT NULL) OR (inserted.[Co] IS NOT NULL AND deleted.[Co] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([RequestNum])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[RequestNum]' ,  CONVERT(VARCHAR(MAX), deleted.[RequestNum]) ,  CONVERT(VARCHAR(MAX), inserted.[RequestNum]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[RequestNum] <> deleted.[RequestNum]) OR (inserted.[RequestNum] IS NULL AND deleted.[RequestNum] IS NOT NULL) OR (inserted.[RequestNum] IS NOT NULL AND deleted.[RequestNum] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([CertifiedPRYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[CertifiedPRYN]' ,  CONVERT(VARCHAR(MAX), deleted.[CertifiedPRYN]) ,  CONVERT(VARCHAR(MAX), inserted.[CertifiedPRYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[CertifiedPRYN] <> deleted.[CertifiedPRYN]) OR (inserted.[CertifiedPRYN] IS NULL AND deleted.[CertifiedPRYN] IS NOT NULL) OR (inserted.[CertifiedPRYN] IS NOT NULL AND deleted.[CertifiedPRYN] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Contract])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Contract]' ,  CONVERT(VARCHAR(MAX), deleted.[Contract]) ,  CONVERT(VARCHAR(MAX), inserted.[Contract]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Contract] <> deleted.[Contract]) OR (inserted.[Contract] IS NULL AND deleted.[Contract] IS NOT NULL) OR (inserted.[Contract] IS NOT NULL AND deleted.[Contract] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Customer])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Customer]' ,  CONVERT(VARCHAR(MAX), deleted.[Customer]) ,  CONVERT(VARCHAR(MAX), inserted.[Customer]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Customer] <> deleted.[Customer]) OR (inserted.[Customer] IS NULL AND deleted.[Customer] IS NOT NULL) OR (inserted.[Customer] IS NOT NULL AND deleted.[Customer] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Department])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Department]' ,  CONVERT(VARCHAR(MAX), deleted.[Department]) ,  CONVERT(VARCHAR(MAX), inserted.[Department]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Department] <> deleted.[Department]) OR (inserted.[Department] IS NULL AND deleted.[Department] IS NOT NULL) OR (inserted.[Department] IS NOT NULL AND deleted.[Department] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([NTPYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[NTPYN]' ,  CONVERT(VARCHAR(MAX), deleted.[NTPYN]) ,  CONVERT(VARCHAR(MAX), inserted.[NTPYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[NTPYN] <> deleted.[NTPYN]) OR (inserted.[NTPYN] IS NULL AND deleted.[NTPYN] IS NOT NULL) OR (inserted.[NTPYN] IS NOT NULL AND deleted.[NTPYN] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([POC])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[POC]' ,  CONVERT(VARCHAR(MAX), deleted.[POC]) ,  CONVERT(VARCHAR(MAX), inserted.[POC]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[POC] <> deleted.[POC]) OR (inserted.[POC] IS NULL AND deleted.[POC] IS NOT NULL) OR (inserted.[POC] IS NOT NULL AND deleted.[POC] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([PublicYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[PublicYN]' ,  CONVERT(VARCHAR(MAX), deleted.[PublicYN]) ,  CONVERT(VARCHAR(MAX), inserted.[PublicYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[PublicYN] <> deleted.[PublicYN]) OR (inserted.[PublicYN] IS NULL AND deleted.[PublicYN] IS NOT NULL) OR (inserted.[PublicYN] IS NOT NULL AND deleted.[PublicYN] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([WMBEYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[WMBEYN]' ,  CONVERT(VARCHAR(MAX), deleted.[WMBEYN]) ,  CONVERT(VARCHAR(MAX), inserted.[WMBEYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[WMBEYN] <> deleted.[WMBEYN]) OR (inserted.[WMBEYN] IS NULL AND deleted.[WMBEYN] IS NOT NULL) OR (inserted.[WMBEYN] IS NOT NULL AND deleted.[WMBEYN] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([Workstream])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Workstream]' ,  CONVERT(VARCHAR(MAX), deleted.[Workstream]) ,  CONVERT(VARCHAR(MAX), inserted.[Workstream]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Workstream] <> deleted.[Workstream]) OR (inserted.[Workstream] IS NULL AND deleted.[Workstream] IS NOT NULL) OR (inserted.[Workstream] IS NOT NULL AND deleted.[Workstream] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 IF UPDATE([QueueDate])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) 
   SELECT 'budJobRequest' , '<KeyString RequestNum = "' + REPLACE(CAST(inserted.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[QueueDate]' ,  CONVERT(VARCHAR(MAX), deleted.[QueueDate]) ,  CONVERT(VARCHAR(MAX), inserted.[QueueDate]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[QueueDate] <> deleted.[QueueDate]) OR (inserted.[QueueDate] IS NULL AND deleted.[QueueDate] IS NOT NULL) OR (inserted.[QueueDate] IS NOT NULL AND deleted.[QueueDate] IS NULL))

 INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT Keys.AuditID, 'bContract', i.Co, i.Contract, 'budJobRequest'
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = '<KeyString RequestNum = "' + REPLACE(CAST(i.[RequestNum] AS VARCHAR(MAX)),'"', '&quot;') + '" />'

 DELETE FROM @HQMAKeys; 
 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudJobRequest_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Update]', 'last', 'update', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Update]', 'last', 'update', null
GO

EXEC sp_settriggerorder N'[dbo].[vtbudJobRequest_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudJobRequest] ON [dbo].[budJobRequest] ([Co], [RequestNum]) ON [PRIMARY]
GO
