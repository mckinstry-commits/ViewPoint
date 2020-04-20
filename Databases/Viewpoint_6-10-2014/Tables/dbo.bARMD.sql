CREATE TABLE [dbo].[bARMD]
(
[ARCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[ARTrans] [dbo].[bTrans] NOT NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NOT NULL,
[DistDate] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Amount] [dbo].[bDollar] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARMD] ON [dbo].[bARMD] ([ARCo], [Mth], [ARTrans], [CustGroup], [MiscDistCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
