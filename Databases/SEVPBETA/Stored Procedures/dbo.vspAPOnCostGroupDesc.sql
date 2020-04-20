SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   Procedure [dbo].[vspAPOnCostGroupDesc]
  /***********************************************************
   * CREATED BY: MV 01/09/2012 - B-08283 - AP OnCost 
   * MODIFIED By :	
   *              
   *
   * USAGE:
   * Returns an OnCost Group description
   * 
   * INPUT PARAMETERS
   *	APCo   
   *	GroupID
   *
   * OUTPUT PARAMETERS
   *	 
   *    @msg If Error, error message, otherwise description of OnCostType
   * RETURN VALUE
   *   0   success
   *   1   fail
   *****************************************************/ 
  	(@APCo bCompany, @GroupID tinyint = NULL, @Desc varchar(60)OUTPUT, @msg VARCHAR(200)OUTPUT)
  AS
  
  SET NOCOUNT ON
  
  
  DECLARE @RCode int
  SELECT @RCode = 0
  	
 IF @APCo IS NULL
 BEGIN
  	SELECT @msg = 'Missing AP Company', @RCode = 1
  	RETURN @RCode
 END
 
 IF @GroupID IS NOT NULL
 BEGIN
	SELECT @msg = Description,@Desc = Description  
	FROM dbo.vAPOnCostGroups 
	WHERE  APCo=@APCo AND GroupID=@GroupID
 END
  
 RETURN @RCode


GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostGroupDesc] TO [public]
GO
