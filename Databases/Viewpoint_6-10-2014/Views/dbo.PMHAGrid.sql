SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************
* Created By:	GF 04/25/2008 - issue #125958
* Modified By:
*
* Used in PM Document Distribution Audit form to display
* attachments on the related tab.
*
*************************************/

CREATE view [dbo].[PMHAGrid] as 
		select i.SourceTableName as [SourceTableName], i.SourceKeyId as [SourceKeyId],
				i.CreatedDateTime as [CreatedDateTime], a.PMHIKeyId as [KeyId], a.AttachmentID 
From PMHA a join PMHI i on i.KeyId=a.PMHIKeyId

GO
GRANT SELECT ON  [dbo].[PMHAGrid] TO [public]
GRANT INSERT ON  [dbo].[PMHAGrid] TO [public]
GRANT DELETE ON  [dbo].[PMHAGrid] TO [public]
GRANT UPDATE ON  [dbo].[PMHAGrid] TO [public]
GRANT SELECT ON  [dbo].[PMHAGrid] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMHAGrid] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMHAGrid] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMHAGrid] TO [Viewpoint]
GO
