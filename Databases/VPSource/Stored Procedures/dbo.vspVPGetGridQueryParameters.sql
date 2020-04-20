SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetGridQueryParameters]  
/**************************************************  
* Created: CC 08/22/2008  
* Modified: ChrisG	3/17/11 - TK-02695 - Added Lookup column
*			ChrisG	3/21/11 - TK-02697 - Order by parameter name
*			HH		3/7/12	- TK-13724 - Added 'Comparison' and 'Operator' columns
*			HH		5/23/12	- TK-14882 - Order by parameter sequence
*     
* This procedure returns the parameters and values associated with a Grid Query  
*  
* Inputs:  
* @QueryName  
*  
* Output:  
* resultset1 Query Parameters  
*  
* Return code:  
*  
****************************************************/  
  
(@QueryName VARCHAR(50))  
  
AS  
  
SET NOCOUNT ON  
  
SELECT Parameters.KeyID,   
  Parameters.QueryName,   
  Parameters.ParameterName,   
  Parameters.Comparison,   
  Parameters.[Value],
  Parameters.Operator,      
  Parameters.IsVisible,   
  Parameters.[Description],   
  COALESCE(Parameters.InputType, DataTypes.InputType) AS 'InputType',   
  COALESCE(Parameters.InputLength, DataTypes.InputLength) AS 'InputLength',
  DataTypes.InputMask,
  COALESCE(Parameters.Prec, DataTypes.Prec) AS 'Prec',  
  Parameters.Lookup AS 'Lookup'
FROM VPGridQueryParameters Parameters   
LEFT OUTER JOIN DDDTShared DataTypes ON Parameters.DataType = DataTypes.Datatype  
WHERE Parameters.QueryName = @QueryName
ORDER BY Parameters.Seq
GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridQueryParameters] TO [public]
GO
