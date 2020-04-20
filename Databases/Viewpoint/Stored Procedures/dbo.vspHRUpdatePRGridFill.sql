SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRUpdatePRGridFill]
/************************************************************************
* CREATED:	mh 11/8/05    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*	Populate the HRUpdatePR Grid    
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/


    (@hrco bCompany, @mth bMonth, @batchid bBatchID, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0

	if @hrco is null
	begin
		select @msg = 'Missing HR Company', @rcode = 1
		goto vspexit
	end

	if @mth is null
	begin
		select @msg = 'Missing Batch Month', @rcode = 1
		goto vspexit
	end

	if @batchid is null
	begin
		select @msg = 'Missing Batch ID', @rcode = 1
		goto vspexit
	end

	Select b.HRRef, b.Employee, isnull(h.FirstName, '') + ' ' + isnull(h.MiddleName, '') + ' ' + 
	isnull(h.LastName, '') as 'Name', BenefitSalaryFlag, b.BenefitCode, c.Description, b.BatchTransType 
	from HRBB b
	join HRRM h on b.Co = h.HRCo and b.HRRef = h.HRRef
	left outer join HRBC c on b.Co = c.HRCo and b.BenefitCode = c.BenefitCode
	where  b.Co = @hrco and b.Mth = @mth and b.BatchId = @batchid 


vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRUpdatePRGridFill] TO [public]
GO
