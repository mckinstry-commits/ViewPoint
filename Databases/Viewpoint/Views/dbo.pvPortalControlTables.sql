SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[pvPortalControlTables]
AS
SELECT     PortalControlID, TableID
FROM         (SELECT     PortalControlID, TopLeftTableID AS TableID
                       FROM          dbo.pPortalControlLayout
                       UNION
                       SELECT     PortalControlID, TopCenterTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_8
                       UNION
                       SELECT     PortalControlID, TopRightTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_7
                       UNION
                       SELECT     PortalControlID, CenterLeftTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_6
                       UNION
                       SELECT     PortalControlID, CenterCenterTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_5
                       UNION
                       SELECT     PortalControlID, CenterRightTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_4
                       UNION
                       SELECT     PortalControlID, BottomLeftTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_3
                       UNION
                       SELECT     PortalControlID, BottomCenterTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_2
                       UNION
                       SELECT     PortalControlID, BottomRightTableID
                       FROM         dbo.pPortalControlLayout AS pPortalControlLayout_1) AS PortalTables
WHERE     (TableID IS NOT NULL)



GO
GRANT SELECT ON  [dbo].[pvPortalControlTables] TO [public]
GRANT INSERT ON  [dbo].[pvPortalControlTables] TO [public]
GRANT DELETE ON  [dbo].[pvPortalControlTables] TO [public]
GRANT UPDATE ON  [dbo].[pvPortalControlTables] TO [public]
GRANT SELECT ON  [dbo].[pvPortalControlTables] TO [VCSPortal]
GO
