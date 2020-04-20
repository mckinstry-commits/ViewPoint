SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRDednLiabChecker]
   /***********************************************************
   * Created: GG 10/09/03
   * Modified: EN 12/04/03 - issue 23061  added isnull check, with (nolock), and dbo
   *			EN 7/09/08  #127015  added code to check in the 4 dedn/liab fields added to PRFI
   *              
   * Usage:
   * Finds all places where a given D/L code has been setup.  Can
   * be used by support or QA to look for incorrect D/L assignments.
   *
   *
   * Inputs:
   *   @prco		PR Company
   *   @dlcode		Deduction/Liability code to search for
   *
   * Output:
   *   none
   *****************************************************/
     (@prco bCompany = null, @dlcode bEDLCode = null)
   
   as
    
   declare @description bDesc, @dltype char(1), @category varchar(1), @state varchar(8000),
   @taxdedn bEDLCode, @unliab bEDLCode, @feddl bEDLCode, @count int, @local varchar(8000),
   @ins varchar(8000), @craft varchar(8000), @class varchar(8000), @emp varchar(8000),
   @ssdedn bEDLCode, @meddedn bEDLCode, @ssliab bEDLCode, @medliab bEDLCode
   
   set nocount on
   
   -- get general info for DLCode
   select @description = Description, @dltype = DLType, @category = CalcCategory
   from dbo.bPRDL with (nolock)
   where PRCo=@prco and DLCode=@dlcode
   if @@rowcount = 0
   	begin
   	print 'DLCode ' + convert(varchar,isnull(@dlcode,'')) + ' has not been setup in PR Co#' + convert(varchar,@prco)
   	goto bspexit
   	end
   print  'Searching for DLCode: ' + convert(varchar,isnull(@dlcode,'')) + ' ' + isnull(@description,'')
   	+ '   Type: ' + case @dltype when 'D' then 'Deduction' when 'L' then 'Liability' end
   	+ '   Calculation Category: ' + @category 
   print ''
   
   -- check Federal setup
   select @taxdedn = TaxDedn, @unliab = FUTALiab, 
		@ssdedn = MiscFedDL1, @meddedn = MiscFedDL2, @ssliab = MiscFedDL3, @medliab = MiscFedDL4 --#127015
   from dbo.bPRFI with (nolock) where PRCo = @prco
   if @@rowcount = 0
   	begin
   	print 'Missing Federal setup info.' 
   	print ''
   	goto statecheck
   	end
   if @taxdedn = @dlcode print 'Setup as the Federal Tax deduction.' 
   if @unliab = @dlcode print 'Setup as the FUTA liability.' 
   if @ssdedn = @dlcode print 'Setup as Misc Fed DL 1.' 
   if @meddedn = @dlcode print 'Setup as Misc Fed DL 2.' 
   if @ssliab = @dlcode print 'Setup as Misc Fed DL 3.' 
   if @medliab = @dlcode print 'Setup as Misc Fed DL 4.' 
   
   -- check Federal detail
   select @feddl from dbo.bPRFD with (nolock) where PRCo = @prco and DLCode = @dlcode
   if @@rowcount > 0 print 'Setup as a miscellanous Federal D/L.' 
   print ''
   
   statecheck:	-- check State Tax deduction
   select @state = State
   from dbo.bPRSI with (nolock) where PRCo = @prco and TaxDedn = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a State Tax deduction: ' + @state 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup as a tax deduction under multiple States:' 
   	select @state = ''	-- reset State variable
   	select @state = State + ', ' + @state from dbo.bPRSI with (nolock) where PRCo = @prco and TaxDedn = @dlcode
   	print substring(@state,1,len(@state)-1)
   	print ''
   	end
   -- check State SUTA liability
   select @state = State
   from dbo.bPRSI with (nolock) where PRCo = @prco and SUTALiab = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a SUTA liability: ' + @state 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup as a SUTA liability under multiple States:' 
   	select @state = ''	-- reset State variable
   	select @state = State + ', ' + @state from dbo.bPRSI with (nolock) where PRCo = @prco and SUTALiab = @dlcode
   	print substring(@state,1,len(@state)-1)
   	print ''
   	end
   -- check State misc D/Ls
   select @state = State
   from dbo.bPRSD with (nolock) where PRCo = @prco and DLCode = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a miscellanous State D/L.' 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup as a miscellanous D/L under multiple States:' 
   	select @state = ''	-- reset State variable
   	select @state = State + ', ' + @state from dbo.bPRSD with (nolock) where PRCo = @prco and DLCode = @dlcode
   	print substring(@state,1,len(@state)-1)
   	print ''
   	end
   
   -- check Local Tax setup
   select @local = LocalCode
   from dbo.bPRLI with (nolock) where PRCo = @prco and TaxDedn = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a Local tax deduction:' + @local 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup as a tax deduction under multiple Local Codes:' 
   	select @local = ''	-- reset Local variable
   	select @local = LocalCode + ', ' + @local from dbo.bPRLI with (nolock) where PRCo = @prco and TaxDedn = @dlcode
   	print substring(@local,1,len(@local)-1)
   	print ''
   	end
   -- check Local misc D/Ls
   select @local = LocalCode
   from dbo.bPRLD with (nolock) where PRCo = @prco and DLCode = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a miscellanous Local D/L: ' + @local 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup as a miscellanous D/L under multiple Local Codes:' 
   	select @local = ''	-- reset Local variable
   	select @local = LocalCode + ', ' + @local from dbo.bPRLD with (nolock) where PRCo = @prco and DLCode = @dlcode
   	print substring(@local,1,len(@local)-1)
   	print '' 
   	end
   
   -- check Insurance setup
   select @ins = State + '/' + InsCode
   from dbo.bPRID with (nolock) where PRCo = @prco and DLCode = @dlcode
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as an Insurance D/L: ' + @ins
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup under multiple States Insurance codes:'
   	select @ins = ''	-- reset Insurance variable
   	select @ins = State + '/' + InsCode + ', ' + @ins
   	from dbo.bPRID with (nolock) where PRCo = @prco and DLCode = @dlcode
   	print substring(@ins,1,len(@ins)-1)
   	print ''
   	end
   
   -- check Craft Master Items setup
   select @craft = Craft
   from dbo.bPRCI with (nolock) where PRCo = @prco and EDLCode = @dlcode and EDLType in ('D','L')
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as Craft Master D/L: ' + @craft 
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup under multiple Crafts:' 
   	select @craft = ''	-- reset Craft variable
   	select @craft = Craft + ', ' + @craft
   	from dbo.bPRCI with (nolock) where PRCo = @prco and EDLCode = @dlcode and EDLType in ('D','L')
   	print substring(@craft,1,len(@craft)-1)
   	print ''
   	end
   
   -- check Craft Class D/L setup
   select @class = Craft + '/' + Class
   from dbo.bPRCD with (nolock) where PRCo = @prco and DLCode = @dlcode 
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as Craft Class D/L: ' + @class
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup under multiple Craft/Classes:' 
   	select @class = ''	-- reset Class variable
   	select @class = Craft + '/' + Class + ', ' + @class
   	from dbo.bPRCD with (nolock) where PRCo = @prco and DLCode = @dlcode 
   	print substring(@class,1,len(@class)-1)
   	print ''
   	end
   
   -- check Craft Template Items
   select @craft = Craft + '/' + convert(varchar,Template)
   from dbo.bPRTI with (nolock) where PRCo = @prco and EDLCode = @dlcode and EDLType in ('D','L')
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as a Craft Template D/L: ' + @craft
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup under multiple Craft/Templates:' 
   	select @craft = ''	-- reset Craft/Template variable
   	select @craft = Craft + '/' + convert(varchar,Template) + ', ' + @craft
   	from dbo.bPRTI with (nolock) where PRCo = @prco and EDLCode = @dlcode and EDLType in ('D','L')
   	print substring(@craft,1,len(@craft)-1)
   	print ''
   	end
   
   -- check Craft Class Template D/L setup
   select @class = Craft + '/' + Class + '/' + convert(varchar,Template)
   from dbo.bPRTD with (nolock) where PRCo = @prco and DLCode = @dlcode 
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as Craft/Class Template D/L: ' + @class
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup under multiple Craft/Class/Templates:' 
   	select @class = ''	-- reset Class variable
   	select @class = Craft + '/' + Class + '/' + convert(varchar,Template) + ', ' + @class
   	from dbo.bPRTD with (nolock) where PRCo = @prco and DLCode = @dlcode 
   	print substring(@class,1,len(@class)-1)
   	print ''
   	end
   
   -- check Employee D/L setup
   select @emp = convert(varchar,Employee)
   from dbo.bPRED with (nolock) where PRCo = @prco and DLCode = @dlcode and EmplBased = 'Y'
   select @count = @@rowcount
   if @count = 1
   	begin
   	print 'Setup as an Employee based D/L: ' + @emp
   	print ''
   	end
   if @count > 1
   	begin
   	print 'Setup for multiple Employees:' 
   	select @emp = ''	-- reset Employee variable
   	select @emp = convert(varchar,Employee) + ', ' + @emp
   	from dbo.bPRED with (nolock) where PRCo = @prco and DLCode = @dlcode and EmplBased = 'Y'
   	print substring(@emp,1,len(@emp)-1)
   	print ''
   	end
   
   bspexit:
   	return

GO
GRANT EXECUTE ON  [dbo].[bspPRDednLiabChecker] TO [public]
GO
