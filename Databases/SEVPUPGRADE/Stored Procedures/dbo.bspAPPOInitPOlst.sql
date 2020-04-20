SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOInitPOlst    Script Date: 8/28/99 9:36:02 AM ******/


CREATE       PROC [dbo].[bspAPPOInitPOlst]
/***********************************************************
* CREATED BY:	danf 02/16/2000
* modified by:	TV	02/21/2001
*				danf 02/28/2002	- Added BatchMth and BatchId
*				kb	10/28/2002	- issue #18878 - fix double quotes
*				MV	12/09/2002	- #19429 - fixed batchmth and batchid case statement
*				GH	08/01/2006	- #30648 Performance Changes
*				MV	08/01/2006	- #120077 - rounding prob with TOBEINV calculation
*				AR	11/29/2010	- #142278 - removing old style joins replace with ANSI correct form
*				TRL 07/27/2011  - TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				CHS	08/12/2011	- TK-07641 added PO Item Line
*
* USAGE:
* Called by AP PO initialize program to populate list
*
* INPUTS:
*    @co         AP Company
*    @vendor     Vendor
*    @vendorgroup group
*
* OUTPUT:
*    @msg        Error message
*
* RETURN:
*    0           Success
*    1           Failure
*
*******************************************************************/
(
  @co bCompany = 0,
  @vendor bVendor,
  @vendorgroup bGroup,
  @po varchar(30),
  @invdate bDate,
  @batchid bBatchID,
  @batchmth bMonth,
  @msg varchar(255) OUTPUT
)
AS 
SET nocount ON
DECLARE @rcode int

SELECT  @rcode = 0

IF @po = '' 
    BEGIN
