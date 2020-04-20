CREATE TABLE [dbo].[bWDJB]
(
[JobName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[QueryName] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[QueryType] [int] NOT NULL CONSTRAINT [DF_bWDJB_QueryType] DEFAULT ((0)),
[Enable] [dbo].[bYN] NOT NULL,
[WDCo] [dbo].[bCompany] NULL,
[FirstRun] [datetime] NULL,
[LastRun] [datetime] NULL,
[Occurs] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[mDay] [int] NULL,
[Freq] [int] NULL,
[Monday] [dbo].[bYN] NOT NULL,
[Tuesday] [dbo].[bYN] NOT NULL,
[Wednesday] [dbo].[bYN] NOT NULL,
[Thursday] [dbo].[bYN] NOT NULL,
[Friday] [dbo].[bYN] NOT NULL,
[Saturday] [dbo].[bYN] NOT NULL,
[Sunday] [dbo].[bYN] NOT NULL,
[DailyInt] [int] NOT NULL,
[HourMinute] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[StartTime] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[EndTime] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[StartDate] [smalldatetime] NOT NULL,
[EndDate] [smalldatetime] NULL,
[EmailFormat] [int] NOT NULL CONSTRAINT [DF_bWDJB_EmailFormat] DEFAULT ((0)),
[EmailTo] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[EmailCC] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[EmailSubject] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[EmailBody] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[EmailBodyHtml] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[WeekTotal] [int] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[BCC] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EmailLine] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[EmailFooter] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[IsConsolidated] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bWDJB_IsConsolidated] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biWDJB] ON [dbo].[bWDJB] ([JobName]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bWDJB] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[btWDJBd] on [dbo].[bWDJB] 
FOR DELETE AS
   
/*--------------------------------------------------------------
*
*  Delete trigger for bWFJB - Notifier Jobs - Cascade deletes records in bWDJP (Notifier Job Params) 
*
*  Created By:  JM 09/04/02
*  Modified by: TV - 23061 added isnulls
*				CC - 129920 clear hashtable for deleted jobs
*
*--------------------------------------------------------------*/
	SET NOCOUNT ON

	DELETE bWDJP 
	FROM bWDJP p 
	INNER JOIN deleted d ON p.JobName = d.JobName 

	DELETE vWFSentNotifications
	FROM vWFSentNotifications n
	INNER JOIN deleted d ON n.JobName = d.JobName

	/* Audit inserts */
	INSERT INTO  bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		SELECT 'bWDJP', 'JobName: ' + d.JobName, null, 'D', null, null, null, GETDATE(), SUSER_SNAME()
		FROM deleted d
	   
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Enable]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Monday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Tuesday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Wednesday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Thursday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Friday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Saturday]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bWDJB].[Sunday]'
GO
