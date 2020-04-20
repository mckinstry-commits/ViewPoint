SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspPMRFIResponseAddRFIContact]
/**************************************************
* Created:	JG - #TK-02080 - Add/Update Contact in PM RFI Distribution from PM RFI Response.
*			JG	07/07/2011	TK-06534 - Added an ISNULL wrapper around the RFISeq.
*
* Used by PM RFI Response to add/update contact in the PM RFI Distribution table.
*
* Inputs:
*	@co			Company
*	@project	Project
*	@rfitype	RFI Type
*	@rfi		RFI
*	@firm		Firm
*	@contact	Contact
*	@datesent	Date Sent
*	@datereqd	Date Required
*	@daterecd	Date Received
*
* Output:
*	@msg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/
	(@co bCompany, @project bJob, @rfitype bDocType, @rfi bDocument, @firm bFirm, 
	@contact bEmployee, @datesent bDate, @datereqd bDate, @daterecd bDate, @msg varchar(255) output)
as

set nocount on 

declare @rcode int
	
if @co is NULL OR @project IS NULL OR @rfitype IS NULL OR @rfi IS NULL OR @firm IS NULL OR @contact IS NULL
	OR @datesent IS NULL
	begin
	select @msg = 'Missing required input parameter(s)', @rcode = 1
	goto vspexit
	end

select @rcode = 0

-- Process Add/Update

IF EXISTS (	SELECT * FROM PMRD WHERE PMCo = @co AND Project = @project AND RFIType = @rfitype AND RFI = @rfi AND
			SentToFirm = @firm AND SentToContact = @contact)
BEGIN
	
	-- Update CC to 'N', Date Sent and Date Due.
	UPDATE PMRD
		SET CC = 'N', DateSent = @datesent, DateReqd = @datereqd, DateRecd = @daterecd
	WHERE PMCo = @co AND Project = @project AND RFIType = @rfitype AND RFI = @rfi 
	AND	SentToFirm = @firm AND SentToContact = @contact
	
END
ELSE -- Create a new contact with the information brought in.
BEGIN

	DECLARE @vendorgroup bGroup, @rfiseq INT, @prefmeth CHAR
	
	-- Grab Vendor Group
	SELECT @vendorgroup = VendorGroup FROM PMCO WHERE PMCo = @co
	
	-- Grab next seq value
	SELECT @rfiseq = ISNULL(MAX(RFISeq),0) + 1 FROM PMRD
	WHERE PMCo = @co 
	AND Project = @project 
	AND RFIType = @rfitype 
	AND RFI = @rfi 
	
	-- Grab the contact prefered method of contract
	SELECT @prefmeth = PrefMethod FROM PMPM
	WHERE VendorGroup = @vendorgroup 
	AND FirmNumber = @firm
	AND ContactCode = @contact
	
	-- Add Contact
	INSERT INTO PMRD (PMCo, Project, RFIType, RFI, RFISeq, VendorGroup, SentToFirm, SentToContact, DateSent, DateReqd, DateRecd, [Send], PrefMethod, CC)
	VALUES (@co, @project, @rfitype, @rfi, @rfiseq, @vendorgroup, @firm, @contact, @datesent, @datereqd, @daterecd, 'Y', @prefmeth, 'N')

END

vspexit:
	if @rcode <> 0 select @msg = @msg + char(13) + char(10) + '[vspPMRFIResponseAddRFIContact]'
	
	return @rcode
	
GO
GRANT EXECUTE ON  [dbo].[vspPMRFIResponseAddRFIContact] TO [public]
GO
