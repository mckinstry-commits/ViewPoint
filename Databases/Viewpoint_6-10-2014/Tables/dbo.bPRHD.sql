CREATE TABLE [dbo].[bPRHD]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[PREndDate] [dbo].[bDate] NOT NULL,
[Holiday] [dbo].[bDate] NOT NULL,
[ApplyToCraft] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPRHD_ApplyToCraft] DEFAULT ('Y'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPRHD] WITH NOCHECK ADD CONSTRAINT [CK_bPRHD_ApplyToCraft] CHECK (([ApplyToCraft]='Y' OR [ApplyToCraft]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRHD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRHD] ON [dbo].[bPRHD] ([PRCo], [PRGroup], [PREndDate], [Holiday]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
