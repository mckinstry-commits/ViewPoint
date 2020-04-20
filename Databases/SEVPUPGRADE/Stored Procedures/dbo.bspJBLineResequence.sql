SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBLineResequence    Script Date: 8/28/99 9:32:34 AM ******/
CREATE PROC [dbo].[bspJBLineResequence]
/***********************************************************
* CREATED BY	: kb 7/18/00
* MODIFIED BY	: bc 08/07/00
*  		bc 09/25/00 - TemplateGroupNum is nullable in JBIL
*    	bc 10/02/01 - Redimensioned Employee to int
*		kb 7/9/2 - issue #17884 need to update Hours, Units, Amt to JBIJ
*		TJL 07/11/02	-	Issue #17701(Indirectly), Reversed order of insert to: JBIJ, JBID, JBIL
*		TJL 08/08/03 - Issue #22010, Correct APRef problem, other improvements
*		TJL 09/15/03 - Issue #22126, Improved performance when resequencing, suspend triggers
*		TJL 07/09/07 - Issue #124993, (5x Issue #124752) Description column for Table Variables must match the associated table.
*		TJL 01/29/09 - Issue #132365, Customer looses JBID Notes.
*		TJL 06/22/10 - Issue #139512, Fix Non-Billable transactions missing from bill and BillStatus not cleared in JCCD
*		DC 6/29/10 - #135813 - expand subcontract number
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*
* USAGE:  when this bsp is run, the lines should already be in the correct order.
*         the funtcion of this code is to create space inbetween existing lines by increments of 10
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
    (
     @co bCompany,
     @billmth bMonth,
     @billnum int,
     @msg varchar(255) OUTPUT
    )
AS 
SET nocount ON

DECLARE @rcode int,
    @sortorder char(1),
    @oldline int,
    @newline int,
    @linecnt int,
    @linecnt2 int

SELECT  @rcode = 0, @newline = 0

SELECT  @linecnt = COUNT(*)
FROM    JBIL WITH (NOLOCK)
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

/* Suspend triggers during resequence process.  Since values in these and related tables already exist
  and this process only changes line numbering without changing original values in any table, we can
  simply re-insert the values into the respective tables without the time consuming updates to 
  related tables.  No Auditing will occur. (Same as when a bill gets deleted.) */
UPDATE  bJBIL
SET     Purge = 'Y', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

UPDATE  bJBID
SET     Purge = 'Y', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

UPDATE  bJBIJ
SET     Purge = 'Y', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum
   
--update bJBIL
--set ReseqYN = 'Y'
--where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum

--create table #LineReseq
DECLARE @LineReseq TABLE
    (
     [NewLine2] int NOT NULL,
     [OldLine] int NULL,
     [Item] [dbo].[bContractItem] NULL,
     [Contract] [dbo].[bContract] NULL,
     [Job] [dbo].[bJob] NULL,
     [PhaseGroup] [dbo].[bGroup] NULL,
     [Phase] [dbo].[bPhase] NULL,
     [Date] [dbo].[bDate] NULL,
     [Template] [varchar](10) NULL,
     [TemplateSeq] [int] NULL,
     [TemplateSortLevel] [tinyint] NULL,
     [TemplateSeqSumOpt] [tinyint] NULL,
     [TemplateSeqGroup] [int] NULL,
     [LineType] [char](1) NULL,
     [Description] [varchar](128) NULL,
     [TaxGroup] [dbo].[bGroup] NULL,
     [TaxCode] [dbo].[bTaxCode] NULL,
     [MarkupOpt] [char](1) NULL,
     [MarkupRate] [dbo].[bUnitCost] NOT NULL,
     [Basis] [dbo].[bDollar] NOT NULL,
     [MarkupAddl] [dbo].[bDollar] NOT NULL,
     [MarkupTotal] [dbo].[bDollar] NOT NULL,
     [Total] [dbo].[bDollar] NOT NULL,
     [Retainage] [dbo].[bDollar] NOT NULL,
     [Discount] [dbo].[bDollar] NOT NULL,
     [NewLine] [int] NULL,
     [ReseqYN] [dbo].[bYN] NOT NULL,
     [LineKey] [varchar](100) NULL,
     [Notes] [varchar](8000) NULL,
     [TemplateGroupNum] [int] NULL,
     [LineForAddon] [int] NULL,
     [AuditYN] [dbo].[bYN] NOT NULL
                           DEFAULT ('Y'),
     [Purge] [dbo].[bYN] NOT NULL
                         DEFAULT ('N'),
     [UniqueAttchID] [uniqueidentifier] NULL
    )
