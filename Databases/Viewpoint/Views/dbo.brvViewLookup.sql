SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.brvViewLookup
AS
SELECT DISTINCT TOP (100) PERCENT o.name, ISNULL(dd.Description, ud.Description) AS Description
FROM         sys.sysobjects AS o LEFT OUTER JOIN
                      dbo.DDTH AS dd ON o.name = dd.TableName LEFT OUTER JOIN
                      dbo.UDTH AS ud ON o.name = ud.TableName
WHERE     (o.type = 'V') AND (dd.Description IS NOT NULL) OR
                      (o.type = 'V') AND (ud.Description IS NOT NULL)
ORDER BY o.name

GO
GRANT SELECT ON  [dbo].[brvViewLookup] TO [public]
GRANT INSERT ON  [dbo].[brvViewLookup] TO [public]
GRANT DELETE ON  [dbo].[brvViewLookup] TO [public]
GRANT UPDATE ON  [dbo].[brvViewLookup] TO [public]
GO
