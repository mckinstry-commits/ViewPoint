CREATE TABLE [dbo].[vHQProjectStatusCodes]
(
[ProjectStatusCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ActiveLookup] [dbo].[bYN] NULL,
[StatusOrder] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQProjectStatusCodes] ADD CONSTRAINT [PK_vHQProjectStatuses] PRIMARY KEY CLUSTERED  ([ProjectStatusCode]) ON [PRIMARY]
GO
