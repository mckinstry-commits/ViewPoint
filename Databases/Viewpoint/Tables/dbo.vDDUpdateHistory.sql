CREATE TABLE [dbo].[vDDUpdateHistory]
(
[SequenceID] [int] NOT NULL IDENTITY(1, 1),
[UpdateType] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[DownloadDate] [datetime] NOT NULL,
[Description] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[FQDN_ComputerName] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Download_Path] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Download_User_Name] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DateInstalled] [datetime] NULL,
[Title] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[VCSUpdateManager_MACAddress] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[Product_Version] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[Product_Code] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Service_Pack] [varchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
