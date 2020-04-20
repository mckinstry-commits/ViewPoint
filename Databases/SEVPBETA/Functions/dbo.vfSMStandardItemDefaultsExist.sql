SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* =============================================
-- Author:		Eric Vaterlaus
-- Create date: 7/13/2011
-- Description:	Determine if Standard Item Defaults exist for specified SMStandardItemDefaultID
=============================================*/
CREATE FUNCTION [dbo].[vfSMStandardItemDefaultsExist]
(
	@SMStandardItemDefaultID AS bigint
)
RETURNS bYN
AS
BEGIN
	-- Declare the return variable here
	DECLARE @Status bYN

	IF EXISTS(SELECT 1 FROM SMStandardItemDefaultDetail WHERE SMStandardItemDefaultID=@SMStandardItemDefaultID)
		RETURN 'Y'

	RETURN 'N'
END


GO
GRANT EXECUTE ON  [dbo].[vfSMStandardItemDefaultsExist] TO [public]
GO
