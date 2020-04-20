SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMGetNextSLPOMOItem  ******/
CREATE proc [dbo].[vspPMGetNextSLPOMOItem]
/*************************************
 * Created By:	10/05/2006 6.x only
 * Modified By:	GP 1/2/2011 TK-10531 - added @APCo and @INCo to get correct company values before checking
 *							for next SL, PO, or MO number.
 *
 *
 * Used to get the next item for a subcontract, purchase order, or material order.
 * Called from PM Subcontract detail, PM Material Detail, PM SL Items, PM PO Items,
 * and PM MO Items. Will get max(Item) from PMSL/PMMF and the appropiate accounting
 * table (SLIT, POIT, INMI). Will return higher of the max items plus 1.
 *
 *
 * Pass:
 * Co			Accounting Company (SL,PO, or IN)
 * module		Accounting module we are getting max item for.
 * header		This will be either the SL, PO, or MO number to get next item for
 *
 * Success returns:
 * 0 on Success, 1 on ERROR
 * @nextitem		the next sequential item
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@co bCompany = null, @module varchar(2) = null, @header varchar(60) = null,
 @nextitem bItem = null output)
as
set nocount on

declare @rcode int, @pmitem bItem, @slitem bItem, @poitem bItem, @moitem bItem, @APCo bCompany, @INCo bCompany

select @rcode = 0, @nextitem = 0

if @co is null or @module is null or @header is null
	begin
	select @rcode = 1
	goto bspexit
	end
	
--Get company values from PM Company Parameters
select @APCo = APCo, @INCo = INCo
from dbo.PMCO
where PMCo = @co	

---- get max(Item) for Subcontract from either PMSL or SLIT
if @module = 'SL'
	begin
	---- get max item from PMSL
	select @pmitem=max(SLItem)
	from PMSL with (nolock) where SLCo=@APCo and SL=@header
	if @@rowcount = 0 or @pmitem is null
		begin
		select @pmitem = 0
		end
	---- get max item from SLIT
	select @slitem=max(SLItem)
	from SLIT with (nolock) where SLCo=@APCo and SL=@header
	if @@rowcount = 0 or @slitem is null
		begin
		select @slitem = 0
		end
	---- take highest of either item value and add one
	if @pmitem >= @slitem select @nextitem = @pmitem
	if @slitem > @pmitem select @nextitem = @slitem
	select @nextitem = @nextitem + 1
	end

---- get max(Item) for purchase order from either PMMF or POIT
if @module = 'PO'
	begin
	---- get max item from PMMF
	select @pmitem=max(POItem)
	from PMMF with (nolock) where POCo=@APCo and PO=@header
	if @@rowcount = 0 or @pmitem is null
		begin
		select @pmitem = 0
		end
	---- get max item from POIT
	select @poitem=max(POItem)
	from POIT with (nolock) where POCo=@APCo and PO=@header
	if @@rowcount = 0 or @poitem is null
		begin
		select @poitem = 0
		end
	---- take highest of either item value and add one
	if @pmitem >= @poitem select @nextitem = @pmitem
	if @poitem > @pmitem select @nextitem = @poitem
	select @nextitem = @nextitem + 1
	end

---- get max(Item) for purchase order from either PMMF or POIT
if @module = 'IN'
	begin
	---- get max item from PMMF
	select @pmitem=max(MOItem)
	from PMMF with (nolock) where INCo=@INCo and MO=@header
	if @@rowcount = 0 or @pmitem is null
		begin
		select @pmitem = 0
		end
	---- get max item from INMI
	select @moitem=max(MOItem)
	from INMI with (nolock) where INCo=@INCo and MO=@header
	if @@rowcount = 0 or @moitem is null
		begin
		select @moitem = 0
		end
	---- take highest of either item value and add one
	if @pmitem >= @moitem select @nextitem = @pmitem
	if @moitem > @pmitem select @nextitem = @moitem
	select @nextitem = @nextitem + 1
	end










bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMGetNextSLPOMOItem] TO [public]
GO
