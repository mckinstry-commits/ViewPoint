SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspSLMyPayRequestItemsUpdate]
/************************************************************
* CREATED:		4/10/07		CHS
* MODIFIED:		6/25/07		CHS
* MODIFIED:		11/26/07	CHS
*				GF 06/26/2010 - issue #135318 expanded SL to varchar(30)
*				GF 03/04/2011 - TK-02323 missing SLItem variable in where clause issue #143522
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   updates pay request Headers
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, Vendor, and VendorGroup from pUsers --%Vendor% & %VendorGroup%
*
************************************************************/
    (
      @SLCo bCompany,
      @UserName bVPUserName,
      @SL VARCHAR(30),
      @SLItem bItem,
      @ItemType TINYINT,
      @Description bItemDesc,
      @PhaseGroup bGroup,
      @Phase bPhase,
      @UM bUM,
      @CurUnits bUnits,
      @CurUnitCost bUnitCost,
	--@CurCost bDollar,
      @PrevWCUnits bUnits,
      @PrevWCCost bDollar,
      @WCUnits bUnits,
      @WCCost bDollar,
      @WCRetPct bPct,
      @WCRetAmt bDollar,
      @PrevSM bDollar,
      @Purchased bDollar,
      @Installed bDollar,
      @SMRetPct bPct,
      @SMRetAmt bDollar,
      @LineDesc bDesc,
      @VendorGroup bGroup,
      @Supplier bVendor,
      @BillMonth bMonth,
      @BillNumber INT,
      @BillChangedYN bYN,
      @WCPctComplete bPct,
      @WCToDate bDollar,
      @WCToDateUnits bUnits,
      @Notes VARCHAR(MAX),
      @Original_SLCo bCompany,
      @Original_UserName bVPUserName,
      @Original_SL VARCHAR(30),
      @Original_SLItem bItem,
      @Original_ItemType TINYINT,
      @Original_Description bItemDesc,
      @Original_PhaseGroup bGroup,
      @Original_Phase bPhase,
      @Original_UM bUM,
      @Original_CurUnits bUnits,
      @Original_CurUnitCost bUnitCost,
	--@Original_CurCost bDollar,
      @Original_PrevWCUnits bUnits,
      @Original_PrevWCCost bDollar,
      @Original_WCUnits bUnits,
      @Original_WCCost bDollar,
      @Original_WCRetPct bPct,
      @Original_WCRetAmt bDollar,
      @Original_PrevSM bDollar,
      @Original_Purchased bDollar,
      @Original_Installed bDollar,
      @Original_SMRetPct bPct,
      @Original_SMRetAmt bDollar,
      @Original_LineDesc bDesc,
      @Original_VendorGroup bGroup,
      @Original_Supplier bVendor,
      @Original_BillMonth bMonth,
      @Original_BillNumber INT,
      @Original_BillChangedYN bYN,
      @Original_WCPctComplete bPct,
      @Original_WCToDate bDollar,
      @Original_WCToDateUnits bUnits,
      @Original_Notes VARCHAR(MAX)

    )
AS 
    SET NOCOUNT ON ;

-- Note: update only if user makes a change
    IF ( @WCCost != @Original_WCCost )
        OR ( @Purchased != @Original_Purchased ) 
        SET @WCToDate = ( @PrevWCCost + @WCCost + @Purchased )
    ELSE 
        SET @WCToDate = @Original_WCToDate
 
-- Note: If it is Lump Sum ignore units -- otherwise update only if user makes a change
    IF @UM != 'LS'
        AND @WCUnits != @Original_WCUnits 
        BEGIN
            SET @WCToDateUnits = ( @WCUnits + @PrevWCUnits )
        END
    ELSE 
        BEGIN
            SET @WCToDateUnits = @Original_WCToDateUnits
            SET @WCUnits = @Original_WCUnits
        END
	
    SET @WCRetAmt = ISNULL(@WCRetPct, 0) * ISNULL(@WCCost, 0)

    SET @SMRetAmt = ISNULL(@Purchased, 0) * ISNULL(@SMRetPct, 0)

    UPDATE  SLWI
    SET     WCUnits = @WCUnits,
            WCCost = @WCCost,
            Purchased = @Purchased,
            WCToDate = @WCToDate,
            WCToDateUnits = @WCToDateUnits,
            LineDesc = @LineDesc,
            SMRetAmt = @SMRetAmt,
            WCRetAmt = @WCRetAmt
    WHERE   SLCo = @SLCo
            AND UserName = @UserName
            AND SL = @SL
----TK-02323 - #143522
            AND SLItem = @SLItem
            AND ItemType = @ItemType
            AND ( WCUnits = @Original_WCUnits
                  OR ( @Original_WCUnits IS NULL
                       AND WCUnits IS NULL
                     )
                )
            AND ( WCCost = @Original_WCCost
                  OR ( @Original_WCCost IS NULL
                       AND WCCost IS NULL
                     )
                )
            AND ( Purchased = @Original_Purchased
                  OR ( @Original_Purchased IS NULL
                       AND Purchased IS NULL
                     )
                )
            AND ( WCToDate = @Original_WCToDate
                  OR ( @Original_WCToDate IS NULL
                       AND WCToDate IS NULL
                     )
                )
            AND ( WCToDateUnits = @Original_WCToDateUnits
                  OR ( @Original_WCToDateUnits IS NULL
                       AND WCToDateUnits IS NULL
                     )
                )
GO
GRANT EXECUTE ON  [dbo].[vpspSLMyPayRequestItemsUpdate] TO [VCSPortal]
GO
