SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE[dbo].[vspVACompanyCopyLoadListview]
  /************************************************************************
  * CREATED: 	MV 06/04/07 
  * MODIFIED:   CC 03/18/2009 Issue# 127519 - Change select to return available tables from Viewpoint metadata 
  *
  * Purpose of Stored Procedure:	To fill the Available Tables Listview on
  *									frmVACompanyCopyforServers
  *    
  * 
  *
  * returns 0 if successfull 
  * returns 1 
  *
  *************************************************************************/
          
AS
BEGIN
SET NOCOUNT ON
  
DECLARE @rcode int
SELECT @rcode = 0

SELECT 
	  TableName
	, IsStaticTable
	, IsTransactionTable
FROM DDTables
WHERE CopyTable = 'Y'
ORDER BY TableName

IF @@ROWCOUNT = 0
	SELECT @rcode=1

bspexit:
   RETURN @rcode
   
END


GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyLoadListview] TO [public]
GO
