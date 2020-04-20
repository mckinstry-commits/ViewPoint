SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Garth Theisen
-- Create date: 6/7/13
-- Description:	Returns VersionStamp of SMTrip record
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTripVersionStampGet]
	@SMTripID int,
	@VersionStamp binary(8) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @VersionStamp = [VersionStamp] FROM vSMTrip WHERE SMTripID = @SMTripID

	RETURN 1

END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripVersionStampGet] TO [public]
GO
