SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/****** Object:  Stored Procedure dbo.vspPOItemLineJCUMConvGet  ******/
CREATE procedure [dbo].[vspPOItemLineJCUMConvGet]
/************************************************************************
 * Created By:	GF 08/17/2011 TK-07440
 * Modified By:	GF 11/21/2011 TK-10203 change UM conversion to bUnitCost
 *				GF 01/05/2011 TK-11551 missed a change to bUnitCost
 *
 *
 *
 *
 * PURPOSE:
 * Retrieve the JC conversion factor for the item material to use
 * when creating JCCD Committed Cost Entries.
 *
 *
 * Called from PO Item Line insert, update, and delete triggers currently.
 *
 *
 * INPUT:
 * @MatlGroup, @Material @UM, @JCUM
 *
 * OUTPUT:
 * @JCUMConv
 *
 *
 * RETURNS:
 *	0 - Success 
 *	1 - Failure
 *
 *************************************************************************/
(@MatlGroup bGroup = NULL, @Material bMatl = NULL, @UM bUM = NULL,
 @JCUM bUM = NULL, @JCUMConv bUnitCost = NULL OUTPUT,
 @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

declare @rcode INT, @HQMatl CHAR(3), @StdUM bUM, @UMConv bUnitCost
			
---- inititalize variables
SET @rcode = 0
SET @HQMatl = 'N'
SET @StdUM = NULL
SET @UMConv = 0
SET @JCUMConv = 0

---- check for Material in HQ
select @StdUM = StdUM
from dbo.bHQMT
where MatlGroup = @MatlGroup and Material = @Material
if @@rowcount = 1
	BEGIN
	-- setup in HQ Materials
	SET @HQMatl = 'Y'    
	if @StdUM = @UM set @UMConv = 1
	END

---- if HQ Material, validate UM and get unit of measure conversion
if @HQMatl = 'Y' and @UM <> @StdUM
	BEGIN
	select @UMConv = Conversion
	from dbo.bHQMU WITH (NOLOCK)
	where MatlGroup = @MatlGroup and Material = @Material and UM = @UM
	END
	
---- determine conversion factor from posted UM to JC UM
SET @JCUMConv = 0
IF ISNULL(@JCUM,'') = @UM SET @JCUMConv = 1

---- get JCUM conversion 
IF @HQMatl = 'Y' AND ISNULL(@JCUM,'') <> @UM
	BEGIN
	EXEC @rcode = dbo.bspHQStdUMGet @MatlGroup, @Material, @JCUM, @JCUMConv OUTPUT, @StdUM OUTPUT, @ErrMsg OUTPUT
	if @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,'')
		GOTO vspexit
		END
		
	---- check JCUM conversion
	IF @JCUMConv <> 0 SET @JCUMConv = @UMConv / @JCUMConv
	END









vspexit:
	return @rcode




GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineJCUMConvGet] TO [public]
GO
