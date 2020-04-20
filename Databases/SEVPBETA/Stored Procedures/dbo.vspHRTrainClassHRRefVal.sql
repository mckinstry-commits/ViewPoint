SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHRTrainClassHRRefVal]
/************************************************************************
* CREATED:	mh 8/23/06    
* MODIFIED:    
*
* Purpose of Stored Procedure
*
*    Validation procedure for Resource in HRTrainClassDetail.  Returns next 
*	available Seq in HRET and prevents a Resource from being registered for
*	the same class twice.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@hrco bCompany = null, @hrref varchar(15), @refout int output, @nextseq int output, @position varchar(10) output, 
	@msg varchar(80) = '' output)

as
set nocount on

    declare @rcode int

 /*
These need to become parameters
@traincode varchar(10), @classseq int 

*/

    select @rcode = 0

	exec @rcode = bspHRResVal @hrco, @hrref, @refout output, @position output, @msg output

	if @rcode = 1 
	begin
		goto bspexit
	end

/*
	if exists(select 1 from HRET where HRCo = @hrco and HRRef = @hrref and ClassSeq = @classseq)
	begin
		select @msg = 'Resource has already been registered for this class', @rcode = 1
	end
	else
	begin
*/
		select @nextseq = isnull(max(Seq), 0) + 1 from HRET where HRCo = @hrco and HRRef = @hrref
/*
	end
*/
        
bspexit:
    
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRTrainClassHRRefVal] TO [public]
GO
