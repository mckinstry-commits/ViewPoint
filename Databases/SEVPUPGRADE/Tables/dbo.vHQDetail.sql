CREATE TABLE [dbo].[vHQDetail]
(
[HQDetailID] [bigint] NOT NULL IDENTITY(1, 1),
[Source] [dbo].[bSource] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vHQDetail] ADD CONSTRAINT [PK_vHQDetail] PRIMARY KEY CLUSTERED  ([HQDetailID]) ON [PRIMARY]
GO
