SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.pvPMLookupInternalOrExternal
AS
SELECT     'I' AS KeyField, 'Internal' AS 'IEDescription'
UNION
SELECT     'E' AS KeyField, 'External' AS 'IEDescription'


GO
GRANT SELECT ON  [dbo].[pvPMLookupInternalOrExternal] TO [public]
GRANT INSERT ON  [dbo].[pvPMLookupInternalOrExternal] TO [public]
GRANT DELETE ON  [dbo].[pvPMLookupInternalOrExternal] TO [public]
GRANT UPDATE ON  [dbo].[pvPMLookupInternalOrExternal] TO [public]
GRANT SELECT ON  [dbo].[pvPMLookupInternalOrExternal] TO [VCSPortal]
GRANT SELECT ON  [dbo].[pvPMLookupInternalOrExternal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[pvPMLookupInternalOrExternal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[pvPMLookupInternalOrExternal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[pvPMLookupInternalOrExternal] TO [Viewpoint]
GO
