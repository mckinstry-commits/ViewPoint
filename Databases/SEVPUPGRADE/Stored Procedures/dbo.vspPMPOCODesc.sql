SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE PROC [dbo].[vspPMPOCODesc]
CREATE  proc [dbo].[vspPMPOCODesc]
/*************************************
 * Created By:	DAN SO 03/31/2011
 * Modified by:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 * called from PM PO Change Order to return key description.
 *
 * Pass:
 * PMCo			PM Company
 * POCo			PO Company
 * Project		PM Project
 * PO			Purchase Order
 * PONum		PM PO Change Order
 *
 * Returns:
 *
 * Success returns:
 *	0 and Description from PMPOCO
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@PMCo bCompany = NULL, @POCo bCompany = NULL, 
 @Project bJob = NULL, @PO varchar(30) = NULL, @PONum smallint = NULL,
 @msg varchar(255) output)
 
AS
SET NOCOUNT ON


DECLARE @rcode int

SET @rcode = 0
SET @msg = ''

	---------------------
	-- GET DESCRIPTION --
	---------------------
	IF ISNULL(@PONum,0) <> 0
		BEGIN
			SELECT @msg = Description
			  FROM PMPOCO WITH (NOLOCK) 
			 WHERE PMCo = @PMCo 
			   AND POCo = @POCo
			   AND Project = @Project
			   AND PO = @PO
			   AND POCONum = @PONum
		END




vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCODesc] TO [public]
GO
