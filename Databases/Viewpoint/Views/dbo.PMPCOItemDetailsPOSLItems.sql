SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[PMPCOItemDetailsPOSLItems]
AS
SELECT JCCo, Job, Phase, JCCType, SLItem AS 'Item', MIN([Description]) AS 'Description', SL, '' AS 'PO' FROM SLIT
GROUP BY JCCo, Job, Phase, JCCType, SLItem, SL
	UNION
SELECT PMCo AS 'JCCo', Project AS 'Job', Phase, CostType AS 'JCCType', SLItem AS 'Item', MIN(SLItemDescription) AS 'Description', SL, '' AS 'PO' FROM PMSL
WHERE NOT EXISTS (SELECT 1 FROM SLIT WHERE PMSL.PMCo = SLIT.JCCo AND PMSL.Project = SLIT.Job AND PMSL.SL = SLIT.SL  AND PMSL.SLItem = SLIT.SLItem) 
GROUP BY PMCo, Project, Phase, CostType, SLItem, SL
	UNION
SELECT JCCo, Job, Phase, JCCType, POItem AS 'Item', MIN([Description]) AS 'Description', '' AS 'SL', PO FROM dbo.POIT
GROUP BY JCCo, Job, Phase, JCCType, POItem, PO
	UNION
SELECT PMCo AS 'JCCo', Project AS 'Job', Phase, CostType AS 'JCCType', POItem AS 'Item', MIN(MtlDescription) AS 'Description', '' AS 'SL', PO FROM PMMF
WHERE NOT EXISTS (SELECT 1 FROM POIT WHERE PMMF.PMCo = POIT.JCCo AND PMMF.Project = POIT.Job AND PMMF.PO = POIT.PO  AND PMMF.POItem = POIT.POItem) 
GROUP BY PMCo, Project, Phase, CostType, POItem, PO



GO
GRANT SELECT ON  [dbo].[PMPCOItemDetailsPOSLItems] TO [public]
GRANT INSERT ON  [dbo].[PMPCOItemDetailsPOSLItems] TO [public]
GRANT DELETE ON  [dbo].[PMPCOItemDetailsPOSLItems] TO [public]
GRANT UPDATE ON  [dbo].[PMPCOItemDetailsPOSLItems] TO [public]
GO
