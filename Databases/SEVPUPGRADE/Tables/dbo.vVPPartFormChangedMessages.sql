CREATE TABLE [dbo].[vVPPartFormChangedMessages]
(
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[FormName] [varchar] (2048) COLLATE Latin1_General_BIN NOT NULL,
[FormTitle] [varchar] (128) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vVPPartFormChangedMessages] ADD CONSTRAINT [PK__vVPPartMessageFo__77496561] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
