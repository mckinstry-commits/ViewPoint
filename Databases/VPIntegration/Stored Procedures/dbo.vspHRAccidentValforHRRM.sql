SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRAccidentValforHRRM]
/************************************************************************
* CREATED:	mh 9/22/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validate Accident and return next Seq for add.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany, @acc varchar(10), @seq int output, @accdate bDate output, @mshaid varchar(10) output, @msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

    select @rcode = 0


	if not exists(select 1 from HRAT where HRCo = @hrco and Accident = @acc)
	begin
		select @msg = 'Invalid Accident.  Accident does not exist or has not been entered.', @rcode = 1
		goto vspexit
	end
	else
	begin
		select @accdate = AccidentDate, @mshaid = MSHAID from HRAT where HRCo = @hrco and Accident = @acc
	end

	--select @seq = max(isnull(HRAI.Seq, 0)) + 1 from HRAI where HRAI.HRCo = @hrco and HRAI.Accident = @acc 

	select @seq = isnull(max(HRAI.Seq), 0) + 1 from HRAI where HRAI.HRCo = @hrco and HRAI.Accident = @acc 

	
vspexit:

     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRAccidentValforHRRM] TO [public]
GO
