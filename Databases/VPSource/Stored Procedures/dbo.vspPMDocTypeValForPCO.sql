SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDocTypeValForPCO    Script Date: 09/16/2005 ******/
CREATE proc [dbo].[vspPMDocTypeValForPCO]
/*************************************
* Created By:	GF 09/16/2005
* Modified By:	GF 03/04/2009 - issue #132108 default int/ext flag
*				GF 02/21/2011 - TK-02849
*
*
* validates PM Document Types for PMPCO form. Returns active flag
* and PCO Dates 1, 2, 3 flags and descriptions
* and PCO Item Dates 1, 2, 3 flags and descriptions
*
* Pass:
* PCOType	PM Document Type
*
*
* Returns:
* @active
* @showpcodate1
* @showpcodate2
* @showpcodate3
* @pcodate1
* @pcodate2
* @pcodate3
* @showpcoitemdate1
* @showpcoitemdate2
* @showpcoitemdate3
* @pcoitemdate1
* @pcoitemdate2
* @pcoitemdate3
* @intextdefault
* @initaddons
* PCO Type Description
*
* tk-02849
* @BudgetType, @SubType, @POType, @ContractType, @PriceMethod
*
* Success returns:
* 0 and Description from PMDT
*
* Error returns:
*	1 and error message
**************************************/
(@pcotype bDocType = null, @active bYN = 'Y' output, 
 @showpcodate1 bYN = 'Y' output, @showpcodate2 bYN = 'Y' output,
 @showpcodate3 bYN = 'Y' output, @pcodate1 bDesc = null output,
 @pcodate2 bDesc = null output, @pcodate3 bDesc = null output,
 @showpcoitemdate1 bYN = 'Y' output, @showpcoitemdate2 bYN = 'Y' output,
 @showpcoitemdate3 bYN = 'Y' output, @pcoitemdate1 bDesc = null output, 
 @pcoitemdate2 bDesc = null output, @pcoitemdate3 bDesc = null output, 
 @intextdefault bYN = 'E' output, @initaddons bYN = 'Y' output,
 ----TK-02849
 @BudgetType CHAR(1) = 'N' OUTPUT, @SubType CHAR(1) = 'N' OUTPUT, @POType CHAR(1) = 'N' OUTPUT,
 @ContractType CHAR(1) = 'N' OUTPUT, @PriceMethod CHAR(1) = 'L' OUTPUT,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @doccategory varchar(10)

select @rcode = 0

if @pcotype is null
	begin
  	select @msg = 'Missing Pending Change Order Type!', @rcode = 1
  	goto bspexit
  	end

-- -- -- get information from PMDT
select @msg = Description, @doccategory=DocCategory, @active=Active,
		@showpcodate1=ShowPCODate1, @showpcodate2=ShowPCODate2, @showpcodate3=ShowPCODate3,
		@pcodate1=PCODate1, @pcodate2=PCODate2, @pcodate3=PCODate3,
		@pcoitemdate1=PCOItemDate1, @showpcoitemdate1=ShowPCOItemDate1,
		@pcoitemdate2=PCOItemDate2, @showpcoitemdate2=ShowPCOItemDate2,
		@pcoitemdate3=PCOItemDate3, @showpcoitemdate3=ShowPCOItemDate3,
		@intextdefault=IntExtDefault, @initaddons=InitAddons, ---- 132108
		----TK-02849
		@BudgetType=BudgetType, @SubType=SubType, @POType=POType,
		@ContractType=ContractType, @PriceMethod=PriceMethod
from dbo.PMDT with (nolock) where DocType = @pcotype
if @@rowcount = 0
	begin
	select @msg = 'PM Pending Change Order Type ' + isnull(@pcotype,'') + ' not on file!', @rcode = 1
	goto bspexit
	end
-- -- -- document category must be 'PCO'
if @doccategory <> 'PCO'
	begin
	select @msg = 'Document category is ' + isnull(@doccategory,'') + '.  must be of category PCO!', @rcode = 1
	goto bspexit
	END

---- check internal/external default using impact types TK-02849
IF @ContractType = 'Y' SET @intextdefault = 'E'
IF @BudgetType = 'Y' AND @ContractType = 'N' SET @intextdefault = 'I'








bspexit:
  	if @rcode<>0 select @msg = isnull(@msg,'')
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTypeValForPCO] TO [public]
GO
