SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/13/2011
-- Description:	Determine if Standard Item Defaults exist for specified SMStandardItemDefaultID
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
=============================================*/
CREATE FUNCTION [dbo].[vfSMStandardItemDefaultsExist]
(
	@SMCo bCompany, @EntitySeq int
)
RETURNS bYN
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Status bYN

	IF EXISTS(SELECT 1 FROM dbo.SMStandardItemDefault WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq)
		RETURN 'Y'

	RETURN 'N'
END


GO
GRANT EXECUTE ON  [dbo].[vfSMStandardItemDefaultsExist] TO [public]
GO
