SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
	Created by: AaronL/JonathanP 03/05/09
	Description: Issue #126160 Add AttachmentSecurityLevel column.
*/

CREATE VIEW [dbo].[DDFS] AS select * from vDDFS

GO
GRANT SELECT ON  [dbo].[DDFS] TO [public]
GRANT INSERT ON  [dbo].[DDFS] TO [public]
GRANT DELETE ON  [dbo].[DDFS] TO [public]
GRANT UPDATE ON  [dbo].[DDFS] TO [public]
GO
