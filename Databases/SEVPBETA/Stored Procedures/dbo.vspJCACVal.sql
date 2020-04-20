SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCACInfo    Script Date: 8/28/99 9:32:55 AM ******/
  CREATE          proc [dbo].[vspJCACVal]
	/*************************************
	* CREATED BY: DANF 11/21/2005
	* MODIFIED By : DANF 01/06/2005 - Issue 29595 - Added Allocation Last run information.
	*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
	*				
	* USAGE:
	* used by JCACRUN to get information about the Allocation 
	* before it is run.
	* Pass in :
	*	JCCo, AllocationCode
	*
	* Returns

	*	Returns a result set of the information from a specific JCAC Record
	*
	* Error returns no rows
	*******************************/
(@jcco bCompany, @alloccode smallint,
@SelectJobs char(1) output, @SelectDepts char(1)  output, @AllocBasis char(1)  output,
@MthDateFlag char(1)  output, @AmtRateFlag char(1) output, @AllocAmtRate varchar(30) output, 
@AllocColumn varchar(30) output, @Phase bPhase output, @CostType bJCCType output, 
@AllocInfo varchar(500) output, @msg varchar(255) output)

  as
  set nocount on
  
--#142350 - removing AllocCode
DECLARE @rcode int,
		@AllocCostTypes varchar(60),
		@BasisString varchar(60),
		@LastPosted smalldatetime,
		@LastMonth smalldatetime,
		@LastBeginDate smalldatetime,
		@LastEndDate smalldatetime
			
  select @rcode = 0
  
  
  if @jcco is null
  	begin
  	select @msg = 'Missing JC Company!', @rcode = 1
  	goto bspexit
  	end
  
  if @alloccode is null
  	begin
  	select @msg = 'Missing Allocation Code!', @rcode = 1
  	goto bspexit
  	end
  
  
  select @msg = Description,
		@SelectJobs = SelectJobs, 
		@SelectDepts = SelectDepts, 
		@AllocBasis = AllocBasis, 
		@MthDateFlag = MthDateFlag, 
		@AmtRateFlag = AmtRateFlag, 
		@AllocAmtRate = case when AmtRateFlag='A' Then convert(varchar(30),AllocAmount) else convert(varchar(30),AllocRate) END,
        @AllocColumn = case when AmtRateFlag='A' Then AmtColumn else RateColumn END, 
		@Phase = Phase, 
		@CostType = CostType,
		@LastPosted = LastPosted,
		@LastMonth = LastMonth,
		@LastBeginDate = LastBeginDate,
		@LastEndDate = LastEndDate
  	from dbo.JCAC with (nolock)
  	where JCCo = @jcco and AllocCode = @alloccode
  
  if @@rowcount = 0
  	begin
  	select @msg = 'Allocation Code not on file!', @rcode = 1
  	goto bspexit
  	end

 if @SelectJobs not in ('P','A','J')
	begin
	select @msg = ' Invalid Job information for Allocation Code.', @rcode = 1
	goto bspexit
	end

 if @SelectDepts not in ('P','D','A')
	begin
	select @msg = ' Invalid Department information for Allocation Code.', @rcode = 1
	goto bspexit
	end


if @AllocBasis not in ('C','H','R')
	begin
	select @msg = ' Invalid Allocation Basis for Allocation Code.', @rcode = 1
	goto bspexit
	end


select @AllocCostTypes = isnull(@AllocCostTypes,'') + ' ' + convert(varchar(3),CostType) 
from dbo.JCAT with (nolock) 
where JCCo=@jcco and AllocCode=@alloccode

select @AllocInfo = 'Applies to '

select @AllocInfo = @AllocInfo + 
	Case @SelectJobs
      when 'P' then 'job entered below'
      when 'A' then 'all jobs'
      when 'J' then 'selected jobs.' end

select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Applies to '

select @AllocInfo = @AllocInfo + 
	Case @SelectDepts
		when 'P' then 'department entered below.'
		when 'D' then 'selected departments.'
		when 'A' then 'all departments.' end


Select @BasisString = 
	Case @AllocBasis
		when 'C' then 'Cost'
		when 'H' then 'Hours'
		when 'R' then 'Revenue' end

select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Based on ' + isnull(@BasisString,'') + ' for cost types : ' + isnull(@AllocCostTypes,'')
select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Allocates a '


If @AmtRateFlag = 'A' 
	select @AllocInfo = @AllocInfo + 'flat amount '
else
	select @AllocInfo = @AllocInfo + 'rate '

If IsNull(@AllocAmtRate,'') = ''
	select @AllocInfo = @AllocInfo + 'from the Job Column: ' + isnull(@AllocColumn,'')
else
	begin
	If @AmtRateFlag = 'A'
		select @AllocInfo = @AllocInfo + 'from the allocation amount. '
	else
		select @AllocInfo = @AllocInfo + 'from the allocation rate. '
	end

select @AllocInfo = @AllocInfo + char(13) + char(10) + 'Post result to Phase: ' + isnull(@Phase,'') + ' Cost type: ' + convert(varchar(3),isnull(@CostType,''))


If isnull(@LastPosted,'') = '' 
	select @AllocInfo = @AllocInfo + char(13) + char(10) + char(13) + char(10) + 'No processing has occurred for this allocation."'
Else
	begin
	select @AllocInfo = @AllocInfo + char(13) + char(10) + char(13) + char(10) + 'Last run on ' + convert(varchar(10),@LastPosted,101) + char(13) + char(10)
	if isnull(@LastBeginDate,'')<>'' and isnull(@LastEndDate,'') <> '' 
		select @AllocInfo = @AllocInfo + ' For the dates ' + convert(varchar(10),@LastBeginDate,101) + ' - ' + convert(varchar(10),@LastEndDate,101) + char(13) + char(10)
	if isnull(@LastMonth,'')<> ''
		select @AllocInfo = @AllocInfo + ' For the month ' + substring(convert(varchar(10),@LastMonth,1),1,3) + substring(convert(varchar(10),@LastMonth,1),7,2)
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCACVal] TO [public]
GO
