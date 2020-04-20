SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[VPCanvasNavigationSettings] 
AS

/***********************************************
* Created: DK TK-14882
*
* Use:	Stores the navigation path (breadcrumb) for a user as they drill through linked queries.
* 
*******************************************/
 SELECT * FROM [dbo].[vVPCanvasNavigationSettings]
GO
GRANT SELECT ON  [dbo].[VPCanvasNavigationSettings] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasNavigationSettings] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasNavigationSettings] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasNavigationSettings] TO [public]
GO
