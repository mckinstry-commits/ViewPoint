SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRPRPParamDefaultVal] 
/***********************************************
* Created: TRL 08/06/07
* Modified:
*
* Used to validate report parameter default values assigned
* to a form.
*
* Inputs:
**	@reportid		Report ID#
*	@param			Report Parameter
*	@defaulttype	Default Type
*	@default		Parameter default value
* 
************************************************/
   (@reportid int = null, @param varchar(30) = null, @inputtype tinyint = null,
	@defaulttype int = null, @default varchar(60) = null, @msg varchar(255) output)
   
as
   
set nocount on
declare @rcode int,  @char int, @tmp varchar(60)
select @rcode = 0
	
-- check for Default Type and Value consistency
if IsNull(@defaulttype,0) = 0 	-- literal fixed value
	begin
	if @default is not null
		begin
		if @inputtype in (1,6) and isnumeric(@default) = 0 	-- numeric, string to numeric
			begin
			select @msg = 'Default value must be numeric.', @rcode = 1
			goto vspexit
			end
		if @inputtype = 2 and isdate(@default) = 0		-- date
			begin
			select @msg = 'Default value must be a valid date.', @rcode = 1
			goto vspexit
			end
		if @inputtype = 3			-- month
			begin
			select @char = charindex('/',@default)
			if @char = 0
				begin
				select @msg = 'Default value must be a valid month.', @rcode = 1
				goto vspexit
				end
			else
				begin
				select @tmp = substring(@default,1,@char - 1) + '/01' + substring(@default,@char,len(@default))
				if isdate(@tmp) = 0
					begin
					select @msg = 'Default value must be a valid month.', @rcode = 1
					goto vspexit
					end
				end
			end
		end
	end	
if @defaulttype = 1		-- current date (+/-)
	begin
	if substring(isnull(@default,''),1,2) <> '%D'		
		begin
		select @msg = 'Date defaults must begin with ''%D''.', @rcode = 1
		goto vspexit
		end
	if len(@default) > 2
		begin
		if substring(@default,3,1) not in ('+','-') or len(@default) < 4
			or isnumeric(substring(@default,4,len(@default)-3)) = 0
		select @msg = 'Use + or - followed by a number to indicate number of days from current date.', @rcode = 1
		goto vspexit
		end
	end	
if @defaulttype = 2		-- current month (+/-)
	begin
	if substring(isnull(@default,''),1,2) <> '%M'		
		begin
		select @msg = 'Month defaults must begin with ''%M''.', @rcode = 1
		goto vspexit
		end
	if len(@default) > 2
		begin
		if substring(@default,3,1) not in ('+','-') or len(@default) < 4
			or isnumeric(substring(@default,4,len(@default)-3)) = 0
		select @msg = 'Use + or - followed by a number to indicate number of months from current date.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 3		-- report parameter
	begin
	if substring(isnull(@default,''),1,3) <> '%RP'		
		begin
		select @msg = 'Defaults based on other Report Parameters must begin with ''%RP''.', @rcode = 1
		goto vspexit
		end
	if len(@default) < 4
		begin
		select @msg = 'A Report Parameter must be included as part of the default value.', @rcode = 1
		goto vspexit
		end
	if not exists(select top 1 1 from dbo.RPRPShared (nolock) where ReportID = @reportid and ParameterName = substring(@default,4,len(@default)-3))
		begin
		select @msg = 'Default Report Parameter doesnot exist.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 4		-- form input
	begin
	if substring(isnull(@default,''),1,3) <> '%FI'		
		begin
		select @msg = 'Form Inputs ''%FI'' should only be used in RP Form Report Parameter Defaults.', @rcode = 1
		goto vspexit
		end
	end

if @defaulttype = 5		-- active Company
	begin
	if isnull(@default,'') <> '%C'		
		begin
		select @msg = 'Use ''%C'' to default active Company #.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 6		-- active Project
	begin
	if isnull(@default,'') <> '%Project'
		begin
		select @msg = 'Use ''%Project'' to default active PM Project.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 7		-- active Job
	begin
	if isnull(@default,'') <> '%Job'
		begin
		select @msg = 'Use ''%Job'' to default active JC Job.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 8		-- active Contract
	begin
	if isnull(@default,'') <> '%Contract'
		begin
		select @msg = 'Use ''%Contract'' to default active JC Contract.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 9		-- active PR Group
	begin
	if isnull(@default,'') <> '%PRGroup'
		begin
		select @msg = 'Use ''%PRGroup'' to default active PR Group.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 10		-- active PR Ending Date
	begin
	if isnull(@default,'') <> '%PREndDate'
		begin
		select @msg = 'Use ''%PREndDate'' to default active PR Ending Date.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 11		-- active JB Progress Bill Mth
	begin
	if isnull(@default,'') <> '%JBProgMth'
		begin
		select @msg = 'Use ''%JBProgMth'' to default active JB Progress Bill Month.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 12		-- active JB Progress Bill#
	begin
	if isnull(@default,'') <> '%JBProgBill'
		begin
		select @msg = 'Use ''%JBProgBill'' to default active JB Progress Bill#.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 13		-- active JB T&M Bill Mth
	begin
	if isnull(@default,'') <> '%JBTMMth'
		begin
		select @msg = 'Use ''%JBTMMth'' to default active JB T&M Bill Month.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 14		-- active JB T&M Bill#
	begin
	if isnull(@default,'') <> '%JBTMBill'
		begin
		select @msg = 'Use ''%JBTMBill'' to default active JB T&M Bill#.', @rcode = 1
		goto vspexit
		end
	end
if @defaulttype = 15		-- Report Attachment Channel
	begin
	if isnull(@default,'') <> '%RAC'
		begin
		select @msg = 'Use ''%RAC'' to default the active report channel used when printing attachments with the report.', @rcode = 1
		goto vspexit
		end
	end


vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspRPRPParamDefaultVal] TO [public]
GO
