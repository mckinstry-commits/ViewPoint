SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMRequestForQuoteGet]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:		11/14/2011 DAN SO - D-03599 - Get DateDue
* 
* Description:	Get the Request for Quote(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @KeyID BIGINT = NULL)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT r.KeyID, 
		r.PMCo, 
		r.Project, 
		r.PCOType, 
		r.PCO, 
		r.RFQ, 
		r.Description, 
		r.RFQDate, 
		r.DateDue,		-- D-03599
		r.VendorGroup, 
		r.FirmNumber, 
		f.FirmName,
		r.ResponsiblePerson, 
		p.FirstName + ' ' + p.LastName as 'ResponsiblePersonName',
		r.Status, 
		c.Description as 'StatusDescription', 
		r.Notes, r.UniqueAttchID

	FROM PMRQ r WITH (NOLOCK)
		LEFT JOIN PMFM f WITH (NOLOCK) ON r.VendorGroup = f.VendorGroup AND r.FirmNumber = f.FirmNumber
		LEFT JOIN PMPM p WITH (NOLOCK) ON r.VendorGroup = p.VendorGroup AND r.ResponsiblePerson = p.ContactCode AND r.FirmNumber = p.FirmNumber
		LEFT JOIN PMSC c WITH (NOLOCK) ON r.Status = c.Status

	WHERE r.PMCo = @JCCo 
	AND r.Project = @Job 
	AND r.VendorGroup = @VendorGroup
	AND r.KeyID = ISNULL(@KeyID, r.KeyID)
END


GO
GRANT EXECUTE ON  [dbo].[vpspPMRequestForQuoteGet] TO [VCSPortal]
GO
