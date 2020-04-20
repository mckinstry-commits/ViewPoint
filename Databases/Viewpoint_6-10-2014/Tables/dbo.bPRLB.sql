CREATE TABLE [dbo].[bPRLB]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[Employee] [dbo].[bEmployee] NOT NULL,
[LeaveCode] [dbo].[bLeaveCode] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NOT NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Rate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bPRLB_Rate] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRLB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [biPRLB] ON [dbo].[bPRLB] ([PRCo], [Employee], [LeaveCode], [EarnCode], [Type]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
