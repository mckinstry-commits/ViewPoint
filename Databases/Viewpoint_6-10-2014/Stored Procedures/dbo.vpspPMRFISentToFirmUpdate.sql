SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMRFISentToFirmUpdate]
/************************************************************
* CREATED:     7/11/06  CHS
* 
* USAGE:
*   Updates PM RFI
*
* CALLED FROM:
*	ViewpointCS Portal  
*   
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@RFIType bDocType,
	@RFI bDocument,
	@RFISeq int,
	@VendorGroup bGroup,
	@SentToFirm bFirm,
	@SentToContact bEmployee,
	@DateSent bDate,
	@InformationReq bNotes,
	@DateReqd bDate,
	@Response bNotes,
	@DateRecd bDate,
	@Send bYN,
	@PrefMethod char(1),
	@CC CHAR(1),
	@UniqueAttchID uniqueidentifier,
	
	@Original_PMCo bCompany,
	@Original_Project bJob,
	@Original_RFIType bDocType,
	@Original_RFI bDocument,
	@Original_RFISeq int,
	@Original_VendorGroup bGroup,
	@Original_SentToFirm bFirm,
	@Original_SentToContact bEmployee,
	@Original_DateSent bDate,
	@Original_InformationReq bNotes,
	@Original_DateReqd bDate,
	@Original_Response bNotes,
	@Original_DateRecd bDate,
	@Original_Send bYN,
	@Original_PrefMethod char(1),
	@Original_CC CHAR(1),
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


UPDATE PMRD
SET
	--PMCo = @PMCo,
	--Project = @Project,
	--RFIType = @RFIType,
	--RFI = @RFI,
	--RFISeq = @RFISeq,
	VendorGroup = @VendorGroup,
	SentToFirm = @SentToFirm,
	SentToContact = @SentToContact,
	DateSent = @DateSent,
	InformationReq = @InformationReq,
	DateReqd = @DateReqd,
	Response = @Response,
	DateRecd = @DateRecd,
	Send = @Send,
	PrefMethod = @PrefMethod,
	CC = @CC,
	UniqueAttchID = @UniqueAttchID
	
WHERE
	(PMCo = @Original_PMCo)
	AND(Project = @Original_Project)
	AND(RFIType = @Original_RFIType)
	AND(RFI = @Original_RFI)
	AND(RFISeq = @Original_RFISeq)
	AND(VendorGroup = @Original_VendorGroup)
	AND(SentToFirm = @Original_SentToFirm)
	AND(SentToContact = @Original_SentToContact)
	AND(DateSent = @Original_DateSent)
	--AND(InformationReq = @Original_InformationReq OR @Original_InformationReq IS NULL AND InformationReq IS NULL)
	AND(DateReqd = @Original_DateReqd OR @Original_DateReqd IS NULL AND DateReqd IS NULL)
	--AND(Response = @Original_Response OR @Original_Response IS NULL AND Response IS NULL)
	AND(DateRecd = @Original_DateRecd OR @Original_DateRecd IS NULL AND DateRecd IS NULL)
	AND(Send = @Original_Send)
	AND(PrefMethod = @Original_PrefMethod)
	AND(CC = @Original_CC)
	AND(UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)

 	bspexit:
 		return @rcode

	bspmessage:
		RAISERROR(@message, 11, -1);
		return @rcode




GO
GRANT EXECUTE ON  [dbo].[vpspPMRFISentToFirmUpdate] TO [VCSPortal]
GO
