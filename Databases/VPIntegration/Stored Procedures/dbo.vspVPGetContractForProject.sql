SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetContractForProject]
/****************************************
 * Created By:	CC 05-12-2011
 * Modified By:	
 *
 *	Gets the contract for a given project
 *
 * Returns:
 *
 *
 *
 **************************************/
(@Company bCompany,
@Project bJob,
@Contract bContract OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT @Contract = [Contract]
	FROM dbo.JCJMPM
	WHERE JCCo = @Company AND Project = @Project;
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetContractForProject] TO [public]
GO
