SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************/
CREATE proc [dbo].[bspMSHaulEntryTicketsFill]
/****************************************************************************
 * Created By:	GF 08/02/2007
 * Modified By:	Dan So 03/20/08 - Issue #127258 - Display SaleDate and Truck
 *				DAN SO 12/28/2009 - Issue #136901 - Uncomment/modified code that UPPER @driver
 *
 *
 *
 * USAGE: Called from MSHaulEntryTics to return a resultset to bind to the ticket
 * verification grid.
 *
 * INPUT PARAMETERS:
 * @co			MS Company
 * @mth			MSHB Batch Month
 * @batchid		MSHB Batch Id
 * @batchseq	MSHB Batch Sequence
 *
 * OUTPUT PARAMETERS:
 * Quote, Purchaser, Description, Quote Date, Expired Date, Active Flag
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
 @msg varchar(8000) output)
as
set nocount on

declare @rcode int, @sql varchar(2000), @saledate bDate, @haultype varchar(1),
		@vendorgroup bGroup, @haulvendor bVendor, @truck varchar(10), @driver bDesc,
		@emco bCompany, @prco bCompany, @emgroup bGroup, @equipment bEquip,
		@employee bEmployee

select @rcode = 0

---- get MSHB information
select @saledate=SaleDate, @haultype=HaulerType, @vendorgroup=VendorGroup, @haulvendor=HaulVendor,
		@truck=Truck, @driver=Driver, @emco=EMCo, @prco=PRCo, @emgroup=EMGroup,
		@equipment=Equipment, @employee=Employee
from MSHB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq



-- ISSUE: #136901 --
IF @driver IS NOT NULL
	BEGIN
		SET @driver = UPPER(RTRIM(@driver))
	END


---- build sql query statement to execute
select @sql = 'select a.MSTrans, a.FromLoc, a.Ticket, '
select @sql = @sql + '''SaleType'' = case a.SaleType when ''C'' then ''Customer'' when ''J'' then ''Job'' when ''I'' then ''Inventory'' else '''' end,'
select @sql = @sql + ' a.MatlGroup, a.Material, b.Description, a.UM, a.MatlUnits, a.VerifyHaul, a.SaleDate, a.Truck'
---- where clause
select @sql = @sql + ' from MSTD a left join HQMT b on b.MatlGroup=a.MatlGroup and b.Material=a.Material'
select @sql = @sql + ' where a.MSCo=' + convert(varchar(3),@co)
select @sql = @sql + ' and a.Mth= ' + CHAR(39) + convert(varchar(30),@mth,101) + CHAR(39)
select @sql = @sql + ' and a.SaleDate = ' + CHAR(39) + convert(varchar(30),@saledate,101) + CHAR(39)
select @sql = @sql + ' and a.HaulTrans is null'

------set @msg = @sql

---- hauler type info
if @haultype = 'E'
	begin
	select @sql = @sql + ' and a.HaulerType = ' + CHAR(39) + 'E' + CHAR(39)
	if isnull(@emco,'') <> ''
		begin
		select @sql = @sql + ' and a.EMCo = ' + convert(varchar(3),@emco)
		end
	else
		begin
		select @sql = @sql + ' and a.EMCo is null'
		end
	if isnull(@equipment,'') <> ''
		begin
		select @sql = @sql + ' and a.Equipment = ' + CHAR(39) + @equipment + CHAR(39)
		end
	else
		begin
		select @sql = @sql + ' and a.Equipment is null'
		end
	if isnull(@prco,'') <> ''
		begin
		select @sql = @sql + ' and a.PRCo = ' + convert(varchar(3),@prco)
		end
	else
		begin
		select @sql = @sql + ' and a.PRCo is null'
		end
	if isnull(@employee,'') <> ''
		begin
		select @sql = @sql + ' and a.Employee = ' + convert(varchar(10),@employee)
		end
	else
		begin
		select @sql = @sql + ' and a.Employee is null'
		end
	goto bspExecuteSQL
	end

if @haultype = 'H'
	begin
	select @sql = @sql + ' and a.HaulerType = ' + CHAR(39) + 'H' + CHAR(39)
	if isnull(@haulvendor,'') <> ''
		begin
		select @sql = @sql + ' and a.HaulVendor = ' + convert(varchar(10),@haulvendor)
		end
	else
		begin
		select @sql = @sql + ' and a.HaulVendor is null'
		end
	if isnull(@truck,'') <> ''
		begin
		select @sql = @sql + ' and a.Truck = ' + CHAR(39) + @truck + CHAR(39)
		end
	else
		begin
		select @sql = @sql + ' and a.Truck is null'
		end

	if @driver is not null
		begin
			select @sql = @sql + ' and UPPER(RTRIM(isnull(Driver,''''))) = ' + CHAR(39) + @driver + CHAR(39)
		end
	else
		begin
			select @sql = @sql + ' and a.Driver is null'
		end

	goto bspExecuteSQL
	end

-- INVALID HAULER TYPE
select @sql = @sql + ' and 1=2'


bspExecuteSQL:
exec (@sql)

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulEntryTicketsFill] TO [public]
GO
