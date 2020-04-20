CREATE TABLE [dbo].[bPMIH]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[Issue] [dbo].[bIssue] NOT NULL,
[Seq] [smallint] NOT NULL,
[DocType] [dbo].[bDocType] NULL,
[Document] [dbo].[bDocument] NULL,
[Rev] [tinyint] NULL,
[PCOType] [dbo].[bDocType] NULL,
[PCO] [dbo].[bPCO] NULL,
[PCOItem] [dbo].[bPCOItem] NULL,
[ACO] [dbo].[bACO] NULL,
[ACOItem] [dbo].[bACOItem] NULL,
[IssueDateTime] [datetime] NOT NULL CONSTRAINT [DF_bPMIH_IssueDateTime] DEFAULT (getdate()),
[Action] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Login] [dbo].[bVPUserName] NULL,
[ActionDate] [dbo].[bDate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
   /******************************************************/
CREATE  trigger [dbo].[btPMIHi] on [dbo].[bPMIH] for Insert as
   

/*--------------------------------------------------------------
    *
    *  insert trigger for PMIH
    *  Created By:   TV
    *  Date:         02/28/02
    *  Modified By:  JayR 03/22/2012 TK-00000  Cleanup unused variables
    *
    *--------------------------------------------------------------*/
   
   if @@rowcount = 0 return
   set nocount on
   
   --Update to add Issue add date and login
   update dbo.bPMIH 
   set Login = SUSER_SNAME(), ActionDate = getdate()
   from inserted i join bPMIH h on i.PMCo = h.PMCo and i.Project = h.Project and i.Issue = h.Issue and i.Seq = h.Seq
   
   RETURN 
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMIH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMIH] ON [dbo].[bPMIH] ([PMCo], [Project], [Issue], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
