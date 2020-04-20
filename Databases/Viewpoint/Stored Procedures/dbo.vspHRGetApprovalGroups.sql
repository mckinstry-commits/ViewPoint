SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspHRGetApprovalGroups]
CREATE procedure [dbo].[vspHRGetApprovalGroups]
/************************************************************************
* CREATED:	Dan Sochacki 01/22/2008     
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Get all HR Approval Groups associated with a Resource.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@HRCo bCompany = null, @HRRes bHRRef = null, @errmsg varchar(80) = '' output)

AS
SET NOCOUNT ON

    DECLARE @rcode int

    SELECT @rcode = 0

	---------------------------
	-- GET APPROVAL GROUP(S) --
	---------------------------
	SELECT PTOAppvrGrp, AppvrGrpDesc 
	  FROM HRAG WITH (NOLOCK)
	 WHERE HRCo = @HRCo 
	   AND (PriAppvr = @HRRes OR SecAppvr = @HRRes)

	----------------------------------------
	-- RETURN ERROR IF NO GROUP WAS FOUND --
	----------------------------------------
  	IF @@rowcount = 0
  	BEGIN
  		SELECT @errmsg = 'PTO Approval Group(s) not found!', @rcode = 1
  		GOTO vspExit
  	END

vspExit:

     RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGetApprovalGroups] TO [public]
GO
