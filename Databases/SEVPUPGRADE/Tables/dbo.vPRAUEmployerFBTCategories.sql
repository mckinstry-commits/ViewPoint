CREATE TABLE [dbo].[vPRAUEmployerFBTCategories]
(
[Category] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Description] [nchar] (60) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPRAUEmployerFBTCategories] ADD CONSTRAINT [PK_vPRAUEmployerFBTCategories] PRIMARY KEY CLUSTERED  ([Category]) ON [PRIMARY]
GO
