SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRTSApproveUpdate]
/************************************************************************
* CREATED:		mh 5/14/07    
* MODIFIED:		 
*
* Purpose of Stored Procedure
*
*    Update ApprovedBy field in PRRH
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
        
    (@prco bCompany, @crew varchar(10), @postdate bDate, @sheetnum smallint, @approved bYN, @approvedby bVPUserName)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @approved = 'Y'
	begin
		Update PRRH set ApprovedBy = @approvedby, Status = 2 
		where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
	end

	if @approved = 'N'
	begin
		Update PRRH set ApprovedBy = null, Status = 1 
		where PRCo = @prco and Crew = @crew and PostDate = @postdate and SheetNum = @sheetnum
	end

vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRTSApproveUpdate] TO [public]
GO
