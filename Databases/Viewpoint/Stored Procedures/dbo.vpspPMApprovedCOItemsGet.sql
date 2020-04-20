SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPMApprovedCOItemsGet]
/***********************************************************
* Created:     8/28/09		JB		Rewrote SP/cleanup
* Modified:		GF 01/09/2011 TK-11694
* 
* Description:	Get the PM Approved Change Order Item(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @ACO bACO, @UserID int, @KeyID int = Null)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT i.KeyID
		, i.PMCo
		, i.Project
		, i.PCO
		, u.Description AS 'Pending CO Description'
		, i.PCOItem
		, i.PCOType
		, t.Description AS 'PCO Type Description'
		, i.ACO
		, a.Description AS 'Approved CO Description'
		, i.ACOItem
		, i.Description
		, a.Description AS 'ACODescription'
		, i.Description AS 'ACOItemDescription'
		, i.Status
		, c.Description AS 'Status Description'
		, i.ApprovedDate
		, i.UM
		, i.Units
		, i.UnitPrice
		, i.ApprovedAmt
		, i.Issue
		, ISNULL(s.Description, '') AS 'Issue Description'
		, i.Date1
		, i.Date2
		, i.Date3
		, i.Contract
		, m.Description AS 'Contract Description'
		, i.ContractItem
		, ci.Description AS 'Contract Item Description'
		, i.ApprovedBy
		, i.ForcePhaseYN
		, i.FixedAmountYN
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
	
	FROM PMOI i WITH (NOLOCK)
		INNER JOIN PMOH a WITH (NOLOCK) ON a.PMCo = i.PMCo AND a.Project = i.Project AND a.ACO = i.ACO
		LEFT JOIN PMOP u WITH (NOLOCK) ON u.PMCo = i.PMCo AND u.Project = i.Project AND u.PCOType = i.PCOType AND u.PCO=i.PCO 
		LEFT JOIN PMIM s WITH (NOLOCK) ON i.PMCo = s.PMCo AND i.Project = s.Project AND i.Issue = s.Issue
		LEFT JOIN PMSC c WITH (NOLOCK) ON i.Status = c.Status
		LEFT JOIN PMDT t WITH (NOLOCK) ON i.PCOType = t.DocType
		LEFT JOIN JCCM m WITH (NOLOCK) ON m.JCCo = i.PMCo AND m.Contract = i.Contract
		LEFT JOIN JCCI ci WITH (NOLOCK) ON ci.JCCo = i.PMCo AND ci.Contract = i.Contract AND ci.Item = i.ContractItem
		LEFT JOIN JBBG b WITH (NOLOCK) ON b.JBCo = i.PMCo AND b.Contract = i.Project AND b.BillGroup = i.BillGroup

	WHERE  i.PMCo = @JCCo 
		AND i.Project=@Job 
		AND i.ACO = @ACO
		AND i.KeyID = ISNULL(@KeyID, i.KeyID)

END





GO
GRANT EXECUTE ON  [dbo].[vpspPMApprovedCOItemsGet] TO [VCSPortal]
GO
