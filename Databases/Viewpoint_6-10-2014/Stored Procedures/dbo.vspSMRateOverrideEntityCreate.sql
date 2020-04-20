SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Scott Alvey
-- Create date: 05/06/2013
-- Description:	Adds entity line to Override Base if it does not exist already
-- Mod: 
-- =============================================
CREATE PROCEDURE [dbo].[vspSMRateOverrideEntityCreate]
	@SMCo bCompany,
	@EntitySeq int,
	@MaterialMarkupOrDiscount char(1)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT 1 FROM dbo.SMRateOverrideBaseRate WHERE SMCo = @SMCo and EntitySeq = @EntitySeq

	IF @@ROWCOUNT = 0
	BEGIN
		INSERT dbo.SMRateOverrideBaseRate (SMCo, EntitySeq, MaterialMarkupOrDiscount)
		VALUES (@SMCo, @EntitySeq, @MaterialMarkupOrDiscount)
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMRateOverrideEntityCreate] TO [public]
GO
