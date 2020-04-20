CREATE TABLE [dbo].[vVPPartFormChangedParameters]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[ColumnName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SqlType] [int] NOT NULL,
[ParameterValue] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ViewName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[FormChangedID] [int] NOT NULL,
[ParameterOrder] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPPartFormChangedParameters] ADD CONSTRAINT [PK__vVPPartFormChang__7EEA8729] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPPartFormChangedParameters] WITH NOCHECK ADD CONSTRAINT [FK_vVPPartFormChangedParameters_vVPPartFormChangedMessages] FOREIGN KEY ([FormChangedID]) REFERENCES [dbo].[vVPPartFormChangedMessages] ([KeyID])
GO
ALTER TABLE [dbo].[vVPPartFormChangedParameters] NOCHECK CONSTRAINT [FK_vVPPartFormChangedParameters_vVPPartFormChangedMessages]
GO
