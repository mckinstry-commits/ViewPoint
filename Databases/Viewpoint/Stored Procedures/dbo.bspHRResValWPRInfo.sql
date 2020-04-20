SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspHRResValWPRInfo]
   /************************************************************************
   * CREATED:	MH 6/28/01    
   * MODIFIED:    allenn 3/06/2002 - issue 16164
   * 			mh 5/27/03 Issue 21360...see below
   *
   * Purpose of Stored Procedure
   *
   * 	Validate HR Resource and obtain PR data listed in HRRM.  
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@hrco bCompany = null, @hrref varchar(15), @refout bHRRef output, @prco bCompany output, 
   	@glco bCompany output, @prgroup bGroup output, @prdept bDept output, @craft bCraft output, 
   	@class bClass output, @inscode bInsCode output, @taxstate bStatus output, 
   	@unempstate bState output, @insstate bState output, @local bLocalCode output,
   	@earncode bEDLCode output, @position varchar(10) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @employee bEmployee
   
       select @rcode = 0
   
   --21360
   	--Cannot just rely on bspHRResourceVal.  If an non existant sort name is passed in
   	--an error is returned as it should.  However, if an non existant HRRef number is 
   	--passed in the code assumes the HRRef will be added and no error is returned.
   
   	--validate HRref...really just for when sort name is passed in as HRRef.
   	exec @rcode = bspHRResourceVal @hrco, @hrref, @refout output, @position output, @msg output
   
   	if @rcode = 0 
   	begin
   --21360
   		--if HRRef number was passed in it is possible that an error was not
   		--returned.  Do another query against HRRM...using @refout.
   
   		if exists(select HRRef from HRRM where HRCo = @hrco and HRRef = @refout)
   		begin
   			select @prco = PRCo, @prgroup = PRGroup, @prdept = PRDept, @craft = StdCraft, 
   			@class = StdClass, @inscode = StdInsCode, @taxstate = StdTaxState, 
   			@unempstate = StdUnempState, @insstate = StdInsState, @local = StdLocal, 
   			@earncode = EarnCode from HRRM where HRCo = @hrco and HRRef = @refout
   
   		end
   		else
   		begin
   			select @msg = 'Not a valid HR Resource Number', @rcode = 1
   		end
   
   		if @prco is null
   			select @prco = PRCo from HRCO where HRCo = @hrco
   
   		select @glco = GLCo from PRCO where PRCo = @prco
   
   	end
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRResValWPRInfo] TO [public]
GO
