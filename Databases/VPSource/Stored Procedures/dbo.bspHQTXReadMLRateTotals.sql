SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROC [dbo].[bspHQTXReadMLRateTotals]
   /********************************************************
   * CREATED BY: 	JM 1/20/00
   * MODIFIED BY: JM 1/2/01 - Removed verification of multi-level tax code - causes
   *	problem at form level when switching to ML for first time and not necessary.
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
   *
   * USAGE:
   * 	Returns sums for bHQTX.NewRate and bHQTX.OldRate on multi-level tax codes.
   *
   * INPUT PARAMETERS:
   *	TaxGroup and TaxCode
   *
   * OUTPUT PARAMETERS:
   *	Sums of OldRate and NewRate for linked TaxCodes in bHQTL.
   *	Error message if applicable
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
(
  @taxgroup bGroup = NULL,
  @taxcode bTaxCode = NULL,
  @oldratetotal float OUTPUT,
  @newratetotal float OUTPUT,
  @msg varchar(60) OUTPUT
)
AS 
SET nocount ON
   
DECLARE @rcode int,
    @multilevel char(1)
SELECT  @rcode = 0
   
IF @taxgroup IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Tax Group',
                @rcode = 1
        GOTO bspexit
    END
   
IF @taxcode IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Tax Code',
                @rcode = 1
        GOTO bspexit
    END
   
   /* Verify multi-level tax code. */
   /*select @multilevel = MultiLevel
   from bHQTX
   where TaxGroup = @taxgroup
       and TaxCode = @taxcode
   if @multilevel <> 'Y'
   	begin
   	select @msg = 'Tax Code not Multi-Level', @rcode = 1, @oldratetotal = 0, @newratetotal = 0
   	goto bspexit
   	end*/
   
   /* Get totals. */
SELECT  @oldratetotal = SUM(HQTX1.OldRate),
        @newratetotal = SUM(HQTX1.NewRate)
FROM    dbo.HQTX HQTX1
			JOIN dbo.HQTL ON HQTX1.TaxGroup = HQTL.TaxGroup
							AND HQTX1.TaxCode = HQTL.TaxLink
WHERE   HQTL.TaxGroup = @taxgroup
        AND HQTL.TaxCode = @taxcode
   
bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQTXReadMLRateTotals] TO [public]
GO
