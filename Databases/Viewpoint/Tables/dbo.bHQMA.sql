CREATE TABLE [dbo].[bHQMA]
(
[TableName] [char] (30) COLLATE Latin1_General_BIN NOT NULL,
[KeyString] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL,
[Co] [dbo].[bCompany] NULL,
[RecType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[FieldName] [char] (30) COLLATE Latin1_General_BIN NULL,
[OldValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[NewValue] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DateTime] [datetime] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[AuditID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE CLUSTERED INDEX [IX_biHQMA_DateTime] ON [dbo].[bHQMA] ([DateTime]) WITH (FILLFACTOR=100) ON [PRIMARY]

ALTER TABLE [dbo].[bHQMA] ADD CONSTRAINT [PK_bHQMA] PRIMARY KEY NONCLUSTERED  ([AuditID]) WITH (FILLFACTOR=100) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [IX_bHQMA_TableName] ON [dbo].[bHQMA] ([TableName]) WITH (FILLFACTOR=100) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 05/22/2009
-- Description:	Delete trigger to cascade delete into HQSA
-- =============================================
CREATE TRIGGER [dbo].[vHQMAd] 
   ON  [dbo].[bHQMA] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    DELETE vHQSA 
    FROM vHQSA
    INNER JOIN deleted ON deleted.AuditID = vHQSA.AuditID
    
END

GO