--select i.PO, h.Description,
        SELECT  h.PO,
                h.Description,
                CONVERT(decimal(14, 2), SUM(CASE t.RecvYN
                                              WHEN 'Y'
                                              THEN CASE t.UM
                                                     WHEN 'LS'
                                                     THEN CASE i.RecvdCost
                                                            WHEN i.InvCost
                                                            THEN 0
                                                            ELSE i.RecvdCost
                                                              - i.InvCost
                                                          END
                                                     ELSE CASE i.RecvdUnits
                                                            WHEN i.InvUnits
                                                            THEN 0
                                                            ELSE ROUND(( ( i.RecvdUnits
                                                              - i.InvUnits )
                                                              * ( t.CurUnitCost
                                                              / CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ), 2)
                                                          END
                                                   END
                                              ELSE CASE t.UM
                                                     WHEN 'LS'
                                                     THEN CASE i.BOCost
                                                            WHEN 0 THEN 0
                                                            ELSE i.BOCost
                                                          END
                                                     ELSE CASE i.BOUnits
                                                            WHEN 0 THEN 0
                                                            ELSE ROUND(( i.BOUnits
                                                              * ( t.CurUnitCost
                                                              / ( CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ) ), 2)
                                                          END
                                                   END
                                            END)) AS 'Left to be Invoiced', --TOBEINV,
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                                JOIN dbo.bHQCP c WITH ( NOLOCK ) ON  p.CompCode = c.CompCode 
																	AND p.PO = h.PO
                       WHERE	p.POCo = @co
                                AND p.Verify = 'Y'
                                AND ( ( c.CompType = 'F'
									        AND p.Complied = 'N'
                                      )
                                      OR ( c.CompType = 'D'
                                           AND ( @invdate > p.ExpDate )
                                           OR p.ExpDate IS NULL
                                         )
                                    )
                     )
                  WHEN 0 THEN ''
                  ELSE 'No'
                END AS 'Compliance',
                CASE WHEN ISNULL(h.InUseMth, '') <> ''
                          AND ( ISNULL(h.InUseMth, '') <> @batchmth
                                OR /*and #19429*/ ISNULL(h.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'
        FROM    vPOItemLine i WITH ( NOLOCK )                
				JOIN bPOIT t WITH ( NOLOCK )  ON i.POCo = t.POCo
                                                AND i.PO = t.PO
                                                AND i.POItem = t.POItem
                JOIN bPOHD h WITH ( NOLOCK ) ON i.POCo = h.POCo
                                                AND i.PO = h.PO
        WHERE   h.POCo = @co
                AND h.Vendor = @vendor
                AND h.VendorGroup = @vendorgroup
                AND h.Status = 0

		GROUP BY        h.PO,
						h.Description,
						h.Status,
						h.InUseMth,
						h.InUseBatchId
						
        HAVING  SUM(CASE t.RecvYN
                      WHEN 'Y'
                      THEN CASE t.UM
                             WHEN 'LS' THEN CASE i.RecvdCost
                                              WHEN i.InvCost THEN 0
                                              ELSE i.RecvdCost - i.InvCost
                                            END
                             ELSE CASE i.RecvdUnits
                                    WHEN i.InvUnits THEN 0
                                    ELSE ( ( i.RecvdUnits - i.InvUnits )
                                           * ( t.CurUnitCost
                                               / CASE t.CurECM
                                                   WHEN 'C' THEN 100
                                                   WHEN 'M' THEN 1000
                                                   ELSE 1
                                                 END ) )
                                  END
                           END
                      ELSE CASE t.UM
                             WHEN 'LS' THEN CASE i.BOCost
                                              WHEN 0 THEN 0
                                              ELSE i.BOCost
                                            END
                             ELSE CASE i.BOUnits
                                    WHEN 0 THEN 0
                                    ELSE ( i.BOUnits * ( t.CurUnitCost
                                                         / ( CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                             END ) ) )
                                  END
                           END
                    END) <> 0
    END

-- Filter by PO
IF @po <> '' 
    BEGIN
        SELECT  h.PO,
                h.Description,
                ROUND(CONVERT(decimal(14, 2), SUM(CASE t.RecvYN
                                                    WHEN 'Y'
                                                    THEN CASE t.UM
                                                           WHEN 'LS'
                                                           THEN CASE i.RecvdCost
                                                              WHEN i.InvCost
                                                              THEN 0
                                                              ELSE i.RecvdCost
                                                              - i.InvCost
                                                              END
                                                           ELSE CASE i.RecvdUnits
                                                              WHEN i.InvUnits
                                                              THEN 0
                                                              ELSE ROUND(( ( i.RecvdUnits
                                                              - i.InvUnits )
                                                              * ( t.CurUnitCost
                                                              / CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ), 2)
                                                              END
                                                         END
                                                    ELSE CASE t.UM
                                                           WHEN 'LS'
                                                           THEN CASE i.BOCost
                                                              WHEN 0 THEN 0
                                                              ELSE i.BOCost
                                                              END
                                                           ELSE CASE i.BOUnits
                                                              WHEN 0 THEN 0
                                                              ELSE ROUND(( i.BOUnits
                                                              * ( t.CurUnitCost
                                                              / ( CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ) ), 2)
                                                              END
                                                         END
                                                  END)), 2) AS 'Left to be Invoiced', --TOBEINV,
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                                JOIN dbo.bHQCP c WITH ( NOLOCK ) ON	p.CompCode = c.CompCode
                       WHERE    p.POCo = @co
                                AND p.PO = h.PO
                                AND p.Verify = 'Y'
                                AND ( ( c.CompType = 'F'
                                        AND p.Complied = 'N'
                                      )
                                      OR ( c.CompType = 'D'
                                           AND ( @invdate > p.ExpDate )
                                           OR p.ExpDate IS NULL
                                         )
                                    )
                     )
                  WHEN 0 THEN ''
                  ELSE 'No'
                END AS 'Compliance',
                CASE WHEN ISNULL(h.InUseMth, '') <> ''
                          AND ( ISNULL(h.InUseMth, '') <> @batchmth
                                OR /*and #19429 */ ISNULL(h.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'

                                                
        FROM    vPOItemLine i WITH ( NOLOCK )                
				JOIN bPOIT t WITH ( NOLOCK )  ON i.POCo = t.POCo
                                                AND i.PO = t.PO
                                                AND i.POItem = t.POItem
                JOIN bPOHD h WITH ( NOLOCK ) ON i.POCo = h.POCo
                                                AND i.PO = h.PO                                                

        WHERE   h.POCo = @co
                AND h.PO LIKE RTRIM(@po) + '%'
                AND h.Vendor = @vendor
                AND h.VendorGroup = VendorGroup
                AND h.Status = 0        

		GROUP BY        h.PO,
						h.Description,
						h.Status,
						h.InUseMth,
						h.InUseBatchId
						
        HAVING  SUM(CASE t.RecvYN
                      WHEN 'Y'
                      THEN CASE t.UM
                             WHEN 'LS' THEN CASE i.RecvdCost
                                              WHEN i.InvCost THEN 0
                                              ELSE i.RecvdCost - i.InvCost
                                            END
                             ELSE CASE i.RecvdUnits
                                    WHEN i.InvUnits THEN 0
                                    ELSE ( ( i.RecvdUnits - i.InvUnits )
                                           * ( t.CurUnitCost
                                               / CASE t.CurECM
                                                   WHEN 'C' THEN 100
                                                   WHEN 'M' THEN 1000
                                                   ELSE 1
                                                 END ) )
                                  END
                           END
                      ELSE CASE t.UM
                             WHEN 'LS' THEN CASE i.BOCost
                                              WHEN 0 THEN 0
                                              ELSE i.BOCost
                                            END
                             ELSE CASE i.BOUnits
                                    WHEN 0 THEN 0
                                    ELSE ( i.BOUnits * ( t.CurUnitCost
                                                         / ( CASE t.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                             END ) ) )
                                  END
                           END
                    END) <> 0
    END

bspexit:
RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[bspAPPOInitPOlst] TO [public]
GO
