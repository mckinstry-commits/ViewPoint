CREATE TABLE [dbo].[vPMEmailSignature]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UserName] [dbo].[bVPUserName] NOT NULL,
[Sequence] [int] NOT NULL,
[Title] [dbo].[bDesc] NOT NULL,
[Signature] [dbo].[bFormattedNotes] NULL,
[IsDefault] [dbo].[bYN] NULL CONSTRAINT [DF_vPMEmailSignature_IsDefault] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vPMEmailSignature] ADD CONSTRAINT [PK_vPMEmailSignature] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
