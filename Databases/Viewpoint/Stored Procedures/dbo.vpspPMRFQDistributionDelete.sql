SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMRFQDistributionDelete
/************************************************************
* CREATED:     1/08/07  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				DAN SO 11/14/2011 - D-03599 - cannot delete: @Original_CCList missing parameter - CCList no longer needed
* USAGE:
*   Deletes PM RFQ
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_PCOType bDocType,
	@Original_PCO bPCO,
	@Original_RFQ bDocument,
	@Original_RFQSeq tinyint,
	@Original_VendorGroup bGroup,
	@Original_SentToFirm bFirm,
	@Original_SentToContact bEmployee,
	@Original_DateSent bDate,
	@Original_DateReqd bDate,
	@Original_Response VARCHAR(MAX),
	@Original_DateRecd bDate,
	@Original_Send char(1),
	@Original_PrefMethod char(1),
	@Original_CC char(1),
	@Original_UniqueAttchID char(1)
)
AS
SET NOCOUNT ON;

DELETE FROM PMQD

WHERE
	(PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (PCOType = @Original_PCOType)
	AND (PCO = @Original_PCO)
	AND (RFQ = @Original_RFQ)
	AND (RFQSeq = @Original_RFQSeq)
	AND (VendorGroup = @Original_VendorGroup)
	AND (SentToFirm = @Original_SentToFirm)
	AND (SentToContact = @Original_SentToContact)
	AND (DateSent = @Original_DateSent)
	AND (DateReqd = @Original_DateReqd OR @Original_DateReqd IS NULL AND DateReqd IS NULL)
	--AND (Response = @Original_Response OR @Original_Response IS NULL AND Response IS NULL)
	AND (DateRecd = @Original_DateRecd OR @Original_DateRecd IS NULL AND DateRecd IS NULL)
	AND (PrefMethod = @Original_PrefMethod OR @Original_PrefMethod IS NULL AND PrefMethod IS NULL)
	AND (CC = @Original_CC OR @Original_CC IS NULL AND CC IS NULL)
	
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMRFQDistributionDelete] TO [VCSPortal]
GO
