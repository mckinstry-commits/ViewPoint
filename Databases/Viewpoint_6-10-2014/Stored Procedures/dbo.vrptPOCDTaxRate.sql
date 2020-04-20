SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		HH
-- Create date: 7/11/2013
-- Description:	Executes [bspHQTaxRateGetAll] and calculate tax rate for POCD
-- Modifications:

-- =============================================
CREATE PROCEDURE [dbo].[vrptPOCDTaxRate]
	@POCo bCompany, 
	@PO varchar(15), 
	@ChangeOrder varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from 
-- interfering with SELECT statements. 
SET nocount ON; 

DECLARE @taxgroup bGroup 
DECLARE @taxcode bTaxCode 
DECLARE @compdate bDate
DECLARE @valueadd varchar(1) 
DECLARE @taxrate bRate 
DECLARE @gstrate bRate 
DECLARE @pstrate bRate
SET @pstrate = NULL
DECLARE @crdGLAcct bGLAcct 
DECLARE @crdRetgGLAcct bGLAcct 
DECLARE @dbtGLAcct bGLAcct 
DECLARE @dbtRetgGLAcct bGLAcct 
DECLARE @crdGLAcctPST bGLAcct 
DECLARE @ARcrdRetgGLAcctPST bGLAcct 
DECLARE @crdRetgGLAcctGST bGLAcct 
DECLARE @APcrdRetgGLAcctPST bGLAcct 

SELECT @taxgroup = POIT.TaxGroup, 
       @taxcode = POIT.TaxCode, 
       @compdate = POCD.ActDate 
FROM   POCD 
       INNER JOIN POIT 
               ON POCD.POCo = POIT.POCo 
                  AND POCD.PO = POIT.PO 
                  AND POCD.POItem = POIT.POItem 
WHERE  POCD.POCo = @POCo 
       AND POCD.PO = @PO 
       AND POCD.ChangeOrder = @ChangeOrder 

EXEC bspHQTaxRateGetAll 
  @taxgroup, 
  @taxcode, 
  @compdate, 
  @valueadd, 
  @taxrate output, 
  @gstrate output, 
  @pstrate output, 
  @crdGLAcct output, 
  @crdRetgGLAcct output, 
  @dbtGLAcct output, 
  @dbtRetgGLAcct output, 
  @crdGLAcctPST output, 
  @ARcrdRetgGLAcctPST output, 
  @crdRetgGLAcctGST output, 
  @APcrdRetgGLAcctPST output
  
SELECT POCD.*, 
       ( @taxrate * POCD.ChgTotCost ) AS ChgTotCostWithTax, 
       @taxgroup                      AS TaxGroup, 
       @taxcode                       AS TaxCode, 
       @compdate                      AS CompDate, 
       @valueadd                      AS ValueAdd, 
       @taxrate                       AS TaxRate, 
       @gstrate                       AS GstRate, 
       @pstrate                       AS PstRate, 
       @crdGLAcct                     AS CrdGLAcct, 
       @crdRetgGLAcct                 AS crdRetgGLAcct, 
       @dbtGLAcct                     AS dbtGLAcct, 
       @dbtRetgGLAcct                 AS dbtRetgGLAcct, 
       @crdGLAcctPST                  AS crdGLAcctPST, 
       @ARcrdRetgGLAcctPST            AS ARcrdRetgGLAcctPST, 
       @crdRetgGLAcctGST              AS crdRetgGLAcctGST, 
       @APcrdRetgGLAcctPST            AS APcrdRetgGLAcctPST 
FROM   POCD 
WHERE  POCD.POCo = @POCo 
       AND POCD.PO = @PO 
       AND POCD.ChangeOrder = @ChangeOrder 
	
END
GO
GRANT EXECUTE ON  [dbo].[vrptPOCDTaxRate] TO [public]
GO
