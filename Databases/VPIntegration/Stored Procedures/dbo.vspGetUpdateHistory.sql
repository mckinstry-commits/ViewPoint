SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [dbo].[vspGetUpdateHistory]
   /***************************************************
   *    Created:	TMS 09/01/09 - Needed a way to insert data into the vDDUpdateHistory table
   *
   *    Purpose: Called from VCSUpdateManager to show history of downloaded updates   
   *  
   *    Input:
   *        @ProductCode - Product code of the product that we want to return entries for
   *                
   ****************************************************/
   (@ProductCode varchar(40))
   
   as
   set nocount on
   
    
   -- Get all entries for selected product --
   
   SELECT UpdateType, DownloadDate, [Description], FQDN_ComputerName,
   Download_Path,Download_User_Name, ISNULL(DateInstalled, '01/01/1900') as 'DateInstalled', Title, Product_Version,
   ISNULL(Service_Pack,' ') as 'Service_Pack'
   FROM DDUpdateHistory
   WHERE RTRIM(Product_Code) = RTRIM(@ProductCode)
   
   -- Return resultset if data is present, otherwise return an error --
   IF @@ROWCOUNT > 0
	BEGIN 
		RETURN
	END ELSE
		RETURN (-1)
	   

GO
GRANT EXECUTE ON  [dbo].[vspGetUpdateHistory] TO [public]
GO
