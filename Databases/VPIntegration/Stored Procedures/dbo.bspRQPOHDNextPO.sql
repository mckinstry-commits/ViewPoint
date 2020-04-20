SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspRQPOHDNextPO    Script Date: 9/30/2004 9:46:22 AM ******/
CREATE  proc [dbo].[bspRQPOHDNextPO]
/***********************************************************
 * CREATED BY	: DC 9/30/04
 * MODIFIED BY	: DC 11/20/07 - #124581 - Add a prefix input to be used before the starting PO#
 *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
 *					GF 10/27/2011 TK-09457 fix for convert bigint to varchar
 *					GP 4/4/2012 - TK-13774 added check against POUnique view
 *
 * USAGE:
 * looks at the POCO AutoPO flag to get the next PO
 * If AutoPO flag is 'Y' then get the PO 
 * If the AutoPO flag is 'N' then get the max PO 
 *
 * INPUT PARAMETERS
 *   POCo  PO Co to get next PO from
 *
 * OUTPUT PARAMETERS
 *   @PO    the next PO number to use
 *
 * RETURN VALUE
 *   0         success
 *   
 *****************************************************/
(@poco bCompany = 0, @po varchar(30) output)
as
set nocount on
    
declare @rcode int, @bpolen INT

SET @rcode = 0
----TK-09457
SET @bpolen = 30
----SELECT @bpolen = length FROM systypes WHERE name = 'bPO' --DC #124581

---- if AutoPO is Y then update the Current PO then read what the PO should be
IF EXISTS(SELECT 1 FROM dbo.POCO WHERE POCo = @poco and AutoPO='Y')
BEGIN
	IF (select ISNUMERIC(LastPO) from dbo.POCO where POCo = @poco) = 1
	BEGIN
		SELECT @po=LastPO 
		FROM dbo.POCO
		WHERE POCo = @poco
	END
	ELSE
	BEGIN
		--Get max PO value from POUnique view (POHD, POHB, POPendingPurchaseOrder)
		select @po = max(cast(PO as varchar))
		from dbo.POUnique
		where POCo = @poco
			and substring(ltrim(PO), 1, 1) not in ('+','-')	
			and isnumeric(PO) = 1
			and patindex('%[.]%', PO) = 0
			and datalength(PO) < 18
	END
END
ELSE
---- If AutoPO is N then get the max number in use.
BEGIN
	--Get max PO value from POUnique view (POHD, POHB, POPendingPurchaseOrder)
	select @po = max(cast(PO as varchar))
	from dbo.POUnique
	where POCo = @poco
		and substring(ltrim(PO), 1, 1) not in ('+','-')	
		and isnumeric(PO) = 1
		and patindex('%[.]%', PO) = 0
		and datalength(PO) < 18
END
    
---- IF there are no PO's then set @po = 1
IF @po is null
BEGIN
	SET @po = 1
END
ELSE
BEGIN
	----TK-09457
	---- IF length larger then allowed set to 1
	if len(convert(BIGINT,@po) + 1) > @bpolen 
	BEGIN				
		SET @po = 1
	END
	ELSE
	BEGIN
		---- set PO number				
		SET @po = CONVERT(BIGINT, @po) + 1
	END
END


return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspRQPOHDNextPO] TO [public]
GO
