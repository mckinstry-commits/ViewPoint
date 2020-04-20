SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMTransmittalDistributionUpdate]
/************************************************************
* CREATED:     12/18/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Updates PM Transmittal Distribution
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@Transmittal bDocument,
	@Seq int,
	@VendorGroup bGroup,
	@SentToFirm bFirm,
	@SentToContact bEmployee,
	@Send bYN,
	@PrefMethod char(1),
	@CC bYN,
	@DateSent bDate,
	@Notes VARCHAR(MAX),
	@UniqueAttchID uniqueidentifier,

	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_Transmittal bDocument,
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

declare @rcode int, @message varchar(255)
select @rcode = 0, @message = ''

if (@PrefMethod is NULL)
	begin
		(select @PrefMethod = (select PMPM.PrefMethod from PMPM where PMPM.VendorGroup = @VendorGroup and PMPM.FirmNumber = @SentToFirm and PMPM.ContactCode = @SentToContact))
	end
	
else if ((@PrefMethod = 'E') and ((select PMPM.EMail from PMPM where PMPM.VendorGroup = @VendorGroup and PMPM.FirmNumber = @SentToFirm and PMPM.ContactCode = @SentToContact) is null))
	begin 
		select @rcode = 1, @message = 'Invalid Method: no EMail setup for Contact.'
		goto bspmessage
	end		
		
else if ((@PrefMethod = 'T') and ((select PMPM.EMail from PMPM where PMPM.VendorGroup = @VendorGroup and PMPM.FirmNumber = @SentToFirm and PMPM.ContactCode = @SentToContact) is null))
	begin 
		select @rcode = 1, @message = 'Invalid Method: no EMail setup for Contact.'
		goto bspmessage
	end		
	
else if ((@PrefMethod = 'F') and ((select PMPM.Fax from PMPM where PMPM.VendorGroup = @VendorGroup and PMPM.FirmNumber = @SentToFirm and PMPM.ContactCode = @SentToContact) is null))
	begin 
		select @rcode = 1, @message = 'Invalid Method: no Fax number setup for Contact.'
		goto bspmessage
	end	


UPDATE PMTC
SET 
	--PMCo = @PMCo, 
	--Project = @Project, 
	--Transmittal = @Transmittal, 
	--Seq = @Seq, 
	VendorGroup = @VendorGroup, 
	SentToFirm = @SentToFirm,  
	SentToContact = @SentToContact, 
	Send = @Send, 
	PrefMethod = @PrefMethod, 
	CC = @CC, 
	DateSent = @DateSent, 
	Notes = @Notes, 
	UniqueAttchID = @UniqueAttchID


WHERE
	(PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (Transmittal = @Original_Transmittal)
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


bspexit:
return @rcode

bspmessage:
	RAISERROR(@message, 11, -1);
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalDistributionUpdate] TO [VCSPortal]
GO