--CREATE UNIQUE CLUSTERED INDEX  btiTempLines ON  #LineReseq(NewLine2)	--REM'D ISSUE #22010
   
--create table #DetailReseq
DECLARE @DetailReseq TABLE
    (
     [NewLine] int NOT NULL,
     [Seq] int NOT NULL,
     [Source] [char](2) NULL,
     [PhaseGroup] [dbo].[bGroup] NULL,
     [CostType] [dbo].[bJCCType] NULL,
     [CostTypeCategory] [char](1) NULL,
     [PRCo] [dbo].[bCompany] NULL,
     [Employee] [dbo].[bEmployee] NULL,
     [EarnType] [dbo].[bEarnType] NULL,
     [Craft] [dbo].[bCraft] NULL,
     [Class] [dbo].[bClass] NULL,
     [Factor] [dbo].[bRate] NULL,
     [Shift] [tinyint] NULL,
     [LiabilityType] [dbo].[bLiabilityType] NULL,
     [APCo] [dbo].[bCompany] NULL,
     [VendorGroup] [dbo].[bGroup] NULL,
     [Vendor] [dbo].[bVendor] NULL,
     [APRef] [dbo].[bAPReference] NULL,
     [PreBillYN] [dbo].[bYN] NOT NULL,
     [INCo] [dbo].[bCompany] NULL,
     [MatlGroup] [dbo].[bGroup] NULL,
     [Material] [dbo].[bMatl] NULL,
     [Location] [dbo].[bLoc] NULL,
     [MSTicket] [dbo].[bTic] NULL,
     [StdUM] [dbo].[bUM] NULL,
     [StdPrice] [dbo].[bUnitCost] NOT NULL,
     [StdECM] [dbo].[bECM] NULL,
     [SL] [varchar](30) NULL, --[dbo].[bSL] NULL,  --DC #135813
     [SLItem] [dbo].[bItem] NULL,
     [PO] [varchar](30) NULL,
     [POItem] [dbo].[bItem] NULL,
     [EMCo] [dbo].[bCompany] NULL,
     [EMGroup] [dbo].[bGroup] NULL,
     [Equipment] [dbo].[bEquip] NULL,
     [RevCode] [dbo].[bRevCode] NULL,
     [JCMonth] [dbo].[bMonth] NULL,
     [JCTrans] [dbo].[bTrans] NULL,
     [JCDate] [dbo].[bDate] NULL,
     [Category] [varchar](10) NULL,
     [Description] [dbo].[bItemDesc] NULL,
     [UM] [dbo].[bUM] NULL,
     [Units] [dbo].[bUnits] NOT NULL,
     [UnitPrice] [dbo].[bUnitCost] NOT NULL,
     [ECM] [dbo].[bECM] NULL,
     [Hours] [dbo].[bHrs] NOT NULL,
     [SubTotal] [numeric](15, 5) NOT NULL,
     [MarkupRate] [dbo].[bUnitCost] NOT NULL,
     [MarkupAddl] [dbo].[bDollar] NOT NULL,
     [MarkupTotal] [numeric](15, 5) NOT NULL,
     [Total] [dbo].[bDollar] NOT NULL,
     [Template] [varchar](10) NULL,
     [TemplateSeq] [int] NULL,
     [TemplateSortLevel] [tinyint] NULL,
     [TemplateSeqSumOpt] [tinyint] NULL,
     [TemplateSeqGroup] [int] NULL,
     [DetailKey] [varchar](500) NULL,
     [Notes] [varchar](8000) NULL,
     [UniqueAttchID] [uniqueidentifier] NULL,
     [AuditYN] [dbo].[bYN] NOT NULL,
     [Purge] [dbo].[bYN] NOT NULL
    )
--CREATE UNIQUE CLUSTERED INDEX  btiTempDetail ON #DetailReseq(NewLine,Seq)	--REM'D ISSUE #22010
   
