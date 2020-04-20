SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		TRL  vfPMPOCONumMaxInterfaceDate
-- Modified: 

-- Create date: 1/31/2013
-- Description:	Returns Max Interface Date for Change Orders
--   
-- =============================================

CREATE FUNCTION [dbo].[vfPMPOCONumMaxInterfaceDate](@PMCo bCompany, @Project bProject,@POCo bCompany,
@PO varchar(30),@POCONum bigint )
RETURNS bDate

AS 

BEGIN
	DECLARE @PMPOCONumMaxInterfaceDate bDate
		
	SELECT  @PMPOCONumMaxInterfaceDate = MAX(InterfaceDate) FROM dbo.PMMF 
	WHERE PMCo=@PMCo AND Project =@Project AND POCo =@POCo AND PO =@PO AND POCONum =@POCONum

	RETURN  @PMPOCONumMaxInterfaceDate 
END
GO
GRANT EXECUTE ON  [dbo].[vfPMPOCONumMaxInterfaceDate] TO [public]
GO
