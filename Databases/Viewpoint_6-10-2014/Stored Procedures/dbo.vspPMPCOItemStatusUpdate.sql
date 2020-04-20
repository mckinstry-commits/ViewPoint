SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMPCOItemStatusUpdate]
/***********************************************************
* CREATED BY:	GF 02/10/2011 - V1 - ID B-20365
* MODIFIED BY:	GP 03/15/2011 - V1# B-03061 modified where clause to i.Status <> @Status since timing at
*					at form level changed to StdBeforeRecUpdate
*				JG 07/22/2011 - TK-07039 - Removed code to check for final status.
*
*
*
*
*
* USAGE: Called after update from PM PCOs to update the PCO Item status
* to the PCO status when the PCO Item status is not final. This is done
* via a prompt in the form to update status.
*
*
* INPUT PARAMETERS
* PMCO
* PROJECT
* PCOType
* PCO
* Status
*
*
* OUTPUT PARAMETERS
*
*
* RETURN VALUE
*   0 - Success
*   1 - Failure
*****************************************************/
(@PMCo bCompany = 0, @Project bJob = NULL, @PCOType bDocType = NULL,
 @PCO bPCO = NULL, @Status VARCHAR(10) = NULL)
as
set nocount on

declare @rcode int

SET @rcode = 0

---- exit if missing needed parameters
IF @PMCo is null or @Project is null or @PCOType is null or @PCO IS NULL OR @Status IS NULL
	BEGIN
	goto bspexit
	END

---- update PMOI.Status set to PMOP.Status where PMOI.Status is not a final status
--SELECT *
UPDATE dbo.PMOI SET Status = @Status
FROM dbo.PMOI i
JOIN dbo.PMOP p ON p.PMCo=i.PMCo AND p.Project=i.Project AND p.PCOType=i.PCOType AND p.PCO=i.PCO
LEFT JOIN dbo.PMSC s ON s.Status=i.Status
WHERE i.PMCo=@PMCo AND i.Project=@Project AND i.PCOType=@PCOType AND i.PCO=@PCO
AND i.Status IS NOT NULL AND p.Status IS NOT NULL
AND i.Status <> @Status




bspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMPCOItemStatusUpdate] TO [public]
GO
