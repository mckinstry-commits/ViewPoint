SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMTransmittalItemInsert]
/************************************************************
* CREATED:		12/18/06	CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Inserts PM Transmittal Items (document)
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob, 
	@Transmittal bDocument, 
	--@Seq int, 
	@Seq varchar(10),
	@DocType bDocType, 
	@Document bDocument, 
	@DocumentDesc bItemDesc, 
	@CopiesSent tinyint, 
	@Status bStatus, 
	@Remarks bNotes, 
	@Rev tinyint, 
	@UniqueAttchID uniqueidentifier
)

AS
SET NOCOUNT ON;

declare @rcode int, @msg varchar(255), @message varchar(255)
select @rcode = 0, @message = ''

set @Seq = (Select IsNull((Max(Seq)+1),1) 
						from PMTS with (nolock) 
						where PMCo = @PMCo and Project = @Project and Transmittal = @Transmittal) 
						
if @Status is null set @Status = (select PMCO.BeginStatus from PMCO Where PMCO.PMCo = @PMCo)

INSERT INTO PMTS(
	PMCo, 
	Project, 
	Transmittal, 
	Seq, 
	DocType, 
	Document, 
	DocumentDesc, 
	CopiesSent, 
	Status, 
	Remarks, 
	Rev, 
	UniqueAttchID)

VALUES(@PMCo,
	@Project, 
	@Transmittal, 
	@Seq, 
	@DocType, 
	@Document, 
	@DocumentDesc, 
	@CopiesSent, 
	@Status, 
	@Remarks, 
	@Rev, 
	@UniqueAttchID
	);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMTransmittalItemGet @PMCo, @Project, null, null, @Transmittal, @KeyID

bspexit:
return @rcode

bspmessage:
	RAISERROR(@message, 11, -1);
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalItemInsert] TO [VCSPortal]
GO
