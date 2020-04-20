CREATE TABLE [dbo].[vPMRelateRecord]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RecTableName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[RECID] [bigint] NOT NULL,
[LinkTableName] [nvarchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[LINKID] [bigint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMRelateRecordd    Script Date: 09/05/2006 ******/
CREATE trigger [dbo].[btPMRelateRecordd] on [dbo].[vPMRelateRecord] for DELETE as
/*--------------------------------------------------------------
 * Created By:	GF 01/24/2011 TFS #398
 * Modified By:  JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
 *
 *
 * Delete trigger for vPMRelateRecord
 *
 * HQMA auditing
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- insert vPMIssueHistory for the RECORD SIDE - RecTableName = 'bPMIM'
INSERT dbo.vPMIssueHistory (IssueKeyID, RelatedTableName, RelatedKeyID, Co, Project, Issue, ActionType, Login)
SELECT d.RECID, d.LinkTableName, d.LINKID, x.PMCo, x.Project, x.Issue, 'D', SUSER_SNAME()
FROM deleted d
INNER JOIN dbo.bPMIM x ON x.KeyID=d.RECID
WHERE d.RecTableName = 'PMIM'
AND NOT EXISTS(SELECT 1 FROM dbo.vPMIssueHistory h WHERE h.IssueKeyID=d.RECID
			AND h.RelatedTableName = d.LinkTableName AND h.RelatedKeyID=d.LINKID AND h.ActionType = 'D')
			

---- insert vPMIssueHistory for the LINK SIDE - LinkTableName = 'bPMIM'
INSERT dbo.vPMIssueHistory (IssueKeyID, RelatedTableName, RelatedKeyID, Co, Project, Issue, ActionType, Login)
SELECT d.LINKID, d.RecTableName, d.RECID, x.PMCo, x.Project, x.Issue, 'D', SUSER_SNAME()
FROM deleted d
INNER JOIN dbo.bPMIM x ON x.KeyID=d.LINKID
WHERE d.LinkTableName = 'PMIM'
AND NOT EXISTS(SELECT 1 FROM dbo.vPMIssueHistory h WHERE h.RelatedTableName = d.RecTableName 
			AND h.IssueKeyID=d.LINKID AND h.RelatedKeyID=d.RECID AND h.ActionType = 'D')


-- Audit inserts
insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMRelateRecord', 'RecTableName: ' + ISNULL(d.RecTableName,'') + ' RECID: ' + ISNULL(CONVERT(VARCHAR(20),d.RECID),'')
		+ ' LinkTableName: ' + ISNULL(d.LinkTableName,'') + ' LINKID: ' + ISNULL(CONVERT(VARCHAR(20),d.LINKID), ''),
		NULL, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d


RETURN





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMRelateRecordi    Script Date: 8/28/99 9:38:24 AM ******/
CREATE trigger [dbo].[btPMRelateRecordi] on [dbo].[vPMRelateRecord] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMRelateRecord
* Created By:	GF 01/24/2011 - TFS #398 
* Modified By:  JayR 03/20/2012 TK-00000 Move checks to use FK constraints.
*
*
* HQMA audit
*--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


---- insert vPMIssueHistory for the RECORD SIDE - RecTableName = 'bPMIM'
INSERT dbo.vPMIssueHistory (IssueKeyID, RelatedTableName, RelatedKeyID, Co, Project, Issue, ActionType, Login)
SELECT i.RECID, i.LinkTableName, i.LINKID, x.PMCo, x.Project, x.Issue, 'A', SUSER_SNAME()
FROM INSERTED i
INNER JOIN dbo.bPMIM x ON x.KeyID=i.RECID
WHERE i.RecTableName = 'PMIM'

---- insert vPMIssueHistory for the LINK SIDE - LinkTableName = 'bPMIM'
INSERT dbo.vPMIssueHistory (IssueKeyID, RelatedTableName, RelatedKeyID, Co, Project, Issue, ActionType, Login)
SELECT i.LINKID, i.RecTableName, i.RECID, x.PMCo, x.Project, x.Issue, 'A', SUSER_SNAME()
FROM INSERTED i
INNER JOIN dbo.bPMIM x ON x.KeyID=i.LINKID
WHERE i.LinkTableName = 'PMIM'

-- Audit inserts
insert into dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPMRelateRecord', 'RecTableName: ' + ISNULL(i.RecTableName,'') + ' RECID: ' + ISNULL(CONVERT(VARCHAR(20),i.RECID),'')
		+ ' LinkTableName: ' + ISNULL(i.LinkTableName,'') + ' LINKID: ' + ISNULL(CONVERT(VARCHAR(20),i.LINKID), ''),
		NULL, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i

RETURN



GO
ALTER TABLE [dbo].[vPMRelateRecord] ADD CONSTRAINT [PK_vPMRelateRecord] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPMRelateRecord_Link] ON [dbo].[vPMRelateRecord] ([RecTableName], [RECID], [LinkTableName], [LINKID]) ON [PRIMARY]
GO
