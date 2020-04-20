CREATE TABLE [dbo].[bPRAU]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRAU] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [biPRAU] ON [dbo].[bPRAU] ([PRCo], [LeaveCode], [EarnCode], [Type]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bPRAU].[Rate]'
GO
