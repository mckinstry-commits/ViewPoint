SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      PROC [dbo].[vspAPT5RefilingGridFill]
  
  /***********************************************************
   * CREATED BY: MV 06/12/09 - #127230 Canadian T5018 reporting
   * MODIFIED By:	MV 09/29/10 - #139807 - return amended amount
   *							 in 'Amount' if Type is not 'O' original. 
					AR 10/27/10 - #135214 Cleaning up code to pass SQL Upgrade Advisor
   *				MV 06/18/12 - TK15758 restrict Amended refiling by bAPVM.V1099YN = 'Y' (vendor is still subject to T5)
   *		
   *
   * Usage:
   *	Used by APT5018 form to fill the grid 
   *
   * Input params:
   *	@enddate			
   *
   * Output params:
   *	@msg		error message
   *
   * Return code:
   *	0 = success, 1 = failure
   *****************************************************/
(
  @apco bCompany,
  @perenddate bDate,
  @vendorgroup bGroup
)
AS 
SET NOCOUNT ON
-- #135214 removing the alaising of a column that has the same name of the alias
SELECT  t.Vendor,
        v.Name,
        t.OrigReportDate,
        t.OrigAmount,
        t.RefilingYN,
        CASE t.Type
          WHEN 'O' THEN t.OrigAmount
          ELSE t.Amount
        END AS Amount,
        CASE t.Type
          WHEN 'O' THEN 'A'
          ELSE t.Type
        END AS [Type]
FROM    dbo.bAPT5 t
        JOIN dbo.bAPVM v ON t.VendorGroup = v.VendorGroup
                            AND t.Vendor = v.Vendor
WHERE   t.APCo = @apco
        AND t.PeriodEndDate = @perenddate
        AND t.VendorGroup = @vendorgroup
        AND v.V1099YN = 'Y'
ORDER BY t.Vendor
	  




                 
GO
GRANT EXECUTE ON  [dbo].[vspAPT5RefilingGridFill] TO [public]
GO
