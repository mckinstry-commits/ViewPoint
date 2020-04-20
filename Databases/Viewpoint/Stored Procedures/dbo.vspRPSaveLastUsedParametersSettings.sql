SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPSaveLastUsedParametersSettings]  
/***********************************************************  
 * CREATED BY: Nitor 12/11/2011  
 * MODIFIED BY:   
 *  
 *USAGE:  
 * Save the Last used parameters with there values for the given report/username combination.    
 *   
 * INPUT PARAMETERS  
 *    @username         VPUserName  
 *    @reportid			ReportID  
 *    @parametername    string 
 *    @value            string  
 *  
 * OUTPUT PARAMETERS  
 *    @msg           error message from  
 *  
 * RETURN VALUE  
 *    none  
 *****************************************************/  
 (@username VARCHAR(128) = NULL,  
  @reportid INT = NULL,  
  @parametername VARCHAR(128) = NULL,   
  @value VARCHAR(128) = NULL,    
  @lastaccessdate SMALLDATETIME = NULL,   
  @msg VARCHAR(255) OUTPUT  
 )   
AS   
  
SET NOCOUNT OFF  
DECLARE @rcode INT  
SELECT @rcode = 0  
  
IF @username is null  
 BEGIN  
  SELECT @msg = 'Missing VP User Name', @rcode = 1  
  GOTO vspexit  
 END  
  
IF @reportid is null or @reportid = 0  
 BEGIN  
  SELECT @msg = 'Missing ReportID', @rcode = 1  
  GOTO vspexit  
 END  
  
IF @reportid >0   
 BEGIN  
  IF (SELECT COUNT(*) FROM RPRTShared WHERE ReportID = @reportid) = 0  
   BEGIN  
    SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid , 0)) + 'does not exist!', @rcode = 1  
    GOTO vspexit  
   END  
 END  
  
IF (SELECT COUNT(*) FROM dbo.vRPSP WHERE VPUserName = @username AND ReportID = @reportid AND ParameterName = @parametername)= 0  
 BEGIN  
  INSERT INTO vRPSP  (VPUserName, ReportID, ParameterName,Value, LastAccessed)  
  VALUES( @username, @reportid, @parametername,@value, @lastaccessdate)  
  IF @@ROWCOUNT =0  
   BEGIN  
    SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid,0)) + ' did not insert!', @rcode = 1  
    GOTO vspexit  
   END  
 END  
ELSE  
 BEGIN  
  UPDATE dbo.vRPSP  
  SET ParameterName= ISNULL(@parametername, ParameterName),   
  Value= ISNULL(@value, Value),    
  LastAccessed = ISNULL(@lastaccessdate, LastAccessed)  
  FROM dbo.vRPSP  WHERE VPUserName = @username AND ReportID = @reportid AND ParameterName = @parametername
  
  IF @@ROWCOUNT =0  
  BEGIN  
   SELECT @msg = 'VP User:  ' + @username + 'Report ID: ' + CONVERT(VARCHAR,ISNULL(@reportid,0)) + ' did not update!', @rcode = 1  
   GOTO vspexit  
  END  
 END  
  
vspexit:  
 IF @rcode <> 0  
 SELECT @msg =  @msg + CHAR(13) + CHAR(10) + '[vspRPSaveLastUsedParametersSettings]'   
 RETURN @rcode  
  
  
  
GO
GRANT EXECUTE ON  [dbo].[vspRPSaveLastUsedParametersSettings] TO [public]
GO
