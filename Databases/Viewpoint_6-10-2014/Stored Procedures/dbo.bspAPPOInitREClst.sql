SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOInitREClst    Script Date: 8/28/99 9:36:02 AM ******/
 
 
CREATE              PROC [dbo].[bspAPPOInitREClst]
   /***********************************************************
    * CREATED BY	: danf 02/16/2000
    * MODIFIED		: Tony v 2/20/01
    *			  Tony v 07/24/01
    *              DANF 02/28/02 Added Batchid and batch month
    *				MV 06/03/04 #24726 - correct batchid and mth logic
    *				Geoff and Jim E. - 10/11/05 #30008 - remove receiver from joins
    *				MV 08/01/06 - #30648 - more performance improvements by J and G.
    *				MV 08/01/06 - #120077 - rounding prob with TOBEINV calc within sum
    *				MV 08/02/06 - #26096 - include POs with blank receiver unless filtering by receiver
	*				MV 02/13/09 - #123778 - limit by PORD APMth, APTrans and APLine instead of InvdFlag
    *				MV 10/05/09 - #135834 - exclude previously invoiced where the old InvdFlag was still used. 
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *				MV 08/24/11 - TK-07944 - AP project to use POItemLine
    *
    * USAGE:
    * Called by AP PO initialize program to populate Receiver list
    *
    * INPUTS:
    *    @co         AP Company
    *    @vendor     Vendor
    *    @vendorgroup group
    *    @po 	PO
    *    @reciever Reciver 
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
  @po varchar(30) = NULL,
  @reciever varchar(20) = NULL,
  @invdate bDate,
  @batchid bBatchID,
  @batchmth bMonth,
  @msg varchar(255) OUTPUT
)
AS 
SET nocount ON
 
DECLARE @rcode int,
    @tempPO varchar(20),
    @tempRec varchar(20)
 
SELECT  @rcode = 0
 
IF @po = ''
    AND @reciever = '' 
    BEGIN
        SELECT  r.Receiver#,
                h.PO,
                h.Description,
                CONVERT(decimal(14, 2), SUM(CASE i.RecvYN
                                              WHEN 'Y'
                                              THEN CASE i.UM
                                                     WHEN 'LS'
                                                     THEN r.RecvdCost
                                                     ELSE ROUND(r.RecvdUnits
                                                              * ( i.CurUnitCost
                                                              / CASE i.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ), 2)
                                                   END
                                              ELSE 0
                                            END)) AS 'Received', /*TOBEINV,*/
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                                JOIN dbo.bHQCP c WITH ( NOLOCK ) ON p.CompCode = c.CompCode
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
                CASE WHEN ISNULL(l.InUseMth, '') <> ''
                          AND ( ISNULL(l.InUseMth, '') <> @batchmth
                                OR /*and #24726 */ ISNULL(l.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'
        FROM    bPORD r WITH ( NOLOCK )
                JOIN bPOHD h WITH ( NOLOCK ) ON r.POCo = h.POCo
                                                AND r.PO = h.PO
                JOIN bPOIT i WITH ( NOLOCK ) ON r.POCo = i.POCo
                                                AND r.PO = i.PO
                                                AND r.POItem = i.POItem
                JOIN vPOItemLine l (NOLOCK)  ON r.POCo = l.POCo
                                                AND r.PO = l.PO
                                                AND r.POItem = l.POItem
                                                AND r.POItemLine = l.POItemLine 
 	-- needed to filter by InvdFlag 07/24/01 TV
-- 	where i.POCo = @co and h.Vendor = @vendor and h.VendorGroup = @vendorgroup and r.InvdFlag = 'N' and r.Receiver# <> '' 
        WHERE   h.POCo = @co
                AND h.Vendor = @vendor
                AND h.VendorGroup = @vendorgroup
                AND r.InvdFlag = 'N'
                AND  --r.Receiver# <> '' 
                r.APMth IS NULL
                AND r.APTrans IS NULL
                AND r.APLine IS NULL
        GROUP BY r.Receiver#,
                h.PO,
                h.Description,
                h.Status,
                l.InUseMth,
                l.InUseBatchId
        HAVING  SUM(CASE i.RecvYN
                      WHEN 'Y'
                      THEN CASE i.UM
                             WHEN 'LS' THEN r.RecvdCost
                             ELSE ( r.RecvdUnits * ( i.CurUnitCost
                                                     / CASE i.CurECM
                                                         WHEN 'C' THEN 100
                                                         WHEN 'M' THEN 1000
                                                         ELSE 1
                                                       END ) )
                           END
                      ELSE 0
                    END) <> 0
 
    END
 -- If filtering list by PO
IF @po <> ''
    AND @reciever = '' 
    BEGIN
        SELECT  r.Receiver#,
                h.PO,
                h.Description,
                CONVERT(decimal(14, 2), SUM(CASE i.RecvYN
                                              WHEN 'Y'
                                              THEN CASE i.UM
                                                     WHEN 'LS'
                                                     THEN r.RecvdCost
                                                     ELSE ROUND(( r.RecvdUnits
                                                              * ( i.CurUnitCost
                                                              / CASE i.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ), 2)
                                                   END
                                              ELSE 0
                                            END)) AS 'Left To be Invoiced', -- TOBEINV,
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                                JOIN dbo.bHQCP c WITH ( NOLOCK )  ON p.CompCode = c.CompCode
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
                END AS COmpliance,
                CASE WHEN ISNULL(l.InUseMth, '') <> ''
                          AND ( ISNULL(l.InUseMth, '') <> @batchmth
                                OR /*and #24726 */ ISNULL(l.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'
        FROM    bPORD r WITH ( NOLOCK ) -- needed to filter by InvdFalg 07/24/01 TV
                JOIN bPOHD h WITH ( NOLOCK ) ON r.POCo = h.POCo
                                                AND r.PO = h.PO
                JOIN bPOIT i WITH ( NOLOCK ) ON r.POCo = i.POCo
                                                AND r.PO = i.PO
                                                AND r.POItem = i.POItem
                JOIN vPOItemLine l (NOLOCK)  ON r.POCo = l.POCo
                                                AND r.PO = l.PO
                                                AND r.POItem = l.POItem
                                                AND r.POItemLine = l.POItemLine 
        WHERE   r.PO LIKE RTRIM(@po) + '%'
                AND /*r.Receiver# <> ''and*/ h.Vendor = @vendor
                AND h.VendorGroup = @vendorgroup
                AND h.POCo = @co
                AND r.APMth IS NULL
                AND r.APTrans IS NULL
                AND r.APLine IS NULL
                AND r.InvdFlag = 'N'
        GROUP BY r.Receiver#,
                h.PO,
                h.Description,
                h.Status,
                l.InUseMth,
                l.InUseBatchId
        HAVING  SUM(CASE i.RecvYN
                      WHEN 'Y'
                      THEN CASE i.UM
                             WHEN 'LS' THEN r.RecvdCost
                             ELSE ( r.RecvdUnits * ( i.CurUnitCost
                                                     / CASE i.CurECM
                                                         WHEN 'C' THEN 100
                                                         WHEN 'M' THEN 1000
                                                         ELSE 1
                                                       END ) )
                           END
                      ELSE 0
                    END) <> 0
 
    END
 
 -- By reciever
IF @reciever <> ''
    AND @po = '' 
    BEGIN
 
        SELECT  r.Receiver#,
                h.PO,
                h.Description,
                CONVERT(decimal(14, 2), SUM(CASE i.RecvYN
                                              WHEN 'Y'
                                              THEN CASE i.UM
                                                     WHEN 'LS'
                                                     THEN r.RecvdCost
                                                     ELSE ROUND(( r.RecvdUnits
                                                              * ( i.CurUnitCost
                                                              / CASE i.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ), 2)
                                                   END
                                              ELSE 0
                                            END)) AS 'Left to be Invoiced',--TOBEINV,
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                                JOIN dbo.bHQCP c WITH ( NOLOCK ) ON p.CompCode = c.CompCode
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
                CASE WHEN ISNULL(l.InUseMth, '') <> ''
                          AND ( ISNULL(l.InUseMth, '') <> @batchmth
                                AND ISNULL(l.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'
        FROM    bPORD r WITH ( NOLOCK ) -- needed to filter by InvdFalg 07/24/01 TV
                JOIN bPOHD h WITH ( NOLOCK ) ON r.POCo = h.POCo
                                                AND r.PO = h.PO
                JOIN bPOIT i WITH ( NOLOCK ) ON r.POCo = i.POCo
                                                AND r.PO = i.PO
                                                AND r.POItem = i.POItem
                JOIN vPOItemLine l (NOLOCK)  ON r.POCo = l.POCo
                                                AND r.PO = l.PO
                                                AND r.POItem = l.POItem
                                                AND r.POItemLine = l.POItemLine 
        WHERE   r.Receiver# LIKE RTRIM(@reciever) + '%'
                AND 
 	/*	r.Receiver# <> ''and*/ h.Vendor = @vendor
                AND h.VendorGroup = @vendorgroup
                AND h.POCo = @co
                AND r.InvdFlag = 'N'
                AND r.APMth IS NULL
                AND r.APTrans IS NULL
                AND r.APLine IS NULL
        GROUP BY r.Receiver#,
                h.PO,
                h.Description,
                h.Status,
                l.InUseMth,
                l.InUseBatchId
        HAVING  SUM(CASE i.RecvYN
                      WHEN 'Y'
                      THEN CASE i.UM
                             WHEN 'LS' THEN r.RecvdCost
                             ELSE ( r.RecvdUnits * ( i.CurUnitCost
                                                     / CASE i.CurECM
                                                         WHEN 'C' THEN 100
                                                         WHEN 'M' THEN 1000
                                                         ELSE 1
                                                       END ) )
                           END
                      ELSE 0
                    END) <> 0
 
    END
 
 -- For filter by Both
 
IF @po <> ''
    AND @reciever <> '' 
    BEGIN
 
        SELECT  r.Receiver#,
                h.PO,
                h.Description,
                CONVERT(decimal(14, 2), SUM(CASE i.RecvYN
                                              WHEN 'Y'
                                              THEN CASE i.UM
                                                     WHEN 'LS'
                                                     THEN r.RecvdCost
                                                     ELSE ROUND(( r.RecvdUnits
                                                              * ( i.CurUnitCost
                                                              / CASE i.CurECM
                                                              WHEN 'C'
                                                              THEN 100
                                                              WHEN 'M'
                                                              THEN 1000
                                                              ELSE 1
                                                              END ) ), 2)
                                                   END
                                              ELSE 0
                                            END)) AS 'Left to be Invoiced', --TOBEINV,
                CASE ( SELECT   COUNT(*)
                       FROM     dbo.bPOCT p WITH ( NOLOCK )
                               JOIN dbo.bHQCP c WITH ( NOLOCK ) ON  p.CompCode = c.CompCode
                       WHERE   p.POCo = @co
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
                CASE WHEN ISNULL(l.InUseMth, '') <> ''
                          AND ( ISNULL(l.InUseMth, '') <> @batchmth
                                AND ISNULL(l.InUseBatchId, '') <> @batchid
                              ) THEN 'Yes'
                     ELSE NULL
                END AS 'In Open Batch'
        FROM    bPORD r WITH ( NOLOCK ) -- needed to filter by InvdFalg 07/24/01 TV
                JOIN bPOHD h WITH ( NOLOCK ) ON r.POCo = h.POCo
                                                AND r.PO = h.PO
                JOIN bPOIT i WITH ( NOLOCK ) ON r.POCo = i.POCo
                                                AND r.PO = i.PO
                                                AND r.POItem = i.POItem
                JOIN vPOItemLine l (NOLOCK)  ON r.POCo = l.POCo
                                                AND r.PO = l.PO
                                                AND r.POItem = l.POItem
                                                AND r.POItemLine = l.POItemLine 
        WHERE   r.PO LIKE RTRIM(@po) + '%'
                AND r.Receiver# LIKE RTRIM(@reciever) + '%'
                AND r.Receiver# <> ''
                AND h.Vendor = @vendor
                AND h.VendorGroup = @vendorgroup
                AND h.POCo = @co
                AND r.InvdFlag = 'N'
                AND r.APMth IS NULL
                AND r.APTrans IS NULL
                AND r.APLine IS NULL
        GROUP BY r.Receiver#,
                h.PO,
                h.Description,
                h.Status,
                l.InUseMth,
                l.InUseBatchId
        HAVING  SUM(CASE i.RecvYN
                      WHEN 'Y'
                      THEN CASE i.UM
                             WHEN 'LS' THEN r.RecvdCost
                             ELSE ( r.RecvdUnits * ( i.CurUnitCost
                                                     / CASE i.CurECM
                                                         WHEN 'C' THEN 100
                                                         WHEN 'M' THEN 1000
                                                         ELSE 1
                                                       END ) )
                           END
                      ELSE 0
                    END) <> 0
 
    END
 
bspexit:
RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPPOInitREClst] TO [public]
GO
