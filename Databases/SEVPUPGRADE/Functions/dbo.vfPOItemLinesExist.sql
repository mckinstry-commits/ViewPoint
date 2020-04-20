SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/11/13
-- Description:	Return a flag indicating if additional PO Distributions exist.
-- =============================================
CREATE FUNCTION [dbo].[vfPOItemLinesExist]
(	
	@POCo bCompany,
	@PO VARCHAR(30), 
	@POItem bItem
)
RETURNS bYN 
AS
BEGIN 
	DECLARE @ItemLinesExist bYN
	
	SELECT @ItemLinesExist = CASE WHEN COUNT(POItemLine)>1 THEN 'Y' ELSE 'N' END 
		FROM dbo.POItemLine WHERE POCo=@POCo
			AND PO=@PO AND POItem=@POItem
	
	RETURN @ItemLinesExist
END
GO
GRANT EXECUTE ON  [dbo].[vfPOItemLinesExist] TO [public]
GO
