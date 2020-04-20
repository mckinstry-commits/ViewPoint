CREATE TABLE [dbo].[bPRGB]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[LiabCode] [dbo].[bEDLCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGB] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRGB] ON [dbo].[bPRGB] ([PRCo], [PRGroup], [LiabCode]) ON [PRIMARY]
GO