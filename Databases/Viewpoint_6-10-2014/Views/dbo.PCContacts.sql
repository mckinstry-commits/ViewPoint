SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [dbo].[PCContacts] as select a.* From vPCContacts a



GO
GRANT SELECT ON  [dbo].[PCContacts] TO [public]
GRANT INSERT ON  [dbo].[PCContacts] TO [public]
GRANT DELETE ON  [dbo].[PCContacts] TO [public]
GRANT UPDATE ON  [dbo].[PCContacts] TO [public]
GRANT SELECT ON  [dbo].[PCContacts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCContacts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCContacts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCContacts] TO [Viewpoint]
GO
