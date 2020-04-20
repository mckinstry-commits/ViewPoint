SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.vpspPMTransmittalHeaderDelete
/************************************************************
* CREATED:     12/13/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Deletes PM Transmittal Header
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/

(
	@Original_PMCo bCompany, 
	@Original_Project bJob, 
	@Original_Transmittal bDocument, 
	@Original_Subject varchar(255), 
	@Original_TransDate bDate, 
	@Original_DateSent bDate, 
	@Original_DateDue bDate, 
	@Original_Issue bIssue, 
	@Original_CreatedBy bVPUserName, 
	@Original_Notes VARCHAR(MAX), 
	@Original_UniqueAttchID uniqueidentifier, 
	@Original_VendorGroup bGroup, 
	@Original_ResponsibleFirm bFirm, 
	@Original_ResponsiblePerson bEmployee, 
	@Original_DateResponded bDate

)

AS
SET NOCOUNT ON;

DELETE FROM PMTM
	
WHERE
(PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (Transmittal = @Original_Transmittal)
	AND (Subject = @Original_Subject OR @Original_Subject IS NULL AND Subject IS NULL)
	AND (TransDate = @Original_TransDate)
	AND (DateSent = @Original_DateSent OR @Original_DateSent IS NULL AND DateSent IS NULL)
	AND (DateDue = @Original_DateDue OR @Original_DateDue IS NULL AND DateDue IS NULL)
	AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL)
	AND (CreatedBy = @Original_CreatedBy OR @Original_CreatedBy IS NULL AND CreatedBy IS NULL)
	
	--AND (Notes = @Original_Notes OR @Original_Notes IS NULL AND Notes IS NULL)
	--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)
	
	AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
	AND (ResponsibleFirm = @Original_ResponsibleFirm OR @Original_ResponsibleFirm IS NULL AND ResponsibleFirm IS NULL)
	AND (ResponsiblePerson = @Original_ResponsiblePerson OR @Original_ResponsiblePerson IS NULL AND ResponsiblePerson IS NULL)
	AND (DateResponded = @Original_DateResponded OR @Original_DateResponded IS NULL AND DateResponded IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalHeaderDelete] TO [VCSPortal]
GO
