CREATE TABLE [dbo].[pPortalAudit]
(
[PortalAuditID] [int] NOT NULL IDENTITY(1, 1),
[Type] [char] (1) COLLATE Latin1_General_BIN NULL,
[TableName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[PrimaryKey] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[FieldName] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[UpdateDate] [datetime] NULL,
[UserName] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================================================================
-- Author:		Chris G.
-- Create date: 8/23/2010
-- Description:	Save of table update dates so Portal can query the info quickly. 
-- =============================================================================================
CREATE TRIGGER [dbo].[pPortalAuditi] 
   ON  [dbo].[pPortalAudit]
   FOR insert
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DECLARE @TableName VARCHAR(128)
    DECLARE @UpdateDate DATETIME
    
    SELECT @TableName = (SELECT TOP 1 TableName FROM inserted)
    SELECT @UpdateDate = (SELECT TOP 1 UpdateDate FROM inserted)
    
	IF @TableName IS NOT NULL		
		BEGIN			
			IF NOT EXISTS(SELECT TOP 1 1 FROM pPortalTableCache WHERE TableName = @TableName)
				BEGIN
					INSERT INTO pPortalTableCache (TableName, LastUpdatedDate) VALUES (@TableName, @UpdateDate)
				END
			ELSE
				BEGIN
					UPDATE pPortalTableCache SET LastUpdatedDate = @UpdateDate WHERE TableName = @TableName
				END
		END
END


/****** Object:  StoredProcedure [dbo].[vpspCachedPortalTablesLastUpdatedGet]    Script Date: 08/23/2010 10:25:55 ******/
SET ANSI_NULLS ON

GO
ALTER TABLE [dbo].[pPortalAudit] ADD CONSTRAINT [PK_PortalAudit] PRIMARY KEY CLUSTERED  ([PortalAuditID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[pPortalAudit] TO [public]
GRANT INSERT ON  [dbo].[pPortalAudit] TO [public]
GRANT DELETE ON  [dbo].[pPortalAudit] TO [public]
GRANT UPDATE ON  [dbo].[pPortalAudit] TO [public]
GRANT SELECT ON  [dbo].[pPortalAudit] TO [VCSPortal]
GRANT INSERT ON  [dbo].[pPortalAudit] TO [VCSPortal]
GRANT DELETE ON  [dbo].[pPortalAudit] TO [VCSPortal]
GRANT UPDATE ON  [dbo].[pPortalAudit] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pPortalAudit] TO [viewpointcs]
GRANT INSERT ON  [dbo].[pPortalAudit] TO [viewpointcs]
GRANT DELETE ON  [dbo].[pPortalAudit] TO [viewpointcs]
GRANT UPDATE ON  [dbo].[pPortalAudit] TO [viewpointcs]
GO
