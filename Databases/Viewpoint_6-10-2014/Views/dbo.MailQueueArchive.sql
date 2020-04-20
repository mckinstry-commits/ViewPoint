SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MailQueueArchive] as select a.* From vMailQueueArchive a
GO
GRANT SELECT ON  [dbo].[MailQueueArchive] TO [public]
GRANT INSERT ON  [dbo].[MailQueueArchive] TO [public]
GRANT DELETE ON  [dbo].[MailQueueArchive] TO [public]
GRANT UPDATE ON  [dbo].[MailQueueArchive] TO [public]
GRANT SELECT ON  [dbo].[MailQueueArchive] TO [Viewpoint]
GRANT INSERT ON  [dbo].[MailQueueArchive] TO [Viewpoint]
GRANT DELETE ON  [dbo].[MailQueueArchive] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[MailQueueArchive] TO [Viewpoint]
GO