--create table #JBIJReseq
DECLARE @JBIJReseq TABLE
    (
     [NewLine] int NOT NULL,
     [Seq] int NOT NULL,
     [JCMonth] [dbo].[bMonth] NOT NULL,
     [JCTrans] [dbo].[bTrans] NOT NULL,
     [BillStatus] [char](1) NULL,
     [Hours] [dbo].[bHrs] NOT NULL
                          DEFAULT ((0)),
     [Units] [dbo].[bUnits] NOT NULL
                            DEFAULT ((0)),
     [Amt] [numeric](15, 5) NOT NULL
                            DEFAULT ((0)),
     [AuditYN] [dbo].[bYN] NOT NULL
                           DEFAULT ('Y'),
     [Purge] [dbo].[bYN] NOT NULL
                         DEFAULT ('N'),
     [UnitPrice] [dbo].[bUnitCost] NOT NULL
                                   DEFAULT ((0)),
     [UniqueAttchID] [uniqueidentifier] NULL,
     [UM] [dbo].[bUM] NULL,
     [EMGroup] [dbo].[bGroup] NULL,
     [EMRevCode] [dbo].[bRevCode] NULL
    )
--CREATE UNIQUE CLUSTERED INDEX  btiTempJBIJ ON #JBIJReseq(NewLine,Seq,JCMonth,JCTrans)	--REM'D ISSUE #22010
   
/* Place Current table data in Table variable with New Line Number */
SELECT  @oldline = MIN(Line)
FROM    bJBIL WITH (NOLOCK)
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum
WHILE @oldline IS NOT NULL 
    BEGIN

        SELECT  @newline = ISNULL(@newline, 0) + 10

        INSERT  @LineReseq
                SELECT  @newline, Line, Item, Contract, Job, PhaseGroup, Phase, Date, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, LineType, [Description], TaxGroup, TaxCode, MarkupOpt, MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount, NewLine, ReseqYN, LineKey, Notes, TemplateGroupNum, LineForAddon, AuditYN, Purge, UniqueAttchID
                FROM    bJBIL WITH (NOLOCK)
                WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum AND Line = @oldline

        INSERT  @DetailReseq
                SELECT  @newline, Seq, Source, PhaseGroup, CostType, CostTypeCategory, PRCo, Employee, EarnType, Craft, Class, Factor, Shift, LiabilityType, APCo, VendorGroup, Vendor, APRef, PreBillYN, INCo, MatlGroup, Material, Location, MSTicket, StdUM, StdPrice, StdECM, SL, SLItem, PO, POItem, EMCo, EMGroup, Equipment, RevCode, JCMonth, JCTrans, JCDate, Category, [Description], UM, Units, UnitPrice, ECM, Hours, SubTotal, MarkupRate, MarkupAddl, MarkupTotal, Total, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, DetailKey, Notes, UniqueAttchID, AuditYN, Purge
                FROM    bJBID WITH (NOLOCK)
                WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum AND Line = @oldline

        INSERT  @JBIJReseq
                SELECT  @newline, Seq, JCMonth, JCTrans, BillStatus, Hours, Units, Amt, AuditYN, Purge, UnitPrice, UniqueAttchID, UM, EMGroup, EMRevCode
                FROM    bJBIJ WITH (NOLOCK)
                WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum AND Line = @oldline

        SELECT  @oldline = MIN(Line)
        FROM    bJBIL WITH (NOLOCK)
        WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum AND Line > @oldline
        IF @@rowcount = 0 
            SELECT  @oldline = NULL
    END
   
SELECT  @linecnt2 = COUNT(*)
FROM    @LineReseq

IF @linecnt <> @linecnt2 
    BEGIN
        SELECT  @msg = 'Error inserting lines into temporary table for processing.', @rcode = 1
        GOTO bspexit
    END

BEGIN TRANSACTION
   
/* Clear out Tables.  Triggers have been suspended. */
DELETE  bJBIL
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum
DELETE  bJBID
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum
DELETE  bJBIJ
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum AND (Line IS NOT NULL AND Seq IS NOT NULL)

