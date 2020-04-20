SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMTransmittalItemGet]
/************************************************************
* CREATED:		12/11/06	CHS
* MODIFIED:		6/7/07		CHS
* MODIFIED:		6/12/07		CHS
*
* USAGE:
*   Returns PM Transmittal Items (document)
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup, OurFirm, and Transmittal
*
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @OurFirm bFirm, 
@Transmittal bDocument,
	@KeyID int = Null)

AS
SET NOCOUNT ON;

SELECT t.KeyID, 
t.PMCo, t.Project, t.Transmittal, 

cast(t.Seq as varchar(10)) as 'Seq', 

t.DocType, 
d.Description as 'DocTypeDescription',
t.Document, 
t.DocumentDesc, t.CopiesSent, t.Status, 
s.Description as 'StatusDescription', 
t.Remarks, t.Rev, t.UniqueAttchID

FROM PMTS t with (nolock)
	left Join PMSC s with (nolock) on s.Status=t.Status
	Left Join PMDT d with (nolock) on t.DocType = d.DocType	

WHERE
	t.PMCo=@JCCo and t.Project=@Job and t.Transmittal = @Transmittal
and t.KeyID = IsNull(@KeyID, t.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMTransmittalItemGet] TO [VCSPortal]
GO
