CREATE TABLE [dbo].[vRFEpisodeUsage]
(
[EpisodeID] [bigint] NOT NULL IDENTITY(1, 1),
[Application] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ApplicationVersion] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[FrameworkVersion] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[OSCaption] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[OSVersion] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ProcessorName] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ProcessorID] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[ProcessorCount] [tinyint] NOT NULL,
[Organization] [varchar] (256) COLLATE Latin1_General_BIN NOT NULL,
[StartDateTime] [datetime] NOT NULL,
[EndDateTime] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [viRFEpisodeUsage] ON [dbo].[vRFEpisodeUsage] ([EpisodeID]) ON [PRIMARY]
GO
