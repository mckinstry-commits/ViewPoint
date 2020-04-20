SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE proc [dbo].[vspWFProcessIdGetForPOHDPM]
/***********************************************************
* CREATED BY:	AW 01/11/2013 TK-20639 PM PO work flow
* MODIFIED BY:	
*
*				
* USAGE:
* used within the work flow class to get a process id
* for the PM PO Header form.
* returns a work flow process id for a POHD record .
* if no process is in place then will return null
*
*
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/ 
(@SrcKeyId BIGINT = NULL, @ProcessId BIGINT = NULL OUTPUT)
AS
SET NOCOUNT ON

declare @rcode INT

SET @rcode = 0
SET @ProcessId = NULL

---- must have a PMMF source key id
IF @SrcKeyId IS NULL RETURN

---- check PMMF and try to locate a valid work flow process
SELECT @ProcessId = COALESCE(wflevel3.KeyID, wflevel2.KeyID, wflevel1.KeyID)
FROM dbo.bPOHD src

	OUTER APPLY (SELECT wflevel1.KeyID
						FROM dbo.vWFProcess wflevel1
						INNER JOIN dbo.vHQCompanyProcess hq ON hq.Process = wflevel1.Process
						WHERE hq.Mod = 'HQ' 
							AND hq.DocType = 'PO' 
							AND hq.HQCo = src.POCo
							AND hq.Active = 'Y') wflevel1
				
	OUTER APPLY (SELECT wflevel2.KeyID
						FROM dbo.vHQCompanyProcess toco
						INNER JOIN dbo.vWFProcess wflevel2 ON wflevel2.Process = toco.Process
						WHERE toco.Mod = 'JC' 
							AND toco.DocType = 'PO' 
							AND toco.HQCo = src.JCCo
							AND toco.Active = 'Y') wflevel2

	OUTER APPLY (SELECT wflevel3.KeyID
						FROM dbo.JCJobApprovalProcess job
						INNER JOIN dbo.WFProcess wflevel3 ON wflevel3.Process = job.Process
						WHERE job.JCCo = src.JCCo
							AND job.DocType = 'PO' 
							AND job.Job = src.Job
							AND job.Active = 'Y') wflevel3

WHERE src.KeyID = @SrcKeyId

IF @@ROWCOUNT = 0
BEGIN
	SET @ProcessId = NULL
END

GO
GRANT EXECUTE ON  [dbo].[vspWFProcessIdGetForPOHDPM] TO [public]
GO
