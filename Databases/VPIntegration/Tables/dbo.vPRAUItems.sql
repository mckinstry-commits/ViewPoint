CREATE TABLE [dbo].[vPRAUItems]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BeginTaxYear] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[EndTaxYear] [char] (4) COLLATE Latin1_General_BIN NULL,
[ItemCode] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[ItemDescription] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tab] [char] (5) COLLATE Latin1_General_BIN NOT NULL,
[ItemOrder] [tinyint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUItems] ADD CONSTRAINT [PK_vPRAUItems_PRCo_ItemCode] PRIMARY KEY CLUSTERED  ([ItemCode]) ON [PRIMARY]
GO
