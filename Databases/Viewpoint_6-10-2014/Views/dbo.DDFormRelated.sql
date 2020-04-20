SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[DDFormRelated] AS
	SELECT a.*, b.Title
	FROM vDDFormRelated a
	INNER JOIN dbo.vDDFH b ON b.Form = a.RelatedForm




GO
GRANT SELECT ON  [dbo].[DDFormRelated] TO [public]
GRANT INSERT ON  [dbo].[DDFormRelated] TO [public]
GRANT DELETE ON  [dbo].[DDFormRelated] TO [public]
GRANT UPDATE ON  [dbo].[DDFormRelated] TO [public]
GRANT SELECT ON  [dbo].[DDFormRelated] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFormRelated] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFormRelated] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFormRelated] TO [Viewpoint]
GO
