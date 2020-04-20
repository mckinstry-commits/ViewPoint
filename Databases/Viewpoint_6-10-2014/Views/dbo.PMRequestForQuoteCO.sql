SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[PMRequestForQuoteCO] AS 

SELECT ROW_NUMBER() OVER(ORDER BY PMCo, Project, RFQ) AS [Seq], *
FROM
(
	--PCO--
	SELECT rfq.PMCo, rfq.Project, rfq.RFQ, 
		'PCO' AS [COType], pco.PCOType AS [DocType], pco.PCO AS [Doc], pco.[Description], pco.[Status], pco.DateCreated, NULL AS [DateSent], NULL AS [DateRequired], NULL AS [DateReceived], pco.Notes, 
		ISNULL(totals.PCORevTotal, 0) AS [Amount],
		bPMSC.[Description] AS [StatusDesc]
	FROM dbo.vPMRelateRecord relate
	JOIN dbo.PMRequestForQuote rfq ON rfq.KeyID = relate.RECID
	LEFT JOIN dbo.bPMOP pco ON pco.KeyID = relate.LINKID
	LEFT JOIN dbo.PMOPTotals totals ON totals.KeyID = pco.KeyID
	LEFT JOIN dbo.bPMSC ON bPMSC.[Status] = pco.[Status]
	WHERE relate.RecTableName = 'PMRequestForQuote' AND relate.LinkTableName = 'PMOP'

	UNION ALL

	--ACO--
	SELECT rfq.PMCo, rfq.Project, rfq.RFQ, 
		'ACO' AS [COType], NULL AS [DocType], aco.ACO AS [Doc], aco.[Description], NULL AS [Status], aco.ApprovalDate AS [DateCreated], aco.DateSent, aco.DateReqd AS [DateRequired], aco.DateRecd AS [DateReceived], aco.Notes,
		ISNULL(totals.ACORevTotal, 0) AS [Amount],
		NULL AS [StatusDesc]	
	FROM dbo.vPMRelateRecord relate
	JOIN dbo.PMRequestForQuote rfq ON rfq.KeyID = relate.RECID
	LEFT JOIN dbo.bPMOH aco ON aco.KeyID = relate.LINKID
	LEFT JOIN dbo.PMOHTotals totals ON totals.PMCo = aco.PMCo AND totals.Project = aco.Project AND totals.ACO = aco.ACO
	WHERE relate.RecTableName = 'PMRequestForQuote' AND relate.LinkTableName = 'PMOH'

	UNION ALL

	--SCO--
	SELECT rfq.PMCo, rfq.Project, rfq.RFQ, 
		'SCO' AS [COType], NULL AS [DocType], CAST(sco.SubCO AS VARCHAR(10)) AS [Doc], sco.[Description], sco.[Status], sco.[Date] AS [DateCreated], sco.DateSent, sco.DateDueBack AS [DateRequired], sco.DateReceived, sco.Notes,
		ISNULL(totals.PMSLAmtCurrent, 0) AS [Amount],
		bPMSC.[Description] AS [StatusDesc]
	FROM dbo.vPMRelateRecord relate
	JOIN dbo.PMRequestForQuote rfq ON rfq.KeyID = relate.RECID
	LEFT JOIN dbo.vPMSubcontractCO sco ON sco.KeyID = relate.LINKID
	LEFT JOIN dbo.PMSCOTotal totals ON totals.SCOKeyID = sco.KeyID
	LEFT JOIN dbo.bPMSC ON bPMSC.[Status] = sco.[Status]
	WHERE relate.RecTableName = 'PMRequestForQuote' AND relate.LinkTableName = 'PMSubcontractCO'

	UNION ALL

	--POCO--
	SELECT rfq.PMCo, rfq.Project, rfq.RFQ, 
		'POCO' AS [COType], NULL AS [DocType], CAST(poco.POCONum AS VARCHAR(10)) AS [Doc], poco.[Description], poco.[Status], poco.[Date] AS [DateCreated], poco.DateSent, poco.DateDueBack AS [DateRequired], poco.DateReceived, poco.Notes,
		ISNULL(totals.PMMFAmtCurrent, 0) AS [Amount],
		bPMSC.[Description] AS [StatusDesc]
	FROM dbo.vPMRelateRecord relate
	JOIN dbo.PMRequestForQuote rfq ON rfq.KeyID = relate.RECID
	LEFT JOIN dbo.vPMPOCO poco ON poco.KeyID = relate.LINKID
	LEFT JOIN dbo.PMPOCOTotal totals ON totals.POKeyID = poco.KeyID
	LEFT JOIN dbo.bPMSC ON bPMSC.[Status] = poco.[Status]
	WHERE relate.RecTableName = 'PMRequestForQuote' AND relate.LinkTableName = 'PMPOCO'
) AS ChangeOrder
GO
GRANT SELECT ON  [dbo].[PMRequestForQuoteCO] TO [public]
GRANT INSERT ON  [dbo].[PMRequestForQuoteCO] TO [public]
GRANT DELETE ON  [dbo].[PMRequestForQuoteCO] TO [public]
GRANT UPDATE ON  [dbo].[PMRequestForQuoteCO] TO [public]
GRANT SELECT ON  [dbo].[PMRequestForQuoteCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMRequestForQuoteCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMRequestForQuoteCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMRequestForQuoteCO] TO [Viewpoint]
GO
