SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHRLicEndorseCopy]
   /************************************************************************
   * CREATED:    
   * MODIFIED:	DAN SO 07/20/2009 - ISSUE #133204 - Change Source/Dest datatype from bState to varchar(4)
   *												Added Country to the INSERT statement
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
       -- ISSUE: #133204 --
       (@sourcestate varchar(4) = null, @deststate varchar(4) = null, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int
   
       select @rcode = 0
   
   	if @sourcestate is null
   	begin
   		select @msg = 'Missing Source State.', @rcode = 1
   		goto bspexit
   	end
   
   	if @deststate is null
   	begin
   		select @msg = 'Missing Destination State.', @rcode = 1
   		goto bspexit
   	end
   
	-- ISSUE: #133204 --
	Insert HRRE (State, LicCodeType, LicCode, LicDesc, Country)
	(select @deststate, s.LicCodeType, s.LicCode, s.LicDesc, s.Country
	from dbo.HRRE s with (nolock) where s.State = @sourcestate and
	not exists (select 1 from dbo.HRRE d with (nolock) where d.State = @deststate and 
	s.LicCodeType = d.LicCodeType and s.LicCode = d.LicCode and s.Country = d.Country))
		
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHRLicEndorseCopy] TO [public]
GO