/* Insert from Table variables into Tables with New Line Numbering.  Triggers have been suspended. */
SELECT  @newline = NULL
SELECT  @newline = MIN(NewLine2)
FROM    @LineReseq
WHILE @newline IS NOT NULL 
    BEGIN

        INSERT  INTO bJBIJ (JBCo, BillMonth, BillNumber, Line, Seq, JCMonth, JCTrans, BillStatus, Hours, Units, Amt, AuditYN, Purge, UnitPrice, UniqueAttchID, UM, EMGroup, EMRevCode)
                SELECT  @co, @billmth, @billnum, NewLine, Seq, JCMonth, JCTrans, BillStatus, Hours, Units, Amt, AuditYN, Purge, UnitPrice, UniqueAttchID, UM, EMGroup, EMRevCode
                FROM    @JBIJReseq
                WHERE   NewLine = @newline

        INSERT  INTO bJBID (JBCo, BillMonth, BillNumber, Line, Seq, Source, PhaseGroup, CostType, CostTypeCategory, PRCo, Employee, EarnType, Craft, Class, Factor, Shift, LiabilityType, APCo, VendorGroup, Vendor, APRef, PreBillYN, INCo, MatlGroup, Material, Location, MSTicket, StdUM, StdPrice, StdECM, SL, SLItem, PO, POItem, EMCo, EMGroup, Equipment, RevCode, JCMonth, JCTrans, JCDate, Category, [Description], UM, Units, UnitPrice, ECM, Hours, SubTotal, MarkupRate, MarkupAddl, MarkupTotal, Total, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, DetailKey, Notes, UniqueAttchID, AuditYN, Purge)
                SELECT  @co, @billmth, @billnum, NewLine, Seq, Source, PhaseGroup, CostType, CostTypeCategory, PRCo, Employee, EarnType, Craft, Class, Factor, Shift, LiabilityType, APCo, VendorGroup, Vendor, APRef, PreBillYN, INCo, MatlGroup, Material, Location, MSTicket, StdUM, StdPrice, StdECM, SL, SLItem, PO, POItem, EMCo, EMGroup, Equipment, RevCode, JCMonth, JCTrans, JCDate, Category, [Description], UM, Units, UnitPrice, ECM, Hours, SubTotal, MarkupRate, MarkupAddl, MarkupTotal, Total, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, DetailKey, Notes, UniqueAttchID, AuditYN, Purge
                FROM    @DetailReseq
                WHERE   NewLine = @newline
   
        INSERT  INTO bJBIL (JBCo, BillMonth, BillNumber, Line, Item, Contract, Job, PhaseGroup, Phase, Date, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, LineType, [Description], TaxGroup, TaxCode, MarkupOpt, MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount, NewLine, ReseqYN, LineKey, Notes, TemplateGroupNum, LineForAddon, AuditYN, Purge, UniqueAttchID)
                SELECT  @co, @billmth, @billnum, NewLine2, Item, Contract, Job, PhaseGroup, Phase, Date, Template, TemplateSeq, TemplateSortLevel, TemplateSeqSumOpt, TemplateSeqGroup, LineType, [Description], TaxGroup, TaxCode, MarkupOpt, MarkupRate, Basis, MarkupAddl, MarkupTotal, Total, Retainage, Discount, NewLine, ReseqYN, LineKey, Notes, TemplateGroupNum, LineForAddon, AuditYN, Purge, UniqueAttchID
                FROM    @LineReseq
                WHERE   NewLine2 = @newline

        SELECT  @newline = MIN(NewLine2)
        FROM    @LineReseq
        WHERE   NewLine2 > @newline

    END
   
IF (SELECT  COUNT(*)
    FROM    JBIL WITH (NOLOCK)
    WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum) <> @linecnt2 
    BEGIN
        SELECT  @msg = 'Error inserting resequenced rows back into JBIL', @rcode = 1
        GOTO error
    END
   
COMMIT TRANSACTION
GOTO bspexit

error:
ROLLBACK TRANSACTION
GOTO bspexit

bspexit:
/* Reset flags, basically to re-enable triggers. */
UPDATE  bJBIL
SET     Purge = 'N', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

UPDATE  bJBID
SET     Purge = 'N', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

UPDATE  bJBIJ
SET     Purge = 'N', AuditYN = 'N'
WHERE   JBCo = @co AND BillMonth = @billmth AND BillNumber = @billnum

--update bJBIL
--set ReseqYN = 'N'
--where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum

RETURN @rcode




GO
GRANT EXECUTE ON  [dbo].[bspJBLineResequence] TO [public]
GO
