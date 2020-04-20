SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMTransmittalHeaderInsert]
/************************************************************
* CREATED:		12/13/06	CHS
* Modified:		6/05/07		chs
*
* USAGE:
*   Inserts PM Transmittal Header
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/

(
	@PMCo bCompany, 
	@Project bJob, 
	@Transmittal bDocument, 
	@Subject varchar(255), 
	@TransDate bDate, 
	@DateSent bDate, 
	@DateDue bDate, 
	@Issue bIssue, 
	@CreatedBy bVPUserName, 
	@Notes bNotes, 
	@UniqueAttchID uniqueidentifier, 
	@VendorGroup bGroup, 
	@ResponsibleFirm bFirm, 
	@ResponsiblePerson bEmployee, 
	@DateResponded bDate

)

AS
SET NOCOUNT ON;

declare @rcode int, @msg varchar(255), @message varchar(255), @nextTransmittal int

select @rcode = 0, @message = ''

set @CreatedBy = (select FirstName + ' ' + LastName + ' (portal)' from pUsers where UserID = @CreatedBy)


if (isnull(@Transmittal,'') = '') or @Transmittal = '+' or @Transmittal = 'n' or @Transmittal = 'N'
	begin
		set @nextTransmittal = (Select IsNull((Max(Transmittal)+1),1) 
						from PMTM with (nolock) 
						where PMCo = @PMCo and Project = @Project
						and ISNUMERIC(Transmittal) = 1 and Transmittal not like '%.%' 
						and substring(ltrim(Transmittal),1,1) <> '0')
		set @msg = null
		exec @rcode = dbo.vpspFormatDatatypeField 'bDocument', @nextTransmittal, @msg output
		set @Transmittal = @msg
	end
else
	begin
		set @msg = null
		exec @rcode = dbo.vpspFormatDatatypeField 'bDocument', @Transmittal, @msg output
		set @Transmittal = @msg
	end


if @Issue = -1 set @Issue = null
if @ResponsiblePerson = -1 set @ResponsiblePerson = null


INSERT INTO 
PMTM(PMCo, Project, Transmittal, Subject, TransDate, DateSent, 
	DateDue, Issue, CreatedBy, Notes, UniqueAttchID, VendorGroup, 
	ResponsibleFirm, ResponsiblePerson, DateResponded
)

VALUES(@PMCo, @Project, @Transmittal, @Subject, @TransDate, @DateSent, 
	@DateDue, @Issue, @CreatedBy, @Notes, @UniqueAttchID, @VendorGroup, 
	@ResponsibleFirm, @ResponsiblePerson, @DateResponded
);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMTransmittalHeaderGet @PMCo, @Project, @VendorGroup, @ResponsibleFirm, @KeyID

bspexit:
return @rcode

bspmessage:
	RAISERROR(@message, 11, -1);
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalHeaderInsert] TO [VCSPortal]
GO
