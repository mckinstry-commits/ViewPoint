CREATE TABLE [dbo].[vVPCanvasGridParameters]
(
[ParamterId] [int] NOT NULL IDENTITY(1, 1),
[GridConfigurationId] [int] NULL,
[Name] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[SqlType] [int] NOT NULL,
[ParameterValue] [varchar] (256) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
