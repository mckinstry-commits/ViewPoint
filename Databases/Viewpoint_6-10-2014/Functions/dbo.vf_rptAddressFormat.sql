SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptAddressFormat]  

/***********************************************************************      
Author:   
Scott Alvey plagerized from Eric Vaterlaus and vfSMAddressFormat
     
Create date:   
12/13/2012
      
Usage:
Format address fields into a sigle string with either embended HTML break tags or
char(13/10) tags based on the @Format parameter. 

Development Notes:
  
Parameters:    
@Address1 - typically has a value 
@Address2 - probably will not have a value
@City - typically has a value  
@State - typically has a value 
@Zip - typically has a value   
@Country - probably will not have a value 
@Format - returned data will be either formatted for HTML boxes or regular text boxes
  
Related objects that call this function: 
SMWorkOrder.rpt (RptID: 1111)
SMWorkOrderStatusByTechnicianDD.rpt (RptID: 1185)   
      
Revision History      
Date  Author  Issue     Description

***********************************************************************/  

(  
	@Address1 varchar(60) = '',  
	@Address2 varchar(60) = '',  
	@City varchar(20) = '',  
	@State varchar(5) = '',  
	@Zip varchar(15) = '',  
	@Country varchar(2) = '',
	@Format varchar(1) = 'H'  
)  

RETURNS varchar(240)  

AS  

BEGIN 
 
DECLARE 
	@ResultVar varchar(240),
	@LineFeed varchar(16) 
	
IF (@Format = 'H')
	BEGIN
		SELECT @LineFeed = '<br>'
	END
ELSE
	BEGIN
		SELECT @LineFeed = char(13) + char(10) 
	END

IF(@Address1 <> '')  
	BEGIN  
		SELECT @ResultVar = @Address1 + @LineFeed  
	END  
IF(@Address2 <> '')  
	BEGIN  
		SELECT @ResultVar = @ResultVar + @Address2 + @LineFeed 
	END  
IF(@City <> '')  
	BEGIN  
		SELECT @ResultVar = @ResultVar + @City + ', '  
	END  	
IF(@State <> '')  
	BEGIN  
		SELECT @ResultVar = @ResultVar + @State  
	END   
IF(@Zip <> '')  
	BEGIN  
		SELECT @ResultVar = @ResultVar + ' ' + @Zip  
	END  
IF(@Country <> '')  
	BEGIN  
		SELECT @ResultVar = @ResultVar + ' ' + @Country  
	END  

RETURN @ResultVar  

END  
GO
GRANT EXECUTE ON  [dbo].[vf_rptAddressFormat] TO [public]
GO
