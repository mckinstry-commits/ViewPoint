SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVAViewGenGetOutOfSyncViews]      
  /********************************      
  * CREATED:  Kaustubh 03/12/2012
  *      
  * Used by Company Copy Wizard to get list of 'out of sync views'.
  *
  * Inputs:      
  *  @datatype - Pass null to return all securable views. 
  *				 Pass a datatype to filter down to only those views can be secured for that type.      
  *
  * OUTPUT PARAMETERS    
  *    @msg - error message.
  *    
  * RETURN VALUE    
  *   0   success    
  *   1   fail
  *********************************/      
(@datatype varchar(30) = null, @msg varchar(512) OUTPUT)      
AS      
SET NOCOUNT ON
      
DECLARE @rcode int      
SELECT @rcode = 0      
      
BEGIN       
 -- Select all the rows matching the given datatype, or return all rows if no datatype is specified.      
 SELECT DISTINCT substring(s.TableName, 2, len(s.TableName)) AS ViewName,       
           s.TableName AS TableName,       
           d.[Description] AS [Description],      
           s.ViewIsOutOfSync      
  FROM DDSLShared s WITH (NOLOCK)      
  left join DDTH d WITH (NOLOCK) ON d.TableName = substring(s.TableName, 2, len(s.TableName))      
  WHERE (s.Datatype = @datatype or @datatype = '' or @datatype is null)  AND s.TableName <> 'bHQMA'  AND s.ViewIsOutOfSync='Y'    
  ORDER BY ViewName      
      
 IF @@rowcount = 0      
  BEGIN
   SELECT @msg = 'Unable to retrieve tables.', @rcode = 1      
  END     
END        
        
 vspexit:       
   RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspVAViewGenGetOutOfSyncViews] TO [public]
GO
