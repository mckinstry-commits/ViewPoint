CREATE TABLE [dbo].[bPRGV]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[PRGroup] [dbo].[bGroup] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRGV] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPRGV] ON [dbo].[bPRGV] ([PRCo], [PRGroup], [LeaveCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
