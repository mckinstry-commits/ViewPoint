CREATE TABLE [dbo].[vRPUP]
(
[VPUserName] [dbo].[bVPUserName] NOT NULL,
[ReportID] [int] NOT NULL,
[PrinterName] [varchar] (256) COLLATE Latin1_General_BIN NULL,
[PaperSource] [int] NULL,
[PaperSize] [int] NULL,
[Duplex] [tinyint] NULL,
[Orientation] [tinyint] NULL,
[LastAccessed] [datetime] NULL,
[Zoom] [int] NULL,
[ViewerWidth] [int] NULL,
[ViewerHeight] [int] NULL,
[ExportFormat] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPUPd] ON [dbo].[vRPUP]
    FOR DELETE
AS
/************************************************************
 * Created: ChrisC 2011-05-17
 * Modified: 
 *
 * Delete trigger on report user preferences (vRPUP)
 *
 * Adds HQ Audit entry 
 *
 ************************************************************/
DECLARE @numrows int,
        @errmsg  varchar(255)

SELECT  @numrows = @@ROWCOUNT
IF @numrows = 0 
    RETURN

SET NOCOUNT ON

BEGIN TRY
    /* Audit deletions */
	INSERT  dbo.bHQMA
			( TableName,
			  KeyString,
			  Co,
			  RecType,
			  FieldName,
			  OldValue,
			  NewValue,
			  DateTime,
			  UserName
			)
			SELECT  'vRPUP',
					'UserName: ' + VPUserName + ' Report ID: '
					+ CONVERT(varchar(12), ReportID),
					NULL,
					'D',
					NULL,
					NULL,
					NULL,
					GETDATE(),
					CASE WHEN SUSER_NAME() = 'viewpointcs' THEN HOST_NAME()
						 ELSE SUSER_NAME()
					END
			FROM    deleted
END TRY
BEGIN CATCH
	IF @@TRANCOUNT <> 0 BEGIN ROLLBACK TRAN END
	SELECT  @errmsg = ERROR_MESSAGE()
        + ' - cannot delete report user preferences.'
	RAISERROR(@errmsg,15,2)
END CATCH



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPUPi] ON [dbo].[vRPUP]
    FOR INSERT
AS
/*********************************************************
 * Created: ChrisC 2011-05-17
 * Modified: 
 *
 * Insert trigger on report user preferences (vRPRP)
 *
 * Adds HQ Audit entry
 *
 *********************************************************/
DECLARE @numrows int,
        @errmsg  varchar(255)

SELECT  @numrows = @@ROWCOUNT
IF @numrows = 0 
    RETURN

SET NOCOUNT ON

BEGIN TRY
    /* Audit inserts */
    INSERT  dbo.bHQMA
        ( TableName,
          KeyString,
          Co,
          RecType,
          FieldName,
          OldValue,
          NewValue,
          DateTime,
          UserName
        )
        SELECT  'vRPUP',
                'UserName: ' + VPUserName + ' Report ID: '
                + CONVERT(varchar(12), ReportID),
                NULL,
                'A',
                NULL,
                NULL,
                NULL,
                GETDATE(),
                CASE WHEN SUSER_NAME() = 'viewpointcs' THEN HOST_NAME()
                     ELSE SUSER_NAME()
                END
        FROM    inserted

END TRY
BEGIN CATCH
	IF @@TRANCOUNT <> 0 BEGIN ROLLBACK TRAN END
	SELECT  @errmsg = ISNULL(@errmsg, '')
        + ' - cannot insert report user preferences.'
	RAISERROR(@errmsg,15,2)
END CATCH
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[vtRPUPu] ON [dbo].[vRPUP]
    FOR UPDATE
AS
/*********************************************************
 * Created: ChrisC 2011-05-17
 * Modified: 
 *
 * Update trigger on report user preferences (vRPUP)
 *
 * Adds HQ Audit entry
 *
 *********************************************************/
DECLARE @numrows INT,
        @errmsg  VARCHAR(255)

SELECT  @numrows = @@ROWCOUNT
IF @numrows = 0 
    RETURN

SET NOCOUNT ON

BEGIN TRY
  /* Audit updates */
  --[PrinterName] [varchar](256) NULL,
  IF UPDATE(PrinterName)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C', 
           'PrinterName',
           d.PrinterName,
           i.PrinterName,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.PrinterName, '') <> ISNULL(d.PrinterName, '')

  --[PaperSource] [int] NULL,
  IF UPDATE(PaperSource)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'PaperSource',
           d.PaperSource,
           i.PaperSource,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.PaperSource, 0) <> ISNULL(d.PaperSource, 0)

  --[PaperSize] [int] NULL,
  IF UPDATE(PaperSize)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'PaperSize',
           d.PaperSize,
           i.PaperSize,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.PaperSize, 0) <> ISNULL(d.PaperSize, 0)

  --[Duplex] [tinyint] NULL,
  IF UPDATE(Duplex)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'Duplex',
           d.Duplex,
           i.Duplex,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.Duplex, 0) <> ISNULL(d.Duplex, 0)

  --[Orientation] [tinyint] NULL,
  IF UPDATE(Orientation)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'Orientation',
           d.Orientation,
           i.Orientation,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.Orientation, 0) <> ISNULL(d.Orientation, 0)

  --[LastAccessed] [datetime] NULL,
  --Logging this would cause a lot of noise for little value, so don't log it

  --[Zoom] [int] NULL,
  IF UPDATE(Zoom)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'Zoom',
           d.Zoom,
           i.Zoom,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.Zoom, 0) <> ISNULL(d.Zoom, 0)

  --[ViewerWidth] [int] NULL,
  IF UPDATE(ViewerWidth)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'ViewerWidth',
           d.ViewerWidth,
           i.ViewerWidth,
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.ViewerWidth, 0) <> ISNULL(d.ViewerWidth, 0)

  --[ViewerHeight] [int] NULL
  IF UPDATE(ViewerHeight)
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    SELECT 'vRPUP', 'UserName: ' + i.VPUserName + ' Report ID: ' + CONVERT(VARCHAR, i.ReportID), NULL, 'C',
           'ViewerHeight',
           CONVERT(VARCHAR, d.ViewerHeight),
           CONVERT(VARCHAR, i.ViewerHeight),
           Getdate(), CASE WHEN Suser_name() = 'viewpointcs' THEN Host_name() ELSE Suser_name() END
    FROM   inserted i
           JOIN deleted d
             ON i.ReportID = d.ReportID
            AND i.VPUserName = d.VPUserName
    WHERE  ISNULL(i.ViewerHeight, 0) <> ISNULL(d.ViewerHeight, 0)

END TRY
BEGIN CATCH
	IF @@TRANCOUNT <> 0 BEGIN ROLLBACK TRAN END
	SELECT  @errmsg = ERROR_MESSAGE()
        + ' - cannot update report user preferences.'
	RAISERROR(@errmsg,15,2)
END CATCH
GO
CREATE UNIQUE CLUSTERED INDEX [viRPUP] ON [dbo].[vRPUP] ([VPUserName], [ReportID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
