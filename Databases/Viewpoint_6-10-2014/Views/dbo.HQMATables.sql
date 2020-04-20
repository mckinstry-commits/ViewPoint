SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[HQMATables]
AS 
/***********************************************************************
*	Created by: 	CC 05/28/2009 - View that returns a list of distinct tables in HQMA
* 
*	Altered by: 	
* 
* 	Returns:		All unique tables listed in HQMA, this is for lookup in VA Audit Log Viewer
* 
***********************************************************************/

	SELECT DISTINCT TableName
	FROM bHQMA
GO
GRANT SELECT ON  [dbo].[HQMATables] TO [public]
GRANT INSERT ON  [dbo].[HQMATables] TO [public]
GRANT DELETE ON  [dbo].[HQMATables] TO [public]
GRANT UPDATE ON  [dbo].[HQMATables] TO [public]
GRANT SELECT ON  [dbo].[HQMATables] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQMATables] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQMATables] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQMATables] TO [Viewpoint]
GO
