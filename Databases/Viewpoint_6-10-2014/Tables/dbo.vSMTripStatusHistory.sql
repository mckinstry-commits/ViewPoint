CREATE TABLE [dbo].[vSMTripStatusHistory]
(
[SMTripID] [bigint] NOT NULL,
[DateTime] [datetime] NOT NULL,
[StatusValue] [smallint] NOT NULL,
[StatusText] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL
) ON [PRIMARY]
GO
