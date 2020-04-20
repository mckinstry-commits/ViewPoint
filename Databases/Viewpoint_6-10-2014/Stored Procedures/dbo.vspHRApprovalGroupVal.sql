SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspHRApprovalGroupVal]
CREATE procedure [dbo].[vspHRApprovalGroupVal]
/************************************************************************
* CREATED:	Dan Sochacki 12/13/2007     
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*   Validate PTO/Leave Approval Group entered in HR Resrouce Master
*		exists in bHRAG under the incoming HRCo
*    
*           
* Notes about Stored Procedure
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@HRCo bCompany = null, @AppGroup bGroup = null, @msg varchar(80) = '' output)

AS
SET NOCOUNT ON

    DECLARE @rcode int

    SELECT @rcode = 0

	-- CHECK FOR EXISTING RECORD
	SELECT @msg = AppvrGrpDesc
	  FROM HRAG WITH (NOLOCK)
     WHERE HRCo = @HRCo
       AND PTOAppvrGrp = @AppGroup
 
	-- RETURN ERROR IF NO GROUP WAS FOUND
  	IF @@rowcount = 0
  	BEGIN
  		SELECT @msg = 'Leave Approval Group does not exist!', @rcode = 1
  		GOTO vspexit
  	END

vspexit:

     RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRApprovalGroupVal] TO [public]
GO
