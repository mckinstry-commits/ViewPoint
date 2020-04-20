SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspHRTrainCheckRegAvail]
   /************************************************************************
   * CREATED:	mh 2/13/04    
   * MODIFIED: mh 9/2/04   
   *
   * Purpose of Stored Procedure
   *
   *	Check the MaxAttend field in HRTC to get the maximum available spaces
   *	for a class.  Compare this to the number of previously registered 
   *	Resources and return the available space.
   *    
   *	9/2/04 - MaxAttend is a nullable field.  Do not calculate available 
   *	space if this field is null
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany, @traincode varchar(10), @type char(1), @classseq int, 
   	@availspace int output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @maxattend int, @regres int
   
       select @rcode = 0
   
   	select @maxattend = MaxAttend from HRTC where HRCo = @hrco and TrainCode = @traincode
   	and Type = @type and ClassSeq = @classseq
   
   	if @maxattend is not null
   	begin
   		select @regres = count(HRRef) from HRET where HRCo = @hrco and TrainCode = @traincode
   		and Type = @type and ClassSeq = @classseq
   	
   		if @regres > @maxattend 
   		begin
   			select @msg = 'More Resources are registered for this class then allowed.', @rcode = 1
   			goto bspexit
   		end
   	
   		select @availspace = @maxattend - @regres
   	end
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRTrainCheckRegAvail] TO [public]
GO
