CREATE TABLE [dbo].[bINCW]
(
[INCo] [dbo].[bCompany] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[Loc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[PhyCnt] [dbo].[bUnits] NULL,
[CntDate] [dbo].[bDate] NULL,
[CntBy] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SysCnt] [dbo].[bUnits] NULL,
[AdjUnits] [dbo].[bUnits] NULL,
[UnitCost] [dbo].[bUnitCost] NULL,
[ECM] [dbo].[bECM] NULL,
[Ready] [dbo].[bYN] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biINCW] ON [dbo].[bINCW] ([INCo], [UserName], [Loc], [MatlGroup], [Material]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bINCW] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bINCW].[Ready]'
GO
