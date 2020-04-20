CREATE TABLE [dbo].[budProjectBuildings]
(
[Co] [dbo].[bCompany] NOT NULL,
[Add1] [dbo].[bItemDesc] NULL,
[Add2] [dbo].[bItemDesc] NULL,
[BET] [smallint] NULL,
[BuildingNum] [tinyint] NOT NULL,
[City] [dbo].[bDesc] NULL,
[EnergyStrRat] [tinyint] NULL,
[LEEDTarget] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[OccOwnership] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Occupant] [dbo].[bItemDesc] NULL,
[Owner] [dbo].[bCustomer] NULL,
[Project] [dbo].[bProject] NOT NULL,
[SameAddAs] [tinyint] NULL,
[SqFt] [dbo].[bUnits] NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[HistoricalYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udProjectBuildings_HistoricalYN] DEFAULT ('N'),
[Description] [dbo].[bItemDesc] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/23/2013
-- Description:	Trigger to fill Address from 'Same Address As' field. 
-- =============================================
CREATE TRIGGER [dbo].[mckAddressAuto] 
   ON  [dbo].[budProjectBuildings] 
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF UPDATE(SameAddAs)
    -- Insert statements for trigger here
	BEGIN
		DECLARE @Co TINYINT, @Project VARCHAR(30), @BuildingNum SMALLINT, @SameAddAs SMALLINT

		SELECT @Co = Co, @Project = Project, @BuildingNum = BuildingNum, @SameAddAs = SameAddAs FROM INSERTED

		UPDATE budProjectBuildings
		SET Add1 = (SELECT Add1 FROM udProjectBuildings WHERE @Co = Co AND @Project = Project AND @SameAddAs = BuildingNum)
		, Add2 = (SELECT Add2 FROM udProjectBuildings WHERE @Co = Co AND @Project = Project AND @SameAddAs = BuildingNum)
		, City = (SELECT City FROM udProjectBuildings WHERE @Co = Co AND @Project = Project AND @SameAddAs = BuildingNum)
		, State = (SELECT State FROM udProjectBuildings WHERE @Co = Co AND @Project = Project AND @SameAddAs = BuildingNum)
		, Zip = (SELECT Zip FROM udProjectBuildings WHERE @Co = Co AND @Project = Project AND @SameAddAs = BuildingNum)
		WHERE @Co = Co AND @Project = Project AND @BuildingNum = BuildingNum
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 12/23/2013
-- Description:	Remove 'SameAddressAs' value if source Address is deleted.
-- =============================================
CREATE TRIGGER [dbo].[mckAddressAutoDel] 
   ON  [dbo].[budProjectBuildings] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @Co TINYINT, @Project VARCHAR(30), @BuildingNum SMALLINT
	SELECT @Co = Co, @Project = Project, @BuildingNum = BuildingNum FROM DELETED
	
	UPDATE budProjectBuildings
	SET SameAddAs = NULL
	WHERE @Co = Co AND @Project = Project AND @BuildingNum = SameAddAs
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudProjectBuildings_Audit_Delete ON dbo.budProjectBuildings
 AFTER DELETE
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:01AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(deleted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(deleted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , deleted.Co , 'D' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM deleted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudProjectBuildings_Audit_Delete] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudProjectBuildings_Audit_Delete]', 'last', 'delete', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudProjectBuildings_Audit_Insert ON dbo.budProjectBuildings
 AFTER INSERT
 NOT FOR REPLICATION AS
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:01AM

 BEGIN TRY 

   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , ISNULL(inserted.Co, '') , 'A' , NULL , NULL , NULL , GETDATE() , SUSER_SNAME()
	FROM inserted

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudProjectBuildings_Audit_Insert] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudProjectBuildings_Audit_Insert]', 'last', 'insert', null
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER dbo.vtbudProjectBuildings_Audit_Update ON dbo.budProjectBuildings
 AFTER UPDATE 
 NOT FOR REPLICATION AS 
 SET NOCOUNT ON 
 -- generated by vspHQCreateAuditTriggers on May 30 2014 11:01AM

 BEGIN TRY 

 IF UPDATE([Co])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Co]' ,  CONVERT(VARCHAR(MAX), deleted.[Co]) ,  CONVERT(VARCHAR(MAX), inserted.[Co]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Co] <> deleted.[Co]) OR (inserted.[Co] IS NULL AND deleted.[Co] IS NOT NULL) OR (inserted.[Co] IS NOT NULL AND deleted.[Co] IS NULL))



 END 

 IF UPDATE([Add1])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Add1]' ,  CONVERT(VARCHAR(MAX), deleted.[Add1]) ,  CONVERT(VARCHAR(MAX), inserted.[Add1]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Add1] <> deleted.[Add1]) OR (inserted.[Add1] IS NULL AND deleted.[Add1] IS NOT NULL) OR (inserted.[Add1] IS NOT NULL AND deleted.[Add1] IS NULL))



 END 

 IF UPDATE([Add2])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Add2]' ,  CONVERT(VARCHAR(MAX), deleted.[Add2]) ,  CONVERT(VARCHAR(MAX), inserted.[Add2]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Add2] <> deleted.[Add2]) OR (inserted.[Add2] IS NULL AND deleted.[Add2] IS NOT NULL) OR (inserted.[Add2] IS NOT NULL AND deleted.[Add2] IS NULL))



 END 

 IF UPDATE([BET])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[BET]' ,  CONVERT(VARCHAR(MAX), deleted.[BET]) ,  CONVERT(VARCHAR(MAX), inserted.[BET]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[BET] <> deleted.[BET]) OR (inserted.[BET] IS NULL AND deleted.[BET] IS NOT NULL) OR (inserted.[BET] IS NOT NULL AND deleted.[BET] IS NULL))



 END 

 IF UPDATE([BuildingNum])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[BuildingNum]' ,  CONVERT(VARCHAR(MAX), deleted.[BuildingNum]) ,  CONVERT(VARCHAR(MAX), inserted.[BuildingNum]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[BuildingNum] <> deleted.[BuildingNum]) OR (inserted.[BuildingNum] IS NULL AND deleted.[BuildingNum] IS NOT NULL) OR (inserted.[BuildingNum] IS NOT NULL AND deleted.[BuildingNum] IS NULL))



 END 

 IF UPDATE([City])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[City]' ,  CONVERT(VARCHAR(MAX), deleted.[City]) ,  CONVERT(VARCHAR(MAX), inserted.[City]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[City] <> deleted.[City]) OR (inserted.[City] IS NULL AND deleted.[City] IS NOT NULL) OR (inserted.[City] IS NOT NULL AND deleted.[City] IS NULL))



 END 

 IF UPDATE([EnergyStrRat])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[EnergyStrRat]' ,  CONVERT(VARCHAR(MAX), deleted.[EnergyStrRat]) ,  CONVERT(VARCHAR(MAX), inserted.[EnergyStrRat]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[EnergyStrRat] <> deleted.[EnergyStrRat]) OR (inserted.[EnergyStrRat] IS NULL AND deleted.[EnergyStrRat] IS NOT NULL) OR (inserted.[EnergyStrRat] IS NOT NULL AND deleted.[EnergyStrRat] IS NULL))



 END 

 IF UPDATE([LEEDTarget])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[LEEDTarget]' ,  CONVERT(VARCHAR(MAX), deleted.[LEEDTarget]) ,  CONVERT(VARCHAR(MAX), inserted.[LEEDTarget]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[LEEDTarget] <> deleted.[LEEDTarget]) OR (inserted.[LEEDTarget] IS NULL AND deleted.[LEEDTarget] IS NOT NULL) OR (inserted.[LEEDTarget] IS NOT NULL AND deleted.[LEEDTarget] IS NULL))



 END 

 IF UPDATE([OccOwnership])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[OccOwnership]' ,  CONVERT(VARCHAR(MAX), deleted.[OccOwnership]) ,  CONVERT(VARCHAR(MAX), inserted.[OccOwnership]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[OccOwnership] <> deleted.[OccOwnership]) OR (inserted.[OccOwnership] IS NULL AND deleted.[OccOwnership] IS NOT NULL) OR (inserted.[OccOwnership] IS NOT NULL AND deleted.[OccOwnership] IS NULL))



 END 

 IF UPDATE([Occupant])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Occupant]' ,  CONVERT(VARCHAR(MAX), deleted.[Occupant]) ,  CONVERT(VARCHAR(MAX), inserted.[Occupant]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Occupant] <> deleted.[Occupant]) OR (inserted.[Occupant] IS NULL AND deleted.[Occupant] IS NOT NULL) OR (inserted.[Occupant] IS NOT NULL AND deleted.[Occupant] IS NULL))



 END 

 IF UPDATE([Owner])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Owner]' ,  CONVERT(VARCHAR(MAX), deleted.[Owner]) ,  CONVERT(VARCHAR(MAX), inserted.[Owner]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Owner] <> deleted.[Owner]) OR (inserted.[Owner] IS NULL AND deleted.[Owner] IS NOT NULL) OR (inserted.[Owner] IS NOT NULL AND deleted.[Owner] IS NULL))



 END 

 IF UPDATE([Project])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Project]' ,  CONVERT(VARCHAR(MAX), deleted.[Project]) ,  CONVERT(VARCHAR(MAX), inserted.[Project]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Project] <> deleted.[Project]) OR (inserted.[Project] IS NULL AND deleted.[Project] IS NOT NULL) OR (inserted.[Project] IS NOT NULL AND deleted.[Project] IS NULL))



 END 

 IF UPDATE([SameAddAs])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[SameAddAs]' ,  CONVERT(VARCHAR(MAX), deleted.[SameAddAs]) ,  CONVERT(VARCHAR(MAX), inserted.[SameAddAs]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[SameAddAs] <> deleted.[SameAddAs]) OR (inserted.[SameAddAs] IS NULL AND deleted.[SameAddAs] IS NOT NULL) OR (inserted.[SameAddAs] IS NOT NULL AND deleted.[SameAddAs] IS NULL))



 END 

 IF UPDATE([SqFt])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[SqFt]' ,  CONVERT(VARCHAR(MAX), deleted.[SqFt]) ,  CONVERT(VARCHAR(MAX), inserted.[SqFt]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[SqFt] <> deleted.[SqFt]) OR (inserted.[SqFt] IS NULL AND deleted.[SqFt] IS NOT NULL) OR (inserted.[SqFt] IS NOT NULL AND deleted.[SqFt] IS NULL))



 END 

 IF UPDATE([State])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[State]' ,  CONVERT(VARCHAR(MAX), deleted.[State]) ,  CONVERT(VARCHAR(MAX), inserted.[State]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[State] <> deleted.[State]) OR (inserted.[State] IS NULL AND deleted.[State] IS NOT NULL) OR (inserted.[State] IS NOT NULL AND deleted.[State] IS NULL))



 END 

 IF UPDATE([Zip])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Zip]' ,  CONVERT(VARCHAR(MAX), deleted.[Zip]) ,  CONVERT(VARCHAR(MAX), inserted.[Zip]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Zip] <> deleted.[Zip]) OR (inserted.[Zip] IS NULL AND deleted.[Zip] IS NOT NULL) OR (inserted.[Zip] IS NOT NULL AND deleted.[Zip] IS NULL))



 END 

 IF UPDATE([Notes])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Notes]' ,  CONVERT(VARCHAR(MAX), deleted.[Notes]) ,  CONVERT(VARCHAR(MAX), inserted.[Notes]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Notes] <> deleted.[Notes]) OR (inserted.[Notes] IS NULL AND deleted.[Notes] IS NOT NULL) OR (inserted.[Notes] IS NOT NULL AND deleted.[Notes] IS NULL))



 END 

 IF UPDATE([UniqueAttchID])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[UniqueAttchID]' ,  CONVERT(VARCHAR(MAX), deleted.[UniqueAttchID]) ,  CONVERT(VARCHAR(MAX), inserted.[UniqueAttchID]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[UniqueAttchID] <> deleted.[UniqueAttchID]) OR (inserted.[UniqueAttchID] IS NULL AND deleted.[UniqueAttchID] IS NOT NULL) OR (inserted.[UniqueAttchID] IS NOT NULL AND deleted.[UniqueAttchID] IS NULL))



 END 

 IF UPDATE([HistoricalYN])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[HistoricalYN]' ,  CONVERT(VARCHAR(MAX), deleted.[HistoricalYN]) ,  CONVERT(VARCHAR(MAX), inserted.[HistoricalYN]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[HistoricalYN] <> deleted.[HistoricalYN]) OR (inserted.[HistoricalYN] IS NULL AND deleted.[HistoricalYN] IS NOT NULL) OR (inserted.[HistoricalYN] IS NOT NULL AND deleted.[HistoricalYN] IS NULL))



 END 

 IF UPDATE([Description])
 BEGIN   INSERT dbo.HQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)

   SELECT 'budProjectBuildings' , '<KeyString Building Number = "' + REPLACE(CAST(inserted.[BuildingNum] AS VARCHAR(MAX)),'"', '&quot;') + '" Project = "' + REPLACE(CAST(inserted.[Project] AS VARCHAR(MAX)),'"', '&quot;') + '" />' , inserted.Co , 'C' , '[Description]' ,  CONVERT(VARCHAR(MAX), deleted.[Description]) ,  CONVERT(VARCHAR(MAX), inserted.[Description]) , GETDATE() , SUSER_SNAME()
		FROM inserted
			INNER JOIN deleted
         ON  inserted.[KeyID] = deleted.[KeyID] 
         AND ((inserted.[Description] <> deleted.[Description]) OR (inserted.[Description] IS NULL AND deleted.[Description] IS NOT NULL) OR (inserted.[Description] IS NOT NULL AND deleted.[Description] IS NULL))



 END 

 END TRY 
 BEGIN CATCH 
   DECLARE	@ErrorMessage	NVARCHAR(4000), 
				@ErrorSeverity	INT; 

   SELECT	@ErrorMessage = 'Error '+ ISNULL(ERROR_MESSAGE(),'') +' in [dbo].[dbo.vtbudProjectBuildings_Audit_Update] trigger', 
				@ErrorSeverity = ERROR_SEVERITY(); 

   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) 
 END CATCH 
GO
EXEC sp_settriggerorder N'[dbo].[vtbudProjectBuildings_Audit_Update]', 'last', 'update', null
GO
CREATE UNIQUE CLUSTERED INDEX [biudProjectBuildings] ON [dbo].[budProjectBuildings] ([Co], [Project], [BuildingNum]) ON [PRIMARY]
GO