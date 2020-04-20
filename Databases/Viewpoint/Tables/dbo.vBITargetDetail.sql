CREATE TABLE [dbo].[vBITargetDetail]
(
[BICo] [dbo].[bCompany] NOT NULL,
[TargetName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[Revision] [int] NOT NULL,
[TargetLevel] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [IX_vBITargetDetail_TargetName_Revision] ON [dbo].[vBITargetDetail] ([BICo], [TargetName], [Revision]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
ALTER TABLE [dbo].[vBITargetDetail] ADD CONSTRAINT [PK_vBITargetDetail] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
