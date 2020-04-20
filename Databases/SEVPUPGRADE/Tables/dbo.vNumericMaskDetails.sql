CREATE TABLE [dbo].[vNumericMaskDetails]
(
[MaskId] [int] NOT NULL IDENTITY(1, 1),
[Scale] [int] NULL,
[ThousandsSeparator] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vNumericMaskDetails] ADD CONSTRAINT [PK_vNumericMaskDetails] PRIMARY KEY CLUSTERED  ([MaskId]) ON [PRIMARY]
GO
