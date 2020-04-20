CREATE TABLE [dbo].[vCalendar]
(
[Date] [smalldatetime] NOT NULL,
[Month] [smalldatetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vCalendar] ADD CONSTRAINT [PK_Calendar] PRIMARY KEY CLUSTERED  ([Date]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_vCalendar_Month] ON [dbo].[vCalendar] ([Month]) ON [PRIMARY]
GO
