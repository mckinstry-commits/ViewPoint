SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspJCDetail_Validation]
   /**************************************************
   *    creted: 12/19/02 TV
   *			 TV - 23061 added isnulls
   *    Purpose: Validate Roll-up code from front end.
   *
   *    Inputs: @co
   *            @code
   *
   *    Outputs: @errmsg
   *
   *
   **************************************************/
   (@co bCompany, @code Char(4),  @RollupType char(1)output,@RollupSel char(1) output, @msg varchar(255) output, @errmsg varchar(255) output)
   
    as
    
    set nocount on
    
    Declare @RollupDesc bDesc, @RollupSourceAP char(1),
            @RollupSourceMS char(1), @RollupSourceIN char(1), @RollupSourcePR char(1), @RollupSourceAR char(1),
            @RollupSourceJC char(1), @RollupSourceEM char(1), @SummaryLevel char(1), @MonthsBack int, @lastClosedMth bMonth,
   		   @glco bCompany, @rcode int

   
   select @rcode = 0
   
   if isnull(@code, '') = ''
       begin
       select @rcode = 1, @errmsg = 'You must enter a code.'
       goto bspexit
       end 
   
	select	@errmsg = RollupDesc,
			@RollupDesc = RollupDesc, @RollupType = RollupType, @RollupSel = RollupSel, @RollupSourceAP = RollupSourceAP,
            @RollupSourceMS = RollupSourceMS, @RollupSourceIN = RollupSourceIN, @RollupSourcePR = RollupSourcePR,
            @RollupSourceAR = RollupSourceAR, @RollupSourceJC = RollupSourceJC, @RollupSourceEM = RollupSourceEM,
            @SummaryLevel = SummaryLevel, @MonthsBack = MonthsBack
	from JCRU with (nolock)
	where JCCo = @co and RollupCode = @code 
    if @@rowcount <> 1
       begin
       select @rcode = 1, @errmsg = 'Invalid Roll-up code.'
       goto bspexit
       end
   
    Select @glco = GLCo from bJCCO where JCCo = @co
   
    select @lastClosedMth = (select LastMthSubClsd from bGLCO where GLCo = @glco) 
    
    --Roll-up Type (Cost or Revenue)
    if @RollupType = 'R' 
        begin
        select @msg = 'Compresses Revenue Detail ' 
        end
    else
        begin
        select @msg = 'Compresses Cost Detail ' 
        end
    
    -- Roll-up selected (All or Selected)
    if @RollupSel = 'A' 
        begin
        select @msg = isnull(@msg,'') + '$Applies to all Contract/Jobs ' 
                           
        end
    else
        begin
        select @msg =isnull( @msg,'') + '$Applies to selected Contract/Jobs ' 
                             
        end
    
    --Sources
    select @msg = isnull(@msg,'') + '$Sources: '
                         
    if @SummaryLevel = 'M'
        select @msg = isnull(@msg,'') + 'All '
    else
        begin
        if @RollupSourceAP = 'Y'
            select @msg = isnull(@msg,'')+ 'AP '
        if @RollupSourceMS = 'Y'
            select @msg = isnull(@msg,'') + 'MS '
        if @RollupSourceIN = 'Y'
            select @msg = isnull(@msg,'') + 'IN '
        if @RollupSourcePR = 'Y'
            select @msg = isnull(@msg,'') + 'PR '
        if @RollupSourceAR = 'Y'
            select @msg = isnull(@msg,'') + 'AR '
        if @RollupSourceJC = 'Y'
            select @msg = isnull(@msg,'') + 'JC '
        if @RollupSourceEM = 'Y'
            select @msg = isnull(@msg,'') + 'EM '
        end
    
    --Summary level
    if @SummaryLevel = 'M'
        begin
        select @msg = isnull(@msg,'') + '$Summary Level: Mth'
        end
    if @SummaryLevel = 'S'
        begin
        select @msg = isnull(@msg,'') + '$Summary Level: Mth/Source'
        end
    if @SummaryLevel = 'D'
        begin
        select @msg = isnull(@msg,'') + '$Summary Level: Mth/Source/Detail'
        end
    select @lastClosedMth =  dateadd(month,@MonthsBack * -1,@lastClosedMth)
    --Month back
    Select @msg = isnull(@msg,'') + '$Will rollup detail through ' + 
                         isnull(convert(varchar(5), Month(@lastClosedMth)),'') + '/' +  isnull(substring(convert(varchar(5), year(@lastClosedMth)),3,2),'')
                          
   
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCDetail_Validation] TO [public]
GO
