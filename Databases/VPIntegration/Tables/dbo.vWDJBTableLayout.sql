CREATE TABLE [dbo].[vWDJBTableLayout]
(
[JobName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[IsPivot] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_IsPivot] DEFAULT ('N'),
[WidthMode] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_WidthMode] DEFAULT ((0)),
[Width] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_Width] DEFAULT ((500)),
[BorderStyle] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_BorderStyle] DEFAULT ((2)),
[BorderColor] [varchar] (7) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vWDJBTableLayout_BorderColor] DEFAULT ('#000000'),
[BorderWidth] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_BorderWidth] DEFAULT ((1)),
[HeaderIsVisible] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_HeaderIsVisible] DEFAULT ('Y'),
[HeaderBackgroundColor] [varchar] (7) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vWDJBTableLayout_HeaderBackgroundColor] DEFAULT ('#CCCCCC'),
[HeaderCellpadding] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_HeaderCellpadding] DEFAULT ((3)),
[DetailBackgroundColor] [varchar] (7) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vWDJBTableLayout_DetailBackgroundColor] DEFAULT ('#FFFFFF'),
[DetailCellpadding] [int] NOT NULL CONSTRAINT [DF_vWDJBTableLayout_DetailCellpadding] DEFAULT ((3)),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vWDJBTableLayout] ADD CONSTRAINT [PK_vWDJBTableLayout] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_vWDJBTableLayout_JobName] ON [dbo].[vWDJBTableLayout] ([JobName]) ON [PRIMARY]
GO
