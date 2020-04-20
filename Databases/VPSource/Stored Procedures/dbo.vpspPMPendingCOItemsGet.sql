SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPendingCOItemsGet]
/***********************************************************
* Created:     8/28/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	GET  PM Pending Change Order Item(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @PCO bPCO, @PCOType bDocType, @UserID INT, @KeyID BIGINT = Null)
AS
BEGIN
	SET NOCOUNT ON;
	
	Select i.KeyID
	, i.PMCo
	, i.Project
	, i.PCO
	, u.Description AS 'Pending CO Description'
	, u.Description AS 'PCOItemDescription'
	, i.PCOItem
	, i.PCOType
	, t.Description AS 'PCO Type Description'
	, i.ACO
	, u.Description AS 'Approved CO Description'
	, i.ACOItem
	, i.Description
	, i.Status
	, c.Description AS 'Status Description'
	, i.ApprovedDate
	, i.UM
	, i.Units
	, i.UnitPrice
	, i.ApprovedAmt
	, i.Issue
	, ISNULL(s.Description, '') AS 'Issue Description'
	, ISNULL(dt.PCOItemDate1, 'Date Description 1') AS 'PCOItemDate1'
	, i.Date1
	, ISNULL(dt.PCOItemDate2, 'Date Description 2') AS 'PCOItemDate2'
	, i.Date2
	, ISNULL(dt.PCOItemDate3, 'Date Description 3') AS 'PCOItemDate3'
	, i.Date3
	, i.Contract
	, m.Description AS 'Contract Description'
	, i.ContractItem
	, ci.Description AS 'Contract Item Description'
	, i.ApprovedBy
	, i.ForcePhaseYN
	, 	i.FixedAmountYN
	, i.FixedAmount
	, i.Notes
	, i.BillGroup
	, b.Description AS BillGroupDescription
	, i.ChangeDays
	, i.InterfacedDate
	, i.UniqueAttchID
	, i.PendingAmount
	, i.Approved
	, @UserID AS 'UserID'
	, @PCO AS 'spPCO'
	, @PCOType AS 'spPCOType'
	
	FROM PMOI i WITH (NOLOCK)
		LEFT JOIN PMOP u WITH (NOLOCK) ON u.PMCo = i.PMCo AND u.Project = i.Project AND u.PCOType = i.PCOType AND u.PCO = i.PCO 
		LEFT JOIN PMIM s WITH (NOLOCK) ON i.PMCo = s.PMCo AND i.Project = s.Project AND i.Issue = s.Issue
		LEFT JOIN PMSC c WITH (NOLOCK) ON i.Status = c.Status
		LEFT JOIN PMDT t WITH (NOLOCK) ON i.PCOType = t.DocType
		LEFT JOIN JCCM m WITH (NOLOCK) ON m.JCCo = i.PMCo AND m.Contract = i.Contract
		LEFT JOIN JCCI ci WITH (NOLOCK) ON ci.JCCo = i.PMCo AND ci.Contract = i.Contract AND ci.Item = i.ContractItem
		LEFT JOIN JBBG b WITH (NOLOCK) ON b.JBCo = i.PMCo AND b.Contract = i.Project AND b.BillGroup = i.BillGroup
		LEFT JOIN PMDT dt WITH (NOLOCK) ON dt.DocType = i.PCOType

	WHERE  i.PMCo = @JCCo 
		AND i.Project = @Job 
		AND i.PCO = @PCO 
		AND @PCOType = i.PCOType
		AND i.KeyID = ISNULL(@KeyID, i.KeyID)

END




GO
GRANT EXECUTE ON  [dbo].[vpspPMPendingCOItemsGet] TO [VCSPortal]
GO
