CREATE TABLE [dbo].[vRFScenarios]
(
[ScenarioID] [int] NOT NULL IDENTITY(1, 1),
[ScenarioName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[Customer] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[UserName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[RecordingDateTime] [datetime] NOT NULL,
[Scene] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[ScenarioFileName] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[IssueNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Module] [varchar] (4) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [viRFScenariosDateTime] ON [dbo].[vRFScenarios] ([RecordingDateTime], [UserName]) INCLUDE ([ScenarioFileName], [Scene]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [viRFScenarios] ON [dbo].[vRFScenarios] ([ScenarioID]) ON [PRIMARY]
GO
