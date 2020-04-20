SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMOtherDocumentsDistributionDelete]
/************************************************************
* CREATED:     11/28/06  CHS
* Modified:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)	
* USAGE:
*   Returns PM Other Documents Distribution
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_DocType bDocType, 
	@Original_Document bDocument, 
	@Original_Seq int,
	@Original_VendorGroup bGroup, 
	@Original_SentToFirm bFirm, 
	@Original_SentToContact bEmployee, 
	@Original_Send bYN, 
	@Original_PrefMethod char(1), 
	@Original_CC bYN, 
	@Original_DateSent bDate, 
	@Original_Notes VARCHAR(MAX),
	@Original_UniqueAttchID uniqueidentifier
	
)

AS
SET NOCOUNT ON;

DELETE FROM PMOC

WHERE (PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (DocType = @Original_DocType) 
	AND (Document = @Original_Document) 
	AND (Seq = @Original_Seq)
	AND (VendorGroup = @Original_VendorGroup) 
	AND (SentToFirm = @Original_SentToFirm) 
	AND (SentToContact = @Original_SentToContact) 
	AND (Send = @Original_Send) 
	AND (PrefMethod = @Original_PrefMethod) 
	AND (CC = @Original_CC) 
	AND (DateSent = @Original_DateSent OR @Original_DateSent IS NULL AND DateSent IS NULL) 
	--AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL)
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)





GO
GRANT EXECUTE ON  [dbo].[vpspPMOtherDocumentsDistributionDelete] TO [VCSPortal]
GO
