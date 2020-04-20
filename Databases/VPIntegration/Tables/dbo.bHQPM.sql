CREATE TABLE [dbo].[bHQPM]
(
[Country] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NOT NULL,
[PriceIndex] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[FinishedMatl] [dbo].[bMatl] NOT NULL,
[ComponentMatl] [dbo].[bMatl] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[UniqueAttchID] [uniqueidentifier] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[bHQPM] ADD CONSTRAINT [PK_bHQPM] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biHQPM] ON [dbo].[bHQPM] ([Country], [State], [PriceIndex], [MatlGroup], [FinishedMatl], [ComponentMatl]) ON [PRIMARY]
GO
