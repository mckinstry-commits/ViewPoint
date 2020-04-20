SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         procedure [dbo].[vspPRDedLiabCodeVal]
  /************************************************************************
  * CREATED:	EN 6/10/05 copied from bsp version ... @active changed from 1/0 to Y/N in 6x - also needed to return D/L description for 6x
  * MODIFIED:	
  *
  * Purpose of Stored Procedure
  *
  *  Check if a DLCode has been used in HR.
  *
  *
  * Notes about Stored Procedure
  *
  *
  * returns 0 if and msg=D/L description if successful
  * returns 1 and error msg if failed
  *
  *************************************************************************/
  
  
      (@prco bCompany, @dlcode bEDLCode, @dlcodeinhr bYN output, @msg varchar(80) = '' output)
  
  as
  set nocount on
  
      declare @rcode tinyint, @hrco bCompany, @active bYN, @benecode bEDLCode
  
      select @rcode = 0, @dlcodeinhr = 'N'

	--get HR Active Flag ... flag is automatically 'N' if HR is not set up in DDMO or License Level = 0
	select @active = 'N'
	select @active = Active from dbo.vDDMO where Mod = 'HR' and LicLevel > 0
  
  	if @active = 'N'
  		goto bspexit
  	else
  		begin
  			--get HRCo
  			declare cHRCo cursor
  			for
  			select HRCo from HRCO where PRCo = @prco
  			open cHRCo
  
  			fetch next from cHRCo into @hrco
  
  			while @@fetch_status = 0
  			begin
  				--check HR for deduction/liab code
  
  				--check HRBI
  				if exists(select EDLCode from HRBI where HRCo = @hrco and EDLType<>'E' and EDLCode = @dlcode)
  				begin
  					select @dlcodeinhr = 'Y'
  					goto closecursor
  				end
  
  				--check HRBD
  				if exists(select EDLCode from HRBD where Co = @hrco and EDLType<>'E' and EDLCode = @dlcode)
  				begin
  					select @dlcodeinhr = 'Y'
  					goto closecursor
  				end		
  
  				--check HRBL
  				if exists(select DLCode from HRBL where HRCo = @hrco and DLCode = @dlcode)
  				begin
  					select @dlcodeinhr = 'Y'
  					goto closecursor
  				end					
  
  				fetch next from cHRCo into @hrco
  			end
  		end
  
  closecursor:
  
  	close cHRCo
  	deallocate cHRCo
  
  bspexit:
  
	--get D/L description
	select @msg='Deduction/Liability code not on file!'
	select @msg=Description from dbo.PRDL with (nolock) where PRCo=@prco and DLCode=@dlcode

       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPRDedLiabCodeVal] TO [public]
GO
