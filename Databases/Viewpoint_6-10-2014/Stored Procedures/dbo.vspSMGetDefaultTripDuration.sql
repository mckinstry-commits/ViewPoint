SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/07/2013
-- Description:	SM trips for Dispatch
-- Modifications:
--				  5/10/13 GPT Task 49604 -- Added DispatchSequence to select clause.
--				  6/10/13 GPT Task 52182 -- Added VersionStamp to select clause.
-- =============================================
CREATE PROCEDURE dbo.vspSMGetDefaultTripDuration
	@SMCo				bCompany,
	@DefaultTripDuration int output,
	@msg				nvarchar OUTPUT
AS
BEGIN

	select @DefaultTripDuration = DefaultTripDuration
	from dbo.SMCO
	where SMCo = @SMCo
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMGetDefaultTripDuration] TO [public]
GO
