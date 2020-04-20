SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspEMAssetTotals]
   /*************************************
   * CREATED BY: DANF 04/17/2007
   * MODIFIED BY: DAN SO 05/06/08 - Issue #126847 - Problem recalculating declining balance schedule when amt taken exists
   *			  DAN SO 07/18/08 - Issue #128708 - Rewrite of Depreciation back-end -> balance incorrect after recalc
   *
   * Returns totals for EM Asset form
   *
   * Pass:
   *	EMCO, Equipment, Asset
   *
   * Success returns:
   *	0 
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@emco bCompany = null, @equipment bEquip = null, @asset varchar(20), @TotalDeprAmt bDollar = NULL,
     @taken bDollar output, @balance bDollar output, @recalc bYN output,
	 @msg varchar(60) output)
   as 
   	set nocount on

   	declare	@rcode	int

	------------------
	-- PRIME VALUES --
	------------------
	SET	@rcode = 0
	SET @recalc = 'N'
   	
   if isnull(@equipment,'') = ''
   	begin
   		select @msg = 'Missing Equipment', @rcode = 1
   		goto bspexit
   	end
   
   if isnull(@asset,'') = ''
   	begin
   		select @msg = 'Missing Asset', @rcode = 1
   		goto bspexit
   	end

	--------------------------------------------------------------------------------------
	-- USING @TotalDeprAmt SINCE BALANCE CAN NOT BE ADDED CORRECTLY IF DEPRECIATION IS  --
	-- RECALCULATED WITH SOME EXISTING AMOUNTS TAKEN									--
	--------------------------------------------------------------------------------------
	SELECT	@taken = SUM(AmtTaken),
			@balance = ISNULL(@TotalDeprAmt, 0) - @taken
	  FROM  EMDS WITH (NOLOCK)
	 WHERE  EMCo = @emco 
	   AND  Equipment = @equipment 
	   AND  Asset = @asset


	if exists(select top 1 1 from EMDS with (nolock) where EMCo = @emco and Equipment = @equipment and Asset = @asset)
		begin
			select @recalc = 'Y'
		end


   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMAssetTotals] TO [public]
GO
