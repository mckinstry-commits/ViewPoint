SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCCIDefaultUMGet    Script Date: 8/28/99 9:35:00 AM ******/
   CREATE   proc [dbo].[bspJCCIDefaultUMGet]
   /*************************************
   * CREATED BY: JM   3/17/98
   * MODIFIED By : TV - 23061 added isnulls
   *				Dan So - 03/24/08 - 127504 - IsMetric Nullable - commented out IS NULL check
   *
   * USAGE:
   *	Returns default um and default unit price.
   *	If imperial, uses JCSI.UM = def um and JCSI.UnitPrice = def up
   *	If metric, uses JCSI.MUM = def um and JCSI.UnitPrice * JCMC.MIFactor = def up
   *
   * Pass:
   *	JCCM.SIRegion - Std Item Region from contract master
   *	JCCI.SICode - Std Item Code from contract items
   *	JCCM.SIMetric - Whether to use metric from contract master
   *
   * Success returns:
   *	0 and either UM or MUM from JCSI
   *
   * Error returns:
   *	1 and error message
   **************************************/
   	(@siregion varchar(6) = null, @sicode varchar(16) = null,
   	@simetric char(1) = null, @defum bUM = '' output,
   	@defup bUnitCost = 0 output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   declare @mifactor real -- conv factor metric -> imp
   declare @impum bUM --imperial um
   declare @mum bUM --metric um
   declare @impup bUnitCost --imperial unit price
   select @rcode = 0
   
   if @siregion is null
   	begin
   	select @msg = 'Missing Std Item Region', @rcode = 1
   	goto bspexit
   	end
   
   if @sicode is null
   	begin
   	select @msg = 'Missing Std Item Code', @rcode = 1
   	goto bspexit
   	end
   
--   if @simetric is null
--   	begin
--   	select @msg = 'Missing Std Item Metric', @rcode = 1
--   	goto bspexit
--   	end
   
   select @impup = UnitPrice, @impum = UM, @mum = MUM
   	from bJCSI
   	where SIRegion = @siregion and SICode = @sicode
   
   if @simetric = 'Y'
   	begin
   	/* set default um to metric um */
   	select @defum = @mum
   	/* set default unit price to imperial unit price converted
    	 * to metric per factor in JCMC table */
   	select @mifactor = MIFactor
   	from bJCMC
   	where UM = @impum and MUM = @mum
   	/* set factor to 0 if doesnt exist in JCMC so defup will = 0 */
   	if @mifactor is null
   		select @mifactor = 0
   	/* set defup */
   	select @defup = @impup * @mifactor
   	end
   else
   	begin
   	/* set default um to imperial um */
   	select @defum = @impum
   	select @defup = @impup
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCIDefaultUMGet] TO [public]
GO
