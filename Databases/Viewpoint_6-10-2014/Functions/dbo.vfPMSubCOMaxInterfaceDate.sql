SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		TRL  vfPMSubCOMaxInterfaceDate
-- Modified: 

-- Create date: 1/31/2013
-- Description:	Returns Max Interface Date for Change Orders
--   
-- =============================================

CREATE FUNCTION [dbo].[vfPMSubCOMaxInterfaceDate] (@PMCo bCompany, @Project bProject,@SLCo bCompany,@SL VARCHAR(30),@SubCO bigint )
RETURNS bDate

AS

BEGIN
	DECLARE @PMSubCOMaxInterfaceDate bDate

	SELECT @PMSubCOMaxInterfaceDate = MAX(InterfaceDate) FROM dbo.PMSL
	WHERE PMCo=@PMCo AND Project =@Project AND SLCo=@SLCo AND SL=@SL AND SubCO =@SubCO	

	RETURN  @PMSubCOMaxInterfaceDate
END
GO
GRANT EXECUTE ON  [dbo].[vfPMSubCOMaxInterfaceDate] TO [public]
GO
