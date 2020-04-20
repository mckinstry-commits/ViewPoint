CREATE TABLE [dbo].[vDDFormButtonsCustom]
(
[Form] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[ButtonID] [int] NOT NULL,
[ButtonText] [varchar] (64) COLLATE Latin1_General_BIN NOT NULL,
[Parent] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ActionType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ButtonAction] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Width] [int] NOT NULL,
[Height] [int] NOT NULL,
[ButtonTop] [int] NOT NULL,
[ButtonLeft] [int] NOT NULL,
[KeyID] [int] NOT NULL IDENTITY(1, 1),
[ButtonRefresh] [tinyint] NOT NULL CONSTRAINT [DF_vDDFormButtonsCustom_ButtonRefresh] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [bivDDFormButtonsCustom] ON [dbo].[vDDFormButtonsCustom] ([Form], [ButtonID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biKeyID] ON [dbo].[vDDFormButtonsCustom] ([KeyID]) ON [PRIMARY]
GO
